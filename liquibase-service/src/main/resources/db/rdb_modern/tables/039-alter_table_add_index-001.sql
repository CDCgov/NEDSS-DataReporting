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

/*CNDE-2859: Add indexes for nrt key tables*/


IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_var_pam_key_39588075' AND object_id = OBJECT_ID('nrt_var_pam_key')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_var_pam_key_39588075] ON dbo.nrt_var_pam_key ( D_VAR_PAM_KEY, VAR_PAM_UID ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_contact_key_148776433' AND object_id = OBJECT_ID('nrt_contact_key')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_contact_key_148776433] ON dbo.nrt_contact_key ( d_contact_record_key ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_investigation_cnde2096_175204520' AND object_id = OBJECT_ID('nrt_investigation_cnde2096')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_investigation_cnde2096_175204520] ON dbo.nrt_investigation_cnde2096 ( public_health_case_uid ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_srte_Anatomic_site_code_290680929' AND object_id = OBJECT_ID('nrt_srte_Anatomic_site_code')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_srte_Anatomic_site_code_290680929] ON dbo.nrt_srte_Anatomic_site_code ( anatomic_site_uid ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_srte_Anatomic_site_code_290680929' AND object_id = OBJECT_ID('nrt_srte_Anatomic_site_code')) BEGIN CREATE UNIQUE NONCLUSTERED INDEX [IX_nrt_srte_Anatomic_site_code_290680929] ON dbo.nrt_srte_Anatomic_site_code ( nbs_uid ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_organization_294615042' AND object_id = OBJECT_ID('nrt_organization')) BEGIN CREATE NONCLUSTERED INDEX [IX_nrt_organization_294615042] ON dbo.nrt_organization ( organization_uid ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_provider_326615156' AND object_id = OBJECT_ID('nrt_provider')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_provider_326615156] ON dbo.nrt_provider ( provider_uid ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_srte_City_code_value_354681157' AND object_id = OBJECT_ID('nrt_srte_City_code_value')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_srte_City_code_value_354681157] ON dbo.nrt_srte_City_code_value ( code ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_patient_374615327' AND object_id = OBJECT_ID('nrt_patient')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_patient_374615327] ON dbo.nrt_patient ( patient_uid ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_srte_Codeset_Group_Metadata_402681328' AND object_id = OBJECT_ID('nrt_srte_Codeset_Group_Metadata')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_srte_Codeset_Group_Metadata_402681328] ON dbo.nrt_srte_Codeset_Group_Metadata ( code_set_group_id ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_investigation_422615498' AND object_id = OBJECT_ID('nrt_investigation')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_investigation_422615498] ON dbo.nrt_investigation ( public_health_case_uid ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_srte_Country_Code_ISO_434681442' AND object_id = OBJECT_ID('nrt_srte_Country_Code_ISO')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_srte_Country_Code_ISO_434681442] ON dbo.nrt_srte_Country_Code_ISO ( code_set_nm, seq_num, code ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_srte_Country_code_466681556' AND object_id = OBJECT_ID('nrt_srte_Country_code')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_srte_Country_code_466681556] ON dbo.nrt_srte_Country_code ( code ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_investigation_confirmation_470615669' AND object_id = OBJECT_ID('nrt_investigation_confirmation')) BEGIN CREATE NONCLUSTERED INDEX [IX_nrt_investigation_confirmation_470615669] ON dbo.nrt_investigation_confirmation ( public_health_case_uid ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_investigation_observation_502615783' AND object_id = OBJECT_ID('nrt_investigation_observation')) BEGIN CREATE NONCLUSTERED INDEX [IX_nrt_investigation_observation_502615783] ON dbo.nrt_investigation_observation ( public_health_case_uid ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_investigation_observation_502615783' AND object_id = OBJECT_ID('nrt_investigation_observation')) BEGIN CREATE NONCLUSTERED INDEX [IX_nrt_investigation_observation_502615783] ON dbo.nrt_investigation_observation ( public_health_case_uid, observation_id, branch_id ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_srte_ELR_XREF_514681727' AND object_id = OBJECT_ID('nrt_srte_ELR_XREF')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_srte_ELR_XREF_514681727] ON dbo.nrt_srte_ELR_XREF ( from_code_set_nm, from_seq_num, from_code, to_code_set_nm, to_seq_num, to_code ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_investigation_notification_518615840' AND object_id = OBJECT_ID('nrt_investigation_notification')) BEGIN CREATE NONCLUSTERED INDEX [IX_nrt_investigation_notification_518615840] ON dbo.nrt_investigation_notification ( public_health_case_uid ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_investigation_notification_518615840' AND object_id = OBJECT_ID('nrt_investigation_notification')) BEGIN CREATE NONCLUSTERED INDEX [IX_nrt_investigation_notification_518615840] ON dbo.nrt_investigation_notification ( public_health_case_uid, source_act_uid ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_investigation_notification_518615840' AND object_id = OBJECT_ID('nrt_investigation_notification')) BEGIN CREATE NONCLUSTERED INDEX [IX_nrt_investigation_notification_518615840] ON dbo.nrt_investigation_notification ( notification_uid ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_d_tb_pam_key_520969778' AND object_id = OBJECT_ID('nrt_d_tb_pam_key')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_d_tb_pam_key_520969778] ON dbo.nrt_d_tb_pam_key ( D_TB_PAM_KEY ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_srte_Investigation_code_562681898' AND object_id = OBJECT_ID('nrt_srte_Investigation_code')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_srte_Investigation_code_562681898] ON dbo.nrt_srte_Investigation_code ( investigation_cd ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_srte_Jurisdiction_code_594682012' AND object_id = OBJECT_ID('nrt_srte_Jurisdiction_code')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_srte_Jurisdiction_code_594682012] ON dbo.nrt_srte_Jurisdiction_code ( code ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_contact_628778143' AND object_id = OBJECT_ID('nrt_contact')) BEGIN CREATE NONCLUSTERED INDEX [IX_nrt_contact_628778143] ON dbo.nrt_contact ( CONTACT_UID ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_place_test_633634146' AND object_id = OBJECT_ID('nrt_place_test')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_place_test_633634146] ON dbo.nrt_place_test ( place_uid ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_srte_LOINC_code_658682240' AND object_id = OBJECT_ID('nrt_srte_LOINC_code')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_srte_LOINC_code_658682240] ON dbo.nrt_srte_LOINC_code ( loinc_cd ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_srte_LOINC_code_658682240' AND object_id = OBJECT_ID('nrt_srte_LOINC_code')) BEGIN CREATE NONCLUSTERED INDEX [IX_nrt_srte_LOINC_code_658682240] ON dbo.nrt_srte_LOINC_code ( time_aspect, system_cd ) WITH (PAD_INDEX = OFF, FILLFACTOR = 100  , IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_srte_LOINC_code_658682240' AND object_id = OBJECT_ID('nrt_srte_LOINC_code')) BEGIN CREATE UNIQUE NONCLUSTERED INDEX [IX_nrt_srte_LOINC_code_658682240] ON dbo.nrt_srte_LOINC_code ( nbs_uid ) WITH (PAD_INDEX = OFF, FILLFACTOR = 90   , IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_srte_Lab_coding_system_706682411' AND object_id = OBJECT_ID('nrt_srte_Lab_coding_system')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_srte_Lab_coding_system_706682411] ON dbo.nrt_srte_Lab_coding_system ( laboratory_id ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_page_case_answer_726616581' AND object_id = OBJECT_ID('nrt_page_case_answer')) BEGIN CREATE NONCLUSTERED INDEX [IX_nrt_page_case_answer_726616581] ON dbo.nrt_page_case_answer ( nbs_case_answer_uid, nbs_question_uid ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_page_case_answer_726616581' AND object_id = OBJECT_ID('nrt_page_case_answer')) BEGIN CREATE NONCLUSTERED INDEX [IX_nrt_page_case_answer_726616581] ON dbo.nrt_page_case_answer ( nbs_case_answer_uid ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_page_case_answer_726616581' AND object_id = OBJECT_ID('nrt_page_case_answer')) BEGIN CREATE NONCLUSTERED INDEX [IX_nrt_page_case_answer_726616581] ON dbo.nrt_page_case_answer ( act_uid ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_srte_Language_code_738682525' AND object_id = OBJECT_ID('nrt_srte_Language_code')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_srte_Language_code_738682525] ON dbo.nrt_srte_Language_code ( code ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_observation_774616752' AND object_id = OBJECT_ID('nrt_observation')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_observation_774616752] ON dbo.nrt_observation ( observation_uid ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_d_tb_hiv_key_776970690' AND object_id = OBJECT_ID('nrt_d_tb_hiv_key')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_d_tb_hiv_key_776970690] ON dbo.nrt_d_tb_hiv_key ( D_TB_HIV_KEY ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_srte_NAICS_Industry_code_802682753' AND object_id = OBJECT_ID('nrt_srte_NAICS_Industry_code')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_srte_NAICS_Industry_code_802682753] ON dbo.nrt_srte_NAICS_Industry_code ( code ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_notification_key_821236930' AND object_id = OBJECT_ID('nrt_notification_key')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_notification_key_821236930] ON dbo.nrt_notification_key ( d_notification_key ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_ldf_data_key_837236987' AND object_id = OBJECT_ID('nrt_ldf_data_key')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_ldf_data_key_837236987] ON dbo.nrt_ldf_data_key ( d_ldf_data_key ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_ldf_group_key_853237044' AND object_id = OBJECT_ID('nrt_ldf_group_key')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_ldf_group_key_853237044] ON dbo.nrt_ldf_group_key ( d_ldf_group_key ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_srte_Participation_type_866682981' AND object_id = OBJECT_ID('nrt_srte_Participation_type')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_srte_Participation_type_866682981] ON dbo.nrt_srte_Participation_type ( act_class_cd, subject_class_cd, type_cd, question_identifier ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_odse_state_defined_field_metadata_873335417' AND object_id = OBJECT_ID('nrt_odse_state_defined_field_metadata')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_odse_state_defined_field_metadata_873335417] ON dbo.nrt_odse_state_defined_field_metadata ( ldf_uid ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_odse_state_defined_field_metadata_873335417' AND object_id = OBJECT_ID('nrt_odse_state_defined_field_metadata')) BEGIN CREATE NONCLUSTERED INDEX [IX_nrt_odse_state_defined_field_metadata_873335417] ON dbo.nrt_odse_state_defined_field_metadata ( ldf_uid ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_srte_Race_code_946683266' AND object_id = OBJECT_ID('nrt_srte_Race_code')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_srte_Race_code_946683266] ON dbo.nrt_srte_Race_code ( code ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_srte_Snomed_code_1010683494' AND object_id = OBJECT_ID('nrt_srte_Snomed_code')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_srte_Snomed_code_1010683494] ON dbo.nrt_srte_Snomed_code ( snomed_cd ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_srte_Snomed_code_1010683494' AND object_id = OBJECT_ID('nrt_srte_Snomed_code')) BEGIN CREATE UNIQUE NONCLUSTERED INDEX [IX_nrt_srte_Snomed_code_1010683494] ON dbo.nrt_srte_Snomed_code ( nbs_uid ) WITH (PAD_INDEX = OFF, FILLFACTOR = 90   , IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_srte_Specimen_source_code_1058683665' AND object_id = OBJECT_ID('nrt_srte_Specimen_source_code')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_srte_Specimen_source_code_1058683665] ON dbo.nrt_srte_Specimen_source_code ( specimen_source_uid ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_srte_Standard_XREF_1106683836' AND object_id = OBJECT_ID('nrt_srte_Standard_XREF')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_srte_Standard_XREF_1106683836] ON dbo.nrt_srte_Standard_XREF ( standard_xref_uid ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_d_gt_12_reas_group_key_1110211901' AND object_id = OBJECT_ID('nrt_d_gt_12_reas_group_key')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_d_gt_12_reas_group_key_1110211901] ON dbo.nrt_d_gt_12_reas_group_key ( D_GT_12_REAS_GROUP_KEY ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_interview_note_1144490760' AND object_id = OBJECT_ID('nrt_interview_note')) BEGIN CREATE NONCLUSTERED INDEX [IX_nrt_interview_note_1144490760] ON dbo.nrt_interview_note ( interview_uid ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_srte_State_county_code_value_1170684064' AND object_id = OBJECT_ID('nrt_srte_State_county_code_value')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_srte_State_county_code_value_1170684064] ON dbo.nrt_srte_State_county_code_value ( code ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_srte_State_model_1202684178' AND object_id = OBJECT_ID('nrt_srte_State_model')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_srte_State_model_1202684178] ON dbo.nrt_srte_State_model ( business_trigger_code_set_nm, business_trigger_set_seq_num, business_trigger_code, module_cd, record_status_from_code ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_srte_State_model_1202684178' AND object_id = OBJECT_ID('nrt_srte_State_model')) BEGIN CREATE UNIQUE NONCLUSTERED INDEX [IX_nrt_srte_State_model_1202684178] ON dbo.nrt_srte_State_model ( nbs_uid ) WITH (PAD_INDEX = OFF, FILLFACTOR = 90   , IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_srte_Codeset_1216159032' AND object_id = OBJECT_ID('nrt_srte_Codeset')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_srte_Codeset_1216159032] ON dbo.nrt_srte_Codeset ( code_set_nm, class_cd ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_srte_Codeset_1216159032' AND object_id = OBJECT_ID('nrt_srte_Codeset')) BEGIN CREATE NONCLUSTERED INDEX [IX_nrt_srte_Codeset_1216159032] ON dbo.nrt_srte_Codeset ( code_set_group_id ) WITH (PAD_INDEX = OFF, FILLFACTOR = 100  , IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_srte_Code_value_general_1248159146' AND object_id = OBJECT_ID('nrt_srte_Code_value_general')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_srte_Code_value_general_1248159146] ON dbo.nrt_srte_Code_value_general ( code_set_nm, code ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_srte_Code_value_general_1248159146' AND object_id = OBJECT_ID('nrt_srte_Code_value_general')) BEGIN CREATE NONCLUSTERED INDEX [IX_nrt_srte_Code_value_general_1248159146] ON dbo.nrt_srte_Code_value_general ( code ) WITH (PAD_INDEX = OFF, FILLFACTOR = 90   , IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_srte_Treatment_code_1250684349' AND object_id = OBJECT_ID('nrt_srte_Treatment_code')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_srte_Treatment_code_1250684349] ON dbo.nrt_srte_Treatment_code ( treatment_cd ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_srte_Unit_code_1282684463' AND object_id = OBJECT_ID('nrt_srte_Unit_code')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_srte_Unit_code_1282684463] ON dbo.nrt_srte_Unit_code ( unit_uid ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_srte_Unit_code_1282684463' AND object_id = OBJECT_ID('nrt_srte_Unit_code')) BEGIN CREATE UNIQUE NONCLUSTERED INDEX [IX_nrt_srte_Unit_code_1282684463] ON dbo.nrt_srte_Unit_code ( nbs_uid ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_contact_answer_1288256490' AND object_id = OBJECT_ID('nrt_contact_answer')) BEGIN CREATE NONCLUSTERED INDEX [IX_nrt_contact_answer_1288256490] ON dbo.nrt_contact_answer ( contact_uid ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_contact_answer_1288256490' AND object_id = OBJECT_ID('nrt_contact_answer')) BEGIN CREATE NONCLUSTERED INDEX [IX_nrt_contact_answer_1288256490] ON dbo.nrt_contact_answer ( contact_uid, rdb_column_nm ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_place_1337636654' AND object_id = OBJECT_ID('nrt_place')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_place_1337636654] ON dbo.nrt_place ( place_uid ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_srte_Program_area_code_1344159488' AND object_id = OBJECT_ID('nrt_srte_Program_area_code')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_srte_Program_area_code_1344159488] ON dbo.nrt_srte_Program_area_code ( prog_area_cd ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_d_gt_12_reas_key_1350212756' AND object_id = OBJECT_ID('nrt_d_gt_12_reas_key')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_d_gt_12_reas_key_1350212756] ON dbo.nrt_d_gt_12_reas_key ( D_GT_12_REAS_KEY ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_srte_Zip_code_value_1362684748' AND object_id = OBJECT_ID('nrt_srte_Zip_code_value')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_srte_Zip_code_value_1362684748] ON dbo.nrt_srte_Zip_code_value ( code ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_place_tele_1369636768' AND object_id = OBJECT_ID('nrt_place_tele')) BEGIN CREATE NONCLUSTERED INDEX [IX_nrt_place_tele_1369636768] ON dbo.nrt_place_tele ( place_uid ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_place_key_1385636825' AND object_id = OBJECT_ID('nrt_place_key')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_place_key_1385636825] ON dbo.nrt_place_key ( d_place_key ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_srte_Cntycity_code_value_1394684862' AND object_id = OBJECT_ID('nrt_srte_Cntycity_code_value')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_srte_Cntycity_code_value_1394684862] ON dbo.nrt_srte_Cntycity_code_value ( cnty_code, city_code ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_srte_Code_value_clinical_1426684976' AND object_id = OBJECT_ID('nrt_srte_Code_value_clinical')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_srte_Code_value_clinical_1426684976] ON dbo.nrt_srte_Code_value_clinical ( code_set_nm, seq_num, code ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_d_hc_prov_ty_3_group_key_1430213041' AND object_id = OBJECT_ID('nrt_d_hc_prov_ty_3_group_key')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_d_hc_prov_ty_3_group_key_1430213041] ON dbo.nrt_d_hc_prov_ty_3_group_key ( D_HC_PROV_TY_3_GROUP_KEY ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_interview_copy_1433871779' AND object_id = OBJECT_ID('nrt_interview_copy')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_interview_copy_1433871779] ON dbo.nrt_interview_copy ( interview_uid ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_d_hc_prov_ty_3_key_1462213155' AND object_id = OBJECT_ID('nrt_d_hc_prov_ty_3_key')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_d_hc_prov_ty_3_key_1462213155] ON dbo.nrt_d_hc_prov_ty_3_key ( D_HC_PROV_TY_3_KEY ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_srte_State_code_1464309172' AND object_id = OBJECT_ID('nrt_srte_State_code')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_srte_State_code_1464309172] ON dbo.nrt_srte_State_code ( state_cd ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_srte_Country_XREF_1490685204' AND object_id = OBJECT_ID('nrt_srte_Country_XREF')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_srte_Country_XREF_1490685204] ON dbo.nrt_srte_Country_XREF ( country_xref_uid ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_srte_Jurisdiction_participation_1522685318' AND object_id = OBJECT_ID('nrt_srte_Jurisdiction_participation')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_srte_Jurisdiction_participation_1522685318] ON dbo.nrt_srte_Jurisdiction_participation ( jurisdiction_cd, fips_cd, type_cd ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_srte_Jurisdiction_participation_1522685318' AND object_id = OBJECT_ID('nrt_srte_Jurisdiction_participation')) BEGIN CREATE NONCLUSTERED INDEX [IX_nrt_srte_Jurisdiction_participation_1522685318] ON dbo.nrt_srte_Jurisdiction_participation ( type_cd ) WITH (PAD_INDEX = OFF, FILLFACTOR = 100  , IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_srte_Jurisdiction_participation_1522685318' AND object_id = OBJECT_ID('nrt_srte_Jurisdiction_participation')) BEGIN CREATE NONCLUSTERED INDEX [IX_nrt_srte_Jurisdiction_participation_1522685318] ON dbo.nrt_srte_Jurisdiction_participation ( fips_cd, type_cd ) WITH (PAD_INDEX = OFF, FILLFACTOR = 100  , IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_d_out_of_cntry_group_key_1542213440' AND object_id = OBJECT_ID('nrt_d_out_of_cntry_group_key')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_d_out_of_cntry_group_key_1542213440] ON dbo.nrt_d_out_of_cntry_group_key ( D_OUT_OF_CNTRY_GROUP_KEY ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_odse_Page_cond_mapping_1544309457' AND object_id = OBJECT_ID('nrt_odse_Page_cond_mapping')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_odse_Page_cond_mapping_1544309457] ON dbo.nrt_odse_Page_cond_mapping ( page_cond_mapping_uid ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_srte_LDF_page_set_1554685432' AND object_id = OBJECT_ID('nrt_srte_LDF_page_set')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_srte_LDF_page_set_1554685432] ON dbo.nrt_srte_LDF_page_set ( ldf_page_id ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_d_out_of_cntry_key_1574213554' AND object_id = OBJECT_ID('nrt_d_out_of_cntry_key')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_d_out_of_cntry_key_1574213554] ON dbo.nrt_d_out_of_cntry_key ( D_OUT_OF_CNTRY_KEY ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_odse_NBS_page_1576309571' AND object_id = OBJECT_ID('nrt_odse_NBS_page')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_odse_NBS_page_1576309571] ON dbo.nrt_odse_NBS_page ( nbs_page_uid ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_srte_Lab_result_1586685546' AND object_id = OBJECT_ID('nrt_srte_Lab_result')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_srte_Lab_result_1586685546] ON dbo.nrt_srte_Lab_result ( lab_result_cd, laboratory_id ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_srte_Lab_result_1586685546' AND object_id = OBJECT_ID('nrt_srte_Lab_result')) BEGIN CREATE UNIQUE NONCLUSTERED INDEX [IX_nrt_srte_Lab_result_1586685546] ON dbo.nrt_srte_Lab_result ( nbs_uid ) WITH (PAD_INDEX = OFF, FILLFACTOR = 90   , IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_investigation_case_management_1629296418' AND object_id = OBJECT_ID('nrt_investigation_case_management')) BEGIN CREATE NONCLUSTERED INDEX [IX_nrt_investigation_case_management_1629296418] ON dbo.nrt_investigation_case_management ( public_health_case_uid ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_investigation_case_management_1629296418' AND object_id = OBJECT_ID('nrt_investigation_case_management')) BEGIN CREATE NONCLUSTERED INDEX [IX_nrt_investigation_case_management_1629296418] ON dbo.nrt_investigation_case_management ( public_health_case_uid, case_management_uid ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_srte_Lab_result_Snomed_1634685717' AND object_id = OBJECT_ID('nrt_srte_Lab_result_Snomed')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_srte_Lab_result_Snomed_1634685717] ON dbo.nrt_srte_Lab_result_Snomed ( lab_result_cd, laboratory_id, snomed_cd ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_ldf_data_1635456150' AND object_id = OBJECT_ID('nrt_ldf_data')) BEGIN CREATE NONCLUSTERED INDEX [IX_nrt_ldf_data_1635456150] ON dbo.nrt_ldf_data ( ldf_uid ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_odse_NBS_ui_metadata_1640309799' AND object_id = OBJECT_ID('nrt_odse_NBS_ui_metadata')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_odse_NBS_ui_metadata_1640309799] ON dbo.nrt_odse_NBS_ui_metadata ( nbs_ui_metadata_uid ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_odse_NBS_ui_metadata_1640309799' AND object_id = OBJECT_ID('nrt_odse_NBS_ui_metadata')) BEGIN CREATE NONCLUSTERED INDEX [IX_nrt_odse_NBS_ui_metadata_1640309799] ON dbo.nrt_odse_NBS_ui_metadata ( question_group_seq_nbr ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_odse_NBS_ui_metadata_1640309799' AND object_id = OBJECT_ID('nrt_odse_NBS_ui_metadata')) BEGIN CREATE NONCLUSTERED INDEX [IX_nrt_odse_NBS_ui_metadata_1640309799] ON dbo.nrt_odse_NBS_ui_metadata ( question_group_seq_nbr, data_type ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_odse_NBS_ui_metadata_1640309799' AND object_id = OBJECT_ID('nrt_odse_NBS_ui_metadata')) BEGIN CREATE NONCLUSTERED INDEX [IX_nrt_odse_NBS_ui_metadata_1640309799] ON dbo.nrt_odse_NBS_ui_metadata ( data_type ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_odse_NBS_ui_metadata_1640309799' AND object_id = OBJECT_ID('nrt_odse_NBS_ui_metadata')) BEGIN CREATE NONCLUSTERED INDEX [IX_nrt_odse_NBS_ui_metadata_1640309799] ON dbo.nrt_odse_NBS_ui_metadata ( investigation_form_cd, data_type ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_odse_NBS_ui_metadata_1640309799' AND object_id = OBJECT_ID('nrt_odse_NBS_ui_metadata')) BEGIN CREATE NONCLUSTERED INDEX [IX_nrt_odse_NBS_ui_metadata_1640309799] ON dbo.nrt_odse_NBS_ui_metadata ( question_group_seq_nbr ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_odse_NBS_ui_metadata_1640309799' AND object_id = OBJECT_ID('nrt_odse_NBS_ui_metadata')) BEGIN CREATE NONCLUSTERED INDEX [IX_nrt_odse_NBS_ui_metadata_1640309799] ON dbo.nrt_odse_NBS_ui_metadata ( data_type, question_group_seq_nbr ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_odse_NBS_ui_metadata_1640309799' AND object_id = OBJECT_ID('nrt_odse_NBS_ui_metadata')) BEGIN CREATE NONCLUSTERED INDEX [IX_nrt_odse_NBS_ui_metadata_1640309799] ON dbo.nrt_odse_NBS_ui_metadata ( question_group_seq_nbr ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_d_smr_exam_ty_group_key_1654213839' AND object_id = OBJECT_ID('nrt_d_smr_exam_ty_group_key')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_d_smr_exam_ty_group_key_1654213839] ON dbo.nrt_d_smr_exam_ty_group_key ( D_SMR_EXAM_TY_GROUP_KEY ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_srte_Lab_test_1666685831' AND object_id = OBJECT_ID('nrt_srte_Lab_test')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_srte_Lab_test_1666685831] ON dbo.nrt_srte_Lab_test ( lab_test_cd, laboratory_id ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_odse_NBS_rdb_metadata_1672309913' AND object_id = OBJECT_ID('nrt_odse_NBS_rdb_metadata')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_odse_NBS_rdb_metadata_1672309913] ON dbo.nrt_odse_NBS_rdb_metadata ( nbs_rdb_metadata_uid ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_odse_NBS_rdb_metadata_1672309913' AND object_id = OBJECT_ID('nrt_odse_NBS_rdb_metadata')) BEGIN CREATE NONCLUSTERED INDEX [IX_nrt_odse_NBS_rdb_metadata_1672309913] ON dbo.nrt_odse_NBS_rdb_metadata ( rdb_table_nm ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_odse_NBS_rdb_metadata_1672309913' AND object_id = OBJECT_ID('nrt_odse_NBS_rdb_metadata')) BEGIN CREATE NONCLUSTERED INDEX [IX_nrt_odse_NBS_rdb_metadata_1672309913] ON dbo.nrt_odse_NBS_rdb_metadata ( nbs_ui_metadata_uid, rdb_table_nm ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_odse_NBS_rdb_metadata_1672309913' AND object_id = OBJECT_ID('nrt_odse_NBS_rdb_metadata')) BEGIN CREATE NONCLUSTERED INDEX [IX_nrt_odse_NBS_rdb_metadata_1672309913] ON dbo.nrt_odse_NBS_rdb_metadata ( nbs_ui_metadata_uid ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_interview_note_key_1676684675' AND object_id = OBJECT_ID('nrt_interview_note_key')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_interview_note_key_1676684675] ON dbo.nrt_interview_note_key ( d_interview_note_key ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_d_smr_exam_ty_key_1686213953' AND object_id = OBJECT_ID('nrt_d_smr_exam_ty_key')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_d_smr_exam_ty_key_1686213953] ON dbo.nrt_d_smr_exam_ty_key ( D_SMR_EXAM_TY_KEY ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_interview_key_1692684732' AND object_id = OBJECT_ID('nrt_interview_key')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_interview_key_1692684732] ON dbo.nrt_interview_key ( d_interview_key ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_srte_Labtest_Progarea_Mapping_1714686002' AND object_id = OBJECT_ID('nrt_srte_Labtest_Progarea_Mapping')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_srte_Labtest_Progarea_Mapping_1714686002] ON dbo.nrt_srte_Labtest_Progarea_Mapping ( lab_test_cd, laboratory_id ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_observation_coded_1736232594' AND object_id = OBJECT_ID('nrt_observation_coded')) BEGIN CREATE NONCLUSTERED INDEX [IX_nrt_observation_coded_1736232594] ON dbo.nrt_observation_coded ( observation_uid ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_observation_coded_1736232594' AND object_id = OBJECT_ID('nrt_observation_coded')) BEGIN CREATE NONCLUSTERED INDEX [IX_nrt_observation_coded_1736232594] ON dbo.nrt_observation_coded ( observation_uid, ovc_code ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_srte_Labtest_loinc_1746686116' AND object_id = OBJECT_ID('nrt_srte_Labtest_loinc')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_srte_Labtest_loinc_1746686116] ON dbo.nrt_srte_Labtest_loinc ( lab_test_cd, laboratory_id, loinc_cd ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_observation_date_1752232651' AND object_id = OBJECT_ID('nrt_observation_date')) BEGIN CREATE NONCLUSTERED INDEX [IX_nrt_observation_date_1752232651] ON dbo.nrt_observation_date ( observation_uid ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_observation_date_1752232651' AND object_id = OBJECT_ID('nrt_observation_date')) BEGIN CREATE NONCLUSTERED INDEX [IX_nrt_observation_date_1752232651] ON dbo.nrt_observation_date ( observation_uid ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_d_pcr_source_group_key_1766214238' AND object_id = OBJECT_ID('nrt_d_pcr_source_group_key')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_d_pcr_source_group_key_1766214238] ON dbo.nrt_d_pcr_source_group_key ( D_PCR_SOURCE_GROUP_KEY ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_observation_edx_1768232708' AND object_id = OBJECT_ID('nrt_observation_edx')) BEGIN CREATE NONCLUSTERED INDEX [IX_nrt_observation_edx_1768232708] ON dbo.nrt_observation_edx ( edx_document_uid ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_srte_Loinc_condition_1778686230' AND object_id = OBJECT_ID('nrt_srte_Loinc_condition')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_srte_Loinc_condition_1778686230] ON dbo.nrt_srte_Loinc_condition ( loinc_cd ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_observation_material_1784232765' AND object_id = OBJECT_ID('nrt_observation_material')) BEGIN CREATE NONCLUSTERED INDEX [IX_nrt_observation_material_1784232765] ON dbo.nrt_observation_material ( act_uid ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_observation_material_1784232765' AND object_id = OBJECT_ID('nrt_observation_material')) BEGIN CREATE NONCLUSTERED INDEX [IX_nrt_observation_material_1784232765] ON dbo.nrt_observation_material ( material_id ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_observation_material_1784232765' AND object_id = OBJECT_ID('nrt_observation_material')) BEGIN CREATE NONCLUSTERED INDEX [IX_nrt_observation_material_1784232765] ON dbo.nrt_observation_material ( act_uid, material_id ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_d_pcr_source_key_1798214352' AND object_id = OBJECT_ID('nrt_d_pcr_source_key')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_d_pcr_source_key_1798214352] ON dbo.nrt_d_pcr_source_key ( D_PCR_SOURCE_KEY ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_observation_numeric_1800232822' AND object_id = OBJECT_ID('nrt_observation_numeric')) BEGIN CREATE NONCLUSTERED INDEX [IX_nrt_observation_numeric_1800232822] ON dbo.nrt_observation_numeric ( observation_uid ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_srte_Loinc_snomed_condition_1810686344' AND object_id = OBJECT_ID('nrt_srte_Loinc_snomed_condition')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_srte_Loinc_snomed_condition_1810686344] ON dbo.nrt_srte_Loinc_snomed_condition ( loinc_snomed_cc_uid ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_observation_reason_1816232879' AND object_id = OBJECT_ID('nrt_observation_reason')) BEGIN CREATE NONCLUSTERED INDEX [IX_nrt_observation_reason_1816232879] ON dbo.nrt_observation_reason ( observation_uid ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_observation_txt_1832232936' AND object_id = OBJECT_ID('nrt_observation_txt')) BEGIN CREATE NONCLUSTERED INDEX [IX_nrt_observation_txt_1832232936] ON dbo.nrt_observation_txt ( observation_uid ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_srte_Occupation_code_1842686458' AND object_id = OBJECT_ID('nrt_srte_Occupation_code')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_srte_Occupation_code_1842686458] ON dbo.nrt_srte_Occupation_code ( code ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_auth_user_1885114602' AND object_id = OBJECT_ID('nrt_auth_user')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_auth_user_1885114602] ON dbo.nrt_auth_user ( auth_user_uid ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_srte_Zipcnty_code_value_1890686629' AND object_id = OBJECT_ID('nrt_srte_Zipcnty_code_value')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_srte_Zipcnty_code_value_1890686629] ON dbo.nrt_srte_Zipcnty_code_value ( zip_code, cnty_code ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_srte_TotalIDM_1940782817' AND object_id = OBJECT_ID('nrt_srte_TotalIDM')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_srte_TotalIDM_1940782817] ON dbo.nrt_srte_TotalIDM ( TotalIDM_id ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_vaccination_1946354844' AND object_id = OBJECT_ID('nrt_vaccination')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_vaccination_1946354844] ON dbo.nrt_vaccination ( vaccination_uid ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_interview_answer_1965297615' AND object_id = OBJECT_ID('nrt_interview_answer')) BEGIN CREATE NONCLUSTERED INDEX [IX_nrt_interview_answer_1965297615] ON dbo.nrt_interview_answer ( interview_uid ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_interview_answer_1965297615' AND object_id = OBJECT_ID('nrt_interview_answer')) BEGIN CREATE NONCLUSTERED INDEX [IX_nrt_interview_answer_1965297615] ON dbo.nrt_interview_answer ( interview_uid, rdb_column_nm ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_srte_IMRDBMapping_1972782931' AND object_id = OBJECT_ID('nrt_srte_IMRDBMapping')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_srte_IMRDBMapping_1972782931] ON dbo.nrt_srte_IMRDBMapping ( IMRDBMapping_id ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_srte_Condition_code_2004783045' AND object_id = OBJECT_ID('nrt_srte_Condition_code')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_srte_Condition_code_2004783045] ON dbo.nrt_srte_Condition_code ( condition_cd ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_srte_Condition_code_2004783045' AND object_id = OBJECT_ID('nrt_srte_Condition_code')) BEGIN CREATE UNIQUE NONCLUSTERED INDEX [IX_nrt_srte_Condition_code_2004783045] ON dbo.nrt_srte_Condition_code ( nbs_uid ) WITH (PAD_INDEX = OFF, FILLFACTOR = 90   , IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_organization_key_2026589912' AND object_id = OBJECT_ID('nrt_organization_key')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_organization_key_2026589912] ON dbo.nrt_organization_key ( d_organization_key ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_organization_key_2026589912' AND object_id = OBJECT_ID('nrt_organization_key')) BEGIN CREATE NONCLUSTERED INDEX [IX_nrt_organization_key_2026589912] ON dbo.nrt_organization_key ( organization_uid ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_provider_key_2042589969' AND object_id = OBJECT_ID('nrt_provider_key')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_provider_key_2042589969] ON dbo.nrt_provider_key ( d_provider_key ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_interview_NOV22_2043969962' AND object_id = OBJECT_ID('nrt_interview_NOV22')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_interview_NOV22_2043969962] ON dbo.nrt_interview_NOV22 ( interview_uid ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_NBS_configuration_2052783216' AND object_id = OBJECT_ID('nrt_NBS_configuration')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_NBS_configuration_2052783216] ON dbo.nrt_NBS_configuration ( config_key ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_patient_key_2058590026' AND object_id = OBJECT_ID('nrt_patient_key')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_patient_key_2058590026] ON dbo.nrt_patient_key ( d_patient_key ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_investigation_key_2074590083' AND object_id = OBJECT_ID('nrt_investigation_key')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_investigation_key_2074590083] ON dbo.nrt_investigation_key ( d_investigation_key ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_confirmation_method_key_2090590140' AND object_id = OBJECT_ID('nrt_confirmation_method_key')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_confirmation_method_key_2090590140] ON dbo.nrt_confirmation_method_key ( d_confirmation_method_key ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_interview_2091970133' AND object_id = OBJECT_ID('nrt_interview')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_interview_2091970133] ON dbo.nrt_interview ( interview_uid ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'IX_nrt_case_management_key_2106590197' AND object_id = OBJECT_ID('nrt_case_management_key')) BEGIN CREATE UNIQUE CLUSTERED INDEX [IX_nrt_case_management_key_2106590197] ON dbo.nrt_case_management_key ( d_case_management_key ) WITH (PAD_INDEX = OFF, IGNORE_DUP_KEY = OFF, STATISTICS_NORECOMPUTE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON ) ON [PRIMARY]
 END

