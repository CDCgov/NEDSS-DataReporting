CREATE  OR ALTER view dbo.v_nrt_nbs_page AS
SELECT DISTINCT 
	page.FORM_CD, 
	page.DATAMART_NM 
FROM [dbo].nrt_odse_Page_cond_mapping pcm WITH(NOLOCK)
inner join [dbo].nrt_odse_NBS_page page WITH(NOLOCK)
	ON pcm.WA_TEMPLATE_UID = page.WA_TEMPLATE_UID
WHERE 
	DATAMART_NM IS NOT NULL 
	AND CONDITION_CD IS NOT NULL;