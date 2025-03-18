IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_srte_Country_code' and xtype = 'U')
    BEGIN
        CREATE TABLE dbo.nrt_srte_Country_code
        (
            code                         varchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS   NOT NULL,
            assigning_authority_cd       varchar(199) COLLATE SQL_Latin1_General_CP1_CI_AS  NULL,
            assigning_authority_desc_txt varchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS  NULL,
            code_desc_txt                varchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS  NULL,
            code_short_desc_txt          varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS   NULL,
            effective_from_time          datetime                                           NULL,
            effective_to_time            datetime                                           NULL,
            excluded_txt                 varchar(1300) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
            key_info_txt                 varchar(2000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
            indent_level_nbr             smallint                                           NULL,
            is_modifiable_ind            char(1) COLLATE SQL_Latin1_General_CP1_CI_AS       NULL,
            parent_is_cd                 varchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS   NULL,
            status_cd                    varchar(1) COLLATE SQL_Latin1_General_CP1_CI_AS    NULL,
            status_time                  datetime                                           NULL,
            code_set_nm                  varchar(256) COLLATE SQL_Latin1_General_CP1_CI_AS  NULL,
            seq_num                      smallint                                           NULL,
            nbs_uid                      int                                                NULL,
            source_concept_id            varchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS   NULL,
            code_system_cd               varchar(300) COLLATE SQL_Latin1_General_CP1_CI_AS  NULL,
            code_system_desc_txt         varchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS  NULL,
            CONSTRAINT PK_Country_code PRIMARY KEY (code)
        );
        CREATE UNIQUE CLUSTERED INDEX IX_Country_code ON dbo.nrt_srte_Country_code (code_desc_txt ASC)
            WITH ( PAD_INDEX = OFF ,FILLFACTOR = 90 ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON )
            ON [PRIMARY ];
    END;