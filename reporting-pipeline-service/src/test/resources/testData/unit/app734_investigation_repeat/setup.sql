-- APP-734: sp_sld_investigation_repeat_postprocessing
-- Bug #10 (D_REPT_KEY surrogate-key alloc) + Bug #13 (TEXT pivot NULL propagation).
-- Seeds one Pertussis Investigation (PHC 22006000) with 24 nrt_page_case_answer
-- rows (2 blocks x 3 seq x 4 data types) directly into RDB_MODERN, then runs the
-- chain. Pre-fix: bug #10 filters all new rows out (key stuck at sentinel 1) so
-- D_INVESTIGATION_REPEAT stays empty; even if rows landed, bug #13 leaves TEXT NULL.
-- Post-fix: rows land with key 2 and TEXT columns populated -> query.sql matches.
USE RDB_MODERN;
INSERT INTO [dbo].[nrt_investigation]
    ([public_health_case_uid], [patient_id], [program_jurisdiction_oid],
     [local_id], [shared_ind], [case_type_cd],
     [jurisdiction_cd], [record_status_cd], [mood_cd], [class_cd],
     [case_class_cd], [cd], [cd_desc_txt], [prog_area_cd],
     [investigation_form_cd], [case_management_uid],
     [investigation_status_cd], [investigation_status],
     [inv_case_status],
     [status_time], [record_status_time], [raw_record_status_cd],
     [add_user_id], [add_user_name], [add_time],
     [last_chg_user_id], [last_chg_user_name], [last_chg_time],
     [mmwr_week], [mmwr_year],
     [nac_page_case_uid],
     [outbreak_ind])
VALUES
    (22006000,                              -- public_health_case_uid
     20000000,                              -- patient_id (foundation Patient)
     22006000,                              -- program_jurisdiction_oid
     N'CAS22006000GA01',                    -- local_id
     N'T',                                  -- shared_ind
     N'I',                                  -- case_type_cd
     N'130001',                             -- jurisdiction_cd (Fulton)
     N'ACTIVE',                             -- record_status_cd
     N'EVN', N'CASE',                       -- mood_cd, class_cd
     N'C', N'10190', N'Pertussis', N'VAC',  -- case_class_cd, cd, cd_desc, prog
     N'PG_Pertussis_Investigation',         -- investigation_form_cd
     22006001,                              -- case_management_uid
     N'O', N'Open',
     N'Confirmed',
     '2026-04-01T00:00:00', '2026-04-01T00:00:00', N'ACTIVE',
     10009282, N'Foundation, Superuser', '2026-04-01T00:00:00',
     10009282, N'Foundation, Superuser', '2026-04-01T00:00:00',
     N'14', N'2026',
     22006000,                              -- nac_page_case_uid
     N'N');                                 -- outbreak_ind

-- ---------------------------------------------------------------------
-- nrt_page_case_answer rows. 24 rows = 2 BLOCK_NMs * 3 answer_group_seq_nbr
-- values * 4 data types each.
--
-- The SP at line 167 (#NBS_CASE_ANSWER_REPT seed) requires
-- nrt_page_case_answer.answer_group_seq_nbr IS NOT NULL.
-- The data-type branches additionally require question_group_seq_nbr
-- IS NOT NULL (lines 183-186 TEXT, lines 251-254 CODED, lines 645-647
-- DATE, lines 765-771 NUMERIC).
--
-- data_type values reference baseline NBS_SRTE codeset 'NBS_DATA_TYPE'
-- (TEXT, CODED, DATE, NUMERIC). These rows propagate from
-- nrt_srte_Code_value_general (the same SRTE table TB full-chain uses for
-- code resolution). Verified live 2026-05-21.
--
-- Each row carries a unique RDB_COLUMN_NM. The SP's dynamic ALTER TABLE
-- loop at line 1241 widens D_INVESTIGATION_REPEAT to include every
-- distinct RDB_COLUMN_NM it sees. With 8 distinct columns authored
-- (4 data types * 2 blocks), the dim should widen by +8 columns.
--
-- NOT-NULL columns required by nrt_page_case_answer DDL:
--   act_uid, nbs_case_answer_uid, nbs_ui_metadata_uid, nbs_question_uid,
--   record_status_cd.
-- nbs_ui_metadata_uid has no FK; we use a stable value (1).
-- ---------------------------------------------------------------------
INSERT INTO [dbo].[nrt_page_case_answer]
    ([act_uid], [nbs_case_answer_uid], [nbs_ui_metadata_uid],
     [nbs_question_uid],
     [rdb_table_nm], [rdb_column_nm], [answer_txt], [answer_group_seq_nbr],
     [investigation_form_cd], [question_identifier], [data_location],
     [code_set_group_id], [last_chg_time], [record_status_cd],
     [datamart_column_nm], [ldf_status_cd], [seq_nbr], [batch_id],
     [data_type], [question_group_seq_nbr], [block_nm],
     [unit_value], [unit_type_cd])
VALUES
    -- ===== BLOCK 1: TRAVEL_BLOCK — 3 seq groups * 4 data types =====
    -- seq 1: TEXT (rdb_column_nm = TRAVEL_LOCATION_TEXT)
    (22006000, 22006100, 1, 22006001, N'D_INVESTIGATION_REPEAT', N'TRAVEL_LOCATION_TEXT',
     N'San Francisco', 1, N'PG_Pertussis_Investigation', N'INV801',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'TRAVEL_LOCATION_TEXT', NULL, 1, NULL,
     N'TEXT', 1, N'TRAVEL_BLOCK', NULL, N'LITERAL'),
    -- seq 1: CODED (rdb_column_nm = TRAVEL_CODED_IND)
    (22006000, 22006101, 1, 22006002, N'D_INVESTIGATION_REPEAT', N'TRAVEL_CODED_IND',
     N'Y', 1, N'PG_Pertussis_Investigation', N'INV802',
     N'NBS_Case_Answer.answer_txt', 4150,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'TRAVEL_CODED_IND', NULL, 1, NULL,
     N'CODED', 1, N'TRAVEL_BLOCK', NULL, N'LITERAL'),
    -- seq 1: DATE (rdb_column_nm = TRAVEL_START_DT)
    (22006000, 22006102, 1, 22006003, N'D_INVESTIGATION_REPEAT', N'TRAVEL_START_DT',
     N'03/15/26', 1, N'PG_Pertussis_Investigation', N'INV803',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'TRAVEL_START_DT', NULL, 1, NULL,
     N'DATE', 1, N'TRAVEL_BLOCK', NULL, N'LITERAL'),
    -- seq 1: NUMERIC (rdb_column_nm = TRAVEL_DURATION_DAYS)
    (22006000, 22006103, 1, 22006004, N'D_INVESTIGATION_REPEAT', N'TRAVEL_DURATION_DAYS',
     N'7', 1, N'PG_Pertussis_Investigation', N'INV804',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'TRAVEL_DURATION_DAYS', NULL, 1, NULL,
     N'NUMERIC', 1, N'TRAVEL_BLOCK', NULL, N'LITERAL'),

    -- seq 2: TEXT
    (22006000, 22006104, 1, 22006001, N'D_INVESTIGATION_REPEAT', N'TRAVEL_LOCATION_TEXT',
     N'Seattle', 2, N'PG_Pertussis_Investigation', N'INV801',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'TRAVEL_LOCATION_TEXT', NULL, 1, NULL,
     N'TEXT', 1, N'TRAVEL_BLOCK', NULL, N'LITERAL'),
    -- seq 2: CODED
    (22006000, 22006105, 1, 22006002, N'D_INVESTIGATION_REPEAT', N'TRAVEL_CODED_IND',
     N'N', 2, N'PG_Pertussis_Investigation', N'INV802',
     N'NBS_Case_Answer.answer_txt', 4150,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'TRAVEL_CODED_IND', NULL, 1, NULL,
     N'CODED', 1, N'TRAVEL_BLOCK', NULL, N'LITERAL'),
    -- seq 2: DATE
    (22006000, 22006106, 1, 22006003, N'D_INVESTIGATION_REPEAT', N'TRAVEL_START_DT',
     N'03/22/26', 2, N'PG_Pertussis_Investigation', N'INV803',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'TRAVEL_START_DT', NULL, 1, NULL,
     N'DATE', 1, N'TRAVEL_BLOCK', NULL, N'LITERAL'),
    -- seq 2: NUMERIC
    (22006000, 22006107, 1, 22006004, N'D_INVESTIGATION_REPEAT', N'TRAVEL_DURATION_DAYS',
     N'5', 2, N'PG_Pertussis_Investigation', N'INV804',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'TRAVEL_DURATION_DAYS', NULL, 1, NULL,
     N'NUMERIC', 1, N'TRAVEL_BLOCK', NULL, N'LITERAL'),

    -- seq 3: TEXT
    (22006000, 22006108, 1, 22006001, N'D_INVESTIGATION_REPEAT', N'TRAVEL_LOCATION_TEXT',
     N'Portland', 3, N'PG_Pertussis_Investigation', N'INV801',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'TRAVEL_LOCATION_TEXT', NULL, 1, NULL,
     N'TEXT', 1, N'TRAVEL_BLOCK', NULL, N'LITERAL'),
    -- seq 3: CODED
    (22006000, 22006109, 1, 22006002, N'D_INVESTIGATION_REPEAT', N'TRAVEL_CODED_IND',
     N'U', 3, N'PG_Pertussis_Investigation', N'INV802',
     N'NBS_Case_Answer.answer_txt', 4150,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'TRAVEL_CODED_IND', NULL, 1, NULL,
     N'CODED', 1, N'TRAVEL_BLOCK', NULL, N'LITERAL'),
    -- seq 3: DATE
    (22006000, 22006110, 1, 22006003, N'D_INVESTIGATION_REPEAT', N'TRAVEL_START_DT',
     N'03/29/26', 3, N'PG_Pertussis_Investigation', N'INV803',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'TRAVEL_START_DT', NULL, 1, NULL,
     N'DATE', 1, N'TRAVEL_BLOCK', NULL, N'LITERAL'),
    -- seq 3: NUMERIC
    (22006000, 22006111, 1, 22006004, N'D_INVESTIGATION_REPEAT', N'TRAVEL_DURATION_DAYS',
     N'3', 3, N'PG_Pertussis_Investigation', N'INV804',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'TRAVEL_DURATION_DAYS', NULL, 1, NULL,
     N'NUMERIC', 1, N'TRAVEL_BLOCK', NULL, N'LITERAL'),

    -- ===== BLOCK 2: EXPOSURE_BLOCK — 3 seq groups * 4 data types =====
    -- seq 1: TEXT (rdb_column_nm = EXPOSURE_CONTACT_TYPE_TEXT)
    (22006000, 22006112, 1, 22006011, N'D_INVESTIGATION_REPEAT', N'EXPOSURE_CONTACT_TYPE_TEXT',
     N'Family member', 1, N'PG_Pertussis_Investigation', N'INV811',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'EXPOSURE_CONTACT_TYPE_TEXT', NULL, 1, NULL,
     N'TEXT', 1, N'EXPOSURE_BLOCK', NULL, N'LITERAL'),
    -- seq 1: CODED
    (22006000, 22006113, 1, 22006012, N'D_INVESTIGATION_REPEAT', N'EXPOSURE_CONFIRMED_IND',
     N'Y', 1, N'PG_Pertussis_Investigation', N'INV812',
     N'NBS_Case_Answer.answer_txt', 4150,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'EXPOSURE_CONFIRMED_IND', NULL, 1, NULL,
     N'CODED', 1, N'EXPOSURE_BLOCK', NULL, N'LITERAL'),
    -- seq 1: DATE
    (22006000, 22006114, 1, 22006013, N'D_INVESTIGATION_REPEAT', N'EXPOSURE_FIRST_DT',
     N'02/20/26', 1, N'PG_Pertussis_Investigation', N'INV813',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'EXPOSURE_FIRST_DT', NULL, 1, NULL,
     N'DATE', 1, N'EXPOSURE_BLOCK', NULL, N'LITERAL'),
    -- seq 1: NUMERIC
    (22006000, 22006115, 1, 22006014, N'D_INVESTIGATION_REPEAT', N'EXPOSURE_DURATION_DAYS',
     N'14', 1, N'PG_Pertussis_Investigation', N'INV814',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'EXPOSURE_DURATION_DAYS', NULL, 1, NULL,
     N'NUMERIC', 1, N'EXPOSURE_BLOCK', NULL, N'LITERAL'),

    -- seq 2: TEXT
    (22006000, 22006116, 1, 22006011, N'D_INVESTIGATION_REPEAT', N'EXPOSURE_CONTACT_TYPE_TEXT',
     N'Coworker', 2, N'PG_Pertussis_Investigation', N'INV811',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'EXPOSURE_CONTACT_TYPE_TEXT', NULL, 1, NULL,
     N'TEXT', 1, N'EXPOSURE_BLOCK', NULL, N'LITERAL'),
    -- seq 2: CODED
    (22006000, 22006117, 1, 22006012, N'D_INVESTIGATION_REPEAT', N'EXPOSURE_CONFIRMED_IND',
     N'Y', 2, N'PG_Pertussis_Investigation', N'INV812',
     N'NBS_Case_Answer.answer_txt', 4150,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'EXPOSURE_CONFIRMED_IND', NULL, 1, NULL,
     N'CODED', 1, N'EXPOSURE_BLOCK', NULL, N'LITERAL'),
    -- seq 2: DATE
    (22006000, 22006118, 1, 22006013, N'D_INVESTIGATION_REPEAT', N'EXPOSURE_FIRST_DT',
     N'02/25/26', 2, N'PG_Pertussis_Investigation', N'INV813',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'EXPOSURE_FIRST_DT', NULL, 1, NULL,
     N'DATE', 1, N'EXPOSURE_BLOCK', NULL, N'LITERAL'),
    -- seq 2: NUMERIC
    (22006000, 22006119, 1, 22006014, N'D_INVESTIGATION_REPEAT', N'EXPOSURE_DURATION_DAYS',
     N'21', 2, N'PG_Pertussis_Investigation', N'INV814',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'EXPOSURE_DURATION_DAYS', NULL, 1, NULL,
     N'NUMERIC', 1, N'EXPOSURE_BLOCK', NULL, N'LITERAL'),

    -- seq 3: TEXT
    (22006000, 22006120, 1, 22006011, N'D_INVESTIGATION_REPEAT', N'EXPOSURE_CONTACT_TYPE_TEXT',
     N'Classmate', 3, N'PG_Pertussis_Investigation', N'INV811',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'EXPOSURE_CONTACT_TYPE_TEXT', NULL, 1, NULL,
     N'TEXT', 1, N'EXPOSURE_BLOCK', NULL, N'LITERAL'),
    -- seq 3: CODED
    (22006000, 22006121, 1, 22006012, N'D_INVESTIGATION_REPEAT', N'EXPOSURE_CONFIRMED_IND',
     N'N', 3, N'PG_Pertussis_Investigation', N'INV812',
     N'NBS_Case_Answer.answer_txt', 4150,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'EXPOSURE_CONFIRMED_IND', NULL, 1, NULL,
     N'CODED', 1, N'EXPOSURE_BLOCK', NULL, N'LITERAL'),
    -- seq 3: DATE
    (22006000, 22006122, 1, 22006013, N'D_INVESTIGATION_REPEAT', N'EXPOSURE_FIRST_DT',
     N'03/02/26', 3, N'PG_Pertussis_Investigation', N'INV813',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'EXPOSURE_FIRST_DT', NULL, 1, NULL,
     N'DATE', 1, N'EXPOSURE_BLOCK', NULL, N'LITERAL'),
    -- seq 3: NUMERIC
    (22006000, 22006123, 1, 22006014, N'D_INVESTIGATION_REPEAT', N'EXPOSURE_DURATION_DAYS',
     N'10', 3, N'PG_Pertussis_Investigation', N'INV814',
     N'NBS_Case_Answer.answer_txt', NULL,
     '2026-04-01T00:00:00', N'ACTIVE',
     N'EXPOSURE_DURATION_DAYS', NULL, 1, NULL,
     N'NUMERIC', 1, N'EXPOSURE_BLOCK', NULL, N'LITERAL');

EXEC dbo.sp_nrt_investigation_postprocessing @id_list = N'22006000', @debug = 0;
EXEC dbo.sp_sld_investigation_repeat_postprocessing @batch_id = 22006000, @phc_id_list = N'22006000', @debug = 0;
