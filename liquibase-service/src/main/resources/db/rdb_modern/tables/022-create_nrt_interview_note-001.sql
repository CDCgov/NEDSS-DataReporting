IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_interview_note' and xtype = 'U')
CREATE TABLE dbo.nrt_interview_note
(
    interview_uid    bigint                                          NOT NULL,
    nbs_answer_uid   bigint                                          NULL,
    user_first_name  varchar(200)                                    NULL,
    user_last_name   varchar(200)                                    NULL,
    user_comment     varchar(2000)                                   NULL,
    comment_date     datetime                                        NULL,
    refresh_datetime datetime2(7) GENERATED ALWAYS AS ROW START      NOT NULL,
    max_datetime     datetime2(7) GENERATED ALWAYS AS ROW END HIDDEN NOT NULL,
    PERIOD FOR SYSTEM_TIME (refresh_datetime, max_datetime)
);

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_interview_note' and xtype = 'U')
    BEGIN

--CNDE-1921
        IF NOT EXISTS(SELECT 1 FROM sys.columns   WHERE Name = N'record_status_cd'   AND Object_ID = Object_ID(N'nrt_interview_note'))
            BEGIN
                ALTER TABLE nrt_interview_note
                    ADD record_status_cd varchar(4000);
            END;

    END;

