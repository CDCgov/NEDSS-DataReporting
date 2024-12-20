IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_srte_Codeset' and xtype = 'U')	 
BEGIN
CREATE TABLE dbo.nrt_srte_Codeset (
	code_set_nm varchar(256) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	assigning_authority_cd varchar(199) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	assigning_authority_desc_txt varchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	code_set_desc_txt varchar(2000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	class_cd varchar(30) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	effective_from_time datetime NULL,
	effective_to_time datetime NULL,
	is_modifiable_ind char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	nbs_uid int NULL,
	source_version_txt varchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	source_domain_nm varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	status_cd varchar(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	status_to_time datetime NULL,
	code_set_group_id bigint NULL,
	admin_comments varchar(2000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	value_set_nm varchar(256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	ldf_picklist_ind_cd char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	value_set_code varchar(256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	value_set_type_cd varchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	value_set_oid varchar(256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	value_set_status_cd varchar(256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	value_set_status_time datetime NULL,
	parent_is_cd bigint NULL,
	add_time datetime NULL,
	add_user_id bigint NULL,
	CONSTRAINT PK_Codeset PRIMARY KEY (class_cd,code_set_nm)
);
 CREATE NONCLUSTERED INDEX RDB_PERF_03312021_1 ON dbo.nrt_srte_Codeset (  code_set_group_id ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 100  ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
	 
END;