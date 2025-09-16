-- use rdb_modern;
IF EXISTS(SELECT 1 FROM NBS_ODSE.DBO.NBS_configuration WHERE config_key ='ENV' AND config_value ='UAT')
    BEGIN
        USE [rdb_modern];
        PRINT 'Switched to database [rdb_modern]'
    END
ELSE
    BEGIN
        USE [rdb];
        PRINT 'Switched to database [rdb]';
    END

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_lab_rpt_user_comment_key' and xtype = 'U')
    AND EXISTS (SELECT 1 FROM sysobjects WHERE name = 'LAB_RPT_USER_COMMENT' and xtype = 'U')
	AND EXISTS (SELECT 1 FROM NBS_ODSE.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME='Act_relationship') 
	AND EXISTS (SELECT 1 FROM NBS_ODSE.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME='Observation') 
    BEGIN
        
        --copy already existing (USER_COMMENT_KEY, LAB_RPT_USER_COMMENT_UID, LAB_TEST_UID) 
		--from LAB_RPT_USER_COMMENT join NBS_ODSE..Act_relationship NBS_ODSE..join Observation

        SET IDENTITY_INSERT [dbo].nrt_lab_rpt_user_comment_key ON


        ;WITH CommentCTE AS (
            SELECT
                c.USER_COMMENT_KEY,
                c.lab_test_uid,
                ROW_NUMBER() OVER (
                    PARTITION BY c.lab_test_uid ORDER BY c.USER_COMMENT_KEY
                ) AS rn
            FROM [dbo].LAB_RPT_USER_COMMENT c
        ),
        ObsCTE AS (
            SELECT
                 o.observation_uid,
                 ar.target_act_uid AS lab_test_uid,
                 ROW_NUMBER() OVER (
                 PARTITION BY ar.target_act_uid ORDER BY o.observation_uid
                 ) AS rn
            FROM [NBS_ODSE].[dbo].Act_relationship ar
            INNER JOIN [NBS_ODSE].[dbo].Act_relationship ar2
                ON ar.source_act_uid = ar2.target_act_uid
            INNER JOIN [NBS_ODSE].[dbo].Observation o
                ON ar2.source_act_uid = o.observation_uid
                AND o.obs_domain_cd_st_1 = 'C_Result'
        )
         INSERT INTO [dbo].nrt_lab_rpt_user_comment_key(
            USER_COMMENT_KEY,
            LAB_RPT_USER_COMMENT_UID,
            LAB_TEST_UID
        )
        SELECT
            c.USER_COMMENT_KEY,
            o.observation_uid,
            c.lab_test_uid
        FROM CommentCTE c
        INNER JOIN ObsCTE o
            ON c.lab_test_uid = o.lab_test_uid
            AND c.rn = o.rn
        LEFT JOIN [dbo].nrt_lab_rpt_user_comment_key uck
            ON uck.USER_COMMENT_KEY = c.USER_COMMENT_KEY
            AND uck.LAB_RPT_USER_COMMENT_UID = o.observation_uid
            AND uck.LAB_TEST_UID = c.lab_test_uid
        WHERE
            uck.USER_COMMENT_KEY IS NULL
            AND uck.LAB_RPT_USER_COMMENT_UID IS NULL
            AND uck.LAB_TEST_UID IS NULL
        ORDER BY c.USER_COMMENT_KEY;

        SET IDENTITY_INSERT [dbo].nrt_lab_rpt_user_comment_key OFF

    END