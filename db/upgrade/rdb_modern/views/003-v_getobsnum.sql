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
        INNER JOIN dbo.nrt_investigation inv with (nolock) on tnio.public_health_case_uid = inv.public_health_case_uid and ISNULL(tnio.batch_id, 1) = ISNULL(inv.batch_id, 1)
        LEFT JOIN dbo.nrt_observation o with (nolock) ON o.observation_uid = tnio.branch_id
        LEFT JOIN dbo.nrt_observation_numeric ovn with (nolock) ON ovn.observation_uid = o.observation_uid and ISNULL(o.batch_id,1) = ISNULL(ovn.batch_id,1)
        WHERE tnio.branch_type_cd = 'InvFrmQ' AND ovn.ovn_seq = 1;
;