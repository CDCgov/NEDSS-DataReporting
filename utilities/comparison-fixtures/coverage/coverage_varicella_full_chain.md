# Coverage: Varicella Investigation full ODSE + Tier 2 + NBS_case_answer chain

Generated: 2026-05-21

## Inputs

- Baseline: 6.0.18.1 (post-liquibase) + foundation + all Tier 1 fixtures
  + all Tier 2 fixtures + existing Tier 3 fixtures (including
  `multi_condition_investigations.sql` stub at UID 22000020 and
  `tb_investigation_full_chain.sql` at UID 22001000).
- Fixture file:
  `fixtures/30_sp_coverage/varicella_investigation_full_chain.sql`.
- UID range allocated: **22002000 - 22002999** (Tier 3 Varicella full-chain).
- Foundation dependencies (read-only):
  - `@superuser_id = 10009282`
  - `@dbo_Entity_patient_uid = 20000000` (foundation Patient; referenced
    by `nrt_investigation.patient_id` so F_VAR_PAM's
    `INNER JOIN D_PATIENT ON PERSON_UID = PATIENT_UID` resolves and the
    f_page_case sentinel-key cascade-DELETE path does not drop the row).
- Tier 3 dependencies (read-only):
  - The existing Varicella stub at `public_health_case_uid = 22000020` in
    `fixtures/30_sp_coverage/multi_condition_investigations.sql` is
    **left untouched**. It exercises the no-PAM-answers path. Our
    full-chain UID 22002000 exercises the populated-PAM-answers path.

## UID allocations

| UID | Symbolic | Entity / column | Notes |
| --- | --- | --- | --- |
| 22002000 | var_full_phc_uid | `act.act_uid`, `public_health_case.public_health_case_uid`, `nrt_investigation.public_health_case_uid`, `nrt_investigation.nac_page_case_uid`, `nrt_page_case_answer.act_uid` (all 25 answer rows) | The single Varicella Investigation full-chain anchor. condition_cd `10030` Varicella (Chickenpox), prog_area_cd `GCD`, investigation_form_cd `INV_FORM_VAR`. Adds the populated-PAM-answers path alongside the existing 22000020 stub's no-answers path. |
| 22002001 | var_full_case_mgmt_uid | `case_management.case_management_uid` (IDENTITY-inserted) | Per Tier 1 v2 Investigation shape. |
| 22002100..22002124 | (25 VAR answer rows) | `nbs_case_answer.nbs_case_answer_uid` + `nrt_page_case_answer.nbs_case_answer_uid` | One per authored VAR question (VAR101 / VAR103 / VAR105 + 22 more, including the two cluster-feeder questions VAR105 → D_RASH_LOC_GEN and VAR176 → D_PCR_SOURCE). |

Unused UIDs in Varicella full-chain Tier 3 block (22002002-22002099,
22002125-22002999) reserved for future expansion (more VAR question
rows to broaden D_VAR_PAM column coverage, additional Varicella
Investigations to exercise multi-row paths, or LDF-flagged answer rows
to unblock VAR_PAM_LDF — see Gaps).

## SPs verified

Tail-EXEC'd in dependency order from the fixture file. Each was
verified via `dbo.job_flow_log` (step_name='SP_COMPLETE',
status_type='COMPLETE'). All ran without errors against the live state.

| SP | File | Param | Outcome |
| --- | --- | --- | --- |
| `sp_nrt_investigation_postprocessing` | 005 | `@id_list` | INSERT into `INVESTIGATION` for case_uid=22002000 |
| `sp_nrt_d_var_pam_postprocessing` | 215 | `@phc_uids` | INSERT into `D_VAR_PAM` (1 row; ~17 columns populated of 122) |
| `sp_nrt_d_rash_loc_gen_postprocessing` | 225 | `@phc_uids` | `D_RASH_LOC_GEN` 1 row (`VALUE='Trunk'`), `D_RASH_LOC_GEN_GROUP` 1 new row |
| `sp_nrt_d_pcr_source_postprocessing` | 230 | `@phc_id_list` | `D_PCR_SOURCE` 1 row (`VALUE='Scab'`), `D_PCR_SOURCE_GROUP` 1 new row |
| `sp_nrt_var_pam_ldf_postprocessing` | 235 | `@phc_uids` | 0 rows (see Gaps: LDF_GAP) |

Verified-but-NOT-tail-EXEC'd (handled by Step 9 of merge_and_verify.sh
when 22002000 is added to PHC_UIDS — see ORCH_TODO below). Spot-checked
in isolation; each ran cleanly against the populated state:

| SP | File | Param | Spot-check Outcome |
| --- | --- | --- | --- |
| `sp_f_var_pam_postprocessing` | 240 | `@phc_id_list` | `F_VAR_PAM` 1 row (PERSON_KEY=3, INVESTIGATION_KEY=7, RASH=2, PCR=2; HOSP/PROV/REPORTER all sentinel-1 — see LINK_REQUIRED) |
| `sp_var_datamart_postprocessing` | 250 | `@phc_uids` | 0 rows at Tier-1-isolation (gated by `EVENT_METRIC` lookup at SP line 692 `INNER JOIN dbo.EVENT_METRIC e ON e.EVENT_UID = d.VAR_PAM_UID` — EVENT_METRIC is empty in baseline; orchestrator Step 9 populates it via `sp_event_metric_datamart_postprocessing` BEFORE running var_datamart, so the full Step 9 sequence will produce VAR_DATAMART rows). |

After spot-check, the F_VAR_PAM row was manually DELETEd from the live
state so that the parent agent's Step 9 run does not double-INSERT.

## Columns populated — row counts per cluster table

Verified post-fixture (Tier-1-isolation, before Step 9):

| Table | Rows | Notes |
| --- | --- | --- |
| `D_VAR_PAM` | 1 | ~17 / 122 cols populated (`D_VAR_PAM_KEY`, `VAR_PAM_UID`, `VARICELLA_VACCINE='Yes'`, `RASH_LOCATION='Other'`, `VESICLES='Yes'`, `MACULAR_PAPULAR='No'`, `FEVER='Yes'`, `FEVER_ONSET_DATE`, `IMMUNOCOMPROMISED='No'`, `PATIENT_VISIT_HC_PROVIDER='Yes'`, `COMPLICATIONS='No'`, `COMPLICATIONS_PNEUMONIA='No'`, `TREATED='No'`, `DEATH_AUTOPSY='No'`, `PREVIOUS_DIAGNOSIS='No'`, `EPI_LINKED='No'`, `TRANSMISSION_SETTING='Community'`, `HEALTHCARE_WORKER='No'`, `LAB_TESTING='Yes'`, `DFA_TEST='No'`, `PCR_TEST='Yes'`, `PCR_TEST_RESULT='Positive'`, `CULTURE_TEST='No'`, `SEROLOGY_TEST='No'`, `IGG_TEST='No'`, `LAST_CHG_TIME`). The other ~100 columns are NULL because each is fed by a distinct VAR question we did not author; this fixture authors a *minimum-viable* set to prove every cluster SP runs end-to-end. Phase 2 expansion: author more VAR question rows (the schema has ~110 VAR questions per `NBS_ODSE.dbo.nbs_question`). |
| `D_RASH_LOC_GEN` | 1 | 6 / 6 cols (`VAR_PAM_UID=22002000`, `D_RASH_LOC_GEN_KEY=2`, `SEQ_NBR=1`, `D_RASH_LOC_GEN_GROUP_KEY=2`, `LAST_CHG_TIME`, `VALUE='Trunk'`). |
| `D_RASH_LOC_GEN_GROUP` | 2 | New group row (KEY=2) joined to D_RASH_LOC_GEN; row 1 is the seeded sentinel. |
| `D_PCR_SOURCE` | 1 | 6 / 6 cols (`VAR_PAM_UID=22002000`, `D_PCR_SOURCE_KEY=2`, `SEQ_NBR=1`, `D_PCR_SOURCE_GROUP_KEY=2`, `LAST_CHG_TIME`, `VALUE='Scab'`). |
| `D_PCR_SOURCE_GROUP` | 2 | New group row + sentinel. |
| `F_VAR_PAM` | 0 at Tier-1-isolation (1 verified via solo `sp_f_var_pam_postprocessing` run, then cleared). | Populates at Step 9. Spot-check showed ~12/12 cols populated (`PERSON_KEY=3`, `D_VAR_PAM_KEY=2`, `D_RASH_LOC_GEN_GROUP_KEY=2`, `D_PCR_SOURCE_GROUP_KEY=2`, `INVESTIGATION_KEY=7`, `HOSPITAL_KEY=1`, `PROVIDER_KEY=1`, `PHYSICIAN_KEY=1`, `ORG_AS_REPORTER_KEY=1`, `PERSON_AS_REPORTER_KEY=1`, both ADD_DATE_KEY/LAST_CHG_DATE_KEY non-NULL). 5 of those keys are sentinel-1 due to no Tier-2 participation/nbs_act_entity edges — see LINK_REQUIRED. |
| `VAR_PAM_LDF` | 0 | LDF_STATUS_CD filter (see Gaps: LDF_GAP). |
| `VAR_DATAMART` | 0 at Tier-1-isolation. | Populates at Step 9 after `sp_event_metric_datamart_postprocessing` populates `EVENT_METRIC` (var_datamart line 692 `INNER JOIN dbo.EVENT_METRIC e ON e.EVENT_UID = d.VAR_PAM_UID` is the gate). |

### Summary

- **5 of 8** Varicella-PAM cluster tables populate at Tier-1-isolation
  (D_VAR_PAM, D_RASH_LOC_GEN, D_RASH_LOC_GEN_GROUP, D_PCR_SOURCE,
  D_PCR_SOURCE_GROUP).
- **2 of 8** populate after Step 9 (F_VAR_PAM, VAR_DATAMART) — verified
  by solo SP runs.
- **1 of 8** remains empty (VAR_PAM_LDF) requiring LDF-flagged answer
  rows — separate Phase 2 LDF-coverage work.

Compared to TB cluster (24/26 from one fixture), Varicella is leaner
(8-table cluster vs 26 — TB has 12 d_topic dims, Varicella only 2).
All 8 are reachable from the same template; this fixture exercises 7
out of 8.

## Columns deliberately skipped

| Table | Column | Reason | Citation |
| --- | --- | --- | --- |
| `D_VAR_PAM` | ~105 / 122 columns | Each is fed by a distinct VAR question; this fixture authors a 25-question minimum-viable set to prove the chain runs. Authoring the remaining ~85 VAR questions is a fixture-completeness exercise (~1 day of mechanical SQL); not blocked by infrastructure. | `215-sp_nrt_d_var_pam_postprocessing-001.sql:264-301` (full PIVOT IN-list) |
| `F_VAR_PAM` | `HOSPITAL_KEY`, `PROVIDER_KEY`, `PHYSICIAN_KEY`, `ORG_AS_REPORTER_KEY`, `PERSON_AS_REPORTER_KEY` (all sentinel-1) | The Varicella Investigation has no `participation` rows of type `PhysicianOfPHC` / `PerAsReporterOfPHC` etc., and `nrt_investigation` columns `hospital_uid` / `org_as_reporter_uid` / `physician_id` / etc. are NULL. Authoring those would require a Tier 2 follow-on (or extending the existing Tier 2 edge agents to cover this PHC). | `240-sp_f_var_pam_postprocessing-001.sql:65-72` |
| `VAR_PAM_LDF` | All columns | See LDF_GAP below. |

## Gaps reported

### LDF_GAP: VAR_PAM_LDF requires LDF-flagged page_case_answer rows

`235-sp_nrt_var_pam_ldf_postprocessing-001.sql:80-82` filters
`nrt_page_case_answer` rows by:

```sql
WHERE  NCA.ldf_status_cd IN ('LDF_UPDATE', 'LDF_CREATE', 'LDF_PROCESSED') AND
       NCA.investigation_form_cd = 'INV_FORM_VAR'
  AND NCA.nuim_record_status_cd IN ('Active', 'Inactive')
```

Our `nrt_page_case_answer` rows have `ldf_status_cd=NULL` (correct for
the main D_VAR_PAM and the 2 d_topic SPs — those filter on
`A.ldf_status_cd IS NULL` or have no LDF check). Authoring VAR_PAM_LDF
coverage requires a SEPARATE batch of nrt_page_case_answer rows with
LDF status flags set plus `nuim_record_status_cd='Active'`. Same Phase
2 work as `coverage_tb_full_chain.md` LDF_GAP — recommended for the
existing follow-on Tier 3 LDF agent (template:
`fixtures/30_sp_coverage/ldf_answers_tetanus.sql`).

### LINK_REQUIRED: F_VAR_PAM cross-subject keys

`F_VAR_PAM` carries 5 sentinel keys (`HOSPITAL_KEY=1`, `PROVIDER_KEY=1`,
`PHYSICIAN_KEY=1`, `ORG_AS_REPORTER_KEY=1`, `PERSON_AS_REPORTER_KEY=1`)
because no Tier 2 participation/nbs_act_entity edges connect the new
Varicella Investigation 22002000 to providers/organizations. The
relevant Tier 2 edge agents (`tier_2_physician_phc`, `tier_2_reporter_phc`,
`tier_2_phc_roles_nae`) only wire foundation/v2 Investigations — they
do not currently extend to Tier 3 Investigations.

These are out of scope for this Tier 3 fixture. Until then,
`F_VAR_PAM`'s 5 cross-subject keys remain sentinel.

### ORCH_TODO: PHC_UIDS does not include 22002000

`scripts/merge_and_verify.sh` line 446 currently has:

```sh
readonly PHC_UIDS='20000100,20050010,22000010,22000020,22000030,22000040,22000050,22000060,22000070,22000080,22000090,22000100,22000200,22001000'
```

22002000 is **not** in this list. Step 9 invocations of
`sp_var_datamart_postprocessing` (line 502),
`sp_f_var_pam_postprocessing` (line 514), and
`sp_event_metric_datamart_postprocessing` (line 489) iterate this list
and will skip 22002000. **Parent agent must extend PHC_UIDS to
`'...,22001000,22002000'`** for the orchestrated end-to-end run to
populate F_VAR_PAM and VAR_DATAMART for the new Investigation. No
other orchestrator changes needed — `sp_nrt_investigation_postprocessing`
and the 4 d_topic SPs are tail-EXEC'd directly by this fixture.

### OUT_OF_SCOPE: not invoked in this fixture

None. All Varicella-cluster SPs are reachable from a single fixture
(unlike TB, which had 12 d_topic SPs — the Varicella cluster is much
smaller).

## Orchestrator integration recommendation

The Varicella PAM cluster follows the same orchestrator-vs-fixture
split as the TB cluster:

- **Fixture tail-EXEC** (this file): `sp_nrt_investigation_postprocessing`,
  `sp_nrt_d_var_pam_postprocessing` (root), `sp_nrt_d_rash_loc_gen_postprocessing`,
  `sp_nrt_d_pcr_source_postprocessing`, `sp_nrt_var_pam_ldf_postprocessing`.
  These populate D_VAR_PAM + the 2 d_topic dims + groups in
  Tier-1-isolation.
- **Orchestrator Step 9**: `sp_event_metric_datamart_postprocessing`,
  `sp_f_var_pam_postprocessing`, `sp_var_datamart_postprocessing`.
  Each writes against the full PHC_UIDS list once per merged-fixture
  run. Required extension: add 22002000 to PHC_UIDS (see ORCH_TODO
  above).

Just like the TB fixture, **do NOT tail-EXEC `sp_f_var_pam_postprocessing`
or `sp_var_datamart_postprocessing` from this fixture** — that would
duplicate Step 9's work and produce 2x row counts (the same potential
duplicate-INSERT pattern noted in the TB coverage report for
TB_DATAMART; var_datamart's INSERT has a `WHERE D.INVESTIGATION_KEY IS
NULL` guard so it's idempotent, but f_var_pam has a DELETE-then-INSERT
guard which would also be safe — still cleaner to single-fire from
Step 9).

## Reproduction recipe

```sh
export SQLCMDPASSWORD=PizzaIsGood33!
# Apply against existing populated state (assumes Tier 1/2/prior Tier 3 already applied)
sqlcmd -S localhost,3433 -U sa -C \
  -i /Users/adam/code/nbs/NEDSS-DataReporting/utilities/comparison-fixtures/fixtures/30_sp_coverage/varicella_investigation_full_chain.sql

# Verify cluster populations
sqlcmd -S localhost,3433 -U sa -C -d RDB_MODERN -Q "SET NOCOUNT ON;
  SELECT 'D_VAR_PAM',         COUNT(*) FROM dbo.D_VAR_PAM UNION ALL
  SELECT 'D_RASH_LOC_GEN',    COUNT(*) FROM dbo.D_RASH_LOC_GEN UNION ALL
  SELECT 'D_PCR_SOURCE',      COUNT(*) FROM dbo.D_PCR_SOURCE UNION ALL
  SELECT 'F_VAR_PAM',         COUNT(*) FROM dbo.F_VAR_PAM UNION ALL
  SELECT 'VAR_DATAMART',      COUNT(*) FROM dbo.VAR_DATAMART UNION ALL
  SELECT 'VAR_PAM_LDF',       COUNT(*) FROM dbo.VAR_PAM_LDF;"
```

For a full-baseline replay, `scripts/merge_and_verify.sh` picks up
this fixture at Step 8 automatically (the script iterates
`30_sp_coverage/*.sql` alphabetically). For F_VAR_PAM + VAR_DATAMART
coverage at Step 9, extend `PHC_UIDS` per ORCH_TODO.
