IF NOT EXISTS (SELECT 1
               FROM sysobjects
               WHERE name = 'nrt_srte_Lab_result_Snomed'
                 and xtype = 'U')
    BEGIN
        CREATE TABLE dbo.nrt_srte_Lab_result_Snomed
        (
            lab_result_cd       varchar(20) NOT NULL,
            laboratory_id       varchar(20) NOT NULL,
            snomed_cd           varchar(20) NOT NULL,
            effective_from_time datetime    NULL,
            effective_to_time   datetime    NULL,
            status_cd           char(1)     NULL,
            status_time         datetime    NULL,
            CONSTRAINT PK_Lab_result_SNOMED205 PRIMARY KEY CLUSTERED (lab_result_cd, laboratory_id, snomed_cd)
        ) ON [PRIMARY]
    END;