# Tier 1 — Patient

You are a Tier 1 sub-agent. Your subject is **Patient**.

Read `prompts/templates/tier_1_subject.md` first — that's the shared
contract. This file fills in subject-specific slots.

## Subject identity

- **Subject name:** patient
- **Foundation row:** `@dbo_Entity_patient_uid = 20000000`
  (`entity.entity_uid`, `person.person_uid`, `person.person_parent_uid`);
  class `PSN`, person.cd `PAT`
- **Foundation locators:**
  - `@dbo_Postal_locator_patient = 20000001` — wired (PST, H, H)
  - `@dbo_Tele_locator_patient = 20000002` — wired (TELE, H, PH)
- **Your UID block:** `20020000–20029999` per `catalog/uid_ranges.md`.
  Update the registry with your final allocation.

## SP chain

- Event SP: `dbo.sp_patient_event @user_id_list nvarchar(max)`
  - File: `liquibase-service/src/main/resources/db/005-rdb_modern/routines/054-sp_patient_event-001.sql`
  - **Note: this SP internally calls `sp_patient_race_event` (line 99).
    You do NOT need to invoke `sp_patient_race_event` separately.**
- Postprocessing SP: `dbo.sp_nrt_patient_postprocessing @id_list, @debug = 0`
  - File: `liquibase-service/src/main/resources/db/005-rdb_modern/routines/004-sp_nrt_patient_postprocessing-001.sql`
- Datamart back-prop SP: `dbo.sp_patient_dim_columns_update_to_datamart @batch_id, @debug`
  - File: `routines/365-sp_patient_dim_columns_update_to_datamart.sql`
  - Invoked downstream from the postprocessing SP via `sp_dyn_dm_dimension_update`
    (line 868 of the postprocessing SP). At Tier 1 it will no-op since no
    datamart fact tables are populated yet — that's expected. Do not
    invoke it manually.

## RDB_MODERN target tables

Per `catalog/rtr_target_columns.md`:

- `dbo.d_patient` — primary write target. **89 column entries in the
  catalog** (significantly larger than Provider/Organization). Read the
  per-table breakdown end-to-end before authoring.
- `dbo.nrt_patient_key` — surrogate-key store; **do not hand-write** per
  the template.
- `dbo.job_flow_log` — logging only.

`dbo.PATIENT_LDF_GROUP` shows up in the catalog but is written by
`sp_nrt_ldf_postprocessing`, not by the patient chain. Out of scope.

Datamart-table Patient columns (e.g., `PATIENT_NAME` in
`HEPATITIS_DATAMART`, `STD_HIV_DATAMART`, etc.) are written by
`sp_patient_dim_columns_update_to_datamart` only after Tier 2 link rows
exist to attach the Patient to an Investigation. Not in scope for Tier 1.

## Locator-cd filters in the event SP

Patient's event SP at lines 250–282 has three locator branches:

- **Address (postal)**: `class_cd='PST' AND use_cd IN ('H', 'BIR')`
  (line 251–252). Foundation's postal locator at 20000001 uses
  `(PST, H, H)` → matches the `H` branch. To exercise the `BIR`
  (birth-country) branch, add a second postal locator + ELP row in your
  block with `(PST, BIR, ...)`.
- **Phone (tele)**: `class_cd='TELE'` only — no `cd` or `use_cd` filter
  (line 265). Foundation's tele at 20000002 → matches.
- **Email**: `class_cd='TELE' AND cd='NET'` (line 278–279). Foundation
  has NO locator with `cd='NET'`. To exercise PATIENT_EMAIL, add a tele
  locator + ELP row in your block with `(TELE, ?, NET)` and a non-NULL
  `email_address`.

## Variant strategy (apply the template's two-variant pattern)

Patient is rich enough that you may want **three rows** rather than two:

1. **Foundation Patient enrichment** (`@dbo_Entity_patient_uid = 20000000`):
   - Add a `(PST, BIR, ...)` postal_locator + ELP row to exercise birth-country.
   - Add a `(TELE, *, NET)` tele_locator + ELP row to exercise email.
   - Add a `person_race` row (foundation does not include one; required
     for race columns).
   - Optionally add an `entity_id` row (e.g., type `SS` for SSN, `MR`
     for medical record number — verify in `EI_TYPE_PAT`).
   - Leave a deliberate set of demographic columns NULL on the
     foundation Patient (race detail, marital status, education level,
     occupation_cd, etc.) to exercise the SP's null/blank handling.
2. **v2 Patient (e.g., UID 20020010)**: a fully-populated alternative
   in your block. Every d_patient column non-NULL. Use this to hit the
   "all columns populated" path.
3. *(Optional)* **v3 Patient with `deceased_ind_cd='Y'`**: if the
   postprocessing SP has CASE branches keyed on `deceased_ind_cd` (read
   the SP body to confirm), add a third Patient with that value set.
   Foundation has `deceased_ind_cd='N'`, v2 should mirror foundation;
   v3 exercises the deceased branch. Allocate (e.g.) UID 20020020.

The two- vs three-variant choice depends on what CASE branches the SP
actually has. Trace the SP body and decide. Document your choice in the
coverage report.

## person_race table

`sp_patient_race_event` reads `dbo.person_race` and surfaces it into the
event SP's JSON projection (lines 304–322 of `sp_patient_event`). The
race table has `race_cd` (single value per row, multiple rows allowed
per person), `race_category_cd`, plus a flotilla of detail flags
(`race_asian_1..3`, `race_amer_ind_1..3`, etc.). For coverage, the
postprocessing SP likely reads many of these. Your fixture should
include at least one `person_race` row per Patient variant — and for
the v2 Patient you may want multiple rows (each with a different
`race_cd`) to exercise the comma-concatenated race-list logic if the SP
has any.

## Forbidden (inherited from template, repeated for clarity)

- No cross-subject `act_relationship`, `participation`, or `nbs_act_entity`
  rows — those are Tier 2.
- No SRTE writes.
- **No UPDATE/DELETE against any foundation row** — the template's
  read-only-foundation contract was tightened after the Organization
  agent's first draft. Even columns `coverage_foundation.md` flags as
  "Tier 1 will populate" must be exercised via *your v2 variant in your
  UID block*, not by UPDATEing the foundation Patient. Additive child
  rows tied to `@dbo_Entity_patient_uid` (new locators, person_race,
  entity_id, additional person_name) are still allowed and encouraged.
- Do not write `nrt_patient_key`.

## Verification recipe

```sh
cd /Users/adam/code/nbs/NEDSS-DataReporting && docker compose down -v && docker compose up -d nbs-mssql liquibase
# poll: until [ "$(docker ps -a --filter name=liquibase --format '{{.Status}}' | head -1 | grep -c 'Exited')" = "1" ]; do sleep 20; done

SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C \
  -i /Users/adam/code/nbs/NEDSS-DataReporting/utilities/comparison-fixtures/fixtures/00_foundation/00_foundation.sql

SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C \
  -i /Users/adam/code/nbs/NEDSS-DataReporting/utilities/comparison-fixtures/fixtures/10_subjects/patient.sql

# event SP — @user_id_list (same param name as Provider). Internally
# also runs sp_patient_race_event for the same UIDs.
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
  -Q "EXEC dbo.sp_patient_event @user_id_list = N'20000000,20020010'"

# postprocessing SP
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
  -Q "EXEC dbo.sp_nrt_patient_postprocessing @id_list = N'20000000,20020010', @debug = 0"

# coverage check
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
  -Q "SELECT * FROM dbo.D_PATIENT WHERE PATIENT_UID IN (20000000, 20020010)" -y 0 -Y 0
```

Apply the template's stop conditions and final-report shape. With 89
catalog columns to cover, expect this to take longer than Provider/Org
— budget accordingly. Report `<populated>/89` for D_PATIENT in your
final reply.
