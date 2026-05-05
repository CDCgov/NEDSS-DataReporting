# Tier 1 — Treatment

You are a Tier 1 sub-agent. Your subject is **Treatment**.

Read `prompts/templates/tier_1_subject.md` first — that's the shared
contract. This file fills in subject-specific slots.

Treatment is a relatively simple subject — small dim (16 cols) + small
fact (11 cols), with all cross-subject FK keys COALESCEd to sentinel
1, no FK constraints on the output tables. Should run cleanly in
isolation.

## Subject identity

- **Subject name:** treatment
- **Foundation row:** `@dbo_Act_treatment_uid = 20000150`
  (`act.act_uid`, `treatment.treatment_uid`); class `TRMT`,
  mood `EVN`. Foundation has many treatment columns NULL (Tier 1
  deferred — see `coverage_foundation.md`'s "treatment" entry).
- **Foundation Patient/Provider/Org**: referenced soft-ly for
  cross-subject FK keys, all COALESCE-to-sentinel-1 in the SP.
- **No internal locators.** Treatment is an Act, not an Entity.
- **Your UID block:** `20100000–20109999` per `catalog/uid_ranges.md`.
  Update the registry with your final allocation.

## SP chain

- Event SP: `dbo.sp_treatment_event @treatment_uids nvarchar(max), @debug = 0`
  - File: `liquibase-service/src/main/resources/db/005-rdb_modern/routines/070-sp_treatment_event-001.sql`
  - **Param name is `@treatment_uids`** — same as the postprocessing
    SP, which is unusual (most subjects use different param names).
  - Only 4 connective-table refs. No INNER JOIN on act_relationship.
- Postprocessing SP: `dbo.sp_nrt_treatment_postprocessing @treatment_uids, @debug = 0`
  - File: `routines/047-sp_nrt_treatment_postprocessing-001.sql`

## RDB_MODERN target tables

Per `catalog/rtr_target_columns.md` and live schema:

- `dbo.TREATMENT` — primary write target. **Live: 16 cols / catalog: 17.**
- `dbo.TREATMENT_EVENT` — fact table. **Live: 11 cols / catalog: 12.**
  All cross-subject FK keys (PATIENT_KEY, INVESTIGATION_KEY,
  CONDITION_KEY, MORB_RPT_KEY, TREATMENT_PROVIDING_ORG_KEY,
  TREATMENT_PHYSICIAN_KEY, LDF_GROUP_KEY, TREATMENT_DT_KEY) are
  **COALESCEd to sentinel 1** in the SP (lines 184–193). No NOT-NULL
  FK violations expected at Tier 1 isolation. **No FK constraints**
  on either table.
- `dbo.nrt_treatment` — synthetic staging. 29 cols.
- `dbo.nrt_treatment_key` — surrogate-key store; **do not hand-write**.
- `dbo.nrt_srte_Treatment_code` — pre-populated SRTE table (27 cols),
  used for treatment code lookups. Do not write.

## Variant strategy (apply the template's two-variant pattern)

- **Foundation Treatment enrichment**: hang additive child rows off
  `@dbo_Act_treatment_uid = 20000150`. Likely the SP needs:
  - The base `treatment` row (foundation has it)
  - Optionally `act_id` rows for treatment IDs
  - Leave most treatment-detail columns NULL on foundation to exercise
    the SP's null/blank handling
- **v2 Treatment**: a separate fully-attributed Treatment in your
  block (e.g., UID 20100010). Set every treatment column the
  postprocessing SP populates from `nrt_treatment`. Use `condition_cd='10110'`
  (Hep A acute) for v1 consistency, and a treatment code from
  `nrt_srte_Treatment_code` (verify which codes are present).

Treatment is single-act (no observation hierarchy like Lab/Morbidity).
No internal act_relationship rows needed. Two variants should suffice.

## Forbidden (inherited from template, repeated for clarity)

- **No cross-subject `act_relationship`, `participation`, or
  `nbs_act_entity` rows.** (Treatment doesn't need internal-hierarchy
  act_relationships either.)
- No SRTE writes.
- **No UPDATE/DELETE against any foundation row.**
- **No INSERTs into other subjects' RDB_MODERN output tables.**
- Do not write surrogate-key stores.

## Verification recipe

```sh
cd /Users/adam/code/nbs/NEDSS-DataReporting && docker compose down -v && docker compose up -d nbs-mssql liquibase
until [ "$(docker ps -a --filter name=liquibase --format '{{.Status}}' | head -1 | grep -c 'Exited')" = "1" ]; do sleep 20; done

SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C \
  -i /Users/adam/code/nbs/NEDSS-DataReporting/utilities/comparison-fixtures/fixtures/00_foundation/00_foundation.sql

SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C \
  -i /Users/adam/code/nbs/NEDSS-DataReporting/utilities/comparison-fixtures/fixtures/10_subjects/treatment.sql

# event SP — @treatment_uids
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
  -Q "EXEC dbo.sp_treatment_event @treatment_uids = N'20000150,20100010', @debug = 0"

# postprocessing SP — same param name
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
  -Q "EXEC dbo.sp_nrt_treatment_postprocessing @treatment_uids = N'20000150,20100010', @debug = 0"

# coverage check
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
  -Q "SELECT * FROM dbo.TREATMENT WHERE TREATMENT_UID IN (20000150, 20100010)" -y 0 -Y 0
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
  -Q "SELECT * FROM dbo.TREATMENT_EVENT" -y 0 -Y 0
```

Apply the template's stop conditions and final-report shape. Report
`<populated>/<live_count>` for TREATMENT and TREATMENT_EVENT. Expect
both to populate cleanly (16/16 + 11/11 or close), with cross-subject
FK keys = sentinel 1.
