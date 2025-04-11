IF NOT EXISTS (SELECT 1
               FROM sysobjects
               WHERE name = 'PATIENT_LDF_GROUP'
                 and xtype = 'U')
    BEGIN
        CREATE TABLE DBO.PATIENT_LDF_GROUP (
        	PATIENT_KEY bigint NOT NULL,
        	LDF_GROUP_KEY bigint NOT NULL,
        	RECORD_STATUS_CD varchar(8) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
        	CONSTRAINT PK__PATIENT___45423284EB5A2D18 PRIMARY KEY (PATIENT_KEY,LDF_GROUP_KEY)
        );
    END;