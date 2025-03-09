CREATE view dbo.v_nrt_nbs_investigation_rdb_table_metadata as
SELECT  DISTINCT page.FORM_CD, page.DATAMART_NM, rdb_meta.RDB_TABLE_NM,
            rdb_meta.RDB_COLUMN_NM,rdb_meta.USER_DEFINED_COLUMN_NM ,ui_meta.INVESTIGATION_FORM_CD
            ,COALESCE(rdb_meta.RDB_COLUMN_NM,',' ,'')  + ', '+ coalesce(rdb_meta.USER_DEFINED_COLUMN_NM ,'') as rdb_column_nm_list
FROM dbo.v_nrt_nbs_page page -- rdb.dbo.TMP_INIT INIT -- populated in main sp - converted to view
  INNER JOIN NBS_ODSE..NBS_UI_METADATA  ui_meta with ( nolock) ON ui_meta.INVESTIGATION_FORM_CD = page.FORM_CD
  INNER JOIN NBS_ODSE..NBS_RDB_METADATA rdb_meta with ( nolock)  ON ui_meta.NBS_UI_METADATA_UID = rdb_meta.NBS_UI_METADATA_UID
WHERE RDB_TABLE_NM='INVESTIGATION' 
  -- AND NBS_UI_METADATA.INVESTIGATION_FORM_CD=(SELECT FORM_CD FROM rdb.dbo.NBS_PAGE WHERE DATAMART_NM=@DATAMART_NAME)
  AND rdb_meta.USER_DEFINED_COLUMN_NM <> '' and rdb_meta.USER_DEFINED_COLUMN_NM IS NOT NULL;