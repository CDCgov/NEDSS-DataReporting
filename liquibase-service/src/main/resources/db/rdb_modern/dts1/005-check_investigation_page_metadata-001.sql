/*
    This file is a DTS1 ONLY Script and should NOT be checked into the Liquibase Changelog
*/

;with union_cd as (
SELECT 'SRTE' as db, condition_cd, investigation_form_cd, NULL as DYN_NM, NULL AS LDF_ASSOCIATED, NULL AS 'LEGACY_SOURCE_TABLE'
from nbs_srte.dbo.condition_code d 
UNION
SELECT 'ODSE: Page DYN_NM' as db , pcm.CONDITION_CD, cc.investigation_form_cd, page.DATAMART_NM as DYN_NM, NULL AS LDF_ASSOCIATED, NULL AS 'LEGACY_SOURCE_TABLE'
	FROM NBS_ODSE..PAGE_COND_MAPPING pcm
	   INNER JOIN NBS_ODSE.DBO.NBS_PAGE page	ON pcm.WA_TEMPLATE_UID = page.WA_TEMPLATE_UID
	   LEFT JOIN NBS_SRTE.DBO.CONDITION_CODE  cc on cc.condition_cd = pcm.condition_cd
    WHERE  pcm.CONDITION_CD IS NOT NULL 
    AND DATAMART_NM IS NOT NULL
UNION
select 'RDB: Condition' as db,d.condition_cd, d.DISEASE_GRP_CD investigation_form_cd, NULL as DYN_NM, NULL AS LDF_ASSOCIATED, NULL AS 'LEGACY_SOURCE_TABLE'
from rdb.dbo.condition d
UNION
select 'RDB: LDF' as db,d.condition_cd, NULL investigation_form_cd, NULL as DYN_NM, DATAMART_NAME AS LDF_ASSOCIATED, LINKED_FACT_TABLE AS 'LEGACY_SOURCE_TABLE'
from rdb.dbo.LDF_DATAMART_TABLE_REF d
)
select *
from union_cd
--where condition_cd IN ('10200','10370')
where condition_cd IN ('10101')
ORDER BY condition_cd, db;