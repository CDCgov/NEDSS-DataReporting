# Comparison Fixtures — Strategy

## Goal

Produce a synthetic but referentially-valid set of NBS_ODSE INSERTs that, after
RTR's full transformation chain runs against them, exercises every RDB_MODERN
table and column RTR is capable of populating from the post-baseline state.
Output is consumed by a yet-to-be-built comparison tool (modeled on
NEDSS-DataCompare) that diffs RDB (MasterETL) against RDB_MODERN (RTR).

This effort is in scope only for step (1) of the comparison pipeline:

1. **Populate ODSE.** ← this work
2. Run MasterETL.
3. Run RTR initial hydration.
4. Diff RDB vs RDB_MODERN.

MasterETL is **out of scope** for fixture authoring. RTR is the unit of analysis.
Tables/columns MasterETL writes that RTR does not are flagged in the final
coverage report as suspected gaps in RTR — not as fixture targets.

## Baseline

Every fixture run begins from a freshly restored baseline. The baseline is:

- The `ghcr.io/cdcent/nedssdb:latest` MSSQL image started with environment
  variable `DATABASE_VERSION=6.0.18.1` (hard-coded at
  `docker-compose.yaml` line 6).
- Migrated through `NEDSSDB/src/migrations/6.0.18.1` (RDB, ODSE, SRTE).
- Liquibase-applied by `reporting-pipeline-service` — i.e. all RTR tables,
  views, functions, and stored procedures from
  `NEDSS-DataReporting/liquibase-service/src/main/resources/db/` are present in
  RDB_MODERN.
- Standard golden seed users created (`superuser`, `rtr_admin`,
  `rtr_service_user`).

The baseline contains a fully populated SRTE (condition codes, code-set values,
nbs_ui_metadata) and pre-seeded LDF metadata for templates. Fixture agents
**MUST** ground every code (`condition_cd`, `type_cd`, `class_cd`, etc.) by
querying SRTE in the live baseline DB — never by inventing codes that look
plausible.

### Connection details

```
Host:      localhost
Port:      3433
DBs:       NBS_ODSE, NBS_SRTE, RDB, RDB_MODERN, NBS_MSGOUTE
User:      sa
Password:  ${DATABASE_PASSWORD:-PizzaIsGood33!}
```

**sqlcmd from agents.** Pass the password via the `SQLCMDPASSWORD` env var,
not `-P` — the `!` in the password triggers zsh history expansion when
double-quoted, which causes intermittent auth failures. Set it once and omit
`-P` entirely:

```sh
export SQLCMDPASSWORD=PizzaIsGood33!
sqlcmd -S localhost,3433 -U sa -C -d NBS_SRTE -Q "SELECT @@VERSION"
```

Stand up the baseline:

```sh
cd /Users/adam/code/nbs/NEDSS-DataReporting
docker compose up -d nbs-mssql liquibase
# wait for liquibase to log "Migrations complete" — ~3-5 minutes
```

Reset between runs by `docker compose down -v && docker compose up -d nbs-mssql liquibase`.

### Idempotency

Fixtures are **not** idempotent. Each run starts from a fresh restore. Agents
do not write `IF NOT EXISTS` guards. UID collisions are forbidden by the UID
range registry (below), not papered over with conditional inserts.

## RTR transformation chain (verification recipe)

Each `sp_nrt_*_postprocessing` SP reads from a `dbo.nrt_*` staging table in
RDB_MODERN. In production, staging is populated by **SQL Server CDC →
Debezium → Kafka → kafka-connect JDBC sink**. The `sp_<entity>_event` SP is
**not** the staging writer — it emits a JSON projection of ODSE rows for
downstream consumption; it does not `INSERT INTO nrt_*`. (Verified directly
in the SP body — see Provider canary findings.)

For fixture verification we deliberately bypass the CDC pipeline and write
synthetic `nrt_<entity>` rows by hand, alongside the ODSE INSERTs, in the
same fixture file. This is a fixture-authoring shortcut, not a model of
production:

- We care about the **postprocessing SP's transformation logic** (nrt_* →
  RDB_MODERN). That's what the comparison test diffs.
- We do **not** care about Debezium's CDC-shape fidelity in this project.
  Production-fidelity of CDC payloads is a separate concern verified
  elsewhere (or out of scope entirely).
- Bringing up Debezium + Kafka + kafka-connect locally and waiting 60–90s
  for staging to flow would slow iteration to a crawl and add four services
  to every reset.

```
ODSE INSERTs                               (in fixture .sql)
   +
synthetic nrt_<entity> INSERTs             (in fixture .sql; mirrors what
                                            Debezium would have produced)
   ↓
EXEC dbo.sp_nrt_<entity>_postprocessing @id_list = '<csv>'   -- nrt_* → RDB_MODERN
   ↓
RDB_MODERN dimensions / facts
```

The event SP (`sp_<entity>_event`) is **not invoked** in fixture
verification — it's a no-op for our purposes since its only side effect is
the JSON-emit query, and the staging row we'd want it to produce is the one
we just hand-authored.

Authoring guidance: when authoring an `nrt_<entity>` row, read the
postprocessing SP body to discover which staging columns it reads. Inspect
`nrt_<entity>` DDL with `INFORMATION_SCHEMA.COLUMNS` for NOT-NULL
constraints and skip any `generated_always_type IN (1,2)` columns
(temporal-table system-period columns). If a staging column is read by the
postprocessing SP but not visible in the event SP's JSON projection, prefer
the postprocessing SP as ground truth.

### Convention: postprocessing SPs read NRT staging only — never ODSE

**Load-bearing architectural invariant** (verified against the entire
`liquibase-service/src/main/resources/db/005-rdb_modern/routines/` tree,
2026-05-19):

- **`sp_*_event` SPs read `nbs_odse.dbo.*` directly** — that is their
  whole job. They project ODSE rows into JSON for downstream NRT
  staging. The 11 files that contain `FROM nbs_odse.dbo.*` /
  `JOIN nbs_odse.dbo.*` are all `*_event` SPs (e.g.
  `sp_observation_event`, `sp_investigation_event`,
  `sp_patient_event`, etc.) plus `sp_user_report_permissions`.
- **`sp_nrt_*_postprocessing` SPs (and `sp_d_*` and `sp_*_datamart_*`
  variants) read RDB_MODERN-side staging only — `nrt_*` tables and
  `#tmp_*` temp tables derived from them. Zero references to
  `nbs_odse.dbo.*` in the postprocessing layer.** The CSV columns
  on NRT staging rows (e.g. `nrt_morbidity_observation.followup_observation_uid`,
  `nrt_observation.associated_phc_uids`) are the upstream debezium
  projection of the act_relationship / participation graph and are
  how postprocessing walks edges without re-traversing ODSE.

**Implications for agents proposing RTR fixes (Tier 3, bug investigations,
SP rewrites):**

- If you find yourself wanting to `JOIN nbs_odse.dbo.act_relationship`
  or any other `nbs_odse.dbo.*` table inside a `sp_nrt_*_postprocessing`
  or `sp_d_*` SP, **stop and look for the staging-side projection**.
  The upstream NRT row almost certainly carries a CSV column or a
  pre-joined value that collapses the graph walk you were about to
  perform via cross-DB read. The CSV idiom looks like
  `CROSS APPLY string_split(<csv_col>, ',') AS x` joined to
  `#morb_obs_reference` / equivalent and filtered by
  `obs_domain_cd_st_1` (or analogous role-code column).
- Cross-DB joins to ODSE from postprocessing SPs will be bounced in
  RTR review on architectural grounds, regardless of whether the
  query is correct. Match the layer's convention.
- **Exception:** the event SPs themselves. If you are editing
  `sp_*_event`, cross-DB ODSE reads are the norm.

This convention was reinforced by bug #3
(`sp_d_morbidity_report_postprocessing` user-comment query): the
first fix attempted a two-hop `nbs_odse.dbo.act_relationship`
traversal; the second-iteration fix uses the staging CSV
`followup_observation_uid` already projected by NRT. The second
fix is the one that landed. See
`bugs/03_morb_rpt_user_comment/pr.md`.

Datamart SPs (Hepatitis_Datamart, Std_Hiv_Datamart, dyn_dm_*, etc.) have no
`_event` partner — they read from already-populated RDB_MODERN dimensions and
are invoked directly after Tier 1 / Tier 2 are merged.

## Decomposition: graph-first, SP-second

The fixture is built in tiers. Each tier's outputs become the next tier's
read-only dependencies.

### Tier 0 — Foundation

Single agent. Produces `fixtures/00_foundation/00_foundation.sql`:

- Reference UIDs (superuser).
- Any condition codes, LDF templates, or NBS_UI_metadata rows the baseline
  *doesn't* already provide but Tier 1+ depend on (must be discovered, not
  assumed).
- One canonical instance of each parent entity that downstream agents attach
  edges to. Concretely: one Patient (Person+Entity), one Provider (Person+Entity),
  one Organization, one Place, one Investigation (Public_health_case+Act), one
  Notification, one Lab Report (Observation+Act), one Morbidity Report,
  one Interview, one Treatment, one Vaccination, one Contact Record.

UID range: `20000000–20009999`.

### Tier 1 — Subjects

One agent per canonical subject (~11). Each agent owns the *internal* edges of
its subject (e.g., Lab Report owns its Observation hierarchy and the
Participation rows linking it to its own Patient and Ordering Provider, but
**not** the link from a Lab to a separate Investigation — that's a Tier 2 edge).

A Tier 1 agent **does not** modify or re-create foundation rows. If its SP
needs variants of foundation rows (e.g., a second patient with `deceased_ind_cd
= 'Y'` to hit a CASE branch), it creates them inside its own UID range and the
new entities are *additions*, not replacements.

Each Tier 1 agent's contract:

1. Read the SP body (event SP + postprocessing SP).
2. Static-extract every column written to RDB_MODERN and the gating predicates.
3. Author ODSE INSERTs that maximize column population, grounded in baseline
   SRTE (verified by `sqlcmd` SELECTs).
4. Verify by `EXEC` of event + postprocessing SPs against a fresh baseline +
   foundation + this fixture.
5. Emit `coverage_<subject>.md` listing populated columns, deliberately-skipped
   columns with reasons, SRTE_GAPS, and any cross-subject edges it expects
   Tier 2 to provide.

UID ranges per subject — see `catalog/uid_ranges.md` (allocated as agents claim
ranges).

### Tier 2 — Links

Cross-subject edges only.

**Decomposition: one agent per edge type.** Phase B's `edge_types.md`
catalog enumerates ~10 load-bearing edge types. Each gets its own
Tier 2 agent producing `fixtures/20_links/<edge_type>.sql` plus a
matching `coverage/coverage_<edge_type>.md`. Agents are independent
(except where one edge type genuinely depends on another — rare).

Examples (one agent each):

- `act_relationship_inv_notification` — `act_relationship` rows of
  `type_cd='InvestigationHasNotification'` linking the foundation
  Investigation to the foundation Notification (and v2 Investigations
  to v2 Notifications). Resolves Notification's INNER JOIN that
  blocks coverage at Tier 1 isolation.
- `act_relationship_lab_inv` — Lab → Investigation
  (`type_cd='LabReportToInvestigation'`).
- `act_relationship_morb_inv` — Morbidity → Investigation.
- `act_relationship_treatment_inv` — Treatment → Investigation
  (`type_cd='TreatmentToPHC'`).
- `participation_patient_phc` — `SubjOfPHC` linking foundation Patient
  to foundation Investigation. Resolves Patient-Investigation context
  that drives Datamart-side patient columns.
- `participation_reporter_phc` — `PerAsReporterOfPHC` /
  `OrgAsReporterOfPHC` linking Provider/Organization to Investigation
  as reporter.
- `participation_physician_phc` — `PhysicianOfPHC` linking Provider to
  Investigation as physician of record.
- `nbs_act_entity_vaccination` — `SubOfVacc` + `PerformerOfVacc`
  linking Vaccination to Patient + Provider.
- `nbs_act_entity_interview` — interview-participant edges.

Tier 2 agents read the UID range registry to find subject UIDs. They
pick edge `type_cd`s from `catalog/edge_types.md` (built in Phase B
from live baseline SRTE), never invent them.

**Pre-Tier-2 infrastructure step.** Before any Tier 2 agent runs, the
verification recipe must invoke two RTR infrastructure SPs to populate
project-wide dimension tables that are empty in the pristine baseline:

- `dbo.RDB_DATE` calendar population. **Note**: `sp_get_date_dim` in
  baseline 6.0.18.1 has an RTR bug — references non-existent
  `dbo.rdb_date_temp` table and has a `#temp_date` scope bug at
  lines 49-55 of `014-sp_get_date_dim-001.sql`. Until upstream RTR
  fixes the SP, populate `RDB_DATE` via a recursive CTE in the merge
  orchestrator. Required because `NOTIFICATION_EVENT`, `LAB_TEST_RESULT`,
  `TREATMENT_EVENT`, etc. have FKs to `RDB_DATE.DATE_KEY` that fail if
  the table is empty.
- `EXEC dbo.sp_nrt_srte_condition_code_postprocessing @condition_cd_list = N'<csv>', @debug = 0`
  — populates `CONDITION` from SRTE for the listed condition codes.
  Required because the Notification chain (and others) read
  `CONDITION_KEY` without COALESCE. **Note**: the SP signature requires
  `@condition_cd_list` (varchar list). For v1 (single-condition-per-family
  per STRATEGY.md), pass `N'10110'` for Hep A acute. The SP filters its
  SRTE source to only those condition codes.

These run *once* per merged-fixture session, after foundation applies
and before the first Tier 2 agent's chain runs. They are not the
responsibility of any individual Tier 2 agent; the merge orchestrator
runs them. (See "Merge contract" section below.)

**Tier 2 agents do not modify foundation, Tier 1 fixtures, or other
Tier 2 fixtures' outputs.** Each agent's output is purely additive
ODSE INSERTs (and the cross-subject connective-table rows) keyed in
its own UID block. After applying its fixture, the agent re-runs
relevant Tier 1 chains (e.g., the Notification chain after wiring
Notif → Inv) to verify coverage extends — but it does *not* author
any RDB_MODERN dimension/fact rows.

**Verification: focused merged-sequence per agent.** Each Tier 2 agent
verifies in this sequence on a fresh baseline:
1. `docker compose down -v && up -d`
2. Apply foundation.
3. Run the two infrastructure SPs.
4. Apply *only the Tier 1 fixtures relevant to this edge type* (e.g.,
   for `act_relationship_inv_notification`: foundation + Investigation
   Tier 1 + Notification Tier 1 — not all 12).
5. Run the relevant Tier 1 chains in dependency order.
6. Apply this agent's `<edge_type>.sql`.
7. Re-run any Tier 1 chains whose coverage depends on the new edges
   (e.g., Notification's chain after the act_relationship is wired).
8. Spot-check coverage: which previously-NULL columns are now populated
   and which still need other Tier 2 agents' edges?

This reduces baseline-reset cost and isolates failures.

**UID range:** Each Tier 2 agent allocates within `21000000–21099999`,
claiming a 1000-wide block per agent (`21000000-21000999` for the
first agent, `21001000-21001999` for the second, etc.). Update
`catalog/uid_ranges.md` as part of each agent's deliverable.

### Tier 3 — Gap-driven SP coverage

Runs only on SPs whose verification step (Tier 1 or post-Tier-2) reports
uncovered RDB_MODERN columns reachable by the SP's logic. Tier 3 agents add
small, targeted ODSE rows or variants to hit the missing branches. They never
modify foundation or existing subjects.

## Phase 0 — RTR target-column map

Before any fixture work, a static analysis pass extracts from every RTR
routine in `liquibase-service/src/main/resources/db/005-rdb_modern/routines/`
the set of (table, column) pairs RTR ever writes to. Output:
`catalog/rtr_target_columns.md`. This is the canonical scope file. Every Tier 1
coverage report is measured against it.

## Phase B — Edge-type catalog

A second static-and-dynamic analysis: enumerate from live baseline SRTE every
legal `type_cd` value for the connective tables — `act_relationship`,
`participation`, `nbs_act_entity`, `entity_locator_participation`, `role`,
`act_id` — together with the source/target `class_cd` constraints each
type_cd implies. Output: `catalog/edge_types.md`.

Agents constructing edges select rows from this catalog rather than authoring
codes inline.

## UID range registry

Single source of truth: `catalog/uid_ranges.md`.

Reservation rules:

- Tier 0 owns `20000000–20009999`. Allocates one block per canonical entity.
- Each Tier 1 agent is granted a 10000-wide block in `200_____0–200_____9999`.
- Tier 2 agents allocate within `21000000–21099999`.
- Tier 3 agents allocate within `22000000–22099999`.
- Sentinel UIDs (e.g., `superuser_id = 10009282`) are referenced by symbolic
  name through DECLAREs and never reallocated.
- An agent allocates only within its assigned block. Cross-references to other
  agents' UIDs are by reading the registry, not by guessing.
- Foreign key targets that live outside ODSE (e.g., SRTE codes) are by string
  value, never UID.

## Output layout

```
NEDSS-DataReporting/utilities/comparison-fixtures/
├── STRATEGY.md                          # this file
├── catalog/
│   ├── rtr_target_columns.md            # Phase 0 output
│   ├── edge_types.md                    # Phase B output
│   ├── uid_ranges.md                    # registry
│   └── subjects.md                      # canonical subject definitions
├── fixtures/
│   ├── 00_foundation/
│   │   └── 00_foundation.sql
│   ├── 10_subjects/
│   │   └── <subject>.sql                # one per Tier 1 agent
│   ├── 20_links/
│   │   └── <edge_type>.sql              # one per Tier 2 agent
│   └── 30_sp_coverage/
│       └── <sp_name>.sql                # only for Tier 3 gaps
├── coverage/
│   ├── coverage_<subject>.md            # Tier 1
│   ├── coverage_<edge_type>.md          # Tier 2
│   └── coverage_<sp_name>.md            # Tier 3
├── prompts/
│   ├── phase_0_target_columns.md
│   ├── phase_b_edge_catalog.md
│   ├── tier_0_foundation.md
│   └── templates/
│       ├── tier_1_subject.md
│       ├── tier_2_link.md
│       └── tier_3_sp_gap.md
└── scripts/
    ├── reset_baseline.sh
    ├── apply_fixture.sh
    └── verify_sp.sh
```

## Merge contract

Final assembled fixture is applied in this deterministic sequence:

1. `docker compose down -v && up -d nbs-mssql liquibase` (fresh baseline).
2. **Pre-fixture infrastructure** — populate project-wide dimension
   tables that are empty in the pristine baseline:
   - `RDB_DATE` calendar — populate via recursive CTE (NOT `sp_get_date_dim`,
     which has an RTR bug — see "Pre-Tier-2 infrastructure step" section above).
     The orchestrator (`scripts/merge_and_verify.sh`) handles this.
   - `EXEC dbo.sp_nrt_srte_condition_code_postprocessing @condition_cd_list = N'10110', @debug = 0`
     (populates `CONDITION` from SRTE for the listed condition codes —
     v1 uses Hep A acute as the canonical condition).
3. `fixtures/00_foundation/00_foundation.sql`.
4. `fixtures/10_subjects/*.sql` — alphabetical, order should not matter
   given UID-range discipline.
5. **Tier 1 chains** — run the full event+postprocessing SP chain in
   dependency order (organization → provider → patient → place →
   investigation → notification → lab → interview → treatment →
   vaccination → contact). Some fact tables may still be partial here
   if they depend on cross-subject edges; that's resolved by Tier 2.
6. `fixtures/20_links/*.sql` — Tier 2 cross-subject edges.
7. **Re-run Tier 1 chains** affected by Tier 2 edges (e.g., Notification
   chain after `act_relationship_inv_notification`). Now-resolved keys
   should populate to their canonical values, not sentinel 1.
8. `fixtures/30_sp_coverage/*.sql` — Tier 3 gap-driven additions.
9. **Datamart SPs** — invoke the datamart chain (Hepatitis_Datamart,
   Std_Hiv_Datamart, dyn_dm_*, etc.) for end-to-end coverage.

If two agents' files contain conflicting `INSERT INTO X (uid, ...)` statements
on the same UID, that's a contract violation and the merge fails loudly.
There is no auto-deduplication.

## Failure-mode policy

When an agent finds it cannot populate a column without exceeding its scope:

- **Missing SRTE row** → record as `SRTE_GAP: <description>` in the coverage
  report. Do not seed SRTE from a Tier 1+ agent.
- **Missing foundation entity** → record as `FOUNDATION_GAP` and stop. Tier 0
  is amended in a follow-up, then dependent agents re-run.
- **Missing cross-subject edge** → record as `LINK_REQUIRED: <edge_spec>` for
  Tier 2 to pick up.
- **Genuinely unreachable column** (dead code, RDB-only, MasterETL-only) →
  record as `OUT_OF_SCOPE: <reason>` with file:line citation.

Silent skips are forbidden.

## Coverage report schema

Every coverage report is markdown with these sections, in order:

```markdown
# Coverage: <artifact name>

## Inputs
- Baseline: 6.0.18.1
- UID range allocated: <block>
- Foundation dependencies: <list of foundation entity names>
- Other-agent dependencies: <list of UID range registry entries>

## SPs verified
- `dbo.sp_<entity>_event` — exit code: 0 / rows-written: N
- `dbo.sp_nrt_<entity>_postprocessing` — exit code: 0 / rows-written: N

## Columns populated
| Table | Column | Sample value |
| ...   | ...    | ...          |

## Columns deliberately skipped
| Table | Column | Reason | Citation |

## Gaps reported
- SRTE_GAP: ...
- FOUNDATION_GAP: ...
- LINK_REQUIRED: ...
- OUT_OF_SCOPE: ...
```

## Build order

1. `STRATEGY.md` (this file).
2. Phase 0 prompt → `catalog/rtr_target_columns.md`.
3. Phase B prompt → `catalog/edge_types.md`.
4. Tier 0 prompt → `fixtures/00_foundation/00_foundation.sql` +
   `coverage/coverage_foundation.md`.
5. **Provider** as first Tier 1 agent, end-to-end. Drives the Tier 1 template.
6. Tier 1 template (`prompts/templates/tier_1_subject.md`).
7. Remaining Tier 1 agents in parallel batches (organization → provider →
   patient → place → investigation → notification → lab → interview →
   treatment → vaccination → contact).
8. Tier 2 template + agents.
9. Tier 3 template + agents (only on reported gaps).
10. Final merge + full-chain verification — `scripts/merge_and_verify.sh`
    runs the deterministic 9-step Merge contract end-to-end (reset →
    infrastructure SPs → foundation → Tier 1 fixtures → Tier 1 chains →
    Tier 2 fixtures → re-run affected Tier 1 chains → Tier 3 → datamart).
    First successful end-to-end run produces ~25 RDB_MODERN dim/fact
    rows across 19 target tables and ~22 cross-subject connective rows.

## Follow-on / phase-2

Captured here so they don't get lost as we focus on v1:

- **Multi-condition variants per disease family.** v1 uses one canonical
  condition per family (e.g., one Hepatitis condition). Datamart columns
  whose logic branches on specific condition codes will be partially covered.
  Phase 2 fans out one investigation per condition code.
- **Subject catalog expansion.** v1 catalog includes the 11 subjects listed
  in Tier 0. Add: Death Record, Aggregate Report, Document, Employer/Insurer
  variants of Organization, Specimen-only observations, additional Place
  types.
- **MasterETL-side coverage.** v1 measures only RTR coverage. After v1,
  re-run analysis against MasterETL SPs in `NEDSSDB/src/migrations/*/RDB/`
  and identify columns MasterETL writes that v1 doesn't exercise.
- **LDF coverage breadth.** v1 seeds one LDF per LDF-type per data-type. Phase
  2 expands to multiple LDFs per type and exercises edge cases like
  multi-select coded LDFs.
- **Repeating-block cardinality > 3.** v1 uses N=3. Phase 2 tests N=1, N=10
  to flush off-by-one logic in `sp_dyn_dm_repeat*`.

- **TODO: ~80 RDB tables nobody on the team currently knows how to populate
  via ODSE inputs.** Per a teammate's note (2026-05): a substantial set of
  legacy RDB tables (DM_INV_*, HEP100, LAB101, SR100, TB_DATAMART,
  TB_HIV_DATAMART, VAR_DATAMART, NBS_CASE_ANSWER_REPT, GEOCODING_LOCATION,
  HEPATITIS_CASE, PERTUSSIS_CASE, RUBELLA_CASE, MISSING_LAB_CASES,
  STAGING_KEY_REPEATING_FINAL, SUMM_DATAMART, VACC_DIFFERENTIAL_*,
  VACC_DISASSOCIATED_TABLE, the various LDF_* / *_LDF / *_LDF_GROUP
  tables, plus L_ADDL_RISK / L_DISEASE_SITE / L_GT_12_REAS /
  L_HC_PROV_TY_3 link tables) are written only by MasterETL — no
  documented ODSE input pattern populates them through RTR. Most
  appear in our Phase 0 catalog as dynamic-SQL targets or are
  populated only after specific datamart SPs run. **Action items**:
  (1) cross-reference the teammate's full list against
  `coverage/coverage_merged.md`'s "Empty (59)" category to find
  overlaps. (2) for each ODSE-unknown table, document in the
  catalog whether it's MasterETL-only (RTR doesn't write it →
  flag as comparison-test gap, not a fixture gap), datamart-SP-driven
  (would populate at Merge step 9 → out of scope for v1), or
  genuinely uninvestigated (belongs in a Tier 3 spike). (3) Once
  the comparison test runs, columns in MasterETL-only tables
  will diff as "RDB has rows, RDB_MODERN doesn't" — that's a
  legitimate finding about RTR coverage gaps, not a fixture bug.

## Progress log

### 2026-05-21 — Phase 2 fanout + overnight autonomous loop

Coverage: **21.8% → 41.4% column coverage** (1004 → 1913 cols
populated; 48 → 66 fully covered tables; 46 → 16 empty). Wall-clock
~5 min for the full pipeline; zero errors in the final run. Split
into two sessions: the daytime Phase-2 fanout landed 33.9% (TB +
STD/HIV + BMIRD + Var + COVID + d_investigation_repeat fixtures);
the overnight autonomous loop added 9 more iterations to land at
41.4% — including case_management + summary_report_case +
aggregate_report fixtures + 2 LDF answer chains + a broad
nrt_investigation enrichment UPDATE pattern (lifted covid/tb/var
datamarts by 30+ cols each) + a COVID contact fixture (lifted
covid_contact_datamart 0→71/94). See SESSION_SUMMARY.md for the
full overnight log.

**Built today**:
- `catalog/odse_unknown_tables.md` — 94-table classification of the
  teammate's ODSE-unknown TODO above (resolves action items 1-2 of
  the Phase 2 follow-on). 22 MasterETL-only, 38 datamart-SP-driven,
  34 Tier-1/Tier-2 reachable.
- Phase-2 full-chain fixtures for TB, COVID, Varicella, STD/HIV
  (Syphilis primary), BMIRD (Strep pneumoniae invasive) — see
  `fixtures/30_sp_coverage/*_investigation_full_chain.sql`. Each
  authors a full ODSE `act` + `public_health_case` + `act_id` +
  `case_management` chain, the `nrt_investigation` staging row, and
  the family-specific `nbs_case_answer` rows that drive the dim
  cluster downstream.
- `d_investigation_repeat.sql` — Tier 3 fixture for the largest
  partial dim. Schema widened 244 → 252 cols via the SP's dynamic
  ALTER TABLE loop; full population blocked by bug #10.
- Orchestrator improvements: liquibase image rebuild on reset
  (working-tree routines reach the running DB without depending on
  `runOnChange` checksums); dynamic-datamart chain wired into Step 9
  via runtime discovery against `v_nrt_nbs_page`; Step 9 ordering
  fix (PAM fact SPs run before condition datamarts); `db_lock.sh`
  for parallel-agent DB coordination.
- `METHODOLOGY.md` — distilled "how we built this" writeup for
  outside readers (NBS/RTR-fluent).
- `DEMO.md` — live-demo cheat-sheet with terminal commands + talking
  points.

**Bugs surfaced (11 total)**:
- 5 fixed upstream via separate PRs (bugs #1, #2, #4, #6, plus
  #769 pre-dated the project)
- 3 squashed onto this branch as standalone commits (bugs #3, #5a,
  #7, #8) since upstream PRs stalled
- 3 documented with repros for follow-up (bugs #9 dyn_dm UNPIVOT;
  #10 sp_sld_investigation_repeat surrogate-key; #11
  sp_aggregate_report_datamart schema mismatch)
- 3 additional issues noted in `bugs/README.md` but not promoted to
  their own dirs (BMIRD INSERT dedup; CMG sentinel duplication;
  COVID_CASE_DATAMART varchar(2000) row-size warning)

**Bugfix on aw/odse-test-seed orchestrator** (not RTR bugs):
- bug-5a inline `@@ROWCOUNT` swap (squashed)
- `sp_f_std_page_case_postprocessing @phc_ids → @phc_id_list` typo
- Step 9 PAM-fact ordering fix

**Deferred / out of scope for v1**:
- The remaining condition families (Pertussis, Measles, Rubella,
  Mumps, Tetanus LDF) — lower yield per agent-day; available as
  templates from the 5 that landed.
- The repeating-block cardinality N=1, N=10 variants.
- LDF breadth (multiple LDFs per type, multi-select coded LDFs).
- The MasterETL-side Phase-0 mirror.
- The actual comparison-tool diff harness (modeled on NEDSS-DataCompare).

### Next session priorities

1. Bug #10 (sp_sld_investigation_repeat surrogate-key) — unlocks
   `D_INVESTIGATION_REPEAT` (252 cols).
2. Bug #9 (dyn_dm UNPIVOT) — unlocks the `DM_INV_*` family.
3. MasterETL-side coverage analysis — required before the diff tool
   can produce meaningful output.
4. The comparison tool itself.

Realistic ceiling on fixture-authorable coverage is **40-45%**
before further progress requires upstream RTR fixes or a pivot to
the diff tool.
