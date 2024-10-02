IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_observation' and xtype = 'U')
    BEGIN

        IF NOT EXISTS(SELECT 1 FROM sys.columns   WHERE Name = N'accession_number'   AND Object_ID = Object_ID(N'nrt_observation'))
            BEGIN
                ALTER TABLE nrt_observation
                    ADD accession_number varchar(199);
            END;

        IF NOT EXISTS(SELECT 1 FROM sys.columns   WHERE Name = N'morb_hosp_id'   AND Object_ID = Object_ID(N'nrt_observation'))
            BEGIN
                ALTER TABLE nrt_observation
                    ADD morb_hosp_id bigint;

            END;
        IF NOT EXISTS(SELECT 1 FROM sys.columns   WHERE Name = N'transcriptionist_id_assign_auth'   AND Object_ID = Object_ID(N'nrt_observation'))
            BEGIN
                ALTER TABLE nrt_observation
                    ADD transcriptionist_id_val varchar(199);

            END;

        IF NOT EXISTS(SELECT 1 FROM sys.columns   WHERE Name = N'transcriptionist_auth_type'   AND Object_ID = Object_ID(N'nrt_observation'))
            BEGIN
                ALTER TABLE nrt_observation
                    ADD transcriptionist_auth_type varchar(100);
            END;

        IF NOT EXISTS(SELECT 1 FROM sys.columns   WHERE Name = N'assistant_interpreter_assign_auth'   AND Object_ID = Object_ID(N'nrt_observation'))
            BEGIN
                ALTER TABLE nrt_observation
                    ADD assistant_interpreter_id_val varchar(199);
            END;

        IF NOT EXISTS(SELECT 1 FROM sys.columns   WHERE Name = N'assistant_interpreter_auth_type'   AND Object_ID = Object_ID(N'nrt_observation'))
            BEGIN
                ALTER TABLE nrt_observation
                    ADD assistant_interpreter_auth_type varchar(100);
            END;

        IF NOT EXISTS(SELECT 1 FROM sys.columns   WHERE Name = N'priority_cd'   AND Object_ID = Object_ID(N'nrt_observation'))
            BEGIN
                ALTER TABLE nrt_observation
                    ADD priority_cd varchar(20);
            END;

    END;