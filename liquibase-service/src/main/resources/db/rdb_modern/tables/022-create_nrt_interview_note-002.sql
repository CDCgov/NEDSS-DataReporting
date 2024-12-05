IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_interview_note' and xtype = 'U')
    BEGIN

        IF NOT EXISTS(SELECT 1 FROM sys.columns   WHERE Name = N'record_status_cd'   AND Object_ID = Object_ID(N'nrt_interview_note'))
            BEGIN
                ALTER TABLE nrt_interview_note
                    ADD record_status_cd varchar(4000);
            END;

    END;
