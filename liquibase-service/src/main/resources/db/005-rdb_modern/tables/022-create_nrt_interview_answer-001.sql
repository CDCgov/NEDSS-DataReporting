IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_interview_answer' and xtype = 'U')
CREATE TABLE dbo.nrt_interview_answer
(
    interview_uid    bigint                                          NOT NULL,
    rdb_column_nm    varchar(30)                                     NULL,
    answer_val       VARCHAR(4000)                                   NULL,
    refresh_datetime datetime2(7) GENERATED ALWAYS AS ROW START      NOT NULL,
    max_datetime     datetime2(7) GENERATED ALWAYS AS ROW END HIDDEN NOT NULL,
    PERIOD FOR SYSTEM_TIME (refresh_datetime, max_datetime)
);

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_interview_answer' and xtype = 'U')
    BEGIN

--CNDE-2295
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'batch_id' AND Object_ID = Object_ID(N'nrt_interview_answer'))
            BEGIN
                ALTER TABLE dbo.nrt_interview_answer
                    ADD batch_id bigint;
            END;

    END;
