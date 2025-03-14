--CNDE-2345
IF NOT EXISTS (SELECT 1
               FROM sysobjects
               WHERE name = 'D_ADDL_RISK_GROUP'
                 and xtype = 'U')

BEGIN				 
	CREATE TABLE DBO.D_ADDL_RISK_GROUP (
		D_ADDL_RISK_GROUP_KEY BIGINT NOT NULL ,
		PRIMARY KEY 
		(
			D_ADDL_RISK_GROUP_KEY
		) 
	);
END;
