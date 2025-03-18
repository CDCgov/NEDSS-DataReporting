IF
NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_srte_Codeset_Group_Metadata' and xtype = 'U')
BEGIN
CREATE TABLE dbo.nrt_srte_Codeset_Group_Metadata
(
    code_set_nm             varchar(256) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
    code_set_group_id       bigint                                            NOT NULL,
    vads_value_set_code     varchar(256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    code_set_desc_txt       varchar(2000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    code_set_short_desc_txt varchar(2000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    ldf_picklist_ind_cd     char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    phin_std_val_ind        char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
    CONSTRAINT PK_Codeset_group41 PRIMARY KEY (code_set_group_id)
);

END;