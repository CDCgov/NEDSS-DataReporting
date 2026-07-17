IF IS_SRVROLEMEMBER('sysadmin') <> 1
    BEGIN
        THROW 50000,
        'This bootstrap script must be run by a SQL Server sysadmin. Please rerun it using an account with sysadmin permissions.',
        1;
    END
GO

-- Enable Snapshot Isolation for NBS_ODSE for
-- Debezium Seeding
-- ------------------------------------------
ALTER DATABASE NBS_ODSE
SET ALLOW_SNAPSHOT_ISOLATION ON;

-- ------------------------------------------
-- 1. Enable CDC at Database Level - NBS_ODSE
-- ------------------------------------------
IF (
    SELECT IS_CDC_ENABLED FROM SYS.DATABASES
    WHERE NAME = 'NBS_ODSE'
) = 0
    BEGIN
        -- for aws
        IF
            EXISTS (
                SELECT 1 FROM SYS.DATABASES
                WHERE NAME = 'rdsadmin'
            )
            BEGIN
                PRINT 'AWS RDS detected. Enabling CDC for NBS_ODSE using rds_cdc_enable_db';
                EXEC MSDB.DBO.RDS_CDC_ENABLE_DB 'NBS_ODSE';
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
USE NBS_ODSE;
GO

DECLARE @odseTablesToEnable TABLE (TABLENAME NVARCHAR(128));

INSERT INTO @odseTablesToEnable (TABLENAME)
SELECT TABLENAME
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
) AS NEWROWS (TABLENAME)
EXCEPT
SELECT NAME
FROM SYS.TABLES
WHERE IS_TRACKED_BY_CDC = 1;

DECLARE @odseTableName NVARCHAR(128);
DECLARE ODSECUR CURSOR FOR SELECT TABLENAME FROM @odseTablesToEnable;

OPEN ODSECUR;
FETCH NEXT FROM ODSECUR INTO @odseTableName;

WHILE @@FETCH_STATUS = 0
    BEGIN
        PRINT 'Enabling CDC for table: ' + @odseTableName;
        BEGIN TRY
            EXEC SYS.SP_CDC_ENABLE_TABLE
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

        FETCH NEXT FROM ODSECUR INTO @odseTableName;
    END

CLOSE ODSECUR;
DEALLOCATE ODSECUR;
GO

-- ------------------------------------------
-- 3. Enable CDC at Database Level - NBS_SRTE
-- ------------------------------------------
IF (
    SELECT IS_CDC_ENABLED FROM SYS.DATABASES
    WHERE NAME = 'NBS_SRTE'
) = 0
    BEGIN
        -- for aws
        IF
            EXISTS (
                SELECT 1 FROM SYS.DATABASES
                WHERE NAME = 'rdsadmin'
            )
            BEGIN
                PRINT 'AWS RDS detected. Enabling CDC for NBS_SRTE using rds_cdc_enable_db';
                EXEC MSDB.DBO.RDS_CDC_ENABLE_DB 'NBS_SRTE';
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
USE NBS_SRTE;
GO

DECLARE @srteTablesToEnable TABLE (TABLENAME NVARCHAR(128));

INSERT INTO @srteTablesToEnable (TABLENAME)
SELECT TABLENAME
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
) AS NEWROWS (TABLENAME)
EXCEPT
SELECT NAME
FROM SYS.TABLES
WHERE IS_TRACKED_BY_CDC = 1;

DECLARE @srteTableName NVARCHAR(128);
DECLARE SRTECUR CURSOR FOR SELECT TABLENAME FROM @srteTablesToEnable;

OPEN SRTECUR;
FETCH NEXT FROM SRTECUR INTO @srteTableName;

WHILE @@FETCH_STATUS = 0
    BEGIN
        PRINT 'Enabling CDC for table: ' + @srteTableName;
        BEGIN TRY
            EXEC SYS.SP_CDC_ENABLE_TABLE
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

        FETCH NEXT FROM SRTECUR INTO @srteTableName;
    END

CLOSE SRTECUR;
DEALLOCATE SRTECUR;
GO
