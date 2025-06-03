  IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_lab_test_key' and xtype = 'U')
    BEGIN

        CREATE TABLE [dbo].nrt_lab_test_key (
          LAB_TEST_KEY bigint IDENTITY(1,1) NOT NULL,
          LAB_TEST_UID bigint NULL,
          created_dttm DATETIME2 default getdate(),
          updated_dttm DATETIME2 default getdate()           
        );

        -- Insert Key = 1 with LAB_TEST_UID = NULL
        INSERT INTO [dbo].nrt_lab_test_key(LAB_TEST_UID)
        VALUES (NULL)

    END