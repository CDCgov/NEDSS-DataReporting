CREATE OR ALTER VIEW dbo.v_getobstxt
AS
SELECT
    tnio.public_health_case_uid
     ,tnio.observation_id
     ,tnio.branch_id
     ,tnio.branch_type_cd
     ,o.cd
     ,ovt.ovt_value_txt as response
FROM
    dbo.nrt_investigation_observation tnio with (nolock)
    INNER JOIN dbo.nrt_investigation inv on tnio.public_health_case_uid = inv.public_health_case_uid and ISNULL(tnio.batch_id, 1) = ISNULL(inv.batch_id, 1)
        LEFT JOIN dbo.nrt_observation o with (nolock) ON o.observation_uid = tnio.branch_id
        LEFT JOIN dbo.nrt_observation_txt ovt with (nolock) ON ovt.observation_uid = o.observation_uid 
        AND ISNULL(ovt.batch_id, 1) = ISNULL(o.batch_id, 1)
WHERE tnio.branch_type_cd = 'InvFrmQ' AND ovt.ovt_seq = 1;
