IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_observation' and xtype = 'U')
    BEGIN

        IF NOT EXISTS(SELECT 1 FROM sys.columns   WHERE Name = N'ctrl_cd_display_form'   AND Object_ID = Object_ID(N'nrt_observation'))
            BEGIN
                ALTER TABLE nrt_observation
                    ADD ctrl_cd_display_form varchar(20);
            END;

    END;