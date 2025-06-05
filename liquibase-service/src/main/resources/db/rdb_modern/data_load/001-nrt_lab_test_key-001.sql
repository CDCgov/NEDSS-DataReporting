  IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_lab_test_key' and xtype = 'U')
     AND EXISTS (SELECT 1 FROM sysobjects WHERE name = 'LAB_TEST' and xtype = 'U')
    BEGIN
        
        --copy already existing (LAB_TEST_KEY, LAB_TEST_UID) from LAB_TEST

        SET IDENTITY_INSERT [dbo].nrt_lab_test_key ON

        INSERT INTO [dbo].nrt_lab_test_key(
			LAB_TEST_KEY, 
			LAB_TEST_UID, 
			created_dttm, 
			updated_dttm 
        )
        SELECT 
			lt.LAB_TEST_KEY, 
			lt.LAB_TEST_UID, 
			lt.LAB_RPT_CREATED_DT, 
			lt.LAB_RPT_LAST_UPDATE_DT 
        FROM [dbo].LAB_TEST lt WITH(NOLOCK) 
        LEFT JOIN [dbo].nrt_lab_test_key k
          ON k.LAB_TEST_KEY = lt.LAB_TEST_KEY AND k.LAB_TEST_UID= lt.LAB_TEST_UID
        WHERE k.LAB_TEST_KEY IS NULL AND k.LAB_TEST_UID IS NULL
            ORDER BY lt.LAB_TEST_KEY;

        SET IDENTITY_INSERT [dbo].nrt_lab_test_key OFF
        
    END