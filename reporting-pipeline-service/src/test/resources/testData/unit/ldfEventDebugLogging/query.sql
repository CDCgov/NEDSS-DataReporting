WITH invocations (procedure_name, debug_logging, entity_id) AS (
    SELECT *
    FROM (VALUES
        ('sp_ldf_data_event',         'off', '99100001'),
        ('sp_ldf_data_event',         'on',  '99100002'),
        ('sp_ldf_data_event',         'off', '99100003'),
        ('sp_ldf_data_event',         'on',  '99100004'),
        ('sp_ldf_data_event',         'off', '99100005'),
        ('sp_ldf_data_event',         'on',  '99100006'),
        ('sp_ldf_data_event',         'off', '99100007'),
        ('sp_ldf_data_event',         'on',  '99100008'),
        ('sp_ldf_data_event',         'off', '99100009'),
        ('sp_ldf_data_event',         'on',  '99100010'),
        ('sp_ldf_data_event',         'off', '99100011'),
        ('sp_ldf_data_event',         'on',  '99100012'),
        ('sp_ldf_patient_event',      'off', '99100001'),
        ('sp_ldf_patient_event',      'on',  '99100002'),
        ('sp_ldf_provider_event',     'off', '99100003'),
        ('sp_ldf_provider_event',     'on',  '99100004'),
        ('sp_ldf_organization_event', 'off', '99100005'),
        ('sp_ldf_organization_event', 'on',  '99100006'),
        ('sp_ldf_observation_event',  'off', '99100007'),
        ('sp_ldf_observation_event',  'on',  '99100008'),
        ('sp_ldf_phc_event',          'off', '99100009'),
        ('sp_ldf_phc_event',          'on',  '99100010'),
        ('sp_ldf_intervention_event', 'off', '99100011'),
        ('sp_ldf_intervention_event', 'on',  '99100012')
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
