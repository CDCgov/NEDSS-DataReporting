# Tier 2 — PHC roles (nbs_act_entity)

You are a Tier 2 sub-agent. Your edge type is the family of
`nbs_act_entity` rows that the Investigation event SP's CASE-pivot
subquery (`056-sp_investigation_event-001.sql:909-934`) reads to
populate `nrt_investigation.<role>_uid` fields.

For v1, you author the **3 highest-value role types**:
- **`PerAsReporterOfPHC`** — populates `person_as_reporter_uid`
- **`OrgAsReporterOfPHC`** — populates `org_as_reporter_uid`
- **`HospOfADT`** — populates `hospital_uid` (and surfaces in F_PAGE_CASE)

The other 17 roles in the same CASE pivot (CASupervisorOfPHC,
FldFupInvestgrOfPHC, OrgAsClinicOfPHC, etc., all MISSING_FROM_SRTE
per Phase B) are deferred to Tier 3.

Read `prompts/templates/tier_2_link.md` first — the shared contract.
This file fills in edge-specific slots. Note the IDENTITY_INSERT
pattern in Step 4.

This edge bundle resolves the architectural finding from `reporter_phc`:
participation rows alone don't populate `nrt_investigation.person_as_reporter_uid`
/ `org_as_reporter_uid` — those fields come from `nbs_act_entity` via
the CASE pivot at lines 913/932.

## Edge identity

Three related edge types, all authored in this fixture as
`nbs_act_entity` rows:

1. **`PerAsReporterOfPHC`** — Investigation act → Provider entity
   - source/target classes per catalog: CASE/PSN
   - SP filter: `056-sp_investigation_event-001.sql:913` (CASE-pivot
     in the `investigation_act_entity` subquery; populates
     `nrt_investigation.person_as_reporter_uid`)
   - IN baseline SRTE PAR_TYPE.
2. **`OrgAsReporterOfPHC`** — Investigation act → Organization entity
   - source/target classes per catalog: CASE/ORG
   - SP filter: `056-sp_investigation_event-001.sql:932`
   - IN baseline SRTE PAR_TYPE.
3. **`HospOfADT`** — Investigation act → Organization entity (hospital)
   - source/target classes per catalog: CASE/ORG
   - SP filter: `056-sp_investigation_event-001.sql:914`
   - IN baseline SRTE PAR_TYPE.

## Endpoints to wire

Six pairs (one row each):

For PerAsReporterOfPHC:
1. Foundation Investigation (20000100) → Foundation Provider (20000010)
2. v2 Investigation (20050010) → v2 Provider (20010010)

For OrgAsReporterOfPHC:
3. Foundation Investigation (20000100) → Foundation Organization (20000020)
4. v2 Investigation (20050010) → v2 Organization (20030010)

For HospOfADT:
5. Foundation Investigation (20000100) → Foundation Organization (20000020)
6. v2 Investigation (20050010) → v2 Organization (20030010)

(Same Org serves as both Reporter and Hospital — common in production
data; v1 simplification per STRATEGY.md.)

## Note: this overlaps the `reporter_phc` agent's participation rows

The `reporter_phc` agent already authored `participation` rows for
PerAsReporterOfPHC + OrgAsReporterOfPHC. This is **not** a duplicate:
- `participation` rows surface in event-SP `person_participations` /
  `organization_participations` JSON branches and feed Datamart-step-9
  filters (PHC fact datamart's `WHERE PAR.TYPE_CD IN (...)`).
- `nbs_act_entity` rows surface in `nrt_investigation.person_as_reporter_uid`
  / `org_as_reporter_uid` directly via the CASE pivot.

The two tables serve different downstream consumers. Both are required
for full coverage. The same source/target endpoints can have rows in
both tables — that's by design, not a violation.

## Your UID block

- **`21009000–21009999`** (tenth Tier 2 agent — incremented from
  `interview_links`'s 21008000–21008999). Allocate 6 UIDs:
  21009000–21009005. Update `catalog/uid_ranges.md`.

## CRITICAL: nbs_act_entity is an IDENTITY table

Wrap your INSERTs:

```sql
SET IDENTITY_INSERT [dbo].[nbs_act_entity] ON;
INSERT INTO [dbo].[nbs_act_entity] (
    [nbs_act_entity_uid], [act_uid], [entity_uid], [type_cd],
    [entity_version_ctrl_nbr],
    [add_time], [add_user_id], [last_chg_time], [last_chg_user_id],
    [record_status_cd], [record_status_time]
) VALUES
    -- 6 rows
    ;
SET IDENTITY_INSERT [dbo].[nbs_act_entity] OFF;
```

## Required reading (in addition to template's list)

- `coverage/coverage_reporter_phc.md` — explicitly identifies this
  agent's scope (the architectural-distinction OUT_OF_SCOPE finding).
- `coverage/coverage_investigation.md` — find LINK_REQUIRED entries
  that mention nbs_act_entity for reporter / hospital roles.
- `liquibase-service/.../routines/056-sp_investigation_event-001.sql`
  — lines 909-934 (the CASE-pivot subquery).
- `fixtures/20_links/{vaccination_links,interview_links}.sql` — sibling
  nbs_act_entity patterns. Same IDENTITY_INSERT wrap.
- `fixtures/20_links/reporter_phc.sql` — the participation cousin.

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
# Inspect JSON projection — pre-edge, person_as_reporter_uid / org_as_reporter_uid / hospital_uid should all be NULL.

SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_nrt_investigation_postprocessing @id_list = N'20000100,20050010', @debug = 0"

# Apply this edge fixture
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C \
  -i /Users/adam/code/nbs/NEDSS-DataReporting/utilities/comparison-fixtures/fixtures/20_links/phc_roles_nae.sql

# Re-run Investigation event SP — JSON should now show person_as_reporter_uid
# / org_as_reporter_uid / hospital_uid populated.
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_investigation_event @phc_id_list = N'20000100,20050010'"
```

## Apply the template's stop conditions and final-report shape

Report:
- Apply result.
- Edge rows authored: 6 expected.
- Coverage assessment: did the JSON projection's
  `investigation_act_entity.person_as_reporter_uid`, `org_as_reporter_uid`,
  `hospital_uid` fields flip from NULL to populated? RDB_MODERN dim
  columns may stay unchanged (Investigation postprocessing reads from
  `nrt_investigation` staging which Tier 1 hand-authored — but spot-check
  whether any `INVESTIGATION` row's reporter/hospital columns are now
  filled).
- Confirmation deliverables exist.
