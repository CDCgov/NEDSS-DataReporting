-- Query 0: Verify D_PATIENT was created
SELECT
    [PATIENT_KEY],
    [PATIENT_MPR_UID],
    [PATIENT_RECORD_STATUS],
    [PATIENT_LOCAL_ID],
    [PATIENT_FIRST_NAME],
    [PATIENT_LAST_NAME],
    [PATIENT_STATE],
    [PATIENT_STATE_CODE],
    [PATIENT_COUNTRY],
    [PATIENT_ENTRY_METHOD],
    [PATIENT_ADDED_BY],
    [PATIENT_LAST_UPDATED_BY]
FROM [RDB_MODERN].[dbo].[D_PATIENT]
WHERE [PATIENT_LOCAL_ID] = 'PSN10014313GA01';

-- Query 1: Verify nrt_patient was created for MPR
SELECT
    [patient_uid],
    [patient_mpr_uid],
    [record_status],
    [local_id],
    [first_name],
    [last_name],
    [state],
    [state_code],
    [country],
    [country_code],
    [entry_method]
FROM [RDB_MODERN].[dbo].[nrt_patient]
WHERE [local_id] = 'PSN10014313GA01' AND [patient_uid] = 10014313;

-- Query 2: Verify nrt_patient was created for version
SELECT
    [patient_uid],
    [patient_mpr_uid],
    [record_status],
    [local_id],
    [first_name],
    [last_name],
    [state],
    [state_code]
FROM [RDB_MODERN].[dbo].[nrt_patient]
WHERE [local_id] = 'PSN10014313GA01' AND [patient_uid] = 10014315;

-- Query 3: Verify INVESTIGATION was created
SELECT
    [INVESTIGATION_KEY],
    [CASE_OID],
    [CASE_UID],
    [INV_LOCAL_ID],
    [INV_SHARE_IND],
    [INVESTIGATION_STATUS],
    [CASE_TYPE],
    [JURISDICTION_CD],
    [JURISDICTION_NM],
    [RECORD_STATUS_CD],
    [PROGRAM_AREA_DESCRIPTION],
    [INVESTIGATION_ADDED_BY],
    [INVESTIGATION_LAST_UPDATED_BY],
    [REFERRAL_BASIS],
    [CURR_PROCESS_STATE],
    [COINFECTION_ID]
FROM [RDB_MODERN].[dbo].[INVESTIGATION]
WHERE [INV_LOCAL_ID] = 'CAS10014317GA01';
