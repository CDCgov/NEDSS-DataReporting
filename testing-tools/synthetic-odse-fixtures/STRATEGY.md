# Comparison Fixtures: Strategy

## Goal

Produce a synthetic but referentially-valid set of NBS_ODSE INSERTs that, after
RTR's full transformation chain runs against them, exercises as much of
RDB_MODERN as RTR can populate from the post-baseline state. v1 reaches roughly
80% column coverage (see the README and `coverage/coverage_merged.md`); the
remaining gap is tracked in the follow-on section below and in the documented
bugs. Output is consumed by the comparison tool in `testing-tools/rdb-compare/`
(modeled on NEDSS-DataCompare), which diffs RDB (MasterETL) against RDB_MODERN
(RTR).

This effort is in scope only for step (1) of the comparison pipeline:

1. Populate ODSE (this work).
2. Run MasterETL.
3. Run RTR initial hydration.
4. Diff RDB vs RDB_MODERN.

MasterETL is out of scope for fixture authoring. RTR is the unit of analysis.
Tables/columns MasterETL writes that RTR does not are flagged in the final
coverage report as suspected gaps in RTR, not as fixture targets.

## Baseline

Every fixture run begins from a freshly restored baseline. The baseline is:

- The `ghcr.io/cdcent/nedssdb:latest` MSSQL image started with environment
  variable `DATABASE_VERSION=6.0.18.1` (hard-coded at
  `docker-compose.yaml` line 6).
- Migrated through `NEDSSDB/src/migrations/6.0.18.1` (RDB, ODSE, SRTE).
- Liquibase-applied by `reporting-pipeline-service`, i.e. all RTR tables,
  views, functions, and stored procedures from
  `NEDSS-DataReporting/liquibase-service/src/main/resources/db/` are present in
  RDB_MODERN.
- Standard golden seed users created (`superuser`, `rtr_admin`,
  `rtr_service_user`).

The baseline contains a fully populated SRTE (condition codes, code-set values,
nbs_ui_metadata) and pre-seeded LDF metadata for templates. Each fixture must
ground every code (`condition_cd`, `type_cd`, `class_cd`, etc.) by querying SRTE
in the live baseline DB, never by inventing codes that look plausible.

### Connection details

```
Host:      localhost
Port:      3433
DBs:       NBS_ODSE, NBS_SRTE, RDB, RDB_MODERN, NBS_MSGOUTE
User:      sa
Password:  ${DATABASE_PASSWORD:-PizzaIsGood33!}
```

Pass the password to sqlcmd via the `SQLCMDPASSWORD` env var rather than `-P`.
The `!` in the password triggers zsh history expansion when double-quoted, which
causes intermittent auth failures. Set it once and omit `-P` entirely:

```sh
export SQLCMDPASSWORD=PizzaIsGood33!
sqlcmd -S localhost,3433 -U sa -C -d NBS_SRTE -Q "SELECT @@VERSION"
```

Stand up the baseline:

```sh
cd /Users/adam/code/nbs/NEDSS-DataReporting
docker compose up -d nbs-mssql liquibase
# wait for liquibase to log "Migrations complete" (~3-5 minutes)
```

Reset between runs by `docker compose down -v && docker compose up -d nbs-mssql liquibase`.

### Idempotency

Fixtures are not idempotent. Each run starts from a fresh restore. Fixtures
do not write `IF NOT EXISTS` guards. UID collisions are forbidden by the UID
range registry (below), not papered over with conditional inserts.

## RTR transformation chain (verification recipe)

Each `sp_nrt_*_postprocessing` SP reads from a `dbo.nrt_*` staging table in
RDB_MODERN. In production, staging is populated by SQL Server CDC, Debezium,
Kafka, and a kafka-connect JDBC sink. The `sp_<entity>_event` SP is not the
staging writer. It emits a JSON projection of ODSE rows for downstream
consumption; it does not `INSERT INTO nrt_*`. (Verified directly in the SP
body; see Provider canary findings.)

The fixtures are ODSE-only. We author the `nbs_odse.dbo.*` INSERTs and let the
real pipeline produce everything downstream. There are no hand-authored
`nrt_*` rows and no manual `EXEC sp_*` in the fixtures, so coverage is exactly
what the real ODSE-to-RTR transform produces.

```
ODSE INSERTs                               (in fixture .sql)
   ↓
SQL Server CDC → Debezium → Kafka → kafka-connect JDBC sink
   ↓
nrt_<entity> staging                       (written by the pipeline)
   ↓
reporting-pipeline-service runs the SP chain (event + postprocessing)
   ↓
RDB_MODERN dimensions / facts
```

The full stack (CDC, Kafka, kafka-connect, reporting-pipeline-service)
runs on every `merge_and_verify.sh`, so coverage is exactly what RTR
produces from the ODSE fixtures. A from-scratch cycle is ~15-20 min (image
rebuild plus CDC drain).

Authoring guidance: to know which ODSE columns a target needs, read the
postprocessing SP body for the staging columns it reads, then trace those
back through the matching `sp_<entity>_event` JSON projection to their
`nbs_odse.dbo.*` sources. If a staging column is read by the postprocessing
SP but not visible in the event SP's projection, prefer the postprocessing
SP as ground truth.

### Convention: postprocessing SPs read NRT staging only, never ODSE

This is a load-bearing architectural invariant, verified against the entire
`liquibase-service/src/main/resources/db/005-rdb_modern/routines/` tree on
2026-05-19.

The `sp_*_event` SPs read `nbs_odse.dbo.*` directly; that is their whole job.
They project ODSE rows into JSON for downstream NRT staging. The 11 files that
contain `FROM nbs_odse.dbo.*` or `JOIN nbs_odse.dbo.*` are all `*_event` SPs
(e.g. `sp_observation_event`, `sp_investigation_event`, `sp_patient_event`,
etc.) plus `sp_user_report_permissions`.

The `sp_nrt_*_postprocessing` SPs (and the `sp_d_*` and `sp_*_datamart_*`
variants) read RDB_MODERN-side staging only: `nrt_*` tables and `#tmp_*` temp
tables derived from them. There are zero references to `nbs_odse.dbo.*` in the
postprocessing layer. The CSV columns on NRT staging rows (e.g.
`nrt_morbidity_observation.followup_observation_uid`,
`nrt_observation.associated_phc_uids`) are the upstream debezium projection of
the act_relationship / participation graph, and are how postprocessing walks
edges without re-traversing ODSE.

This matters when proposing RTR fixes (Tier 3, bug investigations, SP
rewrites). If a fix wants to `JOIN nbs_odse.dbo.act_relationship` or any other
`nbs_odse.dbo.*` table inside a `sp_nrt_*_postprocessing` or `sp_d_*` SP, stop
and look for the staging-side projection. The upstream NRT row almost
certainly carries a CSV column or a pre-joined value that collapses the graph
walk. The CSV idiom looks like `CROSS APPLY string_split(<csv_col>, ',') AS x`
joined to `#morb_obs_reference` (or equivalent) and filtered by
`obs_domain_cd_st_1` (or analogous role-code column). Cross-DB joins to ODSE
from postprocessing SPs will be bounced in RTR review on architectural
grounds, regardless of whether the query is correct. Match the layer's
convention. The event SPs themselves are the exception: when editing
`sp_*_event`, cross-DB ODSE reads are the norm.

This convention was reinforced by bug #3
(`sp_d_morbidity_report_postprocessing` user-comment query): the
first fix attempted a two-hop `nbs_odse.dbo.act_relationship`
traversal; the second-iteration fix uses the staging CSV
`followup_observation_uid` already projected by NRT. The second
fix is the one that landed.

Datamart SPs (Hepatitis_Datamart, Std_Hiv_Datamart, dyn_dm_*, etc.) have no
`_event` partner. They read from already-populated RDB_MODERN dimensions and
are invoked directly after Tier 1 and Tier 2 are merged.

## Decomposition: graph-first, SP-second

The fixture is built in tiers. Each tier's outputs become the next tier's
read-only dependencies.

### Tier 0: Foundation

Produces `fixtures/00_foundation/00_foundation.sql`:

- Reference UIDs (superuser).
- Any condition codes, LDF templates, or NBS_UI_metadata rows the baseline
  does not already provide but Tier 1 and later depend on (must be discovered,
  not assumed).
- One canonical instance of each parent entity that downstream fixtures attach
  edges to. Concretely: one Patient (Person+Entity), one Provider (Person+Entity),
  one Organization, one Place, one Investigation (Public_health_case+Act), one
  Notification, one Lab Report (Observation+Act), one Morbidity Report,
  one Interview, one Treatment, one Vaccination, one Contact Record.

UID range: `20000000–20009999`.

### Tier 1: Subjects

One fixture per canonical subject (12; see the Tier 0 enumeration above). Each
fixture owns the internal edges of its subject. For example, the Lab Report
fixture owns its Observation hierarchy and the Participation rows linking it to
its own Patient and Ordering Provider, but not the link from a Lab to a
separate Investigation, which is a Tier 2 edge.

A Tier 1 fixture does not modify or re-create foundation rows. If its SP needs
variants of foundation rows (e.g. a second patient with `deceased_ind_cd = 'Y'`
to hit a CASE branch), it creates them inside its own UID range as additions,
not replacements.

Each Tier 1 fixture follows this process:

1. Read the SP body (event SP plus postprocessing SP).
2. Static-extract every column written to RDB_MODERN and the gating predicates.
3. Author ODSE INSERTs that maximize column population, grounded in baseline
   SRTE (verified by `sqlcmd` SELECTs).
4. Verify by `EXEC` of event plus postprocessing SPs against a fresh baseline
   plus foundation plus this fixture.
5. Report populated columns, deliberately-skipped columns with reasons,
   SRTE_GAPS, and any cross-subject edges Tier 2 must provide. The rolled-up
   coverage picture lives in `coverage/coverage_merged.md`, regenerated by
   `scripts/coverage_summary.sh`.

UID ranges per subject are recorded in `catalog/uid_ranges.md`.

### Tier 2: Links

Cross-subject edges only.

The decomposition is one fixture per edge type. Phase B's `edge_types.md`
catalog enumerates ~10 load-bearing edge types. Each gets its own
`fixtures/20_links/<edge_type>.sql`, and coverage rolls into
`coverage/coverage_merged.md`. The edge types are independent, except where one
edge type genuinely depends on another (rare).

Examples:

- `act_relationship_inv_notification`: `act_relationship` rows of
  `type_cd='InvestigationHasNotification'` linking the foundation
  Investigation to the foundation Notification (and v2 Investigations
  to v2 Notifications). Resolves Notification's INNER JOIN that
  blocks coverage at Tier 1 isolation.
- `act_relationship_lab_inv`: Lab to Investigation
  (`type_cd='LabReportToInvestigation'`).
- `act_relationship_morb_inv`: Morbidity to Investigation.
- `act_relationship_treatment_inv`: Treatment to Investigation
  (`type_cd='TreatmentToPHC'`).
- `participation_patient_phc`: `SubjOfPHC` linking foundation Patient
  to foundation Investigation. Resolves Patient-Investigation context
  that drives Datamart-side patient columns.
- `participation_reporter_phc`: `PerAsReporterOfPHC` /
  `OrgAsReporterOfPHC` linking Provider/Organization to Investigation
  as reporter.
- `participation_physician_phc`: `PhysicianOfPHC` linking Provider to
  Investigation as physician of record.
- `nbs_act_entity_vaccination`: `SubOfVacc` plus `PerformerOfVacc`
  linking Vaccination to Patient and Provider.
- `nbs_act_entity_interview`: interview-participant edges.

Tier 2 edges read the UID range registry to find subject UIDs. They
pick edge `type_cd`s from `catalog/edge_types.md` (built in Phase B
from live baseline SRTE), and never invent them.

Baseline infrastructure prerequisites. Two project-wide dimension
tables that are empty in the pristine baseline are populated outside
the fixtures so Tier 2 (and later) FKs resolve:

- `dbo.RDB_DATE` calendar population. `sp_get_date_dim` in baseline 6.0.18.1
  has an RTR bug: it references the non-existent `dbo.rdb_date_temp` table and
  has a `#temp_date` scope bug at lines 49-55 of
  `014-sp_get_date_dim-001.sql`. Rather than the broken SP, `RDB_DATE` is
  populated by the liquibase onboarding seed `onboarding-rdb-date-seed`
  (`liquibase-service/.../onboarding/002-rdb_date_seed-001.sql`), which EXECs
  `sp_get_date_dim @start=1990 @end=2030` on baseline `up`. Required because
  `NOTIFICATION_EVENT`, `LAB_TEST_RESULT`, `TREATMENT_EVENT`, etc. have FKs to
  `RDB_DATE.DATE_KEY` that fail if the table is empty.
- `CONDITION` from SRTE. The reporting-pipeline-service populates
  `CONDITION` for processed condition codes off CDC events during the
  drain, so the Notification chain (and others) that read `CONDITION_KEY`
  without COALESCE resolve. For v1 (single-condition-per-family per
  STRATEGY.md) the canonical condition is Hep A acute (`10110`).

These hold for every merged-fixture session; the liquibase seed runs on
baseline `up` and the service runs during the CDC drain.
(See "Merge contract" below.)

Tier 2 fixtures do not modify foundation, Tier 1 fixtures, or other
Tier 2 fixtures' outputs. Each fixture's output is purely additive
ODSE INSERTs (and the cross-subject connective-table rows) keyed in
its own UID block. After applying a fixture, re-run the relevant Tier 1
chains (e.g. the Notification chain after wiring Notif to Inv) to verify
coverage extends, but do not author any RDB_MODERN dimension/fact rows.

Verification uses a focused merged sequence per edge type, on a fresh
baseline:
1. `docker compose down -v && up -d`
2. Apply foundation.
3. Baseline infrastructure is already in place (`RDB_DATE` from the
   liquibase onboarding seed; `CONDITION` populated by the
   reporting-pipeline-service during the drain).
4. Apply only the Tier 1 fixtures relevant to this edge type (e.g.
   for `act_relationship_inv_notification`: foundation plus Investigation
   Tier 1 plus Notification Tier 1, not all 12).
5. Run the relevant Tier 1 chains in dependency order.
6. Apply this edge type's `<edge_type>.sql`.
7. Re-run any Tier 1 chains whose coverage depends on the new edges
   (e.g. Notification's chain after the act_relationship is wired).
8. Spot-check coverage: which previously-NULL columns are now populated
   and which still need other Tier 2 edges.

This reduces baseline-reset cost and isolates failures.

UID range: Tier 2 allocates within `21000000–21099999`, taking a
1000-wide block per edge type (`21000000-21000999` for the first,
`21001000-21001999` for the second, etc.). Update `catalog/uid_ranges.md`
as part of each edge type's deliverable.

### Tier 3: Gap-driven SP coverage

Runs only on SPs whose verification step (Tier 1 or post-Tier-2) reports
uncovered RDB_MODERN columns reachable by the SP's logic. Tier 3 adds
small, targeted ODSE rows or variants to hit the missing branches. It never
modifies foundation or existing subjects.

## Phase 0: RTR target-column map

Before any fixture work, a static analysis pass extracts from every RTR
routine in `liquibase-service/src/main/resources/db/005-rdb_modern/routines/`
the set of (table, column) pairs RTR ever writes to. Output:
`catalog/rtr_target_columns.md`. This is the canonical scope file. Every Tier 1
coverage report is measured against it.

## Phase B: Edge-type catalog

A second static-and-dynamic analysis enumerates from live baseline SRTE every
legal `type_cd` (or analogous discriminator) for the seven connective tables
(`act_relationship`, `participation`, `nbs_act_entity`,
`entity_locator_participation`, `role`, `act_id`, `entity_id`), together with
the source/target `class_cd` constraints each value implies. Output:
`catalog/edge_types.md`.

Edges select rows from this catalog rather than authoring codes inline.

## UID range registry

Single source of truth: `catalog/uid_ranges.md`.

Reservation rules:

- Tier 0 owns `20000000–20009999`. Allocates one block per canonical entity.
- Each Tier 1 subject is granted a 10000-wide block in `200_____0–200_____9999`.
- Tier 2 allocates within `21000000–21099999`.
- Tier 3 allocates within `22000000–22099999`.
- Sentinel UIDs (e.g. `superuser_id = 10009282`) are referenced by symbolic
  name through DECLAREs and never reallocated.
- Each fixture allocates only within its assigned block. Cross-references to
  other UIDs are by reading the registry, not by guessing.
- Foreign key targets that live outside ODSE (e.g. SRTE codes) are by string
  value, never UID.

## Output layout

```
NEDSS-DataReporting/testing-tools/synthetic-odse-fixtures/
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
│   │   └── <subject>.sql                # one per Tier 1 subject
│   ├── 20_links/
│   │   └── <edge_type>.sql              # one per Tier 2 edge type
│   ├── 30_sp_coverage/
│   │   └── <sp_name>.sql                # only for Tier 3 gaps
│   └── _quarantine/                     # bug-gated / seed-gated fixtures
├── coverage/
│   └── coverage_merged.md               # rolled-up coverage report
└── scripts/
    ├── merge_and_verify.sh              # full deterministic Merge contract
    ├── coverage_summary.sh              # regenerates coverage_merged.md
    └── db_lock.sh                       # DB lock for parallel runs
```

## Merge contract

Final assembled fixture is applied by `scripts/merge_and_verify.sh` in
this deterministic CDC-only 8-step sequence (each fixture step is
followed by a CDC drain in which the reporting-pipeline-service fires
the per-subject `*_event` + `*_postprocessing` + datamart SPs off the
CDC events):

1. Reset baseline: `docker compose down -v && build && up` (fresh
   baseline; the liquibase onboarding seed populates `RDB_DATE`).
2. Apply foundation fixture (`fixtures/00_foundation/00_foundation.sql`),
   then drain.
3. Apply Tier 1 fixtures (`fixtures/10_subjects/*.sql`), then drain.
4. Apply Tier 2 fixtures (`fixtures/20_links/*.sql`: cross-subject
   edges), then drain. Keys that were partial in Tier 1 now resolve to
   their canonical values, not sentinel 1.
5. Apply Tier 3 fixtures (`fixtures/30_sp_coverage/*.sql`: gap-driven
   additions), then drain.
6. `run_summary_datamarts`: deterministic post-drain EXEC of
   `sp_event_metric_datamart_postprocessing` →
   `sp_summary_report_case_postprocessing` →
   `sp_sr100_datamart_postprocessing` over `PHC_UIDS`.
7. `run_interview_chain`: re-drive `sp_interview_event` +
   `sp_d_interview_postprocessing` + `sp_f_interview_case_postprocessing`
   post-Tier-3.
8. `print_coverage_summary`.

`scripts/apply_odse_fixtures.sh` runs steps 2-7 against an already-running stack:
it skips the step-1 reset (no volume drop) and the step-8 coverage summary, with
`--reset` / `--verify` to opt either back in. Use it to iterate without rebuilding.

If two fixture files contain conflicting `INSERT INTO X (uid, ...)` statements
on the same UID, that is a contract violation and the merge fails loudly.
There is no auto-deduplication.

## Failure-mode policy

When a fixture cannot populate a column without exceeding its scope:

- Missing SRTE row: record as `SRTE_GAP: <description>` in the coverage
  report. Do not seed SRTE from a Tier 1 or later fixture.
- Missing foundation entity: record as `FOUNDATION_GAP` and stop. Tier 0
  is amended in a follow-up, then dependents re-run.
- Missing cross-subject edge: record as `LINK_REQUIRED: <edge_spec>` for
  Tier 2 to pick up.
- Genuinely unreachable column (dead code, RDB-only, MasterETL-only):
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
- Cross-fixture dependencies: <list of UID range registry entries>

## SPs verified
- `dbo.sp_<entity>_event`: exit code 0 / rows-written N
- `dbo.sp_nrt_<entity>_postprocessing`: exit code 0 / rows-written N

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
2. Phase 0 static-analysis pass → `catalog/rtr_target_columns.md`.
3. Phase B catalog pass → `catalog/edge_types.md`.
4. Tier 0 → `fixtures/00_foundation/00_foundation.sql`.
5. Provider as the first Tier 1 subject, end-to-end. Establishes the
   per-subject authoring pattern (the Tier 1 process above).
6. Remaining Tier 1 subjects (organization → provider → patient → place →
   investigation → notification → lab → interview → treatment →
   vaccination → contact).
7. Tier 2 edge types.
8. Tier 3 gap-driven additions (only on reported gaps).
9. Final merge plus full-chain verification. `scripts/merge_and_verify.sh`
    runs the deterministic 8-step CDC-only Merge contract end-to-end (reset →
    foundation + drain → Tier 1 + drain → Tier 2 + drain → Tier 3 + drain →
    run_summary_datamarts → run_interview_chain → print_coverage_summary).
    The first successful end-to-end run produces ~25 RDB_MODERN dim/fact
    rows across 19 target tables and ~22 cross-subject connective rows.

## Follow-on / phase-2

Captured here so they don't get lost as we focus on v1:

- **Multi-condition variants per disease family.** v1 uses one canonical
  condition per family (e.g., one Hepatitis condition). Datamart columns
  whose logic branches on specific condition codes will be partially covered.
  Phase 2 adds one investigation per condition code.
- **Subject catalog expansion.** v1 catalog includes the 12 subjects listed
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
  L_HC_PROV_TY_3 link tables) are written only by MasterETL, with no
  documented ODSE input pattern that populates them through RTR. Most
  appear in our Phase 0 catalog as dynamic-SQL targets or are
  populated only after specific datamart SPs run. **Action items**:
  (1) cross-reference the teammate's full list against
  `coverage/coverage_merged.md`'s "Empty (59)" category to find
  overlaps. (2) for each ODSE-unknown table, document in the
  catalog whether it's MasterETL-only (RTR doesn't write it, so it is
  a comparison-test gap rather than a fixture gap), datamart-SP-driven
  (would populate via the datamart SPs the reporting-pipeline-service
  fires during the CDC drain, so out of scope for v1), or
  genuinely uninvestigated (belongs in a Tier 3 spike). (3) Once
  the comparison test runs, columns in MasterETL-only tables
  will diff as "RDB has rows, RDB_MODERN doesn't". That is a
  legitimate finding about RTR coverage gaps, not a fixture bug.

## Progress log

The iterative coverage log (Rounds 1-6) and per-session notes were
removed during PR cleanup as build-process artifacts. The durable outcomes
are the RTR defects found, tracked in the APP Jira tickets. Regenerate current
coverage with `scripts/coverage_summary.sh`.
