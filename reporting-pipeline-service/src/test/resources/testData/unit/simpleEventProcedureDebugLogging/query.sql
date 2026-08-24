WITH invocations (procedure_name, debug_logging, entity_id) AS (
    SELECT *
    FROM (VALUES
        ('sp_organization_event', 'off', '990000001'),
        ('sp_organization_event', 'on',  '990000002'),
        ('sp_provider_event',     'off', '990000011'),
        ('sp_provider_event',     'on',  '990000012'),
        ('sp_observation_event',  'off', '990000021'),
        ('sp_observation_event',  'on',  '990000022'),
        ('sp_investigation_event','off', '990000031'),
        ('sp_investigation_event','on',  '990000032'),
        ('sp_notification_event', 'off', '990000041'),
        ('sp_notification_event', 'on',  '990000042'),
        ('sp_auth_user_event',    'off', '990000051'),
        ('sp_auth_user_event',    'on',  '990000052'),
        ('sp_place_event',        'off', '990000061'),
        ('sp_place_event',        'on',  '990000062'),
        ('sp_patient_event',       'off', '990000071'),
        ('sp_patient_event',       'on',  '990000072')
    ) configured(procedure_name, debug_logging, entity_id)
)
SELECT
    invocation.procedure_name,
    invocation.debug_logging,
    SUM(CASE WHEN log.Status_Type = 'START' THEN 1 ELSE 0 END) AS start_count,
    SUM(CASE WHEN log.Status_Type = 'COMPLETE' THEN 1 ELSE 0 END) AS complete_count,
    SUM(CASE WHEN log.Status_Type = 'ERROR' THEN 1 ELSE 0 END) AS error_count,
    COUNT(log.Status_Type) AS total_count
FROM invocations invocation
LEFT JOIN dbo.job_flow_log log
    ON log.package_Name = invocation.procedure_name
    AND log.Msg_Description1 = invocation.entity_id
GROUP BY invocation.procedure_name, invocation.debug_logging
ORDER BY invocation.procedure_name, invocation.debug_logging
