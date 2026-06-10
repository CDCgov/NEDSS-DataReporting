IF NOT EXISTS (SELECT 1
               FROM sysobjects
               WHERE name = 'nrt_srte_LDF_page_set'
                 and xtype = 'U')
    BEGIN
        CREATE TABLE dbo.nrt_srte_LDF_page_set
        (
            ldf_page_id         varchar(20)  NOT NULL,
            business_object_nm  varchar(20)  NULL,
            condition_cd        varchar(20)  NULL,
            ui_display          varchar(10)  NULL,
            indent_level_nbr    smallint     NULL,
            parent_is_cd        varchar(20)  NULL,
            code_set_nm         varchar(256) NULL,
            seq_num             smallint     NULL,
            code_version        varchar(10)  NULL,
            nbs_uid             int          NULL,
            effective_from_time datetime     NULL,
            effective_to_time   datetime     NULL,
            status_cd           char(1)      NULL,
            code_short_desc_txt varchar(50)  NULL,
            display_row         smallint     NULL,
            display_column      smallint     NULL,
            CONSTRAINT PK_LDF_PAGE_SET PRIMARY KEY CLUSTERED (ldf_page_id)
        ) ON [PRIMARY]
    END;