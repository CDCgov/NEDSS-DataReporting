IF NOT EXISTS (SELECT 1
               FROM sysobjects
               WHERE name = 'ORGANIZATION_LDF_GROUP'
                 and xtype = 'U')
    BEGIN
        CREATE TABLE DBO.ORGANIZATION_LDF_GROUP (
        	ORGANIZATION_KEY bigint NOT NULL,
        	LDF_GROUP_KEY bigint NOT NULL,
        	RECORD_STATUS_CD varchar(8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
        	CONSTRAINT PK__ORGANIZA__A5315709896DF96E PRIMARY KEY (ORGANIZATION_KEY,LDF_GROUP_KEY)
        );
        insert into dbo.ORGANIZATION_LDF_GROUP (ORGANIZATION_KEY, LDF_GROUP_KEY, RECORD_STATUS_CD)
                        values (1, 1, 'ACTIVE');
    END;