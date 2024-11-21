CREATE OR ALTER VIEW dbo.v_getobsnum
AS
SELECT
    tnio.public_health_case_uid
     ,tnio.observation_id
     ,tnio.branch_id
     ,tnio.branch_type_cd
     ,o.cd
     ,ovn.ovn_numeric_value_1 as response
FROM
    dbo.nrt_investigation_observation tnio with (nolock)
        LEFT JOIN dbo.nrt_observation o with (nolock) ON o.observation_uid = tnio.branch_id
        LEFT JOIN dbo.nrt_observation_numeric ovn with (nolock) ON ovn.observation_uid = o.observation_uid
        WHERE tnio.branch_type_cd = 'InvFrmQ' --AND ovn.obs_value_numeric_seq = 1;
;