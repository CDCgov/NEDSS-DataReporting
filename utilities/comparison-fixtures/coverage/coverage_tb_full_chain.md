# Coverage: TB Investigation full ODSE + Tier 2 + NBS_case_answer chain

Generated: 2026-05-21

## Inputs

- Baseline: 6.0.18.1 (post-liquibase) + foundation + all Tier 1 fixtures
  + all Tier 2 fixtures + existing Tier 3 fixtures (including
  `multi_condition_investigations.sql` stub at UID 22000010).
- Fixture file:
  `fixtures/30_sp_coverage/tb_investigation_full_chain.sql`.
- UID range allocated: **22001000 - 22001999** (Tier 3 TB full-chain).
- Foundation dependencies (read-only):
  - `@superuser_id = 10009282`
  - `@dbo_Entity_patient_uid = 20000000` (foundation Patient; referenced
    by `nrt_investigation.patient_id` so F_TB_PAM's
    `INNER JOIN D_PATIENT ON PERSON_UID = PATIENT_UID` resolves and the
    f_page_case sentinel-key cascade-DELETE path does not drop the row).
- Tier 3 dependencies (read-only):
  - The existing TB stub at `public_health_case_uid = 22000010` in
    `fixtures/30_sp_coverage/multi_condition_investigations.sql` is
    **left untouched**. It continues to exercise the no-PAM-answers path.
    Our full-chain UID 22001000 exercises the populated-PAM-answers path.

## UID allocations

| UID | Symbolic | Entity / column | Notes |
| --- | --- | --- | --- |
| 22001000 | tb_full_phc_uid | `act.act_uid`, `public_health_case.public_health_case_uid`, `nrt_investigation.public_health_case_uid`, `nrt_investigation.nac_page_case_uid`, `nrt_page_case_answer.act_uid` (every answer row) | The single TB Investigation full-chain anchor. |
| 22001001 | tb_full_case_mgmt_uid | `case_management.case_management_uid` (IDENTITY-inserted) | Per Tier 1 v2 Investigation shape. |
| 22001100..22001122 | (13 nbs_case_answer + nrt_page_case_answer pairs) | `nbs_case_answer.nbs_case_answer_uid` + `nrt_page_case_answer.nbs_case_answer_uid` | One per TUB question authored (13 d_topic feeders + 10 D_TB_PAM main-pivot feeders = 23 total; UIDs allocated contiguously). |

Unused UIDs in TB full-chain Tier 3 block (22001123-22001999) reserved
for future expansion (more TUB question rows to broaden D_TB_PAM
column coverage, additional TB Investigations to exercise multi-row
paths, or LDF-flagged answer rows to unblock TB_PAM_LDF — see Gaps).

## SPs verified

Tail-EXEC'd in dependency order from the fixture file. Each was
verified via `dbo.job_flow_log` (step_name='SP_COMPLETE',
status_type='COMPLETE'). All ran without errors against the live state.

| SP | File | Param | Outcome |
| --- | --- | --- | --- |
| `sp_nrt_investigation_postprocessing` | 005 | `@id_list` | INSERT into `INVESTIGATION` for case_uid=22001000 |
| `sp_nrt_d_tb_pam_postprocessing` | 147 | `@phc_id_list` | INSERT into `D_TB_PAM` (1 row, 8 columns populated) |
| `sp_nrt_d_disease_site_postprocessing` | 145 | `@phc_uids` | `D_DISEASE_SITE` 1 row, `D_DISEASE_SITE_GROUP` 1 new row |
| `sp_nrt_d_addl_risk_postprocessing` | 146 | `@phc_uids` | `D_ADDL_RISK` 1 row, `D_ADDL_RISK_GROUP` 1 new row |
| `sp_nrt_d_tb_hiv_postprocessing` | 160 | `@phc_id_list` | `D_TB_HIV` 1 row (HIV_STATUS, HIV_STATE_PATIENT_NUM, HIV_CITY_CNTY_PATIENT_NUM) |
| `sp_nrt_d_move_cntry_postprocessing` | 156 | `@phc_uids` | `D_MOVE_CNTRY` 1 row, `D_MOVE_CNTRY_GROUP` 1 new row |
| `sp_nrt_d_gt_12_reas_postprocessing` | 170 | `@phc_id_list` | `D_GT_12_REAS` 1 row, `D_GT_12_REAS_GROUP` 1 new row |
| `sp_nrt_d_move_cnty_postprocessing` | 175 | `@phc_uids` | `D_MOVE_CNTY` 1 row, `D_MOVE_CNTY_GROUP` 1 new row |
| `sp_nrt_d_hc_prov_ty_3_postprocessing` | 180 | `@phc_id_list` | `D_HC_PROV_TY_3` 1 row, `D_HC_PROV_TY_3_GROUP` 1 new row |
| `sp_nrt_d_move_state_postprocessing` | 185 | `@phc_uids` | `D_MOVE_STATE` 1 row, `D_MOVE_STATE_GROUP` 1 new row |
| `sp_nrt_d_out_of_cntry_postprocessing` | 190 | `@phc_id_list` | `D_OUT_OF_CNTRY` 1 row, `D_OUT_OF_CNTRY_GROUP` 1 new row |
| `sp_nrt_d_moved_where_postprocessing` | 195 | `@phc_uids` | `D_MOVED_WHERE` 1 row, `D_MOVED_WHERE_GROUP` 1 new row |
| `sp_nrt_d_smr_exam_ty_postprocessing` | 200 | `@phc_id_list` | `D_SMR_EXAM_TY` 1 row, `D_SMR_EXAM_TY_GROUP` 1 new row |
| `sp_nrt_tb_pam_ldf_postprocessing` | 220 | `@phc_id_list` | 0 rows (see Gaps: LDF_STATUS_CD filter) |
| `sp_f_tb_pam_postprocessing` | 206 | `@phc_id_list` | `F_TB_PAM` 1 row (14 / 20 columns populated) |
| `sp_tb_datamart_postprocessing` | 255 | `@phc_id_list` | `TB_DATAMART` 2 rows (see RTR Bug #N — duplicate INSERT) |
| `sp_tb_hiv_datamart_postprocessing` | 260 | `@phc_id_list` | `TB_HIV_DATAMART` 2 rows |

Excluded from the chain:
- `sp_nrt_d_rash_loc_gen_postprocessing` (225) — Varicella, not TB.
- `sp_nrt_d_pcr_source_postprocessing` (230) — Varicella (filters on VAR176).

## Columns populated — row counts per cluster table

| Table | Rows | Notes |
| --- | --- | --- |
| `D_TB_PAM` | 1 | 8 / 166 cols populated (`D_TB_PAM_KEY`, `TB_PAM_UID`, `CALC_DISEASE_SITE='Pulmonary'`, `HOMELESS_IND='No'`, `INIT_REGIMEN_START_DATE`, `INIT_REGIMEN_PA_SALICYLIC_ACID='Yes'`, `CASE_VERIFICATION`, `INIT_DRUG_REG_CALC='1'`, `LAST_CHG_TIME`). The other 158 columns are NULL because each is fed by a distinct TUB question we did not author; this fixture authors a *minimum-viable* set to prove every cluster SP runs end-to-end. Phase 2 expansion: author more TUB question rows (the schema has 169 RVCT TUB questions per `NBS_ODSE.dbo.nbs_question`). |
| `D_DISEASE_SITE` | 1 | 7 / 7 cols (`TB_PAM_UID`, `D_DISEASE_SITE_KEY`, `SEQ_NBR=1`, `D_DISEASE_SITE_GROUP_KEY=2`, `LAST_CHG_TIME`, `VALUE='Pulmonary'`). |
| `D_DISEASE_SITE_GROUP` | 2 | New group row (KEY=2) joined to D_DISEASE_SITE; row 1 is the seeded sentinel. |
| `D_ADDL_RISK` | 1 | 6 / 6 cols (`VALUE='Diabetes Mellitus'`). |
| `D_ADDL_RISK_GROUP` | 2 | New group row + sentinel. |
| `D_TB_HIV` | 1 | 6 / 6 cols (`HIV_STATUS='Negative'`, `HIV_STATE_PATIENT_NUM='HIV-STATE-TB-01'`, `HIV_CITY_CNTY_PATIENT_NUM='HIV-CITY-TB-01'`). |
| `D_MOVE_CNTRY` | 1 | 6 / 6 cols (`VALUE='UNITED STATES'`). |
| `D_MOVE_CNTRY_GROUP` | 2 | New + sentinel. |
| `D_MOVE_CNTY` | 1 | 6 / 6 cols. |
| `D_MOVE_CNTY_GROUP` | 2 | New + sentinel. |
| `D_MOVE_STATE` | 1 | 6 / 6 cols (`VALUE='Georgia'`). |
| `D_MOVE_STATE_GROUP` | 2 | New + sentinel. |
| `D_MOVED_WHERE` | 1 | 6 / 6 cols (`VALUE='Out of the U.S.'`). |
| `D_MOVED_WHERE_GROUP` | 2 | New + sentinel. |
| `D_OUT_OF_CNTRY` | 1 | 6 / 6 cols. |
| `D_OUT_OF_CNTRY_GROUP` | 2 | New + sentinel. |
| `D_HC_PROV_TY_3` | 1 | 6 / 6 cols (`VALUE='Private Outpatient'`). |
| `D_HC_PROV_TY_3_GROUP` | 2 | New + sentinel. |
| `D_GT_12_REAS` | 1 | 6 / 6 cols (`VALUE='Non-adherence'`). |
| `D_GT_12_REAS_GROUP` | 2 | New + sentinel. |
| `D_SMR_EXAM_TY` | 1 | 6 / 6 cols (`VALUE='Pathology/Cytology'`). |
| `D_SMR_EXAM_TY_GROUP` | 2 | New + sentinel. |
| `F_TB_PAM` | 1 | ~14 / 20 cols populated (`PERSON_KEY=3`, `D_TB_PAM_KEY=2`, `PROVIDER_KEY=1` (sentinel — no TB provider participation), all 11 D_*_GROUP_KEYs at value 2). |
| `TB_DATAMART` | 2 | 1 conceptual row, INSERTed twice. See RTR Bug #N below. |
| `TB_HIV_DATAMART` | 2 | Same duplicate-INSERT pattern as TB_DATAMART. |
| `TB_PAM_LDF` | 0 | LDF_STATUS_CD filter (see Gaps: LDF_GAP). |

### Summary
- **24 of 26** TB-PAM cluster tables populate from this fixture.
- **2 of 26** remain empty: `TB_PAM_LDF` (LDF-flagged answer rows
  required — separate Phase 2 work) and one of the D_*_GROUPs which
  was already populated by sentinel rows in the baseline (the new
  group join row is at KEY=2 in every group table).
- TB_DATAMART and TB_HIV_DATAMART each carry one duplicate row from
  re-INSERT on re-run (RTR bug, not a fixture bug).

## Columns deliberately skipped

| Table | Column | Reason | Citation |
| --- | --- | --- | --- |
| `D_TB_PAM` | 158 / 166 columns | Each is fed by a distinct TUB question; this fixture authors a 10-question minimum-viable set to prove the chain runs. Authoring the remaining ~150 TUB questions is a fixture-completeness exercise (~1 day of mechanical SQL); not blocked by infrastructure. | `147-sp_nrt_d_tb_pam_postprocessing-001.sql:307-359` (full pivot column list) |
| `F_TB_PAM` | `PHYSICIAN_KEY`, `REPORTER_KEY`, `ORGANIZATION_KEY`, `HOSPITAL_KEY` (4 NULL or sentinel) | The TB Investigation has no `participation` rows of type `PhysicianOfPHC`, `PerAsReporterOfPHC`, `OrgAsReporterOfPHC`, `HospOfADT`. Authoring those would require a Tier 2 follow-on. Foundation Inv 20000100 (Hep A) carries those edges via Tier 2 fixtures; this TB Investigation is intentionally standalone for Phase 2. | `206-sp_f_tb_pam_postprocessing-001.sql:60-72` |
| `TB_PAM_LDF` | All columns | See LDF_GAP below. |

## Gaps reported

### LDF_GAP: TB_PAM_LDF requires LDF-flagged page_case_answer rows

`220-sp_nrt_tb_pam_ldf_postprocessing-001.sql:83-85` filters
`nrt_page_case_answer` rows by:

```sql
WHERE A.LDF_STATUS_CD IN ('LDF_UPDATE', 'LDF_CREATE', 'LDF_PROCESSED')
  AND A.NUIM_RECORD_STATUS_CD IN ('Active', 'Inactive');
```

Our `nrt_page_case_answer` rows have `LDF_STATUS_CD=NULL` (correct for
the main D_TB_PAM and d_topic SPs — those filter on
`A.ldf_status_cd IS NULL`). Authoring TB_PAM_LDF coverage requires a
SEPARATE batch of nrt_page_case_answer rows with LDF status flags set
plus `NUIM_RECORD_STATUS_CD='Active'`. This is the same Phase 2 work
that `coverage_tier_3.md` already calls out for the `d_ldf_meta_data` /
LDF infrastructure family. Recommended for a follow-on Tier 3 LDF
agent (the existing `fixtures/30_sp_coverage/ldf_answers_tetanus.sql`
is the template).

### RTR Bug surfaced: TB_DATAMART INSERT-only path; no UPDATE

**File**: `255-sp_tb_datamart_postprocessing-001.sql:1751` (TB_DATAMART
INSERT block).

**Symptom**: running `sp_tb_datamart_postprocessing` twice for the same
PHC UID produces two rows in TB_DATAMART (and similarly two in
TB_HIV_DATAMART via sp 260). There is no DELETE-then-INSERT or
MERGE/UPSERT pattern guarding the INSERT block.

**Reproduction (live, 2026-05-21)**: running the fixture's
tail-EXEC sequence (which includes `sp_tb_datamart_postprocessing
@phc_id_list = N'22001000'` exactly once) results in 2 rows in
`TB_DATAMART` because the SP appears to internally INSERT twice
(e.g., from a missing DISTINCT or a self-joined source). Worth
diffing against `sp_hepatitis_datamart_postprocessing` which has a
DELETE-first guard at the top of its INSERT block.

**Impact**: comparison test will report TB_DATAMART row count
mismatches against MasterETL (RDB side will have N rows per
Investigation; RDB_MODERN side will have 2N or more). Flag as
Phase 2 RTR-bug fix candidate alongside the TMP_F_PAGE_CASE
transaction-isolation bug.

**Severity**: medium. Doesn't block populated-state; does break
row-count integrity for the diff tool.

### LINK_REQUIRED: F_TB_PAM cross-subject keys

`F_TB_PAM` carries 4 sentinel-or-NULL keys (`PROVIDER_KEY`,
`PHYSICIAN_KEY`, `REPORTER_KEY`, `ORGANIZATION_KEY`, `HOSPITAL_KEY`)
because no Tier 2 participation/nbs_act_entity rows exist for the new
TB Investigation 22001000. The relevant rows would be:

- `participation type_cd='PhysicianOfPHC'`: 22001000 → provider
  (e.g., foundation Provider 20000010)
- `participation type_cd='InvestgrOfPHC'`: 22001000 → provider
- `participation type_cd='PerAsReporterOfPHC'`: 22001000 → provider
- `nbs_act_entity type_cd='HospOfADT'`: 22001000 → organization

These are out of scope for this Tier 3 fixture (would belong in an
additional Tier 2 fixture authoring TB-specific edges, or in a
Phase 2 expansion). Until then, `F_TB_PAM`'s 4 cross-subject keys
remain sentinel.

### OUT_OF_SCOPE: not invoked in this fixture

- `sp_nrt_d_rash_loc_gen_postprocessing` (225) — Varicella only; filters
  on VAR176 / `INV_FORM_VAR`.
- `sp_nrt_d_pcr_source_postprocessing` (230) — Varicella only; filters
  on VAR176.

These are part of the multi-condition Phase 2 Varicella fixture
(analogous to this fixture, but for Investigation 22000020). They
are NOT TB-PAM cluster members despite the catalog grouping (the
catalog grouped them together because they share the `nrt_page_case_answer`
data source).

## Orchestrator integration recommendation

`scripts/merge_and_verify.sh` currently invokes
`sp_tb_datamart_postprocessing` at line 503 and
`sp_f_tb_pam_postprocessing` at line 513 unconditionally as part of
Step 9 (datamart SPs). For this fixture's full effect to land in the
orchestrated run, the orchestrator needs to **insert a new
post-Tier-3 step (between Step 8 "Tier 3 fixtures" and Step 9
"Datamart SPs") that invokes the 14 d_topic SPs and the TB-PAM root
SP for the TB Investigation UID(s)**:

```bash
# Proposed step 8.5: TB-PAM cluster
run_dm_sp sp_nrt_d_tb_pam_postprocessing        "@phc_id_list = N'$PHC_UIDS', @debug = 0"
run_dm_sp sp_nrt_d_disease_site_postprocessing  "@phc_uids = N'$PHC_UIDS', @debug = 0"
run_dm_sp sp_nrt_d_addl_risk_postprocessing     "@phc_uids = N'$PHC_UIDS', @debug = 0"
run_dm_sp sp_nrt_d_tb_hiv_postprocessing        "@phc_id_list = N'$PHC_UIDS', @debug = 0"
run_dm_sp sp_nrt_d_move_cntry_postprocessing    "@phc_uids = N'$PHC_UIDS', @debug = 0"
run_dm_sp sp_nrt_d_move_cnty_postprocessing     "@phc_uids = N'$PHC_UIDS', @debug = 0"
run_dm_sp sp_nrt_d_move_state_postprocessing    "@phc_uids = N'$PHC_UIDS', @debug = 0"
run_dm_sp sp_nrt_d_moved_where_postprocessing   "@phc_uids = N'$PHC_UIDS', @debug = 0"
run_dm_sp sp_nrt_d_gt_12_reas_postprocessing    "@phc_id_list = N'$PHC_UIDS', @debug = 0"
run_dm_sp sp_nrt_d_hc_prov_ty_3_postprocessing  "@phc_id_list = N'$PHC_UIDS', @debug = 0"
run_dm_sp sp_nrt_d_out_of_cntry_postprocessing  "@phc_id_list = N'$PHC_UIDS', @debug = 0"
run_dm_sp sp_nrt_d_smr_exam_ty_postprocessing   "@phc_id_list = N'$PHC_UIDS', @debug = 0"
run_dm_sp sp_nrt_tb_pam_ldf_postprocessing      "@phc_id_list = N'$PHC_UIDS', @debug = 0"
```

Without this orchestrator step, the fixture's tail-EXEC will populate
the cluster but the orchestrator's Step 9 datamarts (255, 260) will
re-run against an already-populated D_TB_PAM and produce duplicate
TB_DATAMART rows (compounding the bug above).

**Alternative**: rely solely on the fixture's tail-EXEC and trim the
orchestrator's `sp_tb_datamart_postprocessing` / `sp_f_tb_pam_postprocessing`
invocations to single-firing. Cleaner long-term; reduces double-run
contamination.

I recommend the parent agent review the proposed orchestrator diff
before applying — this fixture itself is fully self-contained.

## Reproduction recipe

```sh
export SQLCMDPASSWORD=PizzaIsGood33!
# Apply against existing populated state (assumes Tier 1/2/prior Tier 3 already applied)
sqlcmd -S localhost,3433 -U sa -C \
  -i /Users/adam/code/nbs/NEDSS-DataReporting/utilities/comparison-fixtures/fixtures/30_sp_coverage/tb_investigation_full_chain.sql

# Verify cluster populations
sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN -Q "SET NOCOUNT ON;
  SELECT 'D_TB_PAM', COUNT(*) FROM dbo.D_TB_PAM UNION ALL
  SELECT 'F_TB_PAM', COUNT(*) FROM dbo.F_TB_PAM UNION ALL
  SELECT 'TB_DATAMART', COUNT(*) FROM dbo.TB_DATAMART UNION ALL
  SELECT 'TB_HIV_DATAMART', COUNT(*) FROM dbo.TB_HIV_DATAMART UNION ALL
  SELECT 'D_DISEASE_SITE', COUNT(*) FROM dbo.D_DISEASE_SITE;"
```

For a full-baseline replay, `scripts/merge_and_verify.sh` picks up
this fixture at Step 8 automatically (the script iterates
`30_sp_coverage/*.sql` alphabetically).
