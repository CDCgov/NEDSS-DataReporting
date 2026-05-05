# Tier 2 — InvestigationHasNotification

You are a Tier 2 sub-agent. Your edge type is **`Notification`** (NBS
convention; the SRTE code in `AR_TYPE`). Wires Notification act_uid →
Investigation act_uid via `dbo.act_relationship`.

Read `prompts/templates/tier_2_link.md` first — that's the shared
contract. This file fills in edge-specific slots.

This is the **first Tier 2 agent** and the highest-impact edge:

- Resolves Notification's blocked Tier 1 isolation coverage (currently
  0/6 NOTIFICATION + 0/8 NOTIFICATION_EVENT → expected 6/6 + 8/8).
- Populates Investigation's `notification_history` aggregation (event
  SP lines 692–845).
- Feeds downstream HEPATITIS_DATAMART updates from
  `sp_nrt_notification_postprocessing`.

## Edge identity

- **Edge type:** `Notification` (the convention used by NBS for
  NOTF→CASE act_relationships, even though the SP doesn't filter on
  `type_cd` directly — Phase B notes this is "shape consistency with
  NBS data" rather than a hard SP filter).
- **Source:** `act_relationship.source_act_uid = <Notification's act_uid>`,
  `source_class_cd='NOTF'`.
- **Target:** `act_relationship.target_act_uid = <Investigation's act_uid>`,
  `target_class_cd='CASE'`.
- **Catalog citation:** `catalog/edge_types.md` row for `Notification`
  (under `dbo.act_relationship`).

## Endpoints to wire

Two pairs (foundation→foundation + v2→v2):

1. Foundation Notification (`@dbo_Act_notification_uid = 20000110`) →
   Foundation Investigation (`@dbo_Act_investigation_uid = 20000100`)
2. v2 Notification (UID 20060010, per Notification Tier 1) →
   v2 Investigation (UID 20050010, per Investigation Tier 1)

## Your UID block

- **`21000000–21000999`** (first Tier 2 agent gets the lowest 1000-wide
  block in Tier 2's range). Update `catalog/uid_ranges.md`.

## Required reading (in addition to template's list)

- `coverage/coverage_notification.md` — Tier 1 isolation gap. Read
  the "Tier-1-isolation outcome" and "merged-sequence" sections. Your
  edge is what flips this from blocked to clean.
- `coverage/coverage_investigation.md` — line 196 (LINK_REQUIRED #13)
  identifies your edge. Also any other LINK_REQUIRED entries that
  mention notification.
- `liquibase-service/.../routines/064-sp_notification_event-001.sql`
  — line 49 has the INNER JOIN that your edge unblocks.
- `liquibase-service/.../routines/006-sp_nrt_notification_postprocessing-001.sql`
  — lines 79–80 read `inv.INVESTIGATION_KEY` and `cnd.CONDITION_KEY`
  without COALESCE; your edge plus the infrastructure-SP run for
  CONDITION makes those joins resolve.
- `liquibase-service/.../routines/056-sp_investigation_event-001.sql`
  — lines 692–845 build `notification_history`; your edge surfaces
  notifications in the Investigation JSON projection.

## Verification recipe

```sh
cd /Users/adam/code/nbs/NEDSS-DataReporting && docker compose down -v && docker compose up -d nbs-mssql liquibase
until [ "$(docker ps -a --filter name=liquibase --format '{{.Status}}' | head -1 | grep -c 'Exited')" = "1" ]; do sleep 20; done

# Pre-fixture infrastructure SPs (from STRATEGY.md → Merge contract step 2)
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
  -Q "EXEC dbo.sp_get_date_dim 2020, 2030"
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
  -Q "EXEC dbo.sp_nrt_srte_condition_code_postprocessing"

# Verify both populated correctly
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
  -Q "SET NOCOUNT ON; SELECT 'RDB_DATE' AS tbl, COUNT(*) FROM dbo.RDB_DATE UNION ALL SELECT 'CONDITION', COUNT(*) FROM dbo.CONDITION"
# Expected: RDB_DATE > 0 (calendar populated), CONDITION > 0 (SRTE conditions loaded)

# Foundation
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C \
  -i /Users/adam/code/nbs/NEDSS-DataReporting/utilities/comparison-fixtures/fixtures/00_foundation/00_foundation.sql

# Tier 1 fixtures relevant to this edge (Investigation + Notification + Patient)
# Patient is needed because the Notification SP's PATIENT_KEY join now resolves.
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C \
  -i /Users/adam/code/nbs/NEDSS-DataReporting/utilities/comparison-fixtures/fixtures/10_subjects/patient.sql
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C \
  -i /Users/adam/code/nbs/NEDSS-DataReporting/utilities/comparison-fixtures/fixtures/10_subjects/investigation.sql
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C \
  -i /Users/adam/code/nbs/NEDSS-DataReporting/utilities/comparison-fixtures/fixtures/10_subjects/notification.sql

# Run Tier 1 chains in dependency order
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
  -Q "EXEC dbo.sp_patient_event @user_id_list = N'20000000,20020010'"
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
  -Q "EXEC dbo.sp_nrt_patient_postprocessing @id_list = N'20000000,20020010', @debug = 0"

SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
  -Q "EXEC dbo.sp_investigation_event @phc_id_list = N'20000100,20050010'"
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
  -Q "EXEC dbo.sp_nrt_investigation_postprocessing @id_list = N'20000100,20050010', @debug = 0"

# (Notification chain at this point still hits the FK gap — that's
# expected. Don't run it yet.)

# Apply this edge fixture
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C \
  -i /Users/adam/code/nbs/NEDSS-DataReporting/utilities/comparison-fixtures/fixtures/20_links/inv_notification.sql

# The fixture's tail-EXECs should re-run the Notification chain. Verify
# 6/6 NOTIFICATION + 8/8 NOTIFICATION_EVENT.
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
  -Q "SELECT COUNT(*) AS rows_in_NOTIFICATION FROM dbo.NOTIFICATION;
      SELECT COUNT(*) AS rows_in_NOTIFICATION_EVENT FROM dbo.NOTIFICATION_EVENT" -h -1
# Expected: 2 NOTIFICATION rows + 2 NOTIFICATION_EVENT rows (foundation + v2).

# Spot-check: are INVESTIGATION_KEY and CONDITION_KEY now real (not NULL)?
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
  -Q "SELECT NOTIFICATION_KEY, PATIENT_KEY, INVESTIGATION_KEY, CONDITION_KEY FROM dbo.NOTIFICATION_EVENT" -h -1
```

## Apply the template's stop conditions and final-report shape

Report:
- Apply result (clean / iterations).
- Edge rows authored (count + endpoints).
- Coverage unlocked: NOTIFICATION (now N/6), NOTIFICATION_EVENT (now N/8).
- Cross-check: are INVESTIGATION_KEY, CONDITION_KEY, PATIENT_KEY now
  populated to real keys (not sentinel 1)?
- Coverage still LINK_REQUIRED (the COALESCE-to-1 keys for things this
  edge doesn't touch — physician, reporter, etc.).
- Confirmation deliverables exist.
