# Tier 2 — Interview to Investigation (IXS)

You are a Tier 2 sub-agent. Your edge type is **`IXS`** (act_relationship
linking Interview act_uid → Investigation act_uid). MISSING from
`AR_TYPE` per Phase B but present in other code sets (`BUS_OBJ_TYPE`,
`INFO_SOURCE_COVID`); RTR's SP filters on the literal regardless.

Read `prompts/templates/tier_2_link.md` first — the shared contract.
This file fills in edge-specific slots.

This edge is **shape-consistency, low coverage value**. The Interview
event SP at line 86 LEFT-JOINs on this — Interview event SP returned
2 rows already at Tier 1 isolation, so this edge doesn't unblock
anything. Adds the Investigation UID context to the JSON projection's
INVESTIGATION_UID field (currently NULL post-`interview_links`).

## Edge identity

- **Edge type:** `IXS` (one type_cd; one connective table — act_relationship)
- **Source:** `act_relationship.source_act_uid = <Interview's act_uid>`
- **Target:** `act_relationship.target_act_uid = <Investigation's act_uid>`
- **source_class_cd:** `'ENC'` (Interview's class — verify in foundation)
- **target_class_cd:** `'CASE'`
- **SP filter:** `065-sp_interview_event-001.sql:85-86` (LEFT JOIN ar1)

## Endpoints to wire

Two pairs:

1. Foundation Interview (`@dbo_Act_interview_uid = 20000140`) →
   Foundation Investigation (`@dbo_Act_investigation_uid = 20000100`)
2. v2 Interview (UID 20090010) → v2 Investigation (UID 20050010)

## Your UID block

- **`21011000–21011999`** (twelfth Tier 2 agent — incremented from
  `contact_links`'s 21010000–21010999). `act_relationship` has a
  composite PK so no surrogate UIDs needed; block is reserved.

## Required reading (in addition to template's list)

- `coverage/coverage_interview.md` and `coverage_interview_links.md`
  — note that INVESTIGATION_UID stays NULL post-interview_links because
  IXS act_relationship is missing.
- `liquibase-service/.../routines/065-sp_interview_event-001.sql`
  — lines 85-86.

## Verification recipe

Same shape as inv_notification:

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

# Foundation + relevant Tier 1 fixtures
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -i .../fixtures/00_foundation/00_foundation.sql
for f in patient provider organization investigation interview; do
  SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C \
    -i /Users/adam/code/nbs/NEDSS-DataReporting/utilities/comparison-fixtures/fixtures/10_subjects/${f}.sql
done

# Run Tier 1 chains
# (etc. — see other Tier 2 prompts for the canonical sequence)

# Apply this edge fixture
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C \
  -i /Users/adam/code/nbs/NEDSS-DataReporting/utilities/comparison-fixtures/fixtures/20_links/interview_phc.sql

# Verify: re-run Interview event SP. JSON projection's INVESTIGATION_UID
# should now be 20000100 / 20050010.
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_interview_event @ix_uids = N'20000140,20090010'"
```

## Apply the template's stop conditions and final-report shape

Report:
- Apply result.
- Edge rows authored: 2 expected.
- Coverage assessment: D_INTERVIEW/D_INTERVIEW_NOTE/F_INTERVIEW_CASE
  unchanged (LEFT JOIN, no unblock). Event-SP JSON projection
  INVESTIGATION_UID flipped NULL→20000100/20050010.
- Confirmation deliverables exist.
