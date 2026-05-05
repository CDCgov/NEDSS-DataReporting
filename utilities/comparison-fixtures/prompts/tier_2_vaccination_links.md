# Tier 2 — Vaccination cross-subject links (SubOfVacc + PerformerOfVacc)

You are a Tier 2 sub-agent. Your edge types are **`SubOfVacc`**
(vaccination's subject patient) and **`PerformerOfVacc`** (vaccination's
performer — provider or organization). Both are `nbs_act_entity` rows
linking the Vaccination act_uid to a person/org entity_uid.

Read `prompts/templates/tier_2_link.md` first — the shared contract.
This file fills in edge-specific slots.

This is the **first nbs_act_entity edge** (prior 7 Tier 2 edges used
`act_relationship` or `participation`). Two key differences from prior
edges:

1. **`nbs_act_entity` has a surrogate UID column** (`nbs_act_entity_uid bigint NOT NULL`)
   — you'll allocate UIDs from your block. Prior edges had composite PKs.
2. **Vaccination event SP returns 0 rows at Tier 1 isolation** because
   `WHERE NBS_ACT_ENTITY.TYPE_CD='SubOfVacc'` at line 108 finds no rows.
   Your edge directly unblocks the event SP's JSON projection.

## Edge identity

Two related edge types:

1. **`SubOfVacc`** — `nbs_act_entity` of `type_cd='SubOfVacc'` linking
   Vaccination act_uid → Patient entity_uid. (Vaccination is the
   "intervention"; Patient is the subject of vaccination.)
   - SP filter: `071-sp_vaccination_event-001.sql:108` (main FROM clause —
     INNER-style filter that returns zero rows when no SubOfVacc edges exist),
     `:1156` (postprocessing JSON projection).
   - Catalog: `catalog/edge_types.md` row for `SubOfVacc`.
2. **`PerformerOfVacc`** — `nbs_act_entity` of `type_cd='PerformerOfVacc'`
   linking Vaccination act_uid → Provider entity_uid (or Organization).
   - SP filter: `071-sp_vaccination_event-001.sql:1135, 1146`.
   - Catalog: `catalog/edge_types.md` row for `PerformerOfVacc`.

## nbs_act_entity NOT-NULL columns

Verify with `INFORMATION_SCHEMA.COLUMNS WHERE table_name='nbs_act_entity'`.
Known NOT-NULL: `nbs_act_entity_uid`, `act_uid`, `entity_uid`,
`entity_version_ctrl_nbr` (smallint), `add_time`, `add_user_id`,
`last_chg_time`, `last_chg_user_id`, `record_status_cd`, `record_status_time`.
NULL-allowed: `type_cd` (counter-intuitive but the schema lists it
nullable).

## Endpoints to wire

Four pairs total (one row each):

For SubOfVacc:
1. Foundation Vaccination (`@dbo_Act_vaccination_uid = 20000160`) ↔
   Foundation Patient (`@dbo_Entity_patient_uid = 20000000`)
2. v2 Vaccination (UID 20110010) ↔ v2 Patient (UID 20020010)

For PerformerOfVacc:
3. Foundation Vaccination (20000160) ↔ Foundation Provider
   (`@dbo_Entity_provider_uid = 20000010`)
4. v2 Vaccination (20110010) ↔ v2 Provider (UID 20010010)

(Optional: Performer can also link to an Org for "provider-as-org"
variant. Skip for v1 unless the SP coverage demonstrably needs it.)

## Your UID block

- **`21007000–21007999`** (eighth Tier 2 agent — incremented from
  `physician_phc`'s 21006000–21006999). Need **4 surrogate UIDs**
  for the 4 nbs_act_entity rows. Suggested allocation:
  - `21007000` — SubOfVacc, foundation Vacc → foundation Patient
  - `21007001` — SubOfVacc, v2 Vacc → v2 Patient
  - `21007002` — PerformerOfVacc, foundation Vacc → foundation Provider
  - `21007003` — PerformerOfVacc, v2 Vacc → v2 Provider

  Update `catalog/uid_ranges.md`.

## Required reading (in addition to template's list)

- `coverage/coverage_vaccination.md` — confirms event SP returns 0 rows
  at Tier 1 isolation due to missing nbs_act_entity rows. This edge
  directly unblocks the event SP.
- `liquibase-service/.../routines/071-sp_vaccination_event-001.sql`
  — line 108 (main FROM clause SubOfVacc filter, the "INNER" filter
  that blocks rows), line 1135-1146 (PerformerOfVacc joins), line 1156
  (SubOfVacc projection).
- `fixtures/10_subjects/vaccination.sql` — Vaccination Tier 1 fixture.
  Foundation Vaccination and v2 Vaccination UIDs.
- `fixtures/20_links/{patient_phc,reporter_phc,physician_phc}.sql` —
  participation patterns (different table, but file structure is similar).

## nbs_act_entity row shape

```sql
DECLARE @superuser_id bigint = 10009282;

INSERT INTO [dbo].[nbs_act_entity]
    ([nbs_act_entity_uid], [act_uid], [entity_uid], [type_cd],
     [entity_version_ctrl_nbr],
     [add_time], [add_user_id], [last_chg_time], [last_chg_user_id],
     [record_status_cd], [record_status_time])
VALUES
    -- SubOfVacc: foundation Vacc 20000160 → foundation Patient 20000000
    (21007000, 20000160, 20000000, N'SubOfVacc',
     1,
     '2026-04-01T00:00:00', @superuser_id, '2026-04-01T00:00:00', @superuser_id,
     N'ACTIVE', '2026-04-01T00:00:00'),
    -- (etc. for the other 3)
```

## Verification recipe

```sh
cd /Users/adam/code/nbs/NEDSS-DataReporting && docker compose down -v && docker compose up -d nbs-mssql liquibase
until [ "$(docker ps -a --filter name=liquibase --format '{{.Status}}' | head -1 | grep -c 'Exited')" = "1" ]; do sleep 20; done

# Pre-fixture infrastructure
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
  -Q "SET NOCOUNT ON;
      WITH dates AS (
        SELECT CAST('2020-01-01' AS DATE) AS dt
        UNION ALL
        SELECT DATEADD(day, 1, dt) FROM dates WHERE dt < '2030-12-31'
      )
      INSERT INTO dbo.RDB_DATE (DATE_KEY, DATE_MM_DD_YYYY)
      SELECT DATEDIFF(day, '2010-01-01', dt) + 1, dt FROM dates
      OPTION (MAXRECURSION 0);"

SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
  -Q "EXEC dbo.sp_nrt_srte_condition_code_postprocessing @condition_cd_list = N'10110', @debug = 0"

# Foundation
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C \
  -i /Users/adam/code/nbs/NEDSS-DataReporting/utilities/comparison-fixtures/fixtures/00_foundation/00_foundation.sql

# Tier 1 fixtures: patient + provider + vaccination (minimum)
for f in patient provider vaccination; do
  SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C \
    -i /Users/adam/code/nbs/NEDSS-DataReporting/utilities/comparison-fixtures/fixtures/10_subjects/${f}.sql
done

# Run Tier 1 chains for patient and provider (vaccination's chain still
# fails on event SP returning 0 rows, but its postprocessing reads from
# nrt_vaccination directly, so it produces D_VACCINATION rows anyway —
# Tier 1 isolation already produces 21/21 + 6/6).
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_provider_event @user_id_list = N'20000010,20010010'"
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_nrt_provider_postprocessing @id_list = N'20000010,20010010', @debug = 0"
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_patient_event @user_id_list = N'20000000,20020010'"
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_nrt_patient_postprocessing @id_list = N'20000000,20020010', @debug = 0"

# Apply Vaccination chain pre-edge to capture baseline
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_vaccination_event @vac_uids = N'20000160,20110010', @debug = 0"
# Expected: 0 rows (no SubOfVacc edges yet)

SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_d_vaccination_postprocessing @vac_uids = N'20000160,20110010', @debug = 0"
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_f_vaccination_postprocessing @vac_uids = N'20000160,20110010', @debug = 0"

# Apply this edge fixture
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C \
  -i /Users/adam/code/nbs/NEDSS-DataReporting/utilities/comparison-fixtures/fixtures/20_links/vaccination_links.sql

# Re-run Vaccination event SP — should now project rows. Verify.
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_vaccination_event @vac_uids = N'20000160,20110010', @debug = 0"
# Expected: 2 rows projected (one per vaccination UID)
```

## Apply the template's stop conditions and final-report shape

Report:
- Apply result.
- Edge rows authored: 4 expected.
- Coverage assessment: did Vaccination event SP go from 0 rows to 2 rows
  in projection? Did the postprocessing SPs (D_VACCINATION + F_VACCINATION)
  change column population? They're already 21/21 + 6/6 from Tier 1 — but
  some sentinel-1 keys may now flip to real keys.
- Confirmation deliverables exist.
