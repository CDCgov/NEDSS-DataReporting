# Tier 2 — Reporter participations (Per/Org as Reporter of PHC)

You are a Tier 2 sub-agent. Your edge type is **`PerAsReporterOfPHC`**
(Provider as reporter) plus the related **`OrgAsReporterOfPHC`**
(Organization as reporter). Both authored together since they're the
"reporter" half of an Investigation's reporting metadata.

Read `prompts/templates/tier_2_link.md` first — the shared contract.
This file fills in edge-specific slots.

Like `patient_phc`, this edge is mostly **shape-consistency for the
Datamart step**. At Tier 1 isolation it surfaces reporter UIDs in the
Investigation event SP's JSON projection but doesn't change RDB_MODERN
dim/fact column population. The benefit shows up at Merge contract
step 9 when the PHC fact datamart SPs run.

## Edge identity

Two related edge types, both authored in this fixture:

1. **`PerAsReporterOfPHC`** — `participation` of `type_cd='PerAsReporterOfPHC'`
   linking Provider entity → Investigation act.
   - act_class_cd='CASE', subject_class_cd='PSN' (the Provider is
     class PSN like Patient — distinguished by `person.cd='PRV'`)
   - SP filter sites:
     - `056-sp_investigation_event-001.sql:913` (CASE pivot in
       Investigation JSON projection)
     - `072-sp_public_health_case_fact_datamart_event-001.sql:1900,
       1944-1948` (REPORTER_NAME/PHONE pivots → F_PAGE_CASE)
     - `073-sp_public_health_case_fact_datamart_update-001.sql:106,
       155-156` (same pivot, update path)
   - Catalog: `catalog/edge_types.md` row for `PerAsReporterOfPHC`

2. **`OrgAsReporterOfPHC`** — `participation` of `type_cd='OrgAsReporterOfPHC'`
   linking Organization entity → Investigation act.
   - act_class_cd='CASE', subject_class_cd='ORG'
   - SP filter sites:
     - `056-sp_investigation_event-001.sql:932`
     - `072-...:1898, 1917, 1964`
     - `073-...:106, 160, 213`
   - Catalog: `catalog/edge_types.md` row for `OrgAsReporterOfPHC`

## Endpoints to wire

Four pairs total (2 per type_cd):

For PerAsReporterOfPHC:
1. Foundation Provider (`@dbo_Entity_provider_uid = 20000010`) ↔
   Foundation Investigation (20000100)
2. v2 Provider (UID 20010010) ↔ v2 Investigation (20050010)

For OrgAsReporterOfPHC:
3. Foundation Organization (`@dbo_Entity_organization_uid = 20000020`) ↔
   Foundation Investigation (20000100)
4. v2 Organization (UID 20030010) ↔ v2 Investigation (20050010)

## Your UID block

- **`21005000–21005999`** (sixth Tier 2 agent — incremented from
  `patient_phc`'s 21004000–21004999). Update `catalog/uid_ranges.md`.

## Required reading (in addition to template's list)

- `coverage/coverage_investigation.md` — find LINK_REQUIRED entries
  mentioning reporter participations (likely #2 in the LINK_REQUIRED
  list — REPORTER context for F_PAGE_CASE).
- `liquibase-service/.../routines/056-sp_investigation_event-001.sql`
  — lines 913 (PerAsReporterOfPHC pivot) and 932 (OrgAsReporterOfPHC).
- `liquibase-service/.../routines/072-sp_public_health_case_fact_datamart_event-001.sql`
  — lines 1898–1964 (the PHC fact datamart's reporter-name pivots).
- `liquibase-service/.../routines/073-sp_public_health_case_fact_datamart_update-001.sql`
  — lines 106, 155-156, 160, 213 (update path).
- `fixtures/20_links/patient_phc.sql` — sibling participation pattern.
  Same file shape; just different type_cd values and endpoints.

## participation row shape

```sql
INSERT INTO [dbo].[participation]
    ([act_uid], [subject_entity_uid], [type_cd],
     [act_class_cd], [subject_class_cd],
     [add_time], [add_user_id], [last_chg_time], [last_chg_user_id],
     [record_status_cd], [record_status_time],
     [status_cd], [status_time],
     [type_desc_txt])
VALUES
    -- PerAsReporterOfPHC: foundation Provider as reporter of foundation Inv
    (@foundation_inv_uid, @foundation_provider_uid, N'PerAsReporterOfPHC',
     N'CASE', N'PSN',
     '2026-04-01T00:00:00', @superuser_id, '2026-04-01T00:00:00', @superuser_id,
     N'ACTIVE', '2026-04-01T00:00:00',
     N'A', '2026-04-01T00:00:00',
     N'Person as Reporter of PHC'),
    -- (etc. for v2, then OrgAsReporterOfPHC pairs with subject_class_cd='ORG')
```

Verify the participation table's actual NOT-NULL columns before
authoring (in case `patient_phc` learned about additional columns).

## Verification recipe

```sh
cd /Users/adam/code/nbs/NEDSS-DataReporting && docker compose down -v && docker compose up -d nbs-mssql liquibase
until [ "$(docker ps -a --filter name=liquibase --format '{{.Status}}' | head -1 | grep -c 'Exited')" = "1" ]; do sleep 20; done

# Pre-fixture infrastructure (note: SP signature requires @condition_cd_list)
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

# Tier 1 fixtures: provider + organization + investigation (minimum)
for f in provider organization investigation; do
  SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C \
    -i /Users/adam/code/nbs/NEDSS-DataReporting/utilities/comparison-fixtures/fixtures/10_subjects/${f}.sql
done

# Run Tier 1 chains
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_provider_event @user_id_list = N'20000010,20010010'"
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_nrt_provider_postprocessing @id_list = N'20000010,20010010', @debug = 0"
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_organization_event @org_id_list = N'20000020,20030010'"
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_nrt_organization_postprocessing @id_list = N'20000020,20030010', @debug = 0"
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_investigation_event @phc_id_list = N'20000100,20050010'"
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_nrt_investigation_postprocessing @id_list = N'20000100,20050010', @debug = 0"

# Apply this edge fixture
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C \
  -i /Users/adam/code/nbs/NEDSS-DataReporting/utilities/comparison-fixtures/fixtures/20_links/reporter_phc.sql

# Verify: re-run Investigation event SP and grep its JSON projection for
# the reporter participations.
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_investigation_event @phc_id_list = N'20000100,20050010'"
```

## Apply the template's stop conditions and final-report shape

Report:
- Apply result.
- Edge rows authored: count + breakdown by type_cd (2 PerAsReporterOfPHC + 2 OrgAsReporterOfPHC = 4 total).
- Coverage assessment: honest answer is likely "0 RDB_MODERN dim/fact
  column unlocks at Tier 1 isolation; benefit at Merge step 9". Verify
  this empirically by spot-checking INVESTIGATION columns pre/post.
- Event SP JSON projection: did `person_as_reporter_uid` and
  `org_as_reporter_uid` show up in the projection?
- Coverage still LINK_REQUIRED.
- OUT_OF_SCOPE / SRTE_GAP / FOUNDATION_GAP findings.
- Confirmation deliverables exist.
