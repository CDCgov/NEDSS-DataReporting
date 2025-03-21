--CNDE-2383
IF NOT EXISTS (SELECT 1
               FROM sysobjects
               WHERE name = 'D_MOVE_CNTRY_GROUP'
                 and xtype = 'U')

BEGIN				 
	CREATE TABLE DBO.D_MOVE_CNTRY_GROUP (
		D_MOVE_CNTRY_GROUP_KEY BIGINT NOT NULL ,
		CONSTRAINT PK_D_MOVE_CNTRY_GROUP PRIMARY KEY CLUSTERED 
		(
			D_MOVE_CNTRY_GROUP_KEY
		)  ON [PRIMARY ]
	) ON [PRIMARY];
END;
