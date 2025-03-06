IF NOT EXISTS (SELECT 1
               FROM sysobjects
               WHERE name = 'TREATMENT'
                 and xtype = 'U')
    BEGIN
        CREATE TABLE dbo.TREATMENT
        (
            TREATMENT_KEY                   BIGINT NOT NULL,
            TREATMENT_UID                   BIGINT NULL,
            TREATMENT_LOCAL_ID              VARCHAR(50) NULL,
            TREATMENT_NM                    VARCHAR(150) NULL,
            TREATMENT_DRUG                  VARCHAR(50) NULL,
            TREATMENT_DOSAGE_STRENGTH       VARCHAR(20) NULL,
            TREATMENT_DOSAGE_STRENGTH_UNIT  VARCHAR(20) NULL,
            TREATMENT_FREQUENCY             VARCHAR(20) NULL,
            TREATMENT_DURATION              VARCHAR(10) NULL,
            TREATMENT_DURATION_UNIT         VARCHAR(20) NULL,
            TREATMENT_COMMENTS              VARCHAR(1000) NULL,
            TREATMENT_ROUTE                 VARCHAR(25) NULL,
            CUSTOM_TREATMENT                VARCHAR(100) NULL,
            TREATMENT_SHARED_IND            VARCHAR(50) NULL,
            TREATMENT_OID                   BIGINT NULL,
            RECORD_STATUS_CD                VARCHAR(8) NOT NULL,
            CONSTRAINT PK_TREATMENT PRIMARY KEY (TREATMENT_KEY),
            CONSTRAINT CHK_TREATMENT_RECORD_STATUS CHECK (RECORD_STATUS_CD IN ('ACTIVE','INACTIVE'))
        );
    END;