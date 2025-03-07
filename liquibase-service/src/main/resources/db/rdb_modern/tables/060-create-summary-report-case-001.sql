--CNDE-2292
IF NOT EXISTS (SELECT 1
               FROM sysobjects
               WHERE name = 'SUMMARY_REPORT_CASE'
                 and xtype = 'U')
    BEGIN
        CREATE TABLE dbo.SUMMARY_REPORT_CASE
        (
            SUM_RPT_CASE_COUNT       numeric       NULL,
            SUM_RPT_CASE_COMMENTS    varchar(2000) NULL,
            INVESTIGATION_KEY        bigint        NOT NULL,
            SUM_RPT_CASE_STATUS      varchar(20)   NULL,
            SUMMARY_CASE_SRC_KEY     bigint        NOT NULL,
            NOTIFICATION_SEND_DT_KEY bigint        NOT NULL,
            COUNTY_CD                varchar(50)   NOT NULL,
            COUNTY_NAME              varchar(300)  NOT NULL,
            STATE_CD                 varchar(50)   NOT NULL,
            CONDITION_KEY            bigint        NOT NULL,
            LDF_GROUP_KEY            bigint        NOT NULL,
            LAST_UPDATE_DT_KEY       bigint        NULL,
            PRIMARY KEY (INVESTIGATION_KEY, SUMMARY_CASE_SRC_KEY,
                         NOTIFICATION_SEND_DT_KEY, CONDITION_KEY,
                         LDF_GROUP_KEY),
            FOREIGN KEY (INVESTIGATION_KEY)
                REFERENCES dbo.INVESTIGATION
                ON DELETE NO ACTION,
            FOREIGN KEY (SUMMARY_CASE_SRC_KEY)
                REFERENCES dbo.SUMMARY_CASE_GROUP
                ON DELETE NO ACTION,
            FOREIGN KEY (NOTIFICATION_SEND_DT_KEY)
                REFERENCES dbo.RDB_DATE
                ON DELETE NO ACTION,
            FOREIGN KEY (CONDITION_KEY)
                REFERENCES dbo.CONDITION
                ON DELETE NO ACTION,
            FOREIGN KEY (LDF_GROUP_KEY)
                REFERENCES dbo.LDF_GROUP
                ON DELETE NO ACTION,
        )
    END;
