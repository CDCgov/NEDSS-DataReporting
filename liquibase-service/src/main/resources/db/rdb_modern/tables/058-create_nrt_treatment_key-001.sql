/*
    NOTE: As of ticket CNDE-2536, treatment_uid is no longer enough to determine uniqueness, 
    but a combination of treatment_uid and public_health_case_uid is required.
*/
IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_treatment_key' and xtype = 'U')
    BEGIN
        CREATE TABLE dbo.nrt_treatment_key (
                                               d_treatment_key bigint IDENTITY (1,1) NOT NULL,
                                               treatment_uid   bigint                NULL
        );

        declare @max bigint;
        select @max=max(TREATMENT_KEY)+1 from dbo.TREATMENT ;
        select @max;
        if @max IS NULL   --check when max is returned as null
            SET @max = 2; -- default to 2
        DBCC CHECKIDENT ('dbo.nrt_treatment_key', RESEED, @max);
    END

IF NOT EXISTS(SELECT 1 FROM sys.objects WHERE type = 'PK' AND object_id = OBJECT_ID('nrt_treatment_key'))
BEGIN
ALTER TABLE nrt_treatment_key
    ADD CONSTRAINT pk_nrt_treatment_key PRIMARY KEY (d_treatment_key);
END;

IF NOT EXISTS (SELECT 1 FROM dbo.TREATMENT)
    BEGIN
        INSERT INTO dbo.TREATMENT (TREATMENT_KEY, RECORD_STATUS_CD)
        SELECT 1,'ACTIVE'; --Default record with ACTIVE status as per CHK_TREATMENT_RECORD_STATUS constraint

    END;

-- CNDE-2536
        IF NOT EXISTS(SELECT 1
                      FROM sys.columns
                      WHERE name = N'public_health_case_uid'
                        AND Object_ID = Object_ID(N'nrt_treatment_key'))
            BEGIN
                ALTER TABLE dbo.nrt_treatment_key
                    ADD public_health_case_uid bigint;
            END;

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_treatment_key' and xtype = 'U')
    BEGIN
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'created_dttm' AND Object_ID = Object_ID(N'nrt_treatment_key'))
            BEGIN
                ALTER TABLE dbo.nrt_treatment_key
                    ADD created_dttm DATETIME2 DEFAULT GETDATE();
            END;
        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'updated_dttm' AND Object_ID = Object_ID(N'nrt_treatment_key'))
            BEGIN
                ALTER TABLE dbo.nrt_treatment_key
                    ADD updated_dttm DATETIME2 DEFAULT GETDATE();
            END;
    END;            