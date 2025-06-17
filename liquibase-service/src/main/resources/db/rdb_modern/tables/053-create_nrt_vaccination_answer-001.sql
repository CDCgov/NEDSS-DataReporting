IF NOT EXISTS (SELECT 1 FROM sysobjects  WHERE name = 'nrt_vaccination_answer' and xtype = 'U')
    BEGIN
        CREATE TABLE dbo.nrt_vaccination_answer
        (
            vaccination_uid  bigint                                          NOT NULL,
            rdb_column_nm    varchar(30)                                     NULL,
            answer_val       varchar(4000)                                   NULL,
            refresh_datetime datetime2(7) GENERATED ALWAYS AS ROW START      NOT NULL,
            max_datetime     datetime2(7) GENERATED ALWAYS AS ROW END HIDDEN NOT NULL,
            PERIOD FOR SYSTEM_TIME (refresh_datetime, max_datetime)
        );
    END;

IF NOT EXISTS(SELECT 1 FROM sys.objects WHERE type = 'PK' AND object_id = OBJECT_ID('nrt_vaccination_answer'))
    BEGIN
        ALTER TABLE dbo.nrt_vaccination_answer
        ADD CONSTRAINT pk_nrt_vaccination_answer PRIMARY KEY (vaccination_uid);
    END
