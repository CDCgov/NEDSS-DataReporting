IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_condition_key' and xtype = 'U')
	BEGIN

		CREATE TABLE [dbo].nrt_condition_key (
		CONDITION_KEY   BIGINT IDENTITY(1,1)    NOT NULL,
		condition_cd    VARCHAR(50)             NULL,
        program_area_cd VARCHAR(20)             NULL,
		created_dttm    DATETIME2               DEFAULT getdate(),
		updated_dttm    DATETIME2               DEFAULT getdate()           
		);

		-- Insert Key = 1 with CONDITION_CD, PROGRAM_AREA_CD = NULL
		INSERT INTO [dbo].nrt_condition_key(CONDITION_CD, PROGRAM_AREA_CD)
		VALUES (NULL, NULL)

		--RESEED [dbo].nrt_condition_key table 
		DECLARE @max BIGINT;
		SELECT @max=max(CONDITION_KEY) from [dbo].CONDITION;
		SELECT @max;
		IF @max IS NULL   --check when max is returned as null
			SET @max = 2; -- default to 2, default record with key = 1 is already created
		DBCC CHECKIDENT ('[dbo].nrt_condition_key', RESEED, @max);

	END

