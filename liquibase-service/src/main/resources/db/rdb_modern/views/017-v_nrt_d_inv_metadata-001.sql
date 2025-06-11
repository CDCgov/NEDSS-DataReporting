IF EXISTS(SELECT * FROM sys.views WHERE name = 'v_nrt_d_inv_metadata')
BEGIN
    DROP VIEW [dbo].v_nrt_d_inv_metadata
END;
--GO   --"GO" not supported by liquibase, keep "GO" in manual scripts

CREATE VIEW [dbo].v_nrt_d_inv_metadata 
AS
SELECT DISTINCT 
	ui_meta.INVESTIGATION_FORM_CD,
	page.FORM_CD,
	page.DATAMART_NM,
	rdb_meta.RDB_TABLE_NM,
	rdb_meta.RDB_COLUMN_NM,
	rdb_meta.USER_DEFINED_COLUMN_NM,
	OTHER_VALUE_IND_CD,
	data_type,
	CODE_SET_GROUP_ID,
	mask,
	UNIT_TYPE_CD
FROM [dbo].v_nrt_nbs_page page WITH(NOLOCK)
INNER JOIN [dbo].nrt_odse_NBS_ui_metadata ui_meta WITH(NOLOCK) 
	ON ui_meta.INVESTIGATION_FORM_CD = page.FORM_CD
INNER JOIN [dbo].v_nrt_odse_NBS_rdb_metadata_recent rdb_meta WITH(NOLOCK)
  	ON ui_meta.NBS_UI_METADATA_UID = rdb_meta.NBS_UI_METADATA_UID
WHERE 
	QUESTION_GROUP_SEQ_NBR IS NULL
	AND rdb_meta.USER_DEFINED_COLUMN_NM <> ''
	AND rdb_meta.USER_DEFINED_COLUMN_NM IS NOT NULL;