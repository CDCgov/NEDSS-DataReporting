IF NOT EXISTS (SELECT 1
               FROM sysobjects
               WHERE name = 'TREATMENT_EVENT'
                 and xtype = 'U')
    BEGIN
        CREATE TABLE dbo.TREATMENT_EVENT
        (
            TREATMENT_DT_KEY              BIGINT NOT NULL,
            TREATMENT_PROVIDING_ORG_KEY   BIGINT NOT NULL,
            PATIENT_KEY                   BIGINT NOT NULL,
            TREATMENT_COUNT               NUMERIC(18,0) NULL,
            TREATMENT_KEY                 BIGINT NOT NULL,
            MORB_RPT_KEY                  BIGINT NOT NULL,
            TREATMENT_PHYSICIAN_KEY       BIGINT NOT NULL,
            INVESTIGATION_KEY             BIGINT NOT NULL,
            CONDITION_KEY                 BIGINT NOT NULL,
            LDF_GROUP_KEY                 BIGINT NOT NULL,
            RECORD_STATUS_CD              VARCHAR(8) NOT NULL,
            CONSTRAINT PK_TREATMENT_EVENT PRIMARY KEY (
                                                       TREATMENT_DT_KEY,
                                                       TREATMENT_PROVIDING_ORG_KEY,
                                                       PATIENT_KEY,
                                                       TREATMENT_KEY,
                                                       MORB_RPT_KEY,
                                                       TREATMENT_PHYSICIAN_KEY,
                                                       INVESTIGATION_KEY,
                                                       CONDITION_KEY,
                                                       LDF_GROUP_KEY
                ),
            CONSTRAINT CHK_TRE_EVENT_RECORD_STATUS CHECK (RECORD_STATUS_CD IN ('ACTIVE','INACTIVE'))
        );
    END;