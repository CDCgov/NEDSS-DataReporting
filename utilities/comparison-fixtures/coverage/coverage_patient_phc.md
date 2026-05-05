# Coverage: patient_phc (SubjOfPHC participation edge)

## Inputs

- Baseline: 6.0.18.1
- UID range allocated: **21004000 - 21004999** (Tier 2, fifth agent)
- Foundation dependencies:
  - foundation Patient: `entity_uid = person_uid = 20000000` (`@dbo_Entity_patient_uid`)
  - foundation Investigation: `act_uid = public_health_case_uid = 20000100` (`@dbo_Act_investigation_uid`)
- Other-agent dependencies (Tier 1 read-only):
  - Patient Tier 1: v2 Patient `entity_uid = person_uid = 20020010` (`@dbo_Entity_patient_v2_uid`)
  - Investigation Tier 1: v2 Investigation `act_uid = public_health_case_uid = 20050010` (`@dbo_Act_investigation_v2_uid`)
- Pre-fixture infrastructure (orchestrator-owned):
  - `dbo.RDB_DATE` populated via recursive-CTE seed (per STRATEGY.md "Note: `sp_get_date_dim` in baseline 6.0.18.1 has an RTR bug").
  - `dbo.sp_nrt_srte_condition_code_postprocessing @condition_cd_list=N'10110'` populated `dbo.CONDITION` for Hep A, acute. (Note: the SP signature now requires `@condition_cd_list`; templates citing a parameterless invocation are stale.)

## Edges authored

| Table | type_cd | act_class_cd | subject_class_cd | act_uid (Investigation) | subject_entity_uid (Patient) | Endpoint pairing |
| --- | --- | --- | --- | --- | --- | --- |
| `nbs_odse.dbo.participation` | `SubjOfPHC` | `CASE` | `PSN` | 20000100 (foundation) | 20000000 (foundation) | foundation Patient is subject of foundation Investigation |
| `nbs_odse.dbo.participation` | `SubjOfPHC` | `CASE` | `PSN` | 20050010 (v2) | 20020010 (v2) | v2 Patient is subject of v2 Investigation |

**Total: 2 rows** (no surrogate UID required — composite PK is
`(subject_entity_uid, act_uid, type_cd)`; the 21004000-21004999 block
is reserved for future amendments).

The fixture writes **0 rows** to RDB_MODERN dim/fact tables and
**0 rows** to RDB_MODERN nrt_* staging tables. Tail-EXEC is
sp_investigation_event for SP-callability verification only.

## SPs verified

- `dbo.sp_investigation_event @phc_id_list = N'20000100,20050010'` — exit code 0 / 2 rows projected. **JSON projection now contains the SubjOfPHC participation row in the `person_participations` branch** for both Investigations (verified by grep for `SubjOfPHC.*entity_id":20000000` and `SubjOfPHC.*entity_id":20020010` — both match exactly once each).
- (No re-run of `sp_nrt_investigation_postprocessing` or `sp_nrt_notification_postprocessing` — neither reads `participation` directly; their RDB_MODERN dim/fact output is unaffected by this edge at Tier 1 isolation.)

## Coverage assessment — honest reporting

This edge is **shape-consistency-mostly at Tier 1 isolation**, exactly
as the per-edge prompt warned. Concretely:

- `dbo.INVESTIGATION` (the dimension): 4 rows pre-edge (sentinel
  INVESTIGATION_KEY=1, baseline-seeded KEY=2 for case_uid 10000013,
  KEY=3 for foundation Inv 20000100, KEY=4 for v2 Inv 20050010). The
  post-edge `sp_nrt_investigation_postprocessing` re-run (when invoked
  for verification) leaves all four rows byte-identical: the SP reads
  `nrt_investigation` (hand-authored by Tier 1 Investigation) and
  never traverses `participation`. **Coverage flipped: 0 columns.**
- `dbo.NOTIFICATION_EVENT` columns reading patient context (e.g.,
  `local_patient_uid`, `PATIENT_KEY`): unaffected at Tier 1 isolation.
  `sp_nrt_notification_postprocessing` reads `local_patient_uid` from
  `nrt_investigation_notification` (Tier 1 hand-authored to 20000000)
  and `PATIENT_KEY` is COALESCEd against `D_PATIENT.PATIENT_KEY`
  via `nrt_investigation_notification.local_patient_uid` — neither
  path crosses `participation`. **Coverage flipped: 0 columns.**

What this edge **does** unlock — but ONLY in projections / outputs
that are NOT RDB_MODERN dim/fact tables at Tier 1 isolation:

| SP / projection | LEFT JOIN site | Effect of edge | RDB_MODERN dim/fact column flipped? |
| --- | --- | --- | --- |
| `sp_investigation_event` line 741 (notification_history aggregation, nested in Investigation JSON) | `LEFT JOIN participation part ON part.type_cd='SubjOfPHC' AND part.act_uid=act.target_act_uid` | Resolves the Patient row inside notification_history nested per-notification subject | **No.** The aggregation is projected into JSON consumed by Kafka; not read by `sp_nrt_investigation_postprocessing`. |
| `sp_investigation_event` ~line 339-360 (`person_participations` branch) | Direct read of participation rows where `act_uid = phc.public_health_case_uid` | The 2 SubjOfPHC rows now appear in the JSON `person_participations` array (verified above) | **No.** Same — JSON-only at this level. |
| `sp_notification_event` line 102 (`local_patient_id`/`local_patient_uid` JSON projection) | `LEFT JOIN participation part ON part.type_cd='SubjOfPHC' AND part.act_uid=act.target_act_uid` | Resolves the Patient identity into the Notification JSON output | **No.** `sp_nrt_notification_postprocessing` does not read this projection — it reads the same field from `nrt_investigation_notification`. |
| `sp_public_health_case_fact_datamart_event` line 147 (`WHERE PAR.TYPE_CD = 'SUBJOFPHC'`) | INNER JOIN on `participation` filtered by uppercase 'SUBJOFPHC' | The INNER JOIN now matches; F_PAGE_CASE.PATIENT_KEY and patient-context columns can populate | **YES — but only at Merge contract step 9** (Datamart SPs), not at Tier 1 isolation. Out of scope for this Tier 2 agent's verification. |
| `sp_public_health_case_fact_datamart_update` line 54 (`WHERE PAR.TYPE_CD = 'SUBJOFPHC' AND ...`) | Same | Same | Same |

**SQL Server collation note (verified):** Default collation
`SQL_Latin1_General_CP1_CI_AS` is case-insensitive, so the literal
value `'SubjOfPHC'` (mixed case, used by the event SPs) matches the
filter `'SUBJOFPHC'` (uppercase, used by the datamart SPs). One
participation row value satisfies all four filter sites.

## Coverage unlocked (at Tier 1 isolation)

**0 RDB_MODERN dim/fact columns flipped from NULL/sentinel-1 to real values.**

This is the honest result. The participation row's value lands in
RDB_MODERN at Merge contract step 9 (Datamart SPs:
`sp_public_health_case_fact_datamart_event`,
`sp_public_health_case_fact_datamart_update`,
`sp_inv_summary_datamart_postprocessing`, etc.), not at any Tier 1
chain re-run.

Indirect-but-real values delivered by this fixture:

1. **ODSE graph correctness** — MasterETL traverses `participation`
   directly to populate analogous patient-context columns on the
   RDB side. Without this edge, MasterETL's output would diverge
   from RTR's downstream Datamart-SP output, contaminating the
   eventual RDB-vs-RDB_MODERN comparison test. With this edge, the
   ODSE graph carries a Patient↔Investigation context that both
   pipelines can read.
2. **Event-SP JSON-projection coverage** — `sp_investigation_event`
   and `sp_notification_event` JSON outputs now project Patient
   identity inside the per-Investigation / per-Notification subject
   blocks. This makes the event-SP outputs structurally complete
   (matching what production CDC-Debezium-Kafka would observe) even
   though we don't consume the projection in our local fixture flow.
3. **Pre-requisite for downstream Tier 2 / Datamart agents** —
   any future agent (Tier 3 or Datamart-coverage) that needs the
   participation row to be present can rely on it being authored
   here.

## Coverage still LINK_REQUIRED

Resolved by this edge:

- `coverage_investigation.md` LINK_REQUIRED #1 (`participation
  type_cd='SubjOfPHC' linking foundation Patient → foundation
  Investigation`): **resolved.** The `person_participations` JSON
  branch (event SP lines 339-360) now contains the foundation pair
  in its array. Note: the LINK_REQUIRED entry called out
  "downstream `sp_public_health_case_fact_datamart_event/_update`
  which is out of scope here." That is exactly where the value will
  land — at Merge contract step 9, not at Tier 1 isolation.
- `coverage_investigation.md` LINK_REQUIRED #2 (`participation
  type_cd='SubjOfPHC' linking patient → v2 Investigation`):
  **resolved**, same as #1 with v2 endpoints.
- `coverage_notification.md` line 145 LINK_REQUIRED (`participation
  Patient → Notification's-investigation as 'SubjOfPHC'`):
  **resolved at the JSON-projection level only.** The Notification
  event SP's nested OUTER APPLY at line 102 now resolves to populate
  `local_patient_id`/`local_patient_uid` in the JSON projection.
  The dimension column `NOTIFICATION_EVENT.PATIENT_KEY` is
  unaffected because `sp_nrt_notification_postprocessing` reads
  `nrt_investigation_notification.local_patient_uid` (Tier 1
  hand-authored to 20000000) — not from the JSON projection.
- `coverage_inv_notification.md` line 102 (the
  participation/SubjOfPHC LINK_REQUIRED noted there):
  **resolved at the JSON-projection level only**, same caveat.

Not resolved by this edge (waiting on other Tier 2 agents):

- `coverage_investigation.md` LINK_REQUIRED #3-#16: separate edge
  types (`OrgAsReporterOfPHC`, `PerAsReporterOfPHC`,
  `PhysicianOfPHC`, `InvestgrOfPHC`, `HospOfADT`, `OrgAsClinicOfPHC`,
  `InterviewerOfPHC`, etc.). Each is its own Tier 2 agent.
- Any RDB_MODERN dim/fact column that depends on this edge will
  populate at Merge contract step 9 (Datamart SPs); those are out
  of scope for this Tier 2 agent's verification.

## OUT_OF_SCOPE / SRTE_GAP / FOUNDATION_GAP

- **OUT_OF_SCOPE: `F_PAGE_CASE.PATIENT_KEY` and other Datamart
  patient-context columns.** These flip to populated values at
  Merge contract step 9 (`sp_public_health_case_fact_datamart_event`,
  `sp_public_health_case_fact_datamart_update`,
  `sp_inv_summary_datamart_postprocessing`,
  `sp_hepatitis_datamart_postprocessing`, etc.) — none of which is
  in scope for this Tier 2 agent's verification. The Datamart SPs
  read the participation row authored here directly via
  `WHERE PAR.TYPE_CD = 'SUBJOFPHC'` (case-insensitive collation
  matches our `'SubjOfPHC'` literal). Citation:
  `072-sp_public_health_case_fact_datamart_event-001.sql:147`,
  `073-sp_public_health_case_fact_datamart_update-001.sql:54`.
- **No SRTE_GAP.** `SubjOfPHC` is present in baseline
  `nbs_srte.dbo.Participation_type` (verified:
  `act_class_cd='CASE', subject_class_cd='PSN', concept_code='DEM222',
  type_desc_txt='Subject of Investigation'`).
- **No FOUNDATION_GAP.** Foundation Patient (entity_uid 20000000
  with class_cd='PSN', person.cd='PAT') and foundation Investigation
  (act_uid 20000100 with class_cd='CASE') match the SubjOfPHC
  endpoint constraints exactly.
- **No new LINK_REQUIRED found.** The SP filter sites visited by
  this edge are all single-edge (no chained joins through other
  cross-subject edges).

## Decisions made under prompt ambiguity

1. **Mixed-case `'SubjOfPHC'` literal chosen for the `type_cd`
   value.** The SP filter sites use mixed (`SubjOfPHC`, event SPs)
   and uppercase (`SUBJOFPHC`, datamart SPs) literals. Default
   collation `SQL_Latin1_General_CP1_CI_AS` is case-insensitive,
   so either choice satisfies all four filter sites. We pick mixed
   case to mirror the foundation conventions (the existing baseline
   `dbo.participation` row at PK `(10000008, 10000013, SubjOfPHC)`
   uses mixed case) and to match what NBS production data carries.
2. **Tail-EXEC is `sp_investigation_event` only**, NOT
   `sp_nrt_investigation_postprocessing` or
   `sp_nrt_notification_postprocessing`. Per the per-edge prompt's
   honest-reporting guidance: the postprocessing SPs read from
   nrt_* staging hand-authored by Tier 1 and do not traverse
   `participation`, so a re-run would be wasted work. The event SP
   re-run is a SP-callability check (no errors) and a coverage
   spot-check (verifies the participation row surfaces in the JSON
   projection).
3. **No surrogate UIDs allocated.** The participation table's
   composite PK is `(subject_entity_uid, act_uid, type_cd)`; no
   surrogate UID is needed. The full 21004000-21004999 block is
   reserved for any future amendment that needs surrogate UIDs.
4. **Authored 2 pairs (foundation→foundation + v2→v2),** not the
   four possible cross-pairs. This mirrors the convention in the
   four prior Tier 2 fixtures (inv_notification, lab_inv, morb_inv,
   treatment_inv). A future Tier 3 agent can add cross-pairs
   (e.g., foundation Patient ↔ v2 Investigation) if needed for
   multi-investigation-per-patient datamart coverage.

## Confirmation deliverables exist

- [x] `fixtures/20_links/patient_phc.sql` — 2-row INSERT plus
      tail-EXEC of `sp_investigation_event`.
- [x] `coverage/coverage_patient_phc.md` — this file.
- [x] `catalog/uid_ranges.md` — Tier 2 section extended with the
      patient_phc agent's block (21004000-21004999) and detail
      sub-section.
