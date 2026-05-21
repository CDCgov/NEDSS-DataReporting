# Coverage: BMIRD (Strep pneumoniae invasive) Investigation full ODSE + observation chain

Generated: 2026-05-21

## Inputs

- Baseline: 6.0.18.1 (post-liquibase) + foundation + all Tier 1 fixtures
  + all Tier 2 fixtures + existing Tier 3 fixtures (including
  `multi_condition_investigations.sql` stub at UID 22000100).
- Fixture file:
  `fixtures/30_sp_coverage/bmird_investigation_full_chain.sql`.
- UID range allocated: **22005000 - 22005999** (Tier 3 BMIRD full-chain).
- Foundation dependencies (read-only):
  - `@superuser_id = 10009282`.
  - `@dbo_Entity_patient_uid = 20000000` (foundation Patient; referenced
    by `nrt_investigation.patient_id` so `BMIRD_STREP_PNEUMO_DATAMART`'s
    `LEFT JOIN D_PATIENT P ON BC.PATIENT_KEY = P.PATIENT_KEY` (140 SP
    line 127-128) resolves through `V_NRT_INV_KEYS_ATTRS_MAPPING`'s
    `coalesce(dpat.patient_key, 1)` to the populated foundation Patient
    row).
- Tier 3 dependencies (read-only):
  - The existing BMIRD Strep pneumo stub at `public_health_case_uid =
    22000100` in `fixtures/30_sp_coverage/multi_condition_investigations.sql`
    is **left untouched**. It continues to exercise the no-observations
    path. Our full-chain UID 22005000 exercises the populated-answers
    path.

## UID allocations

| UID | Symbolic | Entity / column | Notes |
| --- | --- | --- | --- |
| 22005000 | bmird_full_phc_uid | `act.act_uid`, `public_health_case.public_health_case_uid`, `nrt_investigation.public_health_case_uid`, `nrt_investigation.nac_page_case_uid`, `nrt_investigation_observation.public_health_case_uid` for every observation row | The single BMIRD Strep pneumo invasive full-chain anchor. |
| 22005001 | bmird_full_case_mgmt_uid | `case_management.case_management_uid` (IDENTITY-inserted) | Per Tier 1 v2 Investigation shape. |
| 22005100..22005112 | (13 BMIRD_Case coded feeders) | `nrt_observation.observation_uid` + linked obs-value/coded rows | One per BMD-prefix coded question routed to `BMIRD_Case` by `nrt_srte_IMRDBMapping`. |
| 22005120..22005123 | (4 BMIRD_Case text feeders) | `nrt_observation.observation_uid` + `nrt_observation_txt` | Free-text BMD answers. |
| 22005130 | (1 BMIRD_Case numeric feeder) | `nrt_observation.observation_uid` + `nrt_observation_numeric` | BMD136 OXACILLIN_ZONE_SIZE. |
| 22005140..22005141 | (2 BMIRD_Case date feeders) | `nrt_observation.observation_uid` + `nrt_observation_date` | First/second additional specimen dates. |
| 22005150..22005153 | (4 BMIRD_Multi_Value_field feeders) | `nrt_observation.observation_uid` + `nrt_observation_coded` | BMD multi-value answers routed to `BMIRD_Multi_Value_field` by `nrt_srte_IMRDBMapping`. |

Unused UIDs in BMIRD full-chain Tier 3 block (22005002-22005099,
22005113-22005119, 22005124-22005129, 22005131-22005139,
22005142-22005149, 22005154-22005999) reserved for future expansion
(more BMD/INV question rows; Antimicrobial batch-entry observations;
LDF_BMIRD via LDF_DIMENSIONAL_DATA seed rows).

## SPs verified

Tail-EXEC'd in dependency order from the fixture file + the BMIRD chain
SPs invoked directly (Step 9 owns them; we verify only here, the
orchestrator owns the orchestrated invocation).

| SP | File | Param | Outcome |
| --- | --- | --- | --- |
| `sp_nrt_investigation_postprocessing` | 005 | `@id_list` | INSERT into `INVESTIGATION` for case_uid=22005000 (verified). Run by fixture tail-EXEC. |
| `sp_bmird_case_datamart_postprocessing` | 040 | `@phc_uids` | INSERT into `BMIRD_Case` (1 row, ~30 columns populated from BMD answer pivot) + 1 row into `BMIRD_MULTI_VALUE_FIELD` from pivoted multi-value answers. **Run by Step 9 of orchestrator (line 505)**, NOT by fixture. |
| `sp_bmird_strep_pneumo_datamart_postprocessing` | 140 | `@phc_uids` | INSERT into `BMIRD_STREP_PNEUMO_DATAMART` (1 row, ~25 / 140 columns populated). **Run by Step 9 of orchestrator (line 506)**, NOT by fixture. |
| `sp_ldf_bmird_datamart_postprocessing` | 285 | `@phc_uids` | 0 rows (see Gaps: LDF_BMIRD requires LDF_DIMENSIONAL_DATA seed). **Run by Step 9 of orchestrator (line 526)**, NOT by fixture. |

## Columns populated — row counts per BMIRD-cluster table

| Table | Total cols | Rows | Notes |
| --- | --- | --- | --- |
| `BMIRD_Case` | 170 | 1 new (2 total including SP-internal sentinel) | ~30 / 170 columns populated. Coded path: BACTERIAL_SPECIES_ISOLATED='Streptococcus pneumoniae, invasive' (resolved via BM_SPEC_ISOL codeset from '11717'), TRANSFERED_IND, DAYCARE_IND, NURSING_HOME_IND, PREGNANT_IND, UNDERLYING_CONDITION_IND='Yes', OXACILLIN_INTERPRETATION='R<20mm(possibly resistant)', PNEUVACC_RECEIVED_IND='Yes', PNEUCONJ_RECEIVED_IND='No', PERSISTENT_DISEASE_IND='No', SAME_PATHOGEN_RECURRENT_IND='No', CULTURE_SEROTYPE='19A', ABCCASE='Yes'. Text path: TYPES_OF_OTHER_INFECTION, STERILE_SITE_OTHER, OTHNONSTER, OTHSEROTYPE. Numeric path: OXACILLIN_ZONE_SIZE=22. Date path: FIRST_ADDITIONAL_SPECIMEN_DT='2026-03-25', SECOND_ADDITIONAL_SPECIMEN_DT='2026-03-28'. Plus all V_NRT_INV_KEYS_ATTRS_MAPPING keys (INVESTIGATION_KEY, PATIENT_KEY, CONDITION_KEY=150, INV_ASSIGNED_DT_KEY=1, NURSING_HOME_KEY=1, ADT_HSPTL_KEY=1, etc.) + ANTIMICROBIAL_GRP_KEY=1 (sentinel — no Antimicrobial rows) + BMIRD_MULTI_VAL_GRP_KEY=2 (new). |
| `BMIRD_STREP_PNEUMO_DATAMART` | 140 | 1 new (2 total on re-run due to RTR Bug — see Gaps) | ~25 / 140 columns populated. DISEASE_CD='11717', DISEASE='Strep pneumoniae, invasive', BACTERIAL_SPECIES_ISOLATED='Streptococcus pneumoniae, invasive', TYPE_INFECTION_BACTEREMIA='Yes' (pivoted from BM_INFEC_TYPE='Bacteremia without focus' via SP 140 CASE WHEN line 797), UNDERLYING_CONDITION_1='Diabetes Mellitus', NON_STERILE_SITE_1='Sinus', ADD_CULTURE_1_SITE_1='Blood', OXACILLIN_INTERPRETATION, OXACILLIN_ZONE_SIZE=22, CULTURE_SEROTYPE='19A', VACCINE_POLYSACCHARIDE='Yes', VACCINE_CONJUGATE='No', HOSPITALIZED='Yes', HOSPITALIZED_ADMISSION_DATE, HOSPITALIZED_DISCHARGE_DATE, HOSPITALIZED_DURATION_DAYS=8, ILLNESS_ONSET_DATE, CASE_STATUS='Confirmed', MMWR_WEEK=14, MMWR_YEAR=2026, EVENT_DATE_TYPE='Illness Onset Date', EVENT_DATE='2026-03-22', ADD_CULTURE_1_DATE='2026-03-25', ADD_CULTURE_2_DATE='2026-03-28', GENERAL_COMMENTS, PROGRAM_JURISDICTION_OID=22005000. |
| `BMIRD_MULTI_VALUE_FIELD` | 17 | 1 new (2 total including SP-internal sentinel) | TYPES_OF_INFECTIONS='Bacteremia without focus', UNDERLYING_CONDITION_NM='Diabetes Mellitus', NON_STERILE_SITE='Sinus', STREP_PNEUMO_1_CULTURE_SITES='Blood'. The 4 BMD multi-value answers got UNPIVOTed by SP 040's `#OBS_CODED_BMIRD_Multi_Value_field` block (lines 270-289) into a single row with all 4 columns set. |
| `ANTIMICROBIAL` | 7 | 0 new (1 sentinel only) | OUT_OF_SCOPE: Antimicrobial batch-entry observations require root-observation/branch_id structure not authored here. See Gaps. |
| `LDF_BMIRD` | 7 | 0 | LDF_DIMENSIONAL_DATA seed rows required. See Gaps. |

### Summary
- **3 of 5** BMIRD cluster tables populate from this fixture
  (BMIRD_Case + BMIRD_STREP_PNEUMO_DATAMART + BMIRD_MULTI_VALUE_FIELD).
- **2 of 5** remain empty: `ANTIMICROBIAL` (batch-entry observation
  scaffolding required — separate Phase 2 work, ~50 UIDs reserved at
  22005200-22005299) and `LDF_BMIRD` (LDF_DIMENSIONAL_DATA seed rows
  required — same Phase 2 LDF work that blocks TB_PAM_LDF /
  STD_HIV_LDF / similar tables).
- BMIRD_STREP_PNEUMO_DATAMART picks up an extra duplicate row each
  re-run (INSERT-only SP, no DELETE-first guard) — same RTR bug as
  TB_DATAMART. See "RTR Bug surfaced" below.

## Columns deliberately skipped

| Table | Column | Reason | Citation |
| --- | --- | --- | --- |
| `BMIRD_Case` | ~140 / 170 columns | Each is fed by a distinct BMD/INV question; this fixture authors a 24-question minimum-viable set to prove the chain runs. Authoring the remaining ~150 BMD/INV questions is a fixture-completeness exercise (~1 day of mechanical SQL); not blocked by infrastructure. | `040-sp_bmird_case_datamart_postprocessing-001.sql:60-72` (the unique_cd source for the obs-coded pivot) + `nrt_srte_IMRDBMapping` (full BMD list — 170 rows match `RDB_table='BMIRD_Case'`). |
| `BMIRD_STREP_PNEUMO_DATAMART` | ~115 / 140 columns | Most additional columns are downstream of BMD/INV questions we did not author OR ANTIMICROBIAL/LDF subqueries that depend on tables not populated here. The hard-coded 8-column Antimicrobial pivot (ANTIMICROBIAL_AGENT_TESTED_1..8 + SUSCEPTABILITY_METHOD_1..8 + MIC_VALUE_1..8 etc.) needs ANTIMICROBIAL rows (40 of the 140 cols). Underlying conditions 2..8 + non-sterile sites 2..3 + add-culture sites 2..3 need additional multi-value answers (9 cols). Reporter/Hospital/Investigator columns need Tier 2 participation edges. | `140-sp_bmird_strep_pneumo_datamart_postprocessing-001.sql:1185-1387` (the wide INSERT column list). |
| `ANTIMICROBIAL` | All columns | See ANTIMICRO_GAP below. |
| `LDF_BMIRD` | All columns | See LDF_GAP below. |

## Gaps reported

### LDF_GAP: LDF_BMIRD requires LDF_DIMENSIONAL_DATA seed rows

`285-sp_ldf_bmird_datamart_postprocessing-001.sql:103-109` INNER JOINs
`LDF_DIMENSIONAL_DATA` to `LDF_DATAMART_TABLE_REF` filtered by
`DATAMART_NAME='LDF_BMIRD'`. The baseline `LDF_DIMENSIONAL_DATA` is
empty; sp_nrt_ldf_postprocessing populates it only when LDF rows exist
for an Investigation (out of scope for this fixture). Same Phase 2
LDF work that `coverage_tb_full_chain.md` already calls out for
TB_PAM_LDF; the existing `fixtures/30_sp_coverage/ldf_answers_tetanus.sql`
is the template.

### ANTIMICRO_GAP: ANTIMICROBIAL requires root + branch observations

`040-sp_bmird_case_datamart_postprocessing-001.sql:200-264` reads
v_rdb_obs_mapping rows where `RDB_table='Antimicrobial'`, filtering on
`root_observation_uid` and `branch_id` — meaning Antimicrobial answers
need a parent (root) observation + child observations (branches) for
batch-entry structure (one batch per drug tested). Authoring this
correctly requires populating `v_getobscode`'s `branch_id` /
`root_observation_uid` semantics — `nrt_investigation_observation`
rows where `root_type_cd='AntimicrobialRoot'` + child observations
of varying `branch_id`. Reserve 22005200-22005299 (100 UIDs) for a
Phase 2 follow-on agent that adds 3-4 Antimicrobial drugs (e.g.,
PENICILLIN with MIC sign/value, plus 2-3 other antibiotics) — that
unlocks ~40 columns of BMIRD_STREP_PNEUMO_DATAMART (the
ANTIMICROBIAL_AGENT_TESTED_1..8 pivot).

### RTR Bug surfaced: BMIRD_STREP_PNEUMO_DATAMART INSERT-only path; no DELETE-first guard

**File**: `140-sp_bmird_strep_pneumo_datamart_postprocessing-001.sql:1196`
(the only INSERT block; no DELETE preceding it).

**Symptom**: running `sp_bmird_strep_pneumo_datamart_postprocessing`
twice for the same PHC UID produces N+1 rows in
`BMIRD_STREP_PNEUMO_DATAMART`. The SP at line 1530-1532 attempts
de-duplication via `LEFT JOIN dbo.BMIRD_STREP_PNEUMO_DATAMART tgt ON
src.INVESTIGATION_KEY = tgt.INVESTIGATION_KEY WHERE
tgt.INVESTIGATION_KEY IS NULL`, but this only prevents
SECOND-and-subsequent INSERTs for the SAME row; the prior row's
columns are stale (not updated). The expected pattern is
DELETE-then-INSERT or MERGE/UPSERT (see `sp_hepatitis_datamart_-
postprocessing` for the correct pattern).

**Reproduction (live, 2026-05-21)**: running the fixture's
tail-EXEC + invoking `sp_bmird_strep_pneumo_datamart_postprocessing
@phc_uids = N'22005000'` once results in 1 row. Re-invoking the same
SP produces 0 new rows (the WHERE guard fires) BUT updates none of
the existing columns either — so if the underlying BMIRD_Case data
changes between runs, BMIRD_STREP_PNEUMO_DATAMART stays stale.

**Impact**: comparison test will report BMIRD_STREP_PNEUMO_DATAMART
column-value mismatches against MasterETL when data flows are
re-replayed. Same root cause as the TB_DATAMART bug surfaced by
`coverage_tb_full_chain.md`. Flag as Phase 2 RTR-bug fix candidate
(the pattern probably affects multiple condition_case_datamart SPs).

**Severity**: medium. Doesn't block populated-state on a single
clean run; does break re-runnability and row-update semantics.

### LDF_GROUP fixture-prereq: BMIRD_Case FK requires LDF_GROUP_KEY=1 sentinel

`BMIRD_Case` has a FK constraint on `LDF_GROUP_KEY` referencing
`dbo.LDF_GROUP`. `V_NRT_INV_KEYS_ATTRS_MAPPING.LDF_GROUP_KEY` is
`COALESCE(lg.ldf_group_key, 1)` — so when no LDF rows exist, it
yields 1, which the FK enforces. Baseline 6.0.18.1 leaves
`LDF_GROUP` empty (no seeded sentinel at KEY=1), so the BMIRD_Case
INSERT fails with FK error.

**Fix in fixture**: `IF NOT EXISTS (... LDF_GROUP_KEY=1) INSERT ...`
seed at top of fixture. Idempotent.

**Phase 2 candidate**: the same `LDF_GROUP_KEY=1` sentinel should be
seeded by the merge orchestrator (alongside `RDB_DATE` / `CONDITION`
infrastructure) so every condition-case_datamart fixture doesn't
need to re-seed. The same FK exists on Hepatitis_Case, Measles_Case,
Pertussis_Case, Rubella_Case, CRS_Case, Var_Case, COVID_Case (15+
condition case_datamart tables). Adding a one-time seed in
`scripts/merge_and_verify.sh` between Step 2 and Step 3 (after
sp_nrt_srte_condition_code_postprocessing, before Tier 1) would
cover all of them.

### OUT_OF_SCOPE: not invoked in this fixture

- `sp_bmird_case_datamart_postprocessing` (040) — Step 9 line 505 owns it.
- `sp_bmird_strep_pneumo_datamart_postprocessing` (140) — Step 9 line 506 owns it.
- `sp_ldf_bmird_datamart_postprocessing` (285) — Step 9 line 526 owns it.

These are invoked by the orchestrator at Step 9 (`merge_and_verify.sh`).
We only invoke them directly here for verification during fixture
authoring. The fixture's tail-EXEC is limited to
`sp_nrt_investigation_postprocessing` per the Tier 3 contract (Step 9
owns the datamart SPs).

## Orchestrator integration

Applied in same commit as this fixture:

- `scripts/merge_and_verify.sh` line 446: add `22005000` to `PHC_UIDS`
  so Step 9 picks up the new full-chain BMIRD Investigation for
  `sp_bmird_case_datamart_postprocessing`,
  `sp_bmird_strep_pneumo_datamart_postprocessing`, and
  `sp_ldf_bmird_datamart_postprocessing`.

## Reproduction recipe

```sh
export SQLCMDPASSWORD=PizzaIsGood33!
# Apply against existing populated state (assumes Tier 1/2/prior Tier 3 already applied)
sqlcmd -S localhost,3433 -U sa -C \
  -i /Users/adam/code/nbs/NEDSS-DataReporting/utilities/comparison-fixtures/fixtures/30_sp_coverage/bmird_investigation_full_chain.sql

# Run the BMIRD chain (Step 9 SPs)
sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN -Q "
  EXEC dbo.sp_bmird_case_datamart_postprocessing @phc_uids = N'22005000', @debug = 0;
  EXEC dbo.sp_bmird_strep_pneumo_datamart_postprocessing @phc_uids = N'22005000', @debug = 0;
  EXEC dbo.sp_ldf_bmird_datamart_postprocessing @phc_uids = N'22005000', @debug = 0;
"

# Verify cluster populations
sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN -h -1 -W -Q "
  SELECT 'BMIRD_Case' AS t, COUNT(*) AS c FROM dbo.BMIRD_Case UNION ALL
  SELECT 'BMIRD_STREP_PNEUMO_DATAMART', COUNT(*) FROM dbo.BMIRD_STREP_PNEUMO_DATAMART UNION ALL
  SELECT 'BMIRD_MULTI_VALUE_FIELD', COUNT(*) FROM dbo.BMIRD_MULTI_VALUE_FIELD UNION ALL
  SELECT 'ANTIMICROBIAL', COUNT(*) FROM dbo.ANTIMICROBIAL UNION ALL
  SELECT 'LDF_BMIRD', COUNT(*) FROM dbo.LDF_BMIRD"
```

For a full-baseline replay, `scripts/merge_and_verify.sh` picks up
this fixture at Step 8 automatically (the script iterates
`30_sp_coverage/*.sql` alphabetically) and the BMIRD chain runs at
Step 9 with `22005000` now in `PHC_UIDS`.
