IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'INV_HIV' and xtype = 'U')
    BEGIN
        CREATE TABLE [dbo].[INV_HIV]
        (
            D_INV_HIV_KEY BIGINT,
            HIV_STATE_CASE_ID VARCHAR(2000),
            HIV_LAST_900_TEST_DT DATE,
            HIV_900_TEST_REFERRAL_DT DATE,
            HIV_CA_900_OTH_RSN_NOT_LO VARCHAR(4000),
            HIV_ENROLL_PRTNR_SRVCS_IND VARCHAR(4000),
            HIV_PREVIOUS_900_TEST_IND VARCHAR(4000),
            HIV_SELF_REPORTED_RSLT_900 VARCHAR(4000),
            HIV_REFER_FOR_900_TEST VARCHAR(4000),
            HIV_900_TEST_IND VARCHAR(4000),
            HIV_900_RESULT VARCHAR(4000),
            HIV_RST_PROVIDED_900_RSLT_IND VARCHAR(4000),
            HIV_POST_TEST_900_COUNSELING VARCHAR(4000),
            HIV_REFER_FOR_900_CARE_IND VARCHAR(4000),
            HIV_KEEP_900_CARE_APPT_IND VARCHAR(4000),
            HIV_AV_THERAPY_LAST_12MO_IND VARCHAR(4000),
            HIV_AV_THERAPY_EVER_IND VARCHAR(4000),
            HIV_CA_900_REASON_NOT_LOC VARCHAR(4000),
            INVESTIGATION_KEY BIGINT
        );
    END;
