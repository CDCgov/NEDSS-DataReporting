# Bug #7: sp_nrt_ldf_dimensional_data_postprocessing produces 0 rows

**Status**: Confirmed. SP early-returns with the "Missing NRT Record" payload
without reaching any of the data-processing steps.
**Severity**: High. LDF_DIMENSIONAL_DATA never populates, which cascades to
all per-condition `ldf_<condition>` tables (including LDF_TETANUS, blocking
Bug #8 downstream).
**Surfaced by**: comparison-fixtures Tier 3 LDF answer chain
(`fixtures/30_sp_coverage/ldf_answers_tetanus.sql`).

## TL;DR

The SP fails for **two independent reasons**, both visible in the same EXEC:

1. **Primary (always fires).** The early-RETURN guard at SP lines 136-158
   (`@backfill_list IS NOT NULL` then RETURN) treats *intentionally
   data-type-filtered* ldf_uids as "missing NRT records" and aborts the whole
   batch. Any single ldf_uid with `data_type NOT IN ('ST','CV','LIST_ST')`
   poisons every other ldf_uid in the same call.

2. **Secondary (latent; would fire if guard removed).** The `#LDF_DATA` step
   (line 622, the "TMP_LDF_DATA" step in the bug report) uses
   `INNER JOIN nrt_srte_LDF_PAGE_SET ON page_set.ldf_page_id = a.ldf_page_id`
   on `nrt_ldf_data`. When `nrt_ldf_data.ldf_page_id` is NULL (as it is for
   our fixture, and as it can plausibly be for production rows whose source
   metadata didn't carry a page_id), the row is dropped. The same join in
   the metadata step (line 107-111) is correctly `LEFT OUTER JOIN`. The
   inconsistency is the bug.

## Comparison to Bug #5

The README's index hypothesized this was the same root cause as Bug #5
(`TMP_F_PAGE_CASE` family, WITH(NOLOCK)/transaction-isolation visibility
from inside the SP scope). It is not.

| Aspect | Bug #5 (TMP_F_PAGE_CASE) | Bug #7 (TMP_LDF_DATA) |
| --- | --- | --- |
| Symptom | TMP step returns 0 from inside SP, same query returns rows outside | Step 3 never runs; SP exits at step 2 |
| Root cause | Suspected NOLOCK/snapshot visibility | Early-RETURN guard treats filter-out as "missing NRT" |
| Same query manual? | Returns rows outside SP | Step 3 query, replicated outside SP, ALSO returns 0 (INNER JOIN drops NULL ldf_page_id rows). Becomes 5 only if the join is changed to LEFT JOIN. |
| Fix locale | Possibly BEGIN TRAN / READ COMMITTED SNAPSHOT setting | One-line guard tightening + one-line JOIN change in the SP body |

So Bug #7 is **logic bugs in the SP**, not a SQL Server isolation quirk.
Bug #5 still warrants its own root-cause investigation.

## Annotated walkthrough of the SP's TMP_LDF_DATA construction

`265-sp_nrt_ldf_dimensional_data_postprocessing-001.sql` lines 49-160:

### Step 1: `#LDF_UID_LIST` (line 49-72)

Splits `@ldf_id_list` on `,`. Returns N rows for N unique ldf_uids. **OK.**
Repro shows row_count=5 (matches our fixture).

### Step 2: `#LDF_META_DATA` (line 76-132)

```sql
SELECT a.ldf_uid, ...                        -- 14 columns from metadata
FROM dbo.nrt_odse_state_defined_field_metadata a WITH (NOLOCK)
LEFT OUTER JOIN dbo.nrt_srte_ldf_page_set page_set WITH (NOLOCK)
    ON page_set.ldf_page_id = a.ldf_page_id  -- LEFT OUTER (correct)
INNER JOIN #LDF_UID_LIST l ON l.ldf_uid = a.ldf_uid
WHERE
    (a.condition_cd IN (SELECT condition_cd FROM dbo.LDF_DATAMART_TABLE_REF WITH (NOLOCK))
     OR a.condition_cd IS NULL)
    AND a.business_object_nm IN ('PHC','BMD','NIP','HEP')
    AND a.data_type IN ('ST','CV','LIST_ST');   -- whitelist
```

Returns row_count=4 in our repro (one of the 5 ldf_uids has `data_type='SUB'`,
which is not in the whitelist).

**Note**: this step's `LEFT OUTER JOIN page_set ... ON ldf_page_id` is the
**correct** pattern. The author understood that page_set is optional. The
inconsistency at the later #LDF_DATA step is the bug.

### Lines 136-158: `@backfill_list` early-RETURN guard (THE PRIMARY BUG)

```sql
declare @backfill_list nvarchar(max);
SET @backfill_list =
(
    SELECT string_agg(t.value, ',')
    FROM (SELECT distinct TRIM(value) AS value FROM STRING_SPLIT(@ldf_id_list, ',')) t
    LEFT JOIN #LDF_META_DATA tmp ON tmp.ldf_uid = t.value
    WHERE tmp.ldf_uid is null
);

IF @backfill_list IS NOT NULL
BEGIN
    SELECT 0 AS public_health_case_uid, ...,
           'Missing NRT Record: sp_nrt_ldf_dimensional_data_postprocessing' AS stored_procedure,
           ...
    WHERE 1=1;
   RETURN;       -- <<<<<<<<<<<<<< exits the entire SP
END
```

**The bug**: `@backfill_list` is the set of ldf_uids in `@ldf_id_list` that
*didn't make it into `#LDF_META_DATA`*. The intent is "did we pass an ldf_uid
that doesn't have a metadata row at all? If so, signal upstream to backfill."
But "didn't make it into `#LDF_META_DATA`" includes:

- (a) ldf_uids with no metadata row at all, AND
- (b) ldf_uids with a metadata row that was filtered out by the WHERE clause
  (`condition_cd not in LDF_DATAMART_TABLE_REF`, `business_object_nm` not
  in the 4-tuple, or `data_type not in ('ST','CV','LIST_ST')`).

Case (b) is not a missing-NRT-record condition; it's a known, intentional
filter. But the guard cannot distinguish (a) from (b), so it treats both as
"abort and signal backfill," which is wrong for (b).

In our repro, the single ldf_uid with `data_type='SUB'` (LDF "subform" type,
intentionally not aggregated into LDF_DIMENSIONAL_DATA) flips
`@backfill_list` to non-NULL, causing the SP to RETURN before processing the
4 valid ldf_uids that *should* have produced LDF_DIMENSIONAL_DATA rows.

**Job_flow_log evidence** (from `repro.sql` Step 2):

| step_number | step_name | row_count |
| --- | --- | --- |
| 0 | SP_Start | 0 |
| 1 | GENERATING #LDF_UID_LIST TABLE | 5 |
| 2 | GENERATING #LDF_META_DATA | 4 |

Notice step 3 onwards are absent: the SP never logged them because it
RETURNed at line 157.

The result-set the SP returns is the "Missing NRT Record" payload from
lines 148-156:

```
public_health_case_uid | datamart | stored_procedure
0                      | Error    | Missing NRT Record: sp_nrt_ldf_dimensional_data_postprocessing
```

### Step "GENERATING #LDF_DATA" (line 619-671): what would happen if guard removed (THE SECONDARY BUG)

```sql
SELECT
    a.ldf_uid, a.active_ind, ...,
    page_set.code_short_desc_txt AS page_set,
    inv.cd AS phc_cd, ...
INTO #LDF_DATA
FROM dbo.nrt_ldf_data a WITH (NOLOCK)
INNER JOIN dbo.nrt_srte_LDF_PAGE_SET page_set WITH (NOLOCK)   -- <<<< INNER (bug)
    ON page_set.ldf_page_id = a.ldf_page_id
LEFT JOIN dbo.nrt_srte_Codeset c WITH (NOLOCK)
    ON a.code_set_nm = c.code_set_nm
INNER JOIN dbo.nrt_INVESTIGATION inv WITH (NOLOCK)
    on a.business_object_uid = inv.public_health_case_uid
INNER JOIN dbo.LDF_DATAMART_TABLE_REF b WITH (NOLOCK)
    ON inv.cd = b.condition_cd
INNER JOIN #LDF_UID_LIST l ON l.ldf_uid = a.ldf_uid
```

Compare the page_set join here to the same join at lines 107-111
(`#LDF_META_DATA` step):

| Step | Join type | Notes |
| --- | --- | --- |
| #LDF_META_DATA (line 108) | `LEFT OUTER JOIN` | correct |
| #LDF_DATA       (line 648) | `INNER JOIN`      | inconsistent; bug |

`nrt_ldf_data.ldf_page_id` may legitimately be NULL: the staging table is
populated from ODSE source events that don't always carry a page_id binding.
For our fixture all 5 rows have `ldf_page_id IS NULL` and they are correctly
dropped by the INNER JOIN. Replacing the INNER JOIN with LEFT JOIN gives 5
rows (proven by `repro.sql` Step 4).

## Comparison: same query inside SP vs outside SP

| Query                                | Inside SP | Outside SP (repro Step 4) |
| --- | --- | --- |
| Step 1 #LDF_UID_LIST                 | 5 rows | 5 rows |
| Step 2 #LDF_META_DATA                | 4 rows | 4 rows |
| Step 3 #LDF_DATA (SP version: INNER JOIN page_set) | (never runs) | **0 rows**; same join behavior outside SP. NOT a NOLOCK/isolation issue. |
| Step 3 #LDF_DATA (FIX version: LEFT JOIN page_set) | n/a | 5 rows |

This rules out the NOLOCK/transaction-isolation hypothesis: the same query
returns 0 outside the SP too. The bug is in the join semantics.

## Suggested fix

Two-part fix in `265-sp_nrt_ldf_dimensional_data_postprocessing-001.sql`:

### Fix 1 (primary; tightens the early-RETURN guard): lines 136-158

Change `@backfill_list` to look at `nrt_odse_state_defined_field_metadata`
existence *directly*, not at `#LDF_META_DATA` membership. That way data_type
filtering doesn't cause false-positive "missing NRT" signals.

```diff
@@ -136,12 +136,14 @@
         declare @backfill_list nvarchar(max);
         SET @backfill_list =
         (
             SELECT string_agg(t.value, ',')
             FROM (SELECT distinct TRIM(value) AS value FROM STRING_SPLIT(@ldf_id_list, ',')) t
-                left join #LDF_META_DATA tmp
-                on tmp.ldf_uid = t.value
-                WHERE tmp.ldf_uid is null
+                LEFT JOIN [dbo].nrt_odse_state_defined_field_metadata md WITH (NOLOCK)
+                    ON md.ldf_uid = t.value
+                WHERE md.ldf_uid IS NULL
         );
```

This means the guard fires only when an ldf_uid genuinely has no metadata row
in the source (true "needs backfill"), not when the metadata row exists but is
filtered out by the SP's own whitelist.

### Fix 2 (secondary; harmonizes the join): line 648

Change the INNER JOIN to LEFT JOIN for consistency with line 108:

```diff
@@ -647,7 +647,7 @@
         INTO #LDF_DATA
         FROM [dbo].nrt_ldf_data a WITH (NOLOCK)
-        INNER JOIN
+        LEFT JOIN
         dbo.nrt_srte_LDF_PAGE_SET page_set WITH ( NOLOCK)
         ON
         page_set.ldf_page_id =a.ldf_page_id
```

With both fixes, the repro EXEC would proceed past step 2 and populate
LDF_DIMENSIONAL_DATA with the 4 valid (non-SUB) rows.

## Workaround for comparison-fixtures

In the meantime, the fixture-side workaround is to either:

(a) Filter `nrt_ldf_data` rows down to only those whose metadata data_type is
    in `('ST','CV','LIST_ST')` before calling the SP, OR
(b) Populate `nrt_ldf_data.ldf_page_id` from the metadata row when authoring
    fixture answers, AND drop the `data_type='SUB'` row from the input list.

(a) is cleaner; the orchestrator can compute the safe ldf_uid sub-list and
pass that. It does not require modifying RTR routines.

## Reproduction

See `repro.sql` in this directory. Run with:

```sh
export SQLCMDPASSWORD=PizzaIsGood33!
sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN -i repro.sql
```

Expected output:
- Step 1: pre-conditions confirm 5 nrt_ldf_data rows, 5 matching metadata rows,
  empty LDF_DIMENSIONAL_DATA, and the `data_type='SUB'` row that triggers
  the bug.
- Step 2: SP EXECs, returns "Missing NRT Record" payload, job_flow_log shows
  only steps 0-2.
- Step 3: backfill_list = `10001977` (the SUB row); metadata for 10001977
  exists with `data_type='SUB'` (proves it's not "missing", it's filtered).
- Step 4: Manual replication shows step 3 (SP version) = 0 rows; step 3
  (LEFT JOIN fix version) = 5 rows.
