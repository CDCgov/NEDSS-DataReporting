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

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_lab_result_comment_key' and xtype = 'U')
    AND EXISTS (SELECT 1 FROM sysobjects WHERE name = 'LAB_RESULT_COMMENT' and xtype = 'U')
    BEGIN
        
        --copy already existing (LAB_RESULT_COMMENT_KEY, LAB_TEST_UID) from LAB_RESULT_COMMENT

        SET IDENTITY_INSERT [dbo].nrt_lab_result_comment_key ON

        INSERT INTO [dbo].nrt_lab_result_comment_key(
            LAB_RESULT_COMMENT_KEY, 
            LAB_RESULT_COMMENT_UID
        )
        SELECT 
            rc.LAB_RESULT_COMMENT_KEY, 
            rc.LAB_TEST_UID 
        FROM [dbo].LAB_RESULT_COMMENT rc WITH(NOLOCK) 
        LEFT JOIN [dbo].nrt_lab_result_comment_key k WITH(NOLOCK)
            ON k.LAB_RESULT_COMMENT_KEY = rc.LAB_RESULT_COMMENT_KEY 
            AND k.LAB_RESULT_COMMENT_UID= rc.LAB_TEST_UID
        WHERE 
            k.LAB_RESULT_COMMENT_KEY IS NULL 
            AND k.LAB_RESULT_COMMENT_UID IS NULL
        ORDER BY rc.LAB_RESULT_COMMENT_KEY;

        SET IDENTITY_INSERT [dbo].nrt_lab_result_comment_key OFF
        
    END