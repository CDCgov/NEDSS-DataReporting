CREATE OR ALTER VIEW dbo.v_nrt_d_inv_repeat_metadata AS
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
  UNIT_TYPE_CD,
  BLOCK_NM,
  BLOCK_PIVOT_NBR,
  PART_TYPE_CD,
  QUESTION_GROUP_SEQ_NBR
FROM dbo.v_nrt_nbs_page page WITH(NOLOCK)
INNER JOIN [dbo].nrt_odse_NBS_ui_metadata ui_meta WITH(NOLOCK) 
	ON ui_meta.INVESTIGATION_FORM_CD = page.FORM_CD
INNER JOIN [dbo].nrt_odse_NBS_rdb_metadata rdb_meta with (nolock)
    ON ui_meta.NBS_UI_METADATA_UID = rdb_meta.NBS_UI_METADATA_UID
WHERE 
	QUESTION_GROUP_SEQ_NBR IS NOT NULL --Difference between D_INV and D_INV_REPEAT
	AND rdb_meta.USER_DEFINED_COLUMN_NM <> ''
	AND rdb_meta.USER_DEFINED_COLUMN_NM IS NOT NULL;