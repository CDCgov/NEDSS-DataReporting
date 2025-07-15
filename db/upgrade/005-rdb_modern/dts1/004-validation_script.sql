/*
    This file is a DTS1 ONLY Script and should NOT be checked into the Liquibase Changelog
*/

select * from (
select 'nrt_organization_key' as tbl_name ,ident_current('nrt_organization_key') as current_seed, max(organization_key) as max_value from d_organization union
select 'nrt_patient_key' as tbl_name ,ident_current('nrt_patient_key') as current_seed, max(patient_key) as max_value from d_patient union
select 'nrt_provider_key' as tbl_name ,ident_current('nrt_provider_key') as current_seed, max(provider_key) as max_value from d_provider union
select 'nrt_investigation_key' as tbl_name ,ident_current('nrt_investigation_key') as current_seed, max(investigation_key) as max_value from investigation union
select 'nrt_ldf_data_key' as tbl_name ,ident_current('nrt_ldf_data_key') as current_seed, max(ldf_data_key) as max_value from ldf_data union
select 'nrt_ldf_group_key' as tbl_name ,ident_current('nrt_ldf_group_key') as current_seed, max(ldf_group_key) as max_value from ldf_group union
select 'nrt_confirmation_method_key' as tbl_name ,ident_current('nrt_confirmation_method_key') as current_seed, max(confirmation_method_key) as max_value from confirmation_method union
select 'nrt_notification_key' as tbl_name ,ident_current('nrt_notification_key') as current_seed, max(notification_key) as max_value from notification union
select 'nrt_lab_test_key' as tbl_name ,ident_current('nrt_lab_test_key') as current_seed, max(lab_test_key) as max_value from lab_test union
select 'nrt_interview_key' as tbl_name ,ident_current('nrt_interview_key') as current_seed, max(d_interview_key) as max_value from d_interview union
select 'nrt_interview_note_key' as tbl_name ,ident_current('nrt_interview_note_key') as current_seed, max(d_interview_note_key) as max_value from d_interview_note union
select 'nrt_treatment_key' as tbl_name ,ident_current('nrt_treatment_key') as current_seed, max(treatment_key) as max_value from treatment union
select 'nrt_vaccination_key' as tbl_name ,ident_current('nrt_vaccination_key') as current_seed, max(d_vaccination_key) as max_value from d_vaccination union
select 'nrt_case_management_key' as tbl_name ,ident_current('nrt_case_management_key') as current_seed, max(d_case_management_key) as max_value from d_case_management union
select 'nrt_contact_key' as tbl_name ,ident_current('nrt_contact_key') as current_seed, max(d_contact_record_key) as max_value from d_contact_record union
select 'nrt_place_key' as tbl_name ,ident_current('nrt_place_key') as current_seed, max(place_key) as max_value from d_place union
select 'nrt_d_tb_pam_key' as tbl_name ,ident_current('nrt_d_tb_pam_key') as current_seed, max(d_tb_pam_key) as max_value from d_tb_pam union
select 'nrt_d_tb_hiv_key' as tbl_name ,ident_current('nrt_d_tb_hiv_key') as current_seed, max(d_tb_hiv_key) as max_value from d_tb_hiv union
select 'nrt_addl_risk_group_key' as tbl_name ,ident_current('nrt_addl_risk_group_key') as current_seed, max(d_addl_risk_group_key) as max_value from d_addl_risk_group union
select 'nrt_addl_risk_key' as tbl_name ,ident_current('nrt_addl_risk_key') as current_seed, max(d_addl_risk_key) as max_value from d_addl_risk union
select 'nrt_disease_site_group_key' as tbl_name ,ident_current('nrt_disease_site_group_key') as current_seed, max(d_disease_site_group_key) as max_value from d_disease_site_group union
select 'nrt_disease_site_key' as tbl_name ,ident_current('nrt_disease_site_key') as current_seed, max(d_disease_site_key) as max_value from d_disease_site union
select 'nrt_move_cntry_group_key' as tbl_name ,ident_current('nrt_move_cntry_group_key') as current_seed, max(d_move_cntry_group_key) as max_value from d_move_cntry_group union
select 'nrt_move_cntry_key' as tbl_name ,ident_current('nrt_move_cntry_key') as current_seed, max(d_move_cntry_key) as max_value from d_move_cntry union
select 'nrt_move_cnty_group_key' as tbl_name ,ident_current('nrt_move_cnty_group_key') as current_seed, max(d_move_cnty_group_key) as max_value from d_move_cnty_group union
select 'nrt_move_cnty_key' as tbl_name ,ident_current('nrt_move_cnty_key') as current_seed, max(d_move_cnty_key) as max_value from d_move_cnty union
select 'nrt_move_state_group_key' as tbl_name ,ident_current('nrt_move_state_group_key') as current_seed, max(d_move_state_group_key) as max_value from d_move_state_group union
select 'nrt_move_state_key' as tbl_name ,ident_current('nrt_move_state_key') as current_seed, max(d_move_state_key) as max_value from d_move_state union
select 'nrt_moved_where_group_key' as tbl_name ,ident_current('nrt_moved_where_group_key') as current_seed, max(d_moved_where_group_key) as max_value from d_moved_where_group union
select 'nrt_moved_where_key' as tbl_name ,ident_current('nrt_moved_where_key') as current_seed, max(d_moved_where_key) as max_value from d_moved_where union
select 'nrt_d_gt_12_reas_group_key' as tbl_name ,ident_current('nrt_d_gt_12_reas_group_key') as current_seed, max(d_gt_12_reas_group_key) as max_value from d_gt_12_reas_group union
select 'nrt_d_gt_12_reas_key' as tbl_name ,ident_current('nrt_d_gt_12_reas_key') as current_seed, max(d_gt_12_reas_key) as max_value from d_gt_12_reas union
select 'nrt_d_hc_prov_ty_3_group_key' as tbl_name ,ident_current('nrt_d_hc_prov_ty_3_group_key') as current_seed, max(d_hc_prov_ty_3_group_key) as max_value from d_hc_prov_ty_3_group union
select 'nrt_d_hc_prov_ty_3_key' as tbl_name ,ident_current('nrt_d_hc_prov_ty_3_key') as current_seed, max(d_hc_prov_ty_3_key) as max_value from d_hc_prov_ty_3 union
select 'nrt_d_out_of_cntry_group_key' as tbl_name ,ident_current('nrt_d_out_of_cntry_group_key') as current_seed, max(d_out_of_cntry_group_key) as max_value from d_out_of_cntry_group union
select 'nrt_d_out_of_cntry_key' as tbl_name ,ident_current('nrt_d_out_of_cntry_key') as current_seed, max(d_out_of_cntry_key) as max_value from d_out_of_cntry union
select 'nrt_d_smr_exam_ty_group_key' as tbl_name ,ident_current('nrt_d_smr_exam_ty_group_key') as current_seed, max(d_smr_exam_ty_group_key) as max_value from d_smr_exam_ty_group union
select 'nrt_d_smr_exam_ty_key' as tbl_name ,ident_current('nrt_d_smr_exam_ty_key') as current_seed, max(d_smr_exam_ty_key) as max_value from d_smr_exam_ty union
select 'nrt_var_pam_key' as tbl_name ,ident_current('nrt_var_pam_key') as current_seed, max(d_var_pam_key) as max_value from d_var_pam union
select 'nrt_rash_loc_gen_group_key' as tbl_name ,ident_current('nrt_rash_loc_gen_group_key') as current_seed, max(d_rash_loc_gen_group_key) as max_value from d_rash_loc_gen_group union
select 'nrt_rash_loc_gen_key' as tbl_name ,ident_current('nrt_rash_loc_gen_key') as current_seed, max(d_rash_loc_gen_key) as max_value from d_rash_loc_gen union
select 'nrt_d_pcr_source_group_key' as tbl_name ,ident_current('nrt_d_pcr_source_group_key') as current_seed, max(d_pcr_source_group_key) as max_value from d_pcr_source_group union
select 'nrt_d_pcr_source_key' as tbl_name ,ident_current('nrt_d_pcr_source_key') as current_seed, max(d_pcr_source_key) as max_value from d_pcr_source union
select 'nrt_hepatitis_case_group_key' as tbl_name ,ident_current('nrt_hepatitis_case_group_key') as current_seed, max(HEP_MULTI_VAL_GRP_KEY) as max_value from hep_multi_value_field_group union
select 'nrt_hepatitis_case_multi_val_key' as tbl_name ,ident_current('nrt_hepatitis_case_multi_val_key') as current_seed, max(HEP_MULTI_VAL_DATA_KEY) as max_value from hep_multi_value_field union
select 'nrt_pertussis_source_group_key' as tbl_name ,ident_current('nrt_pertussis_source_group_key') as current_seed, max(PERTUSSIS_SUSPECT_SRC_GRP_KEY) as max_value from PERTUSSIS_SUSPECTED_SOURCE_GRP union
select 'nrt_pertussis_source_key' as tbl_name ,ident_current('nrt_pertussis_source_key') as current_seed, max(PERTUSSIS_SUSPECT_SRC_FLD_KEY) as max_value from PERTUSSIS_SUSPECTED_SOURCE_FLD union
select 'nrt_pertussis_treatment_group_key' as tbl_name ,ident_current('nrt_pertussis_treatment_group_key') as current_seed, max(PERTUSSIS_TREATMENT_GRP_KEY) as max_value from PERTUSSIS_TREATMENT_GROUP union
select 'nrt_pertussis_treatment_key' as tbl_name ,ident_current('nrt_pertussis_treatment_key') as current_seed, max(PERTUSSIS_TREATMENT_FLD_KEY) as max_value from PERTUSSIS_TREATMENT_FIELD union
select 'nrt_antimicrobial_group_key' as tbl_name ,ident_current('nrt_antimicrobial_group_key') as current_seed, max(ANTIMICROBIAL_GRP_KEY) as max_value from ANTIMICROBIAL_GROUP union
select 'nrt_antimicrobial_key' as tbl_name ,ident_current('nrt_antimicrobial_key') as current_seed, max(ANTIMICROBIAL_KEY) as max_value from ANTIMICROBIAL union
select 'nrt_bmird_multi_val_group_key' as tbl_name ,ident_current('nrt_bmird_multi_val_group_key') as current_seed, max(BMIRD_MULTI_VAL_GRP_KEY) as max_value from BMIRD_MULTI_VALUE_FIELD_GROUP union
select 'nrt_bmird_multi_val_key' as tbl_name ,ident_current('nrt_bmird_multi_val_key') as current_seed, max(BMIRD_MULTI_VAL_FIELD_KEY) as max_value from BMIRD_MULTI_VALUE_FIELD union
select 'nrt_summary_case_group_key' as tbl_name ,ident_current('nrt_summary_case_group_key') as current_seed, max(summary_case_src_key) as max_value from SUMMARY_CASE_GROUP union
select 'nrt_lab_test_key' as tbl_name ,ident_current('nrt_lab_test_key') as current_seed, max(lab_test_key) as max_value from lab_test union
select 'nrt_lab_rpt_user_comment_key' as tbl_name ,ident_current('nrt_lab_rpt_user_comment_key') as current_seed, max(USER_COMMENT_KEY) as max_value from lab_rpt_user_comment union
select 'nrt_lab_result_comment_key' as tbl_name ,ident_current('nrt_lab_result_comment_key') as current_seed, max(LAB_RESULT_COMMENT_KEY) as max_value from lab_result_comment union
select 'nrt_lab_test_result_group_key' as tbl_name ,ident_current('nrt_lab_test_result_group_key') as current_seed, max(TEST_RESULT_GRP_KEY) as max_value from TEST_RESULT_GROUPING
) as tbl where current_seed < max_value