# Bug #5 — TMP_F_PAGE_CASE family: original premise was wrong

**Status**: Investigation complete. The original "bug #5 is a shared
transaction-isolation issue across 10 condition-datamart SPs" hypothesis
**did not survive investigation**. Two distinct issues were uncovered;
neither is what the brief described.

## Headline

- **Bug 5a (real, RTR-side, single SP, logging-only)**: in
  `sp_hepatitis_datamart_postprocessing` only, the `job_flow_log`
  `row_count` for step 3 ("Generating  #TMP_F_PAGE_CASE") is always
  logged as `0`. **The temp table itself IS correctly populated.**
  Downstream steps see the rows. The `0` is a logging defect caused by
  an `IF @debug='true' SELECT ...` statement positioned between
  `SELECT INTO` and the `SELECT @ROWCOUNT_NO = @@ROWCOUNT` capture —
  the IF resets `@@ROWCOUNT` to 0 even when @debug is false (the
  predicate-only path).

- **Bug 5b (fixture-side, the real reason HEPATITIS_DATAMART stays
  empty)**: `nrt_investigation.patient_id = NULL` for the foundation
  Investigation 20000100. This cascades through F_PAGE_CASE's
  `COALESCE(PATIENT.PATIENT_KEY, 1)` to sentinel PATIENT_KEY=1, which
  has PATIENT_UID=NULL. The hepatitis_datamart SP at line 2149 has
  `DELETE FROM #TMP_HEPATITIS_CASE_BASE WHERE PATIENT_UID IS NULL`,
  which removes the row before INSERT.

- **Brief was wrong about scope**: only
  `sp_hepatitis_datamart_postprocessing` references `#TMP_F_PAGE_CASE`
  (20 occurrences). The other 9 SPs in the original brief have **0
  references** — they use entirely different temp-table structures
  (`#S_PHC_LIST`, `#S_INVESTIGATION_LIST`, `#PATIENT`). Their 0-row
  symptoms are unrelated to this bug and need separate investigation.

## Hypotheses tested and ruled out

| H | Hypothesis | Result |
|---|---|---|
| 1 | Snapshot isolation / RCSI | Ruled out — `snapshot_isolation_state=0`, `is_read_committed_snapshot_on=0` |
| 2 | BEGIN TRANSACTION step scoping | Ruled out — each step COMMITs before the next; downstream steps see #TMP_F_PAGE_CASE rows |
| 3 | WITH(NOLOCK) interaction with in-flight tx | Ruled out — F_PAGE_CASE was committed long before the SP ran |
| 4 | STRING_SPLIT vs CASE_UID type conversion | Ruled out — manual query with identical SQL returns the row |
| 5 | Stale plan / parameter sniffing | Ruled out — toggling only `@debug` flips the logged count, which a plan issue can't do |
| 6 | `IF @debug='true' SELECT ...` resets `@@ROWCOUNT` | **CONFIRMED** in isolated test |

## Bug 5a smoking-gun evidence

SP source at `liquibase-service/src/main/resources/db/005-rdb_modern/routines/013-sp_hepatitis_datamart_postprocessing-001.sql` lines 95-111:

```sql
SELECT ... INTO #TMP_F_PAGE_CASE FROM ...;     -- @@ROWCOUNT = 1
IF @debug ='true' SELECT * FROM #TMP_F_PAGE_CASE;  -- predicate-only path resets @@ROWCOUNT to 0
SELECT @ROWCOUNT_NO = @@ROWCOUNT;              -- captures 0 (in production)
```

Direct test (repro Step 3): `rowcount_when_debug_false=0`,
`rowcount_when_debug_true=3`, both temp tables have 3 rows.

Side-by-side SP runs (repro Steps 4a vs 4b): step 3 logs `0` vs `1`,
but **every downstream step (4-18) logs row_count=1 in both runs**,
proving the temp table is identically populated.

This same antipattern does **not** appear in step 2 of the SP
(TMP_CONDITION) — which is why step 2 logs the correct count (3). It
also does **not** appear in any of the other 9 family SPs (verified
via `grep`). It is unique to step 3 of
`sp_hepatitis_datamart_postprocessing`.

## Bug 5b chain (the actual blocker for HEPATITIS_DATAMART population)

1. `nrt_investigation.patient_id = NULL` (foundation Inv 20000100).
2. `sp_f_page_case_postprocessing` line 142: `COALESCE(PATIENT.PATIENT_KEY, 1)` falls back to sentinel.
3. `D_PATIENT.PATIENT_KEY=1` has `PATIENT_UID=NULL` (by design — sentinel "unknown" row).
4. `#TMP_D_Patient.PATIENT_UID = NULL`.
5. `#TMP_HEPATITIS_CASE_BASE.PATIENT_UID = NULL`.
6. SP line 2149: `DELETE FROM #TMP_HEPATITIS_CASE_BASE WHERE PATIENT_UID IS NULL` removes the row.
7. HEPATITIS_DATAMART INSERT runs against an empty source → 0 rows.

## Implications for the rest of the project

The original premise — "fixing #5 unblocks ~10 condition datamarts" —
is **wrong**. Each of the other 9 SPs in the original brief has its own
distinct 0-row reason that needs separate investigation:

- `sp_tb_datamart_postprocessing` (file 255)
- `sp_var_datamart_postprocessing` (file 250)
- `sp_covid_case_datamart_postprocessing` (file 310)
- `sp_pertussis_case_datamart_postprocessing` (file 043)
- `sp_measles_case_datamart_postprocessing` (file 033)
- `sp_rubella_case_datamart_postprocessing` (file 031)
- `sp_std_hiv_datamart_postprocessing` (file 026)
- `sp_bmird_strep_pneumo_datamart_postprocessing` (file 140)
- `sp_crs_case_datamart_postprocessing` (file 032)

Likely candidates to investigate:
- Each may have its own variant of bug 5b (sentinel-key-cascade-to-delete)
- Some may have analogous logging defects to bug 5a
- Some may be condition-gated and just have no matching data even after
  multi-condition fan-out (because v3+ Investigations were authored as
  pure nrt_investigation rows without backing nrt_patient/nrt_provider
  cross-subject staging)

## Suggested fixes

### Fix 5a (RTR, one-line)

Swap order of lines 108 and 111 in
`013-sp_hepatitis_datamart_postprocessing-001.sql` so
`SELECT @ROWCOUNT_NO = @@ROWCOUNT` runs **before** the `IF @debug`
block. This matches the order used by every other step in the file and
every other SP in the family.

```diff
@@ -105,11 +105,11 @@
         FROM dbo.F_PAGE_CASE WITH(NOLOCK)
         ...
         ;
+
+        SELECT @ROWCOUNT_NO = @@ROWCOUNT;

         IF @debug ='true' SELECT * FROM #TMP_F_PAGE_CASE;

-
-        SELECT @ROWCOUNT_NO = @@ROWCOUNT;
-
         INSERT INTO [DBO].[JOB_FLOW_LOG] ...
```

No behavior change beyond fixing the log.

### Fix 5b (fixture-side)

Add a Tier-3 fixture: `UPDATE dbo.nrt_investigation SET patient_id =
20000000 WHERE public_health_case_uid = 20000100;` then re-run
`sp_nrt_investigation_postprocessing → sp_f_page_case_postprocessing →
sp_hepatitis_datamart_postprocessing`. The patient_id needs to point at
a real `nrt_patient.patient_uid` so D_PATIENT has a non-sentinel row.

This is fixture-side, not RTR-side. The original Investigation Tier 1
fixture authoring left `nrt_investigation.patient_id` NULL by design
(the comment in `coverage_investigation.md` notes: "All cross-subject
UID columns on nrt_investigation are left NULL on both variants —
INVESTIGATION dimension does not directly read them; they feed
downstream consumers via Tier 2 connective rows"). That assumption
was correct for INVESTIGATION but wrong for the downstream Datamart
chain — the Datamart SPs read `nrt_investigation.patient_id` directly
to drive PATIENT_KEY resolution in F_PAGE_CASE.

## Reproduction

See `repro.sql` in this directory. 6 steps, idempotent, verified
end-to-end on the merged-fixture DB state:

0. Print snapshot-isolation state (rules out RCSI).
1. Idempotently regenerate F_PAGE_CASE (so step 3+ have something to read).
2. Run the manual TMP_F_PAGE_CASE query — returns `3|6|1` (1 row).
3. Demonstrate the `@@ROWCOUNT`-after-IF bug in isolation — returns
   `0|3` (rowcount=0 when @debug=false; rowcount=3 when @debug=true).
4a. EXEC SP with `@debug=0` — step 3 logs `0`, downstream steps log `1`.
4b. EXEC SP with `@debug=1` — step 3 logs `1`, downstream steps log
    `1` (identical).
5. Trace bug 5b chain (nrt_investigation.patient_id NULL → sentinel →
   DELETE).
6. Confirm only `sp_hepatitis_datamart_postprocessing` uses
   #TMP_F_PAGE_CASE (20 refs vs 0 for the other 9 SPs).

```sh
export SQLCMDPASSWORD=PizzaIsGood33!
sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN -i repro.sql
```
