-- Query 0: Verify nrt_provider was re-written with the updated middle name and email
SELECT
    [provider_uid],
    [first_name],
    [middle_name],
    [last_name],
    [email_work]
FROM [RDB_MODERN].[dbo].[nrt_provider]
WHERE [provider_uid] = 1000013000;

-- Query 1: Verify sp_nrt_provider_postprocessing propagated the update to D_PROVIDER
SELECT
    [PROVIDER_UID],
    [PROVIDER_FIRST_NAME],
    [PROVIDER_MIDDLE_NAME],
    [PROVIDER_LAST_NAME],
    [PROVIDER_EMAIL_WORK]
FROM [RDB_MODERN].[dbo].[D_PROVIDER]
WHERE [PROVIDER_UID] = 1000013000;
