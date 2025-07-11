IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_organization_key' and xtype = 'U')
    BEGIN   
        declare @max bigint;
        select @max=max(organization_key)+1 from dbo.D_ORGANIZATION ;
        select @max;
        if @max IS NULL   --check when max is returned as null
        SET @max = 1;
        DBCC CHECKIDENT ('dbo.nrt_organization_key', RESEED, @max);
    END

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_patient_key' and xtype = 'U')
    BEGIN   
        
        select @max=max(patient_key)+1 from dbo.d_patient;
        select @max;
        if @max IS NULL   --check when max is returned as null
        SET @max = 1;
        DBCC CHECKIDENT ('dbo.nrt_patient_key', RESEED, @max);
    END
IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_provider_key' and xtype = 'U')
    BEGIN
        
        select @max=max(provider_key)+1 from dbo.d_provider;
        select @max;
        if @max IS NULL   --check when max is returned as null
        SET @max = 1;
        DBCC CHECKIDENT ('dbo.nrt_provider_key', RESEED, @max);
    END;
IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_investigation_key' and xtype = 'U')
    BEGIN
        
        select @max=max(INVESTIGATION_KEY)+1 from dbo.INVESTIGATION;
        select @max;
        if @max IS NULL   --check when max is returned as null
        SET @max = 1;
        DBCC CHECKIDENT ('dbo.nrt_investigation_key', RESEED, @max);
    END;
IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_ldf_data_key' and xtype = 'U')
    BEGIN
        
        select @max=max(ldf_data_key)+2 from dbo.ldf_data;
        select @max;
        if @max IS NULL   --check when max is returned as null
            SET @max = 2;
        DBCC CHECKIDENT ('dbo.nrt_ldf_data_key', RESEED, @max);

    END
IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_ldf_group_key' and xtype = 'U')
    BEGIN
        
        select @max=max(ldf_group_key)+1 from dbo.ldf_group;
        select @max;
        if @max IS NULL   --check when max is returned as null
            SET @max = 2;
        DBCC CHECKIDENT ('dbo.nrt_ldf_group_key', RESEED, @max);

    END
IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_confirmation_method_key' and xtype = 'U')
    BEGIN
        
        select @max = max(confirmation_method_key) + 1 from dbo.confirmation_method;
        select @max;
        if @max IS NULL --check when max is returned as null
            SET @max = 2;
        DBCC CHECKIDENT ('dbo.nrt_confirmation_method_key', RESEED, @max);
    END
IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_notification_key' and xtype = 'U')
    BEGIN
        
        select @max=max(notification_key)+1 from dbo.NOTIFICATION ;
        select @max;
        if @max IS NULL   --check when max is returned as null
            SET @max = 1;
        DBCC CHECKIDENT ('dbo.nrt_notification_key', RESEED, @max);
    END
IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_lab_test_key' and xtype = 'U')
	BEGIN
		
		SELECT @max=max(LAB_TEST_KEY) from [dbo].LAB_TEST;
		SELECT @max;
		IF @max IS NULL   --check when max is returned as null
			SET @max = 2; -- default to 2, default record with key = 1 is already created
		DBCC CHECKIDENT ('[dbo].nrt_lab_test_key', RESEED, @max);

	END
IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_interview_key' and xtype = 'U')
    BEGIN
        
        select @max=max(d_interview_key)+1 from dbo.D_INTERVIEW ;
        select @max;
        if @max IS NULL   --check when max is returned as null
            SET @max = 2; -- default to 2, as default record with key = 1 is not stored in D_INTERVIEW
        DBCC CHECKIDENT ('dbo.nrt_interview_key', RESEED, @max);
    END

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_interview_note_key' and xtype = 'U')
    BEGIN
        
        select @max=max(d_interview_note_key)+1 from dbo.D_INTERVIEW_NOTE ;
        select @max;
        if @max IS NULL   --check when max is returned as null
            SET @max = 2; -- default to 2, as default record with key = 1 is not stored in D_INTERVIEW_NOTE
        DBCC CHECKIDENT ('dbo.nrt_interview_note_key', RESEED, @max);
    END

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_treatment_key' and xtype = 'U')
    BEGIN
        
        select @max=max(TREATMENT_KEY)+1 from dbo.TREATMENT ;
        select @max;
        if @max IS NULL   --check when max is returned as null
            SET @max = 2; -- default to 2
        DBCC CHECKIDENT ('dbo.nrt_treatment_key', RESEED, @max);
    END
IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_vaccination_key' and xtype = 'U')
    BEGIN
        
        select @max=max(d_vaccination_key)+1 from dbo.D_VACCINATION ;
        select @max;
        if @max IS NULL   --check when max is returned as null
            SET @max = 2; -- default to 2, as default record with key = 1 is not stored in D_INTERVIEW
        DBCC CHECKIDENT ('dbo.nrt_vaccination_key', RESEED, @max);
    END
IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_case_management_key' and xtype = 'U')
    BEGIN
        
        select @max=max(D_CASE_MANAGEMENT_KEY)+1 from dbo.D_CASE_MANAGEMENT;
        select @max;
        if @max IS NULL   --check when max is returned as null
            SET @max = 1;
        DBCC CHECKIDENT ('dbo.nrt_case_management_key', RESEED, @max);

    END;
IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_contact_key' and xtype = 'U')
BEGIN
    
    select @max=max(d_contact_record_key)+1 from dbo.D_CONTACT_RECORD ;
    select @max;
    if @max IS NULL
        SET @max = 2;
    DBCC CHECKIDENT ('dbo.nrt_contact_key', RESEED, @max);
END

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_place_key' and xtype = 'U')
    BEGIN
        
        select @max = max(place_key) + 1 from dbo.D_PLACE;
        select @max;
        if @max IS NULL --check when max is returned as null
            SET @max = 2; --Start from key=2
        DBCC CHECKIDENT ('dbo.nrt_place_key', RESEED, @max);

    END

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_d_tb_pam_key' and xtype = 'U')
BEGIN
	
	select @max=MAX(D_TB_PAM_KEY) + 1 FROM [dbo].[D_TB_PAM] WITH (NOLOCK);
	select @max;
	if @max IS NULL --check when max is returned as null
		set @max = 2
		DBCC CHECKIDENT ('dbo.nrt_d_tb_pam_key', RESEED, @max);
END

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_d_tb_hiv_key' and xtype = 'U')
BEGIN
	select @max = (SELECT ISNULL(MAX(D_TB_HIV_KEY)+1, 2) FROM dbo.D_TB_HIV);
	DBCC CHECKIDENT ('dbo.nrt_d_tb_hiv_key', RESEED, @max);	
END

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_addl_risk_group_key' and xtype = 'U')
    BEGIN
        
        select @max=max(D_ADDL_RISK_GROUP_KEY)+1 from dbo.d_addl_risk_group ;
        select @max;
        if @max IS NULL   --check when max is returned as null
            SET @max = 2; -- default to 2
        DBCC CHECKIDENT ('dbo.nrt_addl_risk_group_key', RESEED, @max);
    END

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_addl_risk_key' and xtype = 'U')
    BEGIN
        
        select @max=max(D_ADDL_RISK_KEY)+1 from dbo.d_addl_risk ;
        select @max;
        if @max IS NULL   --check when max is returned as null
            SET @max = 2; -- default to 2
        DBCC CHECKIDENT ('dbo.nrt_addl_risk_key', RESEED, @max);
    END
IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_disease_site_group_key' and xtype = 'U')
    BEGIN
        
        select @max=max(D_DISEASE_SITE_GROUP_KEY)+1 from dbo.d_disease_site_group ;
        select @max;
        if @max IS NULL   --check when max is returned as null
            SET @max = 2; -- default to 2
        DBCC CHECKIDENT ('dbo.nrt_disease_site_group_key', RESEED, @max);
    END

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_disease_site_key' and xtype = 'U')
    BEGIN
        
        select @max=max(D_DISEASE_SITE_KEY)+1 from dbo.d_disease_site ;
        select @max;
        if @max IS NULL   --check when max is returned as null
            SET @max = 2; -- default to 2
        DBCC CHECKIDENT ('dbo.nrt_disease_site_key', RESEED, @max);
    END

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_move_cntry_group_key' and xtype = 'U')
    BEGIN
        
        select @max=max(D_MOVE_CNTRY_GROUP_KEY)+1 from dbo.d_move_cntry_group ;
        select @max;
        if @max IS NULL   --check when max is returned as null
            SET @max = 2; -- default to 2
        DBCC CHECKIDENT ('dbo.nrt_move_cntry_group_key', RESEED, @max);
    END

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_move_cntry_key' and xtype = 'U')
    BEGIN
        
        select @max=max(D_MOVE_CNTRY_KEY)+1 from dbo.d_move_cntry ;
        select @max;
        if @max IS NULL   --check when max is returned as null
            SET @max = 2; -- default to 2
        DBCC CHECKIDENT ('dbo.nrt_move_cntry_key', RESEED, @max);
    END

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_move_cnty_group_key' and xtype = 'U')
    BEGIN
        
        select @max=max(D_MOVE_CNTY_GROUP_KEY)+1 from dbo.d_move_cnty_group ;
        select @max;
        if @max IS NULL   --check when max is returned as null
            SET @max = 2; -- default to 2
        DBCC CHECKIDENT ('dbo.nrt_move_cnty_group_key', RESEED, @max);
    END

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_move_cnty_key' and xtype = 'U')
    BEGIN
        
        select @max=max(D_MOVE_CNTY_KEY)+1 from dbo.d_move_cnty ;
        select @max;
        if @max IS NULL   --check when max is returned as null
            SET @max = 2; -- default to 2
        DBCC CHECKIDENT ('dbo.nrt_move_cnty_key', RESEED, @max);
    END

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_move_state_group_key' and xtype = 'U')
    BEGIN
        
        select @max=max(D_MOVE_STATE_GROUP_KEY)+1 from dbo.d_move_state_group ;
        select @max;
        if @max IS NULL   --check when max is returned as null
            SET @max = 2; -- default to 2
        DBCC CHECKIDENT ('dbo.nrt_move_state_group_key', RESEED, @max);
    END

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_move_state_key' and xtype = 'U')
    BEGIN
        
        select @max=max(D_MOVE_STATE_KEY)+1 from dbo.d_move_state ;
        select @max;
        if @max IS NULL   --check when max is returned as null
            SET @max = 2; -- default to 2
        DBCC CHECKIDENT ('dbo.nrt_move_state_key', RESEED, @max);
    END

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_moved_where_group_key' and xtype = 'U')
    BEGIN
        
        select @max=max(D_MOVED_WHERE_GROUP_KEY)+1 from dbo.d_moved_where_group ;
        select @max;
        if @max IS NULL   --check when max is returned as null
            SET @max = 2; -- default to 2
        DBCC CHECKIDENT ('dbo.nrt_moved_where_group_key', RESEED, @max);
    END
IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_moved_where_key' and xtype = 'U')
    BEGIN
        
        select @max=max(D_MOVED_WHERE_KEY)+1 from dbo.d_moved_where ;
        select @max;
        if @max IS NULL   --check when max is returned as null
            SET @max = 2; -- default to 2
        DBCC CHECKIDENT ('dbo.nrt_moved_where_key', RESEED, @max);
    END

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_d_gt_12_reas_group_key' and xtype = 'U')
BEGIN
	select @max = (SELECT ISNULL(MAX(D_GT_12_REAS_GROUP_KEY)+1, 2) FROM dbo.D_GT_12_REAS_GROUP);
	DBCC CHECKIDENT ('dbo.nrt_d_gt_12_reas_group_key', RESEED, @max);	
END

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_d_gt_12_reas_key' and xtype = 'U')
BEGIN
	select @max = (SELECT ISNULL(MAX(D_GT_12_REAS_KEY)+1, 2) FROM dbo.D_GT_12_REAS);
	DBCC CHECKIDENT ('dbo.nrt_d_gt_12_reas_key', RESEED, @max);		
END

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_d_hc_prov_ty_3_group_key' and xtype = 'U')
BEGIN
	select @max = (SELECT ISNULL(MAX(D_HC_PROV_TY_3_GROUP_KEY)+1, 2) FROM dbo.D_HC_PROV_TY_3_GROUP);
	DBCC CHECKIDENT ('dbo.nrt_d_hc_prov_ty_3_group_key', RESEED, @max);	
END

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_d_hc_prov_ty_3_key' and xtype = 'U')
BEGIN
	select @max = (SELECT ISNULL(MAX(D_HC_PROV_TY_3_KEY)+1, 2) FROM dbo.D_HC_PROV_TY_3);
	DBCC CHECKIDENT ('dbo.nrt_d_hc_prov_ty_3_key', RESEED, @max);
END

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_d_out_of_cntry_group_key' and xtype = 'U')
BEGIN
	select @max = (SELECT ISNULL(MAX(D_OUT_OF_CNTRY_GROUP_KEY)+1, 2) FROM dbo.D_OUT_OF_CNTRY_GROUP);
	DBCC CHECKIDENT ('dbo.nrt_d_out_of_cntry_group_key', RESEED, @max);	
END

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_d_out_of_cntry_key' and xtype = 'U')
BEGIN
	select @max = (SELECT ISNULL(MAX(D_OUT_OF_CNTRY_KEY)+1, 2) FROM dbo.D_OUT_OF_CNTRY);
	DBCC CHECKIDENT ('dbo.nrt_d_out_of_cntry_key', RESEED, @max);	
END

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_d_smr_exam_ty_group_key' and xtype = 'U')
BEGIN
	select @max = (SELECT ISNULL(MAX(D_SMR_EXAM_TY_GROUP_KEY)+1, 2) FROM dbo.D_SMR_EXAM_TY_GROUP);
	DBCC CHECKIDENT ('dbo.nrt_d_smr_exam_ty_group_key', RESEED, @max);
END

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_d_smr_exam_ty_key' and xtype = 'U')
BEGIN
	select @max = (SELECT ISNULL(MAX(D_SMR_EXAM_TY_KEY)+1, 2) FROM dbo.D_SMR_EXAM_TY);
	DBCC CHECKIDENT ('dbo.nrt_d_smr_exam_ty_key', RESEED, @max);
END

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_var_pam_key' and xtype = 'U')
BEGIN
        
        select @max=max(d_var_pam_key)+1 from dbo.D_VAR_PAM ;
        select @max;
        if @max IS NULL   --check when max is returned as null
            SET @max = 2; -- default to 2, as default record with key = 1 is not stored in D_INTERVIEW
        DBCC CHECKIDENT ('dbo.nrt_var_pam_key', RESEED, @max);
    END

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_rash_loc_gen_group_key' and xtype = 'U')
    BEGIN

        
        select @max=max(D_RASH_LOC_GEN_GROUP_KEY)+1 from dbo.d_rash_loc_gen_group ;
        select @max;
        if @max IS NULL   --check when max is returned as null
            SET @max = 2; -- default to 2
        DBCC CHECKIDENT ('dbo.nrt_rash_loc_gen_group_key', RESEED, @max);
    END

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_rash_loc_gen_key' and xtype = 'U')
    BEGIN
        
        select @max=max(D_RASH_LOC_GEN_KEY)+1 from dbo.d_rash_loc_gen ;
        select @max;
        if @max IS NULL   --check when max is returned as null
            SET @max = 2; -- default to 2
        DBCC CHECKIDENT ('dbo.nrt_rash_loc_gen_key', RESEED, @max);
    END

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_d_pcr_source_group_key' and xtype = 'U')
BEGIN
	select @max = (SELECT ISNULL(MAX(D_PCR_SOURCE_GROUP_KEY)+1, 2) FROM dbo.D_PCR_SOURCE_GROUP);
	DBCC CHECKIDENT ('dbo.nrt_d_pcr_source_group_key', RESEED, @max);
END

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_d_pcr_source_key' and xtype = 'U')  
BEGIN
	select @max = (SELECT ISNULL(MAX(D_PCR_SOURCE_KEY)+1, 2) FROM dbo.D_PCR_SOURCE);
	DBCC CHECKIDENT ('dbo.nrt_d_pcr_source_key', RESEED, @max);
END

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_hepatitis_case_group_key' and xtype = 'U')
    BEGIN

        --check for null and set default to 2
        select @max = (SELECT ISNULL(MAX(HEP_MULTI_VAL_GRP_KEY) + 1, 2) FROM dbo.hep_multi_value_field_group);
        DBCC CHECKIDENT('dbo.nrt_hepatitis_case_group_key', RESEED, @max);

    END;
IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_hepatitis_case_multi_val_key' and xtype = 'U')
    BEGIN
        --check for null and set default to 2
        select @max = (SELECT ISNULL(MAX(HEP_MULTI_VAL_DATA_KEY) + 1, 2) FROM dbo.hep_multi_value_field);
        DBCC CHECKIDENT('dbo.nrt_hepatitis_case_multi_val_key', RESEED, @max);

    END;
IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_pertussis_source_group_key' and xtype = 'U')
    BEGIN
        --check for null and set default to 2
        select @max = (SELECT ISNULL(MAX(PERTUSSIS_SUSPECT_SRC_GRP_KEY) + 1, 2) FROM dbo.PERTUSSIS_SUSPECTED_SOURCE_GRP);
        DBCC CHECKIDENT('dbo.nrt_pertussis_source_group_key', RESEED, @max);

    END;

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_pertussis_source_key' and xtype = 'U')
    BEGIN
        --check for null and set default to 2
        select @max = (SELECT ISNULL(MAX(PERTUSSIS_SUSPECT_SRC_FLD_KEY) + 1, 2) FROM dbo.PERTUSSIS_SUSPECTED_SOURCE_FLD);
        DBCC CHECKIDENT('dbo.nrt_pertussis_source_key', RESEED, @max);
    END;
IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_pertussis_treatment_group_key' and xtype = 'U')
    BEGIN

        --check for null and set default to 2
        select @max = (SELECT ISNULL(MAX(PERTUSSIS_TREATMENT_GRP_KEY) + 1, 2) FROM dbo.PERTUSSIS_TREATMENT_GROUP);
        DBCC CHECKIDENT('dbo.nrt_pertussis_treatment_group_key', RESEED, @max);

    END;

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_pertussis_treatment_key' and xtype = 'U')
    BEGIN
        --check for null and set default to 2
        select @max = (SELECT ISNULL(MAX(PERTUSSIS_TREATMENT_FLD_KEY) + 1, 2) FROM dbo.PERTUSSIS_TREATMENT_FIELD);
        DBCC CHECKIDENT('dbo.nrt_pertussis_treatment_key', RESEED, @max);

    END;

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_antimicrobial_group_key' and xtype = 'U')
    BEGIN

        --check for null and set default to 2
        select @max = (SELECT ISNULL(MAX(ANTIMICROBIAL_GRP_KEY) + 1, 2) FROM dbo.ANTIMICROBIAL_GROUP);
        DBCC CHECKIDENT('dbo.nrt_antimicrobial_group_key', RESEED, @max);

    END;

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_antimicrobial_key' and xtype = 'U')
    BEGIN
        --check for null and set default to 2, as default record with key = 1 is not stored in ANTIMICROBIAL
        select @max = (SELECT ISNULL(MAX(ANTIMICROBIAL_KEY) + 1, 2) FROM dbo.ANTIMICROBIAL);
        DBCC CHECKIDENT('dbo.nrt_antimicrobial_key', RESEED, @max);

    END;

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_bmird_multi_val_group_key' and xtype = 'U')
    BEGIN
        --check for null and set default to 2
        select @max = (SELECT ISNULL(MAX(BMIRD_MULTI_VAL_GRP_KEY) + 1, 2) FROM dbo.BMIRD_MULTI_VALUE_FIELD_GROUP);
        DBCC CHECKIDENT('dbo.nrt_bmird_multi_val_group_key', RESEED, @max);

    END;

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_bmird_multi_val_key' and xtype = 'U')
    BEGIN
        --check for null and set default to 2, as default record with key = 1 is not stored in BMIRD_MULTI_VALUE_FIELD
        select @max = (SELECT ISNULL(MAX(BMIRD_MULTI_VAL_FIELD_KEY) + 1, 2) FROM dbo.BMIRD_MULTI_VALUE_FIELD);
        DBCC CHECKIDENT('dbo.nrt_bmird_multi_val_key', RESEED, @max);
    END;

IF EXISTS (SELECT 1
               FROM sysobjects
               WHERE name = 'nrt_summary_case_group_key'
                 and xtype = 'U')
    BEGIN
        --Ref PR#189: Check for null and set default to 2
        select @max = (SELECT DISTINCT ISNULL(MAX(SUMMARY_CASE_SRC_KEY) + 1, 2) FROM dbo.SUMMARY_CASE_GROUP);
        DBCC CHECKIDENT ('dbo.nrt_summary_case_group_key', RESEED, @max);

    END;
IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_lab_test_key' and xtype = 'U')
	BEGIN
		--RESEED [dbo].nrt_lab_test_key table 
		
		SELECT @max=max(LAB_TEST_KEY) from [dbo].LAB_TEST;
		SELECT @max;
		IF @max IS NULL   --check when max is returned as null
			SET @max = 2; -- default to 2, default record with key = 1 is already created
		DBCC CHECKIDENT ('[dbo].nrt_lab_test_key', RESEED, @max);

	END

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_lab_rpt_user_comment_key' and xtype = 'U')
	BEGIN
		--RESEED [dbo].nrt_lab_rpt_user_comment_key table 
		SELECT @max=max(USER_COMMENT_KEY) from [dbo].Lab_Rpt_User_Comment;
		SELECT @max;
		IF @max IS NULL   --check when max is returned as null
			SET @max = 2; -- default to 2, default record with key = 1 is already created
		DBCC CHECKIDENT ('[dbo].nrt_lab_rpt_user_comment_key', RESEED, @max);

	END

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_lab_result_comment_key' and xtype = 'U')
	BEGIN

		--RESEED [dbo].nrt_lab_result_comment_key table 
		SELECT @max=max(LAB_RESULT_COMMENT_KEY) from [dbo].LAB_RESULT_COMMENT;
		SELECT @max;
		IF @max IS NULL   --check when max is returned as null
			SET @max = 2; -- default to 2, default record with key = 1 is already created
		DBCC CHECKIDENT ('[dbo].nrt_lab_result_comment_key', RESEED, @max);

	END
    
IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_lab_test_result_group_key' and xtype = 'U')
	BEGIN

		--RESEED [dbo].nrt_lab_test_result_group_key table 
		SELECT @max=max(TEST_RESULT_GRP_KEY) from [dbo].TEST_RESULT_GROUPING;
		SELECT @max;
		IF @max IS NULL   --check when max is returned as null
			SET @max = 2; -- default to 2, default record with key = 1 is already created
		DBCC CHECKIDENT ('[dbo].nrt_lab_test_result_group_key', RESEED, @max);

	END

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_condition_key' and xtype = 'U')
	BEGIN

		--RESEED [dbo].nrt_condition_key table 
		SELECT @max=max(CONDITION_KEY) from [dbo].CONDITION;
		SELECT @max;
		IF @max IS NULL   --check when max is returned as null
			SET @max = 2; -- default to 2, default record with key = 1 is already created
		DBCC CHECKIDENT ('[dbo].nrt_condition_key', RESEED, @max);

	END


