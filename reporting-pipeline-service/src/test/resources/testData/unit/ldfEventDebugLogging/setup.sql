USE [RDB_MODERN]

DELETE FROM dbo.job_flow_log
WHERE package_Name IN (
    'sp_ldf_data_event',
    'sp_ldf_patient_event',
    'sp_ldf_provider_event',
    'sp_ldf_organization_event',
    'sp_ldf_observation_event',
    'sp_ldf_phc_event',
    'sp_ldf_intervention_event'
)
AND Msg_Description1 IN (
    '99100001', '99100002',
    '99100003', '99100004',
    '99100005', '99100006',
    '99100007', '99100008',
    '99100009', '99100010',
    '99100011', '99100012'
)

EXEC dbo.sp_ldf_data_event @bus_obj_nm = 'PAT', @ldf_uid = '99000100', @bus_obj_uid_list = '99100001', @debug_logging = 0
EXEC dbo.sp_ldf_data_event @bus_obj_nm = 'PAT', @ldf_uid = '99000100', @bus_obj_uid_list = '99100002', @debug_logging = 1
EXEC dbo.sp_ldf_data_event @bus_obj_nm = 'PRV', @ldf_uid = '99000100', @bus_obj_uid_list = '99100003', @debug_logging = 0
EXEC dbo.sp_ldf_data_event @bus_obj_nm = 'PRV', @ldf_uid = '99000100', @bus_obj_uid_list = '99100004', @debug_logging = 1
EXEC dbo.sp_ldf_data_event @bus_obj_nm = 'ORG', @ldf_uid = '99000100', @bus_obj_uid_list = '99100005', @debug_logging = 0
EXEC dbo.sp_ldf_data_event @bus_obj_nm = 'ORG', @ldf_uid = '99000100', @bus_obj_uid_list = '99100006', @debug_logging = 1
EXEC dbo.sp_ldf_data_event @bus_obj_nm = 'LAB', @ldf_uid = '99000100', @bus_obj_uid_list = '99100007', @debug_logging = 0
EXEC dbo.sp_ldf_data_event @bus_obj_nm = 'LAB', @ldf_uid = '99000100', @bus_obj_uid_list = '99100008', @debug_logging = 1
EXEC dbo.sp_ldf_data_event @bus_obj_nm = 'PHC', @ldf_uid = '99000100', @bus_obj_uid_list = '99100009', @debug_logging = 0
EXEC dbo.sp_ldf_data_event @bus_obj_nm = 'PHC', @ldf_uid = '99000100', @bus_obj_uid_list = '99100010', @debug_logging = 1
EXEC dbo.sp_ldf_data_event @bus_obj_nm = 'VAC', @ldf_uid = '99000100', @bus_obj_uid_list = '99100011', @debug_logging = 0
EXEC dbo.sp_ldf_data_event @bus_obj_nm = 'VAC', @ldf_uid = '99000100', @bus_obj_uid_list = '99100012', @debug_logging = 1
