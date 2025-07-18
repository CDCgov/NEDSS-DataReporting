IF NOT EXISTS (SELECT 1
               FROM sysobjects
               WHERE name = 'nrt_srte_Cntycity_code_value'
                 and xtype = 'U')
    BEGIN
        CREATE TABLE dbo.nrt_srte_Cntycity_code_value
        (
            cnty_code           varchar(20) NOT NULL,
            city_code           varchar(20) NOT NULL,
            effective_from_time datetime    NULL,
            effective_to_time   datetime    NULL,
            CONSTRAINT PK_Cntycity_code_value PRIMARY KEY CLUSTERED (cnty_code, city_code)
        ) ON [PRIMARY]
    END;