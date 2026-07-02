USE RDB_MODERN;

-- Constants
DECLARE @superuser_id bigint = 10009282;
-- UID Declarations
DECLARE @dbo_nrt_organization_organization_uid bigint = 2345;
DECLARE @dbo_nrt_organization_organization_uid_2 bigint = 2346;
DECLARE @dbo_nrt_observation_observation_uid bigint = 2347;
DECLARE @dbo_nrt_observation_observation_uid_2 bigint = 2348;
DECLARE @dbo_nrt_patient_patient_uid bigint = 2349;
DECLARE @dbo_nrt_patient_patient_uid_2 bigint = 2350;
DECLARE @dbo_nrt_provider_provider_uid bigint = 2351;

DECLARE @dbo_nrt_organization_local_id nvarchar(40) = N'ORG' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_nrt_organization_organization_uid))) + N'GA01';
DECLARE @dbo_nrt_organization_local_id_2 nvarchar(40) = N'ORG' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_nrt_organization_organization_uid_2))) + N'GA01';
DECLARE @dbo_nrt_observation_local_id nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_nrt_observation_observation_uid))) + N'GA01';
DECLARE @dbo_nrt_observation_local_id_2 nvarchar(40) = N'OBS' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_nrt_observation_observation_uid_2))) + N'GA01';
DECLARE @dbo_nrt_provider_local_id nvarchar(40) = N'PSN' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_nrt_provider_provider_uid))) + N'GA01';
DECLARE @dbo_nrt_patient_local_id nvarchar(40) = N'PSN' + CONVERT(nvarchar(20), ABS(CONVERT(bigint, @dbo_nrt_patient_patient_uid))) + N'GA01';
-- Keys and Output Tables
DECLARE @dbo_nrt_lab_test_result_group_key_TEST_RESULT_GRP_KEY bigint;
DECLARE @dbo_nrt_lab_test_result_group_key_TEST_RESULT_GRP_KEY_output TABLE ([value] bigint);
DECLARE @dbo_nrt_provider_key_d_provider_key bigint;
DECLARE @dbo_nrt_provider_key_d_provider_key_output TABLE ([value] bigint);
DECLARE @dbo_nrt_organization_key_d_organization_key bigint;
DECLARE @dbo_nrt_organization_key_d_organization_key_output TABLE ([value] bigint);
DECLARE @dbo_nrt_organization_key_d_organization_key_2 bigint;
DECLARE @dbo_nrt_organization_key_d_organization_key_2_output TABLE ([value] bigint);
DECLARE @dbo_nrt_patient_key_d_patient_key bigint;
DECLARE @dbo_nrt_patient_key_d_patient_key_output TABLE ([value] bigint);
DECLARE @dbo_nrt_patient_key_d_patient_key_2 bigint;
DECLARE @dbo_nrt_patient_key_d_patient_key_2_output TABLE ([value] bigint);
-- Patient helper variable
DECLARE @dbo_nrt_patient_patient_mpr_uid bigint = @dbo_nrt_patient_patient_uid + 1;

-- 1. Truncate tables to ensure a clean state for each test run
DELETE FROM [dbo].[LAB100];
DELETE FROM [dbo].[LAB_TEST_RESULT];
DELETE FROM [dbo].[LAB_RESULT_VAL];
DELETE FROM [dbo].[TEST_RESULT_GROUPING];
DELETE FROM [dbo].[nrt_lab_test_result_group_key];
DELETE FROM [dbo].[LAB_TEST];
DELETE FROM [dbo].[nrt_lab_test_key];
DELETE FROM [dbo].[nrt_observation_material];
DELETE FROM [dbo].[nrt_observation_coded];
DELETE FROM [dbo].[nrt_observation_edx];
DELETE FROM [dbo].[nrt_observation];
DELETE FROM [dbo].[EVENT_METRIC];
DELETE FROM [dbo].[EVENT_METRIC_INC];
DELETE FROM [dbo].[CASE_COUNT];
DELETE FROM [dbo].[D_PATIENT];
DELETE FROM [dbo].[nrt_patient_key];
DELETE FROM [dbo].[nrt_patient];
DELETE FROM [dbo].[D_PROVIDER];
DELETE FROM [dbo].[nrt_provider_key];
DELETE FROM [dbo].[nrt_provider];
DELETE FROM [dbo].[D_ORGANIZATION];
DELETE FROM [dbo].[nrt_organization_key];
DELETE FROM [dbo].[nrt_organization];
DELETE FROM [dbo].[job_flow_log];

-- STEP 1: Imported an ELR

-- Seed Program Area Code
-- Right-aligned SUBSTR('     800007', 7, 5) yields '00007' -> 7
INSERT INTO [dbo].[nrt_srte_Program_area_code] (prog_area_cd, prog_area_desc_txt, nbs_uid)
SELECT 'GCD_TEST', 'General Communicable Disease Test', 7
WHERE NOT EXISTS (
    SELECT 1 
    FROM [dbo].[nrt_srte_Program_area_code] 
    WHERE prog_area_cd = 'GCD_TEST'
);

-- dbo.nrt_organization
-- step: 1
INSERT INTO [dbo].[nrt_organization] ([organization_uid], [local_id], [record_status], [organization_name], [facility_id], [facility_id_auth], [entry_method], [add_user_id], [add_user_name], [add_time], [last_chg_user_id], [last_chg_user_name], [last_chg_time]) VALUES (@dbo_nrt_organization_organization_uid, @dbo_nrt_organization_local_id, N'ACTIVE', N'Diagon Alley Diagnostics', N'3456789012', N'NPI', N'Y', @superuser_id, N'User, ELR', N'2026-05-26T22:00:57.277', @superuser_id, N'User, ELR', N'2026-05-26T22:00:57.277');
-- step: 1
INSERT INTO [dbo].[nrt_organization] ([organization_uid], [local_id], [record_status], [organization_name], [stand_ind_class], [street_address_1], [street_address_2], [city], [state], [state_code], [zip], [country], [country_code], [phone_work], [phone_ext_work], [entry_method], [add_user_id], [add_user_name], [add_time], [last_chg_user_id], [last_chg_user_name], [last_chg_time]) VALUES (@dbo_nrt_organization_organization_uid_2, @dbo_nrt_organization_local_id_2, N'ACTIVE', N'Diagon Alley Diagnostics', N'Offices of All Other Miscellaneous Health Practiti', N'28091 Craig Manor Suite 554', N'', N'Rebeccatown', N'New Hampshire', N'33', N'66913', N'United States', N'840', N'222-434-1879', N'0.0', N'Y', @superuser_id, N'User, ELR', N'2026-05-26T22:00:57.307', @superuser_id, N'User, ELR', N'2026-05-26T22:00:57.307');

-- dbo.nrt_observation_coded
-- step: 1
INSERT INTO [dbo].[nrt_observation_coded] ([observation_uid], [ovc_code], [ovc_code_system_cd], [ovc_display_name], [batch_id]) VALUES (10009385, N'260415000', N'SCT', N'Not Detected', 1779832861210);

-- dbo.nrt_observation_edx
-- step: 1
INSERT INTO [dbo].[nrt_observation_edx] ([edx_document_uid], [edx_act_uid], [edx_add_time]) VALUES (239, 10009384, N'2026-05-26T22:00:56.810');

-- dbo.nrt_observation
-- step: 1
INSERT INTO [dbo].[nrt_observation] ([observation_uid], [class_cd], [mood_cd], [act_uid], [cd_desc_txt], [program_jurisdiction_oid], [local_id], [activity_to_time], [electronic_ind], [version_ctrl_nbr], [obs_domain_cd_st_1], [cd], [shared_ind], [ctrl_cd_display_form], [status_cd], [cd_system_cd], [cd_system_desc_txt], [report_observation_uid], [accession_number], [batch_id]) VALUES (@dbo_nrt_observation_observation_uid, N'OBS', N'EVN', 10009385, N'Varicella zoster virus', 4, @dbo_nrt_observation_local_id, N'2026-05-25T16:31:53', N'Y', 1, N'Result', N'5401-5', N'T', N'LabReport', N'D', N'LN', N'LOINC', 10009384, N'0496712074', 1779832861210);
-- step: 1
INSERT INTO [dbo].[nrt_observation] ([observation_uid], [class_cd], [mood_cd], [act_uid], [cd_desc_txt], [record_status_cd], [jurisdiction_cd], [program_jurisdiction_oid], [prog_area_cd], [local_id], [activity_to_time], [effective_from_time], [rpt_to_state_time], [electronic_ind], [version_ctrl_nbr], [ordering_person_id], [patient_id], [result_observation_uid], [author_organization_id], [ordering_organization_id], [material_id], [obs_domain_cd_st_1], [cd], [shared_ind], [add_user_id], [add_user_name], [add_time], [last_chg_user_id], [last_chg_user_name], [last_chg_time], [ctrl_cd_display_form], [status_cd], [cd_system_cd], [cd_system_desc_txt], [report_observation_uid], [accession_number], [record_status_time], [batch_id]) VALUES (@dbo_nrt_observation_observation_uid_2, N'OBS', N'EVN', 10009384, N'Varicella zoster virus', N'UNPROCESSED', N'130001', 800007, N'GCD', @dbo_nrt_observation_local_id_2, N'2026-05-26T08:31:53', N'2026-05-24T20:31:53', N'2026-05-26T22:00:56.810', N'Y', 1, N'10009378', 10009375, N'10009385', 10009380, 10009381, 10009386, N'Order', N'5401-5', N'T', @superuser_id, N'User, ELR', N'2026-05-26T22:00:57.443', @superuser_id, N'User, ELR', N'2026-05-26T22:00:57.443', N'LabReport', N'D', N'LN', N'LOINC', @dbo_nrt_observation_observation_uid_2, N'0496712074', N'2026-05-26T22:00:57.443', 1779832861210);

-- dbo.nrt_observation_material
-- step: 1
INSERT INTO [dbo].[nrt_observation_material] ([act_uid], [type_cd], [material_id], [subject_class_cd], [record_status], [type_desc_txt], [last_chg_time], [material_cd], [material_desc]) VALUES (10009384, N'SPC', 10009386, N'MAT', N'ACTIVE', N'Specimen', N'2026-05-26T22:00:56.810', N'BRO', N'Bronchial');

-- dbo.nrt_organization_key
-- step: 1
INSERT INTO [dbo].[nrt_organization_key] ([organization_uid], [created_dttm], [updated_dttm]) OUTPUT INSERTED.[d_organization_key] INTO @dbo_nrt_organization_key_d_organization_key_output ([value]) VALUES (@dbo_nrt_organization_organization_uid, N'2026-05-26T22:01:02.0200000', N'2026-05-26T22:01:02.0200000');
SELECT TOP 1 @dbo_nrt_organization_key_d_organization_key = [value] FROM @dbo_nrt_organization_key_d_organization_key_output;
-- step: 1
INSERT INTO [dbo].[nrt_organization_key] ([organization_uid], [created_dttm], [updated_dttm]) OUTPUT INSERTED.[d_organization_key] INTO @dbo_nrt_organization_key_d_organization_key_2_output ([value]) VALUES (@dbo_nrt_organization_organization_uid_2, N'2026-05-26T22:01:02.0200000', N'2026-05-26T22:01:02.0200000');
SELECT TOP 1 @dbo_nrt_organization_key_d_organization_key_2 = [value] FROM @dbo_nrt_organization_key_d_organization_key_2_output;

-- dbo.D_ORGANIZATION
-- step: 1
INSERT INTO [dbo].[D_ORGANIZATION] ([ORGANIZATION_KEY], [ORGANIZATION_UID], [ORGANIZATION_LOCAL_ID], [ORGANIZATION_RECORD_STATUS], [ORGANIZATION_NAME], [ORGANIZATION_FACILITY_ID], [ORGANIZATION_FACILITY_ID_AUTH], [ORGANIZATION_ENTRY_METHOD], [ORGANIZATION_LAST_CHANGE_TIME], [ORGANIZATION_ADD_TIME], [ORGANIZATION_ADDED_BY], [ORGANIZATION_LAST_UPDATED_BY]) VALUES (@dbo_nrt_organization_key_d_organization_key, @dbo_nrt_organization_organization_uid, @dbo_nrt_organization_local_id, N'ACTIVE', N'Diagon Alley Diagnostics', N'3456789012', N'NPI', N'Y', N'2026-05-26T22:00:57.277', N'2026-05-26T22:00:57.277', N'User, ELR', N'User, ELR');
-- step: 1
INSERT INTO [dbo].[D_ORGANIZATION] ([ORGANIZATION_KEY], [ORGANIZATION_UID], [ORGANIZATION_LOCAL_ID], [ORGANIZATION_RECORD_STATUS], [ORGANIZATION_NAME], [ORGANIZATION_STAND_IND_CLASS], [ORGANIZATION_STREET_ADDRESS_1], [ORGANIZATION_CITY], [ORGANIZATION_STATE], [ORGANIZATION_STATE_CODE], [ORGANIZATION_ZIP], [ORGANIZATION_COUNTRY], [ORGANIZATION_PHONE_WORK], [ORGANIZATION_PHONE_EXT_WORK], [ORGANIZATION_ENTRY_METHOD], [ORGANIZATION_LAST_CHANGE_TIME], [ORGANIZATION_ADD_TIME], [ORGANIZATION_ADDED_BY], [ORGANIZATION_LAST_UPDATED_BY]) VALUES (@dbo_nrt_organization_key_d_organization_key_2, @dbo_nrt_organization_organization_uid_2, @dbo_nrt_organization_local_id_2, N'ACTIVE', N'Diagon Alley Diagnostics', N'Offices of All Other Miscellaneous Health Practiti', N'28091 Craig Manor Suite 554', N'Rebeccatown', N'New Hampshire', N'33', N'66913', N'United States', N'222-434-1879', N'0.0', N'Y', N'2026-05-26T22:00:57.307', N'2026-05-26T22:00:57.307', N'User, ELR', N'User, ELR');

-- dbo.nrt_patient
-- step: 1
INSERT INTO [dbo].[nrt_patient] ([patient_uid], [patient_mpr_uid], [record_status], [local_id], [first_name], [last_name], [nm_use_cd], [status_name_cd], [street_address_1], [street_address_2], [city], [state], [state_code], [zip], [country], [country_code], [phone_home], [phone_ext_home], [dob], [current_sex], [curr_sex_cd], [ethnic_group_ind], [ethnicity], [race_calculated], [race_calc_details], [entry_method], [race_all], [add_user_id], [add_user_name], [add_time], [last_chg_user_id], [last_chg_user_name], [last_chg_time]) VALUES (@dbo_nrt_patient_patient_uid, @dbo_nrt_patient_patient_mpr_uid, N'ACTIVE', @dbo_nrt_patient_local_id, N'Filius', N'Flitwick_Sn57y120', N'L', N'A', N'715 Brown Shores Suite 333', N'', N'Valdosta', N'Georgia', N'13', N'30309', N'United States', N'840', N'791-381-2805', N'0.0', N'1945-05-15T00:00:00', N'Male', N'M', N'2186-5', N'Not Hispanic or Latino', N'American Indian or Alaska Native', N'American Indian or Alaska Native', N'Y', N'American Indian or Alaska Native', @superuser_id, N'User, ELR', N'2026-05-26T22:00:56.810', @superuser_id, N'User, ELR', N'2026-05-26T22:00:56.810');
-- step: 1
INSERT INTO [dbo].[nrt_patient] ([patient_uid], [patient_mpr_uid], [record_status], [local_id], [first_name], [last_name], [nm_use_cd], [status_name_cd], [street_address_1], [street_address_2], [city], [state], [state_code], [zip], [country], [country_code], [phone_home], [phone_ext_home], [dob], [current_sex], [curr_sex_cd], [ethnic_group_ind], [ethnicity], [race_calculated], [race_calc_details], [entry_method], [race_all], [add_user_id], [add_user_name], [add_time], [last_chg_user_id], [last_chg_user_name], [last_chg_time]) VALUES (@dbo_nrt_patient_patient_uid_2, @dbo_nrt_patient_patient_mpr_uid, N'ACTIVE', @dbo_nrt_patient_local_id, N'Filius', N'Flitwick_Sn57y120', N'L', N'A', N'715 Brown Shores Suite 333', N'', N'Valdosta', N'Georgia', N'13', N'30309', N'United States', N'840', N'791-381-2805', N'0.0', N'1945-05-15T00:00:00', N'Male', N'M', N'2186-5', N'Not Hispanic or Latino', N'American Indian or Alaska Native', N'American Indian or Alaska Native', N'Y', N'American Indian or Alaska Native', @superuser_id, N'User, ELR', N'2026-05-26T22:00:57.207', @superuser_id, N'User, ELR', N'2026-05-26T22:00:57.207');

-- dbo.nrt_provider
-- step: 1
INSERT INTO [dbo].[nrt_provider] ([provider_uid], [local_id], [record_status], [first_name], [last_name], [provider_registration_num], [provider_registration_num_auth], [street_address_1], [street_address_2], [city], [state], [state_code], [zip], [country], [country_code], [entry_method], [add_user_id], [add_user_name], [add_time], [last_chg_user_id], [last_chg_user_name], [last_chg_time]) VALUES (@dbo_nrt_provider_provider_uid, @dbo_nrt_provider_local_id, N'ACTIVE', N'Stephanie', N'Norton_FAKE', N'0678351535', N'3456789012', N'6077 Andrew Mission Suite 098', N'', N'New Theresaborough', N'Minnesota', N'27', N'50113', N'United States', N'840', N'Y', @superuser_id, N'User, ELR', N'2026-05-26T22:00:57.233', @superuser_id, N'User, ELR', N'2026-05-26T22:00:57.233');

-- dbo.nrt_lab_test_key
-- step: 1
INSERT INTO [dbo].[nrt_lab_test_key] ([LAB_TEST_UID], [created_dttm], [updated_dttm]) VALUES (10009384, N'2026-05-26T22:01:02.8600000', N'2026-05-26T22:01:02.8600000');
-- step: 1
INSERT INTO [dbo].[nrt_lab_test_key] ([LAB_TEST_UID], [created_dttm], [updated_dttm]) VALUES (10009385, N'2026-05-26T22:01:02.8600000', N'2026-05-26T22:01:02.8600000');

-- dbo.nrt_provider_key
-- step: 1
INSERT INTO [dbo].[nrt_provider_key] ([provider_uid], [created_dttm], [updated_dttm]) OUTPUT INSERTED.[d_provider_key] INTO @dbo_nrt_provider_key_d_provider_key_output ([value]) VALUES (@dbo_nrt_provider_provider_uid, N'2026-05-26T22:01:25.7300000', N'2026-05-26T22:01:25.7300000');
SELECT TOP 1 @dbo_nrt_provider_key_d_provider_key = [value] FROM @dbo_nrt_provider_key_d_provider_key_output;

-- dbo.nrt_patient_key
-- step: 1
INSERT INTO [dbo].[nrt_patient_key] ([patient_uid], [created_dttm], [updated_dttm]) OUTPUT INSERTED.[d_patient_key] INTO @dbo_nrt_patient_key_d_patient_key_output ([value]) VALUES (@dbo_nrt_patient_patient_uid, N'2026-05-26T22:01:26.1533333', N'2026-05-26T22:01:26.1533333');
SELECT TOP 1 @dbo_nrt_patient_key_d_patient_key = [value] FROM @dbo_nrt_patient_key_d_patient_key_output;
-- step: 1
INSERT INTO [dbo].[nrt_patient_key] ([patient_uid], [created_dttm], [updated_dttm]) OUTPUT INSERTED.[d_patient_key] INTO @dbo_nrt_patient_key_d_patient_key_2_output ([value]) VALUES (@dbo_nrt_patient_patient_uid_2, N'2026-05-26T22:01:26.1533333', N'2026-05-26T22:01:26.1533333');
SELECT TOP 1 @dbo_nrt_patient_key_d_patient_key_2 = [value] FROM @dbo_nrt_patient_key_d_patient_key_2_output;

-- dbo.LAB_TEST
-- step: 1
INSERT INTO [dbo].[LAB_TEST] ([LAB_TEST_STATUS], [LAB_TEST_KEY], [LAB_RPT_LOCAL_ID], [LAB_RPT_SHARE_IND], [LAB_TEST_CD], [ELR_IND], [LAB_RPT_UID], [LAB_TEST_CD_DESC], [LAB_RPT_RECEIVED_BY_PH_DT], [LAB_RPT_CREATED_BY], [LAB_RPT_LAST_UPDATE_BY], [LAB_TEST_DT], [LAB_RPT_CREATED_DT], [LAB_TEST_TYPE], [LAB_RPT_LAST_UPDATE_DT], [JURISDICTION_CD], [LAB_TEST_CD_SYS_CD], [LAB_TEST_CD_SYS_NM], [JURISDICTION_NM], [OID], [LAB_RPT_STATUS], [ACCESSION_NBR], [SPECIMEN_SRC], [SPECIMEN_DESC], [LAB_TEST_UID], [ROOT_ORDERED_TEST_PNTR], [PARENT_TEST_PNTR], [LAB_TEST_PNTR], [SPECIMEN_COLLECTION_DT], [ROOT_ORDERED_TEST_NM], [PARENT_TEST_NM], [RECORD_STATUS_CD], [RDB_LAST_REFRESH_TIME], [CONDITION_CD]) VALUES (N'Final', 13, @dbo_nrt_observation_local_id_2, N'T', N'5401-5', N'Y', 10009385, N'Varicella zoster virus', N'2026-05-26T22:00:56.810', 10000015, 10000015, N'2026-05-26T08:31:53', N'2026-05-26T22:00:57.443', N'Result', N'2026-05-26T22:00:57.443', N'130001', N'LN', N'LOINC', N'Fulton County', 800007, N'D', N'0496712074', N'BRO', N'Bronchial', 10009385, 10009384, 10009384, 10009385, N'2026-05-24T20:31:53', N'Varicella zoster virus', N'Varicella zoster virus', N'ACTIVE', N'2026-05-26T22:01:02.857', N'10030');
-- step: 1
INSERT INTO [dbo].[LAB_TEST] ([LAB_TEST_STATUS], [LAB_TEST_KEY], [LAB_RPT_LOCAL_ID], [LAB_RPT_SHARE_IND], [LAB_TEST_CD], [ELR_IND], [LAB_RPT_UID], [LAB_TEST_CD_DESC], [LAB_RPT_RECEIVED_BY_PH_DT], [LAB_RPT_CREATED_BY], [LAB_RPT_LAST_UPDATE_BY], [LAB_TEST_DT], [LAB_RPT_CREATED_DT], [LAB_TEST_TYPE], [LAB_RPT_LAST_UPDATE_DT], [JURISDICTION_CD], [LAB_TEST_CD_SYS_CD], [LAB_TEST_CD_SYS_NM], [JURISDICTION_NM], [OID], [LAB_RPT_STATUS], [ACCESSION_NBR], [SPECIMEN_SRC], [SPECIMEN_DESC], [LAB_TEST_UID], [ROOT_ORDERED_TEST_PNTR], [PARENT_TEST_PNTR], [LAB_TEST_PNTR], [SPECIMEN_ADD_TIME], [SPECIMEN_LAST_CHANGE_TIME], [SPECIMEN_COLLECTION_DT], [ROOT_ORDERED_TEST_NM], [PARENT_TEST_NM], [RECORD_STATUS_CD], [RDB_LAST_REFRESH_TIME], [CONDITION_CD], [DOCUMENT_LINK]) VALUES (N'Final', 12, @dbo_nrt_observation_local_id_2, N'T', N'5401-5', N'Y', 10009384, N'Varicella zoster virus', N'2026-05-26T22:00:56.810', 10000015, 10000015, N'2026-05-26T08:31:53', N'2026-05-26T22:00:57.443', N'Order', N'2026-05-26T22:00:57.443', N'130001', N'LN', N'LOINC', N'Fulton County', 800007, N'D', N'0496712074', N'BRO', N'Bronchial', 10009384, 10009384, 10009384, 10009384, N'2026-05-26T22:00:57.443', N'2026-05-26T22:00:57.443', N'2026-05-24T20:31:53', N'Varicella zoster virus', N'Varicella zoster virus', N'ACTIVE', N'2026-05-26T22:01:02.857', N'10030', N'<a href="#" onClick="window.open(''/nbs/viewELRDocument.do?method=viewELRDocument&documentUid=239&dateReceivedHidden=05/28/2026'',''DocumentViewer'',''width=900,height=800,left=0,top=0,menubar=no,titlebar=no,toolbar=no,scrollbars=yes,location=no'');">ViewLabDocument</a>');

-- dbo.nrt_lab_test_result_group_key
-- step: 1
INSERT INTO [dbo].[nrt_lab_test_result_group_key] ([LAB_TEST_UID], [created_dttm], [updated_dttm]) OUTPUT INSERTED.[TEST_RESULT_GRP_KEY] INTO @dbo_nrt_lab_test_result_group_key_TEST_RESULT_GRP_KEY_output ([value]) VALUES (10009385, N'2026-05-26T22:01:03.2900000', N'2026-05-26T22:01:03.2900000');
SELECT TOP 1 @dbo_nrt_lab_test_result_group_key_TEST_RESULT_GRP_KEY = [value] FROM @dbo_nrt_lab_test_result_group_key_TEST_RESULT_GRP_KEY_output;
-- step: 1
UPDATE [dbo].[nrt_lab_test_result_group_key] SET [updated_dttm] = N'2026-05-26T22:01:03.4566667' WHERE [TEST_RESULT_GRP_KEY] = @dbo_nrt_lab_test_result_group_key_TEST_RESULT_GRP_KEY;

-- dbo.TEST_RESULT_GROUPING
-- step: 1
INSERT INTO [dbo].[TEST_RESULT_GROUPING] ([TEST_RESULT_GRP_KEY], [LAB_TEST_UID]) VALUES (@dbo_nrt_lab_test_result_group_key_TEST_RESULT_GRP_KEY, 10009385);

-- dbo.LAB_RESULT_VAL
-- step: 1
INSERT INTO [dbo].[LAB_RESULT_VAL] ([TEST_RESULT_GRP_KEY], [TEST_RESULT_VAL_CD], [TEST_RESULT_VAL_CD_DESC], [TEST_RESULT_VAL_CD_SYS_CD], [TEST_RESULT_VAL_KEY], [RECORD_STATUS_CD], [LAB_TEST_UID], [RDB_LAST_REFRESH_TIME]) VALUES (@dbo_nrt_lab_test_result_group_key_TEST_RESULT_GRP_KEY, N'260415000', N'Not Detected', N'SCT', 8, N'ACTIVE', 10009385, N'2026-05-26T22:01:03.473');

-- dbo.LAB_TEST_RESULT
-- step: 1
INSERT INTO [dbo].[LAB_TEST_RESULT] ([LAB_TEST_KEY], [LAB_TEST_UID], [RESULT_COMMENT_GRP_KEY], [TEST_RESULT_GRP_KEY], [PERFORMING_LAB_KEY], [PATIENT_KEY], [COPY_TO_PROVIDER_KEY], [LAB_TEST_TECHNICIAN_KEY], [SPECIMEN_COLLECTOR_KEY], [ORDERING_ORG_KEY], [REPORTING_LAB_KEY], [CONDITION_KEY], [LAB_RPT_DT_KEY], [MORB_RPT_KEY], [INVESTIGATION_KEY], [LDF_GROUP_KEY], [ORDERING_PROVIDER_KEY], [RECORD_STATUS_CD], [RDB_LAST_REFRESH_TIME]) VALUES (12, 10009384, 1, 1, 1, @dbo_nrt_patient_key_d_patient_key, 1, 1, 1, @dbo_nrt_organization_key_d_organization_key_2, @dbo_nrt_organization_key_d_organization_key, 239, 13296, 1, 1, 1, @dbo_nrt_provider_key_d_provider_key, N'ACTIVE', N'2026-05-26T22:01:03.590');
-- step: 1
INSERT INTO [dbo].[LAB_TEST_RESULT] ([LAB_TEST_KEY], [LAB_TEST_UID], [RESULT_COMMENT_GRP_KEY], [TEST_RESULT_GRP_KEY], [PERFORMING_LAB_KEY], [PATIENT_KEY], [COPY_TO_PROVIDER_KEY], [LAB_TEST_TECHNICIAN_KEY], [SPECIMEN_COLLECTOR_KEY], [ORDERING_ORG_KEY], [REPORTING_LAB_KEY], [CONDITION_KEY], [LAB_RPT_DT_KEY], [MORB_RPT_KEY], [INVESTIGATION_KEY], [LDF_GROUP_KEY], [ORDERING_PROVIDER_KEY], [RECORD_STATUS_CD], [RDB_LAST_REFRESH_TIME]) VALUES (13, 10009385, 1, @dbo_nrt_lab_test_result_group_key_TEST_RESULT_GRP_KEY, 1, @dbo_nrt_patient_key_d_patient_key, 1, 1, 1, @dbo_nrt_organization_key_d_organization_key_2, @dbo_nrt_organization_key_d_organization_key, 1, 13296, 1, 1, 1, @dbo_nrt_provider_key_d_provider_key, N'ACTIVE', N'2026-05-26T22:01:03.590');

-- dbo.EVENT_METRIC_INC
-- step: 1
INSERT INTO [dbo].[EVENT_METRIC_INC] ([EVENT_TYPE], [EVENT_UID], [LOCAL_ID], [LOCAL_PATIENT_ID], [PROG_AREA_CD], [PROG_AREA_DESC_TXT], [PROGRAM_JURISDICTION_OID], [JURISDICTION_CD], [JURISDICTION_DESC_TXT], [RECORD_STATUS_CD], [RECORD_STATUS_DESC_TXT], [RECORD_STATUS_TIME], [ELECTRONIC_IND], [STATUS_CD], [STATUS_DESC_TXT], [ADD_TIME], [ADD_USER_ID], [LAST_CHG_TIME], [LAST_CHG_USER_ID], [ADD_USER_NAME], [LAST_CHG_USER_NAME]) VALUES (N'LabReport', 10009384, @dbo_nrt_observation_local_id_2, N'PSN10067017GA01', N'GCD', N'GCD', 800007, N'130001', N'Fulton County', N'UNPROCESSED', N'Unprocessed', N'2026-05-26T22:00:57.443', N'Y', N'D', N'Completed / Final', N'2026-05-26T22:00:57.443', @superuser_id, N'2026-05-26T22:00:57.443', @superuser_id, N'User, ELR', N'User, ELR');

-- dbo.EVENT_METRIC
-- step: 1
INSERT INTO [dbo].[EVENT_METRIC] ([EVENT_TYPE], [EVENT_UID], [LOCAL_ID], [LOCAL_PATIENT_ID], [PROG_AREA_CD], [PROG_AREA_DESC_TXT], [PROGRAM_JURISDICTION_OID], [JURISDICTION_CD], [JURISDICTION_DESC_TXT], [RECORD_STATUS_CD], [RECORD_STATUS_DESC_TXT], [RECORD_STATUS_TIME], [ELECTRONIC_IND], [STATUS_CD], [STATUS_DESC_TXT], [ADD_TIME], [ADD_USER_ID], [LAST_CHG_TIME], [LAST_CHG_USER_ID], [ADD_USER_NAME], [LAST_CHG_USER_NAME]) VALUES (N'LabReport', 10009384, @dbo_nrt_observation_local_id_2, N'PSN10067017GA01', N'GCD', N'GCD', 800007, N'130001', N'Fulton County', N'UNPROCESSED', N'Unprocessed', N'2026-05-26T22:00:57.443', N'Y', N'D', N'Completed / Final', N'2026-05-26T22:00:57.443', @superuser_id, N'2026-05-26T22:00:57.443', @superuser_id, N'User, ELR', N'User, ELR');

-- dbo.D_PROVIDER
-- step: 1
INSERT INTO [dbo].[D_PROVIDER] ([PROVIDER_UID], [PROVIDER_KEY], [PROVIDER_LOCAL_ID], [PROVIDER_RECORD_STATUS], [PROVIDER_FIRST_NAME], [PROVIDER_LAST_NAME], [PROVIDER_REGISTRATION_NUM], [PROVIDER_REGISRATION_NUM_AUTH], [PROVIDER_STREET_ADDRESS_1], [PROVIDER_CITY], [PROVIDER_STATE], [PROVIDER_STATE_CODE], [PROVIDER_ZIP], [PROVIDER_COUNTRY], [PROVIDER_ENTRY_METHOD], [PROVIDER_LAST_CHANGE_TIME], [PROVIDER_ADD_TIME], [PROVIDER_ADDED_BY], [PROVIDER_LAST_UPDATED_BY]) VALUES (@dbo_nrt_provider_provider_uid, @dbo_nrt_provider_key_d_provider_key, @dbo_nrt_provider_local_id, N'ACTIVE', N'Stephanie', N'Norton_FAKE', N'0678351535', N'3456789012', N'6077 Andrew Mission Suite 098', N'New Theresaborough', N'Minnesota', N'27', N'50113', N'United States', N'Y', N'2026-05-26T22:00:57.233', N'2026-05-26T22:00:57.233', N'User, ELR', N'User, ELR');

-- dbo.D_PATIENT
-- step: 1
INSERT INTO [dbo].[D_PATIENT] ([PATIENT_KEY], [PATIENT_MPR_UID], [PATIENT_RECORD_STATUS], [PATIENT_LOCAL_ID], [PATIENT_FIRST_NAME], [PATIENT_LAST_NAME], [PATIENT_STREET_ADDRESS_1], [PATIENT_CITY], [PATIENT_STATE], [PATIENT_STATE_CODE], [PATIENT_ZIP], [PATIENT_COUNTRY], [PATIENT_PHONE_HOME], [PATIENT_PHONE_EXT_HOME], [PATIENT_DOB], [PATIENT_CURRENT_SEX], [PATIENT_ETHNICITY], [PATIENT_RACE_CALCULATED], [PATIENT_RACE_CALC_DETAILS], [PATIENT_ENTRY_METHOD], [PATIENT_LAST_CHANGE_TIME], [PATIENT_UID], [PATIENT_ADD_TIME], [PATIENT_ADDED_BY], [PATIENT_LAST_UPDATED_BY], [PATIENT_RACE_ALL]) VALUES (@dbo_nrt_patient_key_d_patient_key, @dbo_nrt_patient_patient_mpr_uid, N'ACTIVE', @dbo_nrt_patient_local_id, N'Filius', N'Flitwick_Sn57y120', N'715 Brown Shores Suite 333', N'Valdosta', N'Georgia', N'13', N'30309', N'United States', N'791-381-2805', N'0.0', N'1945-05-15T00:00:00', N'Male', N'Not Hispanic or Latino', N'American Indian or Alaska Native', N'American Indian or Alaska Native', N'Y', N'2026-05-26T22:00:56.810', @dbo_nrt_patient_patient_uid, N'2026-05-26T22:00:56.810', N'User, ELR', N'User, ELR', N'American Indian or Alaska Native');
-- step: 1
INSERT INTO [dbo].[D_PATIENT] ([PATIENT_KEY], [PATIENT_MPR_UID], [PATIENT_RECORD_STATUS], [PATIENT_LOCAL_ID], [PATIENT_FIRST_NAME], [PATIENT_LAST_NAME], [PATIENT_STREET_ADDRESS_1], [PATIENT_CITY], [PATIENT_STATE], [PATIENT_STATE_CODE], [PATIENT_ZIP], [PATIENT_COUNTRY], [PATIENT_PHONE_HOME], [PATIENT_PHONE_EXT_HOME], [PATIENT_DOB], [PATIENT_CURRENT_SEX], [PATIENT_ETHNICITY], [PATIENT_RACE_CALCULATED], [PATIENT_RACE_CALC_DETAILS], [PATIENT_ENTRY_METHOD], [PATIENT_LAST_CHANGE_TIME], [PATIENT_UID], [PATIENT_ADD_TIME], [PATIENT_ADDED_BY], [PATIENT_LAST_UPDATED_BY], [PATIENT_RACE_ALL]) VALUES (@dbo_nrt_patient_key_d_patient_key_2, @dbo_nrt_patient_patient_mpr_uid, N'ACTIVE', @dbo_nrt_patient_local_id, N'Filius', N'Flitwick_Sn57y120', N'715 Brown Shores Suite 333', N'Valdosta', N'Georgia', N'13', N'30309', N'United States', N'791-381-2805', N'0.0', N'1945-05-15T00:00:00', N'Male', N'Not Hispanic or Latino', N'American Indian or Alaska Native', N'American Indian or Alaska Native', N'Y', N'2026-05-26T22:00:57.207', @dbo_nrt_patient_patient_uid_2, N'2026-05-26T22:00:57.207', N'User, ELR', N'User, ELR', N'American Indian or Alaska Native');

EXEC [dbo].[sp_lab100_datamart_postprocessing] @labtestuids = '10009385';
