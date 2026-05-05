USE [RDB_Modern];
DECLARE @superuser_id bigint = 10009282;

-- Adjust the UID declarations below manually so they remain unique across other tests.
DECLARE @dbo_nrt_patient_patient_uid bigint = 20002020;
DECLARE @dbo_nrt_patient_patient_uid_2 bigint = 20002021; --10009285
DECLARE @dbo_nrt_investigation_public_health_case_uid bigint = 20002022; -- 10009287
DECLARE @dbo_nrt_patient_patient_uid_3 bigint = 20002023;
DECLARE @dbo_nrt_patient_patient_uid_4 bigint = 20002024; -- 10009289
DECLARE @dbo_nrt_patient_local_id nvarchar(40) = N'PSN' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_nrt_patient_patient_uid))) + N'GA01';
DECLARE @dbo_nrt_patient_patient_mpr_uid bigint = @dbo_nrt_patient_patient_uid + 1;
DECLARE @dbo_nrt_patient_key_d_patient_key bigint;
DECLARE @dbo_nrt_patient_key_d_patient_key_output TABLE ([value] bigint);
DECLARE @dbo_nrt_investigation_local_id nvarchar(40) = N'CAS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_nrt_investigation_public_health_case_uid))) + N'GA01';
DECLARE @dbo_nrt_patient_key_d_patient_key_2 bigint;
DECLARE @dbo_nrt_patient_key_d_patient_key_2_output TABLE ([value] bigint);
DECLARE @dbo_nrt_investigation_key_d_investigation_key bigint;
DECLARE @dbo_nrt_investigation_key_d_investigation_key_output TABLE ([value] bigint);
DECLARE @dbo_nrt_patient_local_id_2 nvarchar(40) = N'PSN' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_nrt_patient_patient_uid_3))) + N'GA01';
DECLARE @dbo_nrt_patient_patient_mpr_uid_2 bigint = @dbo_nrt_patient_patient_uid_3 + 1;
DECLARE @dbo_nrt_patient_key_d_patient_key_3 bigint;
DECLARE @dbo_nrt_patient_key_d_patient_key_3_output TABLE ([value] bigint);
DECLARE @dbo_nrt_patient_key_d_patient_key_4 bigint;
DECLARE @dbo_nrt_patient_key_d_patient_key_4_output TABLE ([value] bigint);
DECLARE @dbo_nrt_contact_key_d_contact_record_key bigint;
DECLARE @dbo_nrt_contact_key_d_contact_record_key_output TABLE ([value] bigint);

-- STEP 1: Add patient with Covid investigation with Contact record
-- dbo.nrt_backfill
-- step: 1
UPDATE [dbo].[nrt_backfill] SET [record_uid_list] = N'10015000', [status_cd] = N'COMPLETE', [retry_count] = 1, [updated_dttm] = N'2026-05-05T16:00:16.3366667' WHERE [record_key] = 1 AND [entity] = N'NBS_PAGE' AND [batch_id] = 1820668514462321 AND [err_description] = N'Missing NRT Record: sp_nrt_odse_nbs_page_postprocessing' AND [status_cd] = N'READY' AND [retry_count] = 0 AND [created_dttm] = N'2026-05-05T15:57:16.2766667' AND [updated_dttm] = N'2026-05-05T15:57:16.2766667';
-- dbo.nrt_patient
-- step: 1
INSERT INTO [dbo].[nrt_patient] ([patient_uid], [patient_mpr_uid], [record_status], [local_id], [first_name], [last_name], [nm_use_cd], [status_name_cd], [street_address_1], [street_address_2], [state], [state_code], [country], [country_code], [entry_method], [add_user_id], [add_user_name], [add_time], [last_chg_user_id], [last_chg_user_name], [last_chg_time]) VALUES (@dbo_nrt_patient_patient_uid, @dbo_nrt_patient_patient_mpr_uid, N'ACTIVE', @dbo_nrt_patient_local_id, N'Covid', N'Patient', N'L', N'A', N'', N'', N'Georgia', N'13', N'United States', N'840', N'N', @superuser_id, N'Kent, Ariella', N'2026-05-05T16:00:47.087', @superuser_id, N'Kent, Ariella', N'2026-05-05T16:00:47.087');
-- dbo.nrt_patient_key
-- step: 1
INSERT INTO [dbo].[nrt_patient_key] ([patient_uid], [created_dttm], [updated_dttm]) OUTPUT INSERTED.[d_patient_key] INTO @dbo_nrt_patient_key_d_patient_key_output ([value]) VALUES (@dbo_nrt_patient_patient_uid, N'2026-05-05T16:00:56.3166667', N'2026-05-05T16:00:56.3166667');
SELECT TOP 1 @dbo_nrt_patient_key_d_patient_key = [value] FROM @dbo_nrt_patient_key_d_patient_key_output;
-- dbo.D_PATIENT
-- step: 1
INSERT INTO [dbo].[D_PATIENT] ([PATIENT_KEY], [PATIENT_MPR_UID], [PATIENT_RECORD_STATUS], [PATIENT_LOCAL_ID], [PATIENT_FIRST_NAME], [PATIENT_LAST_NAME], [PATIENT_STATE], [PATIENT_STATE_CODE], [PATIENT_COUNTRY], [PATIENT_ENTRY_METHOD], [PATIENT_LAST_CHANGE_TIME], [PATIENT_UID], [PATIENT_ADD_TIME], [PATIENT_ADDED_BY], [PATIENT_LAST_UPDATED_BY]) VALUES (@dbo_nrt_patient_key_d_patient_key, @dbo_nrt_patient_patient_mpr_uid, N'ACTIVE', @dbo_nrt_patient_local_id, N'Covid', N'Patient', N'Georgia', N'13', N'United States', N'N', N'2026-05-05T16:00:47.087', @dbo_nrt_patient_patient_uid, N'2026-05-05T16:00:47.087', N'Kent, Ariella', N'Kent, Ariella');
-- dbo.nrt_patient
-- step: 1
INSERT INTO [dbo].[nrt_patient] ([patient_uid], [patient_mpr_uid], [record_status], [local_id], [first_name], [last_name], [nm_use_cd], [status_name_cd], [state], [state_code], [country], [country_code], [age_reported], [age_reported_unit], [age_reported_unit_cd], [entry_method], [add_user_id], [add_user_name], [add_time], [last_chg_user_id], [last_chg_user_name], [last_chg_time]) VALUES (@dbo_nrt_patient_patient_uid_2, @dbo_nrt_patient_patient_mpr_uid, N'ACTIVE', @dbo_nrt_patient_local_id, N'Covid', N'Patient', N'L', N'A', N'Georgia', N'13', N'United States', N'840', 42, N'Years', N'Y', N'N', @superuser_id, N'Kent, Ariella', N'2026-05-05T16:01:08.920', @superuser_id, N'Kent, Ariella', N'2026-05-05T16:01:08.920');
-- step: 1
UPDATE [dbo].[nrt_patient] SET [last_chg_time] = N'2026-05-05T16:01:08.903' WHERE [patient_uid] = @dbo_nrt_patient_patient_uid;
-- dbo.nrt_investigation
-- step: 1
INSERT INTO [dbo].[nrt_investigation] ([public_health_case_uid], [program_jurisdiction_oid], [local_id], [shared_ind], [investigation_status], [case_type_cd], [jurisdiction_cd], [jurisdiction_nm], [activity_from_time], [mmwr_week], [mmwr_year], [city_county_case_nbr], [record_status_cd], [program_area_description], [add_user_id], [add_user_name], [add_time], [last_chg_user_id], [last_chg_user_name], [last_chg_time], [legacy_case_id], [investigation_status_cd], [patient_id], [mood_cd], [class_cd], [case_class_cd], [cd], [cd_desc_txt], [prog_area_cd], [inv_state_case_id], [nac_page_case_uid], [nac_last_chg_time], [nac_add_time], [investigation_form_cd], [investigation_count], [case_count], [record_status_time], [raw_record_status_cd], [batch_id]) VALUES (@dbo_nrt_investigation_public_health_case_uid, 1300100009, @dbo_nrt_investigation_local_id, N'T', N'Open', N'I', N'130001', N'Fulton County', N'2026-05-05T00:00:00', N'18', N'2026', N'', N'ACTIVE', N'GCD', @superuser_id, N'Kent, Ariella', N'2026-05-05T16:01:08.953', @superuser_id, N'Kent, Ariella', N'2026-05-05T16:01:08.953', N'', N'O', @dbo_nrt_patient_patient_uid_2, N'EVN', N'CASE', N'', N'11065', N'2019 Novel Coronavirus', N'GCD', N'', @dbo_nrt_investigation_public_health_case_uid, N'2026-05-05T16:01:08.953', N'2026-05-05T16:01:08.953', N'PG_COVID-19_v1.1', 1, 1, N'2026-05-05T16:01:08.953', N'OPEN', 1777996873984);
-- dbo.nrt_patient_key
-- step: 1
UPDATE [dbo].[nrt_patient_key] SET [updated_dttm] = N'2026-05-05T16:01:16.8800000' WHERE [d_patient_key] = @dbo_nrt_patient_key_d_patient_key;
-- dbo.D_PATIENT
-- step: 1
DELETE FROM [dbo].[D_PATIENT] WHERE [PATIENT_KEY] = @dbo_nrt_patient_key_d_patient_key;
-- step: 1
INSERT INTO [dbo].[D_PATIENT] ([PATIENT_KEY], [PATIENT_MPR_UID], [PATIENT_RECORD_STATUS], [PATIENT_LOCAL_ID], [PATIENT_FIRST_NAME], [PATIENT_LAST_NAME], [PATIENT_STATE], [PATIENT_STATE_CODE], [PATIENT_COUNTRY], [PATIENT_ENTRY_METHOD], [PATIENT_LAST_CHANGE_TIME], [PATIENT_UID], [PATIENT_ADD_TIME], [PATIENT_ADDED_BY], [PATIENT_LAST_UPDATED_BY]) VALUES (@dbo_nrt_patient_key_d_patient_key, @dbo_nrt_patient_patient_mpr_uid, N'ACTIVE', @dbo_nrt_patient_local_id, N'Covid', N'Patient', N'Georgia', N'13', N'United States', N'N', N'2026-05-05T16:01:08.903', @dbo_nrt_patient_patient_uid, N'2026-05-05T16:00:47.087', N'Kent, Ariella', N'Kent, Ariella');
-- dbo.nrt_patient_key
-- step: 1
INSERT INTO [dbo].[nrt_patient_key] ([patient_uid], [created_dttm], [updated_dttm]) OUTPUT INSERTED.[d_patient_key] INTO @dbo_nrt_patient_key_d_patient_key_2_output ([value]) VALUES (@dbo_nrt_patient_patient_uid_2, N'2026-05-05T16:01:16.8933333', N'2026-05-05T16:01:16.8933333');
SELECT TOP 1 @dbo_nrt_patient_key_d_patient_key_2 = [value] FROM @dbo_nrt_patient_key_d_patient_key_2_output;
-- dbo.D_PATIENT
-- step: 1
INSERT INTO [dbo].[D_PATIENT] ([PATIENT_KEY], [PATIENT_MPR_UID], [PATIENT_RECORD_STATUS], [PATIENT_LOCAL_ID], [PATIENT_FIRST_NAME], [PATIENT_LAST_NAME], [PATIENT_STATE], [PATIENT_STATE_CODE], [PATIENT_COUNTRY], [PATIENT_AGE_REPORTED], [PATIENT_AGE_REPORTED_UNIT], [PATIENT_ENTRY_METHOD], [PATIENT_LAST_CHANGE_TIME], [PATIENT_UID], [PATIENT_ADD_TIME], [PATIENT_ADDED_BY], [PATIENT_LAST_UPDATED_BY]) VALUES (@dbo_nrt_patient_key_d_patient_key_2, @dbo_nrt_patient_patient_mpr_uid, N'ACTIVE', @dbo_nrt_patient_local_id, N'Covid', N'Patient', N'Georgia', N'13', N'United States', 42, N'Years', N'N', N'2026-05-05T16:01:08.920', @dbo_nrt_patient_patient_uid_2, N'2026-05-05T16:01:08.920', N'Kent, Ariella', N'Kent, Ariella');
-- dbo.nrt_investigation_key
-- step: 1
INSERT INTO [dbo].[nrt_investigation_key] ([case_uid], [created_dttm], [updated_dttm]) OUTPUT INSERTED.[d_investigation_key] INTO @dbo_nrt_investigation_key_d_investigation_key_output ([value]) VALUES (@dbo_nrt_investigation_public_health_case_uid, N'2026-05-05T16:01:17.1566667', N'2026-05-05T16:01:17.1566667');
SELECT TOP 1 @dbo_nrt_investigation_key_d_investigation_key = [value] FROM @dbo_nrt_investigation_key_d_investigation_key_output;
-- dbo.INVESTIGATION
-- step: 1
INSERT INTO [dbo].[INVESTIGATION] ([INVESTIGATION_KEY], [CASE_OID], [CASE_UID], [INV_LOCAL_ID], [INV_SHARE_IND], [INVESTIGATION_STATUS], [CASE_TYPE], [JURISDICTION_CD], [JURISDICTION_NM], [INV_START_DT], [CASE_RPT_MMWR_WK], [CASE_RPT_MMWR_YR], [RECORD_STATUS_CD], [PROGRAM_AREA_DESCRIPTION], [ADD_TIME], [LAST_CHG_TIME], [INVESTIGATION_ADDED_BY], [INVESTIGATION_LAST_UPDATED_BY]) VALUES (@dbo_nrt_investigation_key_d_investigation_key, 1300100009, @dbo_nrt_investigation_public_health_case_uid, @dbo_nrt_investigation_local_id, N'T', N'Open', N'I', N'130001', N'Fulton County', N'2026-05-05T00:00:00', 18, 2026, N'ACTIVE', N'GCD', N'2026-05-05T16:01:08.953', N'2026-05-05T16:01:08.953', N'Kent, Ariella', N'Kent, Ariella');
-- dbo.CONFIRMATION_METHOD_GROUP
-- step: 1
INSERT INTO [dbo].[CONFIRMATION_METHOD_GROUP] ([INVESTIGATION_KEY], [CONFIRMATION_METHOD_KEY]) VALUES (@dbo_nrt_investigation_key_d_investigation_key, 1);
-- dbo.F_PAGE_CASE
-- step: 1
INSERT INTO [dbo].[F_PAGE_CASE] ([D_INV_ADMINISTRATIVE_KEY], [D_INV_CLINICAL_KEY], [D_INV_COMPLICATION_KEY], [D_INV_CONTACT_KEY], [D_INV_DEATH_KEY], [D_INV_EPIDEMIOLOGY_KEY], [D_INV_HIV_KEY], [D_INV_PATIENT_OBS_KEY], [D_INV_ISOLATE_TRACKING_KEY], [D_INV_LAB_FINDING_KEY], [D_INV_MEDICAL_HISTORY_KEY], [D_INV_MOTHER_KEY], [D_INV_OTHER_KEY], [D_INV_PREGNANCY_BIRTH_KEY], [D_INV_RESIDENCY_KEY], [D_INV_RISK_FACTOR_KEY], [D_INV_SOCIAL_HISTORY_KEY], [D_INV_SYMPTOM_KEY], [D_INV_TREATMENT_KEY], [D_INV_TRAVEL_KEY], [D_INV_UNDER_CONDITION_KEY], [D_INV_VACCINATION_KEY], [D_INVESTIGATION_REPEAT_KEY], [D_INV_PLACE_REPEAT_KEY], [CONDITION_KEY], [INVESTIGATION_KEY], [PHYSICIAN_KEY], [INVESTIGATOR_KEY], [HOSPITAL_KEY], [PATIENT_KEY], [PERSON_AS_REPORTER_KEY], [ORG_AS_REPORTER_KEY], [GEOCODING_LOCATION_KEY]) VALUES (1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 94, @dbo_nrt_investigation_key_d_investigation_key, 1, 1, 1, @dbo_nrt_patient_key_d_patient_key_2, 1, 1, 1.0);
-- dbo.CASE_COUNT
-- step: 1
INSERT INTO [dbo].[CASE_COUNT] ([CASE_COUNT], [INVESTIGATOR_KEY], [REPORTER_KEY], [PHYSICIAN_KEY], [RPT_SRC_ORG_KEY], [INV_ASSIGNED_DT_KEY], [PATIENT_KEY], [INVESTIGATION_KEY], [INVESTIGATION_COUNT], [CONDITION_KEY], [ADT_HSPTL_KEY], [INV_START_DT_KEY], [DIAGNOSIS_DT_KEY], [INV_RPT_DT_KEY], [GEOCODING_LOCATION_KEY]) VALUES (1, 1, 1, 1, 1, 1, @dbo_nrt_patient_key_d_patient_key_2, @dbo_nrt_investigation_key_d_investigation_key, 1, 94, 1, 1, 1, 1, 1);
-- dbo.EVENT_METRIC_INC
-- step: 1
INSERT INTO [dbo].[EVENT_METRIC_INC] ([EVENT_TYPE], [EVENT_UID], [LOCAL_ID], [LOCAL_PATIENT_ID], [CONDITION_CD], [CONDITION_DESC_TXT], [PROG_AREA_CD], [PROG_AREA_DESC_TXT], [PROGRAM_JURISDICTION_OID], [JURISDICTION_CD], [JURISDICTION_DESC_TXT], [RECORD_STATUS_CD], [RECORD_STATUS_DESC_TXT], [RECORD_STATUS_TIME], [ADD_TIME], [ADD_USER_ID], [LAST_CHG_TIME], [LAST_CHG_USER_ID], [INVESTIGATION_STATUS_CD], [INVESTIGATION_STATUS_DESC_TXT], [ADD_USER_NAME], [LAST_CHG_USER_NAME]) VALUES (N'PHCInvForm', @dbo_nrt_investigation_public_health_case_uid, @dbo_nrt_investigation_local_id, N'PSN10067000GA01', N'11065', N'2019 Novel Coronavirus', N'GCD', N'GCD', 1300100009, N'130001', N'Fulton County', N'OPEN', N'Open', N'2026-05-05T16:01:08.953', N'2026-05-05T16:01:08.953', @superuser_id, N'2026-05-05T16:01:08.953', @superuser_id, N'O', N'Open', N'Kent, Ariella', N'Kent, Ariella');
-- dbo.EVENT_METRIC
-- step: 1
INSERT INTO [dbo].[EVENT_METRIC] ([EVENT_TYPE], [EVENT_UID], [LOCAL_ID], [LOCAL_PATIENT_ID], [CONDITION_CD], [CONDITION_DESC_TXT], [PROG_AREA_CD], [PROG_AREA_DESC_TXT], [PROGRAM_JURISDICTION_OID], [JURISDICTION_CD], [JURISDICTION_DESC_TXT], [RECORD_STATUS_CD], [RECORD_STATUS_DESC_TXT], [RECORD_STATUS_TIME], [ADD_TIME], [ADD_USER_ID], [LAST_CHG_TIME], [LAST_CHG_USER_ID], [INVESTIGATION_STATUS_CD], [INVESTIGATION_STATUS_DESC_TXT], [ADD_USER_NAME], [LAST_CHG_USER_NAME]) VALUES (N'PHCInvForm', @dbo_nrt_investigation_public_health_case_uid, @dbo_nrt_investigation_local_id, N'PSN10067000GA01', N'11065', N'2019 Novel Coronavirus', N'GCD', N'GCD', 1300100009, N'130001', N'Fulton County', N'OPEN', N'Open', N'2026-05-05T16:01:08.953', N'2026-05-05T16:01:08.953', @superuser_id, N'2026-05-05T16:01:08.953', @superuser_id, N'O', N'Open', N'Kent, Ariella', N'Kent, Ariella');
-- dbo.nrt_patient
-- step: 1
INSERT INTO [dbo].[nrt_patient] ([patient_uid], [patient_mpr_uid], [record_status], [local_id], [first_name], [last_name], [nm_use_cd], [status_name_cd], [entry_method], [add_user_id], [add_user_name], [add_time], [last_chg_user_id], [last_chg_user_name], [last_chg_time]) VALUES (@dbo_nrt_patient_patient_uid_3, @dbo_nrt_patient_patient_mpr_uid_2, N'ACTIVE', @dbo_nrt_patient_local_id_2, N'Contacted', N'Patient', N'L', N'A', N'N', @superuser_id, N'Kent, Ariella', N'2026-05-05T16:01:40.027', @superuser_id, N'Kent, Ariella', N'2026-05-05T16:01:40.027');
-- step: 1
INSERT INTO [dbo].[nrt_patient] ([patient_uid], [patient_mpr_uid], [record_status], [local_id], [first_name], [last_name], [nm_use_cd], [status_name_cd], [age_reported], [age_reported_unit], [age_reported_unit_cd], [entry_method], [add_user_id], [add_user_name], [add_time], [last_chg_user_id], [last_chg_user_name], [last_chg_time]) VALUES (@dbo_nrt_patient_patient_uid_4, @dbo_nrt_patient_patient_mpr_uid_2, N'ACTIVE', @dbo_nrt_patient_local_id_2, N'Contacted', N'Patient', N'L', N'A', 22, N'Years', N'Y', N'N', @superuser_id, N'Kent, Ariella', N'2026-05-05T16:01:40.050', @superuser_id, N'Kent, Ariella', N'2026-05-05T16:01:40.050');
-- dbo.nrt_contact
-- step: 1
INSERT INTO [dbo].[nrt_contact] ([CONTACT_UID], [ADD_TIME], [ADD_USER_ID], [CONTACT_ENTITY_UID], [CTT_STATUS], [CTT_STATUS_CODE], [CTT_EVAL_NOTES], [CTT_JURISDICTION_NM], [CTT_NAMED_ON_DT], [CTT_NOTES], [CTT_PROGRAM_AREA], [CTT_RELATIONSHIP], [CTT_RISK_NOTES], [CTT_SHARED_IND], [CTT_SYMP_NOTES], [CTT_TRT_NOTES], [LAST_CHG_TIME], [LAST_CHG_USER_ID], [LOCAL_ID], [PROGRAM_JURISDICTION_OID], [RECORD_STATUS_CD], [RECORD_STATUS_TIME], [SUBJECT_ENTITY_PHC_UID], [SUBJECT_ENTITY_UID], [PROG_AREA_CD], [JURISDICTION_CD], [VERSION_CTRL_NBR]) VALUES (10009290, N'2026-05-05T16:01:40.023', @superuser_id, @dbo_nrt_patient_patient_uid_4, N'Open', N'O', N'', N'Fulton County', N'2026-05-05T00:00:00', N'', N'GCD', N'Acquaintance', N'', N'T', N'', N'', N'2026-05-05T16:01:40.023', @superuser_id, N'CON10000000GA01', 1300100009, N'ACTIVE', N'2026-05-05T16:01:40.023', @dbo_nrt_investigation_public_health_case_uid, @dbo_nrt_patient_patient_uid_2, N'GCD', N'130001', 1);
-- dbo.nrt_metadata_columns

INSERT INTO [dbo].[nrt_metadata_columns] ([TABLE_NAME], [RDB_COLUMN_NM], [LAST_CHG_TIME], [LAST_CHG_USER_ID]) VALUES (N'D_CONTACT_RECORD', N'CTT_EXPOSURE_TYPE', N'2023-01-18T15:28:59.893', @superuser_id);
-- step: 1
INSERT INTO [dbo].[nrt_metadata_columns] ([TABLE_NAME], [RDB_COLUMN_NM], [LAST_CHG_TIME], [LAST_CHG_USER_ID]) VALUES (N'D_CONTACT_RECORD', N'CTT_FIRST_EXPOSURE_DT', N'2023-01-18T15:28:59.893', @superuser_id);
-- step: 1
INSERT INTO [dbo].[nrt_metadata_columns] ([TABLE_NAME], [RDB_COLUMN_NM], [LAST_CHG_TIME], [LAST_CHG_USER_ID]) VALUES (N'D_CONTACT_RECORD', N'CTT_LAST_EXPOSURE_DT', N'2023-01-18T15:28:59.893', @superuser_id);
-- dbo.nrt_contact_answer
-- step: 1
INSERT INTO [dbo].[nrt_contact_answer] ([contact_uid], [rdb_column_nm], [answer_val], [answer_code]) VALUES (10009290, N'CTT_EXPOSURE_TYPE', N'Common Space', N'COMSPACE');
-- step: 1
INSERT INTO [dbo].[nrt_contact_answer] ([contact_uid], [rdb_column_nm], [answer_val], [answer_code]) VALUES (10009290, N'CTT_FIRST_EXPOSURE_DT', N'', N'null');
-- step: 1
INSERT INTO [dbo].[nrt_contact_answer] ([contact_uid], [rdb_column_nm], [answer_val], [answer_code]) VALUES (10009290, N'CTT_LAST_EXPOSURE_DT', N'', N'null');
-- dbo.nrt_patient_key
-- step: 1
INSERT INTO [dbo].[nrt_patient_key] ([patient_uid], [created_dttm], [updated_dttm]) OUTPUT INSERTED.[d_patient_key] INTO @dbo_nrt_patient_key_d_patient_key_3_output ([value]) VALUES (@dbo_nrt_patient_patient_uid_3, N'2026-05-05T16:01:57.5100000', N'2026-05-05T16:01:57.5100000');
SELECT TOP 1 @dbo_nrt_patient_key_d_patient_key_3 = [value] FROM @dbo_nrt_patient_key_d_patient_key_3_output;
-- step: 1
INSERT INTO [dbo].[nrt_patient_key] ([patient_uid], [created_dttm], [updated_dttm]) OUTPUT INSERTED.[d_patient_key] INTO @dbo_nrt_patient_key_d_patient_key_4_output ([value]) VALUES (@dbo_nrt_patient_patient_uid_4, N'2026-05-05T16:01:57.5100000', N'2026-05-05T16:01:57.5100000');
SELECT TOP 1 @dbo_nrt_patient_key_d_patient_key_4 = [value] FROM @dbo_nrt_patient_key_d_patient_key_4_output;
-- dbo.D_PATIENT
-- step: 1
INSERT INTO [dbo].[D_PATIENT] ([PATIENT_KEY], [PATIENT_MPR_UID], [PATIENT_RECORD_STATUS], [PATIENT_LOCAL_ID], [PATIENT_FIRST_NAME], [PATIENT_LAST_NAME], [PATIENT_ENTRY_METHOD], [PATIENT_LAST_CHANGE_TIME], [PATIENT_UID], [PATIENT_ADD_TIME], [PATIENT_ADDED_BY], [PATIENT_LAST_UPDATED_BY]) VALUES (@dbo_nrt_patient_key_d_patient_key_3, @dbo_nrt_patient_patient_mpr_uid_2, N'ACTIVE', @dbo_nrt_patient_local_id_2, N'Contacted', N'Patient', N'N', N'2026-05-05T16:01:40.027', @dbo_nrt_patient_patient_uid_3, N'2026-05-05T16:01:40.027', N'Kent, Ariella', N'Kent, Ariella');
-- step: 1
INSERT INTO [dbo].[D_PATIENT] ([PATIENT_KEY], [PATIENT_MPR_UID], [PATIENT_RECORD_STATUS], [PATIENT_LOCAL_ID], [PATIENT_FIRST_NAME], [PATIENT_LAST_NAME], [PATIENT_AGE_REPORTED], [PATIENT_AGE_REPORTED_UNIT], [PATIENT_ENTRY_METHOD], [PATIENT_LAST_CHANGE_TIME], [PATIENT_UID], [PATIENT_ADD_TIME], [PATIENT_ADDED_BY], [PATIENT_LAST_UPDATED_BY]) VALUES (@dbo_nrt_patient_key_d_patient_key_4, @dbo_nrt_patient_patient_mpr_uid_2, N'ACTIVE', @dbo_nrt_patient_local_id_2, N'Contacted', N'Patient', 22, N'Years', N'N', N'2026-05-05T16:01:40.050', @dbo_nrt_patient_patient_uid_4, N'2026-05-05T16:01:40.050', N'Kent, Ariella', N'Kent, Ariella');
-- dbo.nrt_contact_key
-- step: 1
INSERT INTO [dbo].[nrt_contact_key] ([contact_uid], [created_dttm], [updated_dttm]) OUTPUT INSERTED.[d_contact_record_key] INTO @dbo_nrt_contact_key_d_contact_record_key_output ([value]) VALUES (10009290, N'2026-05-05T16:01:57.7666667', N'2026-05-05T16:01:57.7666667');
SELECT TOP 1 @dbo_nrt_contact_key_d_contact_record_key = [value] FROM @dbo_nrt_contact_key_d_contact_record_key_output;
-- dbo.D_CONTACT_RECORD
-- step: 1
INSERT INTO [dbo].[D_CONTACT_RECORD] ([D_CONTACT_RECORD_KEY], [ADD_TIME], [ADD_USER_ID], [CTT_EVAL_NOTES], [LAST_CHG_TIME], [LAST_CHG_USER_ID], [LOCAL_ID], [CTT_NAMED_ON_DT], [PROGRAM_JURISDICTION_OID], [RECORD_STATUS_CD], [RECORD_STATUS_TIME], [CTT_RISK_NOTES], [CTT_SYMP_NOTES], [CTT_TRT_NOTES], [CTT_NOTES], [VERSION_CTRL_NBR], [CTT_PROGRAM_AREA], [CTT_JURISDICTION_NM], [CTT_SHARED_IND], [CTT_RELATIONSHIP], [CTT_STATUS], [CTT_EXPOSURE_TYPE], [CTT_FIRST_EXPOSURE_DT], [CTT_LAST_EXPOSURE_DT]) VALUES (2.0, N'2026-05-05T16:01:40.023', @superuser_id, N'', N'2026-05-05T16:01:40.023', @superuser_id, N'CON10000000GA01', N'2026-05-05T00:00:00', 1300100009, N'ACTIVE', N'2026-05-05T16:01:40.023', N'', N'', N'', N'', 1, N'GCD', N'Fulton County', N'T', N'Acquaintance', N'Open', N'Common Space', N'1900-01-01T00:00:00', N'1900-01-01T00:00:00');
-- dbo.F_CONTACT_RECORD_CASE
-- step: 1
INSERT INTO [dbo].[F_CONTACT_RECORD_CASE] ([D_CONTACT_RECORD_KEY], [THIRD_PARTY_ENTITY_KEY], [CONTACT_KEY], [SUBJECT_KEY], [THIRD_PARTY_INVESTIGATION_KEY], [SUBJECT_INVESTIGATION_KEY], [CONTACT_INVESTIGATION_KEY], [CONTACT_INTERVIEW_KEY], [DISPOSITIONED_BY_KEY], [CONTACT_EXPOSURE_SITE_KEY], [CONTACT_INVESTIGATOR_KEY]) VALUES (2.0, 1, 7, 5, 1, @dbo_nrt_investigation_key_d_investigation_key, 1, 1.0, 1, 1, 1);
-- dbo.EVENT_METRIC_INC
-- step: 1
INSERT INTO [dbo].[EVENT_METRIC_INC] ([EVENT_TYPE], [EVENT_UID], [LOCAL_ID], [LOCAL_PATIENT_ID], [PROG_AREA_CD], [PROG_AREA_DESC_TXT], [PROGRAM_JURISDICTION_OID], [JURISDICTION_CD], [JURISDICTION_DESC_TXT], [RECORD_STATUS_CD], [RECORD_STATUS_DESC_TXT], [RECORD_STATUS_TIME], [ADD_TIME], [ADD_USER_ID], [LAST_CHG_TIME], [LAST_CHG_USER_ID], [ADD_USER_NAME], [LAST_CHG_USER_NAME]) VALUES (N'CONTACT', 10009290, N'CON10000000GA01', N'PSN10067000GA01', N'GCD', N'GCD', 1300100009, N'130001', N'Fulton County', N'ACTIVE', N'Active', N'2026-05-05T16:01:40.023', N'2026-05-05T16:01:40.023', @superuser_id, N'2026-05-05T16:01:40.023', @superuser_id, N'Kent, Ariella', N'Kent, Ariella');
-- dbo.EVENT_METRIC
-- step: 1
INSERT INTO [dbo].[EVENT_METRIC] ([EVENT_TYPE], [EVENT_UID], [LOCAL_ID], [LOCAL_PATIENT_ID], [PROG_AREA_CD], [PROG_AREA_DESC_TXT], [PROGRAM_JURISDICTION_OID], [JURISDICTION_CD], [JURISDICTION_DESC_TXT], [RECORD_STATUS_CD], [RECORD_STATUS_DESC_TXT], [RECORD_STATUS_TIME], [ADD_TIME], [ADD_USER_ID], [LAST_CHG_TIME], [LAST_CHG_USER_ID], [ADD_USER_NAME], [LAST_CHG_USER_NAME]) VALUES (N'CONTACT', 10009290, N'CON10000000GA01', N'PSN10067000GA01', N'GCD', N'GCD', 1300100009, N'130001', N'Fulton County', N'ACTIVE', N'Active', N'2026-05-05T16:01:40.023', N'2026-05-05T16:01:40.023', @superuser_id, N'2026-05-05T16:01:40.023', @superuser_id, N'Kent, Ariella', N'Kent, Ariella');
-- dbo.CASE_LAB_DATAMART
-- step: 1
INSERT INTO [dbo].[CASE_LAB_DATAMART] ([INVESTIGATION_KEY], [PATIENT_LOCAL_ID], [INVESTIGATION_LOCAL_ID], [PATIENT_FIRST_NM], [PATIENT_LAST_NM], [PATIENT_STATE], [AGE_REPORTED], [AGE_REPORTED_UNIT], [JURISDICTION_NAME], [PROGRAM_AREA_DESCRIPTION], [INVESTIGATION_START_DATE], [DISEASE], [DISEASE_CD], [PROGRAM_JURISDICTION_OID], [PHC_ADD_TIME], [PHC_LAST_CHG_TIME], [EVENT_DATE], [EVENT_DATE_TYPE]) VALUES (@dbo_nrt_investigation_key_d_investigation_key, @dbo_nrt_patient_local_id, @dbo_nrt_investigation_local_id, N'Covid', N'Patient', N'Georgia', 42, N'Years', N'Fulton County', N'GCD', N'2026-05-05T00:00:00', N'2019 Novel Coronavirus', N'11065', 1300100009, N'2026-05-05T16:01:08.953', N'2026-05-05T16:01:08.953', N'2026-05-05T00:00:00', N'Investigation Start Date');

-- dbo.COVID_CONTACT_DATAMART
exec sp_covid_contact_datamart_postprocessing '20002022';
