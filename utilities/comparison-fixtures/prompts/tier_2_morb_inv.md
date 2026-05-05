# Tier 2 — MorbReportToInvestigation

You are a Tier 2 sub-agent. Your edge type is **`MorbReport`** (the
NBS convention for OBS→CASE act_relationships linking Morbidity Order
observations to Public Health Case investigations).

Read `prompts/templates/tier_2_link.md` first — the shared contract.
This file fills in edge-specific slots.

This is the third Tier 2 agent. Mirrors `lab_inv` exactly except:
- Source observations are Morbidity Orders (not Lab Orders)
- type_cd='MorbReport' instead of 'LabReport'

## Edge identity

- **Edge type:** `MorbReport`
- **Source:** `act_relationship.source_act_uid = <Morb Order's act_uid>`,
  `source_class_cd='OBS'`.
- **Target:** `act_relationship.target_act_uid = <Investigation's act_uid>`,
  `target_class_cd='CASE'`.
- **Catalog citation:** `catalog/edge_types.md` row for `MorbReport`
  (under `dbo.act_relationship`).
- **SP filter:** `055-sp_observation_event-001.sql:116-117` — same shared
  filter as LabReport (source/target class only, type_cd is convention).
  Used by `sp_observation_event` and consumed by
  `sp_d_morbidity_report_postprocessing`.

## Endpoints to wire

Two pairs (foundation→foundation + v2→v2):

1. Foundation Morb (`@dbo_Act_morbidity_uid = 20000130`) →
   Foundation Investigation (`@dbo_Act_investigation_uid = 20000100`)
2. v2 Morb Order (UID 20080010, per Morbidity Tier 1 block) →
   v2 Investigation (UID 20050010, per Investigation Tier 1)

**Important — Morb hierarchy detail**: Morbidity's v2 has 18 followup
observations. The cross-subject edge wires the **Order parent**
(20080010) to the Investigation. The followup children are tied to the
Order via Morb-internal act_relationships of `type_cd='COMP'`; they
don't need their own cross-subject edges.

## Your UID block

- **`21002000–21002999`** (third Tier 2 agent — incremented from
  `lab_inv`'s 21001000–21001999). Update `catalog/uid_ranges.md`.

## Required reading (in addition to template's list)

- `coverage/coverage_morbidity.md` — Tier 1 isolation gap. The
  postprocessing SP fails at line 950 (PATIENT_KEY no-COALESCE) AND
  line 1213. Your edge resolves INVESTIGATION_KEY; PATIENT_KEY needs
  Patient Tier 1's chain. With both, MORBIDITY_REPORT_EVENT goes 0/17 → 17/17.
- `coverage/coverage_investigation.md` line 198 (LINK_REQUIRED #15).
- `liquibase-service/.../routines/055-sp_observation_event-001.sql` —
  same file as Lab; lines 116-117 and 430-431.
- `liquibase-service/.../routines/016-sp_nrt_morbidity_report_postprocessing-001.sql` —
  postprocessing SP. **Note**: SP is named `sp_d_morbidity_report_postprocessing`
  inside the file even though the filename says `nrt_morbidity_report`.
  Param: `@pMorbidityIdList` (camelCase).
- `fixtures/20_links/lab_inv.sql` — worked sibling pattern. Note the
  `nrt_observation.associated_phc_uids` UPDATE — same approach needed
  here (the Morb postprocessing SP also reads associated_phc_uids
  directly to drive INVESTIGATION_KEY resolution).
- `fixtures/10_subjects/morbidity.sql` — Morbidity Tier 1.

## Verification recipe

Same shape as `lab_inv` but for Morbidity:

```sh
cd /Users/adam/code/nbs/NEDSS-DataReporting && docker compose down -v && docker compose up -d nbs-mssql liquibase
until [ "$(docker ps -a --filter name=liquibase --format '{{.Status}}' | head -1 | grep -c 'Exited')" = "1" ]; do sleep 20; done

# Pre-fixture infrastructure: recursive CTE for RDB_DATE (sp_get_date_dim broken)
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
  -Q "EXEC dbo.sp_nrt_srte_condition_code_postprocessing"

# Foundation
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C \
  -i /Users/adam/code/nbs/NEDSS-DataReporting/utilities/comparison-fixtures/fixtures/00_foundation/00_foundation.sql

# Tier 1 fixtures relevant: patient, provider, organization, investigation, morbidity
for f in patient provider organization investigation morbidity; do
  SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C \
    -i /Users/adam/code/nbs/NEDSS-DataReporting/utilities/comparison-fixtures/fixtures/10_subjects/${f}.sql
done

# Run Tier 1 chains in dependency order (Morbidity NOT yet — its postprocessing
# SP would fail until your edge wires the act_relationship + your staging
# UPDATE adjusts associated_phc_uids).
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_provider_event @user_id_list = N'20000010,20010010'"
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_nrt_provider_postprocessing @id_list = N'20000010,20010010', @debug = 0"
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_organization_event @org_id_list = N'20000020,20030010'"
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_nrt_organization_postprocessing @id_list = N'20000020,20030010', @debug = 0"
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_patient_event @user_id_list = N'20000000,20020010'"
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_nrt_patient_postprocessing @id_list = N'20000000,20020010', @debug = 0"
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_investigation_event @phc_id_list = N'20000100,20050010'"
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_nrt_investigation_postprocessing @id_list = N'20000100,20050010', @debug = 0"

# Apply this edge fixture (which includes the staging UPDATE + tail-EXEC of
# Morb postprocessing)
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C \
  -i /Users/adam/code/nbs/NEDSS-DataReporting/utilities/comparison-fixtures/fixtures/20_links/morb_inv.sql

# Verify MORBIDITY_REPORT + MORBIDITY_REPORT_EVENT now populate
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
  -Q "SELECT COUNT(*) FROM dbo.MORBIDITY_REPORT WHERE morb_rpt_KEY > 1;
      SELECT morb_rpt_KEY, PATIENT_KEY, INVESTIGATION_KEY, Condition_Key FROM dbo.MORBIDITY_REPORT_EVENT" -h -1
```

## Apply the template's stop conditions and final-report shape

Report:
- Apply result (clean / iterations).
- Edge rows authored (count + endpoints).
- Coverage unlocked: MORBIDITY_REPORT_EVENT goes from 0/17 → expected 17/17.
- Are MORBIDITY_REPORT_EVENT.PATIENT_KEY, INVESTIGATION_KEY, CONDITION_KEY,
  HSPTL_KEY, etc. populated to REAL keys (not sentinel 1)?
- Coverage still LINK_REQUIRED on Morbidity (LDF_GROUP_KEY waits for
  Tier 3; cross-subject keys for Hospital/Reporter need their own
  participation edges in Tier 2).
- Confirmation deliverables exist.
