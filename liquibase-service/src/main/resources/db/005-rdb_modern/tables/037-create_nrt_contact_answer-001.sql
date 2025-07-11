IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_contact_answer' and xtype = 'U')
    BEGIN
        CREATE TABLE dbo.nrt_contact_answer
        (
            contact_uid      bigint                                          NOT NULL,
            rdb_column_nm    varchar(30)                                     NULL,
            answer_val       varchar(4000)                                   NULL,
            refresh_datetime datetime2(7) GENERATED ALWAYS AS ROW START      NOT NULL,
            max_datetime     datetime2(7) GENERATED ALWAYS AS ROW END HIDDEN NOT NULL,
            PERIOD FOR SYSTEM_TIME (refresh_datetime, max_datetime)
        );
    END;
