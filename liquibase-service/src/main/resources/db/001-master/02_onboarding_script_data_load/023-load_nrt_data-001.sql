exec dbo.sp_populate_nrt
    @ODSETable         = 'Organization',
    @ODSEUidColumn     = 'organization_uid',
    @SetStatement      = 'SET t.last_chg_time = COALESCE(DATEADD(millisecond, 2, t.last_chg_time), GETDATE())',
    @BatchSize         = '1000',
    @NRTTable          = 'dbo.nrt_organization',
    @NRTUIDColumn      = 'organization_uid';

exec dbo.sp_populate_nrt
    @ODSETable         = 'Person',
    @ODSEUidColumn     = 'person_uid',
    @SetStatement      = 'SET t.last_chg_time = COALESCE(DATEADD(millisecond, 2, t.last_chg_time), GETDATE())',
    @BatchSize         = '1000',
    @NRTTable          = '(select patient_uid as person_uid from dbo.nrt_patient UNION ALL select provider_uid as person_uid from dbo.nrt_provider)',
    @NRTUIDColumn      = 'person_uid';

exec dbo.sp_populate_nrt
    @ODSETable         = 'Observation',
    @ODSEUidColumn     = 'observation_uid',
    @SetStatement      = 'SET t.last_chg_time = COALESCE(DATEADD(millisecond, 2, t.last_chg_time), GETDATE())',
    @BatchSize         = '1000',
    @NRTTable          = 'dbo.nrt_observation',
    @NRTUIDColumn      = 'observation_uid';

exec dbo.sp_populate_nrt
    @ODSETable         = 'Public_health_case',
    @ODSEUidColumn     = 'public_health_case_uid',
    @SetStatement      = 'SET t.last_chg_time = COALESCE(DATEADD(millisecond, 2, t.last_chg_time), GETDATE())',
    @BatchSize         = '1000',
    @NRTTable          = 'dbo.nrt_investigation',
    @NRTUIDColumn      = 'public_health_case_uid';

exec dbo.sp_populate_nrt
    @ODSETable         = 'Interview',
    @ODSEUidColumn     = 'interview_uid',
    @SetStatement      = 'SET t.last_chg_time = COALESCE(DATEADD(millisecond, 2, t.last_chg_time), GETDATE())',
    @BatchSize         = '1000',
    @NRTTable          = 'dbo.nrt_interview',
    @NRTUIDColumn      = 'interview_uid';


exec dbo.sp_populate_nrt
    @ODSETable         = 'Auth_user',
    @ODSEUidColumn     = 'auth_user_uid',
    @SetStatement      = 'SET t.last_chg_time = COALESCE(DATEADD(millisecond, 2, t.last_chg_time), GETDATE())',
    @BatchSize         = '1000',
    @NRTTable          = 'dbo.nrt_auth_user',
    @NRTUIDColumn      = 'auth_user_uid';


exec dbo.sp_populate_nrt
    @ODSETable         = 'Place',
    @ODSEUidColumn     = 'place_uid',
    @SetStatement      = 'SET t.last_chg_time = COALESCE(DATEADD(millisecond, 2, t.last_chg_time), GETDATE())',
    @BatchSize         = '1000',
    @NRTTable          = 'dbo.nrt_place',
    @NRTUIDColumn      = 'place_uid';

exec dbo.sp_populate_nrt
    @ODSETable         = 'Treatment',
    @ODSEUidColumn     = 'treatment_uid',
    @SetStatement      = 'SET t.last_chg_time = COALESCE(DATEADD(millisecond, 2, t.last_chg_time), t.last_chg_time, GETDATE())',
    @BatchSize         = '1000',
    @NRTTable          = 'dbo.nrt_treatment',
    @NRTUIDColumn      = 'treatment_uid';


exec dbo.sp_populate_nrt
    @ODSETable         = 'Notification',
    @ODSEUidColumn     = 'notification_uid',
    @SetStatement      = 'SET t.last_chg_time = COALESCE(DATEADD(millisecond, 2, t.last_chg_time), GETDATE())',
    @BatchSize         = '1000',
    @NRTTable          = 'dbo.nrt_investigation_notification',
    @NRTUIDColumn      = 'notification_uid';


exec dbo.sp_populate_nrt
    @ODSETable         = 'Intervention',
    @ODSEUidColumn     = 'intervention_uid',
    @SetStatement      = 'SET t.last_chg_time = COALESCE(DATEADD(millisecond, 2, t.last_chg_time), GETDATE())',
    @BatchSize         = '1000',
    @NRTTable          = 'dbo.nrt_vaccination',
    @NRTUIDColumn      = 'vaccination_uid';

exec dbo.sp_populate_nrt
    @ODSETable         = 'CT_contact',
    @ODSEUidColumn     = 'ct_contact_uid',
    @SetStatement      = 'SET t.last_chg_time = COALESCE(DATEADD(millisecond, 2, t.last_chg_time), GETDATE())',
    @BatchSize         = '1000',
    @NRTTable          = 'dbo.nrt_contact',
    @NRTUIDColumn      = 'contact_uid';

/*
    For loading nrt_ldf_data, it is necessary to use multiple key columns,
    as uniqueness is determined by both ldf_uid and business_object_uid.
    So, sp_populate_nrt_multikey is used.
*/
exec dbo.sp_populate_nrt_multikey
    @ODSETable         = 'state_defined_field_data',
    @Key1              = 'ldf_uid',
    @Key2              = 'business_object_uid',
    @SetStatement      = 'SET t.last_chg_time = COALESCE(DATEADD(millisecond, 2, t.last_chg_time), GETDATE())',
    @BatchSize         = '1000',
    @NRTTable          = 'dbo.nrt_ldf_data',
    @NRTKey1           = 'ldf_uid',
    @NRTKey2           = 'business_object_uid';

/*
    Once all of the above stored procedure calls have been executed successfully,
    redeploy the Person, Investigation, and Organization services with the feature flag
    phc-datamart-disable set to false.

    Additionally, redeploy the postprocessing service with the feature flag service-disable
    set to false.
*/