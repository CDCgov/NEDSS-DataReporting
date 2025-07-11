
IF EXISTS(SELECT * FROM sys.views WHERE name = 'v_getobscode')
BEGIN
    DROP VIEW [dbo].v_getobscode
END
GO

CREATE VIEW [dbo].v_getobscode
AS
WITH InvFormQObservations AS (
    SELECT
        tnio.public_health_case_uid
        ,observation_id
        ,branch_id
        ,branch_type_cd
        ,ovc.ovc_code
        ,o.cd
        ,CASE 
            WHEN o.cd IN ('CRS009','CRS162','DEM124','DEM130','DEM162','DMH124',
                            'DMH130','DMH162','INV117','INV154','LOC318','LOC721',
                            'NPH120','NPP021','ORD113')                             THEN 'state'
            WHEN o.cd IN ('CRS163','DEM125','DEM131','DEM165','DMH125','DMH131',
                            'DMH165','INV119','INV156','INV187','LOC309','LOC712',
                            'NOT111','NPH122','NPP023','ORD115','PHC144','SUM100')  THEN 'county'
            WHEN o.cd IN ('INV153','BMD276', 'CRS080','CRS098','CRS164','CRS165',
                            'DEM126','DEM132','DEM167','HEP140','HEP142','HEP242',
                            'HEP255','NPP024','ORD116','RUB146')                    THEN 'country'
            WHEN o.cd IN ('INV107','GEO100','LAB168','MRB137','OBS1017','PHC127')   THEN 'jurcode'
            WHEN o.cd IN ('HEP128','INV169','MRB121','PHC108','SUM106')             THEN 'DISEASE'
            ELSE 'cvg_code' 
        END AS label
    FROM [dbo].nrt_investigation_observation tnio WITH (NOLOCK)
    INNER JOIN [dbo].nrt_investigation inv WITH (NOLOCK) 
        ON tnio.public_health_case_uid = inv.public_health_case_uid 
        AND ISNULL(tnio.batch_id, 1) = ISNULL(inv.batch_id, 1)
    INNER JOIN [dbo].nrt_observation_coded ovc WITH (NOLOCK) 
        ON ovc.observation_uid = tnio.branch_id
    INNER JOIN [dbo].nrt_observation o WITH (NOLOCK) 
        ON o.observation_uid = ovc.observation_uid 
        AND ISNULL(o.batch_id,1) = ISNULL(ovc.batch_id,1)
    WHERE branch_type_cd = 'InvFrmQ'
)
SELECT
    obs.public_health_case_uid
    ,obs.observation_id
    ,obs.branch_id
    ,obs.branch_type_cd
    ,obs.cd
    ,obs.ovc_code as obs_ovc_code
    ,CASE
        WHEN obs.ovc_code = 'NI' THEN 'No Input'
        WHEN label = 'cvg_code' THEN cvg.code_short_desc_txt
        WHEN label = 'country' THEN cc.code_short_desc_txt
        WHEN label = 'state' THEN sc.state_nm
        WHEN label = 'county' THEN sccv.code_desc_txt
        WHEN label = 'jurcode' THEN jc.code_short_desc_txt
        WHEN label = 'DISEASE' THEN con_code.condition_short_nm
        ELSE NULL
    END AS response
    ,CASE
        WHEN label = 'country' THEN cc.code
        WHEN label = 'state' THEN sc.state_cd
        WHEN label = 'county' THEN sccv.code
        WHEN label = 'jurcode' THEN jc.code
        ELSE NULL
    END AS response_cd,
    label
FROM InvFormQObservations obs
LEFT JOIN [dbo].v_codeset cs WITH (NOLOCK) 
    ON cs.cd = obs.cd
LEFT JOIN [dbo].nrt_srte_Code_value_general cvg with (nolock)  
    ON cvg.code_set_nm = cs.CODE_SET_NM 
    AND cvg.code = obs.ovc_code
LEFT JOIN [dbo].nrt_srte_Country_code cc WITH (NOLOCK) 
    ON cc.code = obs.ovc_code
LEFT JOIN [dbo].nrt_srte_State_code sc WITH (NOLOCK) 
    ON sc.state_cd = obs.ovc_code
LEFT JOIN [dbo].nrt_srte_State_county_code_value sccv WITH (NOLOCK) 
    ON sccv.code = obs.ovc_code
LEFT JOIN [dbo].nrt_srte_Jurisdiction_code jc WITH (NOLOCK) 
    ON jc.code = obs.ovc_code
LEFT JOIN [dbo].nrt_srte_Condition_code con_code WITH (NOLOCK) 
    ON con_code.condition_cd = obs.ovc_code;


