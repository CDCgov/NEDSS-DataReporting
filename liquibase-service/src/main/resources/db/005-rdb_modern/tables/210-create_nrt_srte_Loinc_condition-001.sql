IF NOT EXISTS (SELECT 1
               FROM sysobjects
               WHERE name = 'nrt_srte_Loinc_condition'
                 and xtype = 'U')
    BEGIN
        CREATE TABLE dbo.nrt_srte_Loinc_condition
        (
            loinc_cd               varchar(20)  NOT NULL,
            condition_cd           varchar(20)  NOT NULL,
            disease_nm             varchar(200) NULL,
            reported_value         varchar(20)  NULL,
            reported_numeric_value varchar(20)  NULL,
            status_cd              char(1)      NULL,
            status_time            datetime     NULL,
            effective_from_time    datetime     NULL,
            effective_to_time      datetime     NULL,
            CONSTRAINT PK_loinc_cd PRIMARY KEY CLUSTERED (loinc_cd)
        ) ON [PRIMARY]
    END;