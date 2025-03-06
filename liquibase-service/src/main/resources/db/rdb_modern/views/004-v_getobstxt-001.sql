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
        LEFT JOIN dbo.nrt_observation o with (nolock) ON o.observation_uid = tnio.branch_id
        LEFT JOIN dbo.nrt_observation_txt ovt with (nolock) ON ovt.observation_uid = o.observation_uid and 
                     CASE WHEN ovt.batch_id IS NOT NULL and o.batch_id = ovt.batch_id then 1
                          WHEN ovt.batch_id IS NULL then 1
                     else 0 end = 1
WHERE tnio.branch_type_cd = 'InvFrmQ' AND ovt.ovt_seq = 1;