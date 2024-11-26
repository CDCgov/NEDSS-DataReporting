CREATE OR ALTER VIEW dbo.v_getobsdate
AS
SELECT
    tnio.public_health_case_uid
     ,tnio.observation_id
     ,tnio.branch_id
     ,tnio.branch_type_cd
     ,o.cd
     ,ovd.ovd_from_date as response
FROM
    dbo.nrt_investigation_observation tnio with (nolock)
        LEFT JOIN dbo.nrt_observation o with (nolock) ON o.observation_uid = tnio.branch_id
        LEFT JOIN dbo.nrt_observation_date ovd with (nolock) ON ovd.observation_uid = o.observation_uid
WHERE tnio.branch_type_cd = 'InvFrmQ' --AND ovd.obs_value_date_seq = 1;
;