  IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_lab_rpt_user_comment_key' and xtype = 'U')
    BEGIN

        CREATE TABLE [dbo].nrt_lab_rpt_user_comment_key (
          USER_COMMENT_KEY bigint IDENTITY(1,1) NOT NULL,
          LAB_TEST_KEY bigint NULL,
          USER_COMMENT_UID bigint NULL,
        );

        -- Insert Key = 1 with LAB_TEST_KEY= 1, USER_COMMENT_UID = NULL
        INSERT INTO [dbo].nrt_lab_rpt_user_comment_key(LAB_TEST_KEY, USER_COMMENT_UID)
        VALUES (1, NULL)

        --copy already existing (USER_COMMENT_KEY, LAB_TEST_KEY, LAB_TEST_UID) from Lab_Rpt_User_Comment

        SET IDENTITY_INSERT [dbo].nrt_lab_rpt_user_comment_key ON

        INSERT INTO [dbo].nrt_lab_rpt_user_comment_key(USER_COMMENT_KEY, LAB_TEST_KEY, USER_COMMENT_UID)
        SELECT uc.USER_COMMENT_KEY, uc.LAB_TEST_KEY, uck.USER_COMMENT_UID 
        FROM [dbo].Lab_Rpt_User_Comment uc WITH(NOLOCK)  
        INNER JOIN nrt_lab_rpt_user_comment_key uck 
          ON uck.USER_COMMENT_KEY = uc.USER_COMMENT_KEY 
          AND uck.LAB_TEST_KEY = uc.LAB_TEST_KEY
        ORDER BY uc.LAB_TEST_KEY, uc.USER_COMMENT_KEY

        SET IDENTITY_INSERT [dbo].nrt_lab_rpt_user_comment_key OFF

        --RESEED [dbo].nrt_lab_rpt_user_comment_key table 
        DECLARE @max BIGINT;
        select @max=max(USER_COMMENT_KEY) from [dbo].Lab_Rpt_User_Comment;
        select @max;
        if @max IS NULL   --check when max is returned as null
            SET @max = 2; -- default to 2, default record with key = 1 is already created
        DBCC CHECKIDENT ('[dbo].nrt_lab_rpt_user_comment_key', RESEED, @max);

    END