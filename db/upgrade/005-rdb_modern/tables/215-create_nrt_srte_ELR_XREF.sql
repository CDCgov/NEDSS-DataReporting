IF NOT EXISTS (SELECT 1
               FROM sysobjects
               WHERE name = 'nrt_srte_ELR_XREF'
                 and xtype = 'U')
    BEGIN
        CREATE TABLE dbo.nrt_srte_ELR_XREF
        (
            from_code_set_nm    varchar(256) NOT NULL,
            from_seq_num        smallint     NOT NULL,
            from_code           varchar(20)  NOT NULL,
            to_code_set_nm      varchar(256) NOT NULL,
            to_seq_num          smallint     NOT NULL,
            to_code             varchar(20)  NOT NULL,
            effective_from_time datetime     NULL,
            effective_to_time   datetime     NULL,
            status_cd           char(1)      NULL,
            status_time         datetime     NULL,
            laboratory_id       varchar(20)  NULL,
            nbs_uid             int          NULL,
            CONSTRAINT PK_ELR_XREF190 PRIMARY KEY CLUSTERED (from_code_set_nm, from_seq_num, from_code, to_code_set_nm,
                                                             to_seq_num, to_code)
        ) ON [PRIMARY]
    END;