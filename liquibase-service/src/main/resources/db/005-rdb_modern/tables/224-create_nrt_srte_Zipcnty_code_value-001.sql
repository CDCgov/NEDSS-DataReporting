IF NOT EXISTS (SELECT 1
               FROM sysobjects
               WHERE name = 'nrt_srte_Zipcnty_code_value'
                 and xtype = 'U')
    BEGIN
        CREATE TABLE dbo.nrt_srte_Zipcnty_code_value
        (
            zip_code            varchar(20) NOT NULL,
            cnty_code           varchar(20) NOT NULL,
            effective_from_time datetime    NULL,
            effective_to_time   datetime    NULL,
            CONSTRAINT PK_Zipcnty_code_value PRIMARY KEY CLUSTERED (zip_code, cnty_code)
        ) ON [PRIMARY]
    END;