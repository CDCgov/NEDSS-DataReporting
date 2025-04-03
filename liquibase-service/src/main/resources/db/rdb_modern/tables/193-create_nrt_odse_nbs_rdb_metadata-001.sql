IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_odse_NBS_rdb_metadata' and xtype = 'U')
   BEGIN
        CREATE TABLE [dbo].[nrt_odse_NBS_rdb_metadata] (
            [nbs_rdb_metadata_uid] [bigint] NOT NULL,
            [nbs_page_uid] [bigint] NULL,
            [nbs_ui_metadata_uid] [bigint] NOT NULL,
            [rdb_table_nm] [varchar](30) NULL,
            [user_defined_column_nm] [varchar](30) NULL,
            [record_status_cd] [varchar](20) NOT NULL,
            [record_status_time] [datetime] NOT NULL,
            [last_chg_user_id] [bigint] NOT NULL,
            [last_chg_time] [datetime] NOT NULL,
            [local_id] [varchar](50) NULL,
            [rpt_admin_column_nm] [varchar](50) NULL,
            [rdb_column_nm] [varchar](30) NULL,
            [block_pivot_nbr] [int] NULL,
            CONSTRAINT [PK_nrt_odse_NBS_rdb_metadata] PRIMARY KEY CLUSTERED (
                [nbs_rdb_metadata_uid] ASC
            ) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
        ) ON [PRIMARY];

        CREATE NONCLUSTERED INDEX [RDB_PERF_RDB_TBL_NM] ON [dbo].[nrt_odse_NBS_rdb_metadata] (
            [rdb_table_nm] ASC
        )
        INCLUDE (
            [nbs_ui_metadata_uid],
            [rdb_column_nm]
        ) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
        ON [PRIMARY];

        CREATE NONCLUSTERED INDEX [RDB_PERF_UID_RDB_TBL_NM] ON [dbo].[nrt_odse_NBS_rdb_metadata] (
            [nbs_ui_metadata_uid] ASC,
            [rdb_table_nm] ASC
        )
        INCLUDE (
            [rdb_column_nm]
        ) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
        ON [PRIMARY];

        CREATE NONCLUSTERED INDEX [RDB_PERF_UID] ON [dbo].[nrt_odse_NBS_rdb_metadata](
            [nbs_ui_metadata_uid] ASC
        )
        INCLUDE (
            [rdb_column_nm]
        ) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
        ON [PRIMARY];

    END;
