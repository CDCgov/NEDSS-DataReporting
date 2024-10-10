IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_observation' and xtype = 'U')
    BEGIN

        IF NOT EXISTS(SELECT 1 FROM sys.columns   WHERE Name = N'cd_desc_txt'   AND Object_ID = Object_ID(N'nrt_observation'))
            BEGIN
                EXEC sys.sp_rename N'nrt_observation.cd_desc_text', N'cd_desc_txt', 'COLUMN';
            END;

    END;