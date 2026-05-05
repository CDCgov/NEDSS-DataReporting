# Coverage: physician_phc (PhysicianOfPHC + InvestgrOfPHC participation edges)

## Inputs

- Baseline: 6.0.18.1
- UID range allocated: **21006000 - 21006999** (Tier 2, seventh agent)
- Foundation dependencies:
  - foundation Provider: `entity_uid = person_uid = 20000010` (`@dbo_Entity_provider_uid`)
  - foundation Investigation: `act_uid = public_health_case_uid = 20000100` (`@dbo_Act_investigation_uid`)
- Other-agent dependencies (Tier 1 read-only):
  - Provider Tier 1: v2 Provider `entity_uid = person_uid = 20010010` (`@dbo_Entity_provider_v2_uid`)
  - Investigation Tier 1: v2 Investigation `act_uid = public_health_case_uid = 20050010` (`@dbo_Act_investigation_v2_uid`)
- Pre-fixture infrastructure (orchestrator-owned):
  - `dbo.RDB_DATE` populated via recursive-CTE seed (per STRATEGY.md "Note: `sp_get_date_dim` in baseline 6.0.18.1 has an RTR bug").
  - `dbo.sp_nrt_srte_condition_code_postprocessing @condition_cd_list = N'10110'` populated `dbo.CONDITION` for Hep A acute.

## Edges authored

| Table | type_cd | act_class_cd | subject_class_cd | act_uid (Investigation) | subject_entity_uid | Endpoint pairing |
| --- | --- | --- | --- | --- | --- | --- |
| `nbs_odse.dbo.participation` | `PhysicianOfPHC` | `CASE` | `PSN` | 20000100 (foundation) | 20000010 (foundation Provider) | foundation Provider is physician of foundation Investigation |
| `nbs_odse.dbo.participation` | `PhysicianOfPHC` | `CASE` | `PSN` | 20050010 (v2)         | 20010010 (v2 Provider)         | v2 Provider is physician of v2 Investigation |
| `nbs_odse.dbo.participation` | `InvestgrOfPHC`  | `CASE` | `PSN` | 20000100 (foundation) | 20000010 (foundation Provider) | foundation Provider is investigator of foundation Investigation |
| `nbs_odse.dbo.participation` | `InvestgrOfPHC`  | `CASE` | `PSN` | 20050010 (v2)         | 20010010 (v2 Provider)         | v2 Provider is investigator of v2 Investigation |

**Total: 4 rows** (2 PhysicianOfPHC + 2 InvestgrOfPHC; no surrogate UID
required — composite PK is `(subject_entity_uid, act_uid, type_cd)`;
the 21006000-21006999 block is reserved for future amendments).

The fixture writes **0 rows** to RDB_MODERN dim/fact tables and
**0 rows** to RDB_MODERN nrt_* staging tables. Tail-EXEC is
`sp_investigation_event` for SP-callability + JSON-projection
verification only.

## SPs verified

- `dbo.sp_investigation_event @phc_id_list = N'20000100,20050010'` — exit code 0 / 2 rows projected. **JSON projection now contains the InvestgrOfPHC participation rows in the case-investigator JSON branch** for both Investigations. Verified post-edge:

  ```text
  "investigator_assigned_datetime":"2026-04-01T00:00:00"   <- foundation
  "investigator_assigned_datetime":"2026-04-02T00:00:00"   <- v2
  ```

  Both come from the participation `from_time` field at line 848 of
  `056-sp_investigation_event-001.sql`. The PhysicianOfPHC rows are
  also persisted in ODSE participation but **do not** appear in the
  event SP's JSON projection (the SP does not pivot on PhysicianOfPHC
  — verified by `grep PhysicianOfPHC 056-sp_investigation_event-001.sql`
  returning zero matches). PhysicianOfPHC's value only manifests at
  the datamart SPs (Merge contract step 9).

- (No re-run of `sp_nrt_investigation_postprocessing` — the SP reads
  only `nrt_investigation`, never `participation`; INVESTIGATION
  dimension row count and column values are unchanged at 4 rows
  pre/post.)

## Coverage assessment — honest reporting

This edge is **shape-consistency-mostly at Tier 1 isolation**, exactly
as the per-edge prompt warned and as `reporter_phc` / `patient_phc`
demonstrated for sibling participation edges. Concretely:

- `dbo.INVESTIGATION` (the dimension): 4 rows pre-edge (sentinel
  INVESTIGATION_KEY=1, baseline-seeded rows for foundation + v2 Inv).
  The post-edge state is byte-identical: no postprocessing SP was
  re-run for INVESTIGATION because it reads from `nrt_investigation`
  (hand-authored by Tier 1) and never traverses `participation`.
  **Coverage flipped: 0 columns.**
- `nrt_investigation.investigator_id`: NULL pre-edge, **NULL post-edge**.
  The investigation_event SP at line 848 projects only `par2.from_time`
  as `investigator_assigned_datetime` — there is NO pivot extracting
  `par2.subject_entity_uid` as `investigator_id`. The `investigator_id`
  column on `nrt_investigation` is purely a hand-authored staging
  column (Tier 1 left both rows' `investigator_id` NULL); no SP derives
  it from the InvestgrOfPHC participation row. Spot-check (post-edge):
  ```
  public_health_case_uid investigator_id  investigator_assigned_datetime  physician_id
  20000100               NULL             NULL                            NULL
  20050010               NULL             2026-04-02 00:00:00.000         NULL
  ```
  v2's `investigator_assigned_datetime` is the Tier 1 hand-authored
  value, not a participation-derived value. (Even if we re-ran the
  postprocessing SP, the staging value would be unchanged — the SP
  reads it as-is from staging.)
- `nrt_investigation.physician_id`: NULL pre-edge, **NULL post-edge**.
  PhysicianOfPHC is not read by the investigation_event SP at all
  (zero matches in 056-...sql), so authoring its participation row has
  zero effect on the INVESTIGATION dim or `nrt_investigation` staging.

What this edge **does** unlock — but ONLY in projections / outputs
that are NOT RDB_MODERN dim/fact tables at Tier 1 isolation:

| SP / projection | JOIN site | Effect of edge | RDB_MODERN dim/fact column flipped at Tier 1 isolation? |
| --- | --- | --- | --- |
| `sp_investigation_event` `investigator_assigned_datetime` JSON projection (line 848 + 869-874) | LEFT OUTER JOIN on participation where `act_uid = phc.public_health_case_uid` AND `type_cd='InvestgrOfPHC'` AND `act_class_cd='CASE'` AND `subject_class_cd='PSN'` | The 2 InvestgrOfPHC rows now contribute `from_time` to the JSON output's `investigator_assigned_datetime` field for both Investigations. | **No.** JSON-only at this level — consumed by Kafka, not by `sp_nrt_investigation_postprocessing`. |
| `sp_public_health_case_fact_datamart_event` lines 1897-1903 (`PARTICIPATION INNER JOIN`, `TYPE_CD IN ('OrgAsReporterOfPHC','InvestgrOfPHC','PerAsReporterOfPHC','PhysicianOfPHC')`) | INNER JOIN on participation, filtered by both type_cd list AND `RECORD_STATUS_CD='ACTIVE'` | The INNER JOIN now matches the 4 rows; `F_PAGE_CASE.PROVIDERNAME` / `PROVIDERPHONE` (from PhysicianOfPHC at line 1936-1942) and `INVESTIGATORNAME` / `INVESTIGATORPHONE` / `INVESTIGATORASSIGNEDDATE` (from InvestgrOfPHC at line 1951-1962) can populate. | **YES — but only at Merge contract step 9** (Datamart SPs), not at Tier 1 isolation. Out of scope for this Tier 2 agent's verification. |
| `sp_public_health_case_fact_datamart_update` lines 105-110, 152-160 (same logic, update path) | Same | Same | Same — Merge step 9. |

**SQL Server collation note (verified, same as reporter_phc /
patient_phc):** Default collation `SQL_Latin1_General_CP1_CI_AS` is
case-insensitive, so the literal values `'PhysicianOfPHC'` /
`'InvestgrOfPHC'` (mixed case, used by both the event SP at line 872
and the datamart SPs at 072:1899/1901, 073:106) match consistently
across all SP filter sites.

## Coverage unlocked (at Tier 1 isolation)

**0 RDB_MODERN dim/fact columns flipped from NULL/sentinel-1 to real values.**

This is the honest result, fully consistent with the per-edge prompt's
guidance ("Coverage assessment: honest answer — likely 0 RDB_MODERN
dim/fact unlocks at Tier 1 isolation; benefit at Merge step 9"). The
4 participation rows' value lands in RDB_MODERN at Merge contract
step 9 (Datamart SPs:
`sp_public_health_case_fact_datamart_event`,
`sp_public_health_case_fact_datamart_update`, plus any
condition-specific datamarts that read `F_PAGE_CASE.PROVIDER_*` /
`INVESTIGATOR_*` columns), not at any Tier 1 chain re-run.

Indirect-but-real values delivered by this fixture:

1. **ODSE graph correctness** — MasterETL traverses `participation`
   directly to populate analogous physician/investigator-context
   columns on the RDB side. Without these edges, MasterETL's output
   would diverge from RTR's downstream Datamart-SP output,
   contaminating the eventual RDB-vs-RDB_MODERN comparison test. With
   these edges, the ODSE graph carries Provider-as-physician and
   Provider-as-investigator context that both pipelines can read.
2. **Event-SP JSON-projection coverage** — `sp_investigation_event`
   JSON output now projects `investigator_assigned_datetime` from the
   InvestgrOfPHC participation row (from_time field, line 848). This
   makes the event-SP output structurally complete for the
   InvestgrOfPHC pivot (matching what production CDC-Debezium-Kafka
   would observe). PhysicianOfPHC has no event-SP projection — that
   value only manifests at datamart step 9.
3. **Pre-requisite for downstream Datamart agents** — any future
   agent (Tier 3 or Datamart-coverage) that needs the participation
   rows to be present can rely on them being authored here. The
   datamart SPs' `TYPE_CD IN (...)` filter at 072:1897-1902 / 073:106
   covers all four reporter-and-physician/investigator type_cds in a
   single INNER JOIN — so all of (this edge) + (`reporter_phc` edge)
   together drive `F_PAGE_CASE` provider/investigator/reporter columns.

## Coverage still LINK_REQUIRED

Resolved by this edge:

- `coverage_investigation.md` LINK_REQUIRED #5 (`participation
  type_cd='PhysicianOfPHC' linking foundation Provider → foundation/v2
  Investigation`): **resolved** at the ODSE-graph level. The
  `nrt_investigation.physician_id` column called out in that
  LINK_REQUIRED entry is NOT a participation-driven column (no SP
  derives it from PhysicianOfPHC participation); it remains a Tier 1
  hand-authored staging column. The downstream
  `F_PAGE_CASE.PROVIDERNAME` / `PROVIDERPHONE` columns are the actual
  consumers and they populate at Merge step 9.
- `coverage_investigation.md` LINK_REQUIRED #6 (`participation
  type_cd='InvestgrOfPHC' linking foundation Provider →
  foundation/v2 Investigation`): **resolved** at the ODSE-graph level
  AND at the event-SP JSON-projection level (`investigator_assigned_datetime`
  now populates from `participation.from_time`). The
  `nrt_investigation.investigator_id` column is NOT a
  participation-driven column (no SP derives it from InvestgrOfPHC
  participation); it remains a Tier 1 hand-authored staging column.
  The downstream `F_PAGE_CASE.INVESTIGATORNAME` / `INVESTIGATORPHONE`
  / `INVESTIGATORASSIGNEDDATE` columns are the actual consumers and
  they populate at Merge step 9.

Not resolved by this edge (waiting on other Tier 2 agents — already
documented in `coverage_investigation.md`):

- `coverage_investigation.md` LINK_REQUIRED #10 (the `*InvestgrOfPHC`
  variant family — `ClosureInvestgrOfPHC` / `DispoFldFupInvestgrOfPHC`
  / `FldFupInvestgrOfPHC` / `InitFldFupInvestgrOfPHC` /
  `InitFupInvestgrOfPHC` / `SurvInvestgrOfPHC`, all `MISSING_FROM_SRTE`):
  these populate the corresponding `*_investgr_of_phc_uid` columns on
  `nrt_investigation` via the `nbs_act_entity` pivot in the event SP
  at lines 909-933. They are a separate Tier 2 deliverable
  (`nbs_act_entity_*` agent) — NOT this agent's edge type.
- `coverage_investigation.md` LINK_REQUIRED #11-#12 (Organization /
  Provider via `nbs_act_entity`): different connective table, not
  this agent's edge type.
- All RDB_MODERN dim/fact column populations that depend on these
  edges land at Merge contract step 9 (Datamart SPs); those are out
  of scope for this Tier 2 agent's verification.

## OUT_OF_SCOPE / SRTE_GAP / FOUNDATION_GAP

- **OUT_OF_SCOPE: `nrt_investigation.investigator_id` /
  `physician_id`.** Neither column populates from a participation
  pivot. The investigation_event SP at line 848 projects ONLY
  `par2.from_time` (as `investigator_assigned_datetime`) from the
  InvestgrOfPHC participation row, not `par2.subject_entity_uid`.
  No SP elsewhere derives `investigator_id` or `physician_id` from
  participation. These columns are purely hand-authored staging
  columns on `nrt_investigation` (Tier 1 left both NULL on both
  variants — that's a Tier 1 / Tier 3 staging-row gap, not a
  Tier 2 cross-subject-edge gap). To populate them in fixture flow,
  a Tier 1 amendment or Tier 3 staging-row authoring step would be
  needed. Citations: `056-sp_investigation_event-001.sql:848`
  (only from_time projected); `005-sp_nrt_investigation_postprocessing-001.sql`
  reads `investigator_assigned_datetime` at line 126 but never reads
  `investigator_id` (it only writes the column it reads from staging).
- **OUT_OF_SCOPE: `F_PAGE_CASE.PROVIDERNAME`, `PROVIDERPHONE`,
  `INVESTIGATORNAME`, `INVESTIGATORPHONE`, `INVESTIGATORASSIGNEDDATE`
  and related Datamart provider/investigator-context columns.** These
  flip to populated values at Merge contract step 9
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
  `1934-1942` (PROVIDERNAME/PHONE), `1951-1962` (INVESTIGATOR*);
  `073-sp_public_health_case_fact_datamart_update-001.sql:105-110`,
  `152-159`.
- **No SRTE_GAP.** Both `PhysicianOfPHC` and `InvestgrOfPHC` are
  present in baseline `nbs_srte.dbo.Participation_type` (verified by
  query: PhysicianOfPHC has act_class_cd='CASE',
  subject_class_cd='PSN', type_desc_txt='Physician'; InvestgrOfPHC
  has act_class_cd='CASE', subject_class_cd='PSN',
  type_desc_txt='Investigator (Current)').
- **No FOUNDATION_GAP.** Foundation Provider (entity_uid 20000010
  with class_cd='PSN', person.cd='PRV') and foundation Investigation
  (act_uid 20000100 with class_cd='CASE') match the PhysicianOfPHC
  and InvestgrOfPHC endpoint constraints exactly. Same applies for
  v2 Provider (20010010) and v2 Investigation (20050010).
- **No new LINK_REQUIRED found.** The SP filter sites visited by
  this edge are all single-edge (no chained joins through other
  cross-subject edges). The `*InvestgrOfPHC` variant family
  (`MISSING_FROM_SRTE`) is already documented in
  `coverage_investigation.md` LINK_REQUIRED #10 (nbs_act_entity
  agent's responsibility, not this edge type).

## Decisions made under prompt ambiguity

1. **Mixed-case literals chosen for both `type_cd` values
   (`'PhysicianOfPHC'`, `'InvestgrOfPHC'`).** The SP filter sites in
   056 (event, line 872 — InvestgrOfPHC only), 072/073 (datamart) all
   use mixed case. Default collation
   `SQL_Latin1_General_CP1_CI_AS` is case-insensitive, so either
   choice works, but mixed case mirrors NBS production data
   conventions and the foundation/Tier 1 fixture conventions.
2. **`record_status_cd = N'ACTIVE'` is required, not optional.**
   Verified the datamart SPs at `072-...:1896` and `073-...:104`
   filter on `PAR.RECORD_STATUS_CD = 'ACTIVE'`. Without this column,
   the participation rows would be excluded by the datamart pivot.
3. **`from_time` populated explicitly on all 4 rows.** The event SP
   projects `par2.from_time` as `investigator_assigned_datetime`
   (056:848) and the datamart SP projects same as
   `INVESTIGATORASSIGNEDDATE` (072:1959-1962, 073:159). Foundation
   gets 2026-04-01; v2 InvestgrOfPHC gets 2026-04-02 to match Tier 1
   hand-authored `nrt_investigation.investigator_assigned_datetime`
   on v2; v2 PhysicianOfPHC gets 2026-04-04 (datamart only reads
   from_time for Investgr, not Physician). PhysicianOfPHC's
   from_time has no production consumer that we found, but is
   populated for shape parity.
4. **Tail-EXEC is `sp_investigation_event` only**, NOT
   `sp_nrt_investigation_postprocessing`. Per the per-edge prompt's
   honest-reporting guidance and `reporter_phc` / `patient_phc`
   precedent: the postprocessing SP reads from `nrt_investigation`
   staging hand-authored by Tier 1 and does not traverse
   `participation`, so a re-run would be wasted work. The event SP
   re-run is a SP-callability check (no errors) and a coverage
   spot-check (verifies the InvestgrOfPHC participation row's
   from_time surfaces in the JSON projection as
   investigator_assigned_datetime).
5. **No surrogate UIDs allocated.** The participation table's
   composite PK is `(subject_entity_uid, act_uid, type_cd)`; no
   surrogate UID is needed. The full 21006000-21006999 block is
   reserved for any future amendment that needs surrogate UIDs.
6. **Same Provider serves as both Physician and Investigator for the
   same Investigation.** Per the per-edge prompt's explicit guidance:
   "Same Provider serves as both Physician and Investigator of the
   same Investigation — common in production data; v1 simplification
   per STRATEGY.md." Authored 4 rows (2 per type_cd, foundation→
   foundation + v2→v2). A future Tier 3 agent can introduce distinct
   Providers for Physician vs Investigator if needed for
   multi-provider-per-investigation datamart coverage.

## Confirmation deliverables exist

- [x] `fixtures/20_links/physician_phc.sql` — 4-row INSERT plus
      tail-EXEC of `sp_investigation_event`.
- [x] `coverage/coverage_physician_phc.md` — this file.
- [x] `catalog/uid_ranges.md` — Tier 2 section extended with the
      physician_phc agent's block (21006000-21006999) and detail
      sub-section.
