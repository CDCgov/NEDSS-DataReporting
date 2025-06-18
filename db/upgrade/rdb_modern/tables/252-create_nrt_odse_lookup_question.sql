IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_odse_lookup_question' and xtype = 'U')
    BEGIN
        CREATE TABLE [dbo].[nrt_odse_lookup_question] (
                                                          [lookup_question_uid] [bigint] NOT NULL,
                                                          [FROM_QUESTION_IDENTIFIER] [varchar](250) NULL,
                                                          [FROM_QUESTION_DISPLAY_NAME] [varchar](250) NULL,
                                                          [FROM_CODE_SYSTEM_CD] [varchar](250) NULL,
                                                          [FROM_CODE_SYSTEM_DESC_TXT] [varchar](250) NULL,
                                                          [FROM_DATA_TYPE] [varchar](250) NULL,
                                                          [FROM_CODE_SET] [varchar](250) NULL,
                                                          [FROM_FORM_CD] [varchar](250) NULL,
                                                          [TO_QUESTION_IDENTIFIER] [varchar](250) NULL,
                                                          [TO_QUESTION_DISPLAY_NAME] [varchar](250) NULL,
                                                          [TO_CODE_SYSTEM_CD] [varchar](250) NULL,
                                                          [TO_CODE_SYSTEM_DESC_TXT] [varchar](250) NULL,
                                                          [TO_DATA_TYPE] [varchar](250) NULL,
                                                          [TO_CODE_SET] [varchar](250) NULL,
                                                          [TO_FORM_CD] [varchar](250) NULL,
                                                          [RDB_COLUMN_NM] [varchar](30) NULL,
                                                          [ADD_TIME] [datetime] NULL,
                                                          [ADD_USER_ID] [bigint] NULL,
                                                          [LAST_CHG_TIME] [datetime] NULL,
                                                          [LAST_CHG_USER_ID] [bigint] NULL,
                                                          [STATUS_CD] [varchar](1) NULL,
                                                          [STATUS_TIME] [datetime] NULL,

                                                          CONSTRAINT [PK_nrt_odse_lookup_question] PRIMARY KEY CLUSTERED (
                                                                                                                          [lookup_question_uid] ASC
                                                              ) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
        ) ON [PRIMARY];

        -- Create performance indexes based on actual column names
        CREATE NONCLUSTERED INDEX [RDB_PERF_FROM_FORM_CD] ON [dbo].[nrt_odse_lookup_question] (
                                                                                               [FROM_FORM_CD] ASC
            )
            INCLUDE (
                     [RDB_COLUMN_NM],
                     [FROM_QUESTION_IDENTIFIER],
                     [FROM_CODE_SET]
                ) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
            ON [PRIMARY];

        CREATE NONCLUSTERED INDEX [RDB_PERF_FROM_QUESTION_ID] ON [dbo].[nrt_odse_lookup_question] (
                                                                                                   [FROM_QUESTION_IDENTIFIER] ASC
            )
            INCLUDE (
                     [RDB_COLUMN_NM],
                     [FROM_FORM_CD],
                     [FROM_CODE_SET]
                ) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
            ON [PRIMARY];

        PRINT 'nrt_odse_lookup_question table created successfully with correct structure';
    END
ELSE
    BEGIN
        PRINT 'nrt_odse_lookup_question table already exists';
    END