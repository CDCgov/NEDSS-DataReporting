IF NOT EXISTS (SELECT 1 FROM sysobjects  WHERE name = 'CASE_LAB_DATAMART' and xtype = 'U')
    BEGIN
        CREATE TABLE [dbo].[CASE_LAB_DATAMART]
        (

            [INVESTIGATION_KEY]              [bigint]         NOT NULL,
            [PATIENT_LOCAL_ID]               [varchar](50)    NULL,
            [INVESTIGATION_LOCAL_ID]         [varchar](50)    NULL,
            [PATIENT_FIRST_NM]               [varchar](50)    NULL,
            [PATIENT_MIDDLE_NM]              [varchar](50)    NULL,
            [PATIENT_LAST_NM]                [varchar](50)    NULL,
            [PATIENT_STREET_ADDRESS_1]       [varchar](100)   NULL,
            [PATIENT_STREET_ADDRESS_2]       [varchar](100)   NULL,
            [PATIENT_CITY]                   [varchar](100)   NULL,
            [PATIENT_STATE]                  [varchar](100)   NULL,
            [PATIENT_ZIP]                    [varchar](20)    NULL,
            [PATIENT_COUNTY]                 [varchar](300)   NULL,
            [PATIENT_HOME_PHONE]             [varchar](50)    NULL,
            [PATIENT_DOB]                    [datetime]       NULL,
            [AGE_REPORTED]                   [numeric](18, 0) NULL,
            [AGE_REPORTED_UNIT]              [varchar](50)    NULL,
            [PATIENT_CURRENT_SEX]            [varchar](50)    NULL,
            [RACE]                           [varchar](500)   NULL,
            [JURISDICTION_NAME]              [varchar](100)   NULL,
            [PROGRAM_AREA_DESCRIPTION]       [varchar](50)    NULL,
            [INVESTIGATION_START_DATE]       [datetime]       NULL,
            [CASE_STATUS]                    [varchar](50)    NULL,
            [DISEASE]                        [varchar](50)    NULL,
            [DISEASE_CD]                     [varchar](50)    NULL,
            [REPORTING_SOURCE]               [varchar](100)   NULL,
            [GENERAL_COMMENTS]               [varchar](2000)  NULL,
            [PHYSICIAN_NAME]                 [varchar](102)   NULL,
            [PHYSICIAN_PHONE]                [varchar](46)    NULL,
            [LABORATORY_INFORMATION]         [varchar](4000)  NULL,
            [PROGRAM_JURISDICTION_OID]       [numeric](18, 0) NULL,
            [PHC_ADD_TIME]                   [datetime]       NULL,
            [PHC_LAST_CHG_TIME]              [datetime]       NULL,
            [EVENT_DATE]                     [datetime]       NULL,
            [EARLIEST_SPECIMEN_COLLECT_DATE] [datetime]       NULL,
            [EVENT_DATE_TYPE]                [varchar](200)   NULL
        ) ON [PRIMARY];
    END