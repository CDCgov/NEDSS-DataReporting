--Consolidated Recommendations for Indexes

--CNDE-2945 Notes: Performing well. Recommended to keep.
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_page_case_answer_nbs_case_answer_uid_question_uid' AND object_id = OBJECT_ID('dbo.nrt_page_case_answer'))
BEGIN
CREATE INDEX idx_nrt_page_case_answer_nbs_case_answer_uid_question_uid ON dbo.nrt_page_case_answer (nbs_case_answer_uid, nbs_question_uid);
END

--CNDE-2945 Notes: Performing well. Recommended to keep.
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_phc_id_obs_id_branch_id' AND object_id = OBJECT_ID('dbo.nrt_investigation_observation'))
BEGIN
CREATE INDEX idx_phc_id_obs_id_branch_id ON dbo.nrt_investigation_observation (public_health_case_uid, observation_id, branch_id);
END

--CNDE-2945 Notes: Performing well. Recommended to keep.
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_phc_uid_case_mgmt_uid' AND object_id = OBJECT_ID('dbo.nrt_investigation_case_management'))
BEGIN
CREATE INDEX idx_phc_uid_case_mgmt_uid ON dbo.nrt_investigation_case_management (public_health_case_uid, case_management_uid);
END

--CNDE-2945 Notes: Performing well. Recommended to keep.
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_inv_conf_phc_uid' AND object_id = OBJECT_ID('dbo.nrt_investigation_confirmation'))
BEGIN
CREATE INDEX idx_inv_conf_phc_uid ON dbo.nrt_investigation_confirmation (public_health_case_uid);
END

--CNDE-2945 Notes: Performing well. Recommended to keep.
    IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_obs_coded_obs_uid_code' AND object_id = OBJECT_ID('dbo.nrt_observation_coded'))
BEGIN
CREATE INDEX idx_nrt_obs_coded_obs_uid_code ON dbo.nrt_observation_coded (observation_uid, ovc_code);
END

--CNDE-2945 Notes: Performing well. Recommended to keep.
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_inv_notf_notf_uid' AND object_id = OBJECT_ID('dbo.nrt_investigation_notification'))
BEGIN
CREATE INDEX idx_nrt_inv_notf_notf_uid ON dbo.nrt_investigation_notification (notification_uid);
END

--CNDE-2945 Notes: Performing well. Recommended to keep.
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_ldf_data_ldf_uid' AND object_id = OBJECT_ID('dbo.nrt_ldf_data'))
BEGIN
CREATE INDEX idx_nrt_ldf_data_ldf_uid ON dbo.nrt_ldf_data (ldf_uid);
END

--CNDE-2945 Notes: Performing well. Recommended to keep.
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_obs_date_obs_uid' AND object_id = OBJECT_ID('dbo.nrt_observation_date'))
BEGIN
CREATE INDEX idx_nrt_obs_date_obs_uid ON dbo.nrt_observation_date (observation_uid);
END

--CNDE-2945 Notes: Performing well. Recommended to keep.
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_obs_material_material_id' AND object_id = OBJECT_ID('dbo.nrt_observation_material'))
BEGIN
CREATE INDEX idx_nrt_obs_material_material_id ON dbo.nrt_observation_material (material_id);
END

--CNDE-2945 Notes: Performing well. Recommended to keep.
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_obs_numeric_obs_uid' AND object_id = OBJECT_ID('dbo.nrt_observation_numeric'))
BEGIN
CREATE INDEX idx_nrt_obs_numeric_obs_uid ON dbo.nrt_observation_numeric (observation_uid);
END

--CNDE-2945 Notes: Performing well. Recommended to keep.
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_obs_reason_obs_uid' AND object_id = OBJECT_ID('dbo.nrt_observation_reason'))
BEGIN
CREATE INDEX idx_nrt_obs_reason_obs_uid ON dbo.nrt_observation_reason (observation_uid);
END

--CNDE-2945 Notes: Performing well. Recommended to keep.
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_obs_txt_obs_uid' AND object_id = OBJECT_ID('dbo.nrt_observation_txt'))
BEGIN
CREATE INDEX idx_nrt_obs_txt_obs_uid ON dbo.nrt_observation_txt (observation_uid);
END

--CNDE-2945 Notes: Not frequently used. Please continue monitor performance and add index if necessary.
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_phc_uid' AND object_id = OBJECT_ID('dbo.nrt_investigation_case_management'))
BEGIN
CREATE INDEX idx_phc_uid ON dbo.nrt_investigation_case_management (public_health_case_uid);
END

--CNDE-2945 Notes: Not frequently used. Please continue monitor performance and add index if necessary.
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_CONTACT_UID' AND object_id = OBJECT_ID('dbo.nrt_contact'))
BEGIN
CREATE INDEX idx_CONTACT_UID ON dbo.nrt_contact (CONTACT_UID);
END

--CNDE-2945 Notes: Not frequently used. Please continue monitor performance and add index if necessary.
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_contact_uid' AND object_id = OBJECT_ID('dbo.nrt_contact_answer'))
BEGIN
CREATE INDEX idx_contact_uid ON dbo.nrt_contact_answer (contact_uid);
END

--CNDE-2945 Notes: Not frequently used. Please continue monitor performance and add index if necessary.
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_contact_uid_rdb_column' AND object_id = OBJECT_ID('dbo.nrt_contact_answer'))
BEGIN
CREATE INDEX idx_contact_uid_rdb_column ON dbo.nrt_contact_answer (contact_uid,rdb_column_nm);
END

--CNDE-2859: Evaluate performance and create index if needed.
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_place_tele_place_uid' AND object_id = OBJECT_ID('dbo.nrt_place_tele'))
BEGIN
CREATE INDEX idx_nrt_place_tele_place_uid ON dbo.nrt_place_tele (place_uid);
END

--CNDE-2945 Notes: Not frequently used. Please continue monitor performance and add index if necessary.
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_interview_uid_rdb_column' AND object_id = OBJECT_ID('dbo.nrt_interview_answer'))
BEGIN
CREATE INDEX idx_interview_uid_rdb_column ON dbo.nrt_interview_answer (interview_uid, rdb_column_nm);
END

--CNDE-2945 Notes: Not frequently used. Please continue monitor performance and add index if necessary.
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_interview_uid' AND object_id = OBJECT_ID('dbo.nrt_interview_answer'))
BEGIN
CREATE INDEX idx_interview_uid ON dbo.nrt_interview_answer (interview_uid);
END

--CNDE-2945 Notes: Not frequently used. Please continue monitor performance and add index if necessary.
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_interview_uid' AND object_id = OBJECT_ID('dbo.nrt_interview_note'))
BEGIN
CREATE INDEX idx_interview_uid ON dbo.nrt_interview_note (interview_uid);
END

--CNDE-2945 Notes: Updates are greater than reads. Index should be dropped and optimized.
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_phc_id' AND object_id = OBJECT_ID('dbo.nrt_investigation_observation'))
BEGIN
CREATE INDEX idx_phc_id ON dbo.nrt_investigation_observation (public_health_case_uid);
END

--CNDE-2945 Notes: Updates are greater than reads. Index should be dropped and optimized.
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_inv_notf_phc_uid' AND object_id = OBJECT_ID('dbo.nrt_investigation_notification'))
BEGIN
CREATE INDEX idx_nrt_inv_notf_phc_uid ON dbo.nrt_investigation_notification (public_health_case_uid);
END

--CNDE-2945 Notes: Updates are greater than reads. Index should be dropped and optimized.
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_inv_notf_phc_uid_act_uid' AND object_id = OBJECT_ID('dbo.nrt_investigation_notification'))
BEGIN
CREATE INDEX idx_nrt_inv_notf_phc_uid_act_uid ON dbo.nrt_investigation_notification (public_health_case_uid, source_act_uid);
END

--CNDE-2945 Notes: Updates are greater than reads. Index should be dropped and optimized.
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_obs_coded_obs_uid' AND object_id = OBJECT_ID('dbo.nrt_observation_coded'))
BEGIN
CREATE INDEX idx_nrt_obs_coded_obs_uid ON dbo.nrt_observation_coded (observation_uid);
END

--CNDE-2945 Notes: Updates are greater than reads. Index should be dropped and optimized.
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_obs_edx_uid' AND object_id = OBJECT_ID('dbo.nrt_observation_edx'))
BEGIN
CREATE INDEX idx_nrt_obs_edx_uid ON dbo.nrt_observation_edx (edx_document_uid);
END

--CNDE-2945 Notes: Updates are greater than reads. Index should be dropped and optimized.
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_obs_material_act_uid' AND object_id = OBJECT_ID('dbo.nrt_observation_material'))
BEGIN
CREATE INDEX idx_nrt_obs_material_act_uid ON dbo.nrt_observation_material (act_uid);
END

--CNDE-2945 Notes: Updates are greater than reads. Index should be dropped and optimized.
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_obs_material_act_uid_material_id' AND object_id = OBJECT_ID('dbo.nrt_observation_material'))
BEGIN
CREATE INDEX idx_nrt_obs_material_act_uid_material_id ON dbo.nrt_observation_material (act_uid, material_id);
END

--CNDE-2945 Notes: Updates are greater than reads. Index should be dropped and optimized.
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_org_organization_uid' AND object_id = OBJECT_ID('dbo.nrt_organization'))
BEGIN
CREATE INDEX idx_nrt_org_organization_uid ON dbo.nrt_organization (organization_uid);
END

--CNDE-2945 Notes: Updates are greater than reads. Index should be dropped and optimized.
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_page_case_answer_nbs_case_answer_uid' AND object_id = OBJECT_ID('dbo.nrt_page_case_answer'))
BEGIN
CREATE INDEX idx_nrt_page_case_answer_nbs_case_answer_uid ON dbo.nrt_page_case_answer (nbs_case_answer_uid);
END

--CNDE-2945 Notes: Updates are greater than reads. Index should be dropped and optimized.
IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_nrt_page_case_answer_act_uid' AND object_id = OBJECT_ID('dbo.nrt_page_case_answer'))
BEGIN
CREATE INDEX idx_nrt_page_case_answer_act_uid ON dbo.nrt_page_case_answer (act_uid);
END