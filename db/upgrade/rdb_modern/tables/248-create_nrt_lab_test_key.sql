IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_lab_test_key' and xtype = 'U')
	BEGIN

		CREATE TABLE [dbo].nrt_lab_test_key (
		LAB_TEST_KEY BIGINT IDENTITY(1,1) NOT NULL,
		LAB_TEST_UID BIGINT NULL,
		created_dttm DATETIME2 DEFAULT getdate(),
		updated_dttm DATETIME2 DEFAULT getdate()           
		);

		-- Insert Key = 1 with LAB_TEST_UID = NULL
		INSERT INTO [dbo].nrt_lab_test_key(LAB_TEST_UID)
		VALUES (NULL)

		--RESEED [dbo].nrt_lab_test_key table 
		DECLARE @max BIGINT;
		SELECT @max=max(LAB_TEST_KEY) from [dbo].LAB_TEST;
		SELECT @max;
		IF @max IS NULL   --check when max is returned as null
			SET @max = 2; -- default to 2, default record with key = 1 is already created
		DBCC CHECKIDENT ('[dbo].nrt_lab_test_key', RESEED, @max);

	END