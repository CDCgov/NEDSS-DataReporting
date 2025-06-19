IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_treatment' and xtype = 'U')
CREATE TABLE dbo.nrt_treatment
(
    treatment_uid                  varchar(100)                                    NOT NULL,
    organization_uid               varchar(100)                                    NULL,
    provider_uid                   varchar(100)                                    NULL,
    patient_treatment_uid          varchar(100)                                    NULL,
    morbidity_uid                  varchar(100)                                    NULL,
    treatment_name                 varchar(500)                                    NULL,
    treatment_oid                  varchar(100)                                    NULL,
    treatment_comments             varchar(500)                                    NULL,
    treatment_shared_ind           varchar(100)                                    NULL,
    cd                             varchar(100)                                    NULL,
    treatment_date                 datetime                                        NULL,
    treatment_drug                 varchar(100)                                    NULL,
    treatment_drug_name            varchar(500)                                    NULL,
    treatment_dosage_strength      varchar(100)                                    NULL,
    treatment_dosage_strength_unit varchar(100)                                    NULL,
    treatment_frequency            varchar(100)                                    NULL,
    treatment_duration             varchar(100)                                    NULL,
    treatment_duration_unit        varchar(100)                                    NULL,
    treatment_route                varchar(100)                                    NULL,
    local_id                       varchar(100)                                    NULL,
    record_status_cd               varchar(100)                                    NULL,
    add_time                       datetime                                        NULL,
    add_user_id                    varchar(100)                                    NULL,
    last_chg_time                  datetime                                        NULL,
    last_chg_user_id               varchar(100)                                    NULL,
    version_ctrl_nbr               varchar(100)                                    NULL,
    refresh_datetime               datetime2(7) GENERATED ALWAYS AS ROW START      NOT NULL,
    max_datetime                   datetime2(7) GENERATED ALWAYS AS ROW END HIDDEN NOT NULL,
    PERIOD FOR SYSTEM_TIME (refresh_datetime, max_datetime)
);

IF NOT EXISTS(SELECT 1 FROM sys.objects WHERE type = 'PK' AND object_id = OBJECT_ID('nrt_treatment'))
    BEGIN
        ALTER TABLE dbo.nrt_treatment
        ADD CONSTRAINT pk_nrt_treatment PRIMARY KEY (treatment_uid);
    END;

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_treatment' and xtype = 'U')
    BEGIN
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'morbidity_uid' AND Object_ID = Object_ID(N'nrt_treatment'))
            BEGIN
                ALTER TABLE dbo.nrt_treatment
                    ADD morbidity_uid varchar(100);
            END;

        IF EXISTS(SELECT 1 FROM sys.columns WHERE name = N'Treatment_nm' AND Object_ID = Object_ID(N'nrt_treatment'))
            AND NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'treatment_name' AND Object_ID = Object_ID(N'nrt_treatment'))
            BEGIN
                EXEC sp_rename 'nrt_treatment.Treatment_nm', 'treatment_name', 'COLUMN';
            END;

        IF EXISTS(SELECT 1 FROM sys.columns WHERE name = N'Treatment_oid' AND Object_ID = Object_ID(N'nrt_treatment'))
            AND NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'treatment_oid' AND Object_ID = Object_ID(N'nrt_treatment'))
            BEGIN
                EXEC sp_rename 'nrt_treatment.Treatment_oid', 'treatment_oid', 'COLUMN';
            END;

        IF EXISTS(SELECT 1 FROM sys.columns WHERE name = N'Treatment_comments' AND Object_ID = Object_ID(N'nrt_treatment'))
            AND NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'treatment_comments' AND Object_ID = Object_ID(N'nrt_treatment'))
            BEGIN
                EXEC sp_rename 'nrt_treatment.Treatment_comments', 'treatment_comments', 'COLUMN';
            END;

        IF EXISTS(SELECT 1 FROM sys.columns WHERE name = N'Treatment_shared_ind' AND Object_ID = Object_ID(N'nrt_treatment'))
            AND NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'treatment_shared_ind' AND Object_ID = Object_ID(N'nrt_treatment'))
            BEGIN
                EXEC sp_rename 'nrt_treatment.Treatment_shared_ind', 'treatment_shared_ind', 'COLUMN';
            END;

        IF EXISTS(SELECT 1 FROM sys.columns WHERE name = N'Treatment_dt' AND Object_ID = Object_ID(N'nrt_treatment'))
            AND NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'treatment_date' AND Object_ID = Object_ID(N'nrt_treatment'))
            BEGIN
                EXEC sp_rename 'nrt_treatment.Treatment_dt', 'treatment_date', 'COLUMN';
            END;

        IF EXISTS(SELECT 1 FROM sys.columns WHERE name = N'Treatment_drug' AND Object_ID = Object_ID(N'nrt_treatment'))
            AND NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'treatment_drug' AND Object_ID = Object_ID(N'nrt_treatment'))
            BEGIN
                EXEC sp_rename 'nrt_treatment.Treatment_drug', 'treatment_drug', 'COLUMN';
            END;

        IF EXISTS(SELECT 1 FROM sys.columns WHERE name = N'Treatment_drug_nm' AND Object_ID = Object_ID(N'nrt_treatment'))
            AND NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'treatment_drug_name' AND Object_ID = Object_ID(N'nrt_treatment'))
            BEGIN
                EXEC sp_rename 'nrt_treatment.Treatment_drug_nm', 'treatment_drug_name', 'COLUMN';
            END;

        IF EXISTS(SELECT 1 FROM sys.columns WHERE name = N'Treatment_dosage_strength' AND Object_ID = Object_ID(N'nrt_treatment'))
            AND NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'treatment_dosage_strength' AND Object_ID = Object_ID(N'nrt_treatment'))
            BEGIN
                EXEC sp_rename 'nrt_treatment.Treatment_dosage_strength', 'treatment_dosage_strength', 'COLUMN';
            END;

        IF EXISTS(SELECT 1 FROM sys.columns WHERE name = N'Treatment_dosage_strength_unit' AND Object_ID = Object_ID(N'nrt_treatment'))
            AND NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'treatment_dosage_strength_unit' AND Object_ID = Object_ID(N'nrt_treatment'))
            BEGIN
                EXEC sp_rename 'nrt_treatment.Treatment_dosage_strength_unit', 'treatment_dosage_strength_unit',
                     'COLUMN';
            END;

        IF EXISTS(SELECT 1 FROM sys.columns WHERE name = N'Treatment_frequency' AND Object_ID = Object_ID(N'nrt_treatment'))
            AND NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'treatment_frequency' AND Object_ID = Object_ID(N'nrt_treatment'))
            BEGIN
                EXEC sp_rename 'nrt_treatment.Treatment_frequency', 'treatment_frequency', 'COLUMN';
            END;

        IF EXISTS(SELECT 1 FROM sys.columns WHERE name = N'Treatment_duration' AND Object_ID = Object_ID(N'nrt_treatment'))
            AND NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'treatment_duration' AND Object_ID = Object_ID(N'nrt_treatment'))
            BEGIN
                EXEC sp_rename 'nrt_treatment.Treatment_duration', 'treatment_duration', 'COLUMN';
            END;

        IF EXISTS(SELECT 1 FROM sys.columns WHERE name = N'Treatment_duration_unit' AND Object_ID = Object_ID(N'nrt_treatment'))
            AND NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'treatment_duration_unit' AND Object_ID = Object_ID(N'nrt_treatment'))
            BEGIN
                EXEC sp_rename 'nrt_treatment.Treatment_duration_unit', 'treatment_duration_unit', 'COLUMN';
            END;

        IF EXISTS(SELECT 1 FROM sys.columns WHERE name = N'Treatment_route' AND Object_ID = Object_ID(N'nrt_treatment'))
            AND NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'treatment_route' AND Object_ID = Object_ID(N'nrt_treatment'))
            BEGIN
                EXEC sp_rename 'nrt_treatment.Treatment_route', 'treatment_route', 'COLUMN';
            END;

        IF EXISTS(SELECT 1 FROM sys.columns WHERE name = N'LOCAL_ID' AND Object_ID = Object_ID(N'nrt_treatment'))
            AND NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'local_id' AND Object_ID = Object_ID(N'nrt_treatment'))
            BEGIN
                EXEC sp_rename 'nrt_treatment.LOCAL_ID', 'local_id', 'COLUMN';
            END;

        IF EXISTS(SELECT 1 FROM sys.columns WHERE name = N'ADD_TIME' AND Object_ID = Object_ID(N'nrt_treatment'))
            AND NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'add_time' AND Object_ID = Object_ID(N'nrt_treatment'))
            BEGIN
                EXEC sp_rename 'nrt_treatment.ADD_TIME', 'add_time', 'COLUMN';
            END;

        IF EXISTS(SELECT 1 FROM sys.columns WHERE name = N'ADD_USER_ID' AND Object_ID = Object_ID(N'nrt_treatment'))
            AND NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'add_user_id' AND Object_ID = Object_ID(N'nrt_treatment'))
            BEGIN
                EXEC sp_rename 'nrt_treatment.ADD_USER_ID', 'add_user_id', 'COLUMN';
            END;

        IF EXISTS(SELECT 1 FROM sys.columns WHERE name = N'LAST_CHG_TIME' AND Object_ID = Object_ID(N'nrt_treatment'))
            BEGIN
                EXEC sp_rename 'nrt_treatment.LAST_CHG_TIME', 'last_change_time', 'COLUMN';
            END;

        IF EXISTS(SELECT 1 FROM sys.columns WHERE name = N'LAST_CHG_USER_ID' AND Object_ID = Object_ID(N'nrt_treatment'))
            BEGIN
                EXEC sp_rename 'nrt_treatment.LAST_CHG_USER_ID', 'last_change_user_id', 'COLUMN';
            END;

        IF EXISTS(SELECT 1 FROM sys.columns WHERE name = N'VERSION_CTRL_NBR' AND Object_ID = Object_ID(N'nrt_treatment'))
            BEGIN
                EXEC sp_rename 'nrt_treatment.VERSION_CTRL_NBR', 'version_control_number', 'COLUMN';
            END;

-- CNDE-2512
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'associated_phc_uids' AND Object_ID = Object_ID(N'nrt_treatment'))
            BEGIN
                ALTER TABLE dbo.nrt_treatment
                    ADD associated_phc_uids nvarchar(max);
            END;

-- CNDE-2536
        IF EXISTS(SELECT 1 FROM sys.columns WHERE name = N'public_health_case_uid' AND Object_ID = Object_ID(N'nrt_treatment'))
            BEGIN
                ALTER TABLE dbo.nrt_treatment
                    DROP COLUMN public_health_case_uid;
            END;

-- CNDE-2846
        IF EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'treatment_uid' AND Object_ID = Object_ID(N'nrt_treatment'))
            BEGIN
                ALTER TABLE dbo.nrt_treatment ALTER COLUMN treatment_uid bigint NOT NULL;
            END;

        IF EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'organization_uid' AND Object_ID = Object_ID(N'nrt_treatment'))
            BEGIN
                ALTER TABLE dbo.nrt_treatment ALTER COLUMN organization_uid bigint NULL;
            END;

        IF EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'provider_uid' AND Object_ID = Object_ID(N'nrt_treatment'))
            BEGIN
                ALTER TABLE dbo.nrt_treatment ALTER COLUMN provider_uid bigint NULL;
            END;

        IF EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'patient_treatment_uid' AND Object_ID = Object_ID(N'nrt_treatment'))
            BEGIN
                ALTER TABLE dbo.nrt_treatment ALTER COLUMN patient_treatment_uid bigint NULL;
            END;

        IF EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'morbidity_uid' AND Object_ID = Object_ID(N'nrt_treatment'))
            BEGIN
                ALTER TABLE dbo.nrt_treatment ALTER COLUMN morbidity_uid bigint NULL;
            END;

        IF EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'add_user_id' AND Object_ID = Object_ID(N'nrt_treatment'))
            BEGIN
                ALTER TABLE dbo.nrt_treatment ALTER COLUMN add_user_id bigint NULL;
            END;

        IF EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'last_chg_user_id' AND Object_ID = Object_ID(N'nrt_treatment'))
            BEGIN
                ALTER TABLE dbo.nrt_treatment ALTER COLUMN last_chg_user_id bigint NULL;
            END;
    END;
