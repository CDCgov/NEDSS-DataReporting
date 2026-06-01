-- Create the LAB100 table if it does not exist
IF OBJECT_ID('[dbo].[LAB100]', 'U') IS NULL
    BEGIN
        CREATE TABLE [dbo].LAB100 (
            LAB_RPT_LOCAL_ID [varchar](50) NOT NULL,
            RESULTED_LAB_TEST_CD [varchar](50) NULL,
            PROGRAM_JURISDICTION_OID [bigint] NULL,
            RECORD_STATUS_CD [varchar](8) NULL,
            RESULTED_LAB_TEST_CD_DESC [varchar](1000) NULL,
            RESULTEDTEST_CD_SYS_NM [varchar](100) NULL,
            RESULTEDTEST_VAL_CD [varchar](20) NULL,
            RESULTEDTEST_VAL_CD_DESC [varchar](1000) NULL,
            NUMERIC_RESULT_WITHUNITS [varchar](50) NULL,
            LAB_RESULT_TXT_VAL [varchar](2000) NULL,
            LAB_RESULT_COMMENTS [varchar](2000) NULL,
            RESULT_REF_RANGE_FRM [varchar](20) NULL,
            RESULT_REF_RANGE_TO [varchar](20) NULL,
            ALT_LAB_TEST_CD [varchar](50) NULL,
            ALT_LAB_TEST_CD_DESC [varchar](1000) NULL,
            ALT_LAB_TEST_CD_SYS_CD [varchar](50) NULL,
            ALT_LAB_TEST_CD_SYS_NM [varchar](100) NULL,
            PATIENT_KEY [bigint] NULL,
            ACCESSION_NBR [varchar](100) NULL,
            JURISDICTION_CD [varchar](20) NULL,
            JURISDICTION_NM [varchar](32) NULL,
            ORDERING_FACILITY [varchar](100) NULL,
            REPORTING_FACILITY [varchar](100) NULL,
            LAB_TEST_STATUS [varchar](50) NULL,
            ELR_IND [varchar](1) NULL,
            ORDERED_LAB_TEST_CD [varchar](50) NULL,
            ORDERED_LAB_TEST_CD_DESC [varchar](1000) NULL,
            ORDERED_LABTEST_CD_SYS_NM [varchar](100) NULL,
            CONDITION_CD [varchar](72) NULL,
            CONDITION_SHORT_NM [varchar](50) NULL,
            PROGRAM_AREA_CD [varchar](20) NULL,
            PROGRAM_AREA_DESC [varchar](33) NULL,
            SPECIMEN_COLLECTION_DT [datetime] NULL,
            SPECIMEN_SRC_DESC [varchar](100) NULL,
            SPECIMEN_SRC_CD [varchar](50) NULL,
            LAB_TEST_DT [datetime] NULL,
            LAB_RPT_CREATED_DT [datetime] NULL,
            LAB_RPT_LAST_UPDATE_DT [datetime] NULL,
            LAB_RPT_RECEIVED_BY_PH_DT [datetime] NULL,
            LAB_RPT_STATUS [varchar](50) NULL,
            REASON_FOR_TEST_DESC [varchar](4000) NULL,
            PERSON_LOCAL_ID [varchar](50) NULL,
            PERSON_FIRST_NM [varchar](50) NULL,
            PERSON_MIDDLE_NM [varchar](50) NULL,
            PERSON_LAST_NM [varchar](50) NULL,
            PERSON_DOB [datetime] NULL,
            AGE_REPORTED [numeric](18, 0) NULL,
            PATIENT_REPORTED_AGE_UNITS [varchar](20) NULL,
            PERSON_CURR_GENDER [varchar](1) NULL,
            PATIENT_ADDRESS [varchar](725) NULL,
            ADDR_USE_CD_DESC [varchar](1000) NULL,
            ADDR_CD_DESC [varchar](1000) NULL,
            PATIENT_CITY [varchar](50) NULL,
            PATIENT_COUNTY [varchar](50) NULL,
            PATIENT_STATE [varchar](50) NULL,
            PATIENT_ZIP_CODE [varchar](20) NULL,
            ADDRESS_DATE [datetime] NULL,
            ORDERING_PROVIDER_NM [varchar](50) NULL,
            PROVIDER_ADDRESS [varchar](725) NULL,
            PRV_ADDR_USE_CD_DESC [varchar](1000) NULL,
            PRV_ADDR_CD_DESC [varchar](1000) NULL,
            PROVIDER_PHONE [varchar](50) NULL,
            RESULTED_LAB_TEST_KEY [bigint] NULL,
            MORB_RPT_KEY [bigint] NULL,
            LDF_GROUP_KEY [bigint] NULL,
            INVESTIGATION_KEYS [varchar](1000) NULL,
            EVENT_DATE [datetime] NULL,
            REPORTING_FACILITY_UID [bigint] NULL,
            RDB_LAST_REFRESH_TIME [datetime] NULL,
            [Document_link] [varchar](500) NULL
        )
    END
GO

-- Add the Document_link column if it doesn't already exist
IF
    NOT EXISTS (
        SELECT 1 FROM SYS.COLUMNS
        WHERE OBJECT_ID = OBJECT_ID('[dbo].[LAB100]') AND NAME = 'Document_link'
    )
    BEGIN
        ALTER TABLE [dbo].LAB100 ADD [Document_link] [varchar](500) NULL
    END
GO
