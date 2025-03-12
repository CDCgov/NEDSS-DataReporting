IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_phc_id' AND object_id = OBJECT_ID('dbo.nrt_investigation_observation'))
BEGIN
	CREATE INDEX idx_phc_id ON dbo.nrt_investigation_observation (public_health_case_uid);
END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_phc_id_obs_id_branch_id' AND object_id = OBJECT_ID('dbo.nrt_investigation_observation'))
BEGIN
	CREATE INDEX idx_phc_id_obs_id_branch_id
	ON dbo.nrt_investigation_observation (public_health_case_uid, observation_id, branch_id);
END

IF NOT EXISTS(SELECT 1 FROM sys.objects WHERE type = 'PK' AND  parent_object_id = OBJECT_ID ('dbo.nrt_investigation_key'))
BEGIN
ALTER TABLE dbo.nrt_investigation_key ADD CONSTRAINT nrt_investigation_key_pk PRIMARY KEY (d_investigation_key);
END

IF NOT EXISTS(SELECT 1 FROM sys.objects WHERE type = 'PK' AND  parent_object_id = OBJECT_ID ('dbo.nrt_case_management_key'))
BEGIN
ALTER TABLE dbo.nrt_case_management_key ADD CONSTRAINT nrt_case_management_key_pk PRIMARY KEY (d_case_management_key);
END

IF NOT EXISTS(SELECT 1 FROM sys.objects WHERE type = 'PK' AND  parent_object_id = OBJECT_ID ('dbo.nrt_confirmation_method_key'))
BEGIN
ALTER TABLE dbo.nrt_confirmation_method_key ADD CONSTRAINT nrt_confirmation_method_key_pk PRIMARY KEY (d_confirmation_method_key);
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


IF NOT EXISTS(SELECT 1 FROM sys.objects WHERE type = 'PK' AND  parent_object_id = OBJECT_ID ('dbo.nrt_contact_key'))
BEGIN
ALTER TABLE dbo.nrt_contact_key ADD CONSTRAINT pk_d_contact_record_key PRIMARY KEY (d_contact_record_key);
END


IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_interview_uid_rdb_column' AND object_id = OBJECT_ID('dbo.nrt_interview_answer'))
BEGIN
	CREATE INDEX idx_interview_uid_rdb_column ON dbo.nrt_interview_answer (interview_uid, rdb_column_nm);
END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_interview_uid' AND object_id = OBJECT_ID('dbo.nrt_interview_answer'))
BEGIN
	CREATE INDEX idx_interview_uid ON dbo.nrt_interview_answer (interview_uid);
END

IF NOT EXISTS(SELECT 1 FROM sys.objects WHERE type = 'PK' AND  parent_object_id = OBJECT_ID ('dbo.nrt_interview_key'))
BEGIN
ALTER TABLE dbo.nrt_interview_key ADD CONSTRAINT pk_d_interview_key PRIMARY KEY (d_interview_key);
END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_interview_uid' AND object_id = OBJECT_ID('dbo.nrt_interview_note'))
BEGIN
	CREATE INDEX idx_interview_uid ON dbo.nrt_interview_note (interview_uid);
END

IF NOT EXISTS(SELECT 1 FROM sys.objects WHERE type = 'PK' AND  parent_object_id = OBJECT_ID ('dbo.nrt_interview_note_key'))
BEGIN
ALTER TABLE dbo.nrt_interview_note_key ADD CONSTRAINT pk_d_interview_note_key PRIMARY KEY (d_interview_note_key);
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

IF NOT EXISTS(SELECT 1 FROM sys.objects WHERE type = 'PK' AND  parent_object_id = OBJECT_ID ('dbo.nrt_ldf_data_key'))
BEGIN
ALTER TABLE dbo.nrt_ldf_data_key ADD CONSTRAINT pk_ldf_data_key PRIMARY KEY (d_ldf_data_key);
END

IF NOT EXISTS(SELECT 1 FROM sys.objects WHERE type = 'PK' AND  parent_object_id = OBJECT_ID ('dbo.nrt_ldf_group_key'))
BEGIN
ALTER TABLE dbo.nrt_ldf_group_key ADD CONSTRAINT pk_ldf_group_key PRIMARY KEY (d_ldf_group_key);
END
IF NOT EXISTS(SELECT 1 FROM sys.objects WHERE type = 'PK' AND  parent_object_id = OBJECT_ID ('dbo.nrt_notification_key'))
BEGIN
ALTER TABLE dbo.nrt_notification_key ADD CONSTRAINT pk_notification_key PRIMARY KEY (d_notification_key);
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

IF NOT EXISTS(SELECT 1 FROM sys.objects WHERE type = 'PK' AND  parent_object_id = OBJECT_ID ('dbo.nrt_organization_key'))
BEGIN
ALTER TABLE dbo.nrt_organization_key ADD CONSTRAINT nrt_organization_key_pk PRIMARY KEY (d_organization_key);
END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_page_case_answer_nbs_case_answer_uid_question_uid' AND object_id = OBJECT_ID('dbo.nrt_page_case_answer'))
BEGIN
CREATE INDEX idx_nrt_page_case_answer_nbs_case_answer_uid_question_uid ON dbo.nrt_page_case_answer (nbs_case_answer_uid, nbs_question_uid);
END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_page_case_answer_nbs_case_answer_uid' AND object_id = OBJECT_ID('dbo.nrt_page_case_answer'))
BEGIN
CREATE INDEX idx_nrt_page_case_answer_nbs_case_answer_uid ON dbo.nrt_page_case_answer (nbs_case_answer_uid);
END

IF NOT EXISTS(SELECT 1 FROM sys.objects WHERE type = 'PK' AND  parent_object_id = OBJECT_ID ('dbo.nrt_patient_key'))
BEGIN
ALTER TABLE dbo.nrt_patient_key ADD CONSTRAINT pk_d_patient_key PRIMARY KEY (d_patient_key);
END

IF NOT EXISTS(SELECT 1 FROM sys.objects WHERE type = 'PK' AND  parent_object_id = OBJECT_ID ('dbo.nrt_place_key'))
BEGIN
ALTER TABLE dbo.nrt_place_key ADD CONSTRAINT pk_d_place_key_pk PRIMARY KEY (d_place_key);
END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_place_tele_place_uid' AND object_id = OBJECT_ID('dbo.nrt_place_tele'))
BEGIN
CREATE INDEX idx_nrt_place_tele_place_uid ON dbo.nrt_place_tele (place_uid);
END

IF NOT EXISTS(SELECT 1 FROM sys.objects WHERE type = 'PK' AND  parent_object_id = OBJECT_ID ('dbo.nrt_provider_key'))
BEGIN
ALTER TABLE dbo.nrt_provider_key ADD CONSTRAINT pk_d_provider_key PRIMARY KEY (d_provider_key);
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



