CREATE OR ALTER VIEW dbo.v_nrt_d_inv_repeat_blockdata AS
SELECT
	BLOCK_NM,
	RDB_COLUMN_NM,
	USER_DEFINED_COLUMN_NM,
	INVESTIGATION_FORM_CD
FROM
	[dbo].v_nrt_odse_NBS_rdb_metadata_recent rdb_meta WITH(NOLOCK)
INNER JOIN [dbo].nrt_odse_NBS_ui_metadata ui_meta
	ON rdb_meta.NBS_UI_METADATA_UID = ui_meta.NBS_UI_METADATA_UID
WHERE
	BLOCK_NM IS NOT NULL
	AND USER_DEFINED_COLUMN_NM != ''
	AND USER_DEFINED_COLUMN_NM IS NOT NULL
	AND RDB_TABLE_NM = 'D_INVESTIGATION_REPEAT'
	AND (code_set_group_id > 0 OR data_type in ( 'Coded' , 'Text', 'text', 'TEXT', 'CODED'));