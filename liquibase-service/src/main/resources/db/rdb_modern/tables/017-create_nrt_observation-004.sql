IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_observation' and xtype = 'U')
    BEGIN

        IF NOT EXISTS(SELECT 1 FROM sys.columns   WHERE Name = N'cd_desc_txt'   AND Object_ID = Object_ID(N'nrt_observation'))
            BEGIN
                ALTER TABLE nrt_observation
                    ADD cd_desc_txt varchar(1000);
            END;

    END;