  IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_lab_rpt_user_comment_key' and xtype = 'U')
     AND EXISTS (SELECT 1 FROM sysobjects WHERE name = 'LAB_RPT_USER_COMMENT' and xtype = 'U')
    BEGIN
        
        --copy already existing (USER_COMMENT_KEY, LAB_TEST_KEY, LAB_TEST_UID) from LAB_RPT_USER_COMMENT

        SET IDENTITY_INSERT [dbo].nrt_lab_rpt_user_comment_key ON

        INSERT INTO [dbo].nrt_lab_rpt_user_comment_key(USER_COMMENT_KEY, LAB_TEST_KEY, USER_COMMENT_UID)
        SELECT uc.USER_COMMENT_KEY, uc.LAB_TEST_KEY,  uc.LAB_TEST_UID 
        FROM [dbo].LAB_RPT_USER_COMMENT uc WITH(NOLOCK)  
        LEFT JOIN [dbo].nrt_lab_rpt_user_comment_key uck 
            ON uck.USER_COMMENT_KEY = uc.USER_COMMENT_KEY 
            AND uck.LAB_TEST_KEY = uc.LAB_TEST_KEY
          AND uck.USER_COMMENT_UID = LAB_TEST_UID
        WHERE 
          uck.USER_COMMENT_KEY IS NULL 
          AND uck.LAB_TEST_KEY IS NULL 
          AND uck.USER_COMMENT_UID IS NULL
        ORDER BY uc.LAB_TEST_KEY, uc.USER_COMMENT_KEY

        SET IDENTITY_INSERT [dbo].nrt_lab_rpt_user_comment_key OFF

    END