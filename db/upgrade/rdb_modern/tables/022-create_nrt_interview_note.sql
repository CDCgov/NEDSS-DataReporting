IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_interview_note' AND xtype = 'U')
    BEGIN
        CREATE TABLE dbo.nrt_interview_note
        (
            interview_uid    bigint                                          NOT NULL,
            nbs_answer_uid   bigint                                          NULL,
            user_first_name  varchar(200)                                    NULL,
            user_last_name   varchar(200)                                    NULL,
            user_comment     varchar(2000)                                   NULL,
            comment_date     datetime                                        NULL,
            record_status_cd varchar(4000)                                   NULL,
            batch_id         bigint                                          NULL,
            refresh_datetime datetime2(7) GENERATED ALWAYS AS ROW START      NOT NULL,
            max_datetime     datetime2(7) GENERATED ALWAYS AS ROW END HIDDEN NOT NULL,
            PERIOD FOR SYSTEM_TIME (refresh_datetime, max_datetime)
        );
    END

