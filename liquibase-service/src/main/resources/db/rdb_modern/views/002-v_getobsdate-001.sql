IF EXISTS(SELECT * FROM sys.views WHERE name = 'v_getobsdate')
BEGIN
    DROP VIEW [dbo].v_getobsdate
END
--GO   "GO" not supported by liquibase, keep in manual scripts

CREATE VIEW [dbo].v_getobsdate
AS
SELECT
    tnio.public_health_case_uid
    ,tnio.observation_id
    ,tnio.branch_id
    ,tnio.branch_type_cd
    ,o.cd
    ,ovd.ovd_from_date AS response
FROM [dbo].nrt_investigation_observation tnio WITH (NOLOCK)
INNER JOIN [dbo].nrt_investigation inv WITH (NOLOCK) 
    ON tnio.public_health_case_uid = inv.public_health_case_uid 
    AND ISNULL(tnio.batch_id, 1) = ISNULL(inv.batch_id, 1)
LEFT JOIN [dbo].nrt_observation o WITH (NOLOCK) 
    ON o.observation_uid = tnio.branch_id
LEFT JOIN [dbo].nrt_observation_date ovd WITH (NOLOCK) 
    ON ovd.observation_uid = o.observation_uid 
    AND ISNULL(o.batch_id,1) = ISNULL(ovd.batch_id,1)
WHERE tnio.branch_type_cd = 'InvFrmQ' AND ovd.ovd_seq = 1;