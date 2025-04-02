IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'nrt_odse_NBS_ui_metadata' and xtype = 'U')
   BEGIN
        CREATE TABLE [dbo].[nrt_odse_NBS_ui_metadata] (
            [nbs_ui_metadata_uid] [bigint] NOT NULL,
            [nbs_ui_component_uid] [bigint] NOT NULL,
            [nbs_question_uid] [bigint] NULL,
            [parent_uid] [bigint] NULL,
            [add_time] [datetime] NULL,
            [add_user_id] [bigint] NULL,
            [admin_comment] [varchar](2000) NULL,
            [css_style] [varchar](50) NULL,
            [default_value] [varchar](2000) NULL,
            [display_ind] [varchar](1) NULL,
            [enable_ind] [varchar](1) NULL,
            [field_size] [varchar](10) NULL,
            [investigation_form_cd] [varchar](50) NULL,
            [last_chg_time] [datetime] NULL,
            [last_chg_user_id] [bigint] NULL,
            [ldf_position] [varchar](10) NULL,
            [ldf_page_id] [varchar](20) NULL,
            [ldf_status_cd] [varchar](20) NULL,
            [ldf_status_time] [datetime] NULL,
            [max_length] [bigint] NULL,
            [order_nbr] [int] NULL,
            [question_label] [varchar](300) NULL,
            [question_tool_tip] [varchar](2000) NULL,
            [required_ind] [varchar](2) NULL,
            [record_status_cd] [varchar](20) NULL,
            [record_status_time] [datetime] NULL,
            [tab_order_id] [int] NULL,
            [tab_name] [varchar](50) NULL,
            [version_ctrl_nbr] [int] NOT NULL,
            [future_date_ind_cd] [char](1) NULL,
            [nbs_table_uid] [bigint] NULL,
            [code_set_group_id] [bigint] NULL,
            [data_cd] [varchar](50) NULL,
            [data_location] [varchar](150) NULL,
            [data_type] [varchar](20) NULL,
            [data_use_cd] [varchar](20) NULL,
            [legacy_data_location] [varchar](150) NULL,
            [part_type_cd] [varchar](50) NULL,
            [question_group_seq_nbr] [int] NULL,
            [question_identifier] [varchar](50) NULL,
            [question_oid] [varchar](150) NULL,
            [question_oid_system_txt] [varchar](100) NULL,
            [question_unit_identifier] [varchar](20) NULL,
            [repeats_ind_cd] [char](1) NULL,
            [unit_parent_identifier] [varchar](20) NULL,
            [group_nm] [varchar](50) NULL,
            [sub_group_nm] [varchar](50) NULL,
            [desc_txt] [varchar](256) NULL,
            [mask] [varchar](50) NULL,
            [min_value] [bigint] NULL,
            [max_value] [bigint] NULL,
            [nbs_page_uid] [bigint] NULL,
            [local_id] [varchar](50) NULL,
            [standard_nnd_ind_cd] [char](1) NULL,
            [unit_type_cd] [varchar](20) NULL,
            [unit_value] [varchar](50) NULL,
            [other_value_ind_cd] [char](1) NULL,
            [batch_table_appear_ind_cd] [char](1) NULL,
            [batch_table_header] [varchar](50) NULL,
            [batch_table_column_width] [int] NULL,
            [coinfection_ind_cd] [char](1) NULL,
            [block_nm] [varchar](30) NULL,
            CONSTRAINT [PK_NBS_UI_Metadata] PRIMARY KEY CLUSTERED (
                [nbs_ui_metadata_uid] ASC
            ) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
        ) ON [PRIMARY];

        CREATE NONCLUSTERED INDEX [RDB_PERF_GRP_SEQ_NBR] ON [dbo].[NBS_ui_metadata] (
            [question_group_seq_nbr] ASC
        )
        INCLUDE (
            [nbs_question_uid],
            [investigation_form_cd],
            [code_set_group_id],
            [data_type]
        ) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
        ON [PRIMARY];

        CREATE NONCLUSTERED INDEX [RDB_PERF_GRP_SEQ_NBR_DT] ON [dbo].[NBS_ui_metadata] (
            [question_group_seq_nbr] ASC,
            [data_type] ASC
        )
        INCLUDE (
            [nbs_question_uid],
            [investigation_form_cd],
            [code_set_group_id]
        ) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
        ON [PRIMARY];

        CREATE NONCLUSTERED INDEX [RDB_PERF_DT] ON [dbo].[NBS_ui_metadata] (
            [data_type] ASC
        )
        INCLUDE (
            [nbs_question_uid],
            [investigation_form_cd],
            [question_label],
            [data_location],
            [question_identifier]
        ) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
        ON [PRIMARY];

        CREATE NONCLUSTERED INDEX [RDB_PERF_INV_FRM_CD] ON [dbo].[NBS_ui_metadata] (
            [investigation_form_cd] ASC,
            [data_type] ASC
        )
        INCLUDE (
            [nbs_question_uid],
            [question_label],
            [data_location],
            [question_identifier]
        ) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
        ON [PRIMARY];

        CREATE NONCLUSTERED INDEX [RDB_PERF_GRP_SEQ_NBR_BLK] ON [dbo].[NBS_ui_metadata] (
            [question_group_seq_nbr] ASC
        )
        INCLUDE (
            [nbs_question_uid],
            [investigation_form_cd],
            [code_set_group_id],
            [data_type],
            [block_nm]
        ) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
        ON [PRIMARY];

        CREATE NONCLUSTERED INDEX [RDB_PERF_GRP_SEQ_NBR_OTH] ON [dbo].[NBS_ui_metadata] (
            [data_type] ASC,
            [question_group_seq_nbr] ASC
        )
        INCLUDE (
            [nbs_question_uid],
            [investigation_form_cd],
            [code_set_group_id],
            [other_value_ind_cd],[block_nm]
        ) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
        ON [PRIMARY];

        CREATE NONCLUSTERED INDEX [RDB_PERF_GRP_SEQ_NBR_UNIT] ON [dbo].[NBS_ui_metadata] (
            [question_group_seq_nbr] ASC
        )
        INCLUDE (
            [nbs_question_uid],
            [investigation_form_cd],
            [code_set_group_id],
            [data_type],
            [unit_type_cd],
            [unit_value],
            [block_nm]
        ) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON)
        ON [PRIMARY];

   END;
