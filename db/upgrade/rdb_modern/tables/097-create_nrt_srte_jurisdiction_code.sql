IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_srte_jurisdiction_code' and xtype = 'U')
BEGIN
    CREATE TABLE dbo.nrt_srte_jurisdiction_code(
        code                                varchar(20) NOT NULL,
        type_cd                             varchar(20) NOT NULL,
        assigning_authority_cd              varchar(199) NULL,
        assigning_authority_desc_txt        varchar(100) NULL,
        code_desc_txt                       varchar(255) NULL,
        code_short_desc_txt                 varchar(50) NULL,
        effective_from_time                 datetime NULL,
        effective_to_time                   datetime NULL,
        indent_level_nbr                    smallint NULL,
        is_modifiable_ind                   char(1) NULL,
        parent_is_cd                        varchar(20) NULL,
        state_domain_cd                     varchar(20) NULL,
        status_cd                           varchar(1) NULL,
        status_time                         datetime NULL,
        code_set_nm                         varchar(256) NULL,
        code_seq_num                        smallint NULL,
        nbs_uid                             int NULL,
        source_concept_id                   varchar(20) NULL,
        code_system_cd                      varchar(300) NULL,
        code_system_desc_txt                varchar(100) NULL,
        export_ind                          char(1) NULL,
    CONSTRAINT PK_Jurisdiction_code PRIMARY KEY CLUSTERED 
    (
        code ASC
    )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
    ) ON [PRIMARY]

    ALTER TABLE dbo.nrt_srte_jurisdiction_code ADD  DEFAULT ('Y') FOR is_modifiable_ind

    ALTER TABLE dbo.nrt_srte_jurisdiction_code ADD  DEFAULT ('A') FOR status_cd

END;