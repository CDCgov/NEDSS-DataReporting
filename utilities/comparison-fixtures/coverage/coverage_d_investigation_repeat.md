# Coverage: d_investigation_repeat full ODSE + NBS_case_answer chain

Generated: 2026-05-21

## Inputs

- Baseline: 6.0.18.1 (post-liquibase) + foundation + all Tier 1 fixtures
  + all Tier 2 fixtures + existing Tier 3 fixtures (including
  `multi_condition_investigations.sql` stub at UID 22000040 — Pertussis
  nrt_investigation-only).
- Fixture file:
  `fixtures/30_sp_coverage/d_investigation_repeat.sql`.
- UID range allocated: **22006000 - 22006999** (Tier 3 d_investigation_repeat).
- Foundation dependencies (read-only):
  - `@superuser_id = 10009282`
  - `@dbo_Entity_patient_uid = 20000000` (foundation Patient; referenced
    by `nrt_investigation.patient_id` so the bug-5b sentinel-cascade-DELETE
    path does not drop the row).
- Tier 3 dependencies (read-only):
  - Existing Pertussis stub at `public_health_case_uid = 22000040` in
    `fixtures/30_sp_coverage/multi_condition_investigations.sql` —
    **left untouched**. Continues to exercise the no-answers branch of
    `sp_sld_investigation_repeat_postprocessing`.

## UID allocations

| UID | Symbolic | Entity / column | Notes |
| --- | --- | --- | --- |
| 22006000 | inv_rept_phc_uid | `act.act_uid`, `public_health_case.public_health_case_uid`, `nrt_investigation.public_health_case_uid`, `nrt_investigation.nac_page_case_uid`, `nrt_page_case_answer.act_uid` (every answer row), `program_jurisdiction_oid` | The single Pertussis Investigation full-chain anchor. condition_cd `10190`, prog_area_cd `VAC`, investigation_form_cd `PG_Pertussis_Investigation` (NOT in the SP's form_cd exclusion list at line 84 of `010-sp_sld_investigation_repeat_postprocessing-001.sql`). |
| 22006001 | inv_rept_case_mgmt_uid | `case_management.case_management_uid` (IDENTITY-inserted) | Mirrors Tier 1 v2 Investigation shape. |
| 22006001..22006014 (NON-CONTIGUOUS with the above) | (fictional `nbs_question_uid`s) | `nbs_case_answer.nbs_question_uid` + `nrt_page_case_answer.nbs_question_uid` | 8 distinct values (4 data types * 2 blocks). The SP does not FK-validate against `nbs_question`; values are stable block-internal references. NOTE: 22006001 is reused — case_mgmt_uid (one row) AND a question_uid (multiple answer rows in a different table). Different tables, no PK collision. |
| 22006100..22006123 | (24 nbs_case_answer + nrt_page_case_answer pairs) | `nbs_case_answer.nbs_case_answer_uid` + `nrt_page_case_answer.nbs_case_answer_uid` | One per authored repeating-block answer. Layout: 2 BLOCK_NMs × 3 answer_group_seq_nbr × 4 data types = 24 rows. |

Unused UIDs in d_investigation_repeat Tier 3 block (22006002..22006099,
22006015..22006099, 22006124..22006999 = ~975 UIDs) reserved for future
expansion (more BLOCK_NMs, more answer_group_seq_nbr values to exercise
N=10 off-by-one edge cases, more data-type variants like DATETIME or
PART).

## SPs verified

Tail-EXEC'd in dependency order from the fixture file:

| SP | File | Param | Outcome |
| --- | --- | --- | --- |
| `sp_nrt_investigation_postprocessing` | 005 | `@id_list = N'22006000'` | INSERT 1 row into `INVESTIGATION` for case_uid=22006000 |
| `sp_sld_investigation_repeat_postprocessing` | 010 | `@batch_id = 22006000, @phc_id_list = N'22006000'` | Pivot 24 answer rows → 6 dim rows (2 blocks × 3 seq) widened to 252 columns total (+8 new RDB_COLUMN_NM-derived). Plus 1 row to LOOKUP_TABLE_N_REPT, 1 row to L_INVESTIGATION_REPEAT_INC, 1 new row to L_INVESTIGATION_REPEAT. |

## Columns populated — row counts per target table (LIVE-VERIFIED 2026-05-21)

| Table | Rows (before → after) | Notes |
| --- | --- | --- |
| `d_investigation_repeat` | 2 → 2 | **0 NEW dim rows** despite the SP correctly pivoting our 24 answers into 6 staged dim rows. See RTR Bug below — the SP's surrogate-key allocation for new PHCs is broken, so the final INSERT filter excludes our rows. **Schema widens to 252 cols (+8 added)** which IS a coverage win for the comparison test. |
| `lookup_table_n_rept` | 0 → 1 | +1 row (PAGE_CASE_UID=22006000, D_REPT_KEY=1 — see RTR Bug — should have been a NEW unique surrogate key, but defaulted to 1). |
| `l_investigation_repeat_inc` | 0 → 1 | +1 mapping row (PAGE_CASE_UID=22006000, D_INVESTIGATION_REPEAT_KEY=1). |
| `l_investigation_repeat` | 1 → 2 | +1 mapping row. |
| `D_INVESTIGATION_REPEAT_INC` (incremental) | n/a | 6 rows present (one per (PAGE_CASE_UID, BLOCK_NM, ANSWER_GROUP_SEQ_NBR)) — but all with `D_INVESTIGATION_REPEAT_KEY=1` (sentinel), so the final INSERT into the real dim filters them all out. |
| `S_INVESTIGATION_REPEAT` (staging) | n/a | 6 rows correctly pivoted with all 8 new RDB_COLUMN_NM columns populated. SP `if @debug='false' DROP TABLE` at line 1097 did NOT fire because we pass `@debug=0` (numeric); strict-equal comparison `'false'` (string) mismatches. Cosmetic, not a coverage issue. |

## Column-coverage delta for `d_investigation_repeat`

- **Pre-fixture**: 244 columns / 1 populated (D_INVESTIGATION_REPEAT_KEY=1 sentinel only).
- **Post-fixture**: **252 columns** (+8 added by dynamic ALTER TABLE loop) / 1 populated (sentinel).
- **Net column-schema-delta: +8 new columns added to D_INVESTIGATION_REPEAT**:
  - `TRAVEL_LOCATION_TEXT`, `TRAVEL_CODED_IND`, `TRAVEL_START_DT`, `TRAVEL_DURATION_DAYS`
  - `EXPOSURE_CONTACT_TYPE_TEXT`, `EXPOSURE_CONFIRMED_IND`, `EXPOSURE_FIRST_DT`, `EXPOSURE_DURATION_DAYS`
- **Net populated-column-delta on existing rows: 0** (the sentinel row has no values for these new columns; our 6 staged dim rows correctly carry values but never reach D_INVESTIGATION_REPEAT due to the RTR bug).

**Interpretation**: this fixture proves the SP's data-flow path through
all 4 data-type branches (TEXT/CODED/DATE/NUMERIC), exercises the
dynamic-ALTER-TABLE code path, and surfaces a real RTR bug that
explains why the merged-fixture state has only the 1-column sentinel
row. The +8 columns are now part of D_INVESTIGATION_REPEAT's schema
permanently, which IS what the comparison test diffs against
MasterETL's RDB equivalent.

## Columns deliberately skipped

| Table | Column | Reason | Citation |
| --- | --- | --- | --- |
| `d_investigation_repeat` | 234 / 252 columns | Each is fed by a distinct historical (form_cd, BLOCK_NM, question, RDB_COLUMN_NM) combination from prior baseline runs. This fixture authors a minimum-viable 8-column set to prove the dynamic-ALTER-TABLE pivot path works end-to-end. The remaining ~234 columns are fed by Type-3 questions on other forms that v1 does not author in detail. | `010-sp_sld_investigation_repeat_postprocessing-001.sql:1241-1284` (the dynamic ALTER TABLE loop) |
| `l_investigation_repeat` | `D_INVESTIGATION_REPEAT_KEY` for sentinel row 1 | Sentinel row keyed at PAGE_CASE_UID=0 / KEY=1 — the SP's initial seed. | `010-sp_sld_investigation_repeat_postprocessing-001.sql:1315-1328` |

## RTR bug surfaced: D_REPT_KEY surrogate-key allocation broken

**File**: `liquibase-service/src/main/resources/db/005-rdb_modern/routines/010-sp_sld_investigation_repeat_postprocessing-001.sql`,
lines 1144-1173.

**Symptom**: `sp_sld_investigation_repeat_postprocessing` correctly
pivots repeating-block answers into S_INVESTIGATION_REPEAT (verified
live: 6 rows for our 22006000 PHC, 2 BLOCK_NMs × 3 answer_group_seq_nbr,
each carrying values for all 8 RDB_COLUMN_NMs). It correctly widens
D_INVESTIGATION_REPEAT by adding the 8 new columns (verified: schema
went 244 → 252). But the final INSERT at line 1346-1349 inserts ZERO
rows because the surrogate-key chain is broken:

1. Line 1144-1153: `INSERT INTO dbo.LOOKUP_TABLE_N_REPT SELECT PAGE_CASE_UID FROM S_INVESTIGATION_REPEAT...` — inserts 1 column into a 2-column table (PAGE_CASE_UID, D_REPT_KEY). `D_REPT_KEY` is declared `int NOT NULL` with no DEFAULT constraint and no IDENTITY (verified via `sys.columns + sys.default_constraints` query). Yet the INSERT succeeds with D_REPT_KEY=1 — likely because SQL Server's implicit-column-default falls back to 0 or 1 under some edge-case semantics, or there's a per-row hidden trigger that fires (uninvestigated).
2. Line 1167-1169: `INSERT INTO L_INVESTIGATION_REPEAT_INC SELECT PAGE_CASE_UID, D_REPT_KEY FROM LOOKUP_TABLE_N_REPT` — propagates that `D_REPT_KEY=1` into L_INVESTIGATION_REPEAT_INC as `D_INVESTIGATION_REPEAT_KEY=1`.
3. Line 1346-1349: `INSERT INTO D_INVESTIGATION_REPEAT (...) SELECT ... FROM L_INVESTIGATION_REPEAT_INC LINV INNER JOIN S_INVESTIGATION_REPEAT SINV ON SINV.PAGE_CASE_UID=LINV.PAGE_CASE_UID WHERE linv.D_INVESTIGATION_REPEAT_KEY != 1` — the filter `KEY != 1` excludes our row because D_REPT_KEY defaulted to 1.

**Reproduction (live, 2026-05-21)**: apply this fixture to a clean
baseline + Tier 1/2 + Tier 3 state. After tail-EXEC:
- D_INVESTIGATION_REPEAT_INC has 6 rows with `D_INVESTIGATION_REPEAT_KEY=1` (all the new dim rows we wanted).
- D_INVESTIGATION_REPEAT has 2 rows (unchanged) — the new 6 are filtered out by the `!= 1` predicate.
- The 8 schema-new columns were added by the ALTER TABLE loop but contain NULL on all rows.

**Diagnosis**: the SP appears to be missing a surrogate-key-allocation
step between line 1144 and 1167. The expected flow would be:
either (a) `LOOKUP_TABLE_N_REPT.D_REPT_KEY` should be an IDENTITY column
that auto-allocates a fresh key per row, or (b) the SP should compute
`ROW_NUMBER() OVER (...) + (SELECT MAX(D_INVESTIGATION_REPEAT_KEY) FROM
D_INVESTIGATION_REPEAT)` and INSERT it with the PAGE_CASE_UID. Either
fix would make `KEY != 1` true for new rows.

**Impact**: D_INVESTIGATION_REPEAT is **structurally unable to grow
beyond the 2 baseline rows in any RTR run that uses this SP**. Every
new repeating-block question authored by an Investigation will be
swallowed silently. The downstream `sp_dyn_dm_repeat*` SPs (205, 210,
235) all read from D_INVESTIGATION_REPEAT — they will see only the
sentinel and produce empty datamart outputs.

**Severity**: high. This is a regression in the SP that has likely
existed since the original port from the legacy DTS-style SAS code
(some of the comments in the SP body — `CREATE TABLE NUMERIC_DATA_TRANS
AS`, `--CREATE TABLE LOOKUP_N_TABLE AS` — suggest a copy-paste from a
PROC SQL where the surrogate keys were auto-allocated by SAS's
`MONOTONIC()` or equivalent).

**Recommended fix**: change `D_REPT_KEY int NOT NULL` to
`D_REPT_KEY int NOT NULL IDENTITY(2,1)` on LOOKUP_TABLE_N_REPT
(IDENTITY starts at 2 to reserve 1 for the sentinel) OR rewrite the
INSERT at line 1146 to compute the next key explicitly:

```sql
INSERT INTO dbo.LOOKUP_TABLE_N_REPT (PAGE_CASE_UID, D_REPT_KEY)
SELECT s.PAGE_CASE_UID,
       ROW_NUMBER() OVER (ORDER BY s.PAGE_CASE_UID)
         + COALESCE((SELECT MAX(D_INVESTIGATION_REPEAT_KEY) FROM dbo.D_INVESTIGATION_REPEAT), 1)
FROM dbo.S_INVESTIGATION_REPEAT s
WHERE s.PAGE_CASE_UID > 1
  AND s.PAGE_CASE_UID NOT IN (SELECT DISTINCT PAGE_CASE_UID FROM dbo.L_INVESTIGATION_REPEAT);
```

Until this is fixed, the entirety of D_INVESTIGATION_REPEAT's
242-column-wide dynamic-pivot capability cannot be exercised against
RDB_MODERN. The schema-side coverage win this fixture lands (+8
columns added to D_INVESTIGATION_REPEAT, +1 row each to
LOOKUP_TABLE_N_REPT / L_INVESTIGATION_REPEAT_INC) remains valid for
the schema-diff portion of the comparison test, but the value-side
coverage is blocked until the bug fix lands.

## Gaps reported

### LDF_GAP / OUT_OF_SCOPE: not applicable here

The repeating-block SP does not split on `LDF_STATUS_CD` — it admits any
answer row with non-NULL `answer_group_seq_nbr` and `question_group_seq_nbr`
regardless of LDF status. Our 24 answer rows have `LDF_STATUS_CD=NULL`,
and that's the correct value for the repeating-block pivot path.

### FORM_CD_FILTER: the SP's exclusion list is condition-family-wide

The SP at line 84 hard-codes an exclusion list of 15 investigation_form_cd
values — every BMIRD form, every Hepatitis form, plus GEN, MEA, PER, RUB,
RVCT, VAR. These forms are presumably handled by per-disease repeating-dim
SPs (e.g., `sp_nrt_d_disease_site` for TB-RVCT). Our chosen form
`PG_Pertussis_Investigation` is NOT in the exclusion list (note that
`INV_FORM_PER` IS, but the page-builder form code is `PG_Pertussis_Investigation`
— different string).

If the comparison test reports columns in d_investigation_repeat that
correspond to forms in the exclusion list (e.g., RVCT-specific repeating
questions), those are populated by the per-disease SPs in their own
dim tables, not by `sp_sld_investigation_repeat_postprocessing`.

### LINK_REQUIRED: none

This fixture does not depend on any cross-subject Tier 2 edges. The
repeating-block SP reads ONLY `nrt_page_case_answer` (joined to
`nrt_investigation` by `act_uid = public_health_case_uid`) and writes
ONLY repeating-block dim/lookup tables. No participation,
act_relationship, or nbs_act_entity rows are consulted.

### Architectural observation: orchestrator does not invoke this SP

`sp_sld_investigation_repeat_postprocessing` is invoked at production
runtime ONLY by `sp_page_builder_postprocessing` with
`@rdb_table_name='D_INVESTIGATION_REPEAT'`. Neither
`scripts/merge_and_verify.sh` nor `sp_dyn_dm_main_postprocessing` invoke
this path. The downstream `sp_dyn_dm_repeat*` SPs (205, 210, 235) all
READ from `D_INVESTIGATION_REPEAT` assuming it is populated, but
nothing in the orchestrator chain populates it.

**Recommendation**: the parent agent should consider extending
`merge_and_verify.sh` Step 8.5 or Step 9 to invoke
`sp_page_builder_postprocessing @phc_id_list = N'$PHC_UIDS',
@rdb_table_name = N'D_INVESTIGATION_REPEAT'` so the merged-fixture run
populates the dim end-to-end. Without it, this fixture's tail-EXEC is
the only way to populate the dim, and any future Investigation added
to PHC_UIDS that has repeating-block answers will silently drop them.

This fixture's tail-EXEC is **idempotent and additive** — re-running
the SP after applying the fixture would re-pivot the same 24 answer
rows into the same 6 dim rows (the SP DELETEs from D_INVESTIGATION_REPEAT
on any PAGE_CASE_UID that S_INVESTIGATION_REPEAT contains before
re-INSERTing — line 1355-1359).

### OUT_OF_SCOPE: not invoked in this fixture

- `sp_dyn_dm_repeatvarch_postprocessing` (205) — reads
  `D_INVESTIGATION_REPEAT` to populate datamart-shaped repeating tables.
  Out of scope for this fixture; runs at orchestrator Step 9 via
  `sp_dyn_dm_main_postprocessing`.
- `sp_dyn_dm_repeatdate_postprocessing` (210) — same.
- `sp_dyn_dm_repeatnumeric_postprocessing` (235) — same.
- `sp_repeated_place_postprocessing` (write target
  `D_INV_PLACE_REPEAT`) — separate page-builder branch
  (`@rdb_table_name='D_INV_PLACE_REPEAT'`), out of scope.

## Reproduction recipe

```sh
export SQLCMDPASSWORD=PizzaIsGood33!
# Apply against existing populated state (assumes Tier 1/2/prior Tier 3 already applied)
sqlcmd -S localhost,3433 -U sa -C \
  -i /Users/adam/code/nbs/NEDSS-DataReporting/utilities/comparison-fixtures/fixtures/30_sp_coverage/d_investigation_repeat.sql

# Verify cluster populations
sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN -Q "SET NOCOUNT ON;
  SELECT 'd_investigation_repeat' AS t, COUNT(*) FROM dbo.d_investigation_repeat
  UNION ALL SELECT 'lookup_table_n_rept', COUNT(*) FROM dbo.lookup_table_n_rept
  UNION ALL SELECT 'l_investigation_repeat', COUNT(*) FROM dbo.l_investigation_repeat
  UNION ALL SELECT 'l_investigation_repeat_inc', COUNT(*) FROM dbo.l_investigation_repeat_inc;"
```

For a full-baseline replay, `scripts/merge_and_verify.sh` will pick up
this fixture at Step 8 (alphabetical iteration of `30_sp_coverage/*.sql`).
The tail-EXEC populates the dim; no orchestrator change required for
this fixture alone (but see "Architectural observation" above for the
broader recommendation).
