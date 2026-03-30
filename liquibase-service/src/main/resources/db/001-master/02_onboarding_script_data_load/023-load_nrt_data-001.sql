use master;

-- Based on configuration, set @RDB_DB to either rdb_modern or rdb
DECLARE @RDB_DB NVARCHAR(128) = 'rdb';
IF EXISTS(SELECT 1 FROM NBS_ODSE.DBO.NBS_configuration WHERE config_key ='ENV' AND config_value ='UAT')
    BEGIN
        SET @RDB_DB = 'rdb_modern';
    END
PRINT 'Using database ' + @RDB_DB + ' in 023-load_nrt_data-001.sql';

-- Because the table is now variable, we need to build the string dynamically.
DECLARE @NRTTable NVARCHAR(256);

SET @NRTTable = @RDB_DB + '.dbo.nrt_organization';
exec sp_populate_nrt
    @ODSETable         = 'Organization',
    @ODSEUidColumn     = 'organization_uid',
    @SetStatement      = 'SET t.last_chg_time = COALESCE(DATEADD(millisecond, 2, t.last_chg_time), GETDATE())',
    @BatchSize         = '1000',
    @NRTTable          = @NRTTable,
    @NRTUIDColumn      = 'organization_uid';

SET @NRTTable = '(select patient_uid as person_uid from ' + @RDB_DB + '.dbo.nrt_patient UNION ALL select provider_uid as person_uid from ' + @RDB_DB + '.dbo.nrt_provider)';
exec sp_populate_nrt
    @ODSETable         = 'Person',
    @ODSEUidColumn     = 'person_uid',
    @SetStatement      = 'SET t.last_chg_time = COALESCE(DATEADD(millisecond, 2, t.last_chg_time), GETDATE())',
    @BatchSize         = '1000',
    @NRTTable          = @NRTTable,
    @NRTUIDColumn      = 'person_uid';

SET @NRTTable = @RDB_DB + '.dbo.nrt_observation';
exec sp_populate_nrt
    @ODSETable         = 'Observation',
    @ODSEUidColumn     = 'observation_uid',
    @SetStatement      = 'SET t.last_chg_time = COALESCE(DATEADD(millisecond, 2, t.last_chg_time), GETDATE())',
    @BatchSize         = '1000',
    @NRTTable          = @NRTTable,
    @NRTUIDColumn      = 'observation_uid';

SET @NRTTable = @RDB_DB + '.dbo.nrt_investigation';
exec sp_populate_nrt
    @ODSETable         = 'Public_health_case',
    @ODSEUidColumn     = 'public_health_case_uid',
    @SetStatement      = 'SET t.last_chg_time = COALESCE(DATEADD(millisecond, 2, t.last_chg_time), GETDATE())',
    @BatchSize         = '1000',
    @NRTTable          = @NRTTable,
    @NRTUIDColumn      = 'public_health_case_uid';

SET @NRTTable = @RDB_DB + '.dbo.nrt_interview';
exec sp_populate_nrt
    @ODSETable         = 'Interview',
    @ODSEUidColumn     = 'interview_uid',
    @SetStatement      = 'SET t.last_chg_time = COALESCE(DATEADD(millisecond, 2, t.last_chg_time), GETDATE())',
    @BatchSize         = '1000',
    @NRTTable          = @NRTTable,
    @NRTUIDColumn      = 'interview_uid';

SET @NRTTable = @RDB_DB + '.dbo.nrt_auth_user';
exec sp_populate_nrt
    @ODSETable         = 'Auth_user',
    @ODSEUidColumn     = 'auth_user_uid',
    @SetStatement      = 'SET t.last_chg_time = COALESCE(DATEADD(millisecond, 2, t.last_chg_time), GETDATE())',
    @BatchSize         = '1000',
    @NRTTable          = @NRTTable,
    @NRTUIDColumn      = 'auth_user_uid';

SET @NRTTable = @RDB_DB + '.dbo.nrt_place';
exec sp_populate_nrt
    @ODSETable         = 'Place',
    @ODSEUidColumn     = 'place_uid',
    @SetStatement      = 'SET t.last_chg_time = COALESCE(DATEADD(millisecond, 2, t.last_chg_time), GETDATE())',
    @BatchSize         = '1000',
    @NRTTable          = @NRTTable,
    @NRTUIDColumn      = 'place_uid';

SET @NRTTable = @RDB_DB + '.dbo.nrt_treatment';
exec sp_populate_nrt
    @ODSETable         = 'Treatment',
    @ODSEUidColumn     = 'treatment_uid',
    @SetStatement      = 'SET t.last_chg_time = COALESCE(DATEADD(millisecond, 2, t.last_chg_time), t.last_chg_time, GETDATE())',
    @BatchSize         = '1000',
    @NRTTable          = @NRTTable,
    @NRTUIDColumn      = 'treatment_uid';

SET @NRTTable = @RDB_DB + '.dbo.nrt_investigation_notification';
exec sp_populate_nrt
    @ODSETable         = 'Notification',
    @ODSEUidColumn     = 'notification_uid',
    @SetStatement      = 'SET t.last_chg_time = COALESCE(DATEADD(millisecond, 2, t.last_chg_time), GETDATE())',
    @BatchSize         = '1000',
    @NRTTable          = @NRTTable,
    @NRTUIDColumn      = 'notification_uid';

SET @NRTTable = @RDB_DB + '.dbo.nrt_vaccination';
exec sp_populate_nrt
    @ODSETable         = 'Intervention',
    @ODSEUidColumn     = 'intervention_uid',
    @SetStatement      = 'SET t.last_chg_time = COALESCE(DATEADD(millisecond, 2, t.last_chg_time), GETDATE())',
    @BatchSize         = '1000',
    @NRTTable          = @NRTTable,
    @NRTUIDColumn      = 'vaccination_uid';

SET @NRTTable = @RDB_DB + '.dbo.nrt_contact';
exec sp_populate_nrt
    @ODSETable         = 'CT_contact',
    @ODSEUidColumn     = 'ct_contact_uid',
    @SetStatement      = 'SET t.last_chg_time = COALESCE(DATEADD(millisecond, 2, t.last_chg_time), GETDATE())',
    @BatchSize         = '1000',
    @NRTTable          = @NRTTable,
    @NRTUIDColumn      = 'contact_uid';

/*
For loading nrt_ldf_data, it is necessary to use multiple key columns,
as uniqueness is determined by both ldf_uid and business_object_uid.
So, sp_populate_nrt_multikey is used.
 */
SET @NRTTable = @RDB_DB + '.dbo.nrt_ldf_data';
exec sp_populate_nrt_multikey
    @ODSETable         = 'state_defined_field_data',
    @Key1              = 'ldf_uid',
    @Key2              = 'business_object_uid',
    @SetStatement      = 'SET t.last_chg_time = COALESCE(DATEADD(millisecond, 2, t.last_chg_time), GETDATE())',
    @BatchSize         = '1000',
    @NRTTable          = @NRTTable,
    @NRTKey1           = 'ldf_uid',
    @NRTKey2           = 'business_object_uid';

/*
Once all of the above stored procedure calls have been executed successfully,
redeploy the Person, Investigation, and Organization services with the feature flag
phc-datamart-disable set to false.

Additionally, redeploy the postprocessing service with the feature flag service-disable
set to false.
 */