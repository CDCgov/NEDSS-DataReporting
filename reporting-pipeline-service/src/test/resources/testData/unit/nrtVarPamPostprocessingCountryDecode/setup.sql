-- ============================================================
-- sp_nrt_d_var_pam_postprocessing
-- Verifies country decode and non-country coded decode in D_VAR_PAM
--   1) PATIENT_BIRTH_COUNTRY: 124 -> Canada
--   2) EPI_LINKED: Y -> Yes (from CODE_VALUE_GENERAL.code_short_desc_txt)
-- ============================================================

USE [RDB_Modern];

DECLARE @phc_uid BIGINT = 99009901;
DECLARE @condition_cd VARCHAR(20) = 'ZZZVARCTRYTEST';
DECLARE @country_group_id BIGINT = 990001;
DECLARE @epi_group_id BIGINT = 990002;

-- Ensure deterministic test rows for reruns within the same environment.
DELETE FROM dbo.D_VAR_PAM WHERE VAR_PAM_UID = @phc_uid;
DELETE FROM dbo.nrt_var_pam_key WHERE VAR_PAM_UID = @phc_uid;
DELETE FROM dbo.nrt_page_case_answer WHERE act_uid = @phc_uid;
DELETE FROM dbo.nrt_investigation WHERE public_health_case_uid = @phc_uid;
DELETE FROM dbo.nrt_srte_condition_code WHERE condition_cd = @condition_cd;
DELETE FROM dbo.nrt_srte_codeset_group_metadata WHERE code_set_group_id IN (@country_group_id, @epi_group_id);
DELETE FROM dbo.nrt_srte_country_code WHERE code = '124';
DELETE FROM dbo.nrt_srte_code_value_general WHERE code_set_nm = 'VAR_EPI_TEST' AND code = 'Y';

INSERT INTO dbo.nrt_srte_condition_code (
    condition_cd,
    investigation_form_cd,
    nnd_ind,
    reportable_morbidity_ind,
    reportable_summary_ind
)
VALUES (
    @condition_cd,
    'INV_FORM_VAR',
    'N',
    'N',
    'N'
);

INSERT INTO dbo.nrt_investigation (
    public_health_case_uid,
    cd,
    investigation_form_cd,
    last_chg_time
)
VALUES (
    @phc_uid,
    @condition_cd,
    'INV_FORM_VAR',
    '2026-06-23T00:00:00'
);

INSERT INTO dbo.nrt_srte_codeset_group_metadata (code_set_group_id, code_set_nm)
VALUES
    (@country_group_id, 'PSL_CNTRY'),
    (@epi_group_id, 'VAR_EPI_TEST');

INSERT INTO dbo.nrt_srte_country_code (code, code_desc_txt)
VALUES ('124', 'Canada');

INSERT INTO dbo.nrt_srte_code_value_general (
    code_set_nm,
    code,
    code_short_desc_txt
)
VALUES (
    'VAR_EPI_TEST',
    'Y',
    'Yes'
);

INSERT INTO dbo.nrt_page_case_answer (
    act_uid,
    nbs_case_answer_uid,
    nbs_ui_metadata_uid,
    nbs_rdb_metadata_uid,
    nbs_question_uid,
    answer_txt,
    data_location,
    code_set_group_id,
    datamart_column_nm,
    nbs_ui_component_uid,
    record_status_cd,
    last_chg_time
)
VALUES
    (
        @phc_uid,
        990099011,
        990099021,
        990099031,
        990099041,
        '124',
        'NBS_Case_Answer.answer_txt',
        @country_group_id,
        'PATIENT_BIRTH_COUNTRY',
        990099051,
        'ACTIVE',
        '2026-06-23T00:00:00'
    ),
    (
        @phc_uid,
        990099012,
        990099022,
        990099032,
        990099042,
        'Y',
        'NBS_Case_Answer.answer_txt',
        @epi_group_id,
        'EPI_LINKED',
        990099052,
        'ACTIVE',
        '2026-06-23T00:00:00'
    );

EXEC dbo.sp_nrt_d_var_pam_postprocessing @phc_uids = '99009901';
