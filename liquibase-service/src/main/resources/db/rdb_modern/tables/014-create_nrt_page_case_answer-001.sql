IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_page_case_answer' and xtype = 'U')
CREATE TABLE dbo.nrt_page_case_answer
(
    act_uid                bigint                                          NOT NULL,
    nbs_case_answer_uid    bigint                                          NOT NULL,
    nbs_ui_metadata_uid    bigint                                          NOT NULL,
    nbs_rdb_metadata_uid   bigint                                          NOT NULL,
    nbs_question_uid       bigint                                          NOT NULL,
    rdb_table_nm           varchar(30)                                     NULL,
    rdb_column_nm          varchar(30)                                     NULL,
    answer_txt             varchar(2000)                                   NULL,
    answer_group_seq_nbr   varchar(20)                                     NULL,
    investigation_form_cd  varchar(50)                                     NULL,
    unit_value             varchar(50)                                     NULL,
    question_identifier    varchar(50)                                     NULL,
    data_location          varchar(150)                                    NULL,
    question_label         varchar(300)                                    NULL,
    other_value_ind_cd     char(1)                                         NULL,
    unit_type_cd           varchar(20)                                     NULL,
    mask                   varchar(50)                                     NULL,
    data_type              varchar(20)                                     NULL,
    question_group_seq_nbr int                                             NULL,
    code_set_group_id      bigint                                          NULL,
    block_nm               varchar(30)                                     NULL,
    last_chg_time          datetime                                        NULL,
    record_status_cd       varchar(20)                                     NOT NULL,
    refresh_datetime       datetime2(7) GENERATED ALWAYS AS ROW START      NOT NULL,
    max_datetime           datetime2(7) GENERATED ALWAYS AS ROW END HIDDEN NOT NULL,
    PERIOD FOR SYSTEM_TIME (refresh_datetime, max_datetime)
);

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_page_case_answer' and xtype = 'U')
    BEGIN

--CNDE-2108
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'part_type_cd' AND Object_ID = Object_ID(N'nrt_page_case_answer'))
            BEGIN
                ALTER TABLE dbo.nrt_page_case_answer ADD part_type_cd varchar(50);
            END;

--CNDE-2295
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'batch_id' AND Object_ID = Object_ID(N'nrt_page_case_answer'))
            BEGIN
                ALTER TABLE dbo.nrt_page_case_answer
                    ADD batch_id bigint;
            END;

--CNDE-2334
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'datamart_column_nm' AND Object_ID = Object_ID(N'nrt_page_case_answer'))
            BEGIN
                ALTER TABLE dbo.nrt_page_case_answer
                    ADD datamart_column_nm varchar(30) ;
            END;

        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'seq_nbr' AND Object_ID = Object_ID(N'nrt_page_case_answer'))
            BEGIN
                ALTER TABLE dbo.nrt_page_case_answer
                    ADD seq_nbr int;
            END;

        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'ldf_status_cd' AND Object_ID = Object_ID(N'nrt_page_case_answer'))
            BEGIN
                ALTER TABLE dbo.nrt_page_case_answer
                    ADD ldf_status_cd varchar(20);
            END;  

        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'nbs_ui_component_uid' AND Object_ID = Object_ID(N'nrt_page_case_answer'))
            BEGIN
                ALTER TABLE dbo.nrt_page_case_answer
                    ADD nbs_ui_component_uid bigint;
            END;  


        IF EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'nbs_rdb_metadata_uid' AND Object_ID = Object_ID(N'nrt_page_case_answer'))
            BEGIN
                ALTER TABLE dbo.nrt_page_case_answer ALTER COLUMN nbs_rdb_metadata_uid bigint NULL;
            END;                        

    END;