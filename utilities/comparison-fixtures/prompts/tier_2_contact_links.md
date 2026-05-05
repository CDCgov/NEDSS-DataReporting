# Tier 2 — Contact cross-subject links (nbs_act_entity)

You are a Tier 2 sub-agent. Your edge types are three nbs_act_entity
types for Contact:
- **`SiteOfExposure`** (Contact → Place; exposure site)
- **`InvestgrOfContact`** (Contact → Provider; investigator)
- **`DispoInvestgrOfConRec`** (Contact → Provider; disposition investigator)

All three are MISSING_FROM_SRTE per Phase B but RTR's SP filters on
the literal regardless — author with the literal type_cd values per
established policy.

Read `prompts/templates/tier_2_link.md` first — the shared contract.
This file fills in edge-specific slots.

## Important context: Contact's event SP is broken upstream

`sp_contact_record_event` cannot run at all in baseline 6.0.18.1 — it
references `nbs_odse.dbo.fn_get_value_by_cd_codeset` but that function
lives in `RDB_MODERN.dbo` (cross-DB resolution failure documented in
`coverage_contact.md`). This means:

1. You **cannot** verify these edges via tail-EXEC of the event SP —
   it crashes at parse time.
2. The Contact postprocessing SPs (`sp_d_contact_record_postprocessing`,
   `sp_f_contact_record_case_postprocessing`) read from `nrt_contact`
   staging directly, NOT from `nbs_act_entity`. So this edge has
   **zero RDB_MODERN coverage impact at Tier 1 isolation OR in the
   merged sequence** until the upstream RTR bug is fixed.
3. **The fixture's value is purely shape-consistency** for the
   eventual RDB-vs-RDB_MODERN comparison test against MasterETL —
   MasterETL likely traverses these `nbs_act_entity` rows even though
   RTR currently doesn't reach them.

Author the fixture anyway. Document the upstream bug clearly in
coverage. Skip the tail-EXEC of `sp_contact_record_event`.

## Edge identity

Three nbs_act_entity edge types:

1. **`SiteOfExposure`** — Contact act_uid → Place entity_uid
2. **`InvestgrOfContact`** — Contact act_uid → Provider (Person) entity_uid
3. **`DispoInvestgrOfConRec`** — Contact act_uid → Provider (Person) entity_uid
   (could be a different provider than InvestgrOfContact in production;
   v1 uses same Provider for simplicity)

## Endpoints to wire

Six pairs total (one row each):

For SiteOfExposure (Contact → Place):
1. Foundation Contact (`@dbo_Act_contact_uid = 20000170`) ↔
   Foundation Place (`@dbo_Entity_place_uid = 20000030`)
2. v2 Contact (UID 20120010) ↔ Foundation Place (20000030)
   (Contact Tier 1 has only one v2 Contact; place doesn't have a v2
   distinct enough to warrant separate pairing for v1.)

For InvestgrOfContact (Contact → Provider):
3. Foundation Contact (20000170) ↔ Foundation Provider (20000010)
4. v2 Contact (20120010) ↔ v2 Provider (20010010)

For DispoInvestgrOfConRec (Contact → Provider):
5. Foundation Contact (20000170) ↔ Foundation Provider (20000010)
6. v2 Contact (20120010) ↔ v2 Provider (20010010)

## Your UID block

- **`21010000–21010999`** (eleventh Tier 2 agent — incremented from
  `phc_roles_nae`'s 21009000–21009999). Allocate 6 UIDs:
  21010000–21010005. Update `catalog/uid_ranges.md`.

## CRITICAL: nbs_act_entity is an IDENTITY table

Wrap your INSERTs:

```sql
SET IDENTITY_INSERT [dbo].[nbs_act_entity] ON;
INSERT INTO [dbo].[nbs_act_entity] (...) VALUES ...;
SET IDENTITY_INSERT [dbo].[nbs_act_entity] OFF;
```

## Required reading (in addition to template's list)

- `coverage/coverage_contact.md` — note the `OUT_OF_SCOPE_RTR_BUG`
  finding for `sp_contact_record_event`.
- `liquibase-service/.../routines/069-sp_contact_record_event-001.sql`
  — lines 155-157 (the 3 LEFT JOINs).
- `fixtures/20_links/{vaccination_links,interview_links,phc_roles_nae}.sql`
  — sibling nbs_act_entity patterns.

## Verification recipe

DO NOT tail-EXEC `sp_contact_record_event` (broken). Verify by:
1. Apply foundation + Tier 1 fixtures + edge fixture.
2. SELECT from nbs_act_entity to confirm rows landed.
3. Run Contact postprocessing SPs to confirm they're unaffected (and
   the existing 42/66 D_CONTACT_RECORD coverage from Tier 1 still
   holds — should be unchanged).

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

# Tier 1 fixtures: provider + place + contact
for f in provider place contact; do
  SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C \
    -i /Users/adam/code/nbs/NEDSS-DataReporting/utilities/comparison-fixtures/fixtures/10_subjects/${f}.sql
done

# Run Tier 1 chains: provider, place, then contact's two postprocessing SPs.
# (Contact event SP is broken — skip.)
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_provider_event @user_id_list = N'20000010,20010010'"
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_nrt_provider_postprocessing @id_list = N'20000010,20010010', @debug = 0"
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_place_event @id_list = N'20000030'"
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_nrt_place_postprocessing @id_list = N'20000030', @debug = 0"
# Note: skip sp_contact_record_event (broken upstream).
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_d_contact_record_postprocessing @contact_uids = N'20000170,20120010', @debug = 0"
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_f_contact_record_case_postprocessing @contact_uids = N'20000170,20120010', @debug = 0"

# Capture pre-edge coverage on D_CONTACT_RECORD
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "SELECT COUNT(*) FROM dbo.D_CONTACT_RECORD"

# Apply this edge fixture
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C \
  -i /Users/adam/code/nbs/NEDSS-DataReporting/utilities/comparison-fixtures/fixtures/20_links/contact_links.sql

# Verify rows landed in nbs_act_entity (no tail-EXEC of broken event SP)
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d NBS_ODSE \
  -Q "SELECT type_cd, COUNT(*) FROM dbo.nbs_act_entity WHERE type_cd IN ('SiteOfExposure','InvestgrOfContact','DispoInvestgrOfConRec') GROUP BY type_cd"
```

Note: do NOT include a tail-EXEC of `sp_contact_record_event` in the
fixture file. Document the upstream bug as the reason in a comment.

## Apply the template's stop conditions and final-report shape

Report:
- Apply result.
- Edge rows authored: 6 expected.
- Coverage assessment: 0 RDB_MODERN dim/fact unlocks expected (event SP
  broken; postprocessing reads staging directly). Confirm D_CONTACT_RECORD
  row count and column population are unchanged from Tier 1 baseline.
- OUT_OF_SCOPE: explicitly note the `sp_contact_record_event` upstream bug.
- Confirmation deliverables exist.
