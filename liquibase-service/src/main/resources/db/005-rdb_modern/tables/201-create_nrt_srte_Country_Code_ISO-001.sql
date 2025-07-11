IF NOT EXISTS (SELECT 1
               FROM sysobjects
               WHERE name = 'nrt_srte_Country_Code_ISO'
                 and xtype = 'U')
    BEGIN
        CREATE TABLE dbo.nrt_srte_Country_Code_ISO
        (
            code_set_nm                  varchar(256) NOT NULL,
            seq_num                      smallint     NOT NULL,
            code                         varchar(20)  NOT NULL,
            code_desc_txt                varchar(100) NULL,
            code_system_cd               varchar(300) NULL,
            code_system_desc_txt         varchar(100) NULL,
            code_short_desc_txt          varchar(100) NULL,
            assigning_authority_cd       varchar(199) NULL,
            assigning_authority_desc_txt varchar(100) NULL,
            status_cd                    varchar(1)   NULL,
            status_time                  datetime     NULL,
            CONSTRAINT PK_CntryCd_codeSetNmSeqNumCCd PRIMARY KEY CLUSTERED (code_set_nm, seq_num, code)
        ) ON [PRIMARY]
    END;