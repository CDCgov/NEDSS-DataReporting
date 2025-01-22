IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'Condition_code' and xtype = 'U')
    BEGIN

        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'rhap_parse_nbs_ind' AND Object_ID = Object_ID(N'Condition_code'))
            BEGIN
                ALTER TABLE dbo.Condition_code
                    ADD rhap_parse_nbs_ind varchar(1);
            END;

        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'rhap_action_value' AND Object_ID = Object_ID(N'Condition_code'))
            BEGIN
                ALTER TABLE dbo.Condition_code
                    ADD rhap_action_value varchar(200);
            END;
    END;