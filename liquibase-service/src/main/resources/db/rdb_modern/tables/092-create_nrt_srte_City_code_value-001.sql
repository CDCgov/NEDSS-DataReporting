IF
NOT EXISTS (SELECT 1
               FROM sysobjects
               WHERE name = 'nrt_srte_City_code_value'
                 and xtype = 'U')
BEGIN
CREATE TABLE dbo.nrt_srte_City_code_value
(
    code                         varchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    assigning_authority_cd       varchar(199) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    assigning_authority_desc_txt varchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    code_desc_txt                varchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    code_short_desc_txt          varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    effective_from_time          datetime NULL,
    effective_to_time            datetime NULL,
    excluded_txt                 varchar(256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    indent_level_nbr             smallint NULL,
    is_modifiable_ind            char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    parent_is_cd                 varchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    status_cd                    varchar(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    status_time                  datetime NULL,
    code_set_nm                  varchar(256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    seq_num                      smallint NULL,
    nbs_uid                      int NULL,
    source_concept_id            varchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CONSTRAINT PK_City_code_value PRIMARY KEY (code)
);
END;