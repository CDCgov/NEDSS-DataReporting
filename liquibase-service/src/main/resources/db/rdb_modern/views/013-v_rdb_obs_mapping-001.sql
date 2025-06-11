IF EXISTS(SELECT * FROM sys.views WHERE name = 'v_rdb_obs_mapping')
BEGIN
    DROP VIEW [dbo].v_rdb_obs_mapping
END;
--GO   --"GO" not supported by liquibase, keep "GO" in manual scripts

/*
    CNDE-2531:
    Added CROSS JOIN with two dummy rows. This allows for a code to ALWAYS be represented alongside a null PHC_UID.
    This is important for ensuring that when a selection is removed from the UI, it is properly represented and set
    to null in the target table.
    Reasoning:
        If an answer with a certain code is removed from only one investigation,
        but that answer exists for another investigation, the changed investigation won't have that attribute set to null.
        This is because there wouldn't be a record with NULL for that code in v_rdb_obs_mapping.
        Adding the cross join ensures that there is always a record in v_rdb_obs_mapping that is just the information from IMRDBMapping without any observation data.
        The process is basically duplicate every row in the IMRDBMapping, join the observation data onto the duplicated rows only (n = 2),
        then keep only the records with n=1 (the original rows from IMRDBMapping with, deliberately not containing any observation data) or
        records that have a non-null PHC_uid (which would indicate that there are observations for the given code)
        the n=1 filter is there to keep only one record for a code in the scenario that no data exists for that code.
*/

CREATE VIEW [dbo].v_rdb_obs_mapping
AS
WITH imrdb AS (
    SELECT
        RDB_table,
        unique_cd,
        RDB_attribute,
        db_field,
        r.n 
    FROM [dbo].nrt_srte_IMRDBMapping WITH (NOLOCk)
    CROSS JOIN (SELECT 1 AS n UNION ALL SELECT 2) r
) 
SELECT  
    imrdb.RDB_table,
    imrdb.unique_cd,
    imrdb.RDB_attribute AS col_nm,
    imrdb.db_field,
    COALESCE(ovc.public_health_case_uid, ovn.public_health_case_uid, ovt.public_health_case_uid, ovd.public_health_case_uid) AS public_health_case_uid,
    COALESCE(ovc.observation_id, ovn.observation_id, ovt.observation_id, ovd.observation_id) AS root_observation_uid,
    COALESCE(ovc.branch_id, ovn.branch_id, ovt.branch_id, ovd.branch_id) AS branch_id,
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
FROM imrdb
LEFT JOIN [dbo].v_getobscode ovc WITH (NOLOCk)
    ON imrdb.unique_cd = ovc.cd AND imrdb.n = 2
LEFT JOIN [dbo].v_getobsnum ovn WITH (NOLOCk)
    ON imrdb.unique_cd = ovn.cd AND imrdb.n = 2
LEFT JOIN [dbo].v_getobstxt ovt WITH (NOLOCk)
    ON imrdb.unique_cd = ovt.cd AND imrdb.n = 2
LEFT JOIN [dbo].v_getobsdate ovd WITH (NOLOCk)
    ON imrdb.unique_cd = ovd.cd AND imrdb.n = 2
WHERE (
    imrdb.n = 1 
    OR COALESCE(ovc.public_health_case_uid, ovn.public_health_case_uid, ovt.public_health_case_uid, ovd.public_health_case_uid) IS NOT NULL
);