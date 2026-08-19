USE [RDB_MODERN]

DELETE FROM dbo.job_flow_log
WHERE package_Name IN (
    'sp_auth_user_event',
    'sp_patient_event',
    'sp_investigation_event',
    'sp_notification_event',
    'sp_observation_event',
    'sp_organization_event',
    'sp_place_event',
    'sp_provider_event'
)
AND Msg_Description1 IN (
    '990000001', '990000002',
    '990000011', '990000012',
    '990000021', '990000022',
    '990000031', '990000032',
    '990000041', '990000042',
    '990000051', '990000052',
    '990000061', '990000062',
    '990000071', '990000072'
)

EXEC dbo.sp_organization_event @org_id_list = '990000001', @debug_logging = 0
EXEC dbo.sp_organization_event @org_id_list = '990000002', @debug_logging = 1

EXEC dbo.sp_provider_event @user_id_list = '990000011', @debug_logging = 0
EXEC dbo.sp_provider_event @user_id_list = '990000012', @debug_logging = 1

EXEC dbo.sp_observation_event @obs_id_list = '990000021', @debug_logging = 0
EXEC dbo.sp_observation_event @obs_id_list = '990000022', @debug_logging = 1

EXEC dbo.sp_investigation_event @phc_id_list = '990000031', @debug_logging = 0
EXEC dbo.sp_investigation_event @phc_id_list = '990000032', @debug_logging = 1

EXEC dbo.sp_notification_event @notification_list = '990000041', @debug_logging = 0
EXEC dbo.sp_notification_event @notification_list = '990000042', @debug_logging = 1

EXEC dbo.sp_auth_user_event @user_id_list = '990000051', @debug_logging = 0
EXEC dbo.sp_auth_user_event @user_id_list = '990000052', @debug_logging = 1

EXEC dbo.sp_place_event @id_list = '990000061', @debug_logging = 0
EXEC dbo.sp_place_event @id_list = '990000062', @debug_logging = 1

EXEC dbo.sp_patient_event @user_id_list = '990000071', @debug_logging = 0
EXEC dbo.sp_patient_event @user_id_list = '990000072', @debug_logging = 1
