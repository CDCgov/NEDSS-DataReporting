# Coverage: merged fixture (full chain)

Generated: 2026-06-02 17:55:58 UTC

This report is produced by `scripts/coverage_summary.sh` against the
RDB_MODERN state after `scripts/merge_and_verify.sh` has run end-to-end.
It iterates every in-scope target table from
`catalog/rtr_target_columns.md` and counts populated rows + populated
columns.

A column is "populated" if at least one row has a non-NULL value for it.

## Summary

- In-scope target tables: 118
- Fully covered (all columns populated for at least one row): 33
- Partially covered (some columns populated): 24
- Empty (table exists, 0 rows): 60
- Missing (table not present in live RDB_MODERN): 1

- Total columns across in-scope tables: 4312
- Columns with ≥1 populated row: 605
- Overall column coverage: 14.0%

## Per-table coverage

| Table | Rows | Total cols | Populated cols |
| ----- | ---- | ---------- | -------------- |
| dbo.aggregate_report_datamart | 0 | 42 | 0/42 |
| dbo.antimicrobial_group | 1 | 1 | **1/1** |
| dbo.bmird_multi_value_field_group | 1 | 1 | **1/1** |
| dbo.bmird_strep_pneumo_datamart | 0 | 140 | 0/140 |
| dbo.case_count | 1 | 15 | **15/15** |
| dbo.case_lab_datamart | 1 | 35 | 24/35 |
| dbo.condition | 269 | 15 | 14/15 |
| dbo.confirmation_method | 2 | 3 | **3/3** |
| dbo.confirmation_method_group | 2 | 3 | 2/3 |
| dbo.covid_case_datamart | 0 | 100 | 0/100 |
| dbo.covid_contact_datamart | 0 | 94 | 0/94 |
| dbo.covid_lab_celr_datamart | 0 | 101 | 0/101 |
| dbo.covid_lab_datamart | 0 | 120 | 0/120 |
| dbo.covid_vaccination_datamart | 0 | 60 | 0/60 |
| dbo.d_addl_risk | 0 | 6 | 0/6 |
| dbo.d_addl_risk_group | 1 | 1 | **1/1** |
| dbo.d_case_management | 0 | 67 | 0/67 |
| dbo.d_contact_record | 1 | 66 | 1/66 |
| dbo.d_disease_site | 0 | 6 | 0/6 |
| dbo.d_disease_site_group | 1 | 1 | **1/1** |
| dbo.d_gt_12_reas | 0 | 6 | 0/6 |
| dbo.d_gt_12_reas_group | 1 | 1 | **1/1** |
| dbo.d_hc_prov_ty_3 | 0 | 6 | 0/6 |
| dbo.d_hc_prov_ty_3_group | 1 | 1 | **1/1** |
| dbo.d_interview | 0 | 24 | 0/24 |
| dbo.d_interview_note | 0 | 7 | 0/7 |
| dbo.d_inv_place_repeat | 1 | 42 | 1/42 |
| dbo.d_investigation_repeat | 2 | 244 | 1/244 |
| dbo.d_ldf_meta_data | 2620 | 14 | 12/14 |
| dbo.d_move_cntry | 0 | 6 | 0/6 |
| dbo.d_move_cntry_group | 1 | 1 | **1/1** |
| dbo.d_move_cnty | 0 | 6 | 0/6 |
| dbo.d_move_cnty_group | 1 | 1 | **1/1** |
| dbo.d_move_state | 0 | 6 | 0/6 |
| dbo.d_move_state_group | 1 | 1 | **1/1** |
| dbo.d_moved_where | 0 | 6 | 0/6 |
| dbo.d_moved_where_group | 1 | 1 | **1/1** |
| dbo.d_organization | 11 | 30 | 25/30 |
| dbo.d_out_of_cntry | 0 | 6 | 0/6 |
| dbo.d_out_of_cntry_group | 1 | 1 | **1/1** |
| dbo.d_patient | 5 | 81 | 46/81 |
| dbo.d_pcr_source | 0 | 6 | 0/6 |
| dbo.d_pcr_source_group | 1 | 1 | **1/1** |
| dbo.d_place | 0 | 37 | 0/37 |
| dbo.d_provider | 17 | 34 | 28/34 |
| dbo.d_rash_loc_gen | 0 | 6 | 0/6 |
| dbo.d_rash_loc_gen_group | 1 | 1 | **1/1** |
| dbo.d_smr_exam_ty | 0 | 6 | 0/6 |
| dbo.d_smr_exam_ty_group | 1 | 1 | **1/1** |
| dbo.d_tb_hiv | 0 | 6 | 0/6 |
| dbo.d_tb_pam | 0 | 166 | 0/166 |
| dbo.d_vaccination | 2 | 21 | **21/21** |
| dbo.d_var_pam | 0 | 129 | 0/129 |
| dbo.etl_dq_log | 0 | 15 | 0/15 |
| dbo.event_metric | 1 | 28 | 16/28 |
| dbo.event_metric_inc | 1 | 28 | 22/28 |
| dbo.f_contact_record_case | 0 | 11 | 0/11 |
| dbo.f_interview_case | 0 | 10 | 0/10 |
| dbo.f_page_case | 1 | 35 | 33/35 |
| dbo.f_std_page_case | 0 | 52 | 0/52 |
| dbo.f_tb_pam | 0 | 20 | 0/20 |
| dbo.f_vaccination | 0 | 6 | 0/6 |
| dbo.f_var_pam | 0 | 12 | 0/12 |
| dbo.hep100 | 0 | 187 | 0/187 |
| dbo.hep_multi_value_field_group | 1 | 1 | **1/1** |
| dbo.hepatitis_datamart | 0 | 209 | 0/209 |
| dbo.inv_hiv | 1 | 19 | 1/19 |
| dbo.inv_summ_datamart | 2 | 58 | **58/58** |
| dbo.investigation | 3 | 71 | 18/71 |
| dbo.job_batch_rebuild_log | MISSING | - | - |
| dbo.job_flow_log | 22266 | 15 | 13/15 |
| dbo.l_inv_place_repeat | 1 | 2 | 1/2 |
| dbo.l_investigation_repeat | 1 | 2 | 1/2 |
| dbo.l_investigation_repeat_inc | 0 | 2 | 0/2 |
| dbo.lab100 | 0 | 69 | 0/69 |
| dbo.lab101 | 0 | 46 | 0/46 |
| dbo.lab_result_comment | 5 | 6 | **6/6** |
| dbo.lab_result_val | 41 | 20 | **20/20** |
| dbo.lab_rpt_user_comment | 0 | 8 | 0/8 |
| dbo.lab_test | 10 | 66 | 53/66 |
| dbo.lab_test_result | 6 | 20 | 19/20 |
| dbo.ldf_bmird | 0 | 7 | 0/7 |
| dbo.ldf_data | 1 | 17 | 9/17 |
| dbo.ldf_datamart_column_ref | 2662 | 8 | **8/8** |
| dbo.ldf_dimensional_data | 1 | 16 | 9/16 |
| dbo.ldf_foodborne | 0 | 7 | 0/7 |
| dbo.ldf_group | 2 | 2 | **2/2** |
| dbo.ldf_hepatitis | 0 | 7 | 0/7 |
| dbo.ldf_mumps | 0 | 7 | 0/7 |
| dbo.ldf_tetanus | 0 | 7 | 0/7 |
| dbo.ldf_vaccine_prevent_diseases | 1 | 8 | **8/8** |
| dbo.lookup_table_n_rept | 0 | 2 | 0/2 |
| dbo.morb_rpt_user_comment | 0 | 8 | 0/8 |
| dbo.morbidity_report | 2 | 30 | 28/30 |
| dbo.morbidity_report_datamart | 0 | 133 | 0/133 |
| dbo.morbidity_report_event | 1 | 17 | **17/17** |
| dbo.notification | 0 | 6 | 0/6 |
| dbo.notification_event | 0 | 8 | 0/8 |
| dbo.organization_ldf_group | 0 | 3 | 0/3 |
| dbo.patient_ldf_group | 0 | 3 | 0/3 |
| dbo.pertussis_suspected_source_grp | 1 | 1 | **1/1** |
| dbo.pertussis_treatment_group | 1 | 1 | **1/1** |
| dbo.provider_ldf_group | 0 | 3 | 0/3 |
| dbo.rdb_date | 14976 | 11 | **11/11** |
| dbo.result_comment_group | 7 | 3 | **3/3** |
| dbo.sr100 | 0 | 20 | 0/20 |
| dbo.std_hiv_datamart | 0 | 248 | 0/248 |
| dbo.summary_case_group | 1 | 2 | 1/2 |
| dbo.summary_report_case | 0 | 12 | 0/12 |
| dbo.tb_datamart | 0 | 318 | 0/318 |
| dbo.tb_hiv_datamart | 0 | 322 | 0/322 |
| dbo.tb_pam_ldf | 0 | 3 | 0/3 |
| dbo.test_result_grouping | 7 | 3 | **3/3** |
| dbo.treatment | 4 | 16 | **16/16** |
| dbo.treatment_event | 3 | 11 | **11/11** |
| dbo.user_profile | 12 | 8 | **8/8** |
| dbo.var_datamart | 0 | 231 | 0/231 |
| dbo.var_pam_ldf | 0 | 3 | 0/3 |


## Categorization

### Fully covered (33)

Tables where every column has at least one row with a non-NULL value.

- dbo.antimicrobial_group
- dbo.bmird_multi_value_field_group
- dbo.case_count
- dbo.confirmation_method
- dbo.d_addl_risk_group
- dbo.d_disease_site_group
- dbo.d_gt_12_reas_group
- dbo.d_hc_prov_ty_3_group
- dbo.d_move_cntry_group
- dbo.d_move_cnty_group
- dbo.d_move_state_group
- dbo.d_moved_where_group
- dbo.d_out_of_cntry_group
- dbo.d_pcr_source_group
- dbo.d_rash_loc_gen_group
- dbo.d_smr_exam_ty_group
- dbo.d_vaccination
- dbo.hep_multi_value_field_group
- dbo.inv_summ_datamart
- dbo.lab_result_comment
- dbo.lab_result_val
- dbo.ldf_datamart_column_ref
- dbo.ldf_group
- dbo.ldf_vaccine_prevent_diseases
- dbo.morbidity_report_event
- dbo.pertussis_suspected_source_grp
- dbo.pertussis_treatment_group
- dbo.rdb_date
- dbo.result_comment_group
- dbo.test_result_grouping
- dbo.treatment
- dbo.treatment_event
- dbo.user_profile

### Partially covered (24)

Tables with rows but at least one column never populated. These are the
candidates for Tier 3 gap-driven coverage work.

- dbo.case_lab_datamart
- dbo.condition
- dbo.confirmation_method_group
- dbo.d_contact_record
- dbo.d_inv_place_repeat
- dbo.d_investigation_repeat
- dbo.d_ldf_meta_data
- dbo.d_organization
- dbo.d_patient
- dbo.d_provider
- dbo.event_metric
- dbo.event_metric_inc
- dbo.f_page_case
- dbo.inv_hiv
- dbo.investigation
- dbo.job_flow_log
- dbo.l_inv_place_repeat
- dbo.l_investigation_repeat
- dbo.lab_test
- dbo.lab_test_result
- dbo.ldf_data
- dbo.ldf_dimensional_data
- dbo.morbidity_report
- dbo.summary_case_group

### Empty (60)

Tables that exist in RDB_MODERN but have zero rows after the merged
chain runs. Most are datamart-side fact tables that depend on Merge
contract step 9 (Datamart SPs — out of scope for v1).

- dbo.aggregate_report_datamart
- dbo.bmird_strep_pneumo_datamart
- dbo.covid_case_datamart
- dbo.covid_contact_datamart
- dbo.covid_lab_celr_datamart
- dbo.covid_lab_datamart
- dbo.covid_vaccination_datamart
- dbo.d_addl_risk
- dbo.d_case_management
- dbo.d_disease_site
- dbo.d_gt_12_reas
- dbo.d_hc_prov_ty_3
- dbo.d_interview
- dbo.d_interview_note
- dbo.d_move_cntry
- dbo.d_move_cnty
- dbo.d_move_state
- dbo.d_moved_where
- dbo.d_out_of_cntry
- dbo.d_pcr_source
- dbo.d_place
- dbo.d_rash_loc_gen
- dbo.d_smr_exam_ty
- dbo.d_tb_hiv
- dbo.d_tb_pam
- dbo.d_var_pam
- dbo.etl_dq_log
- dbo.f_contact_record_case
- dbo.f_interview_case
- dbo.f_std_page_case
- dbo.f_tb_pam
- dbo.f_vaccination
- dbo.f_var_pam
- dbo.hep100
- dbo.hepatitis_datamart
- dbo.l_investigation_repeat_inc
- dbo.lab100
- dbo.lab101
- dbo.lab_rpt_user_comment
- dbo.ldf_bmird
- dbo.ldf_foodborne
- dbo.ldf_hepatitis
- dbo.ldf_mumps
- dbo.ldf_tetanus
- dbo.lookup_table_n_rept
- dbo.morb_rpt_user_comment
- dbo.morbidity_report_datamart
- dbo.notification
- dbo.notification_event
- dbo.organization_ldf_group
- dbo.patient_ldf_group
- dbo.provider_ldf_group
- dbo.sr100
- dbo.std_hiv_datamart
- dbo.summary_report_case
- dbo.tb_datamart
- dbo.tb_hiv_datamart
- dbo.tb_pam_ldf
- dbo.var_datamart
- dbo.var_pam_ldf

### Missing from live schema (1)

Tables listed in the Phase 0 catalog but absent from baseline 6.0.18.1.
These are catalog/schema drift findings — the SP body references them
but the live DDL doesn't include them.

- dbo.job_batch_rebuild_log

