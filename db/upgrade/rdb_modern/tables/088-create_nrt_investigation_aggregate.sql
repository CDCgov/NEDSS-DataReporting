IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_investigation_aggregate' and xtype = 'U')
CREATE TABLE dbo.nrt_investigation_aggregate
(
    act_uid                bigint                                          NOT NULL,
    nbs_case_answer_uid    bigint                                          NOT NULL,
    answer_txt             varchar(2000)                                   NULL,
    data_type              varchar(20)                                     NULL,
    code_set_group_id      bigint                                          NULL,
    datamart_column_nm     varchar(30)                                     NULL,
    batch_id               bigint                                          NULL,
    refresh_datetime       datetime2(7) GENERATED ALWAYS AS ROW START      NOT NULL,
    max_datetime           datetime2(7) GENERATED ALWAYS AS ROW END HIDDEN NOT NULL,
    PERIOD FOR SYSTEM_TIME (refresh_datetime, max_datetime),
    PRIMARY KEY (act_uid, nbs_case_answer_uid)
);
