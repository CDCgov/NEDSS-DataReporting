CREATE OR ALTER VIEW dbo.v_nrt_d_inv_repeat_metadata AS
    SELECT DISTINCT NBS_UI_METADATA.INVESTIGATION_FORM_CD
                  , page.FORM_CD
                  , page.DATAMART_NM
                  , NBS_RDB_METADATA.RDB_TABLE_NM
                  , NBS_RDB_METADATA.RDB_COLUMN_NM
                  , NBS_RDB_METADATA.USER_DEFINED_COLUMN_NM
                  , OTHER_VALUE_IND_CD
                  , data_type
                  , CODE_SET_GROUP_ID
                  , mask
                  , UNIT_TYPE_CD
                  , BLOCK_NM
                  , BLOCK_PIVOT_NBR
                  , PART_TYPE_CD
                  , QUESTION_GROUP_SEQ_NBR
    FROM dbo.v_nrt_nbs_page page with (nolock)
             INNER JOIN NBS_ODSE..NBS_UI_METADATA with (nolock) ON NBS_UI_METADATA.INVESTIGATION_FORM_CD = page.FORM_CD
             INNER JOIN NBS_ODSE..NBS_RDB_METADATA with (nolock)
                        ON NBS_UI_METADATA.NBS_UI_METADATA_UID = NBS_RDB_METADATA.NBS_UI_METADATA_UID
    WHERE QUESTION_GROUP_SEQ_NBR IS NOT NULL --Difference between D_INV and D_INV_REPEAT
      AND NBS_RDB_METADATA.USER_DEFINED_COLUMN_NM <> ''
      and NBS_RDB_METADATA.USER_DEFINED_COLUMN_NM IS NOT NULL;