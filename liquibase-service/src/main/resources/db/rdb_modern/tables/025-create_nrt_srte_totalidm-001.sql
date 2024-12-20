IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_srte_TotalIDM' and xtype = 'U')
CREATE TABLE dbo.nrt_srte_TotalIDM (
	TotalIDM_id int IDENTITY(1,1) NOT NULL,
	unique_cd nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	SRT_reference nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	format nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	label nvarchar(255) COLLATE SQL_Latin1_General_CP1_CI_AS NULL,
	CONSTRAINT PK_TotalIDM PRIMARY KEY (TotalIDM_id)
);

