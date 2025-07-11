IF NOT EXISTS (SELECT 1
               FROM sysobjects
               WHERE name = 'PROVIDER_LDF_GROUP'
                 and xtype = 'U')
    BEGIN
        CREATE TABLE DBO.PROVIDER_LDF_GROUP (
        	PROVIDER_KEY bigint NOT NULL,
        	LDF_GROUP_KEY bigint NOT NULL,
        	RECORD_STATUS_CD varchar(8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
        	CONSTRAINT PK__PROVIDER__B55EF1768487DDB1 PRIMARY KEY (PROVIDER_KEY,LDF_GROUP_KEY)
        );
        insert into dbo.PROVIDER_LDF_GROUP (PROVIDER_KEY, LDF_GROUP_KEY, RECORD_STATUS_CD)
                        values (1, 1, 'ACTIVE');
    END;