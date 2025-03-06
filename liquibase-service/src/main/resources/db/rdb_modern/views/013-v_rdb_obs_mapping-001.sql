/*
    CNDE-2531:
    Added CROSS JOIN with two dummy rows. This allows for a code to ALWAYS be represented alongside a null PHC_UID.
    This is important for ensuring that when a selection is removed from the UI 
*/
CREATE OR ALTER VIEW dbo.v_rdb_obs_mapping
AS
SELECT  imrdb.RDB_table,
        imrdb.unique_cd,
        imrdb.RDB_attribute as col_nm,
        imrdb.db_field,
        COALESCE(ovc.public_health_case_uid, ovn.public_health_case_uid, ovt.public_health_case_uid, ovd.public_health_case_uid) as public_health_case_uid,
        COALESCE(ovc.observation_id, ovn.observation_id, ovt.observation_id, ovd.observation_id) as root_observation_uid,
        COALESCE(ovc.branch_id, ovn.branch_id, ovt.branch_id, ovd.branch_id) as branch_id,
        CASE
            WHEN imrdb.DB_field = 'code' then ovc.response
            ELSE NULL
            END AS coded_response,
        CASE
            WHEN imrdb.DB_field = 'numeric_value_1' then ovn.response
            ELSE NULL
            END AS numeric_response,
        CASE
            WHEN imrdb.DB_field = 'value_txt' then ovt.response
            ELSE NULL
            END AS txt_response,
        CASE
            WHEN imrdb.DB_field = 'from_time' then ovd.response
            ELSE NULL
            END AS date_response,
        ovc.label
FROM (SELECT
        RDB_table,
        unique_cd,
        RDB_attribute,
        db_field,
        r.n 
    FROM nbs_srte.dbo.imrdbmapping
CROSS JOIN (SELECT 1 AS n UNION ALL SELECT 2) r) imrdb
         LEFT JOIN dbo.v_getobscode ovc ON imrdb.unique_cd = ovc.cd and imrdb.n = 2
         LEFT JOIN dbo.v_getobsnum ovn ON imrdb.unique_cd = ovn.cd and imrdb.n = 2
         LEFT JOIN dbo.v_getobstxt ovt ON imrdb.unique_cd = ovt.cd and imrdb.n = 2
         LEFT JOIN dbo.v_getobsdate ovd ON imrdb.unique_cd = ovd.cd and imrdb.n = 2
where (imrdb.n = 1 or COALESCE(ovc.public_health_case_uid, ovn.public_health_case_uid, ovt.public_health_case_uid, ovd.public_health_case_uid) IS NOT NULL);