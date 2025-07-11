IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'LAB_TEST' and xtype = 'U')
    BEGIN
        --Increase varchar length according to 6.0.16 data dictionary
        IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = object_id('LAB_TEST') AND name='TEST_METHOD_CD' AND max_length=20)
            BEGIN
                ALTER TABLE LAB_TEST
                    ALTER COLUMN TEST_METHOD_CD VARCHAR(199)
            END
    END;