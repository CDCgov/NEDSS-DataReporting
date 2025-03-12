--CNDE-2346
IF NOT EXISTS (SELECT 1
               FROM sysobjects
               WHERE name = 'D_DISEASE_SITE_GROUP'
                 and xtype = 'U')

BEGIN				 
	CREATE TABLE DBO.D_DISEASE_SITE_GROUP (
		D_DISEASE_SITE_GROUP_KEY BIGINT NOT NULL ,
		PRIMARY KEY 
		(
			D_DISEASE_SITE_GROUP_KEY
		) 
	);
END;
