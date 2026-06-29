-- Regression test for RTR APP-737:
-- sp_d_lab_test_postprocessing builds LAB_TEST.RECORD_STATUS_CD from
--     COALESCE(#merge_order.RECORD_STATUS_CD_MERGE,
--              #hierarchical_data.RECORD_STATUS_CD_FOR_RESULT_DRUG)
-- (routine 018 line ~550). The first source (#merge_order, line ~495) is
-- NORMALIZED ('PROCESSED'/''/NULL/UNPROCESSED* -> 'ACTIVE', 'LOG_DEL' ->
-- 'INACTIVE'). The fallback (#hierarchical_data, line ~411) is the RAW
-- nrt_observation.record_status_cd of the report_sprt/refr/observation
-- ancestor and is NOT normalized. When a lab test's root_ordered_test_pntr
-- resolves to NULL, the #merge_order join misses (NULL <> NULL) so
-- RECORD_STATUS_CD_MERGE is NULL and the COALESCE falls through to the raw
-- fallback. If that ancestor carries record_status_cd='PROCESSED', the raw
-- 'PROCESSED' is inserted into dbo.LAB_TEST.RECORD_STATUS_CD, violating
-- CHECK constraint CHK_LABTEST_RECORD_STATUS (RECORD_STATUS_CD IN
-- ('ACTIVE','INACTIVE')) -> Error 547 at the "INSERTING new entries to
-- LAB_TEST" step (~line 909) -> the whole obs batch fails fast.
--
-- This is why the working zz_covid_lab_datamart_unblock.sql fixture (which
-- also uses obs record_status_cd='PROCESSED') does NOT 547: its simple
-- Order/Result chain resolves root_ordered_test_pntr, so #merge_order
-- matches and the NORMALIZED 'ACTIVE' wins before the raw fallback is ever
-- reached. The new lab fixture's deeper hierarchy yields a NULL
-- root_ordered_test_pntr, exposing the un-normalized fallback.
--
-- Minimal repro of that exact shape, seeding nrt_observation directly (the
-- table routine 018 reads): an I_Result lab test (22053701) whose
-- report_observation_uid -> parent P (22053702); P has report_sprt_uid and
-- report_observation_uid NULL (so root_ordered_test_pntr = NULL -> merge_order
-- miss) but report_refr_uid -> R (22053703) which carries raw 'PROCESSED'.
-- Pre-fix: 547. Post-fix (normalize the fallback): LAB_TEST row inserted with
-- RECORD_STATUS_CD='ACTIVE'.

USE RDB_MODERN;

INSERT INTO dbo.nrt_observation
    (observation_uid, obs_domain_cd_st_1, ctrl_cd_display_form, record_status_cd,
     version_ctrl_nbr, report_observation_uid, report_refr_uid, report_sprt_uid, cd, status_cd)
VALUES
    -- T: the lab test obs in the input list. report_observation_uid -> P.
    (22053701, 'I_Result', 'LabReport', 'PROCESSED', 1, 22053702, NULL, NULL, 'LABX', 'A'),
    -- P: parent_test. report_sprt_uid + report_observation_uid NULL => I_Result
    --    root_ordered_test_pntr = COALESCE(NULL, NULL) = NULL (merge_order miss).
    --    report_refr_uid -> R drives RECORD_STATUS_CD_FOR_RESULT_DRUG.
    (22053702, 'I_Result', 'LabReport', 'PROCESSED', 1, NULL, 22053703, NULL, 'LABP', 'A'),
    -- R: refr ancestor carrying the RAW, un-normalized 'PROCESSED'.
    (22053703, 'I_Order',  'LabReport', 'PROCESSED', 1, NULL, NULL, NULL, 'LABR', 'A');

EXEC dbo.sp_d_lab_test_postprocessing @obs_ids = N'22053701', @debug = 0;
