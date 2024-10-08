IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_observation' and xtype = 'U')
    BEGIN

        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'status_cd' AND object_id = Object_ID(N'nrt_observation'))
            BEGIN
            ALTER TABLE nrt_observation
                ADD status_cd char(1);
            END;

        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'cd_system_cd' AND object_id = Object_ID(N'nrt_observation'))
            BEGIN
            ALTER TABLE nrt_observation
                ADD cd_system_cd varchar(50);
            END;

        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'cd_system_desc_txt' AND object_id = Object_ID(N'nrt_observation'))
            BEGIN
            ALTER TABLE nrt_observation
                ADD cd_system_desc_txt varchar(100);
            END;

        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'ctrl_cd_user_defined_1' AND object_id = Object_ID(N'nrt_observation'))
            BEGIN
            ALTER TABLE nrt_observation
                ADD ctrl_cd_user_defined_1 varchar(20);
            END;

        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'alt_cd' AND object_id = Object_ID(N'nrt_observation'))
            BEGIN
            ALTER TABLE nrt_observation
                ADD alt_cd varchar(50);
            END;

        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'alt_cd_desc_txt' AND object_id = Object_ID(N'nrt_observation'))
            BEGIN
            ALTER TABLE nrt_observation
                ADD alt_cd_desc_txt varchar(1000);
            END;

        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'alt_cd_system_cd' AND object_id = Object_ID(N'nrt_observation'))
            BEGIN
            ALTER TABLE nrt_observation
                ADD alt_cd_system_cd varchar(300);
            END;

        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'alt_cd_system_desc_txt' AND object_id = Object_ID(N'nrt_observation'))
            BEGIN
                ALTER TABLE nrt_observation
                    ADD alt_cd_system_desc_txt varchar(100);
            END;

        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'method_cd' AND object_id = Object_ID(N'nrt_observation'))
            BEGIN
                ALTER TABLE nrt_observation
                    ADD method_cd varchar(2000);
            END;

        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'method_desc_txt' AND object_id = Object_ID(N'nrt_observation'))
            BEGIN
                ALTER TABLE nrt_observation
                    ADD method_desc_txt varchar(2000);
            END;

        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'target_site_cd' AND object_id = Object_ID(N'nrt_observation'))
            BEGIN
                ALTER TABLE nrt_observation
                    ADD target_site_cd varchar(20);
            END;

        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'target_site_desc_txt' AND object_id = Object_ID(N'nrt_observation'))
            BEGIN
                ALTER TABLE nrt_observation
                    ADD target_site_desc_txt varchar(100);
            END;

        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'txt' AND object_id = Object_ID(N'nrt_observation'))
            BEGIN
                ALTER TABLE nrt_observation
                    ADD txt varchar(1000);
            END;

        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'interpretation_cd' AND object_id = Object_ID(N'nrt_observation'))
            BEGIN
                ALTER TABLE nrt_observation
                    ADD interpretation_cd varchar(20);
            END;

        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'interpretation_desc_txt' AND object_id = Object_ID(N'nrt_observation'))
            BEGIN
                ALTER TABLE nrt_observation
                    ADD interpretation_desc_txt varchar(100);
            END;

        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'report_observation_uid' AND object_id = Object_ID(N'nrt_observation'))
            BEGIN
                ALTER TABLE nrt_observation
                    ADD report_observation_uid bigint;
            END;

        IF EXISTS(SELECT 1 FROM sys.columns col JOIN sys.types t on col.user_type_id = t.user_type_id
                           WHERE col.name = N'result_observation_uid' AND t.name = 'bigint' AND col.object_id = Object_ID(N'nrt_observation'))
            BEGIN
                ALTER TABLE nrt_observation
                    ALTER COLUMN result_observation_uid nvarchar(max);
            END;

        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'followup_observation_uid' AND object_id = Object_ID(N'nrt_observation'))
            BEGIN
                ALTER TABLE nrt_observation
                    ADD followup_observation_uid nvarchar(max);
            END;

        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'report_refr_uid' AND object_id = Object_ID(N'nrt_observation'))
            BEGIN
                ALTER TABLE nrt_observation
                    ADD report_refr_uid bigint;
            END;

        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'report_sprt_uid' AND object_id = Object_ID(N'nrt_observation'))
            BEGIN
                ALTER TABLE nrt_observation
                    ADD report_sprt_uid bigint;
            END;

        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'morb_physician_id' AND object_id = Object_ID(N'nrt_observation'))
            BEGIN
                ALTER TABLE nrt_observation
                    ADD morb_physician_id bigint;
            END;

        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'morb_reporter_id' AND object_id = Object_ID(N'nrt_observation'))
            BEGIN
                ALTER TABLE nrt_observation
                    ADD morb_reporter_id bigint;
            END;

        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'transcriptionist_id' AND object_id = Object_ID(N'nrt_observation'))
            BEGIN
                ALTER TABLE nrt_observation
                    ADD transcriptionist_id bigint;
            END;

        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'transcriptionist_val' AND object_id = Object_ID(N'nrt_observation'))
            BEGIN
                ALTER TABLE nrt_observation
                    ADD transcriptionist_val varchar(20);
            END;

        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'transcriptionist_first_nm' AND object_id = Object_ID(N'nrt_observation'))
            BEGIN
                ALTER TABLE nrt_observation
                    ADD transcriptionist_first_nm varchar(50);
            END;

        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'transcriptionist_last_nm' AND object_id = Object_ID(N'nrt_observation'))
            BEGIN
                ALTER TABLE nrt_observation
                    ADD transcriptionist_last_nm varchar(50);
            END;

        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'assistant_interpreter_id' AND object_id = Object_ID(N'nrt_observation'))
            BEGIN
                ALTER TABLE nrt_observation
                    ADD assistant_interpreter_id bigint;
            END;

        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'assistant_interpreter_val' AND object_id = Object_ID(N'nrt_observation'))
            BEGIN
                ALTER TABLE nrt_observation
                    ADD assistant_interpreter_val varchar(20);
            END;

        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'assistant_interpreter_first_nm' AND object_id = Object_ID(N'nrt_observation'))
            BEGIN
                ALTER TABLE nrt_observation
                    ADD assistant_interpreter_first_nm varchar(50);
            END;

        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'assistant_interpreter_last_nm' AND object_id = Object_ID(N'nrt_observation'))
            BEGIN
                ALTER TABLE nrt_observation
                    ADD assistant_interpreter_last_nm varchar(50);
            END;

        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'result_interpreter_id' AND object_id = Object_ID(N'nrt_observation'))
            BEGIN
                ALTER TABLE nrt_observation
                    ADD result_interpreter_id bigint;
            END;

        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'specimen_collector_id' AND object_id = Object_ID(N'nrt_observation'))
            BEGIN
                ALTER TABLE nrt_observation
                    ADD specimen_collector_id bigint;
            END;

        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'copy_to_provider_id' AND object_id = Object_ID(N'nrt_observation'))
            BEGIN
                ALTER TABLE nrt_observation
                    ADD copy_to_provider_id bigint;
            END;

        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'lab_test_technician_id' AND object_id = Object_ID(N'nrt_observation'))
            BEGIN
                ALTER TABLE nrt_observation
                    ADD lab_test_technician_id bigint;
            END;

        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'health_care_id' AND object_id = Object_ID(N'nrt_observation'))
            BEGIN
                ALTER TABLE nrt_observation
                    ADD health_care_id bigint;
            END;

        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'morb_hosp_reporter_id' AND object_id = Object_ID(N'nrt_observation'))
            BEGIN
                ALTER TABLE nrt_observation
                    ADD morb_hosp_reporter_id bigint;
            END;

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
                    ADD transcriptionist_id_assign_auth varchar(199);

            END;

        IF NOT EXISTS(SELECT 1 FROM sys.columns   WHERE Name = N'transcriptionist_auth_type'   AND Object_ID = Object_ID(N'nrt_observation'))
            BEGIN
                ALTER TABLE nrt_observation
                    ADD transcriptionist_auth_type varchar(100);
            END;

        IF NOT EXISTS(SELECT 1 FROM sys.columns   WHERE Name = N'assistant_interpreter_id_assign_auth'   AND Object_ID = Object_ID(N'nrt_observation'))
            BEGIN
                ALTER TABLE nrt_observation
                    ADD assistant_interpreter_id_assign_auth varchar(199);
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