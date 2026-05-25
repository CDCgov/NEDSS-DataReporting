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
        (22009100, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'2026-03-20',         1169, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR102 RASH_ONSET_DATE
        (22009101, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'LeftArm',            1445, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR104 RASH_LOCATION_DERMATOME
        (22009102, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'OtherSpecify',       1027, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR106 RASH_LOCATION_OTHER
        (22009103, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'Y',                  1399, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR107 MACULES YNU 4150
        (22009104, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'12',                 1195, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR108 MACULES_NUMBER
        (22009105, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'Y',                  1308, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR109 PAPULES
        (22009106, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'8',                  1144, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR110 PAPULES_NUMBER
        (22009107, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'15',                 1130, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR112 VESICLES_NUMBER
        (22009108, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'N',                  1028, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR114 VESICULAR
        (22009109, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'N',                  1419, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR115 HEMORRHAGIC
        (22009110, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'Y',                  1283, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR116 ITCHY
        (22009111, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'Y',                  1051, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR117 SCABS
        (22009112, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'N',                  1212, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR118 CROPS_WAVES
        (22009113, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'Y',                  1175, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR119 RASH_CRUST
        (22009114, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'5',                  1342, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR120 RASH_CRUSTED_DAYS
        (22009115, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'7',                  1286, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR121 RASH_DURATION_DAYS
        (22009116, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'101.5',              1176, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR124 FEVER_TEMPERATURE
        (22009117, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'3',                  1383, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR125 FEVER_DURATION_DAYS
        (22009118, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'NoneReported',       1328, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR127 IMMUNOCOMPROMISED_CONDITION
        (22009119, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'N',                  1109, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR130 COMPLICATIONS_SKIN_INFECTION
        (22009120, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'N',                  1048, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR131 COMPLICATIONS_CEREB_ATAXIA
        (22009121, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'N',                  1309, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR132 COMPLICATIONS_ENCEPHALITIS
        (22009122, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'N',                  1366, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR133 COMPLICATIONS_DEHYDRATION
        (22009123, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'N',                  1159, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR134 COMPLICATIONS_HEMORRHAGIC
        (22009124, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'112247003',          1171, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR136 COMPLICATIONS_PNEU_DIAG_BY  (2690 PHVS_VZ_DIAG_PNEU_BY)
        (22009125, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'N',                  1443, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR137 COMPLICATIONS_OTHER
        (22009126, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'NoneReported',       1364, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR138 COMPLICATIONS_OTHER_SPECIFY
        (22009127, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'C23048',             1211, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR140 MEDICATION_NAME (2750 PHVS_VZ_MED_RECVD)
        (22009128, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'2026-03-26',         1213, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR141 MEDICATION_START_DATE
        (22009129, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'2026-03-31',         1341, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR142 MEDICATION_STOP_DATE
        (22009130, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'NotApplicable',      1158, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR144 DEATH_CAUSE
        (22009131, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'OTH',                1350, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR145 VARICELLA_NO_VACCINE_REASON (2670)
        (22009132, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'OtherFreeText',      1196, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR146 VARICELLA_NO_VACCINE_OTHER
        (22009133, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'2',                  1168, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR147 VARICELLA_VACCINE_DOSES_NUMBER
        (22009134, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'OtherFreeText',      1362, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR149 VARICELLA_NO_2NDVACCINE_OTHER
        (22009135, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'4',                  1423, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR151 PREVIOUS_DIAGNOSIS_AGE
        (22009136, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'PHC17',              1120, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR152 PREVIOUS_DIAGNOSIS_BY (2680 PHVS_VZ_DIAG_BY)
        (22009137, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'NotApplicable',      1083, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR153 PREVIOUS_DIAGNOSIS_BY_OTHER
        (22009138, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'PHC166',             1457, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR155 EPI_LINKED_CASE_TYPE (2710)
        (22009139, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'NotApplicable',      1214, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR157 TRANSMISSION_SETTING_OTHER
        (22009140, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'18',                 1157, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR159 PREGNANT_WEEKS
        (22009141, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'255247007',          1367, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR160 PREGNANT_TRIMESTER (2420)
        (22009142, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'OTH',                1306, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR162 VARICELLA_NO_2NDVACCINE_REASON (2670)
        (22009143, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'22',                 1402, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR163 LESIONS_TOTAL_LT50
        (22009144, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'2026-03-28',         1192, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR172 DFA_TEST_DATE
        (22009145, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'260385009',          1088, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR173 DFA_TEST_RESULT (2400 negative)
        (22009146, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'2026-03-29',         1398, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR175 PCR_TEST_DATE
        (22009147, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'NotApplicable',      1142, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR177 PCR_TEST_SOURCE_OTHER
        (22009148, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'NotApplicable',      1194, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR179 PCR_TEST_RESULT_OTHER
        (22009149, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'2026-03-29',         1021, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR181 CULTURE_TEST_DATE
        (22009150, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'260385009',          1421, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR182 CULTURE_TEST_RESULT
        (22009151, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'N',                  1422, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR183 LAB_TESTING_OTHER
        (22009152, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'73512001',           1393, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR184 LAB_TESTING_OTHER_SPECIFY (2810)
        (22009153, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'2026-03-30',         1161, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR185 LAB_TESTING_OTHER_DATE
        (22009154, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'260385009',          1240, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR186 LAB_TESTING_OTHER_RESULT (2400)
        (22009155, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'NotApplicable',      1007, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR187 LAB_TESTING_OTHER_RESULT_VALUE
        (22009156, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'N',                  1415, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR189 IGM_TEST
        (22009157, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'71',                 1129, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR190 IGM_TEST_TYPE (2740)
        (22009158, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'NotApplicable',      1307, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR191 IGM_TEST_TYPE_OTHER
        (22009159, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'2026-03-29',         1022, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR192 IGM_TEST_DATE
        (22009160, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'260385009',          1015, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR193 IGM_TEST_RESULT (2400)
        (22009161, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'NotApplicable',      1348, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR194 IGM_TEST_RESULT_VALUE
        (22009162, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'PHC667',             1193, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR196 IGG_TEST_TYPE (2730)
        (22009163, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'PHC671',             1380, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR197 IGG_TEST_WHOLE_CELL_MFGR (2700)
        (22009164, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'MSD',                1039, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR198 IGG_TEST_GP_ELISA_MFGR (2720)
        (22009165, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'NotApplicable',      1330, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR199 IGG_TEST_OTHER
        (22009166, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'2026-03-29',         1311, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR200 IGG_TEST_ACUTE_DATE
        (22009167, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'260385009',          1310, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR201 IGG_TEST_ACUTE_RESULT (2400)
        (22009168, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'1.05',               1433, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR202 IGG_TEST_ACUTE_VALUE
        (22009169, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'2026-04-05',         1188, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR203 IGG_TEST_CONVALESCENT_DATE
        (22009170, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'10828004',           1209, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR204 IGG_TEST_CONVALESCENT_RESULT (2400)
        (22009171, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'3.20',               1125, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR205 IGG_TEST_CONVALESCENT_VALUE
        (22009172, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'N',                  1344, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR206 GENOTYPING_SENT_TO_CDC
        (22009173, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'2026-04-03',         1046, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR207 GENOTYPING_SENT_TO_CDC_DATE
        (22009174, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'N',                  1305, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR208 STRAIN_IDENTIFICATION_SENT
        (22009175, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'PHC126',             1029, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR209 STRAIN_TYPE (2800)
        (22009176, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'NotApplicable',      1374, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR210 MEDICATION_NAME_OTHER
        (22009177, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'[degF]',             1431, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR211 FEVER_TEMPERATURE_UNIT (2650)
        (22009178, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'Y',                  1394, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR212 PREVIOUS_DIAGNOSIS_AGE_UNIT (70 AGE_UNIT) — 'Y' = Year
        (22009179, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'124',                1313, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR215 PATIENT_BIRTH_COUNTRY (3560 PSL_CNTRY=Canada)
        (22009180, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'2020-03-15',         1156, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR216 VACCINE_DATE_1
        (22009181, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'21',                 1189, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR217 VACCINE_TYPE_1 (2820 PHVS_VZ_VAC_ADMIN)
        (22009182, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'MSD',                1154, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR218 VACCINE_MANUFACTURER_1 (2830)
        (22009183, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'LOT-A-001',          1401, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR219 VACCINE_LOT_1
        (22009184, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'2020-05-15',         1312, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR220 VACCINE_DATE_2
        (22009185, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'21',                 1152, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR221 VACCINE_TYPE_2 (2820)
        (22009186, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'MSD',                1053, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR222 VACCINE_MANUFACTURER_2
        (22009187, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'LOT-A-002',          1434, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR223 VACCINE_LOT_2
        (22009188, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'2021-03-15',         1160, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR224 VACCINE_DATE_3
        (22009189, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'21',                 1397, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR225 VACCINE_TYPE_3
        (22009190, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'MSD',                1368, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR226 VACCINE_MANUFACTURER_3
        (22009191, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'LOT-A-003',          1052, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR227 VACCINE_LOT_3
        (22009192, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'2022-03-15',         1215, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR228 VACCINE_DATE_4
        (22009193, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'21',                 1155, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR229 VACCINE_TYPE_4
        (22009194, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'MSD',                1127, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR230 VACCINE_MANUFACTURER_4
        (22009195, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'LOT-A-004',          1400, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR231 VACCINE_LOT_4
        (22009196, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'2023-03-15',         1153, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR232 VACCINE_DATE_5
        (22009197, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'21',                 1050, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR233 VACCINE_TYPE_5
        (22009198, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'MSD',                1340, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0), -- VAR234 VACCINE_MANUFACTURER_5
        (22009199, @var_phc_uid, '2026-04-01T00:00:00', @superuser_id, N'LOT-A-005',          1435, 1, '2026-04-01T00:00:00', @superuser_id, N'ACTIVE', '2026-04-01T00:00:00', 0); -- VAR235 VACCINE_LOT_5

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
        (22009200, @var_phc_uid2, '2026-04-01T00:00:00', @superuser_id2, N'53120007', 1356, 1, '2026-04-01T00:00:00', @superuser_id2, N'ACTIVE', '2026-04-01T00:00:00', 1),
        -- VAR105 RASH_LOCATION_GENERAL third value (2790 Limb)
        (22009201, @var_phc_uid2, '2026-04-01T00:00:00', @superuser_id2, N'61685007', 1356, 1, '2026-04-01T00:00:00', @superuser_id2, N'ACTIVE', '2026-04-01T00:00:00', 2),
        -- VAR176 PCR_TEST_SOURCE second value (2770 - blood)
        (22009202, @var_phc_uid2, '2026-04-01T00:00:00', @superuser_id2, N'119297000', 1329, 1, '2026-04-01T00:00:00', @superuser_id2, N'ACTIVE', '2026-04-01T00:00:00', 1),
        -- VAR176 PCR_TEST_SOURCE third value (2770 - tissue)
        (22009203, @var_phc_uid2, '2026-04-01T00:00:00', @superuser_id2, N'119342007', 1329, 1, '2026-04-01T00:00:00', @superuser_id2, N'ACTIVE', '2026-04-01T00:00:00', 2);
    SET IDENTITY_INSERT [dbo].[nbs_case_answer] OFF;
END
GO

-- =====================================================================
-- RDB_MODERN: mirror to nrt_page_case_answer
-- =====================================================================

USE [RDB_MODERN];
GO

-- Block A: 100 single-row VAR* answers (UIDs 22009100..22009199)
IF NOT EXISTS (SELECT 1 FROM dbo.nrt_page_case_answer WHERE nbs_case_answer_uid BETWEEN 22009100 AND 22009199)
BEGIN
    INSERT INTO [dbo].[nrt_page_case_answer]
        ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid],
         [nbs_question_uid],
         [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr],
         [investigation_form_cd], [question_identifier], [data_location],
         [code_set_group_id], [last_chg_time], [record_status_cd],
         [datamart_column_nm], [ldf_status_cd], [seq_nbr], [batch_id],
         [nbs_ui_component_uid], [nca_add_time], [nuim_record_status_cd])
    VALUES
        -- mirror of Block A rows; datamart_column_nm aligned to D_VAR_PAM PIVOT IN-list
        (22002000, 22009100, 2, 1169, N'VAR_PAM', N'RASH_ONSET_DATE',           N'2026-03-20',  N'1', N'INV_FORM_VAR', N'VAR102', N'NBS_Case_Answer.answer_txt', NULL,  '2026-04-01T00:00:00', N'ACTIVE', N'RASH_ONSET_DATE',           NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009101, 2, 1445, N'VAR_PAM', N'RASH_LOCATION_DERMATOME',   N'LeftArm',     N'1', N'INV_FORM_VAR', N'VAR104', N'NBS_Case_Answer.answer_txt', NULL,  '2026-04-01T00:00:00', N'ACTIVE', N'RASH_LOCATION_DERMATOME',   NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009102, 2, 1027, N'VAR_PAM', N'RASH_LOCATION_OTHER',       N'OtherSpecify',N'1', N'INV_FORM_VAR', N'VAR106', N'NBS_Case_Answer.answer_txt', NULL,  '2026-04-01T00:00:00', N'ACTIVE', N'RASH_LOCATION_OTHER',       NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009103, 2, 1399, N'VAR_PAM', N'MACULES',                   N'Y',           N'1', N'INV_FORM_VAR', N'VAR107', N'NBS_Case_Answer.answer_txt', 4150,  '2026-04-01T00:00:00', N'ACTIVE', N'MACULES',                   NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009104, 2, 1195, N'VAR_PAM', N'MACULES_NUMBER',            N'12',          N'1', N'INV_FORM_VAR', N'VAR108', N'NBS_Case_Answer.answer_txt', NULL,  '2026-04-01T00:00:00', N'ACTIVE', N'MACULES_NUMBER',            NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009105, 2, 1308, N'VAR_PAM', N'PAPULES',                   N'Y',           N'1', N'INV_FORM_VAR', N'VAR109', N'NBS_Case_Answer.answer_txt', 4150,  '2026-04-01T00:00:00', N'ACTIVE', N'PAPULES',                   NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009106, 2, 1144, N'VAR_PAM', N'PAPULES_NUMBER',            N'8',           N'1', N'INV_FORM_VAR', N'VAR110', N'NBS_Case_Answer.answer_txt', NULL,  '2026-04-01T00:00:00', N'ACTIVE', N'PAPULES_NUMBER',            NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009107, 2, 1130, N'VAR_PAM', N'VESICLES_NUMBER',           N'15',          N'1', N'INV_FORM_VAR', N'VAR112', N'NBS_Case_Answer.answer_txt', NULL,  '2026-04-01T00:00:00', N'ACTIVE', N'VESICLES_NUMBER',           NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009108, 2, 1028, N'VAR_PAM', N'VESICULAR',                 N'N',           N'1', N'INV_FORM_VAR', N'VAR114', N'NBS_Case_Answer.answer_txt', 4150,  '2026-04-01T00:00:00', N'ACTIVE', N'VESICULAR',                 NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009109, 2, 1419, N'VAR_PAM', N'HEMORRHAGIC',               N'N',           N'1', N'INV_FORM_VAR', N'VAR115', N'NBS_Case_Answer.answer_txt', 4150,  '2026-04-01T00:00:00', N'ACTIVE', N'HEMORRHAGIC',               NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009110, 2, 1283, N'VAR_PAM', N'ITCHY',                     N'Y',           N'1', N'INV_FORM_VAR', N'VAR116', N'NBS_Case_Answer.answer_txt', 4150,  '2026-04-01T00:00:00', N'ACTIVE', N'ITCHY',                     NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009111, 2, 1051, N'VAR_PAM', N'SCABS',                     N'Y',           N'1', N'INV_FORM_VAR', N'VAR117', N'NBS_Case_Answer.answer_txt', 4150,  '2026-04-01T00:00:00', N'ACTIVE', N'SCABS',                     NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009112, 2, 1212, N'VAR_PAM', N'CROPS_WAVES',               N'N',           N'1', N'INV_FORM_VAR', N'VAR118', N'NBS_Case_Answer.answer_txt', 4150,  '2026-04-01T00:00:00', N'ACTIVE', N'CROPS_WAVES',               NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009113, 2, 1175, N'VAR_PAM', N'RASH_CRUST',                N'Y',           N'1', N'INV_FORM_VAR', N'VAR119', N'NBS_Case_Answer.answer_txt', 4150,  '2026-04-01T00:00:00', N'ACTIVE', N'RASH_CRUST',                NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009114, 2, 1342, N'VAR_PAM', N'RASH_CRUSTED_DAYS',         N'5',           N'1', N'INV_FORM_VAR', N'VAR120', N'NBS_Case_Answer.answer_txt', NULL,  '2026-04-01T00:00:00', N'ACTIVE', N'RASH_CRUSTED_DAYS',         NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009115, 2, 1286, N'VAR_PAM', N'RASH_DURATION_DAYS',        N'7',           N'1', N'INV_FORM_VAR', N'VAR121', N'NBS_Case_Answer.answer_txt', NULL,  '2026-04-01T00:00:00', N'ACTIVE', N'RASH_DURATION_DAYS',        NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009116, 2, 1176, N'VAR_PAM', N'FEVER_TEMPERATURE',         N'101.5',       N'1', N'INV_FORM_VAR', N'VAR124', N'NBS_Case_Answer.answer_txt', NULL,  '2026-04-01T00:00:00', N'ACTIVE', N'FEVER_TEMPERATURE',         NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009117, 2, 1383, N'VAR_PAM', N'FEVER_DURATION_DAYS',       N'3',           N'1', N'INV_FORM_VAR', N'VAR125', N'NBS_Case_Answer.answer_txt', NULL,  '2026-04-01T00:00:00', N'ACTIVE', N'FEVER_DURATION_DAYS',       NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009118, 2, 1328, N'VAR_PAM', N'IMMUNOCOMPROMISED_CONDITION',N'NoneReported',N'1', N'INV_FORM_VAR', N'VAR127', N'NBS_Case_Answer.answer_txt', NULL,  '2026-04-01T00:00:00', N'ACTIVE', N'IMMUNOCOMPROMISED_CONDITION',NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009119, 2, 1109, N'VAR_PAM', N'COMPLICATIONS_SKIN_INFECTION',N'N',         N'1', N'INV_FORM_VAR', N'VAR130', N'NBS_Case_Answer.answer_txt', 4150,  '2026-04-01T00:00:00', N'ACTIVE', N'COMPLICATIONS_SKIN_INFECTION',NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009120, 2, 1048, N'VAR_PAM', N'COMPLICATIONS_CEREB_ATAXIA',N'N',          N'1', N'INV_FORM_VAR', N'VAR131', N'NBS_Case_Answer.answer_txt', 4150,  '2026-04-01T00:00:00', N'ACTIVE', N'COMPLICATIONS_CEREB_ATAXIA',NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009121, 2, 1309, N'VAR_PAM', N'COMPLICATIONS_ENCEPHALITIS',N'N',          N'1', N'INV_FORM_VAR', N'VAR132', N'NBS_Case_Answer.answer_txt', 4150,  '2026-04-01T00:00:00', N'ACTIVE', N'COMPLICATIONS_ENCEPHALITIS',NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009122, 2, 1366, N'VAR_PAM', N'COMPLICATIONS_DEHYDRATION', N'N',           N'1', N'INV_FORM_VAR', N'VAR133', N'NBS_Case_Answer.answer_txt', 4150,  '2026-04-01T00:00:00', N'ACTIVE', N'COMPLICATIONS_DEHYDRATION', NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009123, 2, 1159, N'VAR_PAM', N'COMPLICATIONS_HEMORRHAGIC', N'N',           N'1', N'INV_FORM_VAR', N'VAR134', N'NBS_Case_Answer.answer_txt', 4150,  '2026-04-01T00:00:00', N'ACTIVE', N'COMPLICATIONS_HEMORRHAGIC', NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009124, 2, 1171, N'VAR_PAM', N'COMPLICATIONS_PNEU_DIAG_BY',N'112247003',   N'1', N'INV_FORM_VAR', N'VAR136', N'NBS_Case_Answer.answer_txt', 2690,  '2026-04-01T00:00:00', N'ACTIVE', N'COMPLICATIONS_PNEU_DIAG_BY',NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009125, 2, 1443, N'VAR_PAM', N'COMPLICATIONS_OTHER',       N'N',           N'1', N'INV_FORM_VAR', N'VAR137', N'NBS_Case_Answer.answer_txt', 4150,  '2026-04-01T00:00:00', N'ACTIVE', N'COMPLICATIONS_OTHER',       NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009126, 2, 1364, N'VAR_PAM', N'COMPLICATIONS_OTHER_SPECIFY',N'NoneReported',N'1',N'INV_FORM_VAR', N'VAR138', N'NBS_Case_Answer.answer_txt', NULL,  '2026-04-01T00:00:00', N'ACTIVE', N'COMPLICATIONS_OTHER_SPECIFY',NULL,1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009127, 2, 1211, N'VAR_PAM', N'MEDICATION_NAME',           N'C23048',      N'1', N'INV_FORM_VAR', N'VAR140', N'NBS_Case_Answer.answer_txt', 2750,  '2026-04-01T00:00:00', N'ACTIVE', N'MEDICATION_NAME',           NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009128, 2, 1213, N'VAR_PAM', N'MEDICATION_START_DATE',     N'2026-03-26',  N'1', N'INV_FORM_VAR', N'VAR141', N'NBS_Case_Answer.answer_txt', NULL,  '2026-04-01T00:00:00', N'ACTIVE', N'MEDICATION_START_DATE',     NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009129, 2, 1341, N'VAR_PAM', N'MEDICATION_STOP_DATE',      N'2026-03-31',  N'1', N'INV_FORM_VAR', N'VAR142', N'NBS_Case_Answer.answer_txt', NULL,  '2026-04-01T00:00:00', N'ACTIVE', N'MEDICATION_STOP_DATE',      NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009130, 2, 1158, N'VAR_PAM', N'DEATH_CAUSE',               N'NotApplicable',N'1', N'INV_FORM_VAR',N'VAR144', N'NBS_Case_Answer.answer_txt', NULL,  '2026-04-01T00:00:00', N'ACTIVE', N'DEATH_CAUSE',               NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009131, 2, 1350, N'VAR_PAM', N'VARICELLA_NO_VACCINE_REASON',N'OTH',        N'1', N'INV_FORM_VAR', N'VAR145', N'NBS_Case_Answer.answer_txt', 2670,  '2026-04-01T00:00:00', N'ACTIVE', N'VARICELLA_NO_VACCINE_REASON',NULL,1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009132, 2, 1196, N'VAR_PAM', N'VARICELLA_NO_VACCINE_OTHER',N'OtherFreeText',N'1', N'INV_FORM_VAR',N'VAR146', N'NBS_Case_Answer.answer_txt', NULL,  '2026-04-01T00:00:00', N'ACTIVE', N'VARICELLA_NO_VACCINE_OTHER',NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009133, 2, 1168, N'VAR_PAM', N'VARICELLA_VACCINE_DOSES_NUMBER',N'2',       N'1', N'INV_FORM_VAR', N'VAR147', N'NBS_Case_Answer.answer_txt', NULL,  '2026-04-01T00:00:00', N'ACTIVE', N'VARICELLA_VACCINE_DOSES_NUMBER',NULL,1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009134, 2, 1362, N'VAR_PAM', N'VARICELLA_NO_2NDVACCINE_OTHER',N'OtherFreeText',N'1', N'INV_FORM_VAR',N'VAR149', N'NBS_Case_Answer.answer_txt', NULL,  '2026-04-01T00:00:00', N'ACTIVE', N'VARICELLA_NO_2NDVACCINE_OTHER',NULL,1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009135, 2, 1423, N'VAR_PAM', N'PREVIOUS_DIAGNOSIS_AGE',    N'4',           N'1', N'INV_FORM_VAR', N'VAR151', N'NBS_Case_Answer.answer_txt', NULL,  '2026-04-01T00:00:00', N'ACTIVE', N'PREVIOUS_DIAGNOSIS_AGE',    NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009136, 2, 1120, N'VAR_PAM', N'PREVIOUS_DIAGNOSIS_BY',     N'PHC17',       N'1', N'INV_FORM_VAR', N'VAR152', N'NBS_Case_Answer.answer_txt', 2680,  '2026-04-01T00:00:00', N'ACTIVE', N'PREVIOUS_DIAGNOSIS_BY',     NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009137, 2, 1083, N'VAR_PAM', N'PREVIOUS_DIAGNOSIS_BY_OTHER',N'NotApplicable',N'1',N'INV_FORM_VAR',N'VAR153', N'NBS_Case_Answer.answer_txt', NULL,  '2026-04-01T00:00:00', N'ACTIVE', N'PREVIOUS_DIAGNOSIS_BY_OTHER',NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009138, 2, 1457, N'VAR_PAM', N'EPI_LINKED_CASE_TYPE',      N'PHC166',      N'1', N'INV_FORM_VAR', N'VAR155', N'NBS_Case_Answer.answer_txt', 2710,  '2026-04-01T00:00:00', N'ACTIVE', N'EPI_LINKED_CASE_TYPE',      NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009139, 2, 1214, N'VAR_PAM', N'TRANSMISSION_SETTING_OTHER',N'NotApplicable',N'1',N'INV_FORM_VAR', N'VAR157', N'NBS_Case_Answer.answer_txt', NULL,  '2026-04-01T00:00:00', N'ACTIVE', N'TRANSMISSION_SETTING_OTHER',NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009140, 2, 1157, N'VAR_PAM', N'PREGNANT_WEEKS',            N'18',          N'1', N'INV_FORM_VAR', N'VAR159', N'NBS_Case_Answer.answer_txt', NULL,  '2026-04-01T00:00:00', N'ACTIVE', N'PREGNANT_WEEKS',            NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009141, 2, 1367, N'VAR_PAM', N'PREGNANT_TRIMESTER',        N'255247007',   N'1', N'INV_FORM_VAR', N'VAR160', N'NBS_Case_Answer.answer_txt', 2420,  '2026-04-01T00:00:00', N'ACTIVE', N'PREGNANT_TRIMESTER',        NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009142, 2, 1306, N'VAR_PAM', N'VARICELLA_NO_2NDVACCINE_REASON',N'OTH',     N'1', N'INV_FORM_VAR', N'VAR162', N'NBS_Case_Answer.answer_txt', 2670,  '2026-04-01T00:00:00', N'ACTIVE', N'VARICELLA_NO_2NDVACCINE_REASON',NULL,1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009143, 2, 1402, N'VAR_PAM', N'LESIONS_TOTAL_LT50',        N'22',          N'1', N'INV_FORM_VAR', N'VAR163', N'NBS_Case_Answer.answer_txt', NULL,  '2026-04-01T00:00:00', N'ACTIVE', N'LESIONS_TOTAL_LT50',        NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009144, 2, 1192, N'VAR_PAM', N'DFA_TEST_DATE',             N'2026-03-28',  N'1', N'INV_FORM_VAR', N'VAR172', N'NBS_Case_Answer.answer_txt', NULL,  '2026-04-01T00:00:00', N'ACTIVE', N'DFA_TEST_DATE',             NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009145, 2, 1088, N'VAR_PAM', N'DFA_TEST_RESULT',           N'260385009',   N'1', N'INV_FORM_VAR', N'VAR173', N'NBS_Case_Answer.answer_txt', 2400,  '2026-04-01T00:00:00', N'ACTIVE', N'DFA_TEST_RESULT',           NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009146, 2, 1398, N'VAR_PAM', N'PCR_TEST_DATE',             N'2026-03-29',  N'1', N'INV_FORM_VAR', N'VAR175', N'NBS_Case_Answer.answer_txt', NULL,  '2026-04-01T00:00:00', N'ACTIVE', N'PCR_TEST_DATE',             NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009147, 2, 1142, N'VAR_PAM', N'PCR_TEST_SOURCE_OTHER',     N'NotApplicable',N'1',N'INV_FORM_VAR', N'VAR177', N'NBS_Case_Answer.answer_txt', NULL,  '2026-04-01T00:00:00', N'ACTIVE', N'PCR_TEST_SOURCE_OTHER',     NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009148, 2, 1194, N'VAR_PAM', N'PCR_TEST_RESULT_OTHER',     N'NotApplicable',N'1',N'INV_FORM_VAR', N'VAR179', N'NBS_Case_Answer.answer_txt', NULL,  '2026-04-01T00:00:00', N'ACTIVE', N'PCR_TEST_RESULT_OTHER',     NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009149, 2, 1021, N'VAR_PAM', N'CULTURE_TEST_DATE',         N'2026-03-29',  N'1', N'INV_FORM_VAR', N'VAR181', N'NBS_Case_Answer.answer_txt', NULL,  '2026-04-01T00:00:00', N'ACTIVE', N'CULTURE_TEST_DATE',         NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009150, 2, 1421, N'VAR_PAM', N'CULTURE_TEST_RESULT',       N'260385009',   N'1', N'INV_FORM_VAR', N'VAR182', N'NBS_Case_Answer.answer_txt', 2400,  '2026-04-01T00:00:00', N'ACTIVE', N'CULTURE_TEST_RESULT',       NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009151, 2, 1422, N'VAR_PAM', N'LAB_TESTING_OTHER',         N'N',           N'1', N'INV_FORM_VAR', N'VAR183', N'NBS_Case_Answer.answer_txt', 4150,  '2026-04-01T00:00:00', N'ACTIVE', N'LAB_TESTING_OTHER',         NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009152, 2, 1393, N'VAR_PAM', N'LAB_TESTING_OTHER_SPECIFY', N'73512001',    N'1', N'INV_FORM_VAR', N'VAR184', N'NBS_Case_Answer.answer_txt', 2810,  '2026-04-01T00:00:00', N'ACTIVE', N'LAB_TESTING_OTHER_SPECIFY', NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009153, 2, 1161, N'VAR_PAM', N'LAB_TESTING_OTHER_DATE',    N'2026-03-30',  N'1', N'INV_FORM_VAR', N'VAR185', N'NBS_Case_Answer.answer_txt', NULL,  '2026-04-01T00:00:00', N'ACTIVE', N'LAB_TESTING_OTHER_DATE',    NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009154, 2, 1240, N'VAR_PAM', N'LAB_TESTING_OTHER_RESULT',  N'260385009',   N'1', N'INV_FORM_VAR', N'VAR186', N'NBS_Case_Answer.answer_txt', 2400,  '2026-04-01T00:00:00', N'ACTIVE', N'LAB_TESTING_OTHER_RESULT',  NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009155, 2, 1007, N'VAR_PAM', N'LAB_TESTING_OTHER_RESULT_VALUE',N'NotApplicable',N'1',N'INV_FORM_VAR',N'VAR187', N'NBS_Case_Answer.answer_txt', NULL,  '2026-04-01T00:00:00', N'ACTIVE', N'LAB_TESTING_OTHER_RESULT_VALUE',NULL,1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009156, 2, 1415, N'VAR_PAM', N'IGM_TEST',                  N'N',           N'1', N'INV_FORM_VAR', N'VAR189', N'NBS_Case_Answer.answer_txt', 4150,  '2026-04-01T00:00:00', N'ACTIVE', N'IGM_TEST',                  NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009157, 2, 1129, N'VAR_PAM', N'IGM_TEST_TYPE',             N'71',          N'1', N'INV_FORM_VAR', N'VAR190', N'NBS_Case_Answer.answer_txt', 2740,  '2026-04-01T00:00:00', N'ACTIVE', N'IGM_TEST_TYPE',             NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009158, 2, 1307, N'VAR_PAM', N'IGM_TEST_TYPE_OTHER',       N'NotApplicable',N'1',N'INV_FORM_VAR', N'VAR191', N'NBS_Case_Answer.answer_txt', NULL,  '2026-04-01T00:00:00', N'ACTIVE', N'IGM_TEST_TYPE_OTHER',       NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009159, 2, 1022, N'VAR_PAM', N'IGM_TEST_DATE',             N'2026-03-29',  N'1', N'INV_FORM_VAR', N'VAR192', N'NBS_Case_Answer.answer_txt', NULL,  '2026-04-01T00:00:00', N'ACTIVE', N'IGM_TEST_DATE',             NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009160, 2, 1015, N'VAR_PAM', N'IGM_TEST_RESULT',           N'260385009',   N'1', N'INV_FORM_VAR', N'VAR193', N'NBS_Case_Answer.answer_txt', 2400,  '2026-04-01T00:00:00', N'ACTIVE', N'IGM_TEST_RESULT',           NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009161, 2, 1348, N'VAR_PAM', N'IGM_TEST_RESULT_VALUE',     N'NotApplicable',N'1',N'INV_FORM_VAR', N'VAR194', N'NBS_Case_Answer.answer_txt', NULL,  '2026-04-01T00:00:00', N'ACTIVE', N'IGM_TEST_RESULT_VALUE',     NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009162, 2, 1193, N'VAR_PAM', N'IGG_TEST_TYPE',             N'PHC667',      N'1', N'INV_FORM_VAR', N'VAR196', N'NBS_Case_Answer.answer_txt', 2730,  '2026-04-01T00:00:00', N'ACTIVE', N'IGG_TEST_TYPE',             NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009163, 2, 1380, N'VAR_PAM', N'IGG_TEST_WHOLE_CELL_MFGR',  N'PHC671',      N'1', N'INV_FORM_VAR', N'VAR197', N'NBS_Case_Answer.answer_txt', 2700,  '2026-04-01T00:00:00', N'ACTIVE', N'IGG_TEST_WHOLE_CELL_MFGR',  NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009164, 2, 1039, N'VAR_PAM', N'IGG_TEST_GP_ELISA_MFGR',    N'MSD',         N'1', N'INV_FORM_VAR', N'VAR198', N'NBS_Case_Answer.answer_txt', 2720,  '2026-04-01T00:00:00', N'ACTIVE', N'IGG_TEST_GP_ELISA_MFGR',    NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009165, 2, 1330, N'VAR_PAM', N'IGG_TEST_OTHER',            N'NotApplicable',N'1',N'INV_FORM_VAR', N'VAR199', N'NBS_Case_Answer.answer_txt', NULL,  '2026-04-01T00:00:00', N'ACTIVE', N'IGG_TEST_OTHER',            NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009166, 2, 1311, N'VAR_PAM', N'IGG_TEST_ACUTE_DATE',       N'2026-03-29',  N'1', N'INV_FORM_VAR', N'VAR200', N'NBS_Case_Answer.answer_txt', NULL,  '2026-04-01T00:00:00', N'ACTIVE', N'IGG_TEST_ACUTE_DATE',       NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009167, 2, 1310, N'VAR_PAM', N'IGG_TEST_ACUTE_RESULT',     N'260385009',   N'1', N'INV_FORM_VAR', N'VAR201', N'NBS_Case_Answer.answer_txt', 2400,  '2026-04-01T00:00:00', N'ACTIVE', N'IGG_TEST_ACUTE_RESULT',     NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009168, 2, 1433, N'VAR_PAM', N'IGG_TEST_ACUTE_VALUE',      N'1.05',        N'1', N'INV_FORM_VAR', N'VAR202', N'NBS_Case_Answer.answer_txt', NULL,  '2026-04-01T00:00:00', N'ACTIVE', N'IGG_TEST_ACUTE_VALUE',      NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009169, 2, 1188, N'VAR_PAM', N'IGG_TEST_CONVALESCENT_DATE',N'2026-04-05',  N'1', N'INV_FORM_VAR', N'VAR203', N'NBS_Case_Answer.answer_txt', NULL,  '2026-04-01T00:00:00', N'ACTIVE', N'IGG_TEST_CONVALESCENT_DATE',NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009170, 2, 1209, N'VAR_PAM', N'IGG_TEST_CONVALESCENT_RESULT',N'10828004', N'1', N'INV_FORM_VAR', N'VAR204', N'NBS_Case_Answer.answer_txt', 2400,  '2026-04-01T00:00:00', N'ACTIVE', N'IGG_TEST_CONVALESCENT_RESULT',NULL,1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009171, 2, 1125, N'VAR_PAM', N'IGG_TEST_CONVALESCENT_VALUE',N'3.20',       N'1', N'INV_FORM_VAR', N'VAR205', N'NBS_Case_Answer.answer_txt', NULL,  '2026-04-01T00:00:00', N'ACTIVE', N'IGG_TEST_CONVALESCENT_VALUE',NULL,1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009172, 2, 1344, N'VAR_PAM', N'GENOTYPING_SENT_TO_CDC',    N'N',           N'1', N'INV_FORM_VAR', N'VAR206', N'NBS_Case_Answer.answer_txt', 4150,  '2026-04-01T00:00:00', N'ACTIVE', N'GENOTYPING_SENT_TO_CDC',    NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009173, 2, 1046, N'VAR_PAM', N'GENOTYPING_SENT_TO_CDC_DATE',N'2026-04-03', N'1', N'INV_FORM_VAR', N'VAR207', N'NBS_Case_Answer.answer_txt', NULL,  '2026-04-01T00:00:00', N'ACTIVE', N'GENOTYPING_SENT_TO_CDC_DATE',NULL,1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009174, 2, 1305, N'VAR_PAM', N'STRAIN_IDENTIFICATION_SENT',N'N',           N'1', N'INV_FORM_VAR', N'VAR208', N'NBS_Case_Answer.answer_txt', 4150,  '2026-04-01T00:00:00', N'ACTIVE', N'STRAIN_IDENTIFICATION_SENT',NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009175, 2, 1029, N'VAR_PAM', N'STRAIN_TYPE',               N'PHC126',      N'1', N'INV_FORM_VAR', N'VAR209', N'NBS_Case_Answer.answer_txt', 2800,  '2026-04-01T00:00:00', N'ACTIVE', N'STRAIN_TYPE',               NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009176, 2, 1374, N'VAR_PAM', N'MEDICATION_NAME_OTHER',     N'NotApplicable',N'1',N'INV_FORM_VAR', N'VAR210', N'NBS_Case_Answer.answer_txt', NULL,  '2026-04-01T00:00:00', N'ACTIVE', N'MEDICATION_NAME_OTHER',     NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009177, 2, 1431, N'VAR_PAM', N'FEVER_TEMPERATURE_UNIT',    N'[degF]',      N'1', N'INV_FORM_VAR', N'VAR211', N'NBS_Case_Answer.answer_txt', 2650,  '2026-04-01T00:00:00', N'ACTIVE', N'FEVER_TEMPERATURE_UNIT',    NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009178, 2, 1394, N'VAR_PAM', N'PREVIOUS_DIAGNOSIS_AGE_UNIT',N'Y',          N'1', N'INV_FORM_VAR', N'VAR212', N'NBS_Case_Answer.answer_txt', 70,    '2026-04-01T00:00:00', N'ACTIVE', N'PREVIOUS_DIAGNOSIS_AGE_UNIT',NULL,1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009179, 2, 1313, N'VAR_PAM', N'PATIENT_BIRTH_COUNTRY',     N'124',         N'1', N'INV_FORM_VAR', N'VAR215', N'NBS_Case_Answer.answer_txt', 3560,  '2026-04-01T00:00:00', N'ACTIVE', N'PATIENT_BIRTH_COUNTRY',     NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009180, 2, 1156, N'VAR_PAM', N'VACCINE_DATE_1',            N'2020-03-15',  N'1', N'INV_FORM_VAR', N'VAR216', N'NBS_Case_Answer.answer_txt', NULL,  '2026-04-01T00:00:00', N'ACTIVE', N'VACCINE_DATE_1',            NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009181, 2, 1189, N'VAR_PAM', N'VACCINE_TYPE_1',            N'21',          N'1', N'INV_FORM_VAR', N'VAR217', N'NBS_Case_Answer.answer_txt', 2820,  '2026-04-01T00:00:00', N'ACTIVE', N'VACCINE_TYPE_1',            NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009182, 2, 1154, N'VAR_PAM', N'VACCINE_MANUFACTURER_1',    N'MSD',         N'1', N'INV_FORM_VAR', N'VAR218', N'NBS_Case_Answer.answer_txt', 2830,  '2026-04-01T00:00:00', N'ACTIVE', N'VACCINE_MANUFACTURER_1',    NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009183, 2, 1401, N'VAR_PAM', N'VACCINE_LOT_1',             N'LOT-A-001',   N'1', N'INV_FORM_VAR', N'VAR219', N'NBS_Case_Answer.answer_txt', NULL,  '2026-04-01T00:00:00', N'ACTIVE', N'VACCINE_LOT_1',             NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009184, 2, 1312, N'VAR_PAM', N'VACCINE_DATE_2',            N'2020-05-15',  N'1', N'INV_FORM_VAR', N'VAR220', N'NBS_Case_Answer.answer_txt', NULL,  '2026-04-01T00:00:00', N'ACTIVE', N'VACCINE_DATE_2',            NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009185, 2, 1152, N'VAR_PAM', N'VACCINE_TYPE_2',            N'21',          N'1', N'INV_FORM_VAR', N'VAR221', N'NBS_Case_Answer.answer_txt', 2820,  '2026-04-01T00:00:00', N'ACTIVE', N'VACCINE_TYPE_2',            NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009186, 2, 1053, N'VAR_PAM', N'VACCINE_MANUFACTURER_2',    N'MSD',         N'1', N'INV_FORM_VAR', N'VAR222', N'NBS_Case_Answer.answer_txt', 2830,  '2026-04-01T00:00:00', N'ACTIVE', N'VACCINE_MANUFACTURER_2',    NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009187, 2, 1434, N'VAR_PAM', N'VACCINE_LOT_2',             N'LOT-A-002',   N'1', N'INV_FORM_VAR', N'VAR223', N'NBS_Case_Answer.answer_txt', NULL,  '2026-04-01T00:00:00', N'ACTIVE', N'VACCINE_LOT_2',             NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009188, 2, 1160, N'VAR_PAM', N'VACCINE_DATE_3',            N'2021-03-15',  N'1', N'INV_FORM_VAR', N'VAR224', N'NBS_Case_Answer.answer_txt', NULL,  '2026-04-01T00:00:00', N'ACTIVE', N'VACCINE_DATE_3',            NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009189, 2, 1397, N'VAR_PAM', N'VACCINE_TYPE_3',            N'21',          N'1', N'INV_FORM_VAR', N'VAR225', N'NBS_Case_Answer.answer_txt', 2820,  '2026-04-01T00:00:00', N'ACTIVE', N'VACCINE_TYPE_3',            NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009190, 2, 1368, N'VAR_PAM', N'VACCINE_MANUFACTURER_3',    N'MSD',         N'1', N'INV_FORM_VAR', N'VAR226', N'NBS_Case_Answer.answer_txt', 2830,  '2026-04-01T00:00:00', N'ACTIVE', N'VACCINE_MANUFACTURER_3',    NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009191, 2, 1052, N'VAR_PAM', N'VACCINE_LOT_3',             N'LOT-A-003',   N'1', N'INV_FORM_VAR', N'VAR227', N'NBS_Case_Answer.answer_txt', NULL,  '2026-04-01T00:00:00', N'ACTIVE', N'VACCINE_LOT_3',             NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009192, 2, 1215, N'VAR_PAM', N'VACCINE_DATE_4',            N'2022-03-15',  N'1', N'INV_FORM_VAR', N'VAR228', N'NBS_Case_Answer.answer_txt', NULL,  '2026-04-01T00:00:00', N'ACTIVE', N'VACCINE_DATE_4',            NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009193, 2, 1155, N'VAR_PAM', N'VACCINE_TYPE_4',            N'21',          N'1', N'INV_FORM_VAR', N'VAR229', N'NBS_Case_Answer.answer_txt', 2820,  '2026-04-01T00:00:00', N'ACTIVE', N'VACCINE_TYPE_4',            NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009194, 2, 1127, N'VAR_PAM', N'VACCINE_MANUFACTURER_4',    N'MSD',         N'1', N'INV_FORM_VAR', N'VAR230', N'NBS_Case_Answer.answer_txt', 2830,  '2026-04-01T00:00:00', N'ACTIVE', N'VACCINE_MANUFACTURER_4',    NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009195, 2, 1400, N'VAR_PAM', N'VACCINE_LOT_4',             N'LOT-A-004',   N'1', N'INV_FORM_VAR', N'VAR231', N'NBS_Case_Answer.answer_txt', NULL,  '2026-04-01T00:00:00', N'ACTIVE', N'VACCINE_LOT_4',             NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009196, 2, 1153, N'VAR_PAM', N'VACCINE_DATE_5',            N'2023-03-15',  N'1', N'INV_FORM_VAR', N'VAR232', N'NBS_Case_Answer.answer_txt', NULL,  '2026-04-01T00:00:00', N'ACTIVE', N'VACCINE_DATE_5',            NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009197, 2, 1050, N'VAR_PAM', N'VACCINE_TYPE_5',            N'21',          N'1', N'INV_FORM_VAR', N'VAR233', N'NBS_Case_Answer.answer_txt', 2820,  '2026-04-01T00:00:00', N'ACTIVE', N'VACCINE_TYPE_5',            NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009198, 2, 1340, N'VAR_PAM', N'VACCINE_MANUFACTURER_5',    N'MSD',         N'1', N'INV_FORM_VAR', N'VAR234', N'NBS_Case_Answer.answer_txt', 2830,  '2026-04-01T00:00:00', N'ACTIVE', N'VACCINE_MANUFACTURER_5',    NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009199, 2, 1435, N'VAR_PAM', N'VACCINE_LOT_5',             N'LOT-A-005',   N'1', N'INV_FORM_VAR', N'VAR235', N'NBS_Case_Answer.answer_txt', NULL,  '2026-04-01T00:00:00', N'ACTIVE', N'VACCINE_LOT_5',             NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active');
END
GO

-- Block B: multi-value VAR105 / VAR176 mirror (UIDs 22009200..22009203)
-- Distinct answer_group_seq_nbr values keep these as separate rows in
-- the D_RASH_LOC_GEN / D_PCR_SOURCE topic dim outputs, which the
-- var_datamart STRING_AGG then fans out into RASH_LOCATION_GENERAL_2/3
-- and PCR_TEST_SOURCE_2/3.
-- NOTE: the existing fixture's datamart_column_nm for VAR105 was set
-- as 'RASH_LOCATION_GENERAL' (uppercase). Re-using the same value here.
-- For VAR176 the existing fixture set 'PCR_TEST_SOURCE' so we use the
-- same datamart_column_nm.
IF NOT EXISTS (SELECT 1 FROM dbo.nrt_page_case_answer WHERE nbs_case_answer_uid BETWEEN 22009200 AND 22009203)
BEGIN
    INSERT INTO [dbo].[nrt_page_case_answer]
        ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid],
         [nbs_question_uid],
         [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr],
         [investigation_form_cd], [question_identifier], [data_location],
         [code_set_group_id], [last_chg_time], [record_status_cd],
         [datamart_column_nm], [ldf_status_cd], [seq_nbr], [batch_id],
         [nbs_ui_component_uid], [nca_add_time], [nuim_record_status_cd])
    VALUES
        (22002000, 22009200, 2, 1356, N'VAR_PAM', N'RASH_LOCATION_GENERAL', N'53120007',  N'2', N'INV_FORM_VAR', N'VAR105', N'NBS_Case_Answer.answer_txt', 2790, '2026-04-01T00:00:00', N'ACTIVE', N'RASH_LOCATION_GENERAL', NULL, 2, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009201, 2, 1356, N'VAR_PAM', N'RASH_LOCATION_GENERAL', N'61685007',  N'3', N'INV_FORM_VAR', N'VAR105', N'NBS_Case_Answer.answer_txt', 2790, '2026-04-01T00:00:00', N'ACTIVE', N'RASH_LOCATION_GENERAL', NULL, 3, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009202, 2, 1329, N'VAR_PAM', N'PCR_TEST_SOURCE',       N'119297000', N'2', N'INV_FORM_VAR', N'VAR176', N'NBS_Case_Answer.answer_txt', 2770, '2026-04-01T00:00:00', N'ACTIVE', N'PCR_TEST_SOURCE',       NULL, 2, NULL, 2, '2026-04-01T00:00:00', N'Active'),
        (22002000, 22009203, 2, 1329, N'VAR_PAM', N'PCR_TEST_SOURCE',       N'122575003', N'3', N'INV_FORM_VAR', N'VAR176', N'NBS_Case_Answer.answer_txt', 2770, '2026-04-01T00:00:00', N'ACTIVE', N'PCR_TEST_SOURCE',       NULL, 3, NULL, 2, '2026-04-01T00:00:00', N'Active');
END
GO

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
        (22009210, 22002000, '2026-04-01T00:00:00', 10009282, N'PHC222', 1143, 1, '2026-04-01T00:00:00', 10009282, N'ACTIVE', '2026-04-01T00:00:00', 0);
    SET IDENTITY_INSERT [dbo].[nbs_case_answer] OFF;
END
GO

USE [RDB_MODERN];
GO
IF NOT EXISTS (SELECT 1 FROM dbo.nrt_page_case_answer WHERE nbs_case_answer_uid = 22009210)
BEGIN
    INSERT INTO [dbo].[nrt_page_case_answer]
        ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid], [nbs_question_uid],
         [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr],
         [investigation_form_cd], [question_identifier], [data_location],
         [code_set_group_id], [last_chg_time], [record_status_cd],
         [datamart_column_nm], [ldf_status_cd], [seq_nbr], [batch_id],
         [nbs_ui_component_uid], [nca_add_time], [nuim_record_status_cd])
    VALUES
        (22002000, 22009210, 2, 1143, N'VAR_PAM', N'LESIONS_TOTAL', N'PHC222', N'1', N'INV_FORM_VAR', N'VAR100', N'NBS_Case_Answer.answer_txt', 2760, '2026-04-01T00:00:00', N'ACTIVE', N'LESIONS_TOTAL', NULL, 1, NULL, 2, '2026-04-01T00:00:00', N'Active');
END
GO

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

USE [RDB_MODERN];
GO
UPDATE dbo.nrt_page_case_answer SET answer_txt = N'60132005'
WHERE nbs_case_answer_uid = 22002101 AND question_identifier = N'VAR103' AND answer_txt = N'OTH';
GO

-- =====================================================================
-- Block E: enrich nrt_investigation row 22002000 with INV_COMMENTS,
-- ILLNESS_DURATION/UNIT, and a valid OUTBREAK_NAME code. These flow
-- through sp_nrt_investigation_postprocessing into INVESTIGATION dim,
-- whence the var_datamart SP picks them up as GENERAL_COMMENTS,
-- ILLNESS_DURATION, ILLNESS_DURATION_UNIT, OUTBREAK_NAME.
--
-- OUTBREAK_NM valid code (live 2026-05-24): 'MDK' = "Ketchup - McDonalds"
-- ILLNESS_DURATION_UNIT codeset = AGE_UNIT (e.g. 'D' = Day).
-- =====================================================================
USE [RDB_MODERN];
GO
-- Column name notes (verified live 2026-05-24):
--   nrt_investigation.txt                    -> INV_COMMENTS (NULLIF empty)
--   nrt_investigation.effective_duration_amt -> ILLNESS_DURATION (isnumeric)
--   nrt_investigation.illness_duration_unit  -> ILLNESS_DURATION_UNIT
--   nrt_investigation.outbreak_name          -> OUTBREAK_NAME (PHC->INVESTIGATION)
--                                               then var_datamart joins via
--                                               NRT_SRTE_CODE_VALUE_GENERAL
--                                               CODE_SET_NM='OUTBREAK_NM' to
--                                               surface CODE_SHORT_DESC_TXT
UPDATE dbo.nrt_investigation
SET txt                       = N'Varicella outbreak: index case linked epi-cluster',
    effective_duration_amt    = N'14',
    illness_duration_unit     = N'D',
    outbreak_name             = N'MDK'
WHERE public_health_case_uid = 22002000;
GO

-- The investigation event SP reads from NBS_ODSE.dbo.public_health_case +
-- friends; nrt_investigation is the RDB-side staging that the
-- investigation postprocessing SP reads. Re-run that SP to flow our
-- updates into the INVESTIGATION dim.
BEGIN TRY
    EXEC dbo.sp_nrt_investigation_postprocessing @id_list = N'22002000', @debug = 0;
END TRY
BEGIN CATCH
    PRINT 'zz_var_datamart_enrich: sp_nrt_investigation_postprocessing failed - ' + ERROR_MESSAGE();
END CATCH;
GO

-- =====================================================================
-- Block F: confirmation_method_group enrichment.
--   var_datamart.CONFIRMATION_METHOD_1 / _ALL / _DATE come from joining
--   confirmation_method_group (CMG) to confirmation_method (CM) via
--   CONFIRMATION_METHOD_KEY, filtered by INVESTIGATION_KEY = our
--   investigation. Baseline has 3 CM rows; CM key=4 is LD "Laboratory
--   confirmed". Insert a CMG row binding INV_KEY (looked up dynamically
--   from case_uid=22002000) to CM key=4. Idempotent: skip if exists.
--
--   INVESTIGATION_KEY is volatile across SP reseeds, so resolve at
--   apply time.
-- =====================================================================
DECLARE @inv_key BIGINT;
SELECT @inv_key = INVESTIGATION_KEY FROM dbo.INVESTIGATION WHERE CASE_UID = 22002000;

IF @inv_key IS NOT NULL
   AND NOT EXISTS (
       SELECT 1 FROM dbo.confirmation_method_group
       WHERE INVESTIGATION_KEY = @inv_key
   )
BEGIN
    INSERT INTO dbo.confirmation_method_group
        (INVESTIGATION_KEY, CONFIRMATION_METHOD_KEY, CONFIRMATION_DT)
    VALUES
        (@inv_key, 4, '2026-04-15T00:00:00');
END
GO

-- =====================================================================
-- Tail-EXEC: re-run the VAR-PAM SP chain so the new rows flow into
-- D_VAR_PAM / D_RASH_LOC_GEN / D_PCR_SOURCE / VAR_PAM_LDF / F_VAR_PAM /
-- VAR_DATAMART. Wrapped in TRY/CATCH so a SP failure does not abort
-- merge_and_verify.sh's pipeline (TB regression scar).
-- =====================================================================

BEGIN TRY
    EXEC dbo.sp_nrt_d_var_pam_postprocessing    @phc_uids    = N'22002000', @debug = 0;
END TRY
BEGIN CATCH
    PRINT 'zz_var_datamart_enrich: sp_nrt_d_var_pam_postprocessing failed - ' + ERROR_MESSAGE();
END CATCH;
GO

BEGIN TRY
    EXEC dbo.sp_nrt_d_rash_loc_gen_postprocessing @phc_uids   = N'22002000', @debug = 0;
END TRY
BEGIN CATCH
    PRINT 'zz_var_datamart_enrich: sp_nrt_d_rash_loc_gen_postprocessing failed - ' + ERROR_MESSAGE();
END CATCH;
GO

BEGIN TRY
    EXEC dbo.sp_nrt_d_pcr_source_postprocessing  @phc_id_list = N'22002000', @debug = 0;
END TRY
BEGIN CATCH
    PRINT 'zz_var_datamart_enrich: sp_nrt_d_pcr_source_postprocessing failed - ' + ERROR_MESSAGE();
END CATCH;
GO

BEGIN TRY
    EXEC dbo.sp_nrt_var_pam_ldf_postprocessing   @phc_uids    = N'22002000', @debug = 0;
END TRY
BEGIN CATCH
    PRINT 'zz_var_datamart_enrich: sp_nrt_var_pam_ldf_postprocessing failed - ' + ERROR_MESSAGE();
END CATCH;
GO

BEGIN TRY
    EXEC dbo.sp_f_var_pam_postprocessing         @phc_id_list = N'22002000', @debug = 0;
END TRY
BEGIN CATCH
    PRINT 'zz_var_datamart_enrich: sp_f_var_pam_postprocessing failed - ' + ERROR_MESSAGE();
END CATCH;
GO

BEGIN TRY
    EXEC dbo.sp_var_datamart_postprocessing      @phc_uids    = N'22002000', @debug = 0;
END TRY
BEGIN CATCH
    PRINT 'zz_var_datamart_enrich: sp_var_datamart_postprocessing failed - ' + ERROR_MESSAGE();
END CATCH;
GO
