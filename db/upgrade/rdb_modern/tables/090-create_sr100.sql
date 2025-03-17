IF NOT EXISTS (SELECT 1
               FROM sysobjects
               WHERE name = 'SR100'
                 and xtype = 'U')
    BEGIN

        CREATE TABLE DBO.SR100
        (
            LOCAL_ID           VARCHAR(50)   NOT NULL,
            MMWRWK             NUMERIC       NOT NULL,
            MMWRYR             NUMERIC       NOT NULL,
            NBR_CASES          NUMERIC(8, 0) NULL,
            CONDITION_CD       VARCHAR(50)   NOT NULL,
            CONDITION          VARCHAR(300)  NOT NULL,
            COUNTY_CD          VARCHAR(50)   NOT NULL,
            COUNTY_NAME        VARCHAR(300)  NOT NULL,
            STATE_CD           VARCHAR(50)   NOT NULL,
            RPT_SOURCE         VARCHAR(100)  NULL,
            RPT_SOURCE_DESC    VARCHAR(300)  NULL,
            DATE_REPORTED      DATETIME      NOT NULL,
            MONTH_REPORTED     VARCHAR(20)   NOT NULL,
            NOTIF_CREATE_DATE  DATETIME      NULL,
            NOTIF_CREATE_MONTH VARCHAR(20)   NULL,
            NOTIF_CREATE_YEAR  NUMERIC(4, 0) NULL,
            REPORT_COMMENTS    VARCHAR(2000) NULL,
            DATE_ADDED         DATETIME      NOT NULL,
            ADD_USER_NAME      VARCHAR(300)  NOT NULL,
            INVESTIGATION_KEY  BIGINT        NOT NULL
        )
    END;