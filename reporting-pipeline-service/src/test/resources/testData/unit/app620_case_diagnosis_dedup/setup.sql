USE RDB_MODERN;

-- APP-620: sp_s_pagebuilder_postprocessing built the coded-answer string with a
-- FOR XML PATH('') concat that had no DISTINCT, so two nbs_case_answer rows sharing the
-- same (page_case_uid, nbs_question_uid) and identical answer text produced a doubled,
-- pipe-delimited value (e.g. "730 - Syphilis | 730 - Syphilis") in DM_INV_STD.CASE_DIAGNOSIS.
-- This fixture seeds exactly that duplicate condition and runs the SP; query.sql asserts the
-- value is deduped to a single entry.

-- Disable FK constraints during seed (baseline tables have FKs our private-namespace rows don't satisfy).
EXEC sp_MSforeachtable 'ALTER TABLE ? NOCHECK CONSTRAINT ALL';

-- Private UID/codeset namespace (1000620xxx) to avoid colliding with baseline / functional-test data.
DECLARE @csg         bigint       = 1000620001;  -- code_set_group_id
DECLARE @q           bigint       = 1000620002;  -- nbs_question_uid
DECLARE @act         bigint       = 1000620003;  -- page_case_uid / act_uid
DECLARE @ca1         bigint       = 1000620004;  -- nbs_case_answer_uid (row 1)
DECLARE @ca2         bigint       = 1000620005;  -- nbs_case_answer_uid (row 2 - the duplicate)
DECLARE @ui_meta     bigint       = 1000620006;
DECLARE @ui_comp     bigint       = 1000620007;
DECLARE @form        varchar(50)  = 'APP620_FORM';
DECLARE @code_set_nm varchar(256) = 'APP620_DX';
DECLARE @code        varchar(20)  = '99730';
DECLARE @desc        varchar(100) = '99730 - SyphilisTest';

-- Cleanup any prior remnants from this UID space.
DELETE FROM dbo.NRT_PAGE_CASE_ANSWER        WHERE act_uid = @act;
DELETE FROM dbo.NRT_ODSE_NBS_UI_METADATA    WHERE nbs_ui_metadata_uid = @ui_meta;
DELETE FROM dbo.NRT_SRTE_CODE_VALUE_GENERAL WHERE code_set_nm = @code_set_nm;
DELETE FROM dbo.NRT_SRTE_CODESET            WHERE code_set_nm = @code_set_nm;

-- Reference data so v_nrt_ref_formcode_translation resolves the coded answer to a description.
INSERT INTO dbo.NRT_SRTE_CODESET (code_set_group_id, code_set_nm, class_cd)
VALUES (@csg, @code_set_nm, 'APP620');

INSERT INTO dbo.NRT_SRTE_CODE_VALUE_GENERAL (code_set_nm, code, code_short_desc_txt)
VALUES (@code_set_nm, @code, @desc);

INSERT INTO dbo.NRT_ODSE_NBS_UI_METADATA
    (nbs_ui_metadata_uid, nbs_ui_component_uid, version_ctrl_nbr, investigation_form_cd,
     code_set_group_id, nbs_question_uid, question_identifier)
VALUES (@ui_meta, @ui_comp, 1, @form, @csg, @q, 'APP620_Q');

-- Two NRT_PAGE_CASE_ANSWER rows: distinct nbs_case_answer_uid, identical answer_txt, same
-- (act_uid, nbs_question_uid). Pre-fix these doubled in the FOR XML concat for CASE_DIAGNOSIS.
-- refresh_datetime / max_datetime are GENERATED ALWAYS, so they are omitted from the column list.
INSERT INTO dbo.NRT_PAGE_CASE_ANSWER
    (act_uid, nbs_case_answer_uid, nbs_ui_metadata_uid, nbs_question_uid, rdb_table_nm, rdb_column_nm,
     answer_txt, answer_group_seq_nbr, investigation_form_cd, data_type, question_group_seq_nbr,
     code_set_group_id, record_status_cd, batch_id)
VALUES
    (@act, @ca1, @ui_meta, @q, 'DM_INV_STD', 'CASE_DIAGNOSIS', @code, NULL, @form, 'CODED', NULL,
     @csg, 'ACTIVE', NULL),
    (@act, @ca2, @ui_meta, @q, 'DM_INV_STD', 'CASE_DIAGNOSIS', @code, NULL, @form, 'CODED', NULL,
     @csg, 'ACTIVE', NULL);

EXEC sp_MSforeachtable 'ALTER TABLE ? CHECK CONSTRAINT ALL';

-- Run the read-path post-processing SP. It pivots the coded answers into dbo.S_APP620,
-- where the CASE_DIAGNOSIS column holds the (now deduped) answer description.
EXEC dbo.sp_s_pagebuilder_postprocessing
     @Batch_id       = 1000620000,
     @phc_id_list    = '1000620003',
     @rdb_table_name = 'DM_INV_STD',
     @category       = 'APP620',
     @debug          = 0;
