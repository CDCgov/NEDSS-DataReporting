# Tier 1 — Vaccination

You are a Tier 1 sub-agent. Your subject is **Vaccination**.

Read `prompts/templates/tier_1_subject.md` first — that's the shared
contract. This file fills in subject-specific slots.

Vaccination is a moderately-sized subject — 21-col D_VACCINATION + 6-col
F_VACCINATION, no FK constraints on either. Most cross-subject keys
appear to be COALESCE-friendly or absent. Should run cleanly in
isolation.

## Subject identity

- **Subject name:** vaccination
- **Foundation row:** `@dbo_Act_vaccination_uid = 20000160`
  (`act.act_uid`, `intervention.intervention_uid`); class `INTV`,
  mood `EVN`. Foundation has many intervention columns NULL (Tier 1
  deferred — see `coverage_foundation.md`'s "intervention" entry:
  `activity_from_time, activity_to_time, target_site_cd, method_cd,
  vacc_mfgr_cd, age_at_vacc, material_lot_nm, material_expiration_time,
  vacc_info_source_cd`).
- **Foundation Patient/Provider:** referenced soft-ly via
  `intervention.subject_person_uid` and other UID columns.
- **No internal locators.** Vaccination is an Act, not an Entity.
- **Your UID block:** `20110000–20119999` per `catalog/uid_ranges.md`.

## SP chain

- Event SP: `dbo.sp_vaccination_event @vac_uids nvarchar(max), @debug = 0`
  - File: `liquibase-service/src/main/resources/db/005-rdb_modern/routines/071-sp_vaccination_event-001.sql`
- Postprocessing SPs (2 — like Lab):
  1. `dbo.sp_d_vaccination_postprocessing @vac_uids, @debug = 0`
     - File: `routines/044-sp_d_vaccination_postprocessing-001.sql`
     - Writes `D_VACCINATION` (21 cols).
  2. `dbo.sp_f_vaccination_postprocessing @vac_uids, @debug = 0`
     - File: `routines/046-sp_f_vaccination_postprocessing-001.sql`
     - Writes `F_VACCINATION` (6 cols).
- All 3 SPs use the **same param name `@vac_uids`** (no naming variation).
- **NOT in scope:**
  - `sp_ldf_intervention_event` (062) — LDF chain, separate.
  - `sp_ldf_vaccine_prevent_diseases_datamart_postprocessing` (305) — datamart.
  - `sp_covid_vaccination_datamart_postprocessing` (320) — datamart.

## RDB_MODERN target tables

Per `catalog/rtr_target_columns.md` and live schema:

- `dbo.D_VACCINATION` — primary write target. **Live: 21 cols / catalog: 24.**
- `dbo.F_VACCINATION` — fact table. **Live: 6 cols.** Small.
- `dbo.nrt_vaccination` — synthetic staging. 31 cols.
- `dbo.nrt_vaccination_answer` — answer staging. 5 cols.
- `dbo.nrt_vaccination_key` — surrogate-key store; **do not hand-write**.

No FK constraints on D_VACCINATION/F_VACCINATION. Should run cleanly.

## Variant strategy (apply the template's two-variant pattern)

- **Foundation Vaccination enrichment**: add child rows tied to
  `@dbo_Act_vaccination_uid = 20000160`. The intervention row already
  exists in foundation; you'll need:
  - The matching `nrt_vaccination` staging row (driver of the chain)
  - Possibly `nrt_vaccination_answer` rows for additional fields
  - `act_id` rows if relevant
  - Leave most `intervention.*_cd` columns NULL on foundation
- **v2 Vaccination**: a separate fully-attributed Vaccination in your
  block (e.g., UID 20110010). Pick a real vaccine code from baseline
  SRTE — verify with:
  ```sh
  SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d NBS_SRTE \
    -Q "SET NOCOUNT ON; SELECT TOP 10 code, code_short_desc_txt
        FROM dbo.code_value_general
        WHERE code_set_nm IN ('VAX_TYPE', 'VAX_CD', 'CVX')
        ORDER BY code_set_nm, code"
  ```

For v1 consistency with prior subjects, use a Hepatitis A vaccine
(e.g., CVX 31 = Hep A pediatric, or CVX 52 = Hep A adult) if
available, else any present vaccine.

## Forbidden (inherited from template, repeated for clarity)

- **No cross-subject `act_relationship`, `participation`, or
  `nbs_act_entity` rows.**
- No SRTE writes.
- **No UPDATE/DELETE against any foundation row.**
- **No INSERTs into other subjects' RDB_MODERN output tables.**
- Do not write surrogate-key stores (`nrt_vaccination_key`).
- Do not invoke the 3 out-of-scope SPs (LDF, COVID datamart, vaccine-prevent-diseases datamart).

## Verification recipe

```sh
cd /Users/adam/code/nbs/NEDSS-DataReporting && docker compose down -v && docker compose up -d nbs-mssql liquibase
until [ "$(docker ps -a --filter name=liquibase --format '{{.Status}}' | head -1 | grep -c 'Exited')" = "1" ]; do sleep 20; done

SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C \
  -i /Users/adam/code/nbs/NEDSS-DataReporting/utilities/comparison-fixtures/fixtures/00_foundation/00_foundation.sql

SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C \
  -i /Users/adam/code/nbs/NEDSS-DataReporting/utilities/comparison-fixtures/fixtures/10_subjects/vaccination.sql

# event SP — @vac_uids
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
  -Q "EXEC dbo.sp_vaccination_event @vac_uids = N'20000160,20110010', @debug = 0"

# postprocessing SPs (run BOTH d_ and f_)
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
  -Q "EXEC dbo.sp_d_vaccination_postprocessing @vac_uids = N'20000160,20110010', @debug = 0"

SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
  -Q "EXEC dbo.sp_f_vaccination_postprocessing @vac_uids = N'20000160,20110010', @debug = 0"

# coverage check
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
  -Q "SELECT * FROM dbo.D_VACCINATION WHERE VACCINATION_UID IN (20000160, 20110010)" -y 0 -Y 0
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
  -Q "SELECT * FROM dbo.F_VACCINATION" -y 0 -Y 0
```

Apply the template's stop conditions and final-report shape. Report
`<populated>/<live_count>` for D_VACCINATION (target 21) and
F_VACCINATION (target 6).
