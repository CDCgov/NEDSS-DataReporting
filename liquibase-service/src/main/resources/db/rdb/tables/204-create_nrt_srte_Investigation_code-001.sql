IF NOT EXISTS (SELECT 1
               FROM sysobjects
               WHERE name = 'nrt_srte_Investigation_code'
                 and xtype = 'U')
    BEGIN
        CREATE TABLE dbo.nrt_srte_Investigation_code
        (
            investigation_cd             varchar(20)  NOT NULL,
            investigation_desc_txt       varchar(255) NULL,
            assigning_authority_cd       varchar(199) NULL,
            assigning_authority_desc_txt varchar(100) NULL,
            code_system_cd               varchar(300) NULL,
            code_system_desc_txt         varchar(80)  NULL,
            code_version                 varchar(10)  NULL,
            effective_from_time          datetime     NULL,
            effective_to_time            datetime     NULL,
            status_cd                    varchar(1)   NULL,
            status_time                  datetime     NULL,
            nbs_uid                      smallint     NULL,
            source_concept_id            varchar(20)  NULL,
            code_set_nm                  varchar(256) NOT NULL,
            seq_num                      smallint     NOT NULL,
            CONSTRAINT PK_investigation_code212 PRIMARY KEY CLUSTERED (investigation_cd)
        ) ON [PRIMARY]
    END;