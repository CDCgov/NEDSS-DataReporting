# Tier 1 — Morbidity Report

You are a Tier 1 sub-agent. Your subject is **Morbidity Report**.

Read `prompts/templates/tier_1_subject.md` first — that's the shared
contract. This file fills in subject-specific slots.

Morbidity shares the event SP with Lab (`sp_observation_event` —
different `obs_domain_cd`). Read Lab's fixture (`fixtures/10_subjects/lab.sql`)
and coverage report first — the staging-row authoring pattern, the
LOINC code grounding, and the multi-observation-hierarchy structure
all carry over.

## Subject identity

- **Subject name:** morbidity (a.k.a. morbidity_report)
- **Foundation row:** `@dbo_Act_morbidity_uid = 20000130`
  (`act.act_uid`, `observation.observation_uid`); class `OBS`,
  mood `EVN`, `obs_domain_cd_st_1='Order'`. Foundation has many
  observation columns NULL (Tier 1 deferred).
- **Foundation Patient:** `@dbo_Entity_patient_uid = 20000000`
  (referenced by morbidity as the subject — `observation.subject_person_uid`).
- **No internal locators.** Morbidity is an Act, not an Entity.
- **Your UID block:** `20080000–20089999` per `catalog/uid_ranges.md`.
  Update the registry with your final allocation.

## SP chain

- Event SP: `dbo.sp_observation_event @obs_id_list nvarchar(max)`
  - File: `liquibase-service/src/main/resources/db/005-rdb_modern/routines/055-sp_observation_event-001.sql`
  - **Same event SP as Lab.** Filter difference is `obs_domain_cd_st_1`
    + the observation-class linkage. Read Lab's coverage_lab.md for
    the working pattern.
- Postprocessing SP: `dbo.sp_d_morbidity_report_postprocessing @pMorbidityIdList, @debug = 0`
  - File: `routines/016-sp_nrt_morbidity_report_postprocessing-001.sql`
    (filename uses `nrt_morbidity_report_postprocessing` but the SP
    inside is named `sp_d_morbidity_report_postprocessing` — match the
    SP name when invoking).
  - **Param name is `@pMorbidityIdList` (camelCase, "p" prefix).**
    Yet another convention. Don't guess — match the literal.
- **NOT in scope:**
  - `sp_morbidity_report_datamart_postprocessing` (file 048) — datamart
    SP, populates `MORBIDITY_REPORT_DATAMART` (133 cols). Tier 2/3
    territory.

## RDB_MODERN target tables

Per `catalog/rtr_target_columns.md` and live schema:

- `dbo.MORBIDITY_REPORT` — primary write target. **Live: 30 cols /
  catalog: 31** (close drift). Read the catalog's per-table breakdown.
- `dbo.MORBIDITY_REPORT_EVENT` — fact table. Live: 17 cols / catalog: 16.
  Mostly cross-subject FK keys (PATIENT_KEY, INVESTIGATION_KEY, etc.)
  that COALESCE to sentinel keys when joins miss — **no FK constraints
  on this table**, so isolation should work cleanly.
- `dbo.Morbidity_Report` (case-difference) — sentinel row at
  morb_rpt_KEY=1 self-bootstrapped by the SP at line 1144. Don't
  hand-write.
- `dbo.nrt_observation` — synthetic staging row(s). Same shape as Lab's
  staging.
- Several `nrt_*_key` surrogate-key stores; **do not hand-write**.

## Side-effect: UPDATE to LAB_TEST_RESULT

The Morbidity postprocessing SP at line 335 contains:
```sql
UPDATE dbo.LAB_TEST_RESULT
SET morb_rpt_key = 1, RDB_LAST_REFRESH_TIME = GETDATE()
WHERE morb_rpt_key IN ( ... morb reports without investigations ... )
```

This is a **back-prop UPDATE** — it disassociates Lab results from
morbidity reports that lost their investigation. At Tier 1 isolation
this is a no-op (LAB_TEST_RESULT.morb_rpt_key is NULL on all rows
because no morbidity has linked yet). Safe to ignore for coverage; just
don't be surprised if you see this UPDATE in the SP body.

## Cross-subject dependencies

Most cross-subject FK keys in MORBIDITY_REPORT_EVENT are COALESCEd:
- `INVESTIGATION_KEY = COALESCE(tmp.INVESTIGATION_KEY, 1)` ✓
- `HSPTL_KEY = COALESCE(tmp.HSPTL_KEY, 1)` ✓
- `MORB_RPT_SRC_ORG_KEY = COALESCE(tmp.MORB_RPT_SRC_ORG_KEY, 1)` ✓
- `REPORTER_KEY = COALESCE(tmp.REPORTER_KEY, 1)` ✓

Two are NOT COALESCEd (see SP lines 1155, 1167):
- `PATIENT_KEY = tmp.PATIENT_KEY` — no fallback. If LEFT JOIN to
  D_PATIENT misses, this is NULL. **Spot-check whether Morbidity's
  `nrt_observation` driver row has `subject_person_uid=20000000`
  (foundation Patient), and whether a baseline-seeded D_PATIENT row
  matches.** If neither, document as `LINK_REQUIRED`.
- `LDF_GROUP_KEY = tmp.LDF_GROUP_KEY` — LDF (local data field) coverage
  is owned by `sp_nrt_ldf_postprocessing`, separate chain. NULL on
  Tier 1 is expected and OK (no NOT-NULL constraint on the column).

## Variant strategy (apply the template's two-variant pattern)

- **Foundation Morbidity enrichment**: hang additive child rows off
  `@dbo_Act_morbidity_uid = 20000130`. Likely needs a single
  observation row plus the `nrt_observation` staging entry.
- **v2 Morbidity**: a separate fully-attributed Morbidity Report in
  your block (e.g., UID 20080010). Set every observation/morbidity
  column the postprocessing SP reads. Use the **same `condition_cd='10110'`
  (Hep A acute) as Lab and Investigation** for v1 consistency per
  STRATEGY.md (single-condition-per-family at v1).

Morbidity reports may or may not have a multi-observation hierarchy
like Lab does. Read the SP body to decide. Most morbidity reports are
single-observation (no result-children).

## Forbidden (inherited from template, repeated for clarity)

- **No cross-subject `act_relationship`, `participation`, or
  `nbs_act_entity` rows.**
- No SRTE writes.
- **No UPDATE/DELETE against any foundation row.**
- **No INSERTs into other subjects' RDB_MODERN output tables**
  (D_PATIENT, INVESTIGATION, CONDITION, RDB_DATE, LAB_TEST,
  LAB_TEST_RESULT, etc.).
- Do not write surrogate-key stores.
- Do not invoke `sp_morbidity_report_datamart_postprocessing`.

## Verification recipe

```sh
cd /Users/adam/code/nbs/NEDSS-DataReporting && docker compose down -v && docker compose up -d nbs-mssql liquibase
until [ "$(docker ps -a --filter name=liquibase --format '{{.Status}}' | head -1 | grep -c 'Exited')" = "1" ]; do sleep 20; done

SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C \
  -i /Users/adam/code/nbs/NEDSS-DataReporting/utilities/comparison-fixtures/fixtures/00_foundation/00_foundation.sql

SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C \
  -i /Users/adam/code/nbs/NEDSS-DataReporting/utilities/comparison-fixtures/fixtures/10_subjects/morbidity.sql

# event SP — @obs_id_list (shared with Lab)
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
  -Q "EXEC dbo.sp_observation_event @obs_id_list = N'20000130,20080010'"

# postprocessing SP — note the param name @pMorbidityIdList
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
  -Q "EXEC dbo.sp_d_morbidity_report_postprocessing @pMorbidityIdList = N'20000130,20080010', @debug = 0"

# coverage check
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
  -Q "SELECT * FROM dbo.MORBIDITY_REPORT WHERE MORB_RPT_LOCAL_ID LIKE 'MOR%'" -y 0 -Y 0
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
  -Q "SELECT * FROM dbo.MORBIDITY_REPORT_EVENT" -y 0 -Y 0
```

Apply the template's stop conditions and final-report shape. Report
`<populated>/<live_count>` for MORBIDITY_REPORT and MORBIDITY_REPORT_EVENT.
Expect MORBIDITY_REPORT to fully populate, MORBIDITY_REPORT_EVENT to
have most cross-subject keys = sentinel 1 (COALESCEd).
