/*CNDE-2152: Stopgap for INV_SUMM_DATAMART Requirements. Foreign key constraints will be added after the completion of TB Datamart migration.*/
IF NOT EXISTS (SELECT 1
               FROM sysobjects
               WHERE name = 'F_TB_PAM'
                 and xtype = 'U')
    BEGIN
        CREATE TABLE dbo.F_TB_PAM
        (
            PERSON_KEY               bigint NOT NULL,
            D_TB_PAM_KEY             bigint NOT NULL,
            PROVIDER_KEY             bigint NOT NULL,
            D_MOVE_STATE_GROUP_KEY   bigint NOT NULL,
            D_HC_PROV_TY_3_GROUP_KEY bigint NOT NULL,
            D_DISEASE_SITE_GROUP_KEY bigint NOT NULL,
            D_ADDL_RISK_GROUP_KEY    bigint NOT NULL,
            D_MOVE_CNTY_GROUP_KEY    bigint NOT NULL,
            D_GT_12_REAS_GROUP_KEY   bigint NOT NULL,
            D_MOVE_CNTRY_GROUP_KEY   bigint NOT NULL,
            D_MOVED_WHERE_GROUP_KEY  bigint NOT NULL,
            D_OUT_OF_CNTRY_GROUP_KEY bigint NOT NULL,
            D_SMR_EXAM_TY_GROUP_KEY  bigint NOT NULL,
            ADD_DATE_KEY             bigint NOT NULL,
            LAST_CHG_DATE_KEY        bigint NOT NULL,
            INVESTIGATION_KEY        bigint NOT NULL,
            HOSPITAL_KEY             bigint NOT NULL,
            ORG_AS_REPORTER_KEY      bigint NOT NULL,
            PERSON_AS_REPORTER_KEY   bigint NOT NULL,
            PHYSICIAN_KEY            bigint NOT NULL
        );

    END;