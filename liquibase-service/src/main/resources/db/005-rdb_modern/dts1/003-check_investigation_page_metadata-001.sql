/*
    This file is a DTS1 ONLY Script and should NOT be checked into the Liquibase Changelog
*/

;WITH srte AS (
    SELECT condition_cd, investigation_form_cd, condition_desc_txt
    FROM nbs_srte.dbo.condition_code
),
      odse_mapping AS (
          SELECT DISTINCT pcm.condition_cd, page.DATAMART_NM
          FROM NBS_ODSE..PAGE_COND_MAPPING pcm
                   LEFT JOIN NBS_ODSE.DBO.NBS_PAGE page ON pcm.WA_TEMPLATE_UID = page.WA_TEMPLATE_UID
          WHERE pcm.condition_cd IS NOT NULL
      ),
      rdb_condition AS (
          SELECT condition_cd, disease_grp_cd
          FROM rdb.dbo.condition
      ),
      rdb_ldf AS (
          SELECT condition_cd, DATAMART_NAME, LINKED_FACT_TABLE
          FROM rdb.dbo.LDF_DATAMART_TABLE_REF
      ),
      all_conditions AS (
          SELECT condition_cd FROM srte
          UNION
          SELECT condition_cd FROM odse_mapping
          UNION
          SELECT condition_cd FROM rdb_condition
          UNION
          SELECT condition_cd FROM rdb_ldf
      ),
      combined AS (
          SELECT
              ac.condition_cd,
              s.condition_desc_txt,
              CASE WHEN s.condition_cd IS NOT NULL THEN 'Yes' ELSE 'No' END AS 'In SRTE: Condition Code',
                  s.investigation_form_cd AS 'In SRTE: Investigation_Form_Cd',
                  CASE
                      WHEN om.condition_cd IS NOT NULL AND om.DATAMART_NM IS NOT NULL THEN 'Yes'
                      WHEN om.condition_cd IS NOT NULL AND om.DATAMART_NM IS NULL THEN 'Page Builder Page without Dynamic Datamart'
                      ELSE 'No'
                      END AS 'In ODSE: NBS_Page (Page Builder)',
                  om.DATAMART_NM AS 'In ODSE: NBS_Page Datamart Name',
                  CASE
                      WHEN om.condition_cd IS NOT NULL AND om.DATAMART_NM IS NOT NULL THEN CONCAT('DM_INV_',om.DATAMART_NM)
                      WHEN om.condition_cd IS NOT NULL AND om.DATAMART_NM IS NULL THEN 'Page Builder Page without Dynamic Datamart'
                      ELSE 'No'
                      END AS 'In RDB: Dynamic Datamart (Page Builder)',
                  CASE WHEN rc.condition_cd IS NOT NULL THEN 'Yes' ELSE 'No' END AS 'In RDB: Condition Dimension',
                  rc.disease_grp_cd AS ' RDB Form Cd',
                  CASE WHEN rl.condition_cd IS NOT NULL THEN 'Yes' ELSE 'No' END AS 'In RDB: LDF_DATAMART_TABLE_REF',
                  rl.DATAMART_NAME AS 'In RDB: LDF_DATAMART_TABLE_REF LDF Table',
                  rl.LINKED_FACT_TABLE AS 'In RDB: LDF_DATAMART_TABLE_REF Linked Table',
                  CASE
                      WHEN om.DATAMART_NM IS NOT NULL AND rl.DATAMART_NAME IS NOT NULL THEN 'Legacy Page Migrated. LDF Will not Update'
                      ELSE NULL
                      END AS 'LDF Table Update'
          FROM all_conditions ac
                   LEFT JOIN srte s ON ac.condition_cd = s.condition_cd
                   LEFT JOIN odse_mapping om ON ac.condition_cd = om.condition_cd
                   LEFT JOIN rdb_condition rc ON ac.condition_cd = rc.condition_cd
                   LEFT JOIN rdb_ldf rl ON ac.condition_cd = rl.condition_cd
          where ac.condition_cd IS NOT NULL
      )
 SELECT *
 FROM combined
--WHERE condition_cd = '10010' OR condition_desc_txt like '%Pertussis%'
 ORDER BY condition_cd;