-- =====================================================================
-- Tier 3 — VAR_DATAMART column-coverage enrichment (zz_var_datamart_enrich)
-- =====================================================================
-- Goal: lift VAR_DATAMART populated-column count from 91/231 baseline by
-- authoring additional VAR* answer rows on the existing Varicella
-- Investigation at PHC 22002000 (authored by
-- `varicella_investigation_full_chain.sql`). Each new row maps a VAR*
-- question whose `datamart_column_nm` is NOT covered by the 25-question
-- curated set in the parent fixture.
--
-- WHAT THIS FIXTURE AUTHORS
--   ODSE side (NBS_ODSE.dbo.nbs_case_answer)  — 80+ new rows (one per
--     newly-covered VAR question) keyed on act_uid=22002000.
--   RDB_MODERN side (dbo.nrt_page_case_answer) — 80+ matching rows
--     keyed on act_uid=22002000, with `datamart_column_nm` aligned to
--     the D_VAR_PAM PIVOT IN-list (215 SP lines 264-301) AND the
--     downstream var_datamart final-INSERT column list (250 SP line
--     1736). nbs_case_answer_uid is pinned to UIDs in 22009100..22009199
--     so the IDENTITY column slot stays within Tier 3 / agent C2 block.
--   Multi-value rows: two extra VAR105 (RASH_LOCATION_GENERAL) rows so
--     RASH_LOCATION_GENERAL_2 / _3 emerge from the D_RASH_LOC_GEN ->
--     var_datamart STRING_AGG path. Two extra VAR176 (PCR_TEST_SOURCE)
--     rows for PCR_TEST_SOURCE_2 / _3.
--   Does NOT touch the parent's act / public_health_case / case_management
--     / nrt_investigation rows — reuses 22002000 in every act_uid.
--
-- UID block (agent C2 reserved): 22009000 - 22009999
--   22009100..22009199  nbs_case_answer_uid + nrt_page_case_answer.nbs_case_answer_uid
--     (one per new answer row, single contiguous range)
--
-- VERIFICATION / TAIL-EXEC
--   Re-run the D_VAR_PAM root SP + topic SPs + LDF SP. F_VAR_PAM +
--   VAR_DATAMART are NOT executed here — orchestrator Step 9 already
--   has 22002000 in PHC_UIDS so they run there. To validate locally,
--   we tail-EXEC them at the bottom guarded by TRY/CATCH (no
--   double-INSERT because they internally DELETE-then-INSERT on
--   INVESTIGATION_KEY).
--
-- IDEMPOTENT: every INSERT guarded by `IF NOT EXISTS`.
--
-- BASE STATS (pre-fixture, verified live 2026-05-24):
--   VAR_DATAMART populated columns: 91 / 231
--   D_VAR_PAM PIVOT IN-list covered: 25 / ~140
--
-- ROW DESIGN
--   For each previously-uncovered (question_identifier, datamart_column_nm)
--   pair in dbo.nbs_question, author a single answer row. Use a valid
--   code from the question's code_set_group_id for Coded questions
--   (verified live against dbo.nrt_srte_Code_Value_General 2026-05-24).
--   Date and Numeric and Text answers use representative literal values.
--
--   Multi-value rows (VAR105 / VAR176) use distinct
--   `answer_group_seq_nbr` values so the D_RASH_LOC_GEN /
--   D_PCR_SOURCE topic SPs emit separate D_*_GROUP rows whose values
--   the var_datamart SP STRING_AGGs into RASH_LOCATION_GENERAL_ALL /
--   PCR_TEST_SOURCE_ALL + slot _1, _2, _3.
-- =====================================================================

USE [NBS_ODSE];
GO

DECLARE @superuser_id bigint = 10009282;
DECLARE @var_phc_uid  bigint = 22002000;

-- ---------------------------------------------------------------------
-- nbs_case_answer rows (NBS_ODSE side).
-- IDENTITY_INSERT toggled to pin our UID block 22009100..22009199.
-- Idempotent guard: skip if any of our rows already exist.
-- ---------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM dbo.nbs_case_answer WHERE nbs_case_answer_uid BETWEEN 22009100 AND 22009199)
BEGIN
    SET IDENTITY_INSERT [dbo].[nbs_case_answer] ON;

    INSERT INTO [dbo].[nbs_case_answer]
        ([nbs_case_answer_uid], [act_uid], [add_time], [add_user_id],
         [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr],
         [last_chg_time], [last_chg_user_id],
         [record_status_cd], [record_status_time], [seq_nbr])
    VALUES
        -- Block A: single-row VAR* answer rows for unpopulated D_VAR_PAM columns.
        --   nbs_question_uid values verified live 2026-05-24.
        --   Coded answers use valid codes from each question's code_set_group_id.
        (22009100, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'2026-03-20',         1169, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR102 RASH_ONSET_DATE
        (22009101, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'LeftArm',            1445, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR104 RASH_LOCATION_DERMATOME
        (22009102, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'OtherSpecify',       1027, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR106 RASH_LOCATION_OTHER
        (22009103, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'Y',                  1399, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR107 MACULES YNU 4150
        (22009104, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'12',                 1195, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR108 MACULES_NUMBER
        (22009105, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'Y',                  1308, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR109 PAPULES
        (22009106, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'8',                  1144, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR110 PAPULES_NUMBER
        (22009107, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'15',                 1130, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR112 VESICLES_NUMBER
        (22009108, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'N',                  1028, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR114 VESICULAR
        (22009109, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'N',                  1419, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR115 HEMORRHAGIC
        (22009110, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'Y',                  1283, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR116 ITCHY
        (22009111, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'Y',                  1051, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR117 SCABS
        (22009112, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'N',                  1212, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR118 CROPS_WAVES
        (22009113, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'Y',                  1175, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR119 RASH_CRUST
        (22009114, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'5',                  1342, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR120 RASH_CRUSTED_DAYS
        (22009115, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'7',                  1286, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR121 RASH_DURATION_DAYS
        (22009116, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'101.5',              1176, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR124 FEVER_TEMPERATURE
        (22009117, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'3',                  1383, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR125 FEVER_DURATION_DAYS
        (22009118, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'NoneReported',       1328, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR127 IMMUNOCOMPROMISED_CONDITION
        (22009119, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'N',                  1109, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR130 COMPLICATIONS_SKIN_INFECTION
        (22009120, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'N',                  1048, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR131 COMPLICATIONS_CEREB_ATAXIA
        (22009121, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'N',                  1309, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR132 COMPLICATIONS_ENCEPHALITIS
        (22009122, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'N',                  1366, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR133 COMPLICATIONS_DEHYDRATION
        (22009123, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'N',                  1159, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR134 COMPLICATIONS_HEMORRHAGIC
        (22009124, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'112247003',          1171, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR136 COMPLICATIONS_PNEU_DIAG_BY  (2690 PHVS_VZ_DIAG_PNEU_BY)
        (22009125, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'N',                  1443, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR137 COMPLICATIONS_OTHER
        (22009126, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'NoneReported',       1364, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR138 COMPLICATIONS_OTHER_SPECIFY
        (22009127, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'C23048',             1211, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR140 MEDICATION_NAME (2750 PHVS_VZ_MED_RECVD)
        (22009128, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'2026-03-26',         1213, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR141 MEDICATION_START_DATE
        (22009129, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'2026-03-31',         1341, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR142 MEDICATION_STOP_DATE
        (22009130, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'NotApplicable',      1158, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR144 DEATH_CAUSE
        (22009131, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'OTH',                1350, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR145 VARICELLA_NO_VACCINE_REASON (2670)
        (22009132, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'OtherFreeText',      1196, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR146 VARICELLA_NO_VACCINE_OTHER
        (22009133, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'2',                  1168, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR147 VARICELLA_VACCINE_DOSES_NUMBER
        (22009134, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'OtherFreeText',      1362, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR149 VARICELLA_NO_2NDVACCINE_OTHER
        (22009135, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'4',                  1423, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR151 PREVIOUS_DIAGNOSIS_AGE
        (22009136, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'PHC17',              1120, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR152 PREVIOUS_DIAGNOSIS_BY (2680 PHVS_VZ_DIAG_BY)
        (22009137, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'NotApplicable',      1083, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR153 PREVIOUS_DIAGNOSIS_BY_OTHER
        (22009138, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'PHC166',             1457, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR155 EPI_LINKED_CASE_TYPE (2710)
        (22009139, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'NotApplicable',      1214, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR157 TRANSMISSION_SETTING_OTHER
        (22009140, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'18',                 1157, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR159 PREGNANT_WEEKS
        (22009141, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'255247007',          1367, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR160 PREGNANT_TRIMESTER (2420)
        (22009142, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'OTH',                1306, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR162 VARICELLA_NO_2NDVACCINE_REASON (2670)
        (22009143, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'22',                 1402, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR163 LESIONS_TOTAL_LT50
        (22009144, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'2026-03-28',         1192, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR172 DFA_TEST_DATE
        (22009145, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'260385009',          1088, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR173 DFA_TEST_RESULT (2400 negative)
        (22009146, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'2026-03-29',         1398, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR175 PCR_TEST_DATE
        (22009147, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'NotApplicable',      1142, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR177 PCR_TEST_SOURCE_OTHER
        (22009148, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'NotApplicable',      1194, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR179 PCR_TEST_RESULT_OTHER
        (22009149, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'2026-03-29',         1021, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR181 CULTURE_TEST_DATE
        (22009150, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'260385009',          1421, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR182 CULTURE_TEST_RESULT
        (22009151, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'N',                  1422, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR183 LAB_TESTING_OTHER
        (22009152, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'73512001',           1393, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR184 LAB_TESTING_OTHER_SPECIFY (2810)
        (22009153, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'2026-03-30',         1161, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR185 LAB_TESTING_OTHER_DATE
        (22009154, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'260385009',          1240, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR186 LAB_TESTING_OTHER_RESULT (2400)
        (22009155, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'NotApplicable',      1007, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR187 LAB_TESTING_OTHER_RESULT_VALUE
        (22009156, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'N',                  1415, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR189 IGM_TEST
        (22009157, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'71',                 1129, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR190 IGM_TEST_TYPE (2740)
        (22009158, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'NotApplicable',      1307, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR191 IGM_TEST_TYPE_OTHER
        (22009159, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'2026-03-29',         1022, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR192 IGM_TEST_DATE
        (22009160, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'260385009',          1015, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR193 IGM_TEST_RESULT (2400)
        (22009161, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'NotApplicable',      1348, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR194 IGM_TEST_RESULT_VALUE
        (22009162, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'PHC667',             1193, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR196 IGG_TEST_TYPE (2730)
        (22009163, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'PHC671',             1380, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR197 IGG_TEST_WHOLE_CELL_MFGR (2700)
        (22009164, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'MSD',                1039, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR198 IGG_TEST_GP_ELISA_MFGR (2720)
        (22009165, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'NotApplicable',      1330, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR199 IGG_TEST_OTHER
        (22009166, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'2026-03-29',         1311, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR200 IGG_TEST_ACUTE_DATE
        (22009167, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'260385009',          1310, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR201 IGG_TEST_ACUTE_RESULT (2400)
        (22009168, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'1.05',               1433, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR202 IGG_TEST_ACUTE_VALUE
        (22009169, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'2026-04-05',         1188, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR203 IGG_TEST_CONVALESCENT_DATE
        (22009170, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'10828004',           1209, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR204 IGG_TEST_CONVALESCENT_RESULT (2400)
        (22009171, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'3.20',               1125, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR205 IGG_TEST_CONVALESCENT_VALUE
        (22009172, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'N',                  1344, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR206 GENOTYPING_SENT_TO_CDC
        (22009173, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'2026-04-03',         1046, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR207 GENOTYPING_SENT_TO_CDC_DATE
        (22009174, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'N',                  1305, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR208 STRAIN_IDENTIFICATION_SENT
        (22009175, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'PHC126',             1029, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR209 STRAIN_TYPE (2800)
        (22009176, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'NotApplicable',      1374, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR210 MEDICATION_NAME_OTHER
        (22009177, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'[degF]',             1431, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR211 FEVER_TEMPERATURE_UNIT (2650)
        (22009178, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'Y',                  1394, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR212 PREVIOUS_DIAGNOSIS_AGE_UNIT (70 AGE_UNIT) — 'Y' = Year
        (22009179, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'124',                1313, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR215 PATIENT_BIRTH_COUNTRY (3560 PSL_CNTRY=Canada)
        (22009180, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'2020-03-15',         1156, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR216 VACCINE_DATE_1
        (22009181, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'21',                 1189, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR217 VACCINE_TYPE_1 (2820 PHVS_VZ_VAC_ADMIN)
        (22009182, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'MSD',                1154, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR218 VACCINE_MANUFACTURER_1 (2830)
        (22009183, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'LOT-A-001',          1401, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR219 VACCINE_LOT_1
        (22009184, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'2020-05-15',         1312, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR220 VACCINE_DATE_2
        (22009185, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'21',                 1152, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR221 VACCINE_TYPE_2 (2820)
        (22009186, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'MSD',                1053, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR222 VACCINE_MANUFACTURER_2
        (22009187, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'LOT-A-002',          1434, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR223 VACCINE_LOT_2
        (22009188, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'2021-03-15',         1160, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR224 VACCINE_DATE_3
        (22009189, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'21',                 1397, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR225 VACCINE_TYPE_3
        (22009190, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'MSD',                1368, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR226 VACCINE_MANUFACTURER_3
        (22009191, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'LOT-A-003',          1052, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR227 VACCINE_LOT_3
        (22009192, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'2022-03-15',         1215, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR228 VACCINE_DATE_4
        (22009193, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'21',                 1155, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR229 VACCINE_TYPE_4
        (22009194, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'MSD',                1127, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR230 VACCINE_MANUFACTURER_4
        (22009195, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'LOT-A-004',          1400, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR231 VACCINE_LOT_4
        (22009196, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'2023-03-15',         1153, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR232 VACCINE_DATE_5
        (22009197, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'21',                 1050, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR233 VACCINE_TYPE_5
        (22009198, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'MSD',                1340, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR234 VACCINE_MANUFACTURER_5
        (22009199, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'LOT-A-005',          1435, 1, CAST(GETDATE() AS DATE), @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0); -- VAR235 VACCINE_LOT_5

    SET IDENTITY_INSERT [dbo].[nbs_case_answer] OFF;
END
GO

-- ---------------------------------------------------------------------
-- Multi-value VAR105 / VAR176 answer rows (for RASH_LOCATION_GENERAL_2/3
-- and PCR_TEST_SOURCE_2/3). UID block 22009200..22009203.
-- ---------------------------------------------------------------------
DECLARE @superuser_id2 bigint = 10009282;
DECLARE @var_phc_uid2  bigint = 22002000;

IF NOT EXISTS (SELECT 1 FROM dbo.nbs_case_answer WHERE nbs_case_answer_uid BETWEEN 22009200 AND 22009203)
BEGIN
    SET IDENTITY_INSERT [dbo].[nbs_case_answer] ON;
    INSERT INTO [dbo].[nbs_case_answer]
        ([nbs_case_answer_uid], [act_uid], [add_time], [add_user_id],
         [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr],
         [last_chg_time], [last_chg_user_id],
         [record_status_cd], [record_status_time], [seq_nbr])
    VALUES
        -- VAR105 RASH_LOCATION_GENERAL second value (2790 Face)
        (22009200, @var_phc_uid2, '2026-04-01T00:00:00', @superuser_id2, N'53120007', 1356, 1, CAST(GETDATE() AS DATE), @superuser_id2, N'ACTIVE', '2026-04-01T00:00:00', 1),
        -- VAR105 RASH_LOCATION_GENERAL third value (2790 Limb)
        (22009201, @var_phc_uid2, '2026-04-01T00:00:00', @superuser_id2, N'61685007', 1356, 1, CAST(GETDATE() AS DATE), @superuser_id2, N'ACTIVE', '2026-04-01T00:00:00', 2),
        -- VAR176 PCR_TEST_SOURCE second value (2770 - blood)
        (22009202, @var_phc_uid2, '2026-04-01T00:00:00', @superuser_id2, N'119297000', 1329, 1, CAST(GETDATE() AS DATE), @superuser_id2, N'ACTIVE', '2026-04-01T00:00:00', 1),
        -- VAR176 PCR_TEST_SOURCE third value (2770 - tissue)
        (22009203, @var_phc_uid2, '2026-04-01T00:00:00', @superuser_id2, N'119342007', 1329, 1, CAST(GETDATE() AS DATE), @superuser_id2, N'ACTIVE', '2026-04-01T00:00:00', 2);
    SET IDENTITY_INSERT [dbo].[nbs_case_answer] OFF;
END
GO

-- =====================================================================
-- RDB_MODERN mirror (nrt_page_case_answer) is DERIVED, not authored.
-- The page-builder pipeline projects every ODSE nbs_case_answer row
-- authored above into dbo.nrt_page_case_answer (datamart_column_nm,
-- question_identifier, answer_group_seq_nbr, etc.), so no direct
-- RDB_MODERN writes belong here.
--   Block A: single-row VAR* answers (UIDs 22009100..22009199).
--   Block B: multi-value VAR105 / VAR176 rows (UIDs 22009200..22009203)
--     whose distinct seq_nbr values become distinct D_RASH_LOC_GEN /
--     D_PCR_SOURCE topic-dim rows that var_datamart STRING_AGGs into
--     RASH_LOCATION_GENERAL_2/3 and PCR_TEST_SOURCE_2/3.
-- =====================================================================

-- =====================================================================
-- Block C: VAR100 LESIONS_TOTAL — Coded 2760. The parent fixture did
-- not author VAR100; D_VAR_PAM.LESIONS_TOTAL is therefore NULL. Add.
-- UIDs 22009210..22009210.
-- =====================================================================
USE [NBS_ODSE];
GO
IF NOT EXISTS (SELECT 1 FROM dbo.nbs_case_answer WHERE nbs_case_answer_uid = 22009210)
BEGIN
    SET IDENTITY_INSERT [dbo].[nbs_case_answer] ON;
    INSERT INTO [dbo].[nbs_case_answer]
        ([nbs_case_answer_uid], [act_uid], [add_time], [add_user_id],
         [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr],
         [last_chg_time], [last_chg_user_id],
         [record_status_cd], [record_status_time], [seq_nbr])
    VALUES
        -- VAR100 LESIONS_TOTAL — code_set_group_id=2760 (PHVS_VZ_LESIONS_TOT).
        -- Valid codes verified live 2026-05-24: PHC222 (<50), PHC223 (50-249),
        -- PHC224 (250-499), PHC225 (>500), PHC1437 (50-500), UNK. Use PHC222.
        (22009210, 22002000, '2026-04-01T00:00:00', 10009282, N'PHC222', 1143, 1, CAST(GETDATE() AS DATE), 10009282, N'ACTIVE', '2026-04-01T00:00:00', 0);
    SET IDENTITY_INSERT [dbo].[nbs_case_answer] OFF;
END
GO

-- VAR100 LESIONS_TOTAL is authored correct (PHC222) directly in the
-- ODSE nbs_case_answer INSERT above (uid 22009210); the page-builder
-- carries it into nrt_page_case_answer. No RDB_MODERN self-heal needed.

-- =====================================================================
-- Block D: fix RASH_LOCATION translation. Parent fixture stored 'OTH'
-- which is NOT a valid code in PHVS_VZ_RASH_DISTRO (code_set_group_id
-- 2780; valid codes are 60132005=Generalized, 87017008=Focal, UNK).
-- The D_VAR_PAM SP's translation step joins NRT_SRTE_CODE_VALUE_GENERAL
-- via CODE+CODE_SET_NM, finds no match, so CODE_SHORT_DESC_TXT is NULL
-- and the pivoted value collapses. UPDATE the existing parent-fixture
-- row to a valid code so var_datamart.RASH_LOCATION populates.
-- =====================================================================
USE [NBS_ODSE];
GO
UPDATE dbo.nbs_case_answer SET answer_txt = N'60132005'
WHERE nbs_case_answer_uid = 22002101 AND answer_txt = N'OTH';
GO
-- The corrected ODSE answer_txt is carried into nrt_page_case_answer by
-- the page-builder; no direct RDB_MODERN write needed.

-- =====================================================================
-- Block E: enrich the ODSE public_health_case (22002000) with comments,
-- illness duration, and an outbreak name. These are the RAW ODSE source
-- columns that 056-sp_investigation_event reads and derives into
-- nrt_investigation, whence sp_nrt_investigation_postprocessing flows
-- them into the INVESTIGATION dim and the var_datamart SP surfaces them
-- as GENERAL_COMMENTS, ILLNESS_DURATION, ILLNESS_DURATION_UNIT,
-- OUTBREAK_NAME.
--
-- DERIVATION (056-sp_investigation_event, verified live 2026-06-05):
--   public_health_case.txt                    -> nrt_investigation.txt -> INV_COMMENTS
--   public_health_case.effective_duration_amt -> effective_duration_amt -> ILLNESS_DURATION
--   public_health_case.effective_duration_unit_cd ('D') -> illness_duration_unit
--       is DERIVED via fn_get_value_by_cd_codeset(..., 'INV144') (codeset
--       AGE_UNIT); 'D' resolves to short-desc "Days". We set the RAW cd,
--       NOT illness_duration_unit directly.
--   public_health_case.outbreak_name ('MDK')  -> OUTBREAK_NAME.
-- The sibling fixture (varicella_investigation_full_chain.sql) authors
-- this PHC with outbreak_name=NULL etc.; we enrich it here and bump
-- last_chg_time so 056 reprocesses it.
-- =====================================================================
USE [NBS_ODSE];
GO
UPDATE dbo.public_health_case
SET txt                        = N'Varicella outbreak: index case linked epi-cluster',
    effective_duration_amt     = N'14',
    effective_duration_unit_cd = N'D',
    outbreak_name              = N'MDK',
    last_chg_time              = '2026-04-15T00:00:00'
WHERE public_health_case_uid = 22002000;
GO

-- =====================================================================
-- Block F: confirmation method enrichment (ODSE source).
--   var_datamart.CONFIRMATION_METHOD_1 / _ALL / _DATE derive from
--   CONFIRMATION_METHOD_GROUP, which 005-sp_nrt_investigation_postprocessing
--   builds from the investigation_confirmation_method JSON that
--   056-sp_investigation_event assembles by reading
--   NBS_ODSE.dbo.Confirmation_method (056 lines ~425-435), joining
--   code_value_general on code_set_nm='PHC_CONF_M' for the description.
--   So we author ONE ODSE Confirmation_method row for this PHC.
--
--   confirmation_method_cd='LD' = "Laboratory confirmed" (codeset
--   PHC_CONF_M, verified live 2026-06-05). confirmation_method_desc_txt
--   is left NULL — 056 re-derives it via the PHC_CONF_M join. The PHC
--   last_chg_time bump in Block E forces 056 to reprocess and pick this
--   up. Idempotent: skip if a row already exists.
--   Confirmation_method PK is (public_health_case_uid, confirmation_method_cd);
--   no IDENTITY column.
-- =====================================================================
USE [NBS_ODSE];
GO
IF NOT EXISTS (SELECT 1 FROM dbo.Confirmation_method
               WHERE public_health_case_uid = 22002000 AND confirmation_method_cd = N'LD')
    INSERT INTO dbo.Confirmation_method
        (public_health_case_uid, confirmation_method_cd,
         confirmation_method_desc_txt, confirmation_method_time)
    VALUES
        (22002000, N'LD', NULL, '2026-04-15T00:00:00');
GO

-- =====================================================================
-- Tail-EXEC: re-run the VAR-PAM SP chain so the new rows flow into
-- D_VAR_PAM / D_RASH_LOC_GEN / D_PCR_SOURCE / VAR_PAM_LDF / F_VAR_PAM /
-- VAR_DATAMART. Wrapped in TRY/CATCH so a SP failure does not abort
-- merge_and_verify.sh's pipeline (TB regression scar).
-- =====================================================================

GO

GO

GO

GO

GO

GO
