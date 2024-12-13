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

