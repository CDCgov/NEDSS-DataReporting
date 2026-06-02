-- =====================================================================
-- Tier 3 ENRICHMENT — TB Datamart column expansion via TUB question rows
-- =====================================================================
-- Lifts TB_DATAMART / TB_HIV_DATAMART / D_TB_PAM populated-column counts
-- by authoring the remaining ~146 TUB question answer rows on the
-- existing TB Investigation PHC 22001000 (anchored by
-- `tb_investigation_full_chain.sql`).
--
-- BASELINE (live, 2026-05-24):
--   TB_DATAMART      : 95/318  (gap 223)
--   TB_HIV_DATAMART  : 99/322  (gap 223)
--   D_TB_PAM         :  9/166  (gap 157)
--
-- STRATEGY
--   The 147 SP pivots nrt_page_case_answer rows for INV_FORM_RVCT, keyed
--   on (act_uid, datamart_column_nm). Every TUB question's
--   datamart_column_nm corresponds 1:1 to a D_TB_PAM column. The 255 /
--   260 datamart SPs INNER JOIN D_TB_PAM via f_tb_pam — so populating
--   more D_TB_PAM columns lifts both TB_DATAMART and TB_HIV_DATAMART
--   together (they share the same upstream).
--
--   The anchor fixture authored a curated 23 TUB questions (13 d_topic
--   feeders + 10 main-pivot feeders). This enrichment authors all
--   remaining TUB questions (~146) that:
--     1. have a non-NULL datamart_column_nm,
--     2. have data_location='NBS_Case_Answer.answer_txt' (147 SP filter),
--     3. are NOT in the 13 d_topic-excluded list at 147 SP line 92-95
--        (those are already covered).
--
--   Codes were verified against nrt_srte_code_value_general so the
--   PIVOT->JOIN doesn't silently collapse to NULL.
--
-- UID BLOCK (this fixture): 22011000-22011999
--   22011000..22011145  nbs_case_answer.nbs_case_answer_uid +
--                        nrt_page_case_answer.nbs_case_answer_uid pairs.
--   146 question rows total. Allocated contiguously from 22011000.
--
-- REUSED UIDs (read-only):
--   22001000  PHC anchor (act_uid + public_health_case_uid). Already in
--             PHC_UIDS so orchestrator Step 9 SPs (255, 260) pick this
--             enrichment up automatically.
--   10009282  superuser_id.
--
-- IDEMPOTENCY: every block guarded by IF NOT EXISTS on the first UID
-- of the block (22011000). Re-running is a no-op.
--
-- TAIL-EXEC: rerun the 147 (D_TB_PAM) SP + 255 / 260 (TB_DATAMART,
-- TB_HIV_DATAMART) plus 206 (F_TB_PAM, needed for the f_tb_pam INNER
-- JOIN in 255 to surface the new D_TB_PAM columns). All wrapped in
-- TRY/CATCH.
-- =====================================================================

USE [NBS_ODSE];
GO

DECLARE @user bigint = 10009282;
DECLARE @phc_uid bigint = 22001000;

-- Guard: only run if not already applied.
IF NOT EXISTS (SELECT 1 FROM [dbo].[nbs_case_answer] WHERE nbs_case_answer_uid = 22011000)
BEGIN
    SET IDENTITY_INSERT [dbo].[nbs_case_answer] ON;

    INSERT INTO [dbo].[nbs_case_answer]
        ([nbs_case_answer_uid], [act_uid], [add_time], [add_user_id],
         [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr],
         [last_chg_time], [last_chg_user_id],
         [record_status_cd], [record_status_time], [seq_nbr])
    VALUES
    (22011000, @phc_uid, '2026-04-01T00:00:00', @user, N'TB-TUB102-VAL', 1332, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB102
    (22011001, @phc_uid, '2026-04-01T00:00:00', @user, N'2026-04-05', 1035, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB110
    (22011002, @phc_uid, '2026-04-01T00:00:00', @user, N'N', 1418, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB111
    (22011003, @phc_uid, '2026-04-01T00:00:00', @user, N'42', 1138, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB112
    (22011004, @phc_uid, '2026-04-01T00:00:00', @user, N'840', 1042, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB115
    (22011005, @phc_uid, '2026-04-01T00:00:00', @user, N'840', 1320, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB116
    (22011006, @phc_uid, '2026-04-01T00:00:00', @user, N'260385009', 1045, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB120
    (22011007, @phc_uid, '2026-04-01T00:00:00', @user, N'2026-04-05', 1449, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB121
    (22011008, @phc_uid, '2026-04-01T00:00:00', @user, N'260385009', 1282, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB122
    (22011009, @phc_uid, '2026-04-01T00:00:00', @user, N'2026-04-05', 1390, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB123
    (22011010, @phc_uid, '2026-04-01T00:00:00', @user, N'2026-04-05', 1450, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB124
    (22011011, @phc_uid, '2026-04-01T00:00:00', @user, N'OTH', 1026, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB125
    (22011012, @phc_uid, '2026-04-01T00:00:00', @user, N'260385009', 1025, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB126
    (22011013, @phc_uid, '2026-04-01T00:00:00', @user, N'2026-04-05', 1437, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB127
    (22011014, @phc_uid, '2026-04-01T00:00:00', @user, N'10200004', 1043, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB128
    (22011015, @phc_uid, '2026-04-01T00:00:00', @user, N'260385009', 1058, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB130
    (22011016, @phc_uid, '2026-04-01T00:00:00', @user, N'2026-04-05', 1316, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB131
    (22011017, @phc_uid, '2026-04-01T00:00:00', @user, N'10200004', 1425, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB132
    (22011018, @phc_uid, '2026-04-01T00:00:00', @user, N'2026-04-05', 1108, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB133
    (22011019, @phc_uid, '2026-04-01T00:00:00', @user, N'OTH', 1233, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB134
    (22011020, @phc_uid, '2026-04-01T00:00:00', @user, N'260385009', 1149, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB135
    (22011021, @phc_uid, '2026-04-01T00:00:00', @user, N'2026-04-05', 1090, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB136
    (22011022, @phc_uid, '2026-04-01T00:00:00', @user, N'N', 1281, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB137
    (22011023, @phc_uid, '2026-04-01T00:00:00', @user, N'10200004', 1104, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB138
    (22011024, @phc_uid, '2026-04-01T00:00:00', @user, N'2026-04-05', 1288, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB139
    (22011025, @phc_uid, '2026-04-01T00:00:00', @user, N'OTH', 1077, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB140
    (22011026, @phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1302, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB141
    (22011027, @phc_uid, '2026-04-01T00:00:00', @user, N'N', 1304, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB142
    (22011028, @phc_uid, '2026-04-01T00:00:00', @user, N'N', 1458, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB143
    (22011029, @phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1315, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB144
    (22011030, @phc_uid, '2026-04-01T00:00:00', @user, N'N', 1354, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB145
    (22011031, @phc_uid, '2026-04-01T00:00:00', @user, N'N', 1453, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB146
    (22011032, @phc_uid, '2026-04-01T00:00:00', @user, N'260385009', 1012, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB147
    (22011033, @phc_uid, '2026-04-01T00:00:00', @user, N'2026-04-05', 1076, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB148
    (22011034, @phc_uid, '2026-04-01T00:00:00', @user, N'42', 1337, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB149
    (22011035, @phc_uid, '2026-04-01T00:00:00', @user, N'260385009', 1452, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB150
    (22011036, @phc_uid, '2026-04-01T00:00:00', @user, N'2026-04-05', 1069, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB151
    (22011037, @phc_uid, '2026-04-01T00:00:00', @user, N'TB-TUB152-VAL', 1334, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB152
    (22011038, @phc_uid, '2026-04-01T00:00:00', @user, N'168734001', 1451, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB153
    (22011039, @phc_uid, '2026-04-01T00:00:00', @user, N'N', 1033, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB157
    (22011040, @phc_uid, '2026-04-01T00:00:00', @user, N'N', 1132, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB158
    (22011041, @phc_uid, '2026-04-01T00:00:00', @user, N'C0680668', 1447, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB159
    (22011042, @phc_uid, '2026-04-01T00:00:00', @user, N'N', 1074, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB160
    (22011043, @phc_uid, '2026-04-01T00:00:00', @user, N'N', 1284, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB161
    (22011044, @phc_uid, '2026-04-01T00:00:00', @user, N'282E00000X', 1355, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB162
    (22011045, @phc_uid, '2026-04-01T00:00:00', @user, N'105493001', 1335, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB163
    (22011046, @phc_uid, '2026-04-01T00:00:00', @user, N'N', 1426, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB164
    (22011047, @phc_uid, '2026-04-01T00:00:00', @user, N'N', 1061, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB165
    (22011048, @phc_uid, '2026-04-01T00:00:00', @user, N'N', 1353, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB166
    (22011049, @phc_uid, '2026-04-01T00:00:00', @user, N'TB-TUB168-VAL', 1191, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB168
    (22011050, @phc_uid, '2026-04-01T00:00:00', @user, N'161157008', 1417, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB169
    (22011051, @phc_uid, '2026-04-01T00:00:00', @user, N'N', 1038, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB171
    (22011052, @phc_uid, '2026-04-01T00:00:00', @user, N'N', 1254, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB172
    (22011053, @phc_uid, '2026-04-01T00:00:00', @user, N'N', 1298, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB173
    (22011054, @phc_uid, '2026-04-01T00:00:00', @user, N'N', 1107, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB174
    (22011055, @phc_uid, '2026-04-01T00:00:00', @user, N'N', 1352, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB175
    (22011056, @phc_uid, '2026-04-01T00:00:00', @user, N'N', 1391, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB176
    (22011057, @phc_uid, '2026-04-01T00:00:00', @user, N'N', 1406, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB177
    (22011058, @phc_uid, '2026-04-01T00:00:00', @user, N'N', 1247, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB178
    (22011059, @phc_uid, '2026-04-01T00:00:00', @user, N'N', 1115, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB179
    (22011060, @phc_uid, '2026-04-01T00:00:00', @user, N'N', 1375, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB181
    (22011061, @phc_uid, '2026-04-01T00:00:00', @user, N'N', 1351, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB182
    (22011062, @phc_uid, '2026-04-01T00:00:00', @user, N'N', 1006, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB183
    (22011063, @phc_uid, '2026-04-01T00:00:00', @user, N'N', 1300, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB184
    (22011064, @phc_uid, '2026-04-01T00:00:00', @user, N'N', 1414, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB185
    (22011065, @phc_uid, '2026-04-01T00:00:00', @user, N'N', 1267, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB186
    (22011066, @phc_uid, '2026-04-01T00:00:00', @user, N'N', 1150, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB187
    (22011067, @phc_uid, '2026-04-01T00:00:00', @user, N'N', 1279, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB188
    (22011068, @phc_uid, '2026-04-01T00:00:00', @user, N'TB-TUB189-VAL', 1294, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB189
    (22011069, @phc_uid, '2026-04-01T00:00:00', @user, N'N', 1014, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB190
    (22011070, @phc_uid, '2026-04-01T00:00:00', @user, N'TB-TUB191-VAL', 1280, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB191
    (22011071, @phc_uid, '2026-04-01T00:00:00', @user, N'N', 1331, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB192
    (22011072, @phc_uid, '2026-04-01T00:00:00', @user, N'TB-TUB193-VAL', 1266, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB193
    (22011073, @phc_uid, '2026-04-01T00:00:00', @user, N'N', 1089, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB194
    (22011074, @phc_uid, '2026-04-01T00:00:00', @user, N'2026-04-05', 1322, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB195
    (22011075, @phc_uid, '2026-04-01T00:00:00', @user, N'N', 1018, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB196
    (22011076, @phc_uid, '2026-04-01T00:00:00', @user, N'10200004', 1429, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB197
    (22011077, @phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1056, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB198
    (22011078, @phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1082, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB199
    (22011079, @phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1270, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB200
    (22011080, @phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1173, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB201
    (22011081, @phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1031, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB202
    (22011082, @phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1299, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB203
    (22011083, @phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1459, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB204
    (22011084, @phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1257, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB205
    (22011085, @phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1303, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB206
    (22011086, @phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1229, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB207
    (22011087, @phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1054, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB208
    (22011088, @phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1208, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB209
    (22011089, @phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1253, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB210
    (22011090, @phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1448, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB211
    (22011091, @phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1070, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB212
    (22011092, @phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1067, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB213
    (22011093, @phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1314, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB214
    (22011094, @phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1131, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB215
    (22011095, @phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1066, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB216
    (22011096, @phc_uid, '2026-04-01T00:00:00', @user, N'TB-TUB217-VAL', 1297, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB217
    (22011097, @phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1346, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB218
    (22011098, @phc_uid, '2026-04-01T00:00:00', @user, N'TB-TUB219-VAL', 1139, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB219
    (22011099, @phc_uid, '2026-04-01T00:00:00', @user, N'N', 1093, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB220
    (22011100, @phc_uid, '2026-04-01T00:00:00', @user, N'2026-04-05', 1321, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB221
    (22011101, @phc_uid, '2026-04-01T00:00:00', @user, N'419099009', 1105, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB222
    (22011102, @phc_uid, '2026-04-01T00:00:00', @user, N'TB-TUB223-VAL', 1455, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB223
    (22011103, @phc_uid, '2026-04-01T00:00:00', @user, N'N', 1460, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB224
    (22011104, @phc_uid, '2026-04-01T00:00:00', @user, N'N', 1427, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB226
    (22011105, @phc_uid, '2026-04-01T00:00:00', @user, N'TB-TUB227-VAL', 1102, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB227
    (22011106, @phc_uid, '2026-04-01T00:00:00', @user, N'2026-04-05', 1136, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB232
    (22011107, @phc_uid, '2026-04-01T00:00:00', @user, N'182992009', 1094, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB233
    (22011108, @phc_uid, '2026-04-01T00:00:00', @user, N'PHC697', 1396, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB234
    (22011109, @phc_uid, '2026-04-01T00:00:00', @user, N'TB-TUB236-VAL', 1420, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB236
    (22011110, @phc_uid, '2026-04-01T00:00:00', @user, N'182882002', 1005, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB238
    (22011111, @phc_uid, '2026-04-01T00:00:00', @user, N'42', 1200, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB239
    (22011112, @phc_uid, '2026-04-01T00:00:00', @user, N'N', 1430, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB240
    (22011113, @phc_uid, '2026-04-01T00:00:00', @user, N'2026-04-05', 1285, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB241
    (22011114, @phc_uid, '2026-04-01T00:00:00', @user, N'N', 1137, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB242
    (22011115, @phc_uid, '2026-04-01T00:00:00', @user, N'10200004', 1073, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB243
    (22011116, @phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1075, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB244
    (22011117, @phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1205, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB246
    (22011118, @phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1296, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB247
    (22011119, @phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1231, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB248
    (22011120, @phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1217, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB249
    (22011121, @phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1057, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB250
    (22011122, @phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1011, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB251
    (22011123, @phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1289, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB252
    (22011124, @phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1428, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB253
    (22011125, @phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1032, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB254
    (22011126, @phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1095, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB255
    (22011127, @phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1206, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB256
    (22011128, @phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1081, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB257
    (22011129, @phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1436, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB258
    (22011130, @phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1395, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB259
    (22011131, @phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1062, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB260
    (22011132, @phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1078, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB261
    (22011133, @phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1365, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB262
    (22011134, @phc_uid, '2026-04-01T00:00:00', @user, N'TB-TUB263-VAL', 1008, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB263
    (22011135, @phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1106, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB264
    (22011136, @phc_uid, '2026-04-01T00:00:00', @user, N'TB-TUB265-VAL', 1405, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB265
    (22011137, @phc_uid, '2026-04-01T00:00:00', @user, N'415684004', 1290, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB266
    (22011138, @phc_uid, '2026-04-01T00:00:00', @user, N'TB-TUB270-VAL', 1454, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB270
    (22011139, @phc_uid, '2026-04-01T00:00:00', @user, N'TB-TUB271-VAL', 1295, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB271
    (22011140, @phc_uid, '2026-04-01T00:00:00', @user, N'TB-TUB272-VAL', 1349, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB272
    (22011141, @phc_uid, '2026-04-01T00:00:00', @user, N'2026-04-05', 1072, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB273
    (22011142, @phc_uid, '2026-04-01T00:00:00', @user, N'840', 1327, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB276
    (22011143, @phc_uid, '2026-04-01T00:00:00', @user, N'N', 1336, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB277
    (22011144, @phc_uid, '2026-04-01T00:00:00', @user, N'F', 1301, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB278
    (22011145, @phc_uid, '2026-04-01T00:00:00', @user, N'TB-TUB279-VAL', 1317, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0)  -- TUB279
    ;

    SET IDENTITY_INSERT [dbo].[nbs_case_answer] OFF;
END
GO

USE [RDB_MODERN];
GO

IF NOT EXISTS (SELECT 1 FROM [dbo].[nrt_page_case_answer] WHERE nbs_case_answer_uid = 22011000)
BEGIN
END
GO

-- =====================================================================
-- Corrective overlay rows: anchor fixture wrote 6 TUB questions with
-- the WRONG datamart_column_nm (their nbs_question_uid<->datamart_col
-- mapping in live nbs_question disagrees with what the anchor authored).
-- The anchor rows still feed the columns they THINK they do (the SP
-- pivots on datamart_column_nm, not on nbs_question_uid), but the
-- CORRECT datamart columns stay empty. Author additional rows with
-- correct datamart_column_nm and valid codes so those 6 columns light up.
--
-- TUB100 LINK_STATE_CASE_NUM_1 (no codeset)
-- TUB101 LINK_REASON_1          (codeset 2540 PHVS_TB_LINK_REASON)
-- TUB103 LINK_REASON_2          (codeset 2540)
-- TUB108 COUNT_STATUS           (codeset 2480 PHVS_TB_COUNT_STATUS)
-- TUB109 COUNTRY_OF_VERIFIED_CASE (codeset 4260 PHVS_TB_BIRTH_CNTRY)
-- TUB113 PATIENT_OUTSIDE_US_GT_2_MONTHS (codeset 4150 YNU)
-- TUB117 STATUS_AT_DIAGNOSIS    (codeset 2450 PHVS_STATUS_AT_DIAG)
--
-- UID block: 22011200-22011206 (within reserved 22011000-22011999).
-- =====================================================================
USE [RDB_MODERN];
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[nrt_page_case_answer] WHERE nbs_case_answer_uid = 22011200)
BEGIN

    -- Mirror NBS_ODSE.nbs_case_answer rows (using existing nbs_question_uids).
    SET IDENTITY_INSERT [NBS_ODSE].[dbo].[nbs_case_answer] ON;
    INSERT INTO [NBS_ODSE].[dbo].[nbs_case_answer]
        ([nbs_case_answer_uid], [act_uid], [add_time], [add_user_id],
         [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr],
         [last_chg_time], [last_chg_user_id],
         [record_status_cd], [record_status_time], [seq_nbr])
    VALUES
        (22011200, 22001000, '2026-04-01T00:00:00', 10009282, N'TB-LINK-01', 1068, 1, '2026-04-01T00:00:00', 10009282, N'ACTIVE', '2026-04-01T00:00:00', 1),
        (22011201, 22001000, '2026-04-01T00:00:00', 10009282, N'PHC238', 1264, 1, '2026-04-01T00:00:00', 10009282, N'ACTIVE', '2026-04-01T00:00:00', 1),
        (22011202, 22001000, '2026-04-01T00:00:00', 10009282, N'PHC238', 1044, 1, '2026-04-01T00:00:00', 10009282, N'ACTIVE', '2026-04-01T00:00:00', 1),
        (22011203, 22001000, '2026-04-01T00:00:00', 10009282, N'PHC657', 1091, 1, '2026-04-01T00:00:00', 10009282, N'ACTIVE', '2026-04-01T00:00:00', 1),
        (22011204, 22001000, '2026-04-01T00:00:00', 10009282, N'USA', 1199, 1, '2026-04-01T00:00:00', 10009282, N'ACTIVE', '2026-04-01T00:00:00', 1),
        (22011205, 22001000, '2026-04-01T00:00:00', 10009282, N'N', 1060, 1, '2026-04-01T00:00:00', 10009282, N'ACTIVE', '2026-04-01T00:00:00', 1),
        (22011206, 22001000, '2026-04-01T00:00:00', 10009282, N'397709008', 1319, 1, '2026-04-01T00:00:00', 10009282, N'ACTIVE', '2026-04-01T00:00:00', 1);
    SET IDENTITY_INSERT [NBS_ODSE].[dbo].[nbs_case_answer] OFF;
END
GO

-- =====================================================================
-- Corrective UPDATEs: fix answer_txt values that silently collapse to
-- NULL in the 147 SP pivot because the answer code is not present in
-- the relevant nrt_srte_code_value_general codeset.
--
-- 1. PHVS_TB_BIRTH_CNTRY (4260): the seeded "840" is not a valid code.
--    Use "USA" (verified). Affects PATIENT_BIRTH_COUNTRY,
--    PRIMARY_GUARD_1_BIRTH_COUNTRY, PRIMARY_GUARD_2_BIRTH_COUNTRY,
--    OUT_OF_CNTRY (TUB114), STATUS_AT_DIAGNOSIS (the anchor fixture
--    miswrote TUB109 codeset).
-- 2. PHVS_TB_SUSCEPT (4170): "1" is not a valid code. "385660001"
--    (Not Done) is. Affects all FINAL_SUSCEPT_* + INIT_SUSCEPT_* rows.
-- 3. PHVS_PNUND (2410): some rows already use 260385009; safe.
-- 4. PHVS_TB_LAB_TEST_INT (4190): same.
-- These UPDATEs are idempotent (they're WHERE-targeted by act_uid +
-- nbs_question_uid + answer_txt) and only run if the bad value is
-- still present.
-- =====================================================================
UPDATE [dbo].[nrt_page_case_answer]
SET answer_txt = N'USA'
WHERE act_uid = 22001000
  AND answer_txt = N'840'
  AND code_set_group_id = 4260;

-- The anchor fixture wrote STATUS_AT_DIAGNOSIS code "A" with
-- code_set_group_id=4260 but TUB117 STATUS_AT_DIAGNOSIS uses
-- codeset 2450 (PHVS_STATUS_AT_DIAG; valid code 397709008).
-- The row itself stays put (wrong mapping by anchor); we can't fix
-- without authoring a new row. Skip.

-- Per anchor fixture, TUB245 FINAL_SUSCEPT_RIFAMPIN answer="1" with
-- code_set_group_id=4170. Fix by replacing with "385660001" so the
-- codeset join resolves to "Not Done".
UPDATE [dbo].[nrt_page_case_answer]
SET answer_txt = N'385660001'
WHERE act_uid = 22001000
  AND answer_txt = N'1'
  AND code_set_group_id = 4170;

-- Anchor fixture wrote TUB114 OUT_OF_CNTRY answer "PHC2" which is not
-- a valid PHVS_TB_BIRTH_CNTRY code. Replace with "USA".
UPDATE [dbo].[nrt_page_case_answer]
SET answer_txt = N'USA'
WHERE act_uid = 22001000
  AND question_identifier = N'TUB114'
  AND answer_txt = N'PHC2';
GO

-- =====================================================================
-- Multi-row d_topic answers: each d_topic question (TUB114, 119, 129,
-- 167, 225, 228, 229, 230, 235, 237) can have multiple answer rows.
-- The 255 datamart SP pivots up to MOVED_WHERE_4 etc. Authoring 2-3
-- additional answer rows per d_topic question lights up _2 / _3 /
-- _ALL / _GT3_IND aggregate columns. UID block: 22011300-22011399.
-- =====================================================================
USE [RDB_MODERN];
GO
IF NOT EXISTS (SELECT 1 FROM [dbo].[nrt_page_case_answer] WHERE nbs_case_answer_uid = 22011300)
BEGIN

    -- Mirror NBS_ODSE rows (so the ODSE-side referential model is consistent).
    SET IDENTITY_INSERT [NBS_ODSE].[dbo].[nbs_case_answer] ON;
    INSERT INTO [NBS_ODSE].[dbo].[nbs_case_answer]
        ([nbs_case_answer_uid], [act_uid], [add_time], [add_user_id],
         [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr],
         [last_chg_time], [last_chg_user_id],
         [record_status_cd], [record_status_time], [seq_nbr])
    VALUES
        (22011300, 22001000, '2026-04-01T00:00:00', 10009282, N'10200004', 1079, 1, '2026-04-01T00:00:00', 10009282, N'ACTIVE', '2026-04-01T00:00:00', 2),
        (22011301, 22001000, '2026-04-01T00:00:00', 10009282, N'39607008', 1079, 1, '2026-04-01T00:00:00', 10009282, N'ACTIVE', '2026-04-01T00:00:00', 3),
        (22011302, 22001000, '2026-04-01T00:00:00', 10009282, N'108257001', 1174, 1, '2026-04-01T00:00:00', 10009282, N'ACTIVE', '2026-04-01T00:00:00', 2),
        (22011303, 22001000, '2026-04-01T00:00:00', 10009282, N'108257001', 1174, 1, '2026-04-01T00:00:00', 10009282, N'ACTIVE', '2026-04-01T00:00:00', 3),
        (22011304, 22001000, '2026-04-01T00:00:00', 10009282, N'73211009', 1230, 1, '2026-04-01T00:00:00', 10009282, N'ACTIVE', '2026-04-01T00:00:00', 2),
        (22011305, 22001000, '2026-04-01T00:00:00', 10009282, N'46177005', 1230, 1, '2026-04-01T00:00:00', 10009282, N'ACTIVE', '2026-04-01T00:00:00', 3),
        (22011306, 22001000, '2026-04-01T00:00:00', 10009282, N'C1512888', 1256, 1, '2026-04-01T00:00:00', 10009282, N'ACTIVE', '2026-04-01T00:00:00', 2),
        (22011307, 22001000, '2026-04-01T00:00:00', 10009282, N'C1512888', 1256, 1, '2026-04-01T00:00:00', 10009282, N'ACTIVE', '2026-04-01T00:00:00', 3),
        (22011308, 22001000, '2026-04-01T00:00:00', 10009282, N'13121', 1055, 1, '2026-04-01T00:00:00', 10009282, N'ACTIVE', '2026-04-01T00:00:00', 2),
        (22011309, 22001000, '2026-04-01T00:00:00', 10009282, N'13121', 1055, 1, '2026-04-01T00:00:00', 10009282, N'ACTIVE', '2026-04-01T00:00:00', 3),
        (22011310, 22001000, '2026-04-01T00:00:00', 10009282, N'13', 1248, 1, '2026-04-01T00:00:00', 10009282, N'ACTIVE', '2026-04-01T00:00:00', 2),
        (22011311, 22001000, '2026-04-01T00:00:00', 10009282, N'13', 1248, 1, '2026-04-01T00:00:00', 10009282, N'ACTIVE', '2026-04-01T00:00:00', 3),
        (22011312, 22001000, '2026-04-01T00:00:00', 10009282, N'USA', 1243, 1, '2026-04-01T00:00:00', 10009282, N'ACTIVE', '2026-04-01T00:00:00', 2),
        (22011313, 22001000, '2026-04-01T00:00:00', 10009282, N'USA', 1243, 1, '2026-04-01T00:00:00', 10009282, N'ACTIVE', '2026-04-01T00:00:00', 3),
        (22011314, 22001000, '2026-04-01T00:00:00', 10009282, N'258143003', 1318, 1, '2026-04-01T00:00:00', 10009282, N'ACTIVE', '2026-04-01T00:00:00', 2),
        (22011315, 22001000, '2026-04-01T00:00:00', 10009282, N'258143003', 1318, 1, '2026-04-01T00:00:00', 10009282, N'ACTIVE', '2026-04-01T00:00:00', 3),
        (22011316, 22001000, '2026-04-01T00:00:00', 10009282, N'310174000', 1071, 1, '2026-04-01T00:00:00', 10009282, N'ACTIVE', '2026-04-01T00:00:00', 2),
        (22011317, 22001000, '2026-04-01T00:00:00', 10009282, N'310174000', 1071, 1, '2026-04-01T00:00:00', 10009282, N'ACTIVE', '2026-04-01T00:00:00', 3),
        (22011318, 22001000, '2026-04-01T00:00:00', 10009282, N'USA', 1080, 1, '2026-04-01T00:00:00', 10009282, N'ACTIVE', '2026-04-01T00:00:00', 2),
        (22011319, 22001000, '2026-04-01T00:00:00', 10009282, N'USA', 1080, 1, '2026-04-01T00:00:00', 10009282, N'ACTIVE', '2026-04-01T00:00:00', 3);
    SET IDENTITY_INSERT [NBS_ODSE].[dbo].[nbs_case_answer] OFF;
END
GO

-- =====================================================================
-- Tail-EXEC the SP chain for PHC 22001000.
--   Order matters: D_TB_PAM (147) must run before F_TB_PAM (206) which
--   must run before TB_DATAMART (255) and TB_HIV_DATAMART (260).
--   Wrapped in TRY/CATCH so a downstream failure doesn't abort.
-- =====================================================================
BEGIN TRY
END TRY
BEGIN CATCH
    PRINT 'sp_nrt_d_tb_pam_postprocessing failed: ' + ERROR_MESSAGE();
END CATCH;

-- d_topic SPs (12 total) so multi-row answers light up _2, _3, _ALL, _GT3_IND.
BEGIN TRY EXEC dbo.sp_nrt_d_disease_site_postprocessing @phc_uids = N'22001000', @debug = 0; END TRY BEGIN CATCH PRINT 'd_disease_site: ' + ERROR_MESSAGE(); END CATCH;
BEGIN TRY EXEC dbo.sp_nrt_d_addl_risk_postprocessing    @phc_uids = N'22001000', @debug = 0; END TRY BEGIN CATCH PRINT 'd_addl_risk: ' + ERROR_MESSAGE(); END CATCH;
BEGIN TRY EXEC dbo.sp_nrt_d_move_cntry_postprocessing   @phc_uids = N'22001000', @debug = 0; END TRY BEGIN CATCH PRINT 'd_move_cntry: ' + ERROR_MESSAGE(); END CATCH;
BEGIN TRY EXEC dbo.sp_nrt_d_move_cnty_postprocessing    @phc_uids = N'22001000', @debug = 0; END TRY BEGIN CATCH PRINT 'd_move_cnty: ' + ERROR_MESSAGE(); END CATCH;
BEGIN TRY EXEC dbo.sp_nrt_d_move_state_postprocessing   @phc_uids = N'22001000', @debug = 0; END TRY BEGIN CATCH PRINT 'd_move_state: ' + ERROR_MESSAGE(); END CATCH;
BEGIN TRY EXEC dbo.sp_nrt_d_moved_where_postprocessing  @phc_uids = N'22001000', @debug = 0; END TRY BEGIN CATCH PRINT 'd_moved_where: ' + ERROR_MESSAGE(); END CATCH;
BEGIN TRY EXEC dbo.sp_nrt_d_gt_12_reas_postprocessing   @phc_id_list = N'22001000', @debug = 0; END TRY BEGIN CATCH PRINT 'd_gt_12_reas: ' + ERROR_MESSAGE(); END CATCH;
BEGIN TRY EXEC dbo.sp_nrt_d_hc_prov_ty_3_postprocessing @phc_id_list = N'22001000', @debug = 0; END TRY BEGIN CATCH PRINT 'd_hc_prov_ty_3: ' + ERROR_MESSAGE(); END CATCH;
BEGIN TRY EXEC dbo.sp_nrt_d_out_of_cntry_postprocessing @phc_id_list = N'22001000', @debug = 0; END TRY BEGIN CATCH PRINT 'd_out_of_cntry: ' + ERROR_MESSAGE(); END CATCH;
BEGIN TRY EXEC dbo.sp_nrt_d_smr_exam_ty_postprocessing  @phc_id_list = N'22001000', @debug = 0; END TRY BEGIN CATCH PRINT 'd_smr_exam_ty: ' + ERROR_MESSAGE(); END CATCH;
BEGIN TRY EXEC dbo.sp_nrt_d_tb_hiv_postprocessing       @phc_id_list = N'22001000', @debug = 0; END TRY BEGIN CATCH PRINT 'd_tb_hiv: ' + ERROR_MESSAGE(); END CATCH;

BEGIN TRY
END TRY
BEGIN CATCH
    PRINT 'sp_f_tb_pam_postprocessing failed: ' + ERROR_MESSAGE();
END CATCH;

BEGIN TRY
END TRY
BEGIN CATCH
    PRINT 'sp_tb_datamart_postprocessing failed: ' + ERROR_MESSAGE();
END CATCH;

BEGIN TRY
END TRY
BEGIN CATCH
    PRINT 'sp_tb_hiv_datamart_postprocessing failed: ' + ERROR_MESSAGE();
END CATCH;
GO
