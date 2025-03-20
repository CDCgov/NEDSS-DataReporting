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

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'D_DISEASE_SITE' and xtype = 'U')
BEGIN
	IF NOT EXISTS(SELECT 1 FROM sys.objects WHERE type = 'F' AND  parent_object_id = OBJECT_ID ('dbo.D_DISEASE_SITE'))
	BEGIN
		ALTER TABLE dbo.D_DISEASE_SITE ADD CONSTRAINT FK_D_DISEASE_SITE_D_DISEASE_SITE_GROUP FOREIGN KEY 
		(
			D_DISEASE_SITE_GROUP_KEY
		) REFERENCES dbo.D_DISEASE_SITE_GROUP (
			D_DISEASE_SITE_GROUP_KEY
		);
	END
END;
