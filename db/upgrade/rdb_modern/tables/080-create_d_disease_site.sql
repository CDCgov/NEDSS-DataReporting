--CNDE-2346 Foreign key constraints will be added after the completion of TB Datamart migration.*/
IF NOT EXISTS (SELECT 1
               FROM sysobjects
               WHERE name = 'D_DISEASE_SITE'
                 and xtype = 'U')

BEGIN				 
	CREATE TABLE DBO.D_DISEASE_SITE (
		TB_PAM_UID BIGINT NOT NULL ,
		D_DISEASE_SITE_KEY BIGINT NOT NULL ,
		SEQ_NBR INT NULL ,
		D_DISEASE_SITE_GROUP_KEY BIGINT NOT NULL ,
		LAST_CHG_TIME DATETIME NULL ,
		VALUE VARCHAR (250) NULL ,
		PRIMARY KEY
		(
			D_DISEASE_SITE_KEY,
			TB_PAM_UID
		)  
	);
END;


