  IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_lab_test_key' and xtype = 'U')
    BEGIN

        CREATE TABLE [dbo].nrt_lab_test_key (
          LAB_TEST_KEY bigint IDENTITY(1,1) NOT NULL,
          LAB_TEST_UID bigint NULL,
          created_dttm DATETIME2 default getdate(),
          updated_dttm2 DATETIME2 GENERATED ALWAYS AS ROW END HIDDEN NOT NULL, PERIOD FOR SYSTEM_TIME (updated_dttm,updated_dttm2) 
        );

        -- Insert Key = 1 with LAB_TEST_UID = NULL
        INSERT INTO [dbo].nrt_lab_test_key(LAB_TEST_UID)
        VALUES (NULL)

        --copy already existing (LAB_TEST_KEY, LAB_TEST_UID) from LAB_TEST

        SET IDENTITY_INSERT [dbo].nrt_lab_test_key ON

        INSERT INTO [dbo].nrt_lab_test_key(LAB_TEST_KEY, LAB_TEST_UID)
        SELECT LAB_TEST_KEY, LAB_TEST_UID 
        FROM [dbo].LAB_TEST WITH(NOLOCK) 
        ORDER BY LAB_TEST_KEY

        SET IDENTITY_INSERT [dbo].nrt_lab_test_key OFF

        --RESEED [dbo].nrt_lab_test_key table 
        DECLARE @max BIGINT;
        select @max=max(LAB_TEST_KEY) from [dbo].lab_test;
        select @max;
        if @max IS NULL   --check when max is returned as null
            SET @max = 2; -- default to 2, default record with key = 1 is already created
        DBCC CHECKIDENT ('[dbo].nrt_lab_test_key', RESEED, @max);

    END