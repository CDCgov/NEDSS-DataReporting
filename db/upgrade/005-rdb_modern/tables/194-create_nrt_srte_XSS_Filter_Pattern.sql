IF NOT EXISTS (SELECT 1
               FROM sysobjects
               WHERE name = 'nrt_srte_XSS_Filter_Pattern'
                 and xtype = 'U')
    BEGIN
        CREATE TABLE dbo.nrt_srte_XSS_Filter_Pattern
        (
            XSS_Filter_Pattern_uid bigint       NOT NULL,
            reg_exp                varchar(250) NOT NULL,
            flag                   varchar(250) NOT NULL,
            desc_txt               varchar(200) NULL,
            status_cd              varchar(50)  NOT NULL,
            status_time            datetime     NOT NULL,
            CONSTRAINT PK_XSS_Filter_Pattern PRIMARY KEY CLUSTERED (XSS_Filter_Pattern_uid)
        ) ON [PRIMARY]
    END;