-- Query 0: Verify nrt_provider was directly written by PersonService (direct-write path)
SELECT
    [provider_uid],
    [local_id],
    [first_name],
    [last_name],
    [record_status]
FROM [RDB_MODERN].[dbo].[nrt_provider]
WHERE [provider_uid] = 1000013000;

-- Query 1: Verify sp_nrt_provider_postprocessing hydrated D_PROVIDER
SELECT
    [PROVIDER_UID],
    [PROVIDER_LOCAL_ID],
    [PROVIDER_FIRST_NAME],
    [PROVIDER_LAST_NAME],
    [PROVIDER_RECORD_STATUS]
FROM [RDB_MODERN].[dbo].[D_PROVIDER]
WHERE [PROVIDER_UID] = 1000013000;
