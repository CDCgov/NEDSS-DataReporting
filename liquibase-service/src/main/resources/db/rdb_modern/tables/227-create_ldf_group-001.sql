IF NOT EXISTS (SELECT 1
               FROM sysobjects
               WHERE name = 'LDF_GROUP'
                 and xtype = 'U')
    BEGIN
        CREATE TABLE DBO.LDF_GROUP (
        		LDF_GROUP_KEY        BIGINT NOT NULL,
         		BUSINESS_OBJECT_UID  BIGINT NULL
        );
    END;