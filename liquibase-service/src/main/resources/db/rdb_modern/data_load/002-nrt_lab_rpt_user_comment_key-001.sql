  IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_lab_rpt_user_comment_key' and xtype = 'U')
    AND EXISTS (SELECT 1 FROM sysobjects WHERE name = 'LAB_RPT_USER_COMMENT' and xtype = 'U')
	AND EXISTS (SELECT 1 FROM NBS_ODSE.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME='Act_relationship') 
	AND EXISTS (SELECT 1 FROM NBS_ODSE.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME='Observation') 
    BEGIN
        
        --copy already existing (USER_COMMENT_KEY, LAB_RPT_USER_COMMENT_UID, LAB_TEST_UID) 
		--from LAB_RPT_USER_COMMENT join NBS_ODSE..Act_relationship NBS_ODSE..join Observation

        SET IDENTITY_INSERT [dbo].nrt_lab_rpt_user_comment_key ON

        INSERT INTO [dbo].nrt_lab_rpt_user_comment_key(
			USER_COMMENT_KEY, 
			LAB_RPT_USER_COMMENT_UID, 
			LAB_TEST_UID
		)
		SELECT 
			c.USER_COMMENT_KEY,
			o.observation_uid,
			c.lab_test_uid
		FROM [dbo].LAB_RPT_USER_COMMENT c WITH (NOLOCK)
		INNER JOIN [NBS_ODSE].[dbo].Act_relationship ar WITH (NOLOCK)
			ON ar.target_act_uid = c.lab_test_uid 
		INNER JOIN [NBS_ODSE].[dbo].Act_relationship ar2 WITH (NOLOCK)
			ON ar.source_act_uid = ar2.target_act_uid
		INNER JOIN [NBS_ODSE].[dbo].Observation o WITH (NOLOCK)
			ON ar2.source_act_uid = o.observation_uid 
			AND o.activity_to_time = c.COMMENTS_FOR_ELR_DT
			AND o.add_user_id = c.User_comment_created_by
		LEFT JOIN [dbo].nrt_lab_rpt_user_comment_key uck WITH(NOLOCK)
			ON uck.USER_COMMENT_KEY = c.USER_COMMENT_KEY 
			AND uck.LAB_RPT_USER_COMMENT_UID = o.observation_uid 
			AND uck.LAB_TEST_UID = c.LAB_TEST_UID
		WHERE 
			o.obs_domain_cd_st_1 = 'C_Result'  
			AND uck.USER_COMMENT_KEY IS NULL 
			AND uck.LAB_RPT_USER_COMMENT_UID IS NULL 
			AND uck.LAB_TEST_UID IS NULL
		ORDER BY C.USER_COMMENT_KEY

        SET IDENTITY_INSERT [dbo].nrt_lab_rpt_user_comment_key OFF

    END