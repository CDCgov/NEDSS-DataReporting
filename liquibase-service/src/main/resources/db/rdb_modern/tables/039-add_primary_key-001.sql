

IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND parent_object_id = OBJECT_ID('dbo.nrt_case_management_key'))
    BEGIN
        ALTER TABLE dbo.nrt_case_management_key
            ADD CONSTRAINT nrt_case_management_key_pk PRIMARY KEY (d_case_management_key);
    END

IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND parent_object_id = OBJECT_ID('dbo.nrt_confirmation_method_key'))
    BEGIN
        ALTER TABLE dbo.nrt_confirmation_method_key
            ADD CONSTRAINT nrt_confirmation_method_key_pk PRIMARY KEY (d_confirmation_method_key);
    END

IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND parent_object_id = OBJECT_ID('dbo.nrt_contact_key'))
    BEGIN
        ALTER TABLE dbo.nrt_contact_key
            ADD CONSTRAINT pk_d_contact_record_key PRIMARY KEY (d_contact_record_key);
    END

IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND parent_object_id = OBJECT_ID('dbo.nrt_interview_key'))
    BEGIN
        ALTER TABLE dbo.nrt_interview_key
            ADD CONSTRAINT pk_d_interview_key PRIMARY KEY (d_interview_key);
    END

IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND parent_object_id = OBJECT_ID('dbo.nrt_interview_note_key'))
    BEGIN
        ALTER TABLE dbo.nrt_interview_note_key
            ADD CONSTRAINT pk_d_interview_note_key PRIMARY KEY (d_interview_note_key);
    END

IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND parent_object_id = OBJECT_ID('dbo.nrt_ldf_data_key'))
    BEGIN
        ALTER TABLE dbo.nrt_ldf_data_key
            ADD CONSTRAINT pk_ldf_data_key PRIMARY KEY (d_ldf_data_key);
    END

IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND parent_object_id = OBJECT_ID('dbo.nrt_ldf_group_key'))
    BEGIN
        ALTER TABLE dbo.nrt_ldf_group_key
            ADD CONSTRAINT pk_ldf_group_key PRIMARY KEY (d_ldf_group_key);
    END

IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND parent_object_id = OBJECT_ID('dbo.nrt_notification_key'))
    BEGIN
        ALTER TABLE dbo.nrt_notification_key
            ADD CONSTRAINT pk_notification_key PRIMARY KEY (d_notification_key);
    END

IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND parent_object_id = OBJECT_ID('dbo.nrt_organization_key'))
    BEGIN
        ALTER TABLE dbo.nrt_organization_key
            ADD CONSTRAINT nrt_organization_key_pk PRIMARY KEY (d_organization_key);
    END

IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND parent_object_id = OBJECT_ID('dbo.nrt_patient_key'))
    BEGIN
        ALTER TABLE dbo.nrt_patient_key
            ADD CONSTRAINT pk_d_patient_key PRIMARY KEY (d_patient_key);
    END

IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND parent_object_id = OBJECT_ID('dbo.nrt_place_key'))
    BEGIN
        ALTER TABLE dbo.nrt_place_key
            ADD CONSTRAINT pk_d_place_key_pk PRIMARY KEY (d_place_key);
    END

IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND parent_object_id = OBJECT_ID('dbo.nrt_provider_key'))
    BEGIN
        ALTER TABLE dbo.nrt_provider_key
            ADD CONSTRAINT pk_d_provider_key PRIMARY KEY (d_provider_key);
    END

/*CNDE-2859: Add primary keys for nrt key tables*/

IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND object_id = OBJECT_ID('nrt_addl_risk_group_key'))
    BEGIN
        ALTER TABLE nrt_addl_risk_group_key
            ADD CONSTRAINT pk_nrt_addl_risk_group_key PRIMARY KEY (D_ADDL_RISK_GROUP_KEY, TB_PAM_UID);
    END
IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND object_id = OBJECT_ID('nrt_addl_risk_key'))
    BEGIN
        ALTER TABLE nrt_addl_risk_key
            ADD CONSTRAINT pk_nrt_addl_risk_key PRIMARY KEY (D_ADDL_RISK_KEY, TB_PAM_UID, NBS_Case_Answer_UID);
    END
IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND object_id = OBJECT_ID('nrt_antimicrobial_group_key'))
    BEGIN
        ALTER TABLE nrt_antimicrobial_group_key
            ADD CONSTRAINT pk_nrt_antimicrobial_group_key PRIMARY KEY (ANTIMICROBIAL_GRP_KEY);
    END
IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND object_id = OBJECT_ID('nrt_antimicrobial_key'))
    BEGIN
        ALTER TABLE nrt_antimicrobial_key
            ADD CONSTRAINT pk_nrt_antimicrobial_key PRIMARY KEY (ANTIMICROBIAL_KEY, ANTIMICROBIAL_GRP_KEY);
    END
IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND object_id = OBJECT_ID('nrt_bmird_multi_val_group_key'))
    BEGIN
        ALTER TABLE nrt_bmird_multi_val_group_key
            ADD CONSTRAINT pk_nrt_bmird_multi_val_group_key PRIMARY KEY (BMIRD_MULTI_VAL_GRP_KEY);
    END
IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND object_id = OBJECT_ID('nrt_bmird_multi_val_key'))
    BEGIN
        ALTER TABLE nrt_bmird_multi_val_key
            ADD CONSTRAINT pk_nrt_bmird_multi_val_key PRIMARY KEY (BMIRD_MULTI_VAL_FIELD_KEY, BMIRD_MULTI_VAL_GRP_KEY);
    END
IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND object_id = OBJECT_ID('nrt_condition_key'))
    BEGIN
        ALTER TABLE nrt_condition_key
            ADD CONSTRAINT pk_nrt_condition_key PRIMARY KEY (CONDITION_KEY);
    END
IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND object_id = OBJECT_ID('nrt_contact_answer'))
    BEGIN
        ALTER TABLE nrt_contact_answer
            ADD CONSTRAINT pk_nrt_contact_answer PRIMARY KEY (contact_uid);
    END
IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND object_id = OBJECT_ID('nrt_disease_site_group_key'))
    BEGIN
        ALTER TABLE nrt_disease_site_group_key
            ADD CONSTRAINT pk_nrt_disease_site_group_key PRIMARY KEY (D_DISEASE_SITE_GROUP_KEY, TB_PAM_UID);
    END
IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND object_id = OBJECT_ID('nrt_disease_site_key'))
    BEGIN
        ALTER TABLE nrt_disease_site_key
            ADD CONSTRAINT pk_nrt_disease_site_key PRIMARY KEY (D_DISEASE_SITE_KEY, NBS_Case_Answer_UID, TB_PAM_UID);
    END
IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND object_id = OBJECT_ID('nrt_hepatitis_case_group_key'))
    BEGIN
        ALTER TABLE nrt_hepatitis_case_group_key
            ADD CONSTRAINT pk_nrt_hepatitis_case_group_key PRIMARY KEY (HEP_MULTI_VAL_GRP_KEY);
    END
IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND object_id = OBJECT_ID('nrt_hepatitis_case_multi_val_key'))
    BEGIN
        ALTER TABLE nrt_hepatitis_case_multi_val_key
            ADD CONSTRAINT pk_nrt_hepatitis_case_multi_val_key PRIMARY KEY (HEP_MULTI_VAL_DATA_KEY, HEP_MULTI_VAL_GRP_KEY);
    END
IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND object_id = OBJECT_ID('nrt_interview_answer'))
    BEGIN
        ALTER TABLE nrt_interview_answer
            ADD CONSTRAINT pk_nrt_interview_answer PRIMARY KEY (interview_uid);
    END
IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND object_id = OBJECT_ID('nrt_interview_answer_copy'))
    BEGIN
        ALTER TABLE nrt_interview_answer_copy
            ADD CONSTRAINT pk_nrt_interview_answer_copy PRIMARY KEY (interview_uid);
    END
IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND object_id = OBJECT_ID('nrt_interview_note'))
    BEGIN
        ALTER TABLE nrt_interview_note
            ADD CONSTRAINT pk_nrt_interview_note PRIMARY KEY (interview_uid);
    END
IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND object_id = OBJECT_ID('nrt_interview_note_copy'))
    BEGIN
        ALTER TABLE nrt_interview_note_copy
            ADD CONSTRAINT pk_nrt_interview_note_copy PRIMARY KEY (interview_uid);
    END
IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND object_id = OBJECT_ID('nrt_interview_note_NOV22'))
    BEGIN
        ALTER TABLE nrt_interview_note_NOV22
            ADD CONSTRAINT pk_nrt_interview_note_NOV22 PRIMARY KEY (interview_uid);
    END
IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND object_id = OBJECT_ID('nrt_investigation_aggregate'))
    BEGIN
        ALTER TABLE nrt_investigation_aggregate
            ADD CONSTRAINT pk_nrt_investigation_aggregate PRIMARY KEY (act_uid, nbs_case_answer_uid);
    END
IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND object_id = OBJECT_ID('nrt_investigation_notification'))
    BEGIN
        ALTER TABLE nrt_investigation_notification
            ADD CONSTRAINT pk_nrt_investigation_notification PRIMARY KEY (source_act_uid, notification_uid);
    END
IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND object_id = OBJECT_ID('nrt_investigation_test'))
    BEGIN
        ALTER TABLE nrt_investigation_test
            ADD CONSTRAINT pk_nrt_investigation_test PRIMARY KEY (public_health_case_uid);
    END
IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND object_id = OBJECT_ID('nrt_investigation_test_1'))
    BEGIN
        ALTER TABLE nrt_investigation_test_1
            ADD CONSTRAINT pk_nrt_investigation_test_1 PRIMARY KEY (public_health_case_uid);
    END
IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND object_id = OBJECT_ID('nrt_lab_result_comment_key'))
    BEGIN
        ALTER TABLE nrt_lab_result_comment_key
            ADD CONSTRAINT pk_nrt_lab_result_comment_key PRIMARY KEY (LAB_RESULT_COMMENT_KEY);
    END
IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND object_id = OBJECT_ID('nrt_lab_rpt_user_comment_key'))
    BEGIN
        ALTER TABLE nrt_lab_rpt_user_comment_key
            ADD CONSTRAINT pk_nrt_lab_rpt_user_comment_key PRIMARY KEY (USER_COMMENT_KEY);
    END
IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND object_id = OBJECT_ID('nrt_lab_test_key'))
    BEGIN
        ALTER TABLE nrt_lab_test_key
            ADD CONSTRAINT pk_nrt_lab_test_key PRIMARY KEY (LAB_TEST_KEY);
    END
IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND object_id = OBJECT_ID('nrt_lab_test_result_comment_group_key'))
    BEGIN
        ALTER TABLE nrt_lab_test_result_comment_group_key
            ADD CONSTRAINT pk_nrt_lab_test_result_comment_group_key PRIMARY KEY (TEST_RESULT_GRP_KEY);
    END
IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND object_id = OBJECT_ID('nrt_lab_test_result_group_key'))
    BEGIN
        ALTER TABLE nrt_lab_test_result_group_key
            ADD CONSTRAINT pk_nrt_lab_test_result_group_key PRIMARY KEY (TEST_RESULT_GRP_KEY);
    END
IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND object_id = OBJECT_ID('nrt_ldf_data'))
    BEGIN
        ALTER TABLE nrt_ldf_data
            ADD CONSTRAINT pk_nrt_ldf_data PRIMARY KEY (ldf_uid, business_object_uid);
    END
IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND object_id = OBJECT_ID('nrt_move_cntry_group_key'))
    BEGIN
        ALTER TABLE nrt_move_cntry_group_key
            ADD CONSTRAINT pk_nrt_move_cntry_group_key PRIMARY KEY (D_MOVE_CNTRY_GROUP_KEY, TB_PAM_UID);
    END
IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND object_id = OBJECT_ID('nrt_move_cntry_key'))
    BEGIN
        ALTER TABLE nrt_move_cntry_key
            ADD CONSTRAINT pk_nrt_move_cntry_key PRIMARY KEY (D_MOVE_CNTRY_KEY, TB_PAM_UID, NBS_Case_Answer_UID);
    END
IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND object_id = OBJECT_ID('nrt_move_cnty_group_key'))
    BEGIN
        ALTER TABLE nrt_move_cnty_group_key
            ADD CONSTRAINT pk_nrt_move_cnty_group_key PRIMARY KEY (D_MOVE_CNTY_GROUP_KEY, TB_PAM_UID);
    END
IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND object_id = OBJECT_ID('nrt_move_cnty_key'))
    BEGIN
        ALTER TABLE nrt_move_cnty_key
            ADD CONSTRAINT pk_nrt_move_cnty_key PRIMARY KEY (D_MOVE_CNTY_KEY, TB_PAM_UID, NBS_Case_Answer_UID);
    END
IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND object_id = OBJECT_ID('nrt_move_state_group_key'))
    BEGIN
        ALTER TABLE nrt_move_state_group_key
            ADD CONSTRAINT pk_nrt_move_state_group_key PRIMARY KEY (D_MOVE_STATE_GROUP_KEY, TB_PAM_UID);
    END
IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND object_id = OBJECT_ID('nrt_move_state_key'))
    BEGIN
        ALTER TABLE nrt_move_state_key
            ADD CONSTRAINT pk_nrt_move_state_key PRIMARY KEY (D_MOVE_STATE_KEY, TB_PAM_UID, NBS_Case_Answer_UID);
    END
IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND object_id = OBJECT_ID('nrt_moved_where_group_key'))
    BEGIN
        ALTER TABLE nrt_moved_where_group_key
            ADD CONSTRAINT pk_nrt_moved_where_group_key PRIMARY KEY (D_MOVED_WHERE_GROUP_KEY, TB_PAM_UID);
    END
IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND object_id = OBJECT_ID('nrt_moved_where_key'))
    BEGIN
        ALTER TABLE nrt_moved_where_key
            ADD CONSTRAINT pk_nrt_moved_where_key PRIMARY KEY (D_MOVED_WHERE_KEY, TB_PAM_UID, NBS_Case_Answer_UID);
    END
IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND object_id = OBJECT_ID('nrt_observation_coded'))
    BEGIN
        ALTER TABLE nrt_observation_coded
            ADD CONSTRAINT pk_nrt_observation_coded PRIMARY KEY (observation_uid);
    END
IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND object_id = OBJECT_ID('nrt_observation_date'))
    BEGIN
        ALTER TABLE nrt_observation_date
            ADD CONSTRAINT pk_nrt_observation_date PRIMARY KEY (observation_uid);
    END
IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND object_id = OBJECT_ID('nrt_observation_edx'))
    BEGIN
        ALTER TABLE nrt_observation_edx
            ADD CONSTRAINT pk_nrt_observation_edx PRIMARY KEY (edx_document_uid, edx_act_uid);
    END
IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND object_id = OBJECT_ID('nrt_observation_material'))
    BEGIN
        ALTER TABLE nrt_observation_material
            ADD CONSTRAINT pk_nrt_observation_material PRIMARY KEY (act_uid);
    END
IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND object_id = OBJECT_ID('nrt_observation_numeric'))
    BEGIN
        ALTER TABLE nrt_observation_numeric
            ADD CONSTRAINT pk_nrt_observation_numeric PRIMARY KEY (observation_uid);
    END
IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND object_id = OBJECT_ID('nrt_observation_reason'))
    BEGIN
        ALTER TABLE nrt_observation_reason
            ADD CONSTRAINT pk_nrt_observation_reason PRIMARY KEY (observation_uid);
    END
IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND object_id = OBJECT_ID('nrt_observation_t'))
    BEGIN
        ALTER TABLE nrt_observation_t
            ADD CONSTRAINT pk_nrt_observation_t PRIMARY KEY (observation_uid);
    END
IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND object_id = OBJECT_ID('nrt_observation_test'))
    BEGIN
        ALTER TABLE nrt_observation_test
            ADD CONSTRAINT pk_nrt_observation_test PRIMARY KEY (observation_uid);
    END
IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND object_id = OBJECT_ID('nrt_observation_txt'))
    BEGIN
        ALTER TABLE nrt_observation_txt
            ADD CONSTRAINT pk_nrt_observation_txt PRIMARY KEY (observation_uid);
    END
IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND object_id = OBJECT_ID('nrt_observation_txt_t'))
    BEGIN
        ALTER TABLE nrt_observation_txt_t
            ADD CONSTRAINT pk_nrt_observation_txt_t PRIMARY KEY (observation_uid);
    END
IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND object_id = OBJECT_ID('nrt_organization'))
    BEGIN
        ALTER TABLE nrt_organization
            ADD CONSTRAINT pk_nrt_organization PRIMARY KEY (organization_uid);
    END
IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND object_id = OBJECT_ID('nrt_page_case_answer'))
    BEGIN
        ALTER TABLE nrt_page_case_answer
            ADD CONSTRAINT pk_nrt_page_case_answer PRIMARY KEY (act_uid, nbs_case_answer_uid, nbs_ui_metadata_uid, nbs_question_uid);
    END
IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND object_id = OBJECT_ID('nrt_pertussis_source_group_key'))
    BEGIN
        ALTER TABLE nrt_pertussis_source_group_key
            ADD CONSTRAINT pk_nrt_pertussis_source_group_key PRIMARY KEY (PERTUSSIS_SUSPECT_SRC_GRP_KEY);
    END
IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND object_id = OBJECT_ID('nrt_pertussis_source_key'))
    BEGIN
        ALTER TABLE nrt_pertussis_source_key
            ADD CONSTRAINT pk_nrt_pertussis_source_key PRIMARY KEY (PERTUSSIS_SUSPECT_SRC_FLD_KEY, PERTUSSIS_SUSPECT_SRC_GRP_KEY);
    END
IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND object_id = OBJECT_ID('nrt_pertussis_treatment_group_key'))
    BEGIN
        ALTER TABLE nrt_pertussis_treatment_group_key
            ADD CONSTRAINT pk_nrt_pertussis_treatment_group_key PRIMARY KEY (PERTUSSIS_TREATMENT_GRP_KEY);
    END
IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND object_id = OBJECT_ID('nrt_pertussis_treatment_key'))
    BEGIN
        ALTER TABLE nrt_pertussis_treatment_key
            ADD CONSTRAINT pk_nrt_pertussis_treatment_key PRIMARY KEY (PERTUSSIS_TREATMENT_FLD_KEY, PERTUSSIS_TREATMENT_GRP_KEY);
    END
IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND object_id = OBJECT_ID('nrt_place_key_test'))
    BEGIN
        ALTER TABLE nrt_place_key_test
            ADD CONSTRAINT pk_nrt_place_key_test PRIMARY KEY (d_place_key, place_uid, place_locator_uid);
    END
IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND object_id = OBJECT_ID('nrt_place_tele'))
    BEGIN
        ALTER TABLE nrt_place_tele
            ADD CONSTRAINT pk_nrt_place_tele PRIMARY KEY (place_uid, place_tele_locator_uid);
    END
IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND object_id = OBJECT_ID('nrt_place_tele_test'))
    BEGIN
        ALTER TABLE nrt_place_tele_test
            ADD CONSTRAINT pk_nrt_place_tele_test PRIMARY KEY (place_uid, place_tele_locator_uid);
    END
IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND object_id = OBJECT_ID('nrt_rash_loc_gen_group_key'))
    BEGIN
        ALTER TABLE nrt_rash_loc_gen_group_key
            ADD CONSTRAINT pk_nrt_rash_loc_gen_group_key PRIMARY KEY (D_RASH_LOC_GEN_GROUP_KEY, VAR_PAM_UID);
    END
IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND object_id = OBJECT_ID('nrt_rash_loc_gen_key'))
    BEGIN
        ALTER TABLE nrt_rash_loc_gen_key
            ADD CONSTRAINT pk_nrt_rash_loc_gen_key PRIMARY KEY (D_RASH_LOC_GEN_KEY, VAR_PAM_UID, NBS_Case_Answer_UID);
    END
IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND object_id = OBJECT_ID('nrt_srte_XSS_Filter_Pattern'))
    BEGIN
        ALTER TABLE nrt_srte_XSS_Filter_Pattern
            ADD CONSTRAINT pk_nrt_srte_XSS_Filter_Pattern PRIMARY KEY (XSS_Filter_Pattern_uid);
    END
IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND object_id = OBJECT_ID('nrt_summary_case_group_key'))
    BEGIN
        ALTER TABLE nrt_summary_case_group_key
            ADD CONSTRAINT pk_nrt_summary_case_group_key PRIMARY KEY (summary_case_src_key);
    END
IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND object_id = OBJECT_ID('nrt_test_result_group_key'))
    BEGIN
        ALTER TABLE nrt_test_result_group_key
            ADD CONSTRAINT pk_nrt_test_result_group_key PRIMARY KEY (TEST_RESULT_GRP_KEY);
    END
IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND object_id = OBJECT_ID('nrt_treatment'))
    BEGIN
        ALTER TABLE nrt_treatment
            ADD CONSTRAINT pk_nrt_treatment PRIMARY KEY (treatment_uid);
    END
IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND object_id = OBJECT_ID('nrt_treatment_key'))
    BEGIN
        ALTER TABLE nrt_treatment_key
            ADD CONSTRAINT pk_nrt_treatment_key PRIMARY KEY (d_treatment_key);
    END
IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND object_id = OBJECT_ID('nrt_vaccination_answer'))
    BEGIN
        ALTER TABLE nrt_vaccination_answer
            ADD CONSTRAINT pk_nrt_vaccination_answer PRIMARY KEY (vaccination_uid);
    END
IF NOT EXISTS(SELECT 1
              FROM sys.objects
              WHERE type = 'PK'
                AND object_id = OBJECT_ID('nrt_vaccination_key'))
    BEGIN
        ALTER TABLE nrt_vaccination_key
            ADD CONSTRAINT pk_nrt_vaccination_key PRIMARY KEY (d_vaccination_key);
    END