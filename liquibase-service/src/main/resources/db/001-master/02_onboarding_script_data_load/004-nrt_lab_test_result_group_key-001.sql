-- use rdb_modern;
IF
    EXISTS (
        SELECT 1 FROM NBS_ODSE.DBO.NBS_CONFIGURATION
        WHERE CONFIG_KEY = 'ENV' AND CONFIG_VALUE = 'UAT'
    )
    BEGIN
        USE [rdb_modern];
        PRINT 'Switched to database [rdb_modern]'
    END
ELSE
    BEGIN
        USE [rdb];
        PRINT 'Switched to database [rdb]';
    END

IF
    EXISTS (
        SELECT 1 FROM SYSOBJECTS
        WHERE NAME = 'nrt_lab_test_result_group_key' AND XTYPE = 'U'
    )
    AND EXISTS (
        SELECT 1 FROM SYSOBJECTS
        WHERE NAME = 'TEST_RESULT_GROUPING' AND XTYPE = 'U'
    )
    BEGIN

        --copy already existing (TEST_RESULT_GRP_KEY, LAB_TEST_UID) from TEST_RESULT_GROUPING

        SET IDENTITY_INSERT [dbo].NRT_LAB_TEST_RESULT_GROUP_KEY ON

        INSERT INTO [dbo].NRT_LAB_TEST_RESULT_GROUP_KEY (
            TEST_RESULT_GRP_KEY,
            LAB_TEST_UID
        )
        SELECT
            RG.TEST_RESULT_GRP_KEY,
            RG.LAB_TEST_UID
        FROM [dbo].TEST_RESULT_GROUPING AS RG WITH (NOLOCK)
        LEFT JOIN [dbo].NRT_LAB_TEST_RESULT_GROUP_KEY AS K WITH (NOLOCK)
            ON RG.TEST_RESULT_GRP_KEY = K.TEST_RESULT_GRP_KEY
        WHERE
            K.TEST_RESULT_GRP_KEY IS NULL
        ORDER BY RG.TEST_RESULT_GRP_KEY;

        SET IDENTITY_INSERT [dbo].NRT_LAB_TEST_RESULT_GROUP_KEY OFF

    END
