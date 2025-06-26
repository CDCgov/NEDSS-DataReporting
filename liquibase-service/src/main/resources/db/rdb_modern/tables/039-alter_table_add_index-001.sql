IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_phc_id' AND object_id = OBJECT_ID('dbo.nrt_investigation_observation'))
    BEGIN
        CREATE INDEX idx_phc_id ON dbo.nrt_investigation_observation (public_health_case_uid);
    END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_phc_id_obs_id_branch_id' AND object_id = OBJECT_ID('dbo.nrt_investigation_observation'))
    BEGIN
        CREATE INDEX idx_phc_id_obs_id_branch_id ON dbo.nrt_investigation_observation (public_health_case_uid, observation_id, branch_id);
    END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_CONTACT_UID' AND object_id = OBJECT_ID('dbo.nrt_contact'))
    BEGIN
        CREATE INDEX idx_CONTACT_UID ON dbo.nrt_contact (CONTACT_UID);
    END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_contact_uid' AND object_id = OBJECT_ID('dbo.nrt_contact_answer'))
    BEGIN
        CREATE INDEX idx_contact_uid ON dbo.nrt_contact_answer (contact_uid);
    END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_contact_uid_rdb_column' AND object_id = OBJECT_ID('dbo.nrt_contact_answer'))
    BEGIN
        CREATE INDEX idx_contact_uid_rdb_column ON dbo.nrt_contact_answer (contact_uid,rdb_column_nm);
    END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_interview_uid_rdb_column' AND object_id = OBJECT_ID('dbo.nrt_interview_answer'))
    BEGIN
        CREATE INDEX idx_interview_uid_rdb_column ON dbo.nrt_interview_answer (interview_uid, rdb_column_nm);
    END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_interview_uid' AND object_id = OBJECT_ID('dbo.nrt_interview_answer'))
    BEGIN
        CREATE INDEX idx_interview_uid ON dbo.nrt_interview_answer (interview_uid);
    END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_interview_uid' AND object_id = OBJECT_ID('dbo.nrt_interview_note'))
    BEGIN
        CREATE INDEX idx_interview_uid ON dbo.nrt_interview_note (interview_uid);
    END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_phc_uid' AND object_id = OBJECT_ID('dbo.nrt_investigation_case_management'))
    BEGIN
        CREATE INDEX idx_phc_uid ON dbo.nrt_investigation_case_management (public_health_case_uid);
    END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_phc_uid_case_mgmt_uid' AND object_id = OBJECT_ID('dbo.nrt_investigation_case_management'))
    BEGIN
        CREATE INDEX idx_phc_uid_case_mgmt_uid ON dbo.nrt_investigation_case_management (public_health_case_uid, case_management_uid);
    END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_inv_conf_phc_uid' AND object_id = OBJECT_ID('dbo.nrt_investigation_confirmation'))
    BEGIN
        CREATE INDEX idx_inv_conf_phc_uid ON dbo.nrt_investigation_confirmation (public_health_case_uid);
    END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_inv_notf_phc_uid' AND object_id = OBJECT_ID('dbo.nrt_investigation_notification'))
    BEGIN
        CREATE INDEX idx_nrt_inv_notf_phc_uid ON dbo.nrt_investigation_notification (public_health_case_uid);
    END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_inv_notf_phc_uid_act_uid' AND object_id = OBJECT_ID('dbo.nrt_investigation_notification'))
    BEGIN
        CREATE INDEX idx_nrt_inv_notf_phc_uid_act_uid ON dbo.nrt_investigation_notification (public_health_case_uid, source_act_uid);
    END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_ldf_data_ldf_uid' AND object_id = OBJECT_ID('dbo.nrt_ldf_data'))
    BEGIN
        CREATE INDEX idx_nrt_ldf_data_ldf_uid ON dbo.nrt_ldf_data (ldf_uid);
    END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_obs_coded_obs_uid' AND object_id = OBJECT_ID('dbo.nrt_observation_coded'))
    BEGIN
        CREATE INDEX idx_nrt_obs_coded_obs_uid ON dbo.nrt_observation_coded (observation_uid);
    END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_obs_date_obs_uid' AND object_id = OBJECT_ID('dbo.nrt_observation_date'))
    BEGIN
        CREATE INDEX idx_nrt_obs_date_obs_uid ON dbo.nrt_observation_date (observation_uid);
    END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_obs_edx_uid' AND object_id = OBJECT_ID('dbo.nrt_observation_edx'))
    BEGIN
        CREATE INDEX idx_nrt_obs_edx_uid ON dbo.nrt_observation_edx (edx_document_uid);
    END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_obs_material_act_uid' AND object_id = OBJECT_ID('dbo.nrt_observation_material'))
    BEGIN
        CREATE INDEX idx_nrt_obs_material_act_uid ON dbo.nrt_observation_material (act_uid);
    END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_obs_material_material_id' AND object_id = OBJECT_ID('dbo.nrt_observation_material'))
    BEGIN
        CREATE INDEX idx_nrt_obs_material_material_id ON dbo.nrt_observation_material (material_id);
    END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_obs_material_act_uid_material_id' AND object_id = OBJECT_ID('dbo.nrt_observation_material'))
    BEGIN
        CREATE INDEX idx_nrt_obs_material_act_uid_material_id ON dbo.nrt_observation_material (act_uid, material_id);
    END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_obs_numeric_obs_uid' AND object_id = OBJECT_ID('dbo.nrt_observation_numeric'))
    BEGIN
        CREATE INDEX idx_nrt_obs_numeric_obs_uid ON dbo.nrt_observation_numeric (observation_uid);
    END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_obs_reason_obs_uid' AND object_id = OBJECT_ID('dbo.nrt_observation_reason'))
    BEGIN
        CREATE INDEX idx_nrt_obs_reason_obs_uid ON dbo.nrt_observation_reason (observation_uid);
    END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_obs_txt_obs_uid' AND object_id = OBJECT_ID('dbo.nrt_observation_txt'))
    BEGIN
        CREATE INDEX idx_nrt_obs_txt_obs_uid ON dbo.nrt_observation_txt (observation_uid);
    END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_org_organization_uid' AND object_id = OBJECT_ID('dbo.nrt_organization'))
    BEGIN
        CREATE INDEX idx_nrt_org_organization_uid ON dbo.nrt_organization (organization_uid);
    END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_page_case_answer_nbs_case_answer_uid_question_uid' AND object_id = OBJECT_ID('dbo.nrt_page_case_answer'))
    BEGIN
        CREATE INDEX idx_nrt_page_case_answer_nbs_case_answer_uid_question_uid ON dbo.nrt_page_case_answer (nbs_case_answer_uid, nbs_question_uid);
    END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_page_case_answer_nbs_case_answer_uid' AND object_id = OBJECT_ID('dbo.nrt_page_case_answer'))
    BEGIN
        CREATE INDEX idx_nrt_page_case_answer_nbs_case_answer_uid ON dbo.nrt_page_case_answer (nbs_case_answer_uid);
    END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_place_tele_place_uid' AND object_id = OBJECT_ID('dbo.nrt_place_tele'))
    BEGIN
        CREATE INDEX idx_nrt_place_tele_place_uid ON dbo.nrt_place_tele (place_uid);
    END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_obs_coded_obs_uid_code' AND object_id = OBJECT_ID('dbo.nrt_observation_coded'))
    BEGIN
        CREATE INDEX idx_nrt_obs_coded_obs_uid_code ON dbo.nrt_observation_coded (observation_uid, ovc_code);
    END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_inv_notf_notf_uid' AND object_id = OBJECT_ID('dbo.nrt_investigation_notification'))
    BEGIN
        CREATE INDEX idx_nrt_inv_notf_notf_uid ON dbo.nrt_investigation_notification (notification_uid);
    END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_page_case_answer_act_uid' AND object_id = OBJECT_ID('dbo.nrt_page_case_answer'))
    BEGIN
        CREATE INDEX idx_nrt_page_case_answer_act_uid ON dbo.nrt_page_case_answer (act_uid);
    END

--CNDE-2859: Evaluate performance and create index if needed
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_addl_risk_group_key_uid' AND object_id = OBJECT_ID('dbo.nrt_addl_risk_group_key'))
   BEGIN
        CREATE INDEX  idx_nrt_addl_risk_group_key_uid  ON dbo.nrt_addl_risk_group_key (TB_PAM_UID)
   END

IFNOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_addl_risk_key_uid' AND object_id = OBJECT_ID('dbo.nrt_addl_risk_key'))
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