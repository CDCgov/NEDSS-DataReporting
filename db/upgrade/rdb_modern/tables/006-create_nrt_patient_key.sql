IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_patient_key' and xtype = 'U')
    BEGIN
        CREATE TABLE dbo.nrt_patient_key (
            d_patient_key bigint IDENTITY(1,1) NOT NULL,
            patient_uid bigint NULL,
            created_dttm DATETIME2 DEFAULT GETDATE(),
            updated_dttm DATETIME2 DEFAULT GETDATE(),
            PRIMARY KEY (d_patient_key)
        );
        declare @max bigint;
        select @max=max(patient_key)+1 from dbo.d_patient;
        select @max;
        if @max IS NULL   --check when max is returned as null
        SET @max = 1;
        DBCC CHECKIDENT ('dbo.nrt_patient_key', RESEED, @max);
    END;
