# Tier 2 — Interview cross-subject links

You are a Tier 2 sub-agent. Your edge types are three nbs_act_entity
edge types for Interview:
- **`IntrvwerOfInterview`** (interviewer is Provider)
- **`IntrvweeOfInterview`** (interviewee is Patient)
- **`OrgAsSiteOfIntv`** (interview site is Organization)

All three are MISSING_FROM_SRTE per Phase B but RTR's SP filters on
the literal regardless — author with the literal type_cd values.

Read `prompts/templates/tier_2_link.md` first — the shared contract.
This file fills in edge-specific slots.

This edge is **shape-consistency**, NOT coverage-unlock. Unlike
`vaccination_links` (which had INNER filters that blocked the event SP),
all three Interview event SP joins are **LEFT JOIN** (lines 87–95 of
`065-sp_interview_event-001.sql`) — Interview event SP returns rows at
Tier 1 isolation regardless. Adding these edges populates the JSON
projection's interviewer/interviewee/site UIDs but doesn't change
RDB_MODERN dim/fact column population.

## Edge identity

Three related edge types, all authored in this fixture:

1. **`IntrvwerOfInterview`** — Interview act → Provider entity
   - SP filter: `065-sp_interview_event-001.sql:89` (LEFT JOIN nae)
   - Catalog source/target: Interview/PSN
2. **`IntrvweeOfInterview`** — Interview act → Patient entity
   - SP filter: `065-sp_interview_event-001.sql:95` (LEFT JOIN nae3)
   - Catalog source/target: Interview/PSN
3. **`OrgAsSiteOfIntv`** — Interview act → Organization entity
   - SP filter: `065-sp_interview_event-001.sql:92` (LEFT JOIN nae2)
   - Catalog source/target: Interview/ORG

## Endpoints to wire

Six pairs total (one row per pair, two pairs per type_cd):

For IntrvwerOfInterview (Provider as interviewer):
1. Foundation Interview (`@dbo_Act_interview_uid = 20000140`) ↔
   Foundation Provider (`@dbo_Entity_provider_uid = 20000010`)
2. v2 Interview (UID 20090010) ↔ v2 Provider (UID 20010010)

For IntrvweeOfInterview (Patient as interviewee):
3. Foundation Interview (20000140) ↔ Foundation Patient (`@dbo_Entity_patient_uid = 20000000`)
4. v2 Interview (20090010) ↔ v2 Patient (UID 20020010)

For OrgAsSiteOfIntv (Org as site):
5. Foundation Interview (20000140) ↔ Foundation Organization (`@dbo_Entity_organization_uid = 20000020`)
6. v2 Interview (20090010) ↔ v2 Organization (UID 20030010)

## Your UID block

- **`21008000–21008999`** (ninth Tier 2 agent — incremented from
  `vaccination_links`'s 21007000–21007999). Allocate 6 UIDs:
  21008000–21008005. Update `catalog/uid_ranges.md`.

## CRITICAL: nbs_act_entity is an IDENTITY table

Per the Tier 2 template (Step 4) and `vaccination_links`'s discovery,
`nbs_act_entity_uid` is an IDENTITY column. Wrap your INSERT with:

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

- `coverage/coverage_interview.md` — find LINK_REQUIRED entries
  mentioning these edges. Note: Interview already converged in 1 iter
  with 18/24 D_INTERVIEW + 7/7 D_INTERVIEW_NOTE + 8/10 F_INTERVIEW_CASE
  at Tier 1 isolation. This Tier 2 edge doesn't change those numbers
  (LEFT JOINs).
- `liquibase-service/.../routines/065-sp_interview_event-001.sql`
  — lines 87-95 (the three LEFT JOINs).
- `fixtures/20_links/vaccination_links.sql` — sibling nbs_act_entity
  pattern. Same IDENTITY_INSERT wrap.

## Verification recipe

Same shape as vaccination_links. Read `vaccination_links`'s prompt
verification recipe and adapt for Interview UIDs:

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

# Tier 1 fixtures: patient + provider + organization + interview
for f in patient provider organization interview; do
  SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C \
    -i /Users/adam/code/nbs/NEDSS-DataReporting/utilities/comparison-fixtures/fixtures/10_subjects/${f}.sql
done

# Run Tier 1 chains for each subject
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_provider_event @user_id_list = N'20000010,20010010'"
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_nrt_provider_postprocessing @id_list = N'20000010,20010010', @debug = 0"
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_organization_event @org_id_list = N'20000020,20030010'"
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_nrt_organization_postprocessing @id_list = N'20000020,20030010', @debug = 0"
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_patient_event @user_id_list = N'20000000,20020010'"
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_nrt_patient_postprocessing @id_list = N'20000000,20020010', @debug = 0"

# Run Interview chain pre-edge
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_interview_event @ix_uids = N'20000140,20090010'"
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_d_interview_postprocessing @interview_uids = N'20000140,20090010', @debug = 0"
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_f_interview_case_postprocessing @ix_uids = N'20000140,20090010', @debug = 0"

# Apply this edge fixture
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C \
  -i /Users/adam/code/nbs/NEDSS-DataReporting/utilities/comparison-fixtures/fixtures/20_links/interview_links.sql

# Re-run Interview event SP — should now project interviewer/interviewee/site UIDs
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_interview_event @ix_uids = N'20000140,20090010'"
```

## Apply the template's stop conditions and final-report shape

Report:
- Apply result.
- Edge rows authored: 6 expected (2 per type_cd).
- Coverage assessment: D_INTERVIEW/D_INTERVIEW_NOTE/F_INTERVIEW_CASE
  populations should be unchanged (LEFT JOINs don't gate). Event SP
  JSON projection should now contain interviewer/interviewee/site UIDs.
- Confirmation deliverables exist.
