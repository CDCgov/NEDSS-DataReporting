-- use rdb_modern;
IF EXISTS(SELECT 1 FROM NBS_ODSE.DBO.NBS_configuration WHERE config_key ='ENV' AND config_value ='UAT')
BEGIN
        USE [rdb_modern];
        PRINT 'Switched to database [rdb_modern]'
END
ELSE
BEGIN
        USE [rdb];
        PRINT 'Switched to database [rdb]';
END

--CNDE-2859: Evaluate performance and create index if needed.
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_addl_risk_group_key_uid' AND object_id = OBJECT_ID('dbo.nrt_addl_risk_group_key'))
BEGIN
CREATE INDEX  idx_nrt_addl_risk_group_key_uid  ON dbo.nrt_addl_risk_group_key (TB_PAM_UID)
END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_addl_risk_key_uid' AND object_id = OBJECT_ID('dbo.nrt_addl_risk_key'))
BEGIN
CREATE INDEX  idx_nrt_addl_risk_key_uid  ON dbo.nrt_addl_risk_key (TB_PAM_UID)
END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_antimicrobial_group_key_uid' AND object_id = OBJECT_ID('dbo.nrt_antimicrobial_group_key'))
BEGIN
CREATE INDEX  idx_nrt_antimicrobial_group_key_uid  ON dbo.nrt_antimicrobial_group_key (public_health_case_uid)
END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_antimicrobial_key_uid' AND object_id = OBJECT_ID('dbo.nrt_antimicrobial_key'))
BEGIN
CREATE INDEX  idx_nrt_antimicrobial_key_uid  ON dbo.nrt_antimicrobial_key (public_health_case_uid)
END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_bmird_multi_val_group_key_uid' AND object_id = OBJECT_ID('dbo.nrt_bmird_multi_val_group_key'))
BEGIN
CREATE INDEX  idx_nrt_bmird_multi_val_group_key_uid  ON dbo.nrt_bmird_multi_val_group_key (public_health_case_uid)
END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_bmird_multi_val_key_uid' AND object_id = OBJECT_ID('dbo.nrt_bmird_multi_val_key'))
BEGIN
CREATE INDEX  idx_nrt_bmird_multi_val_key_uid  ON dbo.nrt_bmird_multi_val_key (public_health_case_uid)
END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_case_management_key_uid' AND object_id = OBJECT_ID('dbo.nrt_case_management_key'))
BEGIN
CREATE INDEX  idx_nrt_case_management_key_uid  ON dbo.nrt_case_management_key (public_health_case_uid)
END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_contact_key_uid' AND object_id = OBJECT_ID('dbo.nrt_contact_key'))
BEGIN
CREATE INDEX  idx_nrt_contact_key_uid  ON dbo.nrt_contact_key (contact_uid)
END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_d_gt_12_reas_group_key_uid' AND object_id = OBJECT_ID('dbo.nrt_d_gt_12_reas_group_key'))
BEGIN
CREATE INDEX  idx_nrt_d_gt_12_reas_group_key_uid  ON dbo.nrt_d_gt_12_reas_group_key (TB_PAM_UID)
END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_d_gt_12_reas_key_uid' AND object_id = OBJECT_ID('dbo.nrt_d_gt_12_reas_key'))
BEGIN
CREATE INDEX  idx_nrt_d_gt_12_reas_key_uid  ON dbo.nrt_d_gt_12_reas_key (NBS_CASE_ANSWER_UID)
END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_d_hc_prov_ty_3_group_key_uid' AND object_id = OBJECT_ID('dbo.nrt_d_hc_prov_ty_3_group_key'))
BEGIN
CREATE INDEX  idx_nrt_d_hc_prov_ty_3_group_key_uid  ON dbo.nrt_d_hc_prov_ty_3_group_key (TB_PAM_UID)
END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_d_hc_prov_ty_3_key_uid' AND object_id = OBJECT_ID('dbo.nrt_d_hc_prov_ty_3_key'))
BEGIN
CREATE INDEX  idx_nrt_d_hc_prov_ty_3_key_uid  ON dbo.nrt_d_hc_prov_ty_3_key (NBS_CASE_ANSWER_UID)
END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_d_out_of_cntry_group_key_uid' AND object_id = OBJECT_ID('dbo.nrt_d_out_of_cntry_group_key'))
BEGIN
CREATE INDEX  idx_nrt_d_out_of_cntry_group_key_uid  ON dbo.nrt_d_out_of_cntry_group_key (TB_PAM_UID)
END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_d_out_of_cntry_key_uid' AND object_id = OBJECT_ID('dbo.nrt_d_out_of_cntry_key'))
BEGIN
CREATE INDEX  idx_nrt_d_out_of_cntry_key_uid  ON dbo.nrt_d_out_of_cntry_key (NBS_CASE_ANSWER_UID)
END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_d_pcr_source_group_key_uid' AND object_id = OBJECT_ID('dbo.nrt_d_pcr_source_group_key'))
BEGIN
CREATE INDEX  idx_nrt_d_pcr_source_group_key_uid  ON dbo.nrt_d_pcr_source_group_key (VAR_PAM_UID)
END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_d_pcr_source_key_uid' AND object_id = OBJECT_ID('dbo.nrt_d_pcr_source_key'))
BEGIN
CREATE INDEX  idx_nrt_d_pcr_source_key_uid  ON dbo.nrt_d_pcr_source_key (NBS_CASE_ANSWER_UID)
END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_d_smr_exam_ty_group_key_uid' AND object_id = OBJECT_ID('dbo.nrt_d_smr_exam_ty_group_key'))
BEGIN
CREATE INDEX  idx_nrt_d_smr_exam_ty_group_key_uid  ON dbo.nrt_d_smr_exam_ty_group_key (TB_PAM_UID)
END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_d_smr_exam_ty_key_uid' AND object_id = OBJECT_ID('dbo.nrt_d_smr_exam_ty_key'))
BEGIN
CREATE INDEX  idx_nrt_d_smr_exam_ty_key_uid  ON dbo.nrt_d_smr_exam_ty_key (NBS_CASE_ANSWER_UID)
END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_d_tb_hiv_key_uid' AND object_id = OBJECT_ID('dbo.nrt_d_tb_hiv_key'))
BEGIN
CREATE INDEX  idx_nrt_d_tb_hiv_key_uid  ON dbo.nrt_d_tb_hiv_key (TB_PAM_UID)
END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_d_tb_pam_key_uid' AND object_id = OBJECT_ID('dbo.nrt_d_tb_pam_key'))
BEGIN
CREATE INDEX  idx_nrt_d_tb_pam_key_uid  ON dbo.nrt_d_tb_pam_key (TB_PAM_UID)
END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_disease_site_group_key_uid' AND object_id = OBJECT_ID('dbo.nrt_disease_site_group_key'))
BEGIN
CREATE INDEX  idx_nrt_disease_site_group_key_uid  ON dbo.nrt_disease_site_group_key (TB_PAM_UID)
END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_disease_site_key_uid' AND object_id = OBJECT_ID('dbo.nrt_disease_site_key'))
BEGIN
CREATE INDEX  idx_nrt_disease_site_key_uid  ON dbo.nrt_disease_site_key (NBS_Case_Answer_UID)
END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_hepatitis_case_group_key_uid' AND object_id = OBJECT_ID('dbo.nrt_hepatitis_case_group_key'))
BEGIN
CREATE INDEX  idx_nrt_hepatitis_case_group_key_uid  ON dbo.nrt_hepatitis_case_group_key (public_health_case_uid)
END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_hepatitis_case_multi_val_key_uid' AND object_id = OBJECT_ID('dbo.nrt_hepatitis_case_multi_val_key'))
BEGIN
CREATE INDEX  idx_nrt_hepatitis_case_multi_val_key_uid  ON dbo.nrt_hepatitis_case_multi_val_key (public_health_case_uid)
END

--CNDE-2859: Evaluate performance and create index if needed.
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_interview_key_uid' AND object_id = OBJECT_ID('dbo.nrt_interview_key'))
BEGIN
CREATE INDEX  idx_nrt_interview_key_uid  ON dbo.nrt_interview_key (interview_uid)
END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_interview_note_key_uid' AND object_id = OBJECT_ID('dbo.nrt_interview_note_key'))
BEGIN
CREATE INDEX  idx_nrt_interview_note_key_uid  ON dbo.nrt_interview_note_key (nbs_answer_uid)
END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_investigation_key_uid' AND object_id = OBJECT_ID('dbo.nrt_investigation_key'))
BEGIN
CREATE INDEX  idx_nrt_investigation_key_uid  ON dbo.nrt_investigation_key (case_uid)
END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_lab_result_comment_key_uid' AND object_id = OBJECT_ID('dbo.nrt_lab_result_comment_key'))
BEGIN
CREATE INDEX  idx_nrt_lab_result_comment_key_uid  ON dbo.nrt_lab_result_comment_key (LAB_RESULT_COMMENT_UID)
END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_lab_rpt_user_comment_key_uid' AND object_id = OBJECT_ID('dbo.nrt_lab_rpt_user_comment_key'))
BEGIN
CREATE INDEX  idx_nrt_lab_rpt_user_comment_key_uid  ON dbo.nrt_lab_rpt_user_comment_key (LAB_RPT_USER_COMMENT_UID)
END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_lab_test_key_uid' AND object_id = OBJECT_ID('dbo.nrt_lab_test_key'))
BEGIN
CREATE INDEX  idx_nrt_lab_test_key_uid  ON dbo.nrt_lab_test_key (LAB_TEST_UID)
END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_lab_test_result_group_key_uid' AND object_id = OBJECT_ID('dbo.nrt_lab_test_result_group_key'))
BEGIN
CREATE INDEX  idx_nrt_lab_test_result_group_key_uid  ON dbo.nrt_lab_test_result_group_key (LAB_TEST_UID)
END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_ldf_data_key_uid' AND object_id = OBJECT_ID('dbo.nrt_ldf_data_key'))
BEGIN
CREATE INDEX  idx_nrt_ldf_data_key_uid  ON dbo.nrt_ldf_data_key (business_object_uid)
END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_ldf_group_key_uid' AND object_id = OBJECT_ID('dbo.nrt_ldf_group_key'))
BEGIN
CREATE INDEX  idx_nrt_ldf_group_key_uid  ON dbo.nrt_ldf_group_key (business_object_uid)
END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_move_cntry_group_key_uid' AND object_id = OBJECT_ID('dbo.nrt_move_cntry_group_key'))
BEGIN
CREATE INDEX  idx_nrt_move_cntry_group_key_uid  ON dbo.nrt_move_cntry_group_key (TB_PAM_UID)
END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_move_cntry_key_uid' AND object_id = OBJECT_ID('dbo.nrt_move_cntry_key'))
BEGIN
CREATE INDEX  idx_nrt_move_cntry_key_uid  ON dbo.nrt_move_cntry_key (TB_PAM_UID)
END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_move_cnty_group_key_uid' AND object_id = OBJECT_ID('dbo.nrt_move_cnty_group_key'))
BEGIN
CREATE INDEX  idx_nrt_move_cnty_group_key_uid  ON dbo.nrt_move_cnty_group_key (TB_PAM_UID)
END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_move_cnty_key_uid' AND object_id = OBJECT_ID('dbo.nrt_move_cnty_key'))
BEGIN
CREATE INDEX  idx_nrt_move_cnty_key_uid  ON dbo.nrt_move_cnty_key (TB_PAM_UID)
END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_move_state_group_key_uid' AND object_id = OBJECT_ID('dbo.nrt_move_state_group_key'))
BEGIN
CREATE INDEX  idx_nrt_move_state_group_key_uid  ON dbo.nrt_move_state_group_key (TB_PAM_UID)
END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_move_state_key_uid' AND object_id = OBJECT_ID('dbo.nrt_move_state_key'))
BEGIN
CREATE INDEX  idx_nrt_move_state_key_uid  ON dbo.nrt_move_state_key (TB_PAM_UID)
END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_moved_where_group_key_uid' AND object_id = OBJECT_ID('dbo.nrt_moved_where_group_key'))
BEGIN
CREATE INDEX  idx_nrt_moved_where_group_key_uid  ON dbo.nrt_moved_where_group_key (TB_PAM_UID)
END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_moved_where_key_uid' AND object_id = OBJECT_ID('dbo.nrt_moved_where_key'))
BEGIN
CREATE INDEX  idx_nrt_moved_where_key_uid  ON dbo.nrt_moved_where_key (TB_PAM_UID)
END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_notification_key_uid' AND object_id = OBJECT_ID('dbo.nrt_notification_key'))
BEGIN
CREATE INDEX  idx_nrt_notification_key_uid  ON dbo.nrt_notification_key (notification_uid)
END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_organization_key_uid' AND object_id = OBJECT_ID('dbo.nrt_organization_key'))
BEGIN
CREATE INDEX  idx_nrt_organization_key_uid  ON dbo.nrt_organization_key (organization_uid)
END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_patient_key_uid' AND object_id = OBJECT_ID('dbo.nrt_patient_key'))
BEGIN
CREATE INDEX  idx_nrt_patient_key_uid  ON dbo.nrt_patient_key (patient_uid)
END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_pertussis_source_group_key_uid' AND object_id = OBJECT_ID('dbo.nrt_pertussis_source_group_key'))
BEGIN
CREATE INDEX  idx_nrt_pertussis_source_group_key_uid  ON dbo.nrt_pertussis_source_group_key (public_health_case_uid)
END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_pertussis_source_key_uid' AND object_id = OBJECT_ID('dbo.nrt_pertussis_source_key'))
BEGIN
CREATE INDEX  idx_nrt_pertussis_source_key_uid  ON dbo.nrt_pertussis_source_key (public_health_case_uid)
END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_pertussis_treatment_group_key_uid' AND object_id = OBJECT_ID('dbo.nrt_pertussis_treatment_group_key'))
BEGIN
CREATE INDEX  idx_nrt_pertussis_treatment_group_key_uid  ON dbo.nrt_pertussis_treatment_group_key (public_health_case_uid)
END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_pertussis_treatment_key_uid' AND object_id = OBJECT_ID('dbo.nrt_pertussis_treatment_key'))
BEGIN
CREATE INDEX  idx_nrt_pertussis_treatment_key_uid  ON dbo.nrt_pertussis_treatment_key (public_health_case_uid)
END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_place_key_uid' AND object_id = OBJECT_ID('dbo.nrt_place_key'))
BEGIN
CREATE INDEX  idx_nrt_place_key_uid  ON dbo.nrt_place_key (place_uid)
END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_provider_key_uid' AND object_id = OBJECT_ID('dbo.nrt_provider_key'))
BEGIN
CREATE INDEX  idx_nrt_provider_key_uid  ON dbo.nrt_provider_key (provider_uid)
END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_rash_loc_gen_group_key_uid' AND object_id = OBJECT_ID('dbo.nrt_rash_loc_gen_group_key'))
BEGIN
CREATE INDEX  idx_nrt_rash_loc_gen_group_key_uid  ON dbo.nrt_rash_loc_gen_group_key (VAR_PAM_UID)
END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_rash_loc_gen_key_uid' AND object_id = OBJECT_ID('dbo.nrt_rash_loc_gen_key'))
BEGIN
CREATE INDEX  idx_nrt_rash_loc_gen_key_uid  ON dbo.nrt_rash_loc_gen_key (VAR_PAM_UID)
END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_summary_case_group_key_uid' AND object_id = OBJECT_ID('dbo.nrt_summary_case_group_key'))
BEGIN
CREATE INDEX  idx_nrt_summary_case_group_key_uid  ON dbo.nrt_summary_case_group_key (public_health_case_uid)
END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_treatment_key_uid' AND object_id = OBJECT_ID('dbo.nrt_treatment_key'))
BEGIN
CREATE INDEX  idx_nrt_treatment_key_uid  ON dbo.nrt_treatment_key (treatment_uid)
END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_vaccination_key_uid' AND object_id = OBJECT_ID('dbo.nrt_vaccination_key'))
BEGIN
CREATE INDEX  idx_nrt_vaccination_key_uid  ON dbo.nrt_vaccination_key (vaccination_uid)
END