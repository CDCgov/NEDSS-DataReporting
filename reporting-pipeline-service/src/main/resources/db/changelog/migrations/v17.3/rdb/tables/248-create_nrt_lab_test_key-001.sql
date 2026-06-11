IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_lab_test_key' and xtype = 'U')
	BEGIN

		CREATE TABLE [dbo].nrt_lab_test_key (
		LAB_TEST_KEY BIGINT IDENTITY(1,1) NOT NULL,
		LAB_TEST_UID BIGINT NULL,
		created_dttm DATETIME2 DEFAULT getdate(),
		updated_dttm DATETIME2 DEFAULT getdate()           
		);

		-- RESEED [dbo].nrt_lab_test_key table to align keys with LAB_TEST
        -- when a table with no rows is reseeded, the third parameter will be the key value of the first added row, so
        -- we must increment by 1 to prevent key collision with LAB_TEST
		DECLARE @max BIGINT;
		SELECT @max=max(LAB_TEST_KEY) + 1 from [dbo].LAB_TEST;
		SELECT @max;
		IF @max IS NULL
			SET @max = 2; -- LAB_TEST is expected to have a default null row with LAB_TEST_KEY = 1
		DBCC CHECKIDENT ('[dbo].nrt_lab_test_key', RESEED, @max);

	END;
