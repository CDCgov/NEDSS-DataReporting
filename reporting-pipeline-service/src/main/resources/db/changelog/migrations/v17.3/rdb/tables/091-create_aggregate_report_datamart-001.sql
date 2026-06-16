--CNDE-2140
IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'AGGREGATE_REPORT_DATAMART' and xtype = 'U')
    BEGIN
        CREATE TABLE dbo.AGGREGATE_REPORT_DATAMART
        (
            REPORTING_COUNTY varchar(50) NULL,
            COMMENTS varchar(2000) NULL,
            REPORT_LOCAL_ID varchar(50) NULL,
            CONDITION_DESCRIPTION varchar(300) NULL,
            MMWR_YEAR numeric(19, 0) NULL,
            MMWR_WEEK numeric(19, 0) NULL,
            REPORT_CREATE_DATE datetime2(3) NULL,
            REPORT_LAST_UPDATE_DATE datetime2(3) NULL,
            NUM_HOSP_REPORTING varchar(2000) NULL,
            SURVEILLANCE_METHOD varchar(2000) NULL,
            DIED_COUNT_19_TO_24 float NULL,
            HOSPITALIZED_COUNT_65_PLUS float NULL,
            HOSPITALIZED_COUNT_25_TO_49 float NULL,
            TOTAL_COUNT_25_TO_49 float NULL,
            DIED_COUNT_5_TO_18 float NULL,
            DIED_COUNT_UNKNOWN float NULL,
            DIED_COUNT_25_TO_49 float NULL,
            HOSPITALIZED_COUNT_0_TO_4 float NULL,
            TOTAL_COUNT_TOTAL float NULL,
            HOSPITALIZED_COUNT_5_TO_18 float NULL,
            DIED_COUNT_65_PLUS float NULL,
            DIED_COUNT_TOTAL float NULL,
            TOTAL_COUNT_0_TO_4 float NULL,
            TOTAL_COUNT_50_TO_64 float NULL,
            TOTAL_COUNT_19_TO_24 float NULL,
            DIED_COUNT_50_TO_64 float NULL,
            HOSPITALIZED_COUNT_TOTAL float NULL,
            HOSPITALIZED_COUNT_UNKNOWN float NULL,
            HOSPITALIZED_COUNT_50_TO_64 float NULL,
            TOTAL_COUNT_UNKNOWN float NULL,
            TOTAL_COUNT_65_PLUS float NULL,
            HOSPITALIZED_19_TO_24 float NULL,
            TOTAL_COUNT_5_TO_18 float NULL,
            DIED_COUNT_0_TO_4 float NULL,
            NOTIFICATION_UPD_DT_KEY numeric(20, 0) NULL,
            NOTIFICATION_STATUS varchar(20) NULL,
            NOTIFICATION_LOCAL_ID varchar(50) NULL,
            NOTIFICATION_LAST_CHANGE_TIME datetime2(3) NULL,
            USER_NM varchar(100) NULL,
            PROVIDER_UID numeric(20, 0) NULL,
            PROVIDER_QUICK_CODE varchar(50) NULL,
            PROVIDER_KEY numeric(20, 0) NULL,
            REPORT_CREATED_BY_USER varchar(101) NULL,
            REPORT_LAST_UPDATED_BY_USER varchar(101) NULL
       );
    END;

IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'AGGREGATE_REPORT_DATAMART' and xtype = 'U')
    BEGIN

        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'NUM_HOSP_REPORTING' AND Object_ID = Object_ID(N'AGGREGATE_REPORT_DATAMART'))
            BEGIN
                ALTER TABLE dbo.AGGREGATE_REPORT_DATAMART ADD NUM_HOSP_REPORTING VARCHAR(2000);
            END;

        IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE name = N'SURVEILLANCE_METHOD' AND Object_ID = Object_ID(N'AGGREGATE_REPORT_DATAMART'))
            BEGIN
                ALTER TABLE dbo.AGGREGATE_REPORT_DATAMART ADD SURVEILLANCE_METHOD VARCHAR(2000);
            END;

    END;

