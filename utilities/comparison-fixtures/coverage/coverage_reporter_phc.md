# Coverage: reporter_phc (PerAsReporterOfPHC + OrgAsReporterOfPHC participation edges)

## Inputs

- Baseline: 6.0.18.1
- UID range allocated: **21005000 - 21005999** (Tier 2, sixth agent)
- Foundation dependencies:
  - foundation Provider: `entity_uid = person_uid = 20000010` (`@dbo_Entity_provider_uid`)
  - foundation Organization: `entity_uid = organization_uid = 20000020` (`@dbo_Entity_organization_uid`)
  - foundation Investigation: `act_uid = public_health_case_uid = 20000100` (`@dbo_Act_investigation_uid`)
- Other-agent dependencies (Tier 1 read-only):
  - Provider Tier 1: v2 Provider `entity_uid = person_uid = 20010010` (`@dbo_Entity_provider_v2_uid`)
  - Organization Tier 1: v2 Organization `entity_uid = organization_uid = 20030010` (`@dbo_Entity_organization_v2_uid`)
  - Investigation Tier 1: v2 Investigation `act_uid = public_health_case_uid = 20050010` (`@dbo_Act_investigation_v2_uid`)
- Pre-fixture infrastructure (orchestrator-owned):
  - `dbo.RDB_DATE` populated via recursive-CTE seed (per STRATEGY.md "Note: `sp_get_date_dim` in baseline 6.0.18.1 has an RTR bug").
  - `dbo.sp_nrt_srte_condition_code_postprocessing @condition_cd_list = N'10110'` populated `dbo.CONDITION` for Hep A acute. (Note: the SP signature requires `@condition_cd_list`; templates citing a parameterless invocation are stale.)

## Edges authored

| Table | type_cd | act_class_cd | subject_class_cd | act_uid (Investigation) | subject_entity_uid | Endpoint pairing |
| --- | --- | --- | --- | --- | --- | --- |
| `nbs_odse.dbo.participation` | `PerAsReporterOfPHC` | `CASE` | `PSN` | 20000100 (foundation) | 20000010 (foundation Provider) | foundation Provider is Person-as-reporter of foundation Investigation |
| `nbs_odse.dbo.participation` | `PerAsReporterOfPHC` | `CASE` | `PSN` | 20050010 (v2)         | 20010010 (v2 Provider)         | v2 Provider is Person-as-reporter of v2 Investigation |
| `nbs_odse.dbo.participation` | `OrgAsReporterOfPHC` | `CASE` | `ORG` | 20000100 (foundation) | 20000020 (foundation Org)      | foundation Organization is reporting source of foundation Investigation |
| `nbs_odse.dbo.participation` | `OrgAsReporterOfPHC` | `CASE` | `ORG` | 20050010 (v2)         | 20030010 (v2 Org)              | v2 Organization is reporting source of v2 Investigation |

**Total: 4 rows** (2 PerAsReporterOfPHC + 2 OrgAsReporterOfPHC; no
surrogate UID required — composite PK is `(subject_entity_uid, act_uid,
type_cd)`; the 21005000-21005999 block is reserved for future
amendments).

The fixture writes **0 rows** to RDB_MODERN dim/fact tables and
**0 rows** to RDB_MODERN nrt_* staging tables. Tail-EXEC is
`sp_investigation_event` for SP-callability verification only.

## SPs verified

- `dbo.sp_investigation_event @phc_id_list = N'20000100,20050010'` — exit code 0 / 2 rows projected. **JSON projection now contains all 4 reporter participation rows in the `person_participations` / `organization_participations` branches** for both Investigations. Verified by grep for the raw JSON envelopes (all 4 emit cleanly):

  ```text
  [{"act_uid":20000100,"type_cd":"PerAsReporterOfPHC","entity_id":20000010,"subject_class_cd":"PSN", ... ,"first_name":"Foundation","last_name":"Provider","person_cd":"PRV", ...}]
  [{"act_uid":20000100,"type_cd":"OrgAsReporterOfPHC","entity_id":20000020,"subject_class_cd":"ORG", ... ,"name":"Foundation Organization", ...}]
  [{"act_uid":20050010,"type_cd":"PerAsReporterOfPHC","entity_id":20010010,"subject_class_cd":"PSN", ... ,"first_name":"Variant","last_name":"Provider","person_cd":"PRV", ...}]
  [{"act_uid":20050010,"type_cd":"OrgAsReporterOfPHC","entity_id":20030010,"subject_class_cd":"ORG", ... ,"name":"Variant Hospital", ...}]
  ```

- (No re-run of `sp_nrt_investigation_postprocessing` — the SP reads
  only `nrt_investigation`, never `participation`; INVESTIGATION
  dimension row count and column values are unchanged at 4 rows
  pre/post.)

## Coverage assessment — honest reporting

This edge is **shape-consistency-mostly at Tier 1 isolation**, exactly
as the per-edge prompt warned and as `patient_phc` demonstrated for the
SubjOfPHC participation edge. Concretely:

- `dbo.INVESTIGATION` (the dimension): 4 rows pre-edge (sentinel
  INVESTIGATION_KEY=1, baseline-seeded KEY=2 for case_uid 10000013,
  KEY=3 for foundation Inv 20000100, KEY=4 for v2 Inv 20050010). The
  post-edge `sp_nrt_investigation_postprocessing` re-run leaves all
  four rows byte-identical: the SP reads `nrt_investigation`
  (hand-authored by Tier 1 Investigation) and never traverses
  `participation`. **Coverage flipped: 0 columns.**
- The `nrt_investigation` columns flagged in `coverage_investigation.md`
  cross-subject section (`organization_id`, `person_as_reporter_uid`,
  `org_as_reporter_uid`) read from the investigation_event SP's pivot
  on `nbs_act_entity` (lines 909-933), NOT from `participation`. So
  even though the participation rows are now in place, the
  investigation_event SP's projection at the `investigation_act_entity`
  nested block still emits NULL for those keys. Authoring the
  corresponding `nbs_act_entity` rows is a separate Tier 2 deliverable
  (LINK_REQUIRED #11 in `coverage_investigation.md` — "nbs_act_entity
  type_cd='OrgAsReporterOfPHC'", and the related `PerAsReporterOfPHC`
  pivot at line 913).

What this edge **does** unlock — but ONLY in projections / outputs
that are NOT RDB_MODERN dim/fact tables at Tier 1 isolation:

| SP / projection | JOIN site | Effect of edge | RDB_MODERN dim/fact column flipped at Tier 1 isolation? |
| --- | --- | --- | --- |
| `sp_investigation_event` `person_participations` JSON branch (lines ~339-360) | Direct read of participation rows where `act_uid = phc.public_health_case_uid` AND `subject_class_cd='PSN'` | The 2 PerAsReporterOfPHC rows now appear in the JSON `person_participations` array (verified above). | **No.** JSON-only at this level — consumed by Kafka, not by `sp_nrt_investigation_postprocessing`. |
| `sp_investigation_event` `organization_participations` JSON branch (lines ~362-375) | Direct read of participation rows where `act_uid = phc.public_health_case_uid` AND `subject_class_cd='ORG'` | The 2 OrgAsReporterOfPHC rows now appear in the JSON `organization_participations` array (verified above). | **No.** Same. |
| `sp_public_health_case_fact_datamart_event` lines 1897-1903 (`PARTICIPATION INNER JOIN`, `TYPE_CD IN ('OrgAsReporterOfPHC','InvestgrOfPHC','PerAsReporterOfPHC','PhysicianOfPHC')`) | INNER JOIN on participation, filtered by both type_cd list AND `RECORD_STATUS_CD='ACTIVE'` | The INNER JOIN now matches; `F_PAGE_CASE.REPORTER_NAME` / `REPORTER_PHONE` / `ORGANIZATION_NAME` and related columns can populate | **YES — but only at Merge contract step 9** (Datamart SPs), not at Tier 1 isolation. Out of scope for this Tier 2 agent's verification. |
| `sp_public_health_case_fact_datamart_event` lines 1906-1925 (secondary UNION on `PARTICIPATION`, `TYPE_CD = 'OrgAsReporterOfPHC'`) | INNER JOIN on participation + organization_name | The Org-as-reporter name pivot (ORGANIZATIONNAME at line 1964) resolves | Same — Merge step 9. |
| `sp_public_health_case_fact_datamart_update` lines 105-110, 155-156, 160, 213 (same logic, update path) | Same | Same | Same. |

**SQL Server collation note (verified, same as patient_phc):** Default
collation `SQL_Latin1_General_CP1_CI_AS` is case-insensitive, so the
literal values `'PerAsReporterOfPHC'` / `'OrgAsReporterOfPHC'` (mixed
case, used by both event SPs and datamart SPs — verified by grep)
match consistently across all SP filter sites.

## Coverage unlocked (at Tier 1 isolation)

**0 RDB_MODERN dim/fact columns flipped from NULL/sentinel-1 to real values.**

This is the honest result, fully consistent with the per-edge prompt's
guidance ("likely 0 RDB_MODERN dim/fact unlocks at Tier 1 isolation;
benefit at Merge step 9"). The 4 participation rows' value lands in
RDB_MODERN at Merge contract step 9 (Datamart SPs:
`sp_public_health_case_fact_datamart_event`,
`sp_public_health_case_fact_datamart_update`, plus any
condition-specific datamarts that read `F_PAGE_CASE.REPORTER_*`
columns), not at any Tier 1 chain re-run.

Indirect-but-real values delivered by this fixture:

1. **ODSE graph correctness** — MasterETL traverses `participation`
   directly to populate analogous reporter-context columns on the RDB
   side. Without these edges, MasterETL's output would diverge from
   RTR's downstream Datamart-SP output, contaminating the eventual
   RDB-vs-RDB_MODERN comparison test. With these edges, the ODSE
   graph carries Provider-as-reporter and Organization-as-reporter
   context that both pipelines can read.
2. **Event-SP JSON-projection coverage** — `sp_investigation_event`
   JSON output now projects the reporter participations inside the
   per-Investigation `person_participations` and
   `organization_participations` branches. This makes the event-SP
   output structurally complete (matching what production
   CDC-Debezium-Kafka would observe) even though we don't consume the
   projection in our local fixture flow.
3. **Pre-requisite for downstream Datamart agents** — any future
   agent (Tier 3 or Datamart-coverage) that needs the participation
   rows to be present can rely on them being authored here.

## Coverage still LINK_REQUIRED

Resolved by this edge:

- `coverage_investigation.md` LINK_REQUIRED #3 (`participation
  type_cd='OrgAsReporterOfPHC' linking foundation Organization →
  foundation/v2 Investigation`): **resolved** at the JSON-projection
  level for the participation rows. The downstream
  `nrt_investigation.organization_id` / `org_as_reporter_uid`
  columns called out in that LINK_REQUIRED entry actually read from
  the SP's `nbs_act_entity` pivot (line 932), NOT participation —
  so they remain NULL until the corresponding `nbs_act_entity` rows
  are authored (separate Tier 2 work, see #11 below).
- `coverage_investigation.md` LINK_REQUIRED #4 (`participation
  type_cd='PerAsReporterOfPHC' linking foundation Provider →
  foundation/v2 Investigation`): **resolved** at the JSON-projection
  level. Same caveat — the `nrt_investigation.person_as_reporter_uid`
  column reads from `nbs_act_entity` (line 913), not participation.
- `coverage_inv_notification.md` line 115 PARTICIPATION_REPORTER_PHC
  callout (`PerAsReporterOfPHC` / `OrgAsReporterOfPHC`):
  **resolved** at the JSON-projection level.

Not resolved by this edge (waiting on other Tier 2 agents):

- `coverage_investigation.md` LINK_REQUIRED #5
  (`participation type_cd='PhysicianOfPHC'`): physician_phc Tier 2
  edge agent (separate). The `physician_phc` participation row joins
  the same datamart `TYPE_CD IN (...)` list at 072 line 1897 — it's
  needed for `F_PAGE_CASE.PROVIDERNAME` / `PROVIDERPHONE` to populate,
  but is not this agent's edge type.
- `coverage_investigation.md` LINK_REQUIRED #6
  (`participation type_cd='InvestgrOfPHC'`): same — `InvestgrOfPHC`
  is in the same datamart `TYPE_CD IN (...)` list and feeds
  `F_PAGE_CASE.INVESTIGATORNAME` / `INVESTIGATORPHONE` /
  `INVESTIGATORASSIGNEDDATE`. Separate Tier 2 agent.
- `coverage_investigation.md` LINK_REQUIRED #11
  (`nbs_act_entity type_cd='OrgAsReporterOfPHC' / FldFupFacilityOfPHC
  / OrgAsHospitalOfDelivery linking Organization → Investigation`):
  **NOT resolved here.** The `nbs_act_entity` table is a different
  connective table from `participation`, and the
  investigation_event SP at lines 909-933 reads from
  `nbs_act_entity` for the `org_as_reporter_uid` /
  `person_as_reporter_uid` pivots. A separate Tier 2 agent is
  required to author the `nbs_act_entity` rows. The participation
  rows authored here are what the **datamart SPs** read; the
  `nbs_act_entity` rows are what the **investigation_event SP** reads
  for the `nrt_investigation`-projected reporter UIDs. Both are
  needed for full coverage.
- All RDB_MODERN dim/fact column populations that depend on these
  edges land at Merge contract step 9 (Datamart SPs); those are out
  of scope for this Tier 2 agent's verification.

## OUT_OF_SCOPE / SRTE_GAP / FOUNDATION_GAP

- **OUT_OF_SCOPE: `F_PAGE_CASE.REPORTER_NAME`, `REPORTER_PHONE`,
  `ORGANIZATION_NAME` and related Datamart reporter-context columns.**
  These flip to populated values at Merge contract step 9
  (`sp_public_health_case_fact_datamart_event`,
  `sp_public_health_case_fact_datamart_update`, plus any
  condition-specific datamart SPs that consume `F_PAGE_CASE`
  columns) — none of which is in scope for this Tier 2 agent's
  verification. The Datamart SPs read the participation rows
  authored here directly via `WHERE PAR.TYPE_CD IN
  ('OrgAsReporterOfPHC', 'InvestgrOfPHC', 'PerAsReporterOfPHC',
  'PhysicianOfPHC')` (case-insensitive collation matches our mixed-case
  literals). Citation:
  `072-sp_public_health_case_fact_datamart_event-001.sql:1897-1903`,
  `1944-1948`, `1964`;
  `073-sp_public_health_case_fact_datamart_update-001.sql:105-110`,
  `155-156`, `160`, `213`.
- **OUT_OF_SCOPE: `nrt_investigation.person_as_reporter_uid` /
  `org_as_reporter_uid` / `organization_id`.** These read from
  `nbs_act_entity` pivots in `sp_investigation_event` (lines 913,
  932, and the `organization_id` derivation), not from
  `participation`. A separate Tier 2 `nbs_act_entity_*` agent is
  required to populate these columns.
- **No SRTE_GAP.** Both `PerAsReporterOfPHC` and `OrgAsReporterOfPHC`
  are present in baseline `nbs_srte.dbo.Participation_type` (verified
  by query: PerAsReporterOfPHC has act_class_cd='CASE',
  subject_class_cd='PSN', type_desc_txt='Reporter of Case';
  OrgAsReporterOfPHC has act_class_cd='CASE',
  subject_class_cd='ORG', type_desc_txt='Reporting Source of Case').
- **No FOUNDATION_GAP.** Foundation Provider (entity_uid 20000010
  with class_cd='PSN', person.cd='PRV'), foundation Organization
  (entity_uid 20000020 with class_cd='ORG'), and foundation
  Investigation (act_uid 20000100 with class_cd='CASE') match the
  PerAsReporterOfPHC and OrgAsReporterOfPHC endpoint constraints
  exactly. Same applies for v2 Provider (20010010), v2 Organization
  (20030010), and v2 Investigation (20050010).
- **No new LINK_REQUIRED found.** The SP filter sites visited by
  this edge are all single-edge (no chained joins through other
  cross-subject edges). The `nbs_act_entity_reporter` LINK_REQUIRED
  is already documented in `coverage_investigation.md` #11.

## Decisions made under prompt ambiguity

1. **Mixed-case literals chosen for both `type_cd` values
   (`'PerAsReporterOfPHC'`, `'OrgAsReporterOfPHC'`).** The SP filter
   sites in 056 (event) and 072/073 (datamart) all use mixed case —
   verified by grep at 056 line 913 / 932 and 072 line 1898 / 1900 /
   1917 / 1944 / 1964 and 073 line 106 / 155 / 160 / 213. Default
   collation `SQL_Latin1_General_CP1_CI_AS` is case-insensitive, so
   either choice works, but mixed case mirrors NBS production data
   conventions and the foundation/Tier 1 fixture conventions.
2. **`record_status_cd = N'ACTIVE'` is required, not optional.**
   Verified the datamart SPs at `072-...:1896` and `073-...:104`
   filter on `PAR.RECORD_STATUS_CD = 'ACTIVE'`. Without this column,
   the participation rows would be excluded by the datamart pivot.
   Same verification applies for the secondary UNION block at
   072-...:1916 / 073-...:212 (`PAR2.RECORD_STATUS_CD = 'ACTIVE'`).
3. **Tail-EXEC is `sp_investigation_event` only**, NOT
   `sp_nrt_investigation_postprocessing`. Per the per-edge prompt's
   honest-reporting guidance and `patient_phc`'s precedent: the
   postprocessing SP reads from `nrt_investigation` staging
   hand-authored by Tier 1 and does not traverse `participation`,
   so a re-run would be wasted work. The event SP re-run is a
   SP-callability check (no errors) and a coverage spot-check
   (verifies the participation rows surface in the JSON projection).
4. **No surrogate UIDs allocated.** The participation table's
   composite PK is `(subject_entity_uid, act_uid, type_cd)`; no
   surrogate UID is needed. The full 21005000-21005999 block is
   reserved for any future amendment that needs surrogate UIDs.
5. **Authored 4 rows** (2 PerAsReporterOfPHC + 2 OrgAsReporterOfPHC,
   each pair foundation→foundation + v2→v2), not the 8 possible
   cross-pairs. This mirrors the convention in the prior 5 Tier 2
   fixtures (inv_notification, lab_inv, morb_inv, treatment_inv,
   patient_phc). A future Tier 3 agent can add cross-pairs (e.g.,
   foundation Provider as reporter of v2 Investigation) if needed
   for multi-reporter-per-investigation datamart coverage.
6. **`participation` rows only — no `nbs_act_entity` rows authored.**
   The per-edge prompt explicitly says "4 participation rows total"
   and the catalog row for `PerAsReporterOfPHC` /
   `OrgAsReporterOfPHC` lives under the `dbo.participation` section,
   not under `dbo.nbs_act_entity`. The investigation_event SP at
   lines 913 / 932 reads `nbs_act_entity` for the
   `person_as_reporter_uid` / `org_as_reporter_uid` pivots — but
   that pivot is a separate Tier 2 deliverable (per
   `coverage_investigation.md` LINK_REQUIRED #11 covering
   `nbs_act_entity type_cd='OrgAsReporterOfPHC'`). The two edges are
   complementary: participation drives the datamart SPs, while
   nbs_act_entity drives the event SP's reporter-uid projection.

## Confirmation deliverables exist

- [x] `fixtures/20_links/reporter_phc.sql` — 4-row INSERT plus
      tail-EXEC of `sp_investigation_event`.
- [x] `coverage/coverage_reporter_phc.md` — this file.
- [x] `catalog/uid_ranges.md` — Tier 2 section extended with the
      reporter_phc agent's block (21005000-21005999) and detail
      sub-section.
