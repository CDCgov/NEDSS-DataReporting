IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_srte_Program_area_code' and xtype = 'U')
CREATE TABLE dbo.nrt_srte_Program_area_code (
	prog_area_cd varchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	prog_area_desc_txt varchar(50) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	nbs_uid int NULL,
	status_cd char(1) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	status_time datetime NULL,
	code_set_nm varchar(256) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	code_seq smallint NULL,
	CONSTRAINT PK_Program_area_code196 PRIMARY KEY (prog_area_cd)
);
