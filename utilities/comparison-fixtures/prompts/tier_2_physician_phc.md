# Tier 2 — Physician + Investigator participations

You are a Tier 2 sub-agent. Your edge types are **`PhysicianOfPHC`**
(Provider as Physician of Investigation) and **`InvestgrOfPHC`**
(Provider as Investigator of Investigation). Bundled because:
- Both CASE/PSN participation type_cds
- Both filtered together at the datamart fact SPs (line 106 of
  `073-sp_public_health_case_fact_datamart_update-001.sql`:
  `WHERE PAR.TYPE_CD IN ('InvestgrOfPHC','PerAsReporterOfPHC','PhysicianOfPHC','OrgAsReporterOfPHC')`)
- Both populate distinct F_PAGE_CASE columns (PROVIDER_NAME/PHONE
  from PhysicianOfPHC; INVESTIGATOR_NAME from InvestgrOfPHC)

Read `prompts/templates/tier_2_link.md` first — the shared contract.
This file fills in edge-specific slots.

Like `reporter_phc`, this edge is **shape-consistency for the Datamart
step**. At Tier 1 isolation it surfaces investigator/physician UIDs in
event-SP JSON projections but doesn't change RDB_MODERN dim/fact column
population until Merge contract step 9.

## Edge identity

Two related edge types, both authored in this fixture:

1. **`PhysicianOfPHC`** — `participation` of `type_cd='PhysicianOfPHC'`
   linking Provider entity → Investigation act.
   - act_class_cd='CASE', subject_class_cd='PSN'
   - Used by: `sp_public_health_case_fact_datamart_event` (line 1901,
     1936-1940) and `_update` (line 153-154 — populates `PROVIDERNAME`
     / `PROVIDERPHONE` in F_PAGE_CASE).
   - **NOT referenced by sp_investigation_event** (per Phase B note —
     Investigation event SP uses HospOfADT etc. but not PhysicianOfPHC).
2. **`InvestgrOfPHC`** — `participation` of `type_cd='InvestgrOfPHC'`
   linking Provider entity → Investigation act.
   - act_class_cd='CASE', subject_class_cd='PSN'
   - Used by: `sp_investigation_event` (line 872, 919),
     `sp_public_health_case_fact_datamart_event` (line 1899,
     1952-1960), `_update` (line 157-159 — populates `INVESTIGATORNAME`
     in F_PAGE_CASE).

## Endpoints to wire

Four pairs total (2 per type_cd):

For PhysicianOfPHC:
1. Foundation Provider (`@dbo_Entity_provider_uid = 20000010`) ↔
   Foundation Investigation (`@dbo_Act_investigation_uid = 20000100`)
2. v2 Provider (UID 20010010) ↔ v2 Investigation (UID 20050010)

For InvestgrOfPHC:
3. Foundation Provider (20000010) ↔ Foundation Investigation (20000100)
4. v2 Provider (20010010) ↔ v2 Investigation (20050010)

(Same Provider serves as both Physician and Investigator of the same
Investigation — common in production data; v1 simplification per
STRATEGY.md.)

## Your UID block

- **`21006000–21006999`** (seventh Tier 2 agent — incremented from
  `reporter_phc`'s 21005000–21005999). Update `catalog/uid_ranges.md`.

## Required reading (in addition to template's list)

- `coverage/coverage_investigation.md` — find LINK_REQUIRED entries
  mentioning physician / investigator participation.
- `liquibase-service/.../routines/056-sp_investigation_event-001.sql`
  — lines 872, 919 (InvestgrOfPHC pivot). PhysicianOfPHC is NOT here.
- `liquibase-service/.../routines/072-sp_public_health_case_fact_datamart_event-001.sql`
  — lines 1899-1960.
- `liquibase-service/.../routines/073-sp_public_health_case_fact_datamart_update-001.sql`
  — lines 106, 153-159.
- `fixtures/20_links/{patient_phc,reporter_phc}.sql` — sibling
  participation patterns.

## Verification recipe

Same shape as `reporter_phc`:

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

# Tier 1 fixtures: provider + investigation (minimum)
for f in provider investigation; do
  SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C \
    -i /Users/adam/code/nbs/NEDSS-DataReporting/utilities/comparison-fixtures/fixtures/10_subjects/${f}.sql
done

# Run Tier 1 chains
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_provider_event @user_id_list = N'20000010,20010010'"
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_nrt_provider_postprocessing @id_list = N'20000010,20010010', @debug = 0"
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_investigation_event @phc_id_list = N'20000100,20050010'"
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_nrt_investigation_postprocessing @id_list = N'20000100,20050010', @debug = 0"

# Apply this edge fixture
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C \
  -i /Users/adam/code/nbs/NEDSS-DataReporting/utilities/comparison-fixtures/fixtures/20_links/physician_phc.sql

# Verify: re-run Investigation event SP. InvestgrOfPHC should appear in
# its JSON projection. PhysicianOfPHC won't be there (event SP doesn't
# read it) — only manifests at Datamart step 9.
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_investigation_event @phc_id_list = N'20000100,20050010'"
```

## Apply the template's stop conditions and final-report shape

Report:
- Apply result.
- Edge rows authored: 4 expected (2 PhysicianOfPHC + 2 InvestgrOfPHC).
- Coverage assessment: honest answer — likely 0 RDB_MODERN dim/fact
  unlocks at Tier 1 isolation; benefit at Merge step 9.
- Did `nrt_investigation.investigator_id` populate via the InvestgrOfPHC
  participation? Spot-check (the Investigation event SP at line 919
  does CASE-pivot it).
- Coverage still LINK_REQUIRED.
- OUT_OF_SCOPE / SRTE_GAP / FOUNDATION_GAP.
- Confirmation deliverables exist.
