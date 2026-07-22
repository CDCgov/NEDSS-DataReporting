-- Query 0: Verify nrt_auth_user was directly written by PersonService (direct-write path)
SELECT
    [auth_user_uid],
    [user_id],
    [first_nm],
    [last_nm],
    [nedss_entry_id],
    [record_status_cd]
FROM [RDB_MODERN].[dbo].[nrt_auth_user]
WHERE [auth_user_uid] = 1000012000;

-- Query 1: Verify sp_user_profile_postprocessing hydrated USER_PROFILE
SELECT
    [FIRST_NM],
    [LAST_NM],
    [NEDSS_ENTRY_ID],
    [PROVIDER_KEY],
    [USER_NM]
FROM [RDB_MODERN].[dbo].[USER_PROFILE]
WHERE [NEDSS_ENTRY_ID] = 1000012000;
