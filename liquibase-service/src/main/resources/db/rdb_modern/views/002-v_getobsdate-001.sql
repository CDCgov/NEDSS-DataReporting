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
    INNER JOIN dbo.nrt_investigation inv with (nolock) on tnio.public_health_case_uid = inv.public_health_case_uid and ISNULL(tnio.batch_id, 1) = ISNULL(inv.batch_id, 1)
        LEFT JOIN dbo.nrt_observation o with (nolock) ON o.observation_uid = tnio.branch_id
        LEFT JOIN dbo.nrt_observation_date ovd with (nolock) ON ovd.observation_uid = o.observation_uid and ISNULL(o.batch_id,1) = ISNULL(ovd.batch_id,1)
WHERE tnio.branch_type_cd = 'InvFrmQ' AND ovd.ovd_seq = 1;