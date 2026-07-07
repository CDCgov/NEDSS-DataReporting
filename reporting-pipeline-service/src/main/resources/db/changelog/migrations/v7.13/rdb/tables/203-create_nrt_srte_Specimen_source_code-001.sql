IF NOT EXISTS (SELECT 1
               FROM sysobjects
               WHERE name = 'nrt_srte_Specimen_source_code'
                 and xtype = 'U')
    BEGIN
        CREATE TABLE dbo.nrt_srte_Specimen_source_code
        (
            specimen_source_uid          bigint       NOT NULL,
            code_set_nm                  varchar(256) NOT NULL,
            seq_num                      smallint     NOT NULL,
            code                         varchar(20)  NOT NULL,
            specimen_source_desc_txt     varchar(300) NULL,
            code_system_cd               varchar(300) NULL,
            code_system_desc_txt         varchar(100) NULL,
            assigning_authority_cd       varchar(199) NULL,
            assigning_authority_desc_txt varchar(100) NULL,
            is_modifiable_ind            char(1)      NULL,
            status_cd                    char(1)      NULL,
            status_time                  datetime     NULL,
            CONSTRAINT PK_Specimen_source_code233 PRIMARY KEY CLUSTERED (specimen_source_uid)
        ) ON [PRIMARY]

        ALTER TABLE dbo.nrt_srte_Specimen_source_code
            ADD DEFAULT ('N') FOR is_modifiable_ind
    END;