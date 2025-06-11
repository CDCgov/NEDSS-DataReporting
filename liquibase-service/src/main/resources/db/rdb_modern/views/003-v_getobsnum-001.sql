IF EXISTS(SELECT * FROM sys.views WHERE name = 'v_getobsnum')
BEGIN
    DROP VIEW [dbo].v_getobsnum
END
--GO   "GO" not supported by liquibase, keep "GO" in manual scripts

CREATE VIEW [dbo].v_getobsnum
AS
SELECT
    tnio.public_health_case_uid
    ,tnio.observation_id
    ,tnio.branch_id
    ,tnio.branch_type_cd
    ,o.cd
    ,ovn.ovn_numeric_value_1 AS response
FROM [dbo].nrt_investigation_observation tnio WITH (NOLOCK)
INNER JOIN [dbo].nrt_investigation inv WITH (NOLOCK) 
    ON tnio.public_health_case_uid = inv.public_health_case_uid 
    AND ISNULL(tnio.batch_id, 1) = ISNULL(inv.batch_id, 1)
LEFT JOIN [dbo].nrt_observation o WITH (NOLOCK) 
    ON o.observation_uid = tnio.branch_id
LEFT JOIN [dbo].nrt_observation_numeric ovn WITH (NOLOCK) 
    ON ovn.observation_uid = o.observation_uid 
    AND ISNULL(o.batch_id,1) = ISNULL(ovn.batch_id,1)
WHERE tnio.branch_type_cd = 'InvFrmQ' AND ovn.ovn_seq = 1;