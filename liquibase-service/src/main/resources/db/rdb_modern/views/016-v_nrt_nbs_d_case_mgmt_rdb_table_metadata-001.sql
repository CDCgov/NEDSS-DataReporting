CREATE OR ALTER VIEW dbo.v_nrt_nbs_d_case_mgmt_rdb_table_metadata AS
SELECT DISTINCT 
	page.FORM_CD, 
	page.DATAMART_NM, 
	rdb_meta.RDB_TABLE_NM,
  	rdb_meta.RDB_COLUMN_NM,
	rdb_meta.USER_DEFINED_COLUMN_NM,
	ui_meta.INVESTIGATION_FORM_CD,
  	COALESCE(rdb_meta.RDB_COLUMN_NM,',' ,'')  + ', '+ coalesce(rdb_meta.USER_DEFINED_COLUMN_NM ,'') AS rdb_column_nm_list
FROM dbo.v_nrt_nbs_page page 
INNER JOIN [dbo].nrt_odse_NBS_ui_metadata  ui_meta with ( nolock) 
	ON ui_meta.INVESTIGATION_FORM_CD = page.FORM_CD
INNER JOIN [dbo].v_nrt_odse_NBS_rdb_metadata_recent rdb_meta with ( nolock)  
	ON ui_meta.NBS_UI_METADATA_UID = rdb_meta.NBS_UI_METADATA_UID
WHERE 
	RDB_TABLE_NM='D_CASE_MANAGEMENT' 
    AND rdb_meta.USER_DEFINED_COLUMN_NM <> '' 
	AND rdb_meta.USER_DEFINED_COLUMN_NM IS NOT NULL;