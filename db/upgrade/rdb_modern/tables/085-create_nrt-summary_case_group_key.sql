IF NOT EXISTS (SELECT 1
               FROM sysobjects
               WHERE name = 'nrt_summary_case_group_key'
                 and xtype = 'U')
    BEGIN

        CREATE TABLE dbo.nrt_summary_case_group_key
        (
            summary_case_src_key   bigint IDENTITY (1,1) NOT NULL,
            public_health_case_uid bigint                NULL,
            ovc_observation_uid    bigint                NULL,
            created_dttm DATETIME2 DEFAULT GETDATE(),
            updated_dttm DATETIME2 DEFAULT GETDATE()
        );
        --Ref PR#189: Check for null and set default to 2
        DECLARE @max bigint = (SELECT DISTINCT ISNULL(MAX(SUMMARY_CASE_SRC_KEY) + 1, 2) FROM dbo.SUMMARY_CASE_GROUP);
        DBCC CHECKIDENT ('dbo.nrt_summary_case_group_key', RESEED, @max);

    END;

IF NOT EXISTS (SELECT 1
               FROM dbo.SUMMARY_CASE_GROUP)
    BEGIN

        INSERT INTO dbo.SUMMARY_CASE_GROUP (SUMMARY_CASE_SRC_KEY)
        SELECT 1;

    END;