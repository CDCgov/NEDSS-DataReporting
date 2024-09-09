IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_observation' and xtype = 'U')
    BEGIN

        IF NOT EXISTS(SELECT 1 FROM sys.columns   WHERE Name = N'ctrl_cd_display_form'   AND Object_ID = Object_ID(N'nrt_observation'))
            BEGIN
                ALTER TABLE nrt_observation
                    ADD ctrl_cd_display_form varchar(20);
            END;

        IF NOT EXISTS(SELECT 1 FROM sys.columns   WHERE Name = N'obs_domain_cd_st_1'   AND Object_ID = Object_ID(N'nrt_observation'))
            BEGIN
                ALTER TABLE nrt_observation
                    ADD obs_domain_cd_st_1 varchar(20);

            END;
        IF NOT EXISTS(SELECT 1 FROM sys.columns   WHERE Name = N'processing_decision_cd'   AND Object_ID = Object_ID(N'nrt_observation'))
            BEGIN
                ALTER TABLE nrt_observation
                    ADD processing_decision_cd varchar(20);

            END;

        IF NOT EXISTS(SELECT 1 FROM sys.columns   WHERE Name = N'cd'   AND Object_ID = Object_ID(N'nrt_observation'))
            BEGIN
                ALTER TABLE nrt_observation
                    ADD cd varchar(50);
            END;

        IF NOT EXISTS(SELECT 1 FROM sys.columns   WHERE Name = N'shared_ind'   AND Object_ID = Object_ID(N'nrt_observation'))
            BEGIN
                ALTER TABLE nrt_observation
                    ADD shared_ind char(1);
            END;

    END;