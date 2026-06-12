IF NOT EXISTS (SELECT 1
               FROM sysobjects
               WHERE name = 'LDF_GROUP'
                 and xtype = 'U')
    BEGIN
        CREATE TABLE DBO.LDF_GROUP (
        		LDF_GROUP_KEY        BIGINT NOT NULL,
         		BUSINESS_OBJECT_UID  BIGINT NULL
        );
        insert into dbo.ldf_group(ldf_group_key, business_object_uid)
                        VALUES (1, NULL);
    END;