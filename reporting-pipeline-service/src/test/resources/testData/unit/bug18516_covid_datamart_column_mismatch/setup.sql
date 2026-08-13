-- NBS Central #18516 - sp_covid_case_datamart_postprocessing fails at step 18 with
-- SQL Server error 120 ("The select list for the INSERT statement contains fewer
-- items than the insert list").
--
-- Step 18 builds its INSERT dynamically. The INSERT column list comes from the
-- pivot temp tables; the SELECT list comes from the same temp tables INNER JOINed
-- to the columns of dbo.COVID_CASE_DATAMART. Any temp column missing from the
-- target table is therefore dropped from the SELECT and kept in the INSERT.
--
-- Four of the five ALTER TABLE guards that keep the target table in sync resolve
-- the COVID investigation form from nrt_srte_CONDITION_CODE.investigation_form_cd,
-- the same value the pivots use. The multi-string guard (step 10) instead joins
-- dbo.condition on disease_grp_cd. When those two disagree, step 10 adds nothing
-- while step 11 still pivots the columns in, and step 18 dies.
--
-- This seeds a state-customized COVID page to make them disagree. It does not
-- modify dbo.condition, which the restored image already ships with
-- condition_cd 11065 / disease_grp_cd 'PG_COVID-19_v1.1'.
--
-- Key band: 18516xxx.

USE RDB_MODERN;

DELETE FROM [RDB_MODERN].[dbo].[COVID_CASE_DATAMART] WHERE public_health_case_uid = 18516289;
DELETE FROM [RDB_MODERN].[dbo].[NRT_ODSE_NBS_RDB_METADATA] WHERE nbs_rdb_metadata_uid BETWEEN 18516001 AND 18516099;
DELETE FROM [RDB_MODERN].[dbo].[NRT_ODSE_NBS_UI_METADATA] WHERE nbs_ui_metadata_uid BETWEEN 18516001 AND 18516099;
DELETE FROM [RDB_MODERN].[dbo].[nrt_srte_CONDITION_CODE] WHERE condition_cd = '11065';
DELETE FROM [RDB_MODERN].[dbo].[NRT_INVESTIGATION] WHERE public_health_case_uid = 18516289;

-- The COVID investigation being reprocessed. Only public_health_case_uid and cd
-- matter to step 1; refresh_datetime / max_datetime are GENERATED ALWAYS.
INSERT INTO [dbo].[NRT_INVESTIGATION] ([public_health_case_uid], [cd], [record_status_cd])
VALUES (18516289, N'11065', N'ACTIVE');

-- @inv_form_cd. A state-customized COVID page, so it no longer equals
-- dbo.condition.disease_grp_cd for condition 11065.
INSERT INTO [dbo].[nrt_srte_CONDITION_CODE]
    ([condition_cd], [investigation_form_cd], [nnd_ind], [reportable_morbidity_ind], [reportable_summary_ind])
VALUES (N'11065', N'PG_COVID-19_v1.1_CUSTOM', N'N', N'N', N'N');

-- (a) Discrete question. Step 7's guard uses @inv_form_cd, so this column is added.
INSERT INTO [dbo].[NRT_ODSE_NBS_UI_METADATA]
    ([nbs_ui_metadata_uid], [nbs_ui_component_uid], [nbs_question_uid], [investigation_form_cd],
     [question_group_seq_nbr], [data_location], [question_identifier], [question_label], [version_ctrl_nbr])
VALUES (18516001, 1007, 18516001, N'PG_COVID-19_v1.1_CUSTOM',
        NULL, N'NBS_CASE_ANSWER.ANSWER_TXT', N'CUSTOM001', N'Custom discrete question', 1);
INSERT INTO [dbo].[NRT_ODSE_NBS_RDB_METADATA]
    ([nbs_rdb_metadata_uid], [nbs_ui_metadata_uid], [user_defined_column_nm], [rdb_table_nm],
     [record_status_cd], [record_status_time], [last_chg_user_id], [last_chg_time])
VALUES (18516001, 18516001, N'CUSTOM_DISCRETE_COL', N'D_INV_CLINICAL',
        N'ACTIVE', GETDATE(), 1, GETDATE());

-- (b) Repeating-block question. Steps 12/14/16 also use @inv_form_cd, so the
--     _1/_2/_3 columns are added. Present so every pivot group contributes at
--     least one column and the generated statement stays syntactically valid.
INSERT INTO [dbo].[NRT_ODSE_NBS_UI_METADATA]
    ([nbs_ui_metadata_uid], [nbs_ui_component_uid], [nbs_question_uid], [investigation_form_cd],
     [question_group_seq_nbr], [data_location], [question_identifier], [question_label], [version_ctrl_nbr])
VALUES (18516002, 1007, 18516002, N'PG_COVID-19_v1.1_CUSTOM',
        1, N'NBS_CASE_ANSWER.ANSWER_TXT', N'CUSTOM002', N'Custom repeating question', 1);
INSERT INTO [dbo].[NRT_ODSE_NBS_RDB_METADATA]
    ([nbs_rdb_metadata_uid], [nbs_ui_metadata_uid], [user_defined_column_nm], [rdb_table_nm],
     [record_status_cd], [record_status_time], [last_chg_user_id], [last_chg_time])
VALUES (18516002, 18516002, N'CUSTOM_REPEAT_COL', N'D_INV_CLINICAL',
        N'ACTIVE', GETDATE(), 1, GETDATE());

-- (c) Multi-string question configured long ago, back when the form codes still
--     matched. Its datamart column already exists, so the multi-string group is
--     non-empty at step 18 and the count gap is what surfaces, not a syntax error.
INSERT INTO [dbo].[NRT_ODSE_NBS_UI_METADATA]
    ([nbs_ui_metadata_uid], [nbs_ui_component_uid], [nbs_question_uid], [investigation_form_cd],
     [question_group_seq_nbr], [data_location], [question_identifier], [question_label], [version_ctrl_nbr])
VALUES (18516003, 1013, 18516003, N'PG_COVID-19_v1.1_CUSTOM',
        NULL, N'NBS_CASE_ANSWER.ANSWER_TXT', N'CUSTOM003', N'Established multi-select question', 1);
INSERT INTO [dbo].[NRT_ODSE_NBS_RDB_METADATA]
    ([nbs_rdb_metadata_uid], [nbs_ui_metadata_uid], [user_defined_column_nm], [rdb_table_nm],
     [record_status_cd], [record_status_time], [last_chg_user_id], [last_chg_time])
VALUES (18516003, 18516003, N'MULTI_ANS_ESTABLISHED_COL', N'D_INV_CLINICAL',
        N'ACTIVE', GETDATE(), 1, GETDATE());

-- (d) Multi-string question configured recently. Step 11 pivots this column into
--     the temp table, step 10's guard never returns it, so COVID_CASE_DATAMART
--     never gets it. This is the column that breaks step 18.
INSERT INTO [dbo].[NRT_ODSE_NBS_UI_METADATA]
    ([nbs_ui_metadata_uid], [nbs_ui_component_uid], [nbs_question_uid], [investigation_form_cd],
     [question_group_seq_nbr], [data_location], [question_identifier], [question_label], [version_ctrl_nbr])
VALUES (18516004, 1013, 18516004, N'PG_COVID-19_v1.1_CUSTOM',
        NULL, N'NBS_CASE_ANSWER.ANSWER_TXT', N'CUSTOM004', N'Newly added multi-select question', 1);
INSERT INTO [dbo].[NRT_ODSE_NBS_RDB_METADATA]
    ([nbs_rdb_metadata_uid], [nbs_ui_metadata_uid], [user_defined_column_nm], [rdb_table_nm],
     [record_status_cd], [record_status_time], [last_chg_user_id], [last_chg_time])
VALUES (18516004, 18516004, N'MULTI_ANS_NEW_COL', N'D_INV_CLINICAL',
        N'ACTIVE', GETDATE(), 1, GETDATE());

-- The established multi-string column, as an earlier successful run left it.
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
               WHERE TABLE_NAME = 'COVID_CASE_DATAMART' AND TABLE_SCHEMA = 'dbo'
                 AND COLUMN_NAME = 'MULTI_ANS_ESTABLISHED_COL')
    ALTER TABLE [dbo].[COVID_CASE_DATAMART] ADD MULTI_ANS_ESTABLISHED_COL varchar(8000);

-- The SP swallows its own error into JOB_FLOW_LOG, so this EXEC does not throw.
EXEC RDB_MODERN.DBO.SP_COVID_CASE_DATAMART_POSTPROCESSING '18516289';
