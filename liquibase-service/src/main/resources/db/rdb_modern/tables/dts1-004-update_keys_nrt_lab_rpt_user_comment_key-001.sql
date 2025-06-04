  IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_lab_rpt_user_comment_key' and xtype = 'U')
    AND EXISTS (SELECT 1 FROM sysobjects WHERE name = 'LAB_RPT_USER_COMMENT' and xtype = 'U')
	AND EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_observation' and xtype = 'U')
    BEGIN
        
        --copy already existing (USER_COMMENT_KEY, LAB_RPT_USER_COMMENT_UID, LAB_TEST_UID) 
		--from LAB_RPT_USER_COMMENT join nrt_observation

        SET IDENTITY_INSERT [dbo].nrt_lab_rpt_user_comment_key ON

        INSERT INTO [dbo].nrt_lab_rpt_user_comment_key(
			USER_COMMENT_KEY, 
			LAB_RPT_USER_COMMENT_UID, 
			LAB_TEST_UID,
			created_dttm,
			updated_dttm
		)
        SELECT 
          	uc.USER_COMMENT_KEY, 
			o.observation_uid, 
			uc.LAB_TEST_UID,
			uc.COMMENTS_FOR_ELR_DT,
			uc.RDB_LAST_REFRESH_TIME
        FROM [dbo].LAB_RPT_USER_COMMENT uc WITH(NOLOCK)
        INNER JOIN [dbo].nrt_observation o WITH(NOLOCK)
			ON o.activity_to_time = uc.COMMENTS_FOR_ELR_DT 
        LEFT JOIN [dbo].nrt_lab_rpt_user_comment_key uck WITH(NOLOCK)
			ON uck.USER_COMMENT_KEY = uc.USER_COMMENT_KEY 
			AND uck.LAB_RPT_USER_COMMENT_UID = o.observation_uid 
			AND uck.LAB_TEST_UID = uc.LAB_TEST_UID
        WHERE 
			o.cd_desc_txt = 'User Report Comment' 
			AND o.add_user_id = uc.User_comment_created_by
			AND uck.USER_COMMENT_KEY IS NULL 
			AND uck.LAB_RPT_USER_COMMENT_UID IS NULL 
			AND uck.LAB_TEST_UID IS NULL
        ORDER BY uc.USER_COMMENT_KEY, o.observation_uid

        SET IDENTITY_INSERT [dbo].nrt_lab_rpt_user_comment_key OFF

    END