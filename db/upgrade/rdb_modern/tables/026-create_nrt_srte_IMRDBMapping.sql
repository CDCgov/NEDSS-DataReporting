IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_srte_IMRDBMapping' and xtype = 'U')
CREATE TABLE dbo.nrt_srte_IMRDBMapping (
	IMRDBMapping_id int IDENTITY(1,1) NOT NULL,
	unique_cd varchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	unique_name varchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	description varchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	DB_table varchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	DB_field varchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	RDB_table varchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	RDB_attribute varchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	other_attributes varchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	condition_cd varchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	CONSTRAINT PK_IMRDBMapping PRIMARY KEY (IMRDBMapping_id)
);

