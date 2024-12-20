IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_srte_Code_value_general' and xtype = 'U')	 
BEGIN	 
CREATE TABLE dbo.nrt_srte_Code_value_general (
	code_set_nm varchar(256) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	code varchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	code_desc_txt varchar(300) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	code_short_desc_txt varchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	code_system_cd varchar(300) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	code_system_desc_txt varchar(100) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	effective_from_time datetime NULL,
	effective_to_time datetime NULL,
	indent_level_nbr smallint NULL,
	is_modifiable_ind char(1) COLLATE SQL_Latin1_General_CP1_CI_AS DEFAULT 'Y' NULL,
	nbs_uid int NULL,
	parent_is_cd varchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	source_concept_id varchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	super_code_set_nm varchar(256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	super_code varchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	status_cd char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	status_time datetime NULL,
	concept_type_cd varchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	concept_code varchar(256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	concept_nm varchar(256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	concept_preferred_nm varchar(256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	concept_status_cd varchar(256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	concept_status_time datetime NULL,
	code_system_version_nbr varchar(256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	concept_order_nbr int NULL,
	admin_comments varchar(2000) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	add_time datetime NULL,
	add_user_id bigint NULL,
	CONSTRAINT PK_Code_value_general PRIMARY KEY (code_set_nm,code)
);
 CREATE NONCLUSTERED INDEX INDEX_CODE_VALUE_GENERAL_IND01 ON dbo.nrt_srte_Code_value_general (  code ASC  )  
	 WITH (  PAD_INDEX = OFF ,FILLFACTOR = 90   ,SORT_IN_TEMPDB = OFF , IGNORE_DUP_KEY = OFF , STATISTICS_NORECOMPUTE = OFF , ONLINE = OFF , ALLOW_ROW_LOCKS = ON , ALLOW_PAGE_LOCKS = ON  )
	 ON [PRIMARY ] ;
END;