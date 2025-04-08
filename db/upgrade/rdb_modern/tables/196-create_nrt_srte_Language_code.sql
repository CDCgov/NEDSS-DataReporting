IF NOT EXISTS (SELECT 1
               FROM sysobjects
               WHERE name = 'nrt_srte_Language_code'
                 and xtype = 'U')
    BEGIN
        CREATE TABLE dbo.nrt_srte_Language_code
        (
            code                         varchar(20)   NOT NULL,
            assigning_authority_cd       varchar(199)  NULL,
            assigning_authority_desc_txt varchar(100)  NULL,
            code_desc_txt                varchar(255)  NULL,
            code_short_desc_txt          varchar(50)   NULL,
            effective_from_time          datetime      NULL,
            effective_to_time            datetime      NULL,
            key_info_txt                 varchar(2000) NULL,
            indent_level_nbr             smallint      NULL,
            is_modifiable_ind            char(1)       NULL,
            parent_is_cd                 varchar(20)   NULL,
            nbs_uid                      int           NOT NULL,
            status_cd                    varchar(1)    NULL,
            status_time                  datetime      NULL,
            code_set_nm                  varchar(256)  NULL,
            seq_num                      smallint      NULL,
            source_concept_id            varchar(20)   NULL,
            CONSTRAINT PK_ISO_language_code_value PRIMARY KEY CLUSTERED (code)
        ) ON [PRIMARY]

        ALTER TABLE dbo.nrt_srte_Language_code
            ADD DEFAULT ('Y') FOR is_modifiable_ind
        ALTER TABLE dbo.nrt_srte_Language_code
            ADD DEFAULT ('A') FOR status_cd
    END;