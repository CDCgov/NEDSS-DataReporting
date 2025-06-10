IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_lab_test_result_group_key' and xtype = 'U')
    AND EXISTS (SELECT 1 FROM sysobjects WHERE name = 'TEST_RESULT_GROUPING' and xtype = 'U')
    BEGIN
        
        --copy already existing (TEST_RESULT_GRP_KEY, LAB_TEST_UID) from TEST_RESULT_GROUPING

        SET IDENTITY_INSERT [dbo].nrt_lab_test_result_group_key ON

        INSERT INTO [dbo].nrt_lab_test_result_group_key(
            TEST_RESULT_GRP_KEY, 
            LAB_TEST_UID
        )
        SELECT 
            rg.TEST_RESULT_GRP_KEY, 
            rg.LAB_TEST_UID 
        FROM [dbo].TEST_RESULT_GROUPING rg WITH(NOLOCK) 
        LEFT JOIN [dbo].nrt_lab_test_result_group_key k WITH(NOLOCK)
            ON k.TEST_RESULT_GRP_KEY = rg.TEST_RESULT_GRP_KEY 
            AND k.LAB_TEST_UID= rg.LAB_TEST_UID
        WHERE 
            k.TEST_RESULT_GRP_KEY IS NULL 
            AND k.LAB_TEST_UID IS NULL
        ORDER BY rg.TEST_RESULT_GRP_KEY;

        SET IDENTITY_INSERT [dbo].nrt_lab_test_result_group_key OFF
        
    END