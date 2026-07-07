IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_srte_Anatomic_site_code' and xtype = 'U')
BEGIN
CREATE TABLE dbo.nrt_srte_Anatomic_site_code
(
    anatomic_site_uid            bigint                                                   NOT NULL,
    code_set_nm                  varchar(256) COLLATE SQL_Latin1_General_CP1_CI_AS        NOT NULL,
    seq_num                      smallint                                                 NOT NULL,
    code                         varchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS         NOT NULL,
    anatomic_site_desc_txt       varchar(300) COLLATE SQL_Latin1_General_CP1_CI_AS        NULL,
    assigning_authority_cd       varchar(199) COLLATE SQL_Latin1_General_CP1_CI_AS        NULL,
    assigning_authority_desc_txt varchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS        NULL,
    code_system_cd               varchar(300) COLLATE SQL_Latin1_General_CP1_CI_AS        NULL,
    code_system_desc_txt         varchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS        NULL,
    nbs_uid                      bigint                                                   NULL,
    is_modifiable_ind            char(1) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT 'N' NULL,
    status_cd                    char(1) COLLATE SQL_Latin1_General_CP1_CI_AS             NULL,
    status_time                  datetime                                                 NULL,
    CONSTRAINT PK_Anatomic_site_code234 PRIMARY KEY (anatomic_site_uid),
    CONSTRAINT UQ__Anatomic_site_co__318258D2 UNIQUE (nbs_uid)
);
END;
