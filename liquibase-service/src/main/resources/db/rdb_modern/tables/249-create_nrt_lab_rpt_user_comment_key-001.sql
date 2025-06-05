IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_lab_rpt_user_comment_key' and xtype = 'U')
	BEGIN

		CREATE TABLE [dbo].nrt_lab_rpt_user_comment_key (
			USER_COMMENT_KEY BIGINT IDENTITY(1,1) NOT NULL,
			LAB_RPT_USER_COMMENT_UID BIGINT NULL,
			LAB_TEST_UID BIGINT NULL,
			created_dttm DATETIME2 DEFAULT GETDATE(),
			updated_dttm DATETIME2 DEFAULT GETDATE()
		);

		-- Insert Key = 1 with LAB_RPT_USER_COMMENT_UID = NULL, LAB_TEST_UID= NULL
		INSERT INTO [dbo].nrt_lab_rpt_user_comment_key(LAB_RPT_USER_COMMENT_UID, LAB_TEST_UID)
		VALUES (NULL, NULL)

		--RESEED [dbo].nrt_lab_rpt_user_comment_key table 
		DECLARE @max BIGINT;
		SELECT @max=max(USER_COMMENT_KEY) from [dbo].Lab_Rpt_User_Comment;
		SELECT @max;
		IF @max IS NULL   --check when max is returned as null
			SET @max = 2; -- default to 2, default record with key = 1 is already created
		DBCC CHECKIDENT ('[dbo].nrt_lab_rpt_user_comment_key', RESEED, @max);

	END