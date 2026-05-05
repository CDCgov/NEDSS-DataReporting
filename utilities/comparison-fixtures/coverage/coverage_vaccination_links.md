# Coverage: vaccination_links (SubOfVacc + PerformerOfVacc nbs_act_entity edges)

## Inputs

- Baseline: 6.0.18.1
- UID range allocated: **21007000 - 21007999** (Tier 2, eighth agent)
- Foundation dependencies:
  - foundation Vaccination: `act_uid = intervention_uid = 20000160` (`@dbo_Act_vaccination_uid`)
  - foundation Patient: `entity_uid = person_uid = 20000000` (`@dbo_Entity_patient_uid`)
  - foundation Provider: `entity_uid = person_uid = 20000010` (`@dbo_Entity_provider_uid`)
- Other-agent dependencies (Tier 1 read-only):
  - Vaccination Tier 1: v2 Vaccination `act_uid = intervention_uid = 20110010` (`@dbo_Act_vaccination_v2_uid`)
  - Patient Tier 1: v2 Patient `entity_uid = person_uid = 20020010` (`@dbo_Entity_patient_v2_uid`)
  - Provider Tier 1: v2 Provider `entity_uid = person_uid = 20010010` (`@dbo_Entity_provider_v2_uid`)
- Pre-fixture infrastructure (orchestrator-owned):
  - `dbo.RDB_DATE` populated via recursive-CTE seed (per STRATEGY.md "Note: `sp_get_date_dim` in baseline 6.0.18.1 has an RTR bug").
  - `dbo.sp_nrt_srte_condition_code_postprocessing @condition_cd_list = N'10110'` populated `dbo.CONDITION` for Hep A acute.

## Edges authored

| Table | nbs_act_entity_uid | type_cd | act_uid (Vaccination) | entity_uid | Endpoint pairing |
| --- | --- | --- | --- | --- | --- |
| `nbs_odse.dbo.nbs_act_entity` | 21007000 | `SubOfVacc` | 20000160 (foundation Vacc) | 20000000 (foundation Patient) | foundation Patient is the subject of the foundation Vaccination |
| `nbs_odse.dbo.nbs_act_entity` | 21007001 | `SubOfVacc` | 20110010 (v2 Vacc) | 20020010 (v2 Patient) | v2 Patient is the subject of the v2 Vaccination |
| `nbs_odse.dbo.nbs_act_entity` | 21007002 | `PerformerOfVacc` | 20000160 (foundation Vacc) | 20000010 (foundation Provider) | foundation Provider performed the foundation Vaccination |
| `nbs_odse.dbo.nbs_act_entity` | 21007003 | `PerformerOfVacc` | 20110010 (v2 Vacc) | 20010010 (v2 Provider) | v2 Provider performed the v2 Vaccination |

**Total: 4 rows**, each consuming a surrogate UID from the
21007000-21007999 block. **Unlike prior 7 Tier 2 agents** (which used
participation/act_relationship composite PKs and consumed zero UIDs),
nbs_act_entity has a `nbs_act_entity_uid bigint NOT NULL IDENTITY`
column requiring explicit UID allocation. The fixture wraps the INSERT
with `SET IDENTITY_INSERT [dbo].[nbs_act_entity] ON / OFF` to insert
explicit UIDs from this agent's block.

The fixture writes **0 rows** to RDB_MODERN dim/fact tables and
**0 rows** to RDB_MODERN nrt_* staging tables. Tail-EXEC is
`sp_vaccination_event` for SP-callability + JSON-projection
verification (also a coverage-unlock for the event SP itself, since
the SP went from 0 rows to 2 rows projected — see below).

## SPs verified

- `dbo.sp_vaccination_event @vac_uids = N'20000160,20110010', @debug = 0`
  — exit code 0.
  - **Pre-edge**: **0 rows projected** (the main FROM clause INNER
    JOIN at line 108 of `071-sp_vaccination_event-001.sql` filters
    `NBS_ACT_ENTITY.TYPE_CD='SubOfVacc'` — with no SubOfVacc rows in
    nbs_act_entity, the SP's projection was empty).
  - **Post-edge**: **2 rows projected** (one per Vaccination UID).
    Verified row content by direct sqlcmd capture:

    | VACCINATION_UID | PATIENT_UID | PROVIDER_UID | ORGANIZATION_UID | PHC_UID |
    | --- | --- | --- | --- | --- |
    | 20000160 | 20000000 | 20000010 | NULL | NULL |
    | 20110010 | 20020010 | 20010010 | NULL | NULL |

    Both rows now correctly project the patient (from SubOfVacc CTE,
    line 1156) and provider (from PerformerOfVacc PROVIDER_INFO CTE,
    line 1135). ORGANIZATION_UID remains NULL (no
    PerformerOfVacc-to-Organization edges authored — that is an
    optional v2 enhancement; foundation/v2 Vaccination performer is a
    Provider/Person, not an Organization). PHC_UID remains NULL (the
    `act_relationship type_cd='1180'` Vaccination → Investigation
    edge is a separate Tier 2 deliverable not owned by this agent).

- `dbo.sp_d_vaccination_postprocessing @vac_uids = N'20000160,20110010', @debug = 0`
  — exit code 0. Re-run post-edge as a sanity check; D_VACCINATION
  row count and column values **unchanged** at 3 rows (1 sentinel +
  foundation D_VACCINATION_KEY=2 + v2 D_VACCINATION_KEY=3). The SP
  reads from `nrt_vaccination` (hand-authored by Tier 1) and does
  NOT traverse `nbs_act_entity`. **0 D_VACCINATION columns flipped
  pre/post.**

- `dbo.sp_f_vaccination_postprocessing @vac_uids = N'20000160,20110010', @debug = 0`
  — exit code 0. Re-run post-edge as a sanity check; F_VACCINATION
  row count and column values **unchanged** at 2 rows. Pre-edge and
  post-edge column values are byte-identical:

  | D_VACCINATION_KEY | PATIENT_KEY | VACCINE_GIVEN_BY_KEY | VACCINE_GIVEN_BY_ORG_KEY | INVESTIGATION_KEY |
  | --- | --- | --- | --- | --- |
  | 2 (foundation) | 1 (sentinel) | 1 (sentinel) | 1 (sentinel) | 1 (sentinel) |
  | 3 (v2) | 3 (real D_PATIENT key) | 12 (real D_PROVIDER key) | 1 (sentinel) | 1 (sentinel) |

  **0 F_VACCINATION columns flipped pre/post by THIS edge.** The
  v2 row's non-sentinel PATIENT_KEY=3 and VACCINE_GIVEN_BY_KEY=12 were
  already populated pre-edge — they resolved through the `nrt_vaccination`
  soft-ref columns (`patient_uid=20000000` and `provider_uid=20000010`,
  both authored by Tier 1 on the v2 row). The Patient and Provider
  Tier 1 chains had already populated D_PATIENT (3 rows) and
  D_PROVIDER (2 rows + 11 sentinels = 13 keys) before the edge applied.
  The `f_vaccination_postprocessing` SP at lines 74-85 looks up dim
  keys via `nrt_vaccination.patient_uid` / `provider_uid` /
  `organization_uid` / `phc_uid` — all of which are columns on the
  staging table, not derived from `nbs_act_entity`.

## Coverage assessment — honest reporting

This edge is the **first Tier 2 edge that genuinely unblocks an
event SP at Tier 1 isolation** (prior 7 edges were
shape-consistency-mostly because their event SPs returned rows even
without the edges). The Vaccination event SP's main FROM clause
filters on `TYPE_CD='SubOfVacc'` as an INNER predicate (line 108 of
`071-sp_vaccination_event-001.sql`), so without our SubOfVacc rows
the event SP literally produced zero output rows.

Concrete pre/post deltas:

| Artifact | Pre-edge | Post-edge | Delta |
| --- | --- | --- | --- |
| `dbo.nbs_act_entity` row count (TYPE_CD='SubOfVacc') | 0 | 2 | +2 |
| `dbo.nbs_act_entity` row count (TYPE_CD='PerformerOfVacc') | 0 | 2 | +2 |
| `sp_vaccination_event` rows projected (foundation Vacc) | 0 | 1 | +1 |
| `sp_vaccination_event` rows projected (v2 Vacc) | 0 | 1 | +1 |
| Event-SP JSON `PATIENT_UID` field for foundation Vacc | unprojected (no row) | 20000000 | unblocked |
| Event-SP JSON `PATIENT_UID` field for v2 Vacc | unprojected (no row) | 20020010 | unblocked |
| Event-SP JSON `PROVIDER_UID` field for foundation Vacc | unprojected (no row) | 20000010 | unblocked |
| Event-SP JSON `PROVIDER_UID` field for v2 Vacc | unprojected (no row) | 20010010 | unblocked |
| `D_VACCINATION` row count | 3 | 3 | 0 |
| `D_VACCINATION` column values | (foundation null path + v2 populated path, 21/21) | identical | 0 |
| `F_VACCINATION` row count | 2 | 2 | 0 |
| `F_VACCINATION` PATIENT_KEY (foundation row) | 1 (sentinel) | 1 (sentinel) | 0 |
| `F_VACCINATION` PATIENT_KEY (v2 row) | 3 (real D_PATIENT) | 3 (real D_PATIENT) | 0 |
| `F_VACCINATION` VACCINE_GIVEN_BY_KEY (v2 row) | 12 (real D_PROVIDER) | 12 (real D_PROVIDER) | 0 |

## Coverage unlocked (at Tier 1 isolation)

**Event-SP-projection unlocks: 2 rows × 4 fields = 8 JSON-projection
fields flipped from "unprojected (no row)" to populated for the
PATIENT_UID and PROVIDER_UID pivots.** This is the FIRST Tier 2 agent
to flip event-SP projection rows (vs. flipping JSON-field values
within already-projected rows, which is what prior agents did).

**RDB_MODERN dim/fact column unlocks at Tier 1 isolation: 0.** This
is consistent with the per-edge prompt's guidance: "the postprocessing
SPs (D_VACCINATION + F_VACCINATION) change column population? They're
already 21/21 + 6/6 from Tier 1 — but some sentinel-1 keys may now
flip to real keys." After verification, the answer is more nuanced:
the sentinel-1 keys on F_VACCINATION's foundation row are NOT flipped
by this edge (they remain sentinel-1 because foundation `nrt_vaccination`
has soft-ref columns NULL — the sentinel comes from the COALESCE,
not from the dim lookup). And the v2 row's non-sentinel keys
(PATIENT_KEY=3, VACCINE_GIVEN_BY_KEY=12) were ALREADY populated
pre-edge because they are driven by `nrt_vaccination.patient_uid` /
`provider_uid` (Tier 1 hand-authored), not by `nbs_act_entity`.

The PRIMARY value of this edge:

1. **Unblocking the Vaccination event SP's JSON projection.** Without
   this edge, the event SP returns 0 rows, which would propagate to
   downstream Kafka consumers in production (the JSON output is the
   contract between RTR and downstream services). With the edge, the
   SP correctly projects 2 rows with PATIENT_UID and PROVIDER_UID
   populated. **This is the genuine Tier 1-isolation coverage unlock
   that no prior Tier 2 edge has delivered.**
2. **ODSE graph correctness for the RDB-vs-RDB_MODERN comparison test.**
   MasterETL traverses `nbs_act_entity` directly to populate analogous
   vaccination subject/performer columns on the RDB side. Without
   these edges, MasterETL's output would diverge from RTR's downstream
   output, contaminating the eventual RDB-vs-RDB_MODERN comparison.
   With these edges, the ODSE graph carries vaccination-subject and
   vaccination-performer context consistently.
3. **Pre-requisite for downstream agents.** Any future Tier 2/Tier 3
   agent that needs nbs_act_entity SubOfVacc / PerformerOfVacc rows
   to be present (e.g., a future Tier 2 agent that wires
   `act_relationship type_cd='1180'` Vaccination → Investigation
   would create the third leg of the vaccination-event projection,
   feeding PHC_UID via line 1167) can rely on these rows being
   authored here.

## Coverage still LINK_REQUIRED

Resolved by this edge:

- `coverage_vaccination.md` LINK_REQUIRED
  "Tier 2 cross-subject edges required for the event SP to surface
  rows: `participation.type_cd='SubOfVacc'` ... `participation.type_cd='PerformerOfVacc'`":
  **resolved**. (The coverage doc said "participation" but the actual
  table is `nbs_act_entity` — verified against
  `071-sp_vaccination_event-001.sql:108,1135,1146,1156` which all
  read `NBS_ACT_ENTITY`, not `participation`. Catalog row in
  `edge_types.md` "dbo.nbs_act_entity" lists both type_cds correctly.)

Not resolved by this edge (waiting on other Tier 2 agents — already
documented in `coverage_vaccination.md`):

- `coverage_vaccination.md` LINK_REQUIRED #1 (F_VACCINATION foundation
  row's `PATIENT_KEY` / `VACCINE_GIVEN_BY_KEY` /
  `VACCINE_GIVEN_BY_ORG_KEY` / `INVESTIGATION_KEY`): foundation row's
  sentinel-1 keys remain sentinel-1 because foundation
  `nrt_vaccination.patient_uid` / `provider_uid` /
  `organization_uid` / `phc_uid` are NULL (Tier 1 deliberately left
  them NULL for the foundation null-propagation variant). Resolution
  requires either a Tier 1 amendment populating the soft refs on
  foundation, or a downstream Datamart SP that derives them via
  ODSE-graph traversal — neither is this agent's responsibility.
- `coverage_vaccination.md` LINK_REQUIRED entry "act_relationship.type_cd='1180'"
  for VaccinationToPHC (line 1167 of the event SP): this would
  populate the event-SP JSON `PHC_UID` field. The 1180
  act_relationship is a separate Tier 2 deliverable
  (`vaccination_to_phc` or analogous edge agent), NOT owned by this
  agent. Currently `PHC_UID` projects as NULL post-edge for both
  vaccination rows (verified above).
- `coverage_vaccination.md` mentions `PerformerOfVacc` may also link
  to an Organization (catalog row notes "Person (provider) or
  Organization"). This v1 fixture authors PerformerOfVacc-to-Provider
  edges only (matching the per-edge prompt's "Skip [Org performer]
  for v1 unless the SP coverage demonstrably needs it"). Result:
  ORGANIZATION_UID JSON field projects as NULL post-edge for both
  vaccination rows. The ORG_INFO CTE at line 1140-1148 INNER joins
  both `nbs_act_entity` (TYPE_CD='PerformerOfVacc') AND
  `Organization` — so it requires both an nbs_act_entity row pointing
  to an Organization entity_uid (not authored here) AND that entity
  being a row in `Organization`. A future amendment can add a 5th row
  to this fixture if Organization-as-performer coverage is needed.

## OUT_OF_SCOPE / SRTE_GAP / FOUNDATION_GAP

- **OUT_OF_SCOPE: F_VACCINATION foundation-row sentinel-1 FK columns.**
  As documented above, foundation row's `PATIENT_KEY` / `VACCINE_GIVEN_BY_KEY`
  / `VACCINE_GIVEN_BY_ORG_KEY` / `INVESTIGATION_KEY` remain sentinel-1
  because the lookup is driven by `nrt_vaccination` soft refs (NULL
  on foundation row), not by nbs_act_entity. Out of scope for this
  Tier 2 agent — would require a Tier 1 staging-row amendment.
- **OUT_OF_SCOPE: `sp_vaccination_event` ORGANIZATION_UID projection.**
  Post-edge ORGANIZATION_UID is NULL on both projected rows because
  this fixture does not author a PerformerOfVacc-to-Organization
  edge (per the per-edge prompt's v1 simplification). Out of scope
  unless Organization-performer coverage is later required.
- **OUT_OF_SCOPE: `sp_vaccination_event` PHC_UID projection.**
  Post-edge PHC_UID is NULL on both projected rows because the event
  SP at line 1167 reads `act_relationship.type_cd='1180'` for the
  VaccinationToPHC pivot. That edge is a separate Tier 2 agent's
  responsibility (not this fixture's).
- **OUT_OF_SCOPE: Datamart SPs.** No Datamart SP is invoked by this
  fixture. The Vaccination dimension/fact has no Datamart-tier SP
  in the RTR routine catalog beyond `sp_covid_vaccination_datamart_postprocessing`,
  which is itself out of scope per `coverage_vaccination.md`.
- **No SRTE_GAP.** Both `SubOfVacc` and `PerformerOfVacc` are present
  in baseline `nbs_srte.dbo.Participation_type` (verified by query):
  - SubOfVacc: act_class_cd='INTV', subject_class_cd='PAT',
    type_desc_txt='Subject of Vaccination'.
  - PerformerOfVacc: act_class_cd='INTV', appears with both
    subject_class_cd='PSN' (type_desc_txt='Vaccination Administration
    Provider') AND subject_class_cd='ORG' (type_desc_txt='Vaccination
    Administration Facility'). We use the PSN flavor for v1.
- **No FOUNDATION_GAP.** Foundation Vaccination (act_uid 20000160 with
  class_cd='INTV', mood='EVN', `intervention.intervention_uid=20000160`),
  foundation Patient (entity_uid 20000000, class_cd='PSN',
  person.cd='PAT'), and foundation Provider (entity_uid 20000010,
  class_cd='PSN', person.cd='PRV') match the SubOfVacc/PerformerOfVacc
  endpoint constraints exactly. Same applies for v2 Vaccination
  (20110010), v2 Patient (20020010), v2 Provider (20010010).
- **No new LINK_REQUIRED found.** The SP filter sites visited by this
  edge (lines 108, 1135, 1146, 1156) are all single-edge — no chained
  joins through other cross-subject edges.

## Decisions made under prompt ambiguity

1. **IDENTITY_INSERT wrap required for nbs_act_entity inserts.**
   `nbs_act_entity_uid` is an IDENTITY column in baseline 6.0.18.1
   (verified via `sys.columns.is_identity=1`), unlike the participation
   and act_relationship tables used by prior Tier 2 agents. The
   per-edge prompt did not explicitly mention IDENTITY semantics,
   but the surrogate-UID requirement implied explicit allocation,
   which mandates `SET IDENTITY_INSERT ... ON / OFF` around the
   INSERT. Initial apply failed with Msg 544 ("Cannot insert
   explicit value for identity column ... when IDENTITY_INSERT is
   set to OFF"); re-applied successfully after wrapping.
2. **`type_cd` populated as `N'SubOfVacc'` and `N'PerformerOfVacc'`
   (mixed case).** The SP filter sites at 071-...:108 (`'SubOfVacc'`),
   1135 (`'PerformerOfVacc'`), 1146 (`'PerformerOfVacc'`),
   1156 (`'SubOfVacc'`) all use mixed case. Default collation
   `SQL_Latin1_General_CP1_CI_AS` is case-insensitive, so either
   choice works, but mixed case mirrors NBS production data
   conventions and the SRTE Participation_type entries.
3. **`entity_version_ctrl_nbr = 1` (smallint).** Standard NBS
   convention for new versioned rows. The per-edge prompt explicitly
   called this out as a NOT-NULL column requiring a value.
4. **`record_status_cd = N'ACTIVE'` populated explicitly even though
   no current SP filters on it.** Same shape-consistency rationale
   as prior Tier 2 agents. Future SP additions might filter; ODSE
   graph correctness for the comparison test against MasterETL also
   benefits.
5. **PerformerOfVacc-to-Provider only, not -to-Organization.** Per
   the per-edge prompt: "Optional: Performer can also link to an Org
   for 'provider-as-org' variant. Skip for v1 unless the SP coverage
   demonstrably needs it." Verified post-edge: ORGANIZATION_UID
   projects as NULL on both vaccination rows; this is not a fixture
   failure but a deliberate v1 scope decision. A future amendment
   could add a 5th row (`PerformerOfVacc` → foundation Organization
   `entity_uid=20000020`) to populate ORGANIZATION_UID, but the v2
   fully-attributed Vaccination row's `nrt_vaccination.organization_uid`
   already references the foundation Organization for downstream
   F_VACCINATION lookup — so the gap exists only at the event SP's
   JSON projection level, not at the dim/fact level.
6. **No tail-EXEC of D_VACCINATION / F_VACCINATION postprocessing
   SPs in the fixture file.** The merge orchestrator owns step-7
   re-runs; this fixture's tail-EXEC is `sp_vaccination_event` only,
   which is the genuine coverage-unlock target. We DID re-run the
   postprocessing SPs during verification to confirm they produce
   identical D_VACCINATION/F_VACCINATION values pre/post-edge
   (a sanity check, not a fixture-flow requirement).
7. **No surrogate-UID allocation for "future amendment" reservation
   beyond the 4 used.** The 21007000-21007999 block is deliberately
   wide (1000 UIDs); 996 are reserved for future Vaccination-link
   Tier 2 amendments (e.g., adding the Organization-performer 5th
   row, or a v3 Vaccination's edges).

## Confirmation deliverables exist

- [x] `fixtures/20_links/vaccination_links.sql` — 4-row INSERT into
      `nbs_act_entity` (with IDENTITY_INSERT wrap) plus tail-EXEC
      of `sp_vaccination_event`.
- [x] `coverage/coverage_vaccination_links.md` — this file.
- [x] `catalog/uid_ranges.md` — Tier 2 section extended with the
      vaccination_links agent's block (21007000-21007999) and detail
      sub-section listing all 4 surrogate UIDs.
