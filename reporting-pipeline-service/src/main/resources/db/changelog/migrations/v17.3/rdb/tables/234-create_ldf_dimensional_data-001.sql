IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'LDF_DIMENSIONAL_DATA' and xtype = 'U')
BEGIN
	CREATE TABLE [dbo].[LDF_DIMENSIONAL_DATA] (
        COL1 NVARCHAR(4000) NULL,                   
        INVESTIGATION_UID BIGINT NOT NULL,          
        CODE_SHORT_DESC_TXT NVARCHAR(300) NULL,     
        LDF_UID BIGINT  NULL,                       
        CODE_SET_NM NVARCHAR(256) NULL,             
        LABEL_TXT NVARCHAR(300) NULL,               
        DATA_SOURCE NVARCHAR(50) NULL,              
        CDC_NATIONAL_ID NVARCHAR(50) NULL,          
        BUSINESS_OBJECT_NM NVARCHAR(50) NULL,       
        CONDITION_CD NVARCHAR(50),              
        CUSTOM_SUBFORM_METADATA_UID BIGINT,     
        PAGE_SET NVARCHAR(50),                  
        DATAMART_COLUMN_NM NVARCHAR(100),       
        PHC_CD NVARCHAR(10),                    
        DATA_TYPE NVARCHAR(50),                 
        FIELD_SIZE INT                          
    );
END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_ldf_dimensional_data_ldf_uid' AND object_id = OBJECT_ID('dbo.LDF_DIMENSIONAL_DATA'))
BEGIN
	CREATE INDEX idx_ldf_dimensional_data_ldf_uid
	ON [dbo].[LDF_DIMENSIONAL_DATA] (LDF_UID);
END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_ldf_dimensional_data_investigation_uid' AND object_id = OBJECT_ID('dbo.LDF_DIMENSIONAL_DATA'))
BEGIN
	CREATE INDEX idx_ldf_dimensional_data_investigation_uid
	ON [dbo].[LDF_DIMENSIONAL_DATA] (INVESTIGATION_UID);
END

IF NOT EXISTS(SELECT * FROM sys.indexes WHERE name = 'idx_ldf_dimensional_data_investigation_uid_ldf_uid' AND object_id = OBJECT_ID('dbo.LDF_DIMENSIONAL_DATA'))
BEGIN
	CREATE INDEX idx_ldf_dimensional_data_investigation_uid_ldf_uid
	ON [dbo].[LDF_DIMENSIONAL_DATA] (INVESTIGATION_UID, LDF_UID);
END