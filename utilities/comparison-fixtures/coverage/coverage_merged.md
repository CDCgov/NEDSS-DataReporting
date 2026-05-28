# Coverage: merged fixture (full chain)

Generated: 2026-05-27 21:54:15 UTC

This report is produced by `scripts/coverage_summary.sh` against the
RDB_MODERN state after `scripts/merge_and_verify.sh` has run end-to-end.
It iterates every in-scope target table from
`catalog/rtr_target_columns.md` and counts populated rows + populated
columns.

A column is "populated" if at least one row has a non-NULL value for it.

## Summary

- In-scope target tables: 118
- Fully covered (all columns populated for at least one row): 76
- Partially covered (some columns populated): 36
- Empty (table exists, 0 rows): 5
- Missing (table not present in live RDB_MODERN): 1

- Total columns across in-scope tables: 4633
- Columns with ≥1 populated row: 4165
- Overall column coverage: 89.9%

## Per-table coverage

| Table | Rows | Total cols | Populated cols |
| ----- | ---- | ---------- | -------------- |
| dbo.aggregate_report_datamart | 0 | 42 | 0/42 |
| dbo.antimicrobial_group | 2 | 1 | **1/1** |
| dbo.bmird_multi_value_field_group | 2 | 1 | **1/1** |
| dbo.bmird_strep_pneumo_datamart | 2 | 140 | 126/140 |
| dbo.case_count | 24 | 15 | 13/15 |
| dbo.case_lab_datamart | 22 | 35 | 11/35 |
| dbo.condition | 269 | 15 | 14/15 |
| dbo.confirmation_method | 3 | 3 | **3/3** |
| dbo.confirmation_method_group | 27 | 3 | **3/3** |
| dbo.covid_case_datamart | 2 | 383 | 379/383 |
| dbo.covid_contact_datamart | 2 | 94 | 93/94 |
| dbo.covid_lab_celr_datamart | 1 | 101 | 85/101 |
| dbo.covid_lab_datamart | 1 | 129 | 127/129 |
| dbo.covid_vaccination_datamart | 2 | 60 | **60/60** |
| dbo.d_addl_risk | 3 | 6 | **6/6** |
| dbo.d_addl_risk_group | 2 | 1 | **1/1** |
| dbo.d_case_management | 3 | 67 | 62/67 |
| dbo.d_contact_record | 4 | 66 | 57/66 |
| dbo.d_disease_site | 3 | 6 | **6/6** |
| dbo.d_disease_site_group | 2 | 1 | **1/1** |
| dbo.d_gt_12_reas | 3 | 6 | **6/6** |
| dbo.d_gt_12_reas_group | 2 | 1 | **1/1** |
| dbo.d_hc_prov_ty_3 | 3 | 6 | **6/6** |
| dbo.d_hc_prov_ty_3_group | 2 | 1 | **1/1** |
| dbo.d_interview | 2 | 24 | 18/24 |
| dbo.d_interview_note | 2 | 7 | **7/7** |
| dbo.d_inv_place_repeat | 1 | 44 | 1/44 |
| dbo.d_investigation_repeat | 32 | 253 | 250/253 |
| dbo.d_ldf_meta_data | 2620 | 14 | 12/14 |
| dbo.d_move_cntry | 3 | 6 | **6/6** |
| dbo.d_move_cntry_group | 2 | 1 | **1/1** |
| dbo.d_move_cnty | 3 | 6 | **6/6** |
| dbo.d_move_cnty_group | 2 | 1 | **1/1** |
| dbo.d_move_state | 3 | 6 | **6/6** |
| dbo.d_move_state_group | 2 | 1 | **1/1** |
| dbo.d_moved_where | 3 | 6 | **6/6** |
| dbo.d_moved_where_group | 2 | 1 | **1/1** |
| dbo.d_organization | 13 | 30 | **30/30** |
| dbo.d_out_of_cntry | 3 | 6 | **6/6** |
| dbo.d_out_of_cntry_group | 2 | 1 | **1/1** |
| dbo.d_patient | 7 | 81 | **81/81** |
| dbo.d_pcr_source | 3 | 6 | **6/6** |
| dbo.d_pcr_source_group | 2 | 1 | **1/1** |
| dbo.d_place | 8 | 37 | **37/37** |
| dbo.d_provider | 19 | 34 | **34/34** |
| dbo.d_rash_loc_gen | 3 | 6 | **6/6** |
| dbo.d_rash_loc_gen_group | 2 | 1 | **1/1** |
| dbo.d_smr_exam_ty | 3 | 6 | **6/6** |
| dbo.d_smr_exam_ty_group | 2 | 1 | **1/1** |
| dbo.d_tb_hiv | 1 | 6 | **6/6** |
| dbo.d_tb_pam | 1 | 166 | 161/166 |
| dbo.d_vaccination | 4 | 21 | **21/21** |
| dbo.d_var_pam | 1 | 129 | 127/129 |
| dbo.etl_dq_log | 6200 | 15 | 14/15 |
| dbo.event_metric | 33 | 28 | **28/28** |
| dbo.event_metric_inc | 33 | 28 | **28/28** |
| dbo.f_contact_record_case | 2 | 11 | **11/11** |
| dbo.f_interview_case | 2 | 10 | **10/10** |
| dbo.f_page_case | 7 | 35 | 33/35 |
| dbo.f_std_page_case | 2 | 52 | **52/52** |
| dbo.f_tb_pam | 1 | 20 | **20/20** |
| dbo.f_vaccination | 2 | 6 | **6/6** |
| dbo.f_var_pam | 1 | 12 | **12/12** |
| dbo.hep100 | 1 | 187 | 185/187 |
| dbo.hep_multi_value_field_group | 1 | 1 | **1/1** |
| dbo.hepatitis_datamart | 2 | 209 | 144/209 |
| dbo.inv_hiv | 3 | 19 | 17/19 |
| dbo.inv_summ_datamart | 1 | 58 | **58/58** |
| dbo.investigation | 28 | 71 | **71/71** |
| dbo.job_batch_rebuild_log | MISSING | - | - |
| dbo.job_flow_log | 25825 | 15 | 14/15 |
| dbo.l_inv_place_repeat | 1 | 2 | 1/2 |
| dbo.l_investigation_repeat | 3 | 2 | **2/2** |
| dbo.l_investigation_repeat_inc | 1 | 2 | **2/2** |
| dbo.lab100 | 1 | 69 | 62/69 |
| dbo.lab101 | 1 | 46 | 11/46 |
| dbo.lab_result_comment | 6 | 6 | **6/6** |
| dbo.lab_result_val | 42 | 20 | **20/20** |
| dbo.lab_rpt_user_comment | 1 | 8 | **8/8** |
| dbo.lab_test | 13 | 66 | **66/66** |
| dbo.lab_test_result | 9 | 20 | 19/20 |
| dbo.ldf_bmird | 0 | 7 | 0/7 |
| dbo.ldf_data | 21 | 17 | 9/17 |
| dbo.ldf_datamart_column_ref | 2662 | 8 | **8/8** |
| dbo.ldf_dimensional_data | 18 | 16 | 14/16 |
| dbo.ldf_foodborne | 1 | 12 | 11/12 |
| dbo.ldf_group | 8 | 2 | **2/2** |
| dbo.ldf_hepatitis | 0 | 7 | 0/7 |
| dbo.ldf_mumps | 1 | 10 | 9/10 |
| dbo.ldf_tetanus | 1 | 11 | 10/11 |
| dbo.ldf_vaccine_prevent_diseases | 1 | 8 | **8/8** |
| dbo.lookup_table_n_rept | 0 | 2 | 0/2 |
| dbo.morb_rpt_user_comment | 1 | 8 | **8/8** |
| dbo.morbidity_report | 4 | 30 | **30/30** |
| dbo.morbidity_report_datamart | 3 | 133 | **133/133** |
| dbo.morbidity_report_event | 3 | 17 | **17/17** |
| dbo.notification | 2 | 6 | **6/6** |
| dbo.notification_event | 2 | 8 | **8/8** |
| dbo.organization_ldf_group | 1 | 3 | **3/3** |
| dbo.patient_ldf_group | 1 | 3 | **3/3** |
| dbo.pertussis_suspected_source_grp | 1 | 1 | **1/1** |
| dbo.pertussis_treatment_group | 1 | 1 | **1/1** |
| dbo.provider_ldf_group | 1 | 3 | **3/3** |
| dbo.rdb_date | 14976 | 11 | **11/11** |
| dbo.result_comment_group | 8 | 3 | **3/3** |
| dbo.sr100 | 0 | 20 | 0/20 |
| dbo.std_hiv_datamart | 2 | 248 | 231/248 |
| dbo.summary_case_group | 2 | 2 | **2/2** |
| dbo.summary_report_case | 1 | 12 | 11/12 |
| dbo.tb_datamart | 2 | 318 | 277/318 |
| dbo.tb_hiv_datamart | 2 | 322 | 281/322 |
| dbo.tb_pam_ldf | 1 | 6 | **6/6** |
| dbo.test_result_grouping | 8 | 3 | **3/3** |
| dbo.treatment | 7 | 16 | **16/16** |
| dbo.treatment_event | 6 | 11 | **11/11** |
| dbo.user_profile | 11 | 8 | **8/8** |
| dbo.var_datamart | 2 | 231 | 210/231 |
| dbo.var_pam_ldf | 3 | 6 | **6/6** |


## Categorization

### Fully covered (76)

Tables where every column has at least one row with a non-NULL value.

- dbo.antimicrobial_group
- dbo.bmird_multi_value_field_group
- dbo.confirmation_method
- dbo.confirmation_method_group
- dbo.covid_vaccination_datamart
- dbo.d_addl_risk
- dbo.d_addl_risk_group
- dbo.d_disease_site
- dbo.d_disease_site_group
- dbo.d_gt_12_reas
- dbo.d_gt_12_reas_group
- dbo.d_hc_prov_ty_3
- dbo.d_hc_prov_ty_3_group
- dbo.d_interview_note
- dbo.d_move_cntry
- dbo.d_move_cntry_group
- dbo.d_move_cnty
- dbo.d_move_cnty_group
- dbo.d_move_state
- dbo.d_move_state_group
- dbo.d_moved_where
- dbo.d_moved_where_group
- dbo.d_organization
- dbo.d_out_of_cntry
- dbo.d_out_of_cntry_group
- dbo.d_patient
- dbo.d_pcr_source
- dbo.d_pcr_source_group
- dbo.d_place
- dbo.d_provider
- dbo.d_rash_loc_gen
- dbo.d_rash_loc_gen_group
- dbo.d_smr_exam_ty
- dbo.d_smr_exam_ty_group
- dbo.d_tb_hiv
- dbo.d_vaccination
- dbo.event_metric
- dbo.event_metric_inc
- dbo.f_contact_record_case
- dbo.f_interview_case
- dbo.f_std_page_case
- dbo.f_tb_pam
- dbo.f_vaccination
- dbo.f_var_pam
- dbo.hep_multi_value_field_group
- dbo.inv_summ_datamart
- dbo.investigation
- dbo.l_investigation_repeat
- dbo.l_investigation_repeat_inc
- dbo.lab_result_comment
- dbo.lab_result_val
- dbo.lab_rpt_user_comment
- dbo.lab_test
- dbo.ldf_datamart_column_ref
- dbo.ldf_group
- dbo.ldf_vaccine_prevent_diseases
- dbo.morb_rpt_user_comment
- dbo.morbidity_report
- dbo.morbidity_report_datamart
- dbo.morbidity_report_event
- dbo.notification
- dbo.notification_event
- dbo.organization_ldf_group
- dbo.patient_ldf_group
- dbo.pertussis_suspected_source_grp
- dbo.pertussis_treatment_group
- dbo.provider_ldf_group
- dbo.rdb_date
- dbo.result_comment_group
- dbo.summary_case_group
- dbo.tb_pam_ldf
- dbo.test_result_grouping
- dbo.treatment
- dbo.treatment_event
- dbo.user_profile
- dbo.var_pam_ldf

### Partially covered (36)

Tables with rows but at least one column never populated. These are the
candidates for Tier 3 gap-driven coverage work.

- dbo.bmird_strep_pneumo_datamart
- dbo.case_count
- dbo.case_lab_datamart
- dbo.condition
- dbo.covid_case_datamart
- dbo.covid_contact_datamart
- dbo.covid_lab_celr_datamart
- dbo.covid_lab_datamart
- dbo.d_case_management
- dbo.d_contact_record
- dbo.d_interview
- dbo.d_inv_place_repeat
- dbo.d_investigation_repeat
- dbo.d_ldf_meta_data
- dbo.d_tb_pam
- dbo.d_var_pam
- dbo.etl_dq_log
- dbo.f_page_case
- dbo.hep100
- dbo.hepatitis_datamart
- dbo.inv_hiv
- dbo.job_flow_log
- dbo.l_inv_place_repeat
- dbo.lab100
- dbo.lab101
- dbo.lab_test_result
- dbo.ldf_data
- dbo.ldf_dimensional_data
- dbo.ldf_foodborne
- dbo.ldf_mumps
- dbo.ldf_tetanus
- dbo.std_hiv_datamart
- dbo.summary_report_case
- dbo.tb_datamart
- dbo.tb_hiv_datamart
- dbo.var_datamart

### Empty (5)

Tables that exist in RDB_MODERN but have zero rows after the merged
chain runs. Most are datamart-side fact tables that depend on Merge
contract step 9 (Datamart SPs — out of scope for v1).

- dbo.aggregate_report_datamart
- dbo.ldf_bmird
- dbo.ldf_hepatitis
- dbo.lookup_table_n_rept
- dbo.sr100

### Missing from live schema (1)

Tables listed in the Phase 0 catalog but absent from baseline 6.0.18.1.
These are catalog/schema drift findings — the SP body references them
but the live DDL doesn't include them.

- dbo.job_batch_rebuild_log

