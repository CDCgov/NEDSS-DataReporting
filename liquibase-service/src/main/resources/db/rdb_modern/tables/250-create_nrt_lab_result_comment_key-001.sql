IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_lab_result_comment_key' and xtype = 'U')
	BEGIN

		CREATE TABLE [dbo].nrt_lab_result_comment_key (
			LAB_RESULT_COMMENT_KEY BIGINT IDENTITY(1,1) NOT NULL,
			LAB_RESULT_COMMENT_UID BIGINT NULL,               
			created_dttm DATETIME2 DEFAULT getdate(),
			updated_dttm DATETIME2 DEFAULT getdate()           
		);

		-- Insert Key = 1 with LAB_RESULT_COMMENT_UID = NULL
		INSERT INTO [dbo].nrt_lab_result_comment_key(LAB_RESULT_COMMENT_UID)
		VALUES (NULL)

		--RESEED [dbo].nrt_lab_result_comment_key table 
		DECLARE @max BIGINT;
		SELECT @max=max(LAB_RESULT_COMMENT_KEY) from [dbo].LAB_RESULT_COMMENT;
		SELECT @max;
		IF @max IS NULL   --check when max is returned as null
			SET @max = 2; -- default to 2, default record with key = 1 is already created
		DBCC CHECKIDENT ('[dbo].nrt_lab_result_comment_key', RESEED, @max);

	END;

IF NOT EXISTS(SELECT 1 FROM sys.objects WHERE type = 'PK' AND object_id = OBJECT_ID('nrt_lab_result_comment_key'))
    BEGIN
        ALTER TABLE dbo.nrt_lab_result_comment_key
        ADD CONSTRAINT pk_nrt_lab_result_comment_key PRIMARY KEY (LAB_RESULT_COMMENT_KEY);
    END

