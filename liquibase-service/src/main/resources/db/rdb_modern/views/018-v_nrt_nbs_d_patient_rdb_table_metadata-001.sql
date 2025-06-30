IF EXISTS(SELECT * FROM sys.views WHERE name = 'v_nrt_nbs_d_patient_rdb_table_metadata')
BEGIN
    DROP VIEW [dbo].v_nrt_nbs_d_patient_rdb_table_metadata
END
GO

CREATE VIEW [dbo].v_nrt_nbs_d_patient_rdb_table_metadata 
AS
SELECT DISTINCT 
	page.FORM_CD, 
	page.DATAMART_NM, 
	rdb_meta.RDB_TABLE_NM,
	rdb_meta.RDB_COLUMN_NM,
	rdb_meta.USER_DEFINED_COLUMN_NM,
	ui_meta.INVESTIGATION_FORM_CD,
	COALESCE(rdb_meta.RDB_COLUMN_NM,',' ,'')  + ', '+ COALESCE(rdb_meta.USER_DEFINED_COLUMN_NM ,'') AS rdb_column_nm_list
FROM [dbo].v_nrt_nbs_page page WITH(NOLOCK)
INNER JOIN [dbo].nrt_odse_NBS_ui_metadata ui_meta WITH(NOLOCK)
	ON ui_meta.INVESTIGATION_FORM_CD = page.FORM_CD
INNER JOIN [dbo].v_nrt_odse_NBS_rdb_metadata_recent rdb_meta WITH(NOLOCK)  
	ON ui_meta.NBS_UI_METADATA_UID = rdb_meta.NBS_UI_METADATA_UID
	AND rdb_meta.RDB_TABLE_NM='D_PATIENT' 
	AND rdb_meta.RDB_COLUMN_NM NOT IN ('PATIENT_WORK_STREET_ADDRESS_1', 'PATIENT_WORK_STREET_ADDRESS_2')
	AND rdb_meta.USER_DEFINED_COLUMN_NM <> '' AND rdb_meta.USER_DEFINED_COLUMN_NM IS NOT NULL;