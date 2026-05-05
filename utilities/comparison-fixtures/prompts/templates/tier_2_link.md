# Tier 2 — Cross-subject link (template)

You are a sub-agent on a multi-agent project that generates synthetic
NBS_ODSE INSERTs for RDB-vs-RDB_MODERN comparison testing. This template
covers Tier 2 cross-subject link fixtures. You will receive a per-edge-type
prompt that fills in the `<<EDGE_TYPE>>` slots below; this file is the
shared contract.

Your edge type is `<<EDGE_TYPE>>` — a load-bearing cross-subject edge
(e.g., `InvestigationHasNotification`, `LabReportToInvestigation`,
`SubjOfPHC`, `PerAsReporterOfPHC`, etc.). See
`catalog/edge_types.md` for the full inventory.

## Deliverables

1. `fixtures/20_links/<edge_type_name>.sql` — your additive
   cross-subject `act_relationship` / `participation` / `nbs_act_entity`
   rows, allocated within your UID block. Plus any **post-edge SP
   re-runs** that exercise newly-resolved coverage (these are
   `EXEC` statements at the bottom of the file, not separate scripts).
2. `coverage/coverage_<edge_type_name>.md` — coverage report per the
   schema in STRATEGY.md, focused on **incremental coverage** that
   wiring this edge unlocks (e.g., LINK_REQUIRED entries from Tier 1
   that this edge resolves).
3. Append your UID allocations to `catalog/uid_ranges.md` under the
   Tier 2 section (1000-wide block).

## Required reading (in order)

1. `STRATEGY.md` — pay special attention to:
   - "Tier 2 — Links" decomposition: one agent per edge type.
   - "Merge contract" sequence — particularly the **pre-fixture
     infrastructure SPs** (`sp_get_date_dim`, `sp_nrt_srte_condition_code_postprocessing`)
     that you must invoke before any chain runs.
   - "Failure-mode policy" — when to record `SRTE_GAP`, `LINK_REQUIRED`
     (yes, Tier 2 can find more!), `FOUNDATION_GAP`, `OUT_OF_SCOPE`.
2. `catalog/edge_types.md` — find your edge type. Read the row
   carefully: `type_cd`, source/target class_cd constraints, used-by SPs.
   Pick UIDs from foundation and Tier 1 fixtures that match the
   class_cd constraints.
3. `catalog/rtr_target_columns.md` — for understanding which RDB_MODERN
   columns the wired-edge will affect. Useful for the coverage report.
4. `catalog/uid_ranges.md` — your block is documented in your per-edge
   prompt; allocate within it.
5. `fixtures/00_foundation/00_foundation.sql` — read-only.
6. `fixtures/10_subjects/*.sql` for the subjects your edge connects —
   read the relevant ones to find the canonical UIDs (foundation +
   v2/v3 variants) you'll wire together.
7. `coverage/coverage_*.md` for affected subjects — find the
   `LINK_REQUIRED` entries that mention your edge type. These are your
   *coverage targets*: the columns that will go from NULL/sentinel-1 to
   real values after your edge fires.
8. The relevant SP files — the SPs whose joins depend on your edge.
   Trace exactly which columns get unlocked.

## Connection / sqlcmd usage

Same as Tier 1 — use `SQLCMDPASSWORD` env var, NEVER `-P`:

```sh
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d NBS_ODSE -Q "..."
```

## Method

### Step 1 — Trace the LINK_REQUIRED entries

Grep across `coverage/coverage_*.md` for mentions of your edge type:

```sh
grep -nE "LINK_REQUIRED.*<<edge_type>>|<<type_cd>>" \
  /Users/adam/code/nbs/NEDSS-DataReporting/utilities/comparison-fixtures/coverage/*.md
```

For each hit, identify the (table, column) gaps your edge should
resolve. These are your coverage targets.

### Step 2 — Identify endpoint UIDs

From the foundation file and Tier 1 fixtures, find the canonical UIDs
of the entities/acts your edge connects. For example, if your edge
type is `InvestigationHasNotification`:

- Foundation Investigation: `@dbo_Act_investigation_uid = 20000100`
- v2 Investigation: 20050010 (per Investigation Tier 1 block)
- Foundation Notification: `@dbo_Act_notification_uid = 20000110`
- v2 Notification: 20060010 (per Notification Tier 1 block)

Author edges between **all relevant pairs** (foundation→foundation +
v2→v2, possibly more if subject-pair logic warrants).

### Step 3 — Verify edge-type validity

Confirm against `catalog/edge_types.md`:
- The `type_cd` exists in baseline SRTE (or is documented as
  `MISSING_FROM_SRTE` and used anyway per Phase B's findings).
- The source/target `class_cd` constraints match your endpoint
  entities/acts. Cite the catalog row in a SQL comment above each
  INSERT.

### Step 4 — Author the fixture

`fixtures/20_links/<<edge_type_name>>.sql`:

- `USE [NBS_ODSE]` at the top.
- DECLARE every UID at the top (your block) plus references to the
  cross-subject UIDs (foundation/Tier 1) you're wiring.
- INSERT the connective-table rows (`act_relationship`,
  `participation`, or `nbs_act_entity`).
- **`nbs_act_entity` only**: `nbs_act_entity_uid` is an IDENTITY column.
  To use UIDs from your assigned block, wrap your INSERT with:
  ```sql
  SET IDENTITY_INSERT [dbo].[nbs_act_entity] ON;
  INSERT INTO [dbo].[nbs_act_entity] (...)
  VALUES (...);
  SET IDENTITY_INSERT [dbo].[nbs_act_entity] OFF;
  ```
  `act_relationship` and `participation` use composite PKs and don't
  need surrogate UIDs at all.
- `N'...'` strings, `'2026-04-01T00:00:00'` default datetime.
- Common columns: `add_time`, `add_user_id=@superuser_id`,
  `record_status_cd='ACTIVE'`, `status_cd='A'`, etc.
- Cite each `type_cd` choice with `code_set_nm` and the catalog
  reference in a comment.

#### Post-edge SP re-runs (at the bottom of the file)

After your INSERTs, append the `EXEC` statements that re-run the
relevant Tier 1 chains so coverage can be verified end-to-end. For
example, if you wired Notification→Investigation, append:

```sql
USE [RDB_MODERN];

-- Re-run Notification chain — INVESTIGATION_KEY/CONDITION_KEY now resolve.
EXEC dbo.sp_nrt_notification_postprocessing
  @notification_uids = N'20000110,20060010', @debug = 0;
```

The merge orchestrator runs these `EXEC` statements as part of step 7
in the Merge contract sequence.

### Step 5 — Verification recipe (focused merged-sequence)

Run this on a fresh baseline:

```sh
cd /Users/adam/code/nbs/NEDSS-DataReporting && docker compose down -v && docker compose up -d nbs-mssql liquibase
until [ "$(docker ps -a --filter name=liquibase --format '{{.Status}}' | head -1 | grep -c 'Exited')" = "1" ]; do sleep 20; done

# Pre-fixture infrastructure SPs
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
  -Q "EXEC dbo.sp_get_date_dim 2020, 2030"
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN \
  -Q "EXEC dbo.sp_nrt_srte_condition_code_postprocessing @condition_cd_list = N'10110', @debug = 0"
# Note: SP signature requires @condition_cd_list (varchar list of condition codes).
# v1 uses '10110' (Hep A acute) per STRATEGY.md single-condition-per-family.

# Foundation
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C \
  -i /Users/adam/code/nbs/NEDSS-DataReporting/utilities/comparison-fixtures/fixtures/00_foundation/00_foundation.sql

# Tier 1 fixtures relevant to your edge type only — apply them in any order
# (UID-range discipline ensures no collisions). For Notif→Inv:
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C \
  -i .../fixtures/10_subjects/investigation.sql
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C \
  -i .../fixtures/10_subjects/notification.sql

# Run the relevant Tier 1 chains (event + postprocessing SPs) for those
# subjects. Order matters: dependencies first.
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_investigation_event ..."
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "EXEC dbo.sp_nrt_investigation_postprocessing ..."
# (Notification's chain at this point still hits the FK gap — its event SP
# returns 0 rows because act_relationship is missing. That's expected
# pre-edge.)

# Apply your edge fixture
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd -S localhost,3433 -U sa -C \
  -i .../fixtures/20_links/<<edge_type_name>>.sql

# The fixture's tail-EXECs re-run the affected chains. Verify they now
# COMPLETE without the previous errors.

# Coverage check: query the affected RDB_MODERN tables, count
# previously-NULL columns that are now populated.
SQLCMDPASSWORD=PizzaIsGood33! sqlcmd ... -Q "SELECT * FROM dbo.NOTIFICATION_EVENT" -y 0 -Y 0
```

If your edge type needs all 12 Tier 1 fixtures applied (e.g., a
Datamart-prerequisite edge), apply them all. The "focused" sequence
is just an optimization — full sequence works too.

## Forbidden in Tier 2

- **No new ODSE entity rows** (Person, Entity, Organization, Place,
  Act, Public_health_case, Observation, etc.). Your edge wires
  existing entities/acts. If you find you need a new endpoint, that's a
  Tier 1 amendment, not Tier 2.
- **No SRTE writes.** If your `type_cd` requires an SRTE code that
  doesn't exist, document as `SRTE_GAP` (consistent with Phase B's
  `MISSING_FROM_SRTE` flagged codes — those are intentionally
  retained, since RTR SPs filter on the literal regardless).
- **No foundation modifications.** No `UPDATE` / `DELETE` against
  foundation rows or Tier 1 fixtures' rows. Append-only.
- **No INSERTs into RDB_MODERN dimension/fact tables** (D_PATIENT,
  INVESTIGATION, NOTIFICATION_EVENT, etc.). Those are the SP chains'
  output. You exercise them via the post-edge `EXEC` re-runs.
- **No infrastructure-SP invocation in your fixture file.** The merge
  orchestrator handles `sp_get_date_dim` and
  `sp_nrt_srte_condition_code_postprocessing` once per session
  (per the Merge contract step 2). Don't duplicate.
- `IF NOT EXISTS` guards. Fresh baseline, no idempotency.

## Coverage report (`coverage/coverage_<<edge_type_name>>.md`)

Use the schema in STRATEGY.md → "Coverage report schema". Tier 2's
report should focus on:

1. **Edges authored** — table of edge rows with type_cd / source / target.
2. **Coverage unlocked** — for each (table, column) pair previously
   marked LINK_REQUIRED in Tier 1 coverage reports, show:
   - The Tier 1 coverage report that flagged it.
   - The before-state value (NULL or sentinel 1).
   - The after-state value (real key, real text, etc.).
3. **Coverage still LINK_REQUIRED** — pairs not yet resolved by your
   edge that depend on other Tier 2 agents' edges. Cite which edges.
4. **OUT_OF_SCOPE** for any column the catalog mentions but neither
   this edge nor any Tier 2 edge resolves (datamart-only, Tier 3, etc.).

## Stop conditions

Done when ALL of:

- Your edge fixture applies cleanly against a fresh baseline + relevant
  Tier 1 fixtures + their chains.
- Post-edge SP re-runs COMPLETE without errors.
- All LINK_REQUIRED entries from Tier 1 coverage reports that name
  your edge type are either resolved or documented as still-blocked
  (waiting on another Tier 2 edge).
- Coverage report exists, including the standard schema.
- `uid_ranges.md` extended with your Tier 2 block.
- You have not modified foundation, Tier 1, or any other Tier 2 agent's
  outputs.

Stop and hand back. Do not start other Tier 2 edge types.

## Final report

When you reply back, include:

- Apply result (clean / iterations).
- Edge rows authored: count + edge_type_cd + endpoint summary.
- Coverage unlocked: count of (table, column) pairs flipped from
  NULL/sentinel-1 to real values.
- Coverage still LINK_REQUIRED (with which edges they're waiting on).
- OUT_OF_SCOPE / SRTE_GAP / FOUNDATION_GAP findings.
- Decisions made under prompt ambiguity.
- Confirmation all three deliverables exist.
