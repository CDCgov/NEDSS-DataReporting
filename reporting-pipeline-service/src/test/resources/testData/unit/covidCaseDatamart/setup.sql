USE [NBS_ODSE];

-- Cleanup existing data to ensure a clean state
DELETE FROM [dbo].[NBS_act_entity] WHERE [act_uid] = 10009289;
DELETE FROM [dbo].[Participation] WHERE [act_uid] = 10009289;
DELETE FROM [dbo].[Act_id] WHERE [act_uid] = 10009289;
DELETE FROM [dbo].[Public_health_case] WHERE [public_health_case_uid] = 10009289;
DELETE FROM [dbo].[Act] WHERE [act_uid] = 10009289;
DELETE FROM [dbo].[Person_race] WHERE [person_uid] = 10009283;
DELETE FROM [dbo].[Person_name] WHERE [person_uid] = 10009283;
DELETE FROM [dbo].[Person] WHERE [person_uid] = 10009283;
DELETE FROM [dbo].[Entity] WHERE [entity_uid] = 10009283;
DELETE FROM [dbo].[NBS_case_answer] WHERE [act_uid] = 10009289;

-- Cleanup NRT and D tables
DELETE FROM rdb_modern.dbo.nrt_investigation WHERE public_health_case_uid = 10009289;
DELETE FROM rdb_modern.dbo.nrt_patient WHERE patient_uid = 10009283;
DELETE FROM rdb_modern.dbo.D_PATIENT WHERE patient_uid = 10009283;
DELETE FROM rdb_modern.dbo.nrt_srte_Condition_code WHERE condition_cd = '11065';
DELETE FROM rdb_modern.dbo.nrt_srte_Jurisdiction_code WHERE code = '130001';
DELETE FROM rdb_modern.dbo.nrt_page_case_answer WHERE act_uid = 10009289;

-- Seed ODSE Data
INSERT INTO [dbo].[Entity] (entity_uid, class_cd) VALUES (10009283, 'PSN');

INSERT INTO [dbo].[Person] (person_uid, add_time, add_user_id, age_reported, age_reported_unit_cd, birth_time, birth_time_calc, cd, curr_sex_cd, deceased_ind_cd, last_chg_time, last_chg_user_id, local_id, record_status_cd, record_status_time, status_cd, status_time, first_nm, last_nm, version_ctrl_nbr) 
VALUES (10009283, '2026-04-24T23:15:09.073', 10009282, '36', 'Y', '1990-01-01T00:00:00', '1990-01-01T00:00:00', 'PAT', 'M', 'Y', '2026-04-24T23:15:09.073', 10009282, 'PSN10063000GA01', 'ACTIVE', '2026-04-24T23:15:09.073', 'A', '2026-04-24T23:15:09.073', 'Surma', 'Singh', 1);

INSERT INTO [dbo].[Person_name] (person_uid, person_name_seq, add_time, add_user_id, first_nm, last_chg_time, last_chg_user_id, last_nm, nm_use_cd, record_status_cd, record_status_time, status_cd, status_time) 
VALUES (10009283, 1, '2026-04-24T23:15:07.563', 10009282, 'Surma', '2026-04-24T23:15:07.563', 10009282, 'Singh', 'L', 'ACTIVE', '2026-04-24T23:15:07.563', 'A', '2026-04-24T23:15:07.563');

INSERT INTO [dbo].[Act] (act_uid, class_cd, mood_cd) VALUES (10009289, 'CASE', 'EVN');

INSERT INTO [dbo].[Public_health_case] (public_health_case_uid, activity_from_time, add_time, add_user_id, cd, cd_desc_txt, jurisdiction_cd, last_chg_time, last_chg_user_id, local_id, mmwr_week, mmwr_year, prog_area_cd, record_status_cd, record_status_time, status_cd, version_ctrl_nbr) 
VALUES (10009289, '2026-04-24T00:00:00', '2026-04-24T23:15:09.197', 10009282, '11065', '2019 Novel Coronavirus', '130001', '2026-04-24T23:15:09.197', 10009282, 'CAS10001000GA01', '16', '2026', 'GCD', 'ACTIVE', '2026-04-24T23:15:09.197', 'A', 1);

INSERT INTO [dbo].[Participation] (subject_entity_uid, act_uid, type_cd, act_class_cd, add_time, add_user_id, last_chg_time, last_chg_user_id, record_status_cd, record_status_time, status_cd, status_time, subject_class_cd) 
VALUES (10009283, 10009289, 'SubjOfPHC', 'CASE', '2026-04-24T23:15:07.597', 10009282, '2026-04-24T23:15:07.597', 10009282, 'ACTIVE', '2026-04-24T23:15:07.607', 'A', '2026-04-24T23:15:07.607', 'PSN');

-- Seed Metadata
INSERT INTO rdb_modern.dbo.nrt_srte_Condition_code (condition_cd, nnd_ind, reportable_morbidity_ind, reportable_summary_ind, investigation_form_cd)
VALUES ('11065', 'Y', 'Y', 'Y', 'PG_COVID-19_v1.1');

INSERT INTO rdb_modern.dbo.nrt_srte_Jurisdiction_code (code, type_cd, code_desc_txt, code_short_desc_txt)
VALUES ('130001', 'JUR', 'Fulton County', 'Fulton County');

-- Seed NRT Data
INSERT INTO rdb_modern.dbo.nrt_investigation (public_health_case_uid, cd, local_id, record_status_cd, patient_id, jurisdiction_cd, add_time, last_chg_time)
VALUES (10009289, '11065', 'CAS10001000GA01', 'ACTIVE', 10009283, '130001', '2026-04-24T23:15:09.197', '2026-04-24T23:15:09.197');

INSERT INTO rdb_modern.dbo.nrt_patient (patient_uid, local_id, first_name, last_name, record_status, status_name_cd, nm_use_cd)
VALUES (10009283, 'PSN10063000GA01', 'Surma', 'Singh', 'ACTIVE', 'A', 'L');

-- Seed D_PATIENT
INSERT INTO rdb_modern.dbo.D_PATIENT (patient_uid, patient_key, patient_local_id, patient_record_status) 
VALUES (10009283, 10009283, 'PSN10063000GA01', 'ACTIVE');

-- Seed NRT_PAGE_CASE_ANSWER (Mandatory answers for datamart joins)
INSERT INTO rdb_modern.dbo.nrt_page_case_answer (act_uid, nbs_case_answer_uid, nbs_question_uid, answer_txt, record_status_cd, investigation_form_cd)
VALUES (10009289, 3241, 10004138, 'CEPUI', 'ACTIVE', 'PG_COVID-19_v1.1');
