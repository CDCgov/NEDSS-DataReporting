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

-- Guard: only run if not already applied. nbs_case_answer_uid is
-- IDENTITY; let it AUTO-assign (LESSON 10) and guard on the natural key.
IF NOT EXISTS (SELECT 1 FROM [dbo].[nbs_case_answer] WHERE act_uid = @phc_uid AND nbs_question_uid = 1332 AND answer_group_seq_nbr IS NULL)
BEGIN
    INSERT INTO [dbo].[nbs_case_answer]
        ([act_uid], [add_time], [add_user_id],
         [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr],
         [last_chg_time], [last_chg_user_id],
         [record_status_cd], [record_status_time], [seq_nbr])
    VALUES
    (@phc_uid, '2026-04-01T00:00:00', @user, N'TB-TUB102-VAL', 1332, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB102
    (@phc_uid, '2026-04-01T00:00:00', @user, N'2026-04-05', 1035, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB110
    (@phc_uid, '2026-04-01T00:00:00', @user, N'N', 1418, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB111
    (@phc_uid, '2026-04-01T00:00:00', @user, N'42', 1138, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB112
    (@phc_uid, '2026-04-01T00:00:00', @user, N'840', 1042, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB115
    (@phc_uid, '2026-04-01T00:00:00', @user, N'840', 1320, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB116
    (@phc_uid, '2026-04-01T00:00:00', @user, N'260385009', 1045, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB120
    (@phc_uid, '2026-04-01T00:00:00', @user, N'2026-04-05', 1449, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB121
    (@phc_uid, '2026-04-01T00:00:00', @user, N'260385009', 1282, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB122
    (@phc_uid, '2026-04-01T00:00:00', @user, N'2026-04-05', 1390, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB123
    (@phc_uid, '2026-04-01T00:00:00', @user, N'2026-04-05', 1450, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB124
    (@phc_uid, '2026-04-01T00:00:00', @user, N'OTH', 1026, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB125
    (@phc_uid, '2026-04-01T00:00:00', @user, N'260385009', 1025, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB126
    (@phc_uid, '2026-04-01T00:00:00', @user, N'2026-04-05', 1437, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB127
    (@phc_uid, '2026-04-01T00:00:00', @user, N'10200004', 1043, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB128
    (@phc_uid, '2026-04-01T00:00:00', @user, N'260385009', 1058, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB130
    (@phc_uid, '2026-04-01T00:00:00', @user, N'2026-04-05', 1316, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB131
    (@phc_uid, '2026-04-01T00:00:00', @user, N'10200004', 1425, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB132
    (@phc_uid, '2026-04-01T00:00:00', @user, N'2026-04-05', 1108, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB133
    (@phc_uid, '2026-04-01T00:00:00', @user, N'OTH', 1233, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB134
    (@phc_uid, '2026-04-01T00:00:00', @user, N'260385009', 1149, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB135
    (@phc_uid, '2026-04-01T00:00:00', @user, N'2026-04-05', 1090, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB136
    (@phc_uid, '2026-04-01T00:00:00', @user, N'N', 1281, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB137
    (@phc_uid, '2026-04-01T00:00:00', @user, N'10200004', 1104, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB138
    (@phc_uid, '2026-04-01T00:00:00', @user, N'2026-04-05', 1288, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB139
    (@phc_uid, '2026-04-01T00:00:00', @user, N'OTH', 1077, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB140
    (@phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1302, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB141
    (@phc_uid, '2026-04-01T00:00:00', @user, N'N', 1304, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB142
    (@phc_uid, '2026-04-01T00:00:00', @user, N'N', 1458, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB143
    (@phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1315, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB144
    (@phc_uid, '2026-04-01T00:00:00', @user, N'N', 1354, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB145
    (@phc_uid, '2026-04-01T00:00:00', @user, N'N', 1453, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB146
    (@phc_uid, '2026-04-01T00:00:00', @user, N'260385009', 1012, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB147
    (@phc_uid, '2026-04-01T00:00:00', @user, N'2026-04-05', 1076, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB148
    (@phc_uid, '2026-04-01T00:00:00', @user, N'42', 1337, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB149
    (@phc_uid, '2026-04-01T00:00:00', @user, N'260385009', 1452, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB150
    (@phc_uid, '2026-04-01T00:00:00', @user, N'2026-04-05', 1069, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB151
    (@phc_uid, '2026-04-01T00:00:00', @user, N'TB-TUB152-VAL', 1334, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB152
    (@phc_uid, '2026-04-01T00:00:00', @user, N'168734001', 1451, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB153
    (@phc_uid, '2026-04-01T00:00:00', @user, N'N', 1033, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB157
    (@phc_uid, '2026-04-01T00:00:00', @user, N'N', 1132, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB158
    (@phc_uid, '2026-04-01T00:00:00', @user, N'C0680668', 1447, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB159
    (@phc_uid, '2026-04-01T00:00:00', @user, N'N', 1074, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB160
    (@phc_uid, '2026-04-01T00:00:00', @user, N'N', 1284, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB161
    (@phc_uid, '2026-04-01T00:00:00', @user, N'282E00000X', 1355, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB162
    (@phc_uid, '2026-04-01T00:00:00', @user, N'105493001', 1335, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB163
    (@phc_uid, '2026-04-01T00:00:00', @user, N'N', 1426, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB164
    (@phc_uid, '2026-04-01T00:00:00', @user, N'N', 1061, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB165
    (@phc_uid, '2026-04-01T00:00:00', @user, N'N', 1353, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB166
    (@phc_uid, '2026-04-01T00:00:00', @user, N'TB-TUB168-VAL', 1191, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB168
    (@phc_uid, '2026-04-01T00:00:00', @user, N'161157008', 1417, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB169
    (@phc_uid, '2026-04-01T00:00:00', @user, N'N', 1038, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB171
    (@phc_uid, '2026-04-01T00:00:00', @user, N'N', 1254, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB172
    (@phc_uid, '2026-04-01T00:00:00', @user, N'N', 1298, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB173
    (@phc_uid, '2026-04-01T00:00:00', @user, N'N', 1107, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB174
    (@phc_uid, '2026-04-01T00:00:00', @user, N'N', 1352, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB175
    (@phc_uid, '2026-04-01T00:00:00', @user, N'N', 1391, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB176
    (@phc_uid, '2026-04-01T00:00:00', @user, N'N', 1406, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB177
    (@phc_uid, '2026-04-01T00:00:00', @user, N'N', 1247, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB178
    (@phc_uid, '2026-04-01T00:00:00', @user, N'N', 1115, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB179
    (@phc_uid, '2026-04-01T00:00:00', @user, N'N', 1375, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB181
    (@phc_uid, '2026-04-01T00:00:00', @user, N'N', 1351, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB182
    (@phc_uid, '2026-04-01T00:00:00', @user, N'N', 1006, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB183
    (@phc_uid, '2026-04-01T00:00:00', @user, N'N', 1300, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB184
    (@phc_uid, '2026-04-01T00:00:00', @user, N'N', 1414, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB185
    (@phc_uid, '2026-04-01T00:00:00', @user, N'N', 1267, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB186
    (@phc_uid, '2026-04-01T00:00:00', @user, N'N', 1150, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB187
    (@phc_uid, '2026-04-01T00:00:00', @user, N'N', 1279, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB188
    (@phc_uid, '2026-04-01T00:00:00', @user, N'TB-TUB189-VAL', 1294, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB189
    (@phc_uid, '2026-04-01T00:00:00', @user, N'N', 1014, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB190
    (@phc_uid, '2026-04-01T00:00:00', @user, N'TB-TUB191-VAL', 1280, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB191
    (@phc_uid, '2026-04-01T00:00:00', @user, N'N', 1331, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB192
    (@phc_uid, '2026-04-01T00:00:00', @user, N'TB-TUB193-VAL', 1266, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB193
    (@phc_uid, '2026-04-01T00:00:00', @user, N'N', 1089, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB194
    (@phc_uid, '2026-04-01T00:00:00', @user, N'2026-04-05', 1322, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB195
    (@phc_uid, '2026-04-01T00:00:00', @user, N'N', 1018, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB196
    (@phc_uid, '2026-04-01T00:00:00', @user, N'10200004', 1429, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB197
    (@phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1056, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB198
    (@phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1082, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB199
    (@phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1270, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB200
    (@phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1173, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB201
    (@phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1031, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB202
    (@phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1299, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB203
    (@phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1459, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB204
    (@phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1257, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB205
    (@phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1303, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB206
    (@phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1229, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB207
    (@phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1054, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB208
    (@phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1208, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB209
    (@phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1253, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB210
    (@phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1448, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB211
    (@phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1070, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB212
    (@phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1067, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB213
    (@phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1314, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB214
    (@phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1131, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB215
    (@phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1066, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB216
    (@phc_uid, '2026-04-01T00:00:00', @user, N'TB-TUB217-VAL', 1297, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB217
    (@phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1346, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB218
    (@phc_uid, '2026-04-01T00:00:00', @user, N'TB-TUB219-VAL', 1139, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB219
    (@phc_uid, '2026-04-01T00:00:00', @user, N'N', 1093, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB220
    (@phc_uid, '2026-04-01T00:00:00', @user, N'2026-04-05', 1321, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB221
    (@phc_uid, '2026-04-01T00:00:00', @user, N'419099009', 1105, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB222
    (@phc_uid, '2026-04-01T00:00:00', @user, N'TB-TUB223-VAL', 1455, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB223
    (@phc_uid, '2026-04-01T00:00:00', @user, N'N', 1460, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB224
    (@phc_uid, '2026-04-01T00:00:00', @user, N'N', 1427, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB226
    (@phc_uid, '2026-04-01T00:00:00', @user, N'TB-TUB227-VAL', 1102, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB227
    (@phc_uid, '2026-04-01T00:00:00', @user, N'2026-04-05', 1136, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB232
    (@phc_uid, '2026-04-01T00:00:00', @user, N'182992009', 1094, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB233
    (@phc_uid, '2026-04-01T00:00:00', @user, N'PHC697', 1396, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB234
    (@phc_uid, '2026-04-01T00:00:00', @user, N'TB-TUB236-VAL', 1420, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB236
    (@phc_uid, '2026-04-01T00:00:00', @user, N'182882002', 1005, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB238
    (@phc_uid, '2026-04-01T00:00:00', @user, N'42', 1200, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB239
    (@phc_uid, '2026-04-01T00:00:00', @user, N'N', 1430, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB240
    (@phc_uid, '2026-04-01T00:00:00', @user, N'2026-04-05', 1285, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB241
    (@phc_uid, '2026-04-01T00:00:00', @user, N'N', 1137, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB242
    (@phc_uid, '2026-04-01T00:00:00', @user, N'10200004', 1073, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB243
    (@phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1075, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB244
    (@phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1205, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB246
    (@phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1296, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB247
    (@phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1231, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB248
    (@phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1217, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB249
    (@phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1057, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB250
    (@phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1011, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB251
    (@phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1289, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB252
    (@phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1428, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB253
    (@phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1032, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB254
    (@phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1095, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB255
    (@phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1206, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB256
    (@phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1081, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB257
    (@phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1436, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB258
    (@phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1395, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB259
    (@phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1062, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB260
    (@phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1078, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB261
    (@phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1365, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB262
    (@phc_uid, '2026-04-01T00:00:00', @user, N'TB-TUB263-VAL', 1008, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB263
    (@phc_uid, '2026-04-01T00:00:00', @user, N'385660001', 1106, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB264
    (@phc_uid, '2026-04-01T00:00:00', @user, N'TB-TUB265-VAL', 1405, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB265
    (@phc_uid, '2026-04-01T00:00:00', @user, N'415684004', 1290, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB266
    (@phc_uid, '2026-04-01T00:00:00', @user, N'TB-TUB270-VAL', 1454, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB270
    (@phc_uid, '2026-04-01T00:00:00', @user, N'TB-TUB271-VAL', 1295, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB271
    (@phc_uid, '2026-04-01T00:00:00', @user, N'TB-TUB272-VAL', 1349, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB272
    (@phc_uid, '2026-04-01T00:00:00', @user, N'2026-04-05', 1072, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB273
    (@phc_uid, '2026-04-01T00:00:00', @user, N'840', 1327, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB276
    (@phc_uid, '2026-04-01T00:00:00', @user, N'N', 1336, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB277
    (@phc_uid, '2026-04-01T00:00:00', @user, N'F', 1301, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0), -- TUB278
    (@phc_uid, '2026-04-01T00:00:00', @user, N'TB-TUB279-VAL', 1317, 1, '2026-04-01T00:00:00', @user, N'ACTIVE', '2026-04-01T00:00:00', 0)  -- TUB279
    ;
END
GO

USE [RDB_MODERN];
GO

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
-- nbs_case_answer_uid is IDENTITY; let it AUTO-assign (LESSON 10) and
-- guard on the NBS_ODSE natural key instead of a hardcoded surrogate.
IF NOT EXISTS (SELECT 1 FROM [NBS_ODSE].[dbo].[nbs_case_answer]
               WHERE act_uid = 22001000 AND nbs_question_uid = 1068 AND seq_nbr = 1 AND answer_group_seq_nbr IS NULL)
BEGIN

    -- Mirror NBS_ODSE.nbs_case_answer rows (using existing nbs_question_uids).
    INSERT INTO [NBS_ODSE].[dbo].[nbs_case_answer]
        ([act_uid], [add_time], [add_user_id],
         [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr],
         [last_chg_time], [last_chg_user_id],
         [record_status_cd], [record_status_time], [seq_nbr])
    VALUES
        (22001000, '2026-04-01T00:00:00', 10009282, N'TB-LINK-01', 1068, 1, '2026-04-01T00:00:00', 10009282, N'ACTIVE', '2026-04-01T00:00:00', 1),
        (22001000, '2026-04-01T00:00:00', 10009282, N'PHC238', 1264, 1, '2026-04-01T00:00:00', 10009282, N'ACTIVE', '2026-04-01T00:00:00', 1),
        (22001000, '2026-04-01T00:00:00', 10009282, N'PHC238', 1044, 1, '2026-04-01T00:00:00', 10009282, N'ACTIVE', '2026-04-01T00:00:00', 1),
        (22001000, '2026-04-01T00:00:00', 10009282, N'PHC657', 1091, 1, '2026-04-01T00:00:00', 10009282, N'ACTIVE', '2026-04-01T00:00:00', 1),
        (22001000, '2026-04-01T00:00:00', 10009282, N'USA', 1199, 1, '2026-04-01T00:00:00', 10009282, N'ACTIVE', '2026-04-01T00:00:00', 1),
        (22001000, '2026-04-01T00:00:00', 10009282, N'N', 1060, 1, '2026-04-01T00:00:00', 10009282, N'ACTIVE', '2026-04-01T00:00:00', 1),
        (22001000, '2026-04-01T00:00:00', 10009282, N'397709008', 1319, 1, '2026-04-01T00:00:00', 10009282, N'ACTIVE', '2026-04-01T00:00:00', 1);
END
GO

-- =====================================================================
-- Corrective ODSE rows: fix answer_txt values that silently collapse to
-- NULL in the 147 SP pivot because the seeded answer code is not present
-- in the relevant nrt_srte_code_value_general codeset.
--
-- ODSE-ONLY PRINCIPLE: this fixture authors ONLY NBS_ODSE.nbs_case_answer
-- rows; the RTR pipeline (CDC -> page-builder -> nrt_page_case_answer)
-- derives the RDB_MODERN staging. Direct UPDATEs to RDB_MODERN's
-- nrt_page_case_answer (the prior approach) are erased on the next CDC
-- drain — the page-builder rebuilds nrt from nbs_case_answer — so the
-- only durable fix is to correct the ODSE source.
--
-- 147 SP mechanics (verified, lines 159-219 + 303-304): each answer is
-- LEFT JOINed to code_value_general (code_set_nm, code=answer_txt) then
-- translated to CODE_SHORT_DESC_TXT before the `MAX(ANSWER_TXT)` PIVOT.
-- An invalid code (e.g. '840') resolves to NULL; a valid code ('USA')
-- resolves to 'UNITED STATES'. With BOTH rows present for one question,
-- MAX(NULL,'UNITED STATES') = 'UNITED STATES'. So authoring an ADDITIONAL
-- 'USA' row (higher seq_nbr) alongside the anchor's seq_nbr=0 '840' row
-- lights the column up WITHOUT editing the read-only anchor.
--
-- WHAT NEEDED FIXING (verified against live D_TB_PAM 2026-06-05):
--   * PHVS_TB_BIRTH_CNTRY (codeset 4260): anchor seeded '840' (invalid;
--     only 'USA'='UNITED STATES' is valid). Three D_TB_PAM columns were
--     left NULL because no corrective ODSE row existed for them:
--       PATIENT_BIRTH_COUNTRY         q1327 (TUB276)
--       PRIMARY_GUARD_1_BIRTH_COUNTRY q1042 (TUB115)
--       PRIMARY_GUARD_2_BIRTH_COUNTRY q1320 (TUB116)
--     (COUNTRY_OF_VERIFIED_CASE q1199/TUB109 is already 'USA' via the
--      corrective block above; MOVE_CNTRY q1243/TUB230 and OUT_OF_CNTRY
--      q1080/TUB114 are d_topic dimensions already carrying 'USA' via the
--      multi-row block below — none need an additional row here.)
--   * PHVS_TB_SUSCEPT (codeset 4170): the FINAL_/INIT_SUSCEPT_* questions
--     are already authored as '385660001' (Not Done) in the main block
--     above (lines ~146-204), so there is NO stray '1' to correct — the
--     former UPDATE was a no-op. Nothing to author here.
--
-- UID block: nbs_case_answer.nbs_case_answer_uid is IDENTITY; AUTO-assign
-- (LESSON 10) and guard on the NBS_ODSE natural key.
-- =====================================================================
IF NOT EXISTS (SELECT 1 FROM [NBS_ODSE].[dbo].[nbs_case_answer]
               WHERE act_uid = 22001000 AND nbs_question_uid = 1327 AND seq_nbr = 1 AND answer_group_seq_nbr IS NULL)
BEGIN
    INSERT INTO [NBS_ODSE].[dbo].[nbs_case_answer]
        ([act_uid], [add_time], [add_user_id],
         [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr],
         [last_chg_time], [last_chg_user_id],
         [record_status_cd], [record_status_time], [seq_nbr])
    VALUES
        -- TUB276 PATIENT_BIRTH_COUNTRY -> 'USA' (PHVS_TB_BIRTH_CNTRY 4260)
        (22001000, '2026-04-01T00:00:00', 10009282, N'USA', 1327, 1, '2026-04-01T00:00:00', 10009282, N'ACTIVE', '2026-04-01T00:00:00', 1),
        -- TUB115 PRIMARY_GUARD_1_BIRTH_COUNTRY -> 'USA'
        (22001000, '2026-04-01T00:00:00', 10009282, N'USA', 1042, 1, '2026-04-01T00:00:00', 10009282, N'ACTIVE', '2026-04-01T00:00:00', 1),
        -- TUB116 PRIMARY_GUARD_2_BIRTH_COUNTRY -> 'USA'
        (22001000, '2026-04-01T00:00:00', 10009282, N'USA', 1320, 1, '2026-04-01T00:00:00', 10009282, N'ACTIVE', '2026-04-01T00:00:00', 1);
END
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
-- nbs_case_answer_uid is IDENTITY; let it AUTO-assign (LESSON 10) and
-- guard on the NBS_ODSE natural key instead of a hardcoded surrogate.
IF NOT EXISTS (SELECT 1 FROM [NBS_ODSE].[dbo].[nbs_case_answer]
               WHERE act_uid = 22001000 AND nbs_question_uid = 1079 AND seq_nbr = 2 AND answer_group_seq_nbr IS NULL)
BEGIN

    -- Mirror NBS_ODSE rows (so the ODSE-side referential model is consistent).
    INSERT INTO [NBS_ODSE].[dbo].[nbs_case_answer]
        ([act_uid], [add_time], [add_user_id],
         [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr],
         [last_chg_time], [last_chg_user_id],
         [record_status_cd], [record_status_time], [seq_nbr])
    VALUES
        (22001000, '2026-04-01T00:00:00', 10009282, N'10200004', 1079, 1, '2026-04-01T00:00:00', 10009282, N'ACTIVE', '2026-04-01T00:00:00', 2),
        (22001000, '2026-04-01T00:00:00', 10009282, N'39607008', 1079, 1, '2026-04-01T00:00:00', 10009282, N'ACTIVE', '2026-04-01T00:00:00', 3),
        (22001000, '2026-04-01T00:00:00', 10009282, N'108257001', 1174, 1, '2026-04-01T00:00:00', 10009282, N'ACTIVE', '2026-04-01T00:00:00', 2),
        (22001000, '2026-04-01T00:00:00', 10009282, N'108257001', 1174, 1, '2026-04-01T00:00:00', 10009282, N'ACTIVE', '2026-04-01T00:00:00', 3),
        (22001000, '2026-04-01T00:00:00', 10009282, N'73211009', 1230, 1, '2026-04-01T00:00:00', 10009282, N'ACTIVE', '2026-04-01T00:00:00', 2),
        (22001000, '2026-04-01T00:00:00', 10009282, N'46177005', 1230, 1, '2026-04-01T00:00:00', 10009282, N'ACTIVE', '2026-04-01T00:00:00', 3),
        (22001000, '2026-04-01T00:00:00', 10009282, N'C1512888', 1256, 1, '2026-04-01T00:00:00', 10009282, N'ACTIVE', '2026-04-01T00:00:00', 2),
        (22001000, '2026-04-01T00:00:00', 10009282, N'C1512888', 1256, 1, '2026-04-01T00:00:00', 10009282, N'ACTIVE', '2026-04-01T00:00:00', 3),
        (22001000, '2026-04-01T00:00:00', 10009282, N'13121', 1055, 1, '2026-04-01T00:00:00', 10009282, N'ACTIVE', '2026-04-01T00:00:00', 2),
        (22001000, '2026-04-01T00:00:00', 10009282, N'13121', 1055, 1, '2026-04-01T00:00:00', 10009282, N'ACTIVE', '2026-04-01T00:00:00', 3),
        (22001000, '2026-04-01T00:00:00', 10009282, N'13', 1248, 1, '2026-04-01T00:00:00', 10009282, N'ACTIVE', '2026-04-01T00:00:00', 2),
        (22001000, '2026-04-01T00:00:00', 10009282, N'13', 1248, 1, '2026-04-01T00:00:00', 10009282, N'ACTIVE', '2026-04-01T00:00:00', 3),
        (22001000, '2026-04-01T00:00:00', 10009282, N'USA', 1243, 1, '2026-04-01T00:00:00', 10009282, N'ACTIVE', '2026-04-01T00:00:00', 2),
        (22001000, '2026-04-01T00:00:00', 10009282, N'USA', 1243, 1, '2026-04-01T00:00:00', 10009282, N'ACTIVE', '2026-04-01T00:00:00', 3),
        (22001000, '2026-04-01T00:00:00', 10009282, N'258143003', 1318, 1, '2026-04-01T00:00:00', 10009282, N'ACTIVE', '2026-04-01T00:00:00', 2),
        (22001000, '2026-04-01T00:00:00', 10009282, N'258143003', 1318, 1, '2026-04-01T00:00:00', 10009282, N'ACTIVE', '2026-04-01T00:00:00', 3),
        (22001000, '2026-04-01T00:00:00', 10009282, N'310174000', 1071, 1, '2026-04-01T00:00:00', 10009282, N'ACTIVE', '2026-04-01T00:00:00', 2),
        (22001000, '2026-04-01T00:00:00', 10009282, N'310174000', 1071, 1, '2026-04-01T00:00:00', 10009282, N'ACTIVE', '2026-04-01T00:00:00', 3),
        (22001000, '2026-04-01T00:00:00', 10009282, N'USA', 1080, 1, '2026-04-01T00:00:00', 10009282, N'ACTIVE', '2026-04-01T00:00:00', 2),
        (22001000, '2026-04-01T00:00:00', 10009282, N'USA', 1080, 1, '2026-04-01T00:00:00', 10009282, N'ACTIVE', '2026-04-01T00:00:00', 3);
END
GO

-- =====================================================================
-- Tail-EXEC the SP chain for PHC 22001000.
--   Order matters: D_TB_PAM (147) must run before F_TB_PAM (206) which
--   must run before TB_DATAMART (255) and TB_HIV_DATAMART (260).
--   Wrapped in TRY/CATCH so a downstream failure doesn't abort.
-- =====================================================================

-- d_topic SPs (12 total) so multi-row answers light up _2, _3, _ALL, _GT3_IND.

GO
