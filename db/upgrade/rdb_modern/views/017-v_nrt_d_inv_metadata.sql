CREATE  OR ALTER VIEW dbo.v_nrt_d_inv_metadata AS
SELECT  DISTINCT NBS_UI_METADATA.INVESTIGATION_FORM_CD,page.FORM_CD, page.DATAMART_NM, NBS_RDB_METADATA.RDB_TABLE_NM, NBS_RDB_METADATA.RDB_COLUMN_NM,NBS_RDB_METADATA.USER_DEFINED_COLUMN_NM  
,OTHER_VALUE_IND_CD,data_type,CODE_SET_GROUP_ID,mask,UNIT_TYPE_CD
	  -- into #tmp_DynDm_D_INV_METADATA
	  FROM dbo.v_nrt_nbs_page page with (nolock) 
	     INNER JOIN NBS_ODSE..NBS_UI_METADATA  with (nolock) ON  NBS_UI_METADATA.INVESTIGATION_FORM_CD = page.FORM_CD
	     INNER JOIN NBS_ODSE..NBS_RDB_METADATA  with (nolock) ON NBS_UI_METADATA.NBS_UI_METADATA_UID = NBS_RDB_METADATA.NBS_UI_METADATA_UID
	WHERE  QUESTION_GROUP_SEQ_NBR IS NULL
	  AND NBS_RDB_METADATA.USER_DEFINED_COLUMN_NM <> '' and NBS_RDB_METADATA.USER_DEFINED_COLUMN_NM IS NOT NULL
	  -- and RDB_TABLE_NM=@RDB_TABLE_NM AND
	  -- and NBS_UI_METADATA.INVESTIGATION_FORM_CD=(SELECT distinct FORM_CD FROM dbo.v_nrt_nbs_page with (nolock) WHERE DATAMART_NM= @DATAMART_NAME )
   ;;