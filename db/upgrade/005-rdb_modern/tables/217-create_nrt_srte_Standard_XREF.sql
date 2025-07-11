IF NOT EXISTS (SELECT 1
               FROM sysobjects
               WHERE name = 'nrt_srte_Standard_XREF'
                 and xtype = 'U')
    BEGIN
        CREATE TABLE dbo.nrt_srte_Standard_XREF
        (
            standard_xref_uid  bigint       NOT NULL,
            from_code_set_nm   varchar(256) NOT NULL,
            from_seq_num       smallint     NOT NULL,
            from_code          varchar(20)  NOT NULL,
            from_code_desc_txt varchar(300) NULL,
            to_code_set_nm     varchar(256) NOT NULL,
            to_seq_num         smallint     NOT NULL,
            to_code            varchar(20)  NOT NULL,
            to_code_desc_txt   varchar(300) NULL,
            to_code_system_cd  varchar(300) NULL,
            status_cd          varchar(1)   NULL,
            status_time        datetime     NULL,
            CONSTRAINT PK_StdXREF_standardXrefUid PRIMARY KEY CLUSTERED (standard_xref_uid)
        ) ON [PRIMARY]
    END;