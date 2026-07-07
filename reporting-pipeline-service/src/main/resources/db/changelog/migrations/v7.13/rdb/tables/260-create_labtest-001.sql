-- Create the LAB_TEST table if it does not exist
IF OBJECT_ID('[dbo].[LAB_TEST]', 'U') IS NULL
    BEGIN
        CREATE TABLE [dbo].LAB_TEST (
            LAB_TEST_STATUS [varchar](50) NULL,
            LAB_TEST_KEY [bigint] NOT NULL,
            LAB_RPT_LOCAL_ID [varchar](50) NULL,
            TEST_METHOD_CD [varchar](20) NULL,
            TEST_METHOD_CD_DESC [varchar](100) NULL,
            LAB_RPT_SHARE_IND [varchar](50) NULL,
            LAB_TEST_CD [varchar](1000) NULL,
            ELR_IND [varchar](50) NULL,
            LAB_RPT_UID [bigint] NULL,
            LAB_TEST_CD_DESC [varchar](2000) NULL,
            INTERPRETATION_FLG [varchar](20) NULL,
            LAB_RPT_RECEIVED_BY_PH_DT [datetime] NULL,
            LAB_RPT_CREATED_BY [bigint] NULL,
            REASON_FOR_TEST_DESC [varchar](4000) NULL,
            REASON_FOR_TEST_CD [varchar](4000) NULL,
            LAB_RPT_LAST_UPDATE_BY [bigint] NULL,
            LAB_TEST_DT [datetime] NULL,
            LAB_RPT_CREATED_DT [datetime] NULL,
            LAB_TEST_TYPE [varchar](50) NULL,
            LAB_RPT_LAST_UPDATE_DT [datetime] NULL,
            JURISDICTION_CD [varchar](20) NULL,
            LAB_TEST_CD_SYS_CD [varchar](50) NULL,
            LAB_TEST_CD_SYS_NM [varchar](100) NULL,
            JURISDICTION_NM [varchar](50) NULL,
            OID [bigint] NULL,
            ALT_LAB_TEST_CD [varchar](50) NULL,
            LAB_RPT_STATUS [char](1) NULL,
            DANGER_CD_DESC [varchar](100) NULL,
            ALT_LAB_TEST_CD_DESC [varchar](1000) NULL,
            ACCESSION_NBR [varchar](100) NULL,
            SPECIMEN_SRC [varchar](50) NULL,
            PRIORITY_CD [varchar](20) NULL,
            ALT_LAB_TEST_CD_SYS_CD [varchar](50) NULL,
            ALT_LAB_TEST_CD_SYS_NM [varchar](100) NULL,
            SPECIMEN_SITE [varchar](20) NULL,
            SPECIMEN_DETAILS [varchar](1000) NULL,
            DANGER_CD [varchar](20) NULL,
            SPECIMEN_COLLECTION_VOL [varchar](20) NULL,
            SPECIMEN_COLLECTION_VOL_UNIT [varchar](50) NULL,
            SPECIMEN_DESC [varchar](1000) NULL,
            SPECIMEN_SITE_DESC [varchar](100) NULL,
            CLINICAL_INFORMATION [varchar](1000) NULL,
            LAB_TEST_UID [bigint] NULL,
            ROOT_ORDERED_TEST_PNTR [bigint] NULL,
            PARENT_TEST_PNTR [bigint] NULL,
            LAB_TEST_PNTR [bigint] NULL,
            SPECIMEN_ADD_TIME [datetime] NULL,
            SPECIMEN_LAST_CHANGE_TIME [datetime] NULL,
            SPECIMEN_COLLECTION_DT [datetime] NULL,
            SPECIMEN_NM [varchar](100) NULL,
            ROOT_ORDERED_TEST_NM [varchar](1000) NULL,
            PARENT_TEST_NM [varchar](1000) NULL,
            TRANSCRIPTIONIST_NAME [varchar](300) NULL,
            TRANSCRIPTIONIST_ID [varchar](100) NULL,
            TRANSCRIPTIONIST_ASS_AUTH_CD [varchar](199) NULL,
            TRANSCRIPTIONIST_ASS_AUTH_TYPE [varchar](100) NULL,
            ASSISTANT_INTERPRETER_NAME [varchar](300) NULL,
            ASSISTANT_INTERPRETER_ID [varchar](100) NULL,
            ASSISTANT_INTER_ASS_AUTH_CD [varchar](199) NULL,
            ASSISTANT_INTER_ASS_AUTH_TYPE [varchar](100) NULL,
            RESULT_INTERPRETER_NAME [varchar](300) NULL,
            RECORD_STATUS_CD [varchar](8) NOT NULL,
            RDB_LAST_REFRESH_TIME [datetime] NULL,
            CONDITION_CD [varchar](20) NULL,
            PROCESSING_DECISION_CD [varchar](50) NULL,
            PROCESSING_DECISION_DESC [varchar](50) NULL,
            [Document_link] [varchar](500) NULL
        )
    END
GO

-- Add the document_link column if it doesn't already exist
IF
    NOT EXISTS (
        SELECT 1 FROM SYS.COLUMNS
        WHERE
            OBJECT_ID = OBJECT_ID('[dbo].[LAB_TEST]') AND NAME = 'Document_link'
    )
    BEGIN
        ALTER TABLE [dbo].LAB_TEST ADD [Document_link] [varchar](500) NULL
    END
GO
