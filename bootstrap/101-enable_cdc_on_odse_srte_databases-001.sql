IF IS_SRVROLEMEMBER('sysadmin') <> 1
    BEGIN
        THROW 50000,
        'This bootstrap script must be run by a SQL Server sysadmin. Please rerun it using an account with sysadmin permissions.',
        1;
    END
GO

-- ------------------------------------------
-- 1. Enable CDC at Database Level - NBS_ODSE
-- ------------------------------------------
IF (
    SELECT is_cdc_enabled FROM sys.databases
    WHERE name = 'NBS_ODSE'
) = 0
    BEGIN
        -- for aws
        IF
            EXISTS (
                SELECT 1 FROM sys.databases
                WHERE name = 'rdsadmin'
            )
            BEGIN
                PRINT 'AWS RDS detected. Enabling CDC for NBS_ODSE using rds_cdc_enable_db';
                EXEC msdb.dbo.rds_cdc_enable_db 'NBS_ODSE';
            END
        ELSE
            BEGIN
                PRINT 'Standard SQL Server detected. Enabling CDC for NBS_ODSE using sp_cdc_enable_db';
                EXEC ('USE [NBS_ODSE]; EXEC sys.sp_cdc_enable_db;');
            END
    END
ELSE
    BEGIN
        PRINT 'CDC is already enabled for NBS_ODSE';
    END
GO

-- ------------------------------------------
-- 2. Enable CDC for Tables - NBS_ODSE
-- ------------------------------------------
USE nbs_odse;
GO

DECLARE @odseTablesToEnable TABLE (tablename NVARCHAR(128));

INSERT INTO @odseTablesToEnable (tablename)
SELECT tablename
FROM (
    VALUES
    ('Act_relationship'),
    ('Auth_user'),
    ('CT_contact'),
    ('Intervention'),
    ('Interview'),
    ('NBS_page'),
    ('NBS_rdb_metadata'),
    ('NBS_ui_metadata'),
    ('Notification'),
    ('Observation'),
    ('Organization'),
    ('Page_cond_mapping'),
    ('Person'),
    ('Place'),
    ('Public_health_case'),
    ('state_defined_field_data'),
    ('State_Defined_Field_Metadata'),
    ('Treatment'),
    ('NBS_configuration'),
    ('LOOKUP_QUESTION')
) AS newrows (tablename)
EXCEPT
SELECT name
FROM sys.tables
WHERE is_tracked_by_cdc = 1;

DECLARE @odseTableName NVARCHAR(128);
DECLARE odseCur CURSOR FOR SELECT tablename FROM @odseTablesToEnable;

OPEN odseCur;
FETCH NEXT FROM odseCur INTO @odseTableName;

WHILE @@FETCH_STATUS = 0
    BEGIN
        PRINT 'Enabling CDC for table: ' + @odseTableName;
        BEGIN TRY
            EXEC sys.sp_cdc_enable_table
                @source_schema = N'dbo',
                @source_name = @odseTableName,
                @role_name = NULL;
        END TRY
        BEGIN CATCH
            PRINT 'ERROR: Could not enable CDC for table '
            + @odseTableName
            + '. Error: '
            + ERROR_MESSAGE();
        END CATCH

        FETCH NEXT FROM odseCur INTO @odseTableName;
    END

CLOSE odseCur;
DEALLOCATE odseCur;
GO

-- ------------------------------------------
-- 3. Enable CDC at Database Level - NBS_SRTE
-- ------------------------------------------
IF (
    SELECT is_cdc_enabled FROM sys.databases
    WHERE name = 'NBS_SRTE'
) = 0
    BEGIN
        -- for aws
        IF
            EXISTS (
                SELECT 1 FROM sys.databases
                WHERE name = 'rdsadmin'
            )
            BEGIN
                PRINT 'AWS RDS detected. Enabling CDC for NBS_SRTE using rds_cdc_enable_db';
                EXEC msdb.dbo.rds_cdc_enable_db 'NBS_SRTE';
            END
        ELSE
            BEGIN
                PRINT 'Standard SQL Server detected. Enabling CDC for NBS_SRTE using sp_cdc_enable_db';
                EXEC ('USE [NBS_SRTE]; EXEC sys.sp_cdc_enable_db;');
            END
    END
ELSE
    BEGIN
        PRINT 'CDC is already enabled for NBS_SRTE';
    END
GO

-- ------------------------------------------
-- 4. Enable CDC for Tables - NBS_SRTE
-- ------------------------------------------
USE nbs_srte;
GO

DECLARE @srteTablesToEnable TABLE (tablename NVARCHAR(128));

INSERT INTO @srteTablesToEnable (tablename)
SELECT tablename
FROM (
    VALUES
    ('Anatomic_site_code'),
    ('City_code_value'),
    ('Cntycity_code_value'),
    ('Code_value_clinical'),
    ('Code_value_general'),
    ('Codeset'),
    ('Codeset_Group_Metadata'),
    ('Condition_code'),
    ('Country_code'),
    ('Country_Code_ISO'),
    ('Country_XREF'),
    ('ELR_XREF'),
    ('IMRDBMapping'),
    ('Investigation_code'),
    ('Jurisdiction_code'),
    ('Jurisdiction_participation'),
    ('Lab_coding_system'),
    ('Lab_result'),
    ('Lab_result_Snomed'),
    ('Lab_test'),
    ('Labtest_loinc'),
    ('Labtest_Progarea_Mapping'),
    ('Language_code'),
    ('LDF_page_set'),
    ('LOINC_code'),
    ('Loinc_condition'),
    ('Loinc_snomed_condition'),
    ('NAICS_Industry_code'),
    ('Occupation_code'),
    ('Participation_type'),
    ('Program_area_code'),
    ('Race_code'),
    ('Snomed_code'),
    ('Specimen_source_code'),
    ('Standard_XREF'),
    ('State_code'),
    ('State_county_code_value'),
    ('State_model'),
    ('TotalIDM'),
    ('Treatment_code'),
    ('Unit_code'),
    ('Zip_code_value'),
    ('Zipcnty_code_value')
) AS newrows (tablename)
EXCEPT
SELECT name
FROM sys.tables
WHERE is_tracked_by_cdc = 1;

DECLARE @srteTableName NVARCHAR(128);
DECLARE srteCur CURSOR FOR SELECT tablename FROM @srteTablesToEnable;

OPEN srteCur;
FETCH NEXT FROM srteCur INTO @srteTableName;

WHILE @@FETCH_STATUS = 0
    BEGIN
        PRINT 'Enabling CDC for table: ' + @srteTableName;
        BEGIN TRY
            EXEC sys.sp_cdc_enable_table
                @source_schema = N'dbo',
                @source_name = @srteTableName,
                @role_name = NULL;
        END TRY
        BEGIN CATCH
            PRINT 'ERROR: Could not enable CDC for table '
            + @srteTableName
            + '. Error: '
            + ERROR_MESSAGE();
        END CATCH

        FETCH NEXT FROM srteCur INTO @srteTableName;
    END

CLOSE srteCur;
DEALLOCATE srteCur;
GO
