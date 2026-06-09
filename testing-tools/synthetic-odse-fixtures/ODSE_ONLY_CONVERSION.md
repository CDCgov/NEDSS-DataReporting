# ODSE-only fixture conversion: RDB_MODERN direct-write remediation

**Principle:** fixtures author ONLY NBS_ODSE source rows; the RTR pipeline
(CDC → kafka-connect sink → `nrt_*` → `sp_*_postprocessing` → `D_*`/`F_*`/
`L_INV_*`/`*_DATAMART`/`INVESTIGATION`/`LAB_*` in RDB_MODERN) must DERIVE
everything in RDB_MODERN. Direct fixture writes to RDB_MODERN tables are the
violation being removed.

**Audit:** 24 of 101 active fixtures wrote directly to RDB_MODERN-only tables.
Triaged one-per-fixture. **All 24 are convertible to ODSE-only; none is blocked
by an RTR bug at the fixture-write level.** (Outputs that ARE bug-blocked,
HEPATITIS_DATAMART / STD_HIV_DATAMART via the `#TMP_F_PAGE_CASE` chain in
`013-sp_hepatitis_datamart` (bug #5), are datamart-SP outputs the service fires during the CDC drain, not fixture writes, so they
are not in scope here.)

**Key finding:** per-topic `D_INV_<topic>` / `L_INV_<topic>` ARE RTR-derived, via
**dynamic SQL** in `009-sp_d_pagebuilder_postprocessing` (`'INSERT INTO [dbo].' +
@rdb_table_name`, line 114/127) and `008-sp_l_pagebuilder_postprocessing`. A
static `grep 'INSERT INTO D_INV_x'` misses them (false-negative); they are NOT
MasterETL-only.

**Facts to record:** the VAR/TB/COVID/STD datamart SPs do not all use the same
TMP_F_PAGE_CASE pattern (F_PAGE_CASE refs per SP: hepatitis 013 = 66; covid 310 = 0;
var 250 = 0; tb 255 = 0). Bug #5 is specific to the F_PAGE_CASE-dependent SPs
(hepatitis), not a shared datamart-SP defect. See `bugs/README.md`. HEPATITIS_CASE and
HEPATITIS_DATAMART do not stay at 0 (live: HEPATITIS_DATAMART=6, HEPATITIS_CASE=1).

---

## Group A: delete dead/redundant direct-write; file stays (ODSE already present)

| Fixture | Write to remove | Why safe |
|---|---|---|
| `10_subjects/lab.sql` | IDENTITY-advance block ~438-465 (nrt_lab_test_key/_result_group_key) | Inert no-op pair + DELETE of a phantom row; key tables self-allocate via #17-fixed SPs 017/018 |
| `20_links/lab_inv.sql` | `USE [RDB_MODERN]` + 2× nrt_observation UPDATE ~158-168 | `associated_phc_uids` derived by 055-sp_observation_event from already-authored `act_relationship` LabReport edges |
| `20_links/morb_inv.sql` | `USE [RDB_MODERN]` + 2× nrt_observation UPDATE ~176-186 | Same as lab_inv; MorbReport `act_relationship` already authored in-file |
| `20_links/treatment_inv.sql` | `USE [RDB_MODERN]` + 2× nrt_treatment UPDATE ~239-249 (+ moot comments) | `associated_phc_uids` derived by 070-sp_treatment_event from already-authored TreatmentToPHC `act_relationship` |
| `30_sp_coverage/bmird_investigation_full_chain.sql` | LDF_GROUP sentinel INSERT ~199-213 | `015-sp_nrt_ldf_postprocessing` self-seeds the KEY=1 sentinel (lines 31-35); ensure LDF SP runs before BMIRD datamart SP |
| `30_sp_coverage/f_page_case_unblock.sql` | nrt_investigation UPDATE 48-51 (whole file) | INVESTIGATION_FORM_CD derives from ODSE PHC `cd='10110'` + SRTE condition_code via 056; file becomes empty → retire |
| `30_sp_coverage/zz_inv_summ_datamart_unblock.sql` | INV_SUMM_DATAMART seed INSERT 73-195 (whole file) | 045 already produces real rows; synthetic seed is cosmetic. No bug #21 exists in `bugs/`. File → retire |
| `30_sp_coverage/covid_investigation_full_chain.sql` | none executable (covid_case_datamart only in comments) | Already ODSE-only; trim stale header comments only |

## Group B: whole file superseded by an existing ODSE-only sibling, quarantine and document

| Fixture | Superseded by | Notes |
|---|---|---|
| `zz_covid_case_datamart_round2.sql` | `zz_covid_dedicated_entities.sql` | Half-finished stub (5/7 sections empty); its nrt_investigation UPDATE regresses correct ODSE values |
| `zz_covid_contact_datamart_enrich.sql` | `zz_covid_contact_fill.sql` + `zz_covid_dedicated_entities.sql` + `zz_covid_contact_side.sql` | Patches a patient (20000000) no longer linked to the COVID PHC |
| `zz_covid_vaccination_datamart_enrich.sql` | `zz_covid_vaccination_gap.sql` + `zz_covid_dedicated_entities.sql` | Self-defeating (no NRT_VACCINATION row, so dims never joined) |
| `zz_d_contact_record_enrich.sql` | `zz_contact_record_gap.sql` | Also seeds NRT_METADATA_COLUMNS (a deeper violation) |
| `zz_d_inv_place_repeat_enrich.sql` | `zz_d_inv_place_repeat.sql` | Self-declared "now-inert"; carries one forbidden DELETE on nrt_page_case_answer |
| `zz_enrich_vaccination.sql` | `zz_covid_vaccination_gap.sql` | Overwrites a Hep-A row's material_cd to COVID '208' (not ODSE-backed) |
| `zz_lab101_unblock.sql` | `zz_lab100_101_fill.sql` Part B | LAB101 datamart fullness is separately gated by bug #16 against the ODSE path |
| `zz_hepatitis_zz_hep100_unblock.sql` | pipeline (live HEPATITIS_CASE=1 derived from PHC 22043000) | Header's "no SP writes it" claim is false; 039-sp_hepatitis_case_datamart writes it via dynamic SQL |

## STATUS: COMPLETE. All 24 converted, ODSE-only invariant holds (0 violators)

Validated end-to-end via a clean `merge_and_verify` run (full CDC pipeline, no
direct RDB_MODERN writes). Every formerly-direct-written output now populates from
the pipeline: D_CASE_MANAGEMENT=22, D_TB_PAM=2, VAR_DATAMART=2/F_VAR_PAM=1,
CONFIRMATION_METHOD_GROUP=34, LAB_TEST=85/LAB100=5, INVESTIGATION=33,
MORBIDITY_REPORT=3/_EVENT=2/_DATAMART=2, D_INV_HIV=2/L_INV_HIV=2,
D_INV_RISK_FACTOR=6/L_INV_RISK_FACTOR=8, D_INV_LAB_FINDING=4, STD_HIV_DATAMART=1.

Two earlier risk flags resolved: (1) the std_hiv per-topic D_INV_*/L_INV_* derive
from nbs_case_answer via the page-builder during the CDC drain, with no explicit
pagebuilder loop needed; (2) STD_HIV_DATAMART and MORBIDITY_REPORT_DATAMART both
populate and are not bug-blocked.

In the current CDC-only flow the reporting-pipeline-service fires the
per-subject event + postprocessing + datamart SPs off CDC events during
the drain, so these clusters no longer need manual per-subject UID lists
in `scripts/merge_and_verify.sh`. The one deterministic list that
survives is `PHC_UIDS` (used by `run_summary_datamarts`), which includes
22006000 (phase2), 22015200 (morb), and the var PHC 22002000. The morb
patient/provider/org cluster and the lab-pair/morb-lab observations are
picked up by the service during the drain.

## Group C: real ODSE authoring required (DONE; see STATUS above)

| Fixture | Effort | Conversion |
|---|---|---|
| `case_management_staging.sql` | med | Replace nrt_investigation_case_management UPDATEs with ODSE `case_management` rows (enrich uid 20050011; INSERT one for PHC 20000100) + last_chg_time bump. Model: `zz_std_case_management.sql` (has the full nrt-col→ODSE-source decode map) |
| `zz_tb_datamart_enrich.sql` | med | Replace 3 nrt_page_case_answer answer_txt UPDATEs with corrected ODSE `nbs_case_answer.answer_txt` on PHC 22001000 (codeset 4260→'USA', 4170→'385660001', TUB114→'USA'); fix the anchor's seeded codes |
| `zz_var_datamart_enrich.sql` | med | Delete 4 writes; move INV_COMMENTS/illness-duration/outbreak_name into the var PHC `public_health_case` INSERT; author one ODSE `Confirmation_method` row; fix VAR103 code in the sibling |
| `zz_lab100_enrich.sql` | med | Replace 6 LAB_* INSERTs with 2 ODSE observation hierarchies (Order+Result, obs_value_*, participations, act_relationship COMP). Model: `zz_lab100_101_fill.sql` Part A. Add Result UIDs to orchestrator lab @obs_ids |
| `zz_enrich_phase2_investigations.sql` | high | Replace the 60-col nrt_investigation UPDATE (22 PHCs) with ODSE `public_health_case` column fills + `participation` InvestgrOfPHC + `nbs_case_answer` (for inv_state_case_id/legacy_case_id/city_county_case_nbr). 056 decodes the ~20 text columns, so author raw codes only |
| `zz_morbidity_report_datamart_enrich.sql` | high | Full multi-subject ODSE rewrite (1 morb + 16 follow-ups, patient, 2 providers, 2 orgs, investigation, 3 labs, 3 treatments) + cross-subject `act_relationship`/`participation` links so morb/lab/treatment share an investigation. Models: 10_subjects/* + 20_links/* |
| `std_hiv_investigation_full_chain.sql` | high | Delete 10 D_INV_*/L_INV_* dim/link INSERTs; author STD-form `nbs_case_answer` rows per category so 011→009→008 pagebuilder SPs derive the dims/links. Model: `tb_investigation_full_chain.sql`. (STD_HIV_DATAMART itself is a datamart-SP output fired by the service during the CDC drain, possibly bug-gated, not a fixture write) |
| `zz_std_hiv_datamart_enrich.sql` | high | Author repeating-block observations / `nbs_case_answer` for the 9 topic categories so the pagebuilder SPs (008/009) derive the per-topic D_INV_*/L_INV_*; the D_PATIENT/D_CASE_MANAGEMENT UPDATEs become ODSE person/case_management fills |
