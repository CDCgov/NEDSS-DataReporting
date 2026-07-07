# ODSE-unknown RDB tables: classification

Generated: 2026-05-21 (Phase 2 prep for APP-471).

Source list: `STRATEGY.md` "Follow-on / phase-2" plus a teammate's note about ~80
RDB tables with no known ODSE-input path. Cross-referenced against
`coverage/coverage_merged.md` for the current empty/partial/full state.

## Method

For every table in the teammate's list (and the broader 118 in-scope
target tables from `coverage_merged.md`):

1. Greped `liquibase-service/src/main/resources/db/005-rdb_modern/routines/`
   for `INSERT INTO <tbl>`, `UPDATE <tbl>`, `MERGE [INTO] <tbl>`, and
   `SELECT … INTO <tbl>`. Filtered out FROM-clause reads and references
   to `#<tbl>` temp tables, so what remains is real persistent writes.
2. Where the writer is a `sp_*_datamart_*` SP that does dynamic SQL
   (`'INSERT INTO dbo.' + @tgt_table_nm + ...'`), the target was
   identified by reading the `DECLARE @tgt_table_nm` line at the top of
   the SP.
3. For each writer found, classified by SP filename pattern:
   - `sp_*_datamart_*` (incl. `sp_dyn_dm_*`, `sp_aggregate_report_datamart_*`,
     `sp_*_case_datamart_*`, `sp_ldf_*_datamart_*`) → bucket (b).
   - `sp_nrt_*_postprocessing` and `sp_d_*_postprocessing` already
     exercised by the v1 merged-chain → bucket (c).
   - No writer in any routine → bucket (a) MasterETL-only.
4. Two tables that an earlier triage pass had marked MasterETL-only are
   in fact RTR-written; see the corrections in Notable findings.

## Summary counts

- (a) MasterETL-only (no RTR writer): **26 tables**
- (b) Datamart-SP-driven (datamart SPs / dyn_dm chain the service fires during the CDC drain): **45 tables**
- (c) Tier-1-or-Tier-2 reachable (fixture gap): **35 tables**
- (d) Uninvestigated (insufficient time / unclear): **0 tables**
- Missing from live schema (per `coverage_merged.md`): **118 tables**
  flagged separately (see note below).
- Already populated despite being on the unknown list: see Notable
  findings (counts depend on whether `coverage_merged.md` is regenerated
  after the most recent fixture seed cycle).

> **Note on `coverage_merged.md` MISSING (118)**: at generation time
> the file reported *all 118* in-scope target tables as missing from
> baseline 6.0.18.1. That is a separate Liquibase / DDL bootstrap
> issue (likely a stale `coverage_merged.md` snapshot or a baseline
> regression), **not** a per-table classification problem. The
> bucketing below is the static analysis of whether RTR *would*
> populate the table if the DDL were present and fixtures were
> authored.

## Classification table

Writer SP file numbers are the prefix (e.g., `005` for
`005-sp_nrt_investigation_postprocessing-001.sql`). "(none)" in
the Writer column means no RTR routine writes the table.

### (a) MasterETL-only (RTR never writes these)

| Table | Writer SP | Notes |
| ----- | --------- | ----- |
| `dm_inv_administrative` | (none) | Static name not in any routine. The `sp_dyn_dm_createdm_postprocessing` builds `DM_INV_<datamart_nm>` dynamically; "administrative" is not a v1 datamart_nm. Belongs to MasterETL legacy schema. |
| `dm_inv_clinical` | (none) | Same as above. |
| `dm_inv_epi` | (none) | Same as above. |
| `dm_inv_lab_finding` | (none) | Same as above. |
| `dm_inv_risk_factor` | (none) | Same as above. |
| `dm_inv_treatment` | (none) | Same as above. |
| `geocoding_location` | (none) | Read by 10 SPs as `LEFT JOIN dbo.GEOCODING_LOCATION` for the geocoding_location_key FK lookup; never written. Pure MasterETL output. |
| `missing_lab_cases` | (none) | Not referenced anywhere in the routines tree. |
| `staging_key_repeating_final` | (none) | Not referenced anywhere. (`STAGING_KEY_REPEATING_*` is a MasterETL pipeline artifact.) |
| `vacc_differential_dose` | (none) | Not referenced anywhere. |
| `vacc_differential_dose_grp` | (none) | Not referenced anywhere. |
| `vacc_disassociated_table` | (none) | Not referenced anywhere. |
| `l_addl_risk` | (none) | Used only as `#L_ADDL_RISK` temp table in `146-sp_nrt_d_addl_risk_postprocessing`. Persistent table is MasterETL. |
| `l_disease_site` | (none) | Same pattern. |
| `l_gt_12_reas` | (none) | Same pattern. |
| `l_hc_prov_ty_3` | (none) | Same pattern. |
| `l_move_cntry` | (none) | Same pattern. |
| `l_move_cnty` | (none) | Same pattern. |
| `l_move_state` | (none) | Same pattern. |
| `l_moved_where` | (none) | Same pattern. |
| `l_out_of_cntry` | (none) | Same pattern. |
| `l_pcr_source` | (none) | Same pattern. |
| `l_rash_loc_gen` | (none) | Same pattern. |
| `l_smr_exam_ty` | (none) | Same pattern. |
| `nbs_case_answer_rept` | (none) | Used only as `#NBS_CASE_ANSWER_REPT` temp table inside `010-sp_sld_investigation_repeat_postprocessing`. Persistent table is MasterETL. |
| `summ_datamart` | (none) | The persistent table referenced by MasterETL. RTR has `INV_SUMM_DATAMART` (different table) populated by `045-sp_inv_summary_datamart_postprocessing`. Note also `tmp_DynDm_INV_SUMM_DATAMART_*` temp-table family. |

### (b) Datamart-SP-driven (RTR writes via the datamart SPs the service fires during the CDC drain)

These populate when the reporting-pipeline-service fires the datamart
SPs off CDC events during the drain. Several
condition-specific datamarts were blocked by SP-level defects rather than
missing fixtures; HEPATITIS_DATAMART in particular by the `#TMP_F_PAGE_CASE`
chain in bug #5.

| Table | Writer SP | Notes |
| ----- | --------- | ----- |
| `aggregate_report_datamart` | `050-sp_aggregate_report_datamart_postprocessing` | Dynamic SQL via `@tgt_table_nm='AGGREGATE_REPORT_DATAMART'`. |
| `bmird_case` | `040-sp_bmird_case_datamart_postprocessing` | Dynamic SQL via `@tgt_table_nm='BMIRD_Case'`. |
| `bmird_strep_pneumo_datamart` | `140-sp_bmird_strep_pneumo_datamart_postprocessing` | Direct INSERT. Currently 0 rows (TMP_F_PAGE_CASE family bug). |
| `case_lab_datamart` | `034-sp_case_lab_datamart_postprocessing` | Direct INSERT. |
| `covid_case_datamart` | `310-sp_covid_case_datamart_postprocessing` | TMP_F_PAGE_CASE family bug. |
| `covid_contact_datamart` | `315-sp_covid_contact_datamart_postprocessing` |  |
| `covid_lab_celr_datamart` | `325-sp_covid_lab_celr_datamart_postprocessing` |  |
| `covid_lab_datamart` | `330-sp_covid_lab_datamart_postprocessing` |  |
| `covid_vaccination_datamart` | `320-sp_covid_vaccination_datamart_postprocessing` |  |
| `crs_case` | `032-sp_crs_case_datamart_postprocessing` | Dynamic SQL `@tgt_table_nm='CRS_Case'`. |
| `f_page_case` | `012-sp_f_page_case_postprocessing` | Already populated by Tier 3 unblock (form-cd fix). |
| `f_std_page_case` | `025-sp_f_std_page_case_postprocessing` |  |
| `f_vaccination` | `046-sp_f_vaccination_postprocessing` |  |
| `f_var_pam` | `240-sp_f_var_pam_postprocessing` | Varicella PAM cluster. |
| `f_tb_pam` | `206-sp_f_tb_pam_postprocessing` | TB PAM cluster. |
| `f_contact_record_case` | `038-sp_f_contact_record_case_postprocessing` |  |
| `f_interview_case` | `024-sp_f_interview_case_postprocessing` |  |
| `hep100` | `042-sp_hep100_datamart_postprocessing` |  |
| `hepatitis_case` | `039-sp_hepatitis_case_datamart_postprocessing` | Dynamic SQL `@tgt_table_nm='Hepatitis_Case'`. Also UPDATEd by `015-sp_nrt_ldf_postprocessing` (group_key reassignment). |
| `hepatitis_datamart` | `013-sp_hepatitis_datamart_postprocessing` | Currently 0 rows (TMP_F_PAGE_CASE family bug). |
| `inv_summ_datamart` | `045-sp_inv_summary_datamart_postprocessing` | Direct INSERT (line 867). |
| `lab100` | `019-sp_lab100_datamart_postprocessing` |  |
| `lab101` | `020-sp_lab101_datamart_postprocessing` |  |
| `ldf_bmird` | `285-sp_ldf_bmird_datamart_postprocessing` | LDF chain. |
| `ldf_foodborne` | `290-sp_ldf_foodborne_datamart_postprocessing` | LDF chain. |
| `ldf_hepatitis` | `320-sp_ldf_hepatitis_datamart_postprocessing` | LDF chain. Blocked by LDF_DIMENSIONAL_DATA bug per Tier 3. |
| `ldf_mumps` | `295-sp_ldf_mumps_datamart_postprocessing` | LDF chain. |
| `ldf_tetanus` | `300-sp_ldf_tetanus_datamart_postprocessing` | LDF chain. Blocked per Tier 3. |
| `ldf_vaccine_prevent_diseases` | `305-sp_ldf_vaccine_prevent_diseases_datamart_postprocessing` | LDF chain. |
| `measles_case` | `033-sp_measles_case_datamart_postprocessing` | Dynamic SQL. |
| `morbidity_report_datamart` | `048-sp_morbidity_report_datamart_postprocessing` | Direct INSERT. |
| `pertussis_case` | `043-sp_pertussis_case_datamart_postprocessing` | Dynamic SQL `@tgt_table_nm='Pertussis_Case'`. |
| `pertussis_suspected_source_grp` | `043-sp_pertussis_case_datamart_postprocessing` | Direct INSERT (line 659). |
| `pertussis_treatment_group` | `043-sp_pertussis_case_datamart_postprocessing` | Direct INSERT. |
| `rubella_case` | `031-sp_rubella_case_datamart_postprocessing` | Dynamic SQL. |
| `sr100` | `155-sp_sr100_datamart_postprocessing` | Direct INSERT. |
| `std_hiv_datamart` | `026-sp_std_hiv_datamart_postprocessing` | TMP_F_PAGE_CASE family bug. |
| `summary_report_case` | `150-sp_summary_report_case_postprocessing` |  |
| `tb_datamart` | `255-sp_tb_datamart_postprocessing` | Direct INSERT line 1751; TMP_F_PAGE_CASE family bug. |
| `tb_hiv_datamart` | `260-sp_tb_hiv_datamart_postprocessing` |  |
| `var_datamart` | `250-sp_var_datamart_postprocessing` | Direct INSERT. |
| `antimicrobial_group` | `040-sp_bmird_case_datamart_postprocessing` | INSERT INTO dbo.ANTIMICROBIAL_GROUP. |
| `bmird_multi_value_field_group` | `040-sp_bmird_case_datamart_postprocessing` | INSERT INTO dbo.BMIRD_MULTI_VALUE_FIELD_GROUP. |
| `hep_multi_value_field_group` | `039-sp_hepatitis_case_datamart_postprocessing` | INSERT INTO dbo.HEP_MULTI_VALUE_FIELD_GROUP. |
| `inv_hiv` | `026-sp_std_hiv_datamart_postprocessing` |  |

### (c) Tier-1 / Tier-2 reachable (fixture gap)

These would populate once we author fixture rows that exercise the
relevant subject. The TB-PAM cluster (14 d_* tables, 12 d_*_group
tables, plus pam-LDFs) needs a TB Investigation with proper TB form
answers, which is explicit Phase 2 work.

| Table | Writer SP | Notes |
| ----- | --------- | ----- |
| `d_addl_risk` | `146-sp_nrt_d_addl_risk_postprocessing` | TB-PAM cluster. |
| `d_addl_risk_group` | `146-sp_nrt_d_addl_risk_postprocessing` | TB-PAM cluster. |
| `d_disease_site` | `145-sp_nrt_d_disease_site_postprocessing` | TB-PAM cluster. |
| `d_disease_site_group` | `145-sp_nrt_d_disease_site_postprocessing` | TB-PAM cluster. |
| `d_gt_12_reas` | `170-sp_nrt_d_gt_12_reas_postprocessing` | TB-PAM cluster. |
| `d_gt_12_reas_group` | `170-sp_nrt_d_gt_12_reas_postprocessing` | TB-PAM cluster. |
| `d_hc_prov_ty_3` | `180-sp_nrt_d_hc_prov_ty_3_postprocessing` | TB-PAM cluster. |
| `d_hc_prov_ty_3_group` | `180-sp_nrt_d_hc_prov_ty_3_postprocessing` | TB-PAM cluster. |
| `d_move_cntry` | `156-sp_nrt_d_move_cntry_postprocessing` | TB-PAM cluster. |
| `d_move_cntry_group` | `156-sp_nrt_d_move_cntry_postprocessing` | TB-PAM cluster. |
| `d_move_cnty` | `175-sp_nrt_d_move_cnty_postprocessing` | TB-PAM cluster. |
| `d_move_cnty_group` | `175-sp_nrt_d_move_cnty_postprocessing` | TB-PAM cluster. |
| `d_move_state` | `185-sp_nrt_d_move_state_postprocessing` | TB-PAM cluster. |
| `d_move_state_group` | `185-sp_nrt_d_move_state_postprocessing` | TB-PAM cluster. |
| `d_moved_where` | `195-sp_nrt_d_moved_where_postprocessing` | TB-PAM cluster. |
| `d_moved_where_group` | `195-sp_nrt_d_moved_where_postprocessing` | TB-PAM cluster. |
| `d_out_of_cntry` | `190-sp_nrt_d_out_of_cntry_postprocessing` | TB-PAM cluster. |
| `d_out_of_cntry_group` | `190-sp_nrt_d_out_of_cntry_postprocessing` | TB-PAM cluster. |
| `d_pcr_source` | `230-sp_nrt_d_pcr_source_postprocessing` | TB-PAM cluster. |
| `d_pcr_source_group` | `230-sp_nrt_d_pcr_source_postprocessing` | TB-PAM cluster. |
| `d_rash_loc_gen` | `225-sp_nrt_d_rash_loc_gen_postprocessing` | TB-PAM cluster (varicella). |
| `d_rash_loc_gen_group` | `225-sp_nrt_d_rash_loc_gen_postprocessing` | TB-PAM cluster. |
| `d_smr_exam_ty` | `200-sp_nrt_d_smr_exam_ty_postprocessing` | TB-PAM cluster. |
| `d_smr_exam_ty_group` | `200-sp_nrt_d_smr_exam_ty_postprocessing` | TB-PAM cluster. |
| `d_tb_hiv` | `160-sp_nrt_d_tb_hiv_postprocessing` | TB-PAM cluster. |
| `d_tb_pam` | `147-sp_nrt_d_tb_pam_postprocessing` | TB-PAM cluster (root: the 14 d_topic SPs read D_TB_PAM). |
| `d_var_pam` | `215-sp_nrt_d_var_pam_postprocessing` | Varicella PAM. |
| `d_case_management` | `022-sp_nrt_case_management_postprocessing` | Needs a case-management ODSE input. |
| `tb_pam_ldf` | `220-sp_nrt_tb_pam_ldf_postprocessing` | TB-PAM cluster. Runs after TB PAM dim tables. |
| `var_pam_ldf` | `235-sp_nrt_var_pam_ldf_postprocessing` | Var-PAM equivalent. |
| `summary_case_group` | `150-sp_summary_report_case_postprocessing` | Sentinel-only today (1 row); real population needs summary-report fixture. |
| `etl_dq_log` | `007-sp_s_pagebuilder_postprocessing`, `010-sp_sld_investigation_repeat_postprocessing`, `025-sp_f_std_page_case_postprocessing` | **Correction** to an earlier triage that marked this MasterETL-only: three RTR routines INSERT into it as DQ-failure side-channel logging. Will populate once a fixture hits an invalid numeric / DQ-fail branch. |
| `lookup_table_n_rept` | `010-sp_sld_investigation_repeat_postprocessing` | **Correction** to an earlier triage that marked this MasterETL-only: `sp_sld_investigation_repeat_postprocessing` does `DELETE FROM dbo.LOOKUP_TABLE_N_REPT; INSERT INTO dbo.LOOKUP_TABLE_N_REPT …` (lines 1144-1146). Will populate once the SLD repeat chain runs against a fixture with NBS_PAGE rows. |
| `confirmation_method` | `005-sp_nrt_investigation_postprocessing` | Already partially exercised (Investigation chain INSERT/UPDATE); should be in coverage_merged.md once the missing-DDL issue is resolved. |
| `confirmation_method_group` | `005-sp_nrt_investigation_postprocessing` | Same. |

### (d) Genuinely uninvestigated (0 tables)

Every table in the teammate's list resolved to one of (a)/(b)/(c).
No (d) entries.

## Notable findings

1. **Two tables an earlier triage marked MasterETL-only are actually
   RTR-written.** `etl_dq_log` and `lookup_table_n_rept` were both
   listed as having no RTR writer. Both are in fact written by RTR
   routines. `etl_dq_log` receives DQ-failure rows from three
   page-builder / SLD-repeat SPs (DQ_ISSUE_DESC_TXT, etc.), so bucket
   (c). `lookup_table_n_rept` is fully rewritten by
   `010-sp_sld_investigation_repeat_postprocessing` (DELETE +
   INSERT), also bucket (c). Two more tables are reachable than
   previously thought, but only if a fixture exercises the SLD repeat
   chain or a DQ-fail branch.

2. **The `dm_inv_*` family is almost certainly a misnamed
   classification on the teammate's part.** The teammate listed
   `dm_inv_administrative`, `dm_inv_clinical`, etc. as ODSE-unknown.
   These specific names appear nowhere in the RTR routines. RTR
   *does* build `DM_INV_<datamart_nm>` tables dynamically via
   `245-sp_dyn_dm_createdm_postprocessing` (line 35:
   `@tgt_table_nm = 'DM_INV_' + @DATAMART_NAME`). The dynamic chain
   produces tables like `DM_INV_HEPATITIS_DATAMART`, not the
   topic-named legacy tables. The legacy `DM_INV_ADMINISTRATIVE`,
   `DM_INV_CLINICAL`, etc. are MasterETL output. RTR replaces
   them with per-condition wide DM_INV tables generated by the
   dyn_dm chain. The eventual RDB-vs-RDB_MODERN diff surfaces
   this as a schema-shape gap rather than a row-count gap.

3. **The TB-PAM cluster is the single biggest fixture-gap
   opportunity.** 26 of 34 bucket (c) tables (76%) are TB / Var /
   Topic-PAM dimensions. Authoring a TB Investigation with proper
   NBS_case_answer rows for the RVCT form would unblock 14 d_*
   tables + 12 d_*_group tables + `tb_pam_ldf` in one fixture.
   Similarly a Varicella Investigation would unblock `d_var_pam`,
   `f_var_pam`, `d_rash_loc_gen`, `var_pam_ldf`. This dovetails
   with the multi-condition expansion work, but
   `multi_condition_investigations.sql` is currently a stub, so the
   TB/Var families still need the full ODSE `act` + `public_health_case`
   + `nbs_case_answer` + form-id chain that TB-PAM postprocessing
   requires.

4. **The dyn_dm chain (sp_dyn_dm_*) fires via the service's
   page-builder path, gated on fixture content.** In the CDC-only flow
   the reporting-pipeline-service drives the `sp_dyn_dm_*` family
   (`sp_dyn_dm_createdm_postprocessing`,
   `sp_dyn_dm_invest_form_postprocessing`, `sp_dyn_dm_repeat*`) off CDC
   events during the drain, via its page-builder path — not from any
   script step. The RTR-side `DM_INV_<DATAMART_NAME>` wide tables (the
   modern equivalent of the legacy `DM_INV_*` topic tables) stay 0-rows
   only when fixtures don't drive the page-builder path for the relevant
   form. **Phase 2 gating item**: ensure the synthetic fixtures author
   the investigation/form content that makes the service fire the
   dyn_dm family before running the comparison.

5. **The `confirmation_method` / `confirmation_method_group` pair
   is not actually ODSE-unknown.** `005-sp_nrt_investigation_postprocessing`
   has explicit INSERT and UPDATE blocks for both, gated on
   investigation rows with confirmation data. Should be in
   coverage_merged.md as populated once the baseline DDL issue is
   fixed; teammate may have listed them based on legacy MasterETL
   naming.

## Overlap with multi-condition expansion

`multi_condition_investigations.sql` is currently a stub (no investigations
authored). The bucket (c) tables below would be unblocked by authoring full
ODSE condition chains (`act` + `public_health_case` + `nbs_case_answer` /
form-id) for these conditions:

- **TB family** (Investigation 22000010, condition 10220, INV_FORM_RVCT):
  `d_tb_pam`, `d_tb_hiv`, `d_addl_risk`(+group), `d_disease_site`(+group),
  `d_gt_12_reas`(+group), `d_hc_prov_ty_3`(+group), `d_move_cntry`(+group),
  `d_move_cnty`(+group), `d_move_state`(+group), `d_moved_where`(+group),
  `d_out_of_cntry`(+group), `d_pcr_source`(+group), `d_smr_exam_ty`(+group),
  `tb_pam_ldf`.
- **Varicella family** (Investigation 22000020, condition 10030, INV_FORM_VAR):
  `d_var_pam`, `d_rash_loc_gen`(+group), `var_pam_ldf`, `f_var_pam`.
- **TB datamart** (bucket b, but unblocks alongside): `tb_datamart`,
  `tb_hiv_datamart`, plus the entire condition-datamart SP family
  pending the TMP_F_PAGE_CASE bug.

The multi-condition fixtures should validate against this list as they
extend coverage to more conditions.

## Recommended Phase 2 priority

1. **First**: author the TB-PAM full chain fixture (TB Investigation
   with RVCT form `nbs_case_answer` rows). 26 of 35 bucket (c) tables
   light up from a single fixture file. This is the highest yield-per-
   effort opportunity in the catalog.
2. **Second**: fix the `#TMP_F_PAGE_CASE` chain in the
   condition-datamart SP family (bug #5).
   Without this, the affected condition-specific datamarts stay at
   0 rows regardless of fixture authoring. This is an RTR fix, not a
   fixture fix.
3. **Third**: drive the dyn_dm chain
   (`sp_dyn_dm_invest_form_postprocessing` →
   `sp_dyn_dm_createdm_postprocessing` → `sp_dyn_dm_repeat*`), which the
   service fires via its page-builder path during the CDC drain; author
   the fixture investigation/form content needed to trigger it. This
   produces the modern `DM_INV_<DATAMART_NAME>` wide tables that
   replace the legacy `DM_INV_*` topic tables on the RDB_MODERN side.
4. **Fourth**: small win. Fixture a DQ-fail branch (invalid numeric)
   to exercise `etl_dq_log` writes. Cheap to author, gives one row
   in a previously-thought-empty table, and validates the DQ
   reporting path.
5. **Skip for now**: pure MasterETL-only tables (`geocoding_location`,
   `dm_inv_*`, `vacc_differential_*`, `vacc_disassociated_table`,
   `staging_key_repeating_final`, `missing_lab_cases`, the legacy
   `l_*` lookup tables). These will surface as "RDB has rows,
   RDB_MODERN doesn't" in the diff. That is a finding for the
   comparison report rather than a fixture authoring task.
