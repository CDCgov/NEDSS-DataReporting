IF EXISTS(SELECT * FROM sys.views WHERE name = 'v_nrt_nbs_repeatnumeric_rdb_table_metadata')
BEGIN
    DROP VIEW [dbo].v_nrt_nbs_repeatnumeric_rdb_table_metadata
END
--GO   "GO" not supported by liquibase, keep in manual scripts

CREATE VIEW [dbo].v_nrt_nbs_repeatnumeric_rdb_table_metadata 
AS
SELECT
    page.FORM_CD,
    page.DATAMART_NM,
    rdb_meta.RDB_TABLE_NM,
    rdb_meta.RDB_COLUMN_NM,
    rdb_meta.USER_DEFINED_COLUMN_NM,
    rdb_meta.BLOCK_PIVOT_NBR,
    ui_meta.INVESTIGATION_FORM_CD,
    ui_meta.BLOCK_NM,
    OTHER_VALUE_IND_CD,
    UNIT_TYPE_CD,
    MASK,
    COALESCE(rdb_meta.RDB_COLUMN_NM,',' ,'') + ', '+ COALESCE(rdb_meta.USER_DEFINED_COLUMN_NM ,'') AS rdb_column_nm_list,
    data_type,
    code_set_group_id
FROM [dbo].v_nrt_nbs_page page WITH(NOLOCK)
INNER JOIN [dbo].nrt_odse_NBS_ui_metadata ui_meta WITH(NOLOCK)
    ON ui_meta.INVESTIGATION_FORM_CD = page.FORM_CD
INNER JOIN [dbo].v_nrt_odse_NBS_rdb_metadata_recent rdb_meta WITH(NOLOCK)
    ON rdb_meta.NBS_UI_METADATA_UID = ui_meta.NBS_UI_METADATA_UID
WHERE
  rdb_meta.USER_DEFINED_COLUMN_NM <> '' 
  AND rdb_meta.USER_DEFINED_COLUMN_NM IS NOT NULL
  AND rdb_meta.RDB_TABLE_NM = 'D_INVESTIGATION_REPEAT'
  AND (code_set_group_id < 0 OR code_set_group_id IS NULL OR data_type in ('Numeric','NUMERIC'));