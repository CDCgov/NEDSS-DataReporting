/*CNDE-2152: Stopgap for INV_SUMM_DATAMART Requirements. Foreign key constraints will be added after the completion of TB Datamart migration.*/
IF NOT EXISTS (SELECT 1
               FROM sysobjects
               WHERE name = 'F_VAR_PAM'
                 and xtype = 'U')
    BEGIN
        CREATE TABLE dbo.F_VAR_PAM
        (
            PERSON_KEY               bigint NOT NULL,
            D_VAR_PAM_KEY            bigint NOT NULL,
            PROVIDER_KEY             bigint NOT NULL,
            D_PCR_SOURCE_GROUP_KEY   bigint NOT NULL,
            D_RASH_LOC_GEN_GROUP_KEY bigint NOT NULL,
            HOSPITAL_KEY             bigint NOT NULL,
            ORG_AS_REPORTER_KEY      bigint NOT NULL,
            PERSON_AS_REPORTER_KEY   bigint NOT NULL,
            PHYSICIAN_KEY            bigint NOT NULL,
            ADD_DATE_KEY             bigint NOT NULL,
            LAST_CHG_DATE_KEY        bigint NOT NULL,
            INVESTIGATION_KEY        bigint NOT NULL
        );
    END;