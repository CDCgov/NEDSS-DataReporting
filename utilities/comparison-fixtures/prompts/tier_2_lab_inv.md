# Tier 2 — LabReportToInvestigation

You are a Tier 2 sub-agent. Your edge type is **`LabReport`** (the
NBS convention for OBS→CASE act_relationships linking Lab Order
observations to Public Health Case investigations).

Read `prompts/templates/tier_2_link.md` first — the shared contract.
This file fills in edge-specific slots.

This is the second Tier 2 agent. The first (`InvestigationHasNotification`)
demonstrated the working pattern: small fixture, big coverage unlock.

## Edge identity

- **Edge type:** `LabReport`
- **Source:** `act_relationship.source_act_uid = <Lab Order's act_uid>`,
  `source_class_cd='OBS'`.
- **Target:** `act_relationship.target_act_uid = <Investigation's act_uid>`,
  `target_class_cd='CASE'`.
- **Catalog citation:** `catalog/edge_types.md` row for `LabReport`
  (under `dbo.act_relationship`).
- **SP filter:** `055-sp_observation_event-001.sql:116-117` and `:430-431`
  filter on `source_class_cd='OBS' AND target_class_cd='CASE'`. Used by
  `sp_observation_event` (lab → PHC lookup), consumed by
  `sp_d_lab_test_postprocessing`, `sp_d_labtest_result_postprocessing`,
  and downstream lab datamart SPs (out of scope here).

## Endpoints to wire

Two pairs (foundation→foundation + v2→v2 Order):

1. Foundation Lab (`@dbo_Act_lab_uid = 20000120`) →
   Foundation Investigation (`@dbo_Act_investigation_uid = 20000100`)
2. v2 Lab Order (UID 20070010, per Lab Tier 1 block) →
   v2 Investigation (UID 20050010, per Investigation Tier 1)

**Important — Lab hierarchy detail**: Lab's v2 has 4 observations
(Order parent + Result child + C_Order + C_Result). The cross-subject
edge wires the **Order parent** (20070010) to the Investigation. The
Result/C_Order/C_Result children are tied to the Order via Lab-internal
act_relationships of `type_cd='COMP'`; they don't need their own
cross-subject edges.

## Your UID block

- **`21001000–21001999`** (second Tier 2 agent — incremented from
  `inv_notification`'s 21000000–21000999). Update `catalog/uid_ranges.md`.

## Required reading (in addition to template's list)

- `coverage/coverage_lab.md` — find LINK_REQUIRED entries (the SP-
  reads-INVESTIGATION_KEY-without-COALESCE pattern). The 13 sentinel-1
  cross-subject keys on LAB_TEST_RESULT include INVESTIGATION_KEY,
  PATIENT_KEY, CONDITION_KEY, etc. Your edge resolves INVESTIGATION_KEY
  for Lab→Investigation. Patient/Condition/etc. are resolved by the
  Tier 1 chains (with infrastructure SPs).
- `coverage/coverage_investigation.md` line 197 (LINK_REQUIRED #14) —
  identifies your edge as required for Investigation's
  `investigation_observation_ids` JSON branch (event SP lines 378–407).
- `liquibase-service/.../routines/055-sp_observation_event-001.sql` —
  lines 116-117 and 430-431 are the AR_TYPE filter. Read enough
  context to understand which JSON branches surface lab→PHC info.
- `liquibase-service/.../routines/018-sp_d_lab_test_postprocessing-001.sql` —
  the postprocessing SP that reads INVESTIGATION_KEY from
  `nrt_lab_test_result_group` joins.
- `fixtures/10_subjects/lab.sql` — Lab Tier 1 fixture. Lab's
  internal Order→Result act_relationship rows are at lines ~257–280;
  yours go in a different file but use the same
  Order's `act_uid=20070010` as source.
- `fixtures/20_links/inv_notification.sql` — the worked example for
  Tier 2 fixture authoring.

## Verification recipe

```sh
cd /Users/adam/code/nbs/NEDSS-DataReporting && docker compose down -v && docker compose up -d nbs-mssql liquibase
until [ "$(docker ps -a --filter name=liquibase --format '{{.Status}}' | head -1 | grep -c 'Exited')" = "1" ]; do sleep 20; done

# Pre-fixture infrastructure: RDB_DATE via recursive CTE (sp_get_date_dim has
# an RTR bug per STRATEGY.md), then sp_nrt_srte_condition_code_postprocessing.
# (Use the recursive CTE pattern that the inv_notification agent worked out;
# read the inv_notification fixture's verification log if you need the SQL.)
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

# Verify both populated
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
  -Q "SET NOCOUNT ON; SELECT 'RDB_DATE' AS tbl, COUNT(*) FROM dbo.RDB_DATE UNION ALL SELECT 'CONDITION', COUNT(*) FROM dbo.CONDITION"

# Foundation
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C \
  -i /Users/adam/code/nbs/NEDSS-DataReporting/utilities/comparison-fixtures/fixtures/00_foundation/00_foundation.sql

# Tier 1 fixtures relevant to this edge: Patient + Provider + Organization +
# Investigation + Lab. (Patient/Provider/Org needed because LAB_TEST_RESULT
# has cross-subject FK keys that resolve to those dimensions.)
for f in patient provider organization investigation lab; do
  SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C \
    -i /Users/adam/code/nbs/NEDSS-DataReporting/utilities/comparison-fixtures/fixtures/10_subjects/${f}.sql
done

# Run Tier 1 chains in dependency order (subjects first, Lab last)
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_provider_event @user_id_list = N'20000010,20010010'"
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_nrt_provider_postprocessing @id_list = N'20000010,20010010', @debug = 0"
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_organization_event @org_id_list = N'20000020,20030010'"
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_nrt_organization_postprocessing @id_list = N'20000020,20030010', @debug = 0"
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_patient_event @user_id_list = N'20000000,20020010'"
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_nrt_patient_postprocessing @id_list = N'20000000,20020010', @debug = 0"
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_investigation_event @phc_id_list = N'20000100,20050010'"
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_nrt_investigation_postprocessing @id_list = N'20000100,20050010', @debug = 0"
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_observation_event @obs_id_list = N'20000120,20070010'"
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_d_lab_test_postprocessing @obs_ids = N'20000120,20070010', @debug = 0"
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_d_labtest_result_postprocessing @obs_ids = N'20000120,20070010', @debug = 0"

# Apply this edge fixture
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C \
  -i /Users/adam/code/nbs/NEDSS-DataReporting/utilities/comparison-fixtures/fixtures/20_links/lab_inv.sql

# The fixture's tail-EXECs should re-run the Lab postprocessing chains.
# Verify INVESTIGATION_KEY now resolves to a real key (not sentinel 1).
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
  -Q "SELECT LAB_TEST_UID, PATIENT_KEY, INVESTIGATION_KEY, CONDITION_KEY, ORDERING_PROVIDER_KEY FROM dbo.LAB_TEST_RESULT" -h -1
```

## Apply the template's stop conditions and final-report shape

Report:
- Apply result (clean / iterations).
- Edge rows authored (count + endpoints).
- Coverage unlocked: which LAB_TEST_RESULT cross-subject FK columns
  flipped from sentinel 1 to real keys.
- Coverage still LINK_REQUIRED on LAB_TEST_RESULT (waiting on other
  Tier 2 edges or Tier 3 work).
- Confirmation deliverables exist.
