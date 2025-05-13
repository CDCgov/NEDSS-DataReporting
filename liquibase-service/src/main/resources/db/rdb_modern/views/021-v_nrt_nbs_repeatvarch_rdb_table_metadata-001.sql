create or alter  view dbo.v_nrt_nbs_repeatvarch_rdb_table_metadata as
SELECT
page.FORM_CD,
    page.DATAMART_NM,
	rdb_meta.RDB_TABLE_NM,
    rdb_meta.RDB_COLUMN_NM,
    rdb_meta.USER_DEFINED_COLUMN_NM,
    rdb_meta.BLOCK_PIVOT_NBR,
    ui_meta.INVESTIGATION_FORM_CD,
    ui_meta.BLOCK_NM ,
    OTHER_VALUE_IND_CD,
    COALESCE(rdb_meta.RDB_COLUMN_NM,',' ,'')  + ', '+ coalesce(rdb_meta.USER_DEFINED_COLUMN_NM ,'') as rdb_column_nm_list,
    data_type,
    code_set_group_id
FROM
    dbo.v_nrt_nbs_page page with (nolock)
INNER JOIN NBS_ODSE..NBS_UI_METADATA ui_meta on ui_meta.INVESTIGATION_FORM_CD = page.FORM_CD
INNER JOIN NBS_ODSE..NBS_RDB_METADATA rdb_meta ON  rdb_meta.NBS_UI_METADATA_UID =ui_meta.NBS_UI_METADATA_UID
WHERE
rdb_meta.USER_DEFINED_COLUMN_NM <> '' and rdb_meta.USER_DEFINED_COLUMN_NM IS NOT NULL
AND rdb_meta.RDB_TABLE_NM ='D_INVESTIGATION_REPEAT'
and (code_set_group_id >0
OR data_type in ( 'Coded' ,'Text','text','TEXT','CODED') )
;
