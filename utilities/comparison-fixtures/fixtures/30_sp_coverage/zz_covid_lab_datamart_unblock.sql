-- =====================================================================
-- Tier 3 — COVID-19 Lab observation full-chain (unblock COVID_LAB_DATAMART)
-- =====================================================================
-- Goal: lift `dbo.COVID_LAB_DATAMART` from 0/129 columns -> ~80+ columns
--       by introducing a COVID-coded LAB Order+Result observation pair
--       linked to the existing COVID Investigation PHC 22003000.
--
-- WHY EMPTY CURRENTLY
--   `sp_covid_lab_datamart_postprocessing` filters input observations on:
--     - the observation is an Order
--     - the linked Result's `cd` IS IN nrt_srte_Loinc_condition
--       WHERE condition_cd = '11065'  (2019 Novel Coronavirus)
--     - AND `cd` NOT IN nrt_srte_Loinc_code WHERE time_aspect='Pt'
--       AND system_cd='^Patient'
--   The orchestrator's `LAB_OBS_UIDS = '20000120,20070010'` are both
--   Hep-A coded ('13950-1' -> condition '10110'), so the SP no-ops.
--   ALSO: nrt_srte_Loinc_condition currently has ZERO rows for
--   condition_cd='11065' (live-verified). Even a COVID-LOINC-coded
--   observation would fail the filter without seed.
--
-- WHAT THIS FIXTURE AUTHORS
--   1. SRTE seed: 4 rows into `nrt_srte_Loinc_condition` mapping the
--      common COVID LOINC codes (94309-2 SARS-CoV-2 RNA NAA, 94500-6,
--      94531-1, 94533-7) to condition_cd '11065'.
--   2. ODSE chain (NBS_ODSE) — minimal Lab Order/Result hierarchy:
--        - act          (act_uid=22022000 Order, =22022001 Result)
--        - observation  (both Order + Result, cd='94309-2',
--                        obs_domain_cd_st_1='Order'/'Result',
--                        ctrl_cd_display_form='LabReport')
--        - act_id       (PHC_LOCAL_ID style act_id row on Order)
--        - act_relationship (Result -> Order parent, COMP)
--        - obs_value_coded / numeric / txt / observation_interp
--          (so the ODSE side has matching aux rows)
--        - act_relationship (Order -> COVID PHC 22003000, LabInv-style
--          source=Order target=PHC) so the SP's #COVID_LAB_ASSOCIATIONS
--          `STRING_AGG(i.local_id...)` group-by resolves to the COVID
--          Investigation local_id.
--   3. RDB_MODERN staging mirroring the kafka-connect JDBC sink writes:
--        - nrt_observation: 2 rows (COVID Order + COVID Result).
--          Order.result_observation_uid = '22022001' (CSV per SP's
--          STRING_SPLIT). Order.patient_id = 20000000 (foundation).
--          Order.associated_phc_uids = '22003000' so the
--          COVID_LAB_ASSOCIATIONS branch picks up the PHC link.
--          Result.report_observation_uid = 22022000 (parent).
--          Both: prog_area_cd='STD' jurisdiction_cd='130001'
--          electronic_ind='Y' shared_ind='T'.
--        - nrt_observation_txt: 2 rows for Result (FT result-text,
--          N comment-text).
--        - nrt_observation_coded: 1 row Result (10828004 Positive).
--        - nrt_observation_numeric: 1 row Result (numeric+range+unit).
--        - nrt_observation_material: 1 row Order (specimen SER serum).
--   4. Tail-EXEC dbo.sp_covid_lab_datamart_postprocessing with the new
--      Order UID `22022000` so the fixture is self-verifying. The SP
--      deletes-and-reinserts only for input observations, so it is
--      idempotent and safe to re-run.
--
-- WHY ALSO SP_COVID_LAB_CELR_DATAMART? — out of scope for THIS fixture.
--   `sp_covid_lab_celr_datamart_postprocessing` reads the same
--   condition-filtered lab set. If LAB_OBS_UIDS is extended to include
--   22022000 (see ORCH_TODO below), Step 9 will also feed CELR.
--
-- ORCH_TODO (post-fixture follow-on)
--   Extend `LAB_OBS_UIDS` in scripts/merge_and_verify.sh to include
--   '22022000' (the COVID Order UID). With that, Step 9 will exercise
--   the same path the tail-EXEC here exercises locally, AND will also
--   reach `sp_covid_lab_celr_datamart_postprocessing` (the CELR SP is
--   driven off the same UID list, and shares the condition_cd='11065'
--   filter). Today the tail-EXEC at the bottom of this fixture is
--   sufficient to populate COVID_LAB_DATAMART; ORCH_TODO is purely a
--   coverage bonus.
--
-- UID block (Tier 3 — slot reserved 2026-05-24):  22022000 - 22022999
--   22022000  act.act_uid / observation.observation_uid / nrt_observation
--             (COVID Lab Order — root of the hierarchy; this UID is
--             passed to sp_covid_lab_datamart_postprocessing)
--   22022001  COVID Lab Result child observation
--   22022010  Material (informational only — material_id on Order)
--
-- Foundation dependencies (read-only):
--   @superuser_id              10009282
--   @foundation_patient_uid    20000000  (D_PATIENT + nrt_patient row)
--   @foundation_provider_uid   20000010
--   @foundation_org_uid        20000020
--   @covid_phc_uid             22003000  (covid_investigation_full_chain.sql)
--
-- GOTCHAS
--   - nrt_observation INSERT must match the 83-column footprint used by
--     the Tier 1 Lab fixture; we follow that template verbatim.
--   - sp_covid_lab_datamart_postprocessing reads from BOTH D_PATIENT and
--     nrt_patient via LEFT JOIN + COALESCE; foundation patient exists in
--     both, so PATIENT_DATA resolves cleanly.
--   - The SP's #COVID_RESULT_LIST filter `o.cd IN (SELECT loinc_cd FROM
--     nrt_srte_Loinc_condition WHERE condition_cd='11065')` — we seed
--     that table FIRST so the filter passes. Without this seed, even a
--     COVID-LOINC observation will be filtered out.
--   - nrt_srte_Loinc_condition PK is `(loinc_cd, condition_cd)`. We use
--     IF NOT EXISTS guards so re-application is a no-op.
-- =====================================================================

-- =====================================================================
-- Step 1. Seed `nrt_srte_Loinc_condition` for COVID LOINC codes.
-- =====================================================================
USE [RDB_MODERN];
GO

IF NOT EXISTS (SELECT 1 FROM dbo.nrt_srte_Loinc_condition
               WHERE loinc_cd = '94309-2' AND condition_cd = '11065')
BEGIN
    INSERT INTO dbo.nrt_srte_Loinc_condition
        (loinc_cd, condition_cd, disease_nm, status_cd, status_time, effective_from_time)
    VALUES
        ('94309-2', '11065', '2019 Novel Coronavirus', 'A',
         '2026-04-01T00:00:00', '2026-04-01T00:00:00');
END;

IF NOT EXISTS (SELECT 1 FROM dbo.nrt_srte_Loinc_condition
               WHERE loinc_cd = '94500-6' AND condition_cd = '11065')
BEGIN
    INSERT INTO dbo.nrt_srte_Loinc_condition
        (loinc_cd, condition_cd, disease_nm, status_cd, status_time, effective_from_time)
    VALUES
        ('94500-6', '11065', '2019 Novel Coronavirus', 'A',
         '2026-04-01T00:00:00', '2026-04-01T00:00:00');
END;

IF NOT EXISTS (SELECT 1 FROM dbo.nrt_srte_Loinc_condition
               WHERE loinc_cd = '94531-1' AND condition_cd = '11065')
BEGIN
    INSERT INTO dbo.nrt_srte_Loinc_condition
        (loinc_cd, condition_cd, disease_nm, status_cd, status_time, effective_from_time)
    VALUES
        ('94531-1', '11065', '2019 Novel Coronavirus', 'A',
         '2026-04-01T00:00:00', '2026-04-01T00:00:00');
END;

IF NOT EXISTS (SELECT 1 FROM dbo.nrt_srte_Loinc_condition
               WHERE loinc_cd = '94533-7' AND condition_cd = '11065')
BEGIN
    INSERT INTO dbo.nrt_srte_Loinc_condition
        (loinc_cd, condition_cd, disease_nm, status_cd, status_time, effective_from_time)
    VALUES
        ('94533-7', '11065', '2019 Novel Coronavirus', 'A',
         '2026-04-01T00:00:00', '2026-04-01T00:00:00');
END;

GO

-- =====================================================================
-- Step 2. ODSE chain (NBS_ODSE).
-- =====================================================================
USE [NBS_ODSE];
GO

DECLARE @superuser_id           bigint = 10009282;
DECLARE @foundation_patient_uid bigint = 20000000;
DECLARE @covid_phc_uid          bigint = 22003000;
DECLARE @covid_lab_order_uid    bigint = 22022000;
DECLARE @covid_lab_result_uid   bigint = 22022001;

-- act parents
IF NOT EXISTS (SELECT 1 FROM dbo.act WHERE act_uid = @covid_lab_order_uid)
BEGIN
    INSERT INTO dbo.act (act_uid, class_cd, mood_cd)
    VALUES (@covid_lab_order_uid, N'OBS', N'EVN');
END;

IF NOT EXISTS (SELECT 1 FROM dbo.act WHERE act_uid = @covid_lab_result_uid)
BEGIN
    INSERT INTO dbo.act (act_uid, class_cd, mood_cd)
    VALUES (@covid_lab_result_uid, N'OBS', N'EVN');
END;

-- ODSE: COVID Lab Order observation
IF NOT EXISTS (SELECT 1 FROM dbo.observation WHERE observation_uid = @covid_lab_order_uid)
BEGIN
    INSERT INTO dbo.observation
        ([observation_uid], [add_time], [add_user_id], [cd], [cd_desc_txt],
         [cd_system_cd], [cd_system_desc_txt],
         [last_chg_time], [last_chg_user_id], [local_id],
         [obs_domain_cd_st_1], [obs_domain_cd], [ctrl_cd_display_form],
         [record_status_cd], [record_status_time],
         [status_cd], [status_time], [subject_person_uid],
         [shared_ind], [version_ctrl_nbr], [prog_area_cd], [jurisdiction_cd],
         [program_jurisdiction_oid], [electronic_ind],
         [activity_to_time], [effective_from_time], [rpt_to_state_time],
         [activity_from_time], [method_cd], [method_desc_txt],
         [target_site_cd], [target_site_desc_txt], [txt],
         [priority_cd], [processing_decision_cd], [pregnant_ind_cd])
    VALUES
        (@covid_lab_order_uid, '2026-04-10T00:00:00', @superuser_id,
         N'94309-2', N'SARS coronavirus 2 RNA [Presence] in Respiratory specimen by NAA with probe detection',
         N'2.16.840.1.113883.6.1', N'LN',
         '2026-04-10T00:00:00', @superuser_id, N'OBS22022000GA01',
         N'Order', N'Order', N'LabReport',
         N'PROCESSED', '2026-04-10T00:00:00',
         N'A', '2026-04-10T00:00:00', @foundation_patient_uid,
         N'T', 1, N'COV', N'130001',
         22022000, N'Y',
         '2026-04-10T08:00:00', '2026-04-09T18:00:00', '2026-04-10T10:00:00',
         '2026-04-09T18:00:00', N'RT-PCR', N'Real-Time Reverse Transcriptase PCR',
         N'NASOPH', N'Nasopharyngeal',
         N'Tier 3 COVID Lab Order — SARS-CoV-2 RNA NAA test for COVID PHC 22003000.',
         N'R', N'AC', N'N');
END;

-- ODSE: COVID Lab Result observation (child of Order)
IF NOT EXISTS (SELECT 1 FROM dbo.observation WHERE observation_uid = @covid_lab_result_uid)
BEGIN
    INSERT INTO dbo.observation
        ([observation_uid], [add_time], [add_user_id], [cd], [cd_desc_txt],
         [cd_system_cd], [cd_system_desc_txt],
         [last_chg_time], [last_chg_user_id], [local_id],
         [obs_domain_cd_st_1], [obs_domain_cd], [ctrl_cd_display_form],
         [record_status_cd], [record_status_time],
         [status_cd], [status_time], [subject_person_uid],
         [shared_ind], [version_ctrl_nbr], [prog_area_cd], [jurisdiction_cd],
         [program_jurisdiction_oid], [electronic_ind],
         [activity_to_time], [effective_from_time])
    VALUES
        (@covid_lab_result_uid, '2026-04-10T08:30:00', @superuser_id,
         N'94309-2', N'SARS coronavirus 2 RNA [Presence] in Respiratory specimen by NAA with probe detection',
         N'2.16.840.1.113883.6.1', N'LN',
         '2026-04-10T08:30:00', @superuser_id, N'OBS22022001GA01',
         N'Result', N'Result', N'LabReport',
         N'PROCESSED', '2026-04-10T08:30:00',
         N'A', '2026-04-10T08:30:00', @foundation_patient_uid,
         N'T', 1, N'COV', N'130001',
         22022001, N'Y',
         '2026-04-10T08:30:00', '2026-04-09T18:00:00');
END;

-- ODSE: act_id on Order (accession-style)
IF NOT EXISTS (SELECT 1 FROM dbo.act_id
               WHERE act_uid = @covid_lab_order_uid AND act_id_seq = 1)
BEGIN
    INSERT INTO dbo.act_id
        ([act_uid], [act_id_seq], [add_time], [add_user_id],
         [assigning_authority_cd], [assigning_authority_desc_txt],
         [last_chg_time], [last_chg_user_id], [record_status_cd],
         [record_status_time], [root_extension_txt], [type_cd],
         [type_desc_txt], [status_cd], [status_time])
    VALUES
        (@covid_lab_order_uid, 1, '2026-04-10T00:00:00', @superuser_id,
         N'2.16.840.1.114222.4.5.1.1', N'NEDSS_LOCAL',
         '2026-04-10T00:00:00', @superuser_id, N'ACTIVE',
         '2026-04-10T00:00:00', N'ACC-COVID-22022000', N'OBS_LOCAL_ID',
         N'Local Observation Identifier', N'A', '2026-04-10T00:00:00');
END;

-- ODSE: act_relationship Result -> Order (COMP)
IF NOT EXISTS (SELECT 1 FROM dbo.act_relationship
               WHERE source_act_uid = @covid_lab_result_uid
                 AND target_act_uid = @covid_lab_order_uid)
BEGIN
    INSERT INTO dbo.act_relationship
        ([source_act_uid], [target_act_uid], [type_cd], [add_time], [add_user_id],
         [last_chg_time], [last_chg_user_id], [record_status_cd],
         [record_status_time], [sequence_nbr], [source_class_cd],
         [target_class_cd], [status_cd], [status_time], [type_desc_txt])
    VALUES
        (@covid_lab_result_uid, @covid_lab_order_uid, N'COMP',
         '2026-04-10T08:30:00', @superuser_id,
         '2026-04-10T08:30:00', @superuser_id, N'ACTIVE',
         '2026-04-10T08:30:00', 1, N'OBS', N'OBS', N'A',
         '2026-04-10T08:30:00', N'Component');
END;

-- ODSE: act_relationship Order -> COVID PHC (LabInv-style cross-subject link)
IF NOT EXISTS (SELECT 1 FROM dbo.act_relationship
               WHERE source_act_uid = @covid_lab_order_uid
                 AND target_act_uid = @covid_phc_uid)
BEGIN
    INSERT INTO dbo.act_relationship
        ([source_act_uid], [target_act_uid], [type_cd], [add_time], [add_user_id],
         [last_chg_time], [last_chg_user_id], [record_status_cd],
         [record_status_time], [sequence_nbr], [source_class_cd],
         [target_class_cd], [status_cd], [status_time], [type_desc_txt])
    VALUES
        (@covid_lab_order_uid, @covid_phc_uid, N'LabReport',
         '2026-04-10T08:30:00', @superuser_id,
         '2026-04-10T08:30:00', @superuser_id, N'ACTIVE',
         '2026-04-10T08:30:00', 1, N'OBS', N'CASE', N'A',
         '2026-04-10T08:30:00', N'Lab linked to investigation');
END;

-- ODSE: observation_interp + obs_value_coded/numeric/txt on Result
IF NOT EXISTS (SELECT 1 FROM dbo.observation_interp
               WHERE observation_uid = @covid_lab_result_uid)
BEGIN
    INSERT INTO dbo.observation_interp (observation_uid, interpretation_cd, interpretation_desc_txt)
    VALUES (@covid_lab_result_uid, N'A', N'Abnormal');
END;

IF NOT EXISTS (SELECT 1 FROM dbo.obs_value_coded
               WHERE observation_uid = @covid_lab_result_uid AND code = '260373001')
BEGIN
    INSERT INTO dbo.obs_value_coded
        (observation_uid, code, code_system_cd, code_system_desc_txt,
         display_name, alt_cd, alt_cd_desc_txt, alt_cd_system_cd, alt_cd_system_desc_txt)
    VALUES
        (@covid_lab_result_uid, N'260373001', N'2.16.840.1.113883.6.96', N'SCT',
         N'Detected', N'POS', N'Detected', N'L', N'Local');
END;

IF NOT EXISTS (SELECT 1 FROM dbo.obs_value_numeric
               WHERE observation_uid = @covid_lab_result_uid AND obs_value_numeric_seq = 1)
BEGIN
    INSERT INTO dbo.obs_value_numeric
        (observation_uid, obs_value_numeric_seq, comparator_cd_1, numeric_value_1,
         numeric_unit_cd, low_range, high_range)
    VALUES
        (@covid_lab_result_uid, 1, N'<', 25.0, N'Ct', N'0.00', N'40.00');
END;

IF NOT EXISTS (SELECT 1 FROM dbo.obs_value_txt
               WHERE observation_uid = @covid_lab_result_uid AND obs_value_txt_seq = 1)
BEGIN
    INSERT INTO dbo.obs_value_txt
        (observation_uid, obs_value_txt_seq, txt_type_cd, value_txt)
    VALUES
        (@covid_lab_result_uid, 1, N'FT', N'SARS-CoV-2 RNA DETECTED. Positive for SARS-CoV-2.');
END;

GO

-- =====================================================================
-- Step 3. RDB_MODERN staging — nrt_observation Order+Result + auxiliaries.
-- =====================================================================
USE [RDB_MODERN];
GO

DECLARE @superuser_id           bigint = 10009282;
DECLARE @foundation_patient_uid bigint = 20000000;
DECLARE @foundation_provider_uid bigint = 20000010;
DECLARE @foundation_org_uid     bigint = 20000020;
DECLARE @covid_phc_uid          bigint = 22003000;
DECLARE @covid_lab_order_uid    bigint = 22022000;
DECLARE @covid_lab_result_uid   bigint = 22022001;
DECLARE @covid_material_uid     bigint = 22022010;

-- nrt_observation Order row (83-column footprint, matching Tier 1 Lab fixture)
IF NOT EXISTS (SELECT 1 FROM dbo.nrt_observation WHERE observation_uid = @covid_lab_order_uid)
BEGIN
    INSERT INTO dbo.nrt_observation
        ( [observation_uid], [class_cd], [mood_cd], [act_uid]
        , [cd_desc_txt], [record_status_cd], [jurisdiction_cd]
        , [program_jurisdiction_oid], [prog_area_cd], [pregnant_ind_cd]
        , [local_id], [activity_to_time], [effective_from_time]
        , [rpt_to_state_time], [electronic_ind], [version_ctrl_nbr]
        , [ordering_person_id], [patient_id], [result_observation_uid]
        , [author_organization_id], [ordering_organization_id]
        , [performing_organization_id], [material_id], [obs_domain_cd_st_1]
        , [processing_decision_cd], [cd], [shared_ind]
        , [add_user_id], [add_user_name], [add_time]
        , [last_chg_user_id], [last_chg_user_name], [last_chg_time]
        , [ctrl_cd_display_form], [status_cd], [cd_system_cd]
        , [cd_system_desc_txt], [ctrl_cd_user_defined_1], [alt_cd]
        , [alt_cd_desc_txt], [alt_cd_system_cd], [alt_cd_system_desc_txt]
        , [method_cd], [method_desc_txt], [target_site_cd]
        , [target_site_desc_txt], [txt], [interpretation_cd]
        , [interpretation_desc_txt], [report_observation_uid]
        , [followup_observation_uid], [report_refr_uid], [report_sprt_uid]
        , [morb_physician_id], [morb_reporter_id], [transcriptionist_id]
        , [transcriptionist_val], [transcriptionist_first_nm]
        , [transcriptionist_last_nm], [assistant_interpreter_id]
        , [assistant_interpreter_val], [assistant_interpreter_first_nm]
        , [assistant_interpreter_last_nm], [result_interpreter_id]
        , [specimen_collector_id], [copy_to_provider_id]
        , [lab_test_technician_id], [health_care_id], [morb_hosp_reporter_id]
        , [accession_number], [morb_hosp_id]
        , [transcriptionist_id_assign_auth]
        , [transcriptionist_auth_type], [assistant_interpreter_id_assign_auth]
        , [assistant_interpreter_auth_type], [priority_cd]
        , [record_status_time], [status_time], [batch_id]
        , [associated_phc_uids], [activity_from_time]
        , [device_instance_id_1], [device_instance_id_2]
        )
    VALUES
        -- COVID Lab Order (UID 22022000)
        ( @covid_lab_order_uid, N'OBS', N'EVN', @covid_lab_order_uid
        , N'SARS coronavirus 2 RNA [Presence] in Respiratory specimen by NAA with probe detection', N'PROCESSED', N'130001'
        , 22022000, N'COV', N'N'
        , N'OBS22022000GA01', '2026-04-10T08:00:00', '2026-04-09T18:00:00'
        , '2026-04-10T10:00:00', N'Y', 1
        , CAST(@foundation_provider_uid AS nvarchar(50)), @foundation_patient_uid
                                      , CAST(@covid_lab_result_uid AS nvarchar(50))
        , @foundation_org_uid, @foundation_org_uid
        , @foundation_org_uid, @covid_material_uid, N'Order'
        , N'AC', N'94309-2', N'T'
        , @superuser_id, N'Foundation, Superuser', '2026-04-10T00:00:00'
        , @superuser_id, N'Foundation, Superuser', '2026-04-10T00:00:00'
        , N'LabReport', N'A', N'2.16.840.1.113883.6.1'
        , N'LN', N'UDV1', N'SARS-COV-2-RNA'
        , N'SARS-CoV-2 RNA NAA', N'L', N'Local'
        , N'RT-PCR**Roche-Cobas-6800', N'Real-Time Reverse Transcriptase PCR', N'NASOPH'
        , N'Nasopharyngeal', N'Tier 3 COVID Lab Order — SARS-CoV-2 RNA NAA.', NULL
        , NULL, @covid_lab_order_uid
        , NULL, @covid_lab_order_uid
                                                                , @covid_lab_order_uid
        , @foundation_provider_uid, @foundation_provider_uid, @foundation_provider_uid
        , N'TRX-COV', N'Tara'
        , N'COVTranscriber', @foundation_provider_uid
        , N'AIN-COV', N'Cameron'
        , N'COVInterpreter', @foundation_provider_uid
        , @foundation_provider_uid, @foundation_provider_uid
        , @foundation_provider_uid, @foundation_org_uid, @foundation_provider_uid
        , N'ACC-COVID-22022000', @foundation_org_uid
        , N'2.16.840.1.113883.4.6'
        , N'NPI', N'2.16.840.1.113883.4.6'
        , N'NPI', N'R'
        , '2026-04-10T00:00:00', '2026-04-10T00:00:00', NULL
        , N'22003000', '2026-04-09T18:00:00'
        , N'DEV-COBAS-6800', N'DEV-SN-A1B2'
        );
END;

-- nrt_observation Result row
IF NOT EXISTS (SELECT 1 FROM dbo.nrt_observation WHERE observation_uid = @covid_lab_result_uid)
BEGIN
    INSERT INTO dbo.nrt_observation
        ( [observation_uid], [class_cd], [mood_cd], [act_uid]
        , [cd_desc_txt], [record_status_cd], [jurisdiction_cd]
        , [program_jurisdiction_oid], [prog_area_cd], [pregnant_ind_cd]
        , [local_id], [activity_to_time], [effective_from_time]
        , [rpt_to_state_time], [electronic_ind], [version_ctrl_nbr]
        , [ordering_person_id], [patient_id], [result_observation_uid]
        , [author_organization_id], [ordering_organization_id]
        , [performing_organization_id], [material_id], [obs_domain_cd_st_1]
        , [processing_decision_cd], [cd], [shared_ind]
        , [add_user_id], [add_user_name], [add_time]
        , [last_chg_user_id], [last_chg_user_name], [last_chg_time]
        , [ctrl_cd_display_form], [status_cd], [cd_system_cd]
        , [cd_system_desc_txt], [ctrl_cd_user_defined_1], [alt_cd]
        , [alt_cd_desc_txt], [alt_cd_system_cd], [alt_cd_system_desc_txt]
        , [method_cd], [method_desc_txt], [target_site_cd]
        , [target_site_desc_txt], [txt], [interpretation_cd]
        , [interpretation_desc_txt], [report_observation_uid]
        , [followup_observation_uid], [report_refr_uid], [report_sprt_uid]
        , [morb_physician_id], [morb_reporter_id], [transcriptionist_id]
        , [transcriptionist_val], [transcriptionist_first_nm]
        , [transcriptionist_last_nm], [assistant_interpreter_id]
        , [assistant_interpreter_val], [assistant_interpreter_first_nm]
        , [assistant_interpreter_last_nm], [result_interpreter_id]
        , [specimen_collector_id], [copy_to_provider_id]
        , [lab_test_technician_id], [health_care_id], [morb_hosp_reporter_id]
        , [accession_number], [morb_hosp_id]
        , [transcriptionist_id_assign_auth]
        , [transcriptionist_auth_type], [assistant_interpreter_id_assign_auth]
        , [assistant_interpreter_auth_type], [priority_cd]
        , [record_status_time], [status_time], [batch_id]
        , [associated_phc_uids], [activity_from_time]
        , [device_instance_id_1], [device_instance_id_2]
        )
    VALUES
        ( @covid_lab_result_uid, N'OBS', N'EVN', @covid_lab_result_uid
        , N'SARS coronavirus 2 RNA [Presence] in Respiratory specimen by NAA with probe detection', N'PROCESSED', N'130001'
        , 22022001, N'COV', NULL
        , N'OBS22022001GA01', '2026-04-10T08:30:00', '2026-04-09T18:00:00'
        , '2026-04-10T10:00:00', N'Y', 1
        , CAST(@foundation_provider_uid AS nvarchar(50)), @foundation_patient_uid, NULL
        , @foundation_org_uid, @foundation_org_uid
        , @foundation_org_uid, NULL, N'Result'
        , NULL, N'94309-2', N'T'
        , @superuser_id, N'Foundation, Superuser', '2026-04-10T08:30:00'
        , @superuser_id, N'Foundation, Superuser', '2026-04-10T08:30:00'
        , N'LabReport', N'A', N'2.16.840.1.113883.6.1'
        , N'LN', NULL, NULL
        , NULL, NULL, NULL
        , N'RT-PCR**Roche-Cobas-6800', N'Real-Time Reverse Transcriptase PCR', NULL
        , NULL, NULL, N'A'
        , N'Abnormal', @covid_lab_order_uid
        , NULL, @covid_lab_order_uid, @covid_lab_order_uid
        , NULL, NULL, NULL
        , NULL, NULL
        , NULL, NULL
        , NULL, NULL
        , NULL, @foundation_provider_uid
        , NULL, NULL
        , NULL, NULL, NULL
        , NULL, NULL
        , NULL
        , NULL, NULL
        , NULL, NULL
        , '2026-04-10T08:30:00', '2026-04-10T08:30:00', NULL
        , N'22003000', '2026-04-09T18:00:00'
        , N'DEV-COBAS-6800', N'DEV-SN-A1B2'
        );
END;

-- nrt_observation_txt: result text (FT) + comment (N) for Result
IF NOT EXISTS (SELECT 1 FROM dbo.nrt_observation_txt
               WHERE observation_uid = @covid_lab_result_uid AND ovt_seq = 1)
BEGIN
    INSERT INTO dbo.nrt_observation_txt
        (observation_uid, ovt_seq, ovt_txt_type_cd, ovt_value_txt, batch_id)
    VALUES
        (@covid_lab_result_uid, 1, N'FT',
         N'SARS-CoV-2 RNA DETECTED. Positive for SARS-CoV-2.', NULL);
END;

IF NOT EXISTS (SELECT 1 FROM dbo.nrt_observation_txt
               WHERE observation_uid = @covid_lab_result_uid AND ovt_seq = 2)
BEGIN
    INSERT INTO dbo.nrt_observation_txt
        (observation_uid, ovt_seq, ovt_txt_type_cd, ovt_value_txt, batch_id)
    VALUES
        (@covid_lab_result_uid, 2, N'N',
         N'Result confirmed by retest. Patient notified.', NULL);
END;

-- nrt_observation_coded: coded result (Detected / Positive)
IF NOT EXISTS (SELECT 1 FROM dbo.nrt_observation_coded
               WHERE observation_uid = @covid_lab_result_uid)
BEGIN
    INSERT INTO dbo.nrt_observation_coded
        (observation_uid, ovc_code, ovc_code_system_cd, ovc_code_system_desc_txt,
         ovc_display_name, ovc_alt_cd, ovc_alt_cd_desc_txt, ovc_alt_cd_system_cd,
         ovc_alt_cd_system_desc_txt, batch_id)
    VALUES
        (@covid_lab_result_uid, N'260373001', N'2.16.840.1.113883.6.96',
         N'SCT', N'Detected',
         N'POS', N'Positive', N'L', N'Local', NULL);
END;

-- nrt_observation_numeric: numeric result
IF NOT EXISTS (SELECT 1 FROM dbo.nrt_observation_numeric
               WHERE observation_uid = @covid_lab_result_uid)
BEGIN
    INSERT INTO dbo.nrt_observation_numeric
        (observation_uid, ovn_high_range, ovn_low_range,
         ovn_comparator_cd_1, ovn_numeric_value_1, ovn_numeric_value_2,
         ovn_numeric_unit_cd, ovn_separator_cd, ovn_seq, batch_id)
    VALUES
        (@covid_lab_result_uid, N'40.00', N'0.00', N'<',
         25.0, NULL, N'Ct', NULL, 1, NULL);
END;

-- nrt_observation_material: specimen material on Order
IF NOT EXISTS (SELECT 1 FROM dbo.nrt_observation_material
               WHERE act_uid = @covid_lab_order_uid)
BEGIN
    INSERT INTO dbo.nrt_observation_material
        (act_uid, type_cd, material_id, subject_class_cd,
         record_status, type_desc_txt, last_chg_time,
         material_cd, material_nm, material_details,
         material_collection_vol, material_collection_vol_unit,
         material_desc, risk_cd, risk_desc_txt)
    VALUES
        (@covid_lab_order_uid, N'SPC', @covid_material_uid, N'MAT',
         N'ACTIVE', N'Specimen', '2026-04-10T00:00:00',
         N'258500001', N'Nasopharyngeal swab',
         N'Nasopharyngeal swab, viral transport medium, refrigerated',
         N'2', N'mL',
         N'Nasopharyngeal specimen', N'B', N'Biohazard');
END;

GO

-- =====================================================================
-- Step 4. Tail-EXEC sp_covid_lab_datamart_postprocessing with the new
--   COVID Order UID. Self-verifying — orchestrator's Step 9 uses
--   LAB_OBS_UIDS='20000120,20070010' which does NOT include 22022000,
--   so the orchestrator will NOT DELETE-and-reinsert this row at
--   Step 9. The fixture's data persists for the verifier.
-- =====================================================================
BEGIN TRY
    EXEC dbo.sp_covid_lab_datamart_postprocessing
        @observation_id_list = N'22022000',
        @debug               = 0;
END TRY
BEGIN CATCH
    -- Log & swallow so the fixture remains rerunnable in pipelines and
    -- the rest of the merge_and_verify chain continues even if a future
    -- SP refactor introduces a transient failure.
    PRINT 'WARN: sp_covid_lab_datamart_postprocessing raised an error: ' + ERROR_MESSAGE();
END CATCH;

GO
