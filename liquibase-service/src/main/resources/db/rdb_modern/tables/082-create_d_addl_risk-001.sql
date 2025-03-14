--CNDE-2345 Foreign key constraints will be added after the completion of TB Datamart migration.*/
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