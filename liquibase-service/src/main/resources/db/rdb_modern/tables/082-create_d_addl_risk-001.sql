IF NOT EXISTS (SELECT 1
               FROM sysobjects
               WHERE name = 'D_ADDL_RISK'
                 and xtype = 'U')

BEGIN				 
	CREATE TABLE DBO.D_ADDL_RISK (
		TB_PAM_UID BIGINT NOT NULL ,
		D_ADDL_RISK_KEY BIGINT NOT NULL ,
		SEQ_NBR INT NULL ,
		D_ADDL_RISK_GROUP_KEY BIGINT NOT NULL ,
		LAST_CHG_TIME DATETIME NULL ,
		VALUE VARCHAR (250) NULL ,
		PRIMARY KEY
		(
			D_ADDL_RISK_KEY,
			TB_PAM_UID
		)  
	);
END;

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'D_ADDL_RISK' and xtype = 'U')
BEGIN
	IF NOT EXISTS(SELECT 1 FROM sys.objects WHERE type = 'F' AND  parent_object_id = OBJECT_ID ('dbo.D_ADDL_RISK'))
	BEGIN
		ALTER TABLE dbo.D_ADDL_RISK ADD CONSTRAINT FK_D_ADDL_RISK_D_ADDL_RISK_GROUP FOREIGN KEY 
		(
			D_ADDL_RISK_GROUP_KEY
		) REFERENCES dbo.D_ADDL_RISK_GROUP (
			D_ADDL_RISK_GROUP_KEY
		);
	END
END;


