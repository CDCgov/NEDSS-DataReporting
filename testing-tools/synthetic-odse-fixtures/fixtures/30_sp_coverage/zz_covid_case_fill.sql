-- =====================================================================
-- Tier 3 (NO-SHORTCUT) — COVID_CASE_DATAMART repeating-group fill
-- =====================================================================
-- Branch: aw/remove-nrt-shortcut. ODSE-ONLY fixture: authors NBS_ODSE
-- rows only. NO nrt_* INSERTs, NO EXEC sp_*, NO liquibase/seed/SRTE
-- edits. The real pipeline (CDC/Debezium -> kafka-connect sink ->
-- reporting-pipeline-service page-builder + sp_covid_case_datamart_
-- postprocessing) turns these ODSE answers into datamart columns.
--
-- TARGET
--   dbo.COVID_CASE_DATAMART (383 cols), single COVID PHC 22003000
--   (condition 11065, form PG_COVID-19_v1.1). Baseline = 209/383
--   populated; 174 NULL. This fixture targets the 105 repeating-group
--   columns (`<COL>_1`, `<COL>_2`, `<COL>_3`) that are ALL currently
--   NULL: SPECIMEN/LAB/TEST, TRAVEL, EXPOSURE-LOCATION, and
--   OCCUPATION/INDUSTRY blocks.
--
-- WHY REPEATING-GROUP, AND WHY THESE WERE NULL
--   sp_covid_case_datamart_postprocessing (routine 310) builds the
--   `_1/_2/_3` columns in Steps "RPT_DATA_1/2/3". Each pivots
--   NRT_PAGE_CASE_ANSWER rows whose `answer_group_seq_nbr = 1` (resp.
--   2, 3) for questions whose NRT_ODSE_NBS_UI_METADATA row has
--   `question_group_seq_nbr IS NOT NULL` (repeating block),
--   `nbs_ui_component_uid NOT IN (1013,1025)`,
--   `data_location LIKE '%Answer_txt'`, and
--   `investigation_form_cd = 'PG_COVID-19_v1.1'`. The PHC already has
--   answers for every one of these questions in NRT, but ALL of them
--   carry `answer_group_seq_nbr = 0` (verified live 2026-06-03), so the
--   `=1/2/3` RPT pivots match nothing -> 105 NULL columns. This fixture
--   adds the missing repeating answers (groups 1, 2, 3) in ODSE.
--
--   These are DISTINCT ui_metadata rows from the discrete (group_seq
--   NULL) path, and they are NOT components 1013/1025, so adding them
--   neither double-fires the discrete pivot nor the multi-select pivot.
--   The existing answer_group_seq_nbr=0 rows are untouched and continue
--   to be ignored by every pivot (they match no path).
--
-- VALUE FIDELITY (MIXED -> COVID is clinically-meaningful -> REAL)
--   Coded questions (nbs_ui_component_uid 1007 with code_set_group_id)
--   use real codes resolved live from NRT_SRTE_CODE_VALUE_GENERAL on
--   2026-06-03 (the SP resolves answer_txt -> code_short_desc_txt via
--   NRT_SRTE_CODESET/CODE_VALUE_GENERAL, so the column lands the
--   description). Date questions (1008) carry ISO dates; free-text
--   questions (1009/1008-text) carry realistic clinical text. The three
--   answer groups model a plausible specimen/travel/occupation history.
--
-- SEED/LAB-GATED COLUMNS NOT TOUCHED (documented, not fixed)
--   The lab-sourced COVID datamarts (covid_lab_datamart,
--   covid_lab_celr_datamart) are SEED-gated on
--   nrt_srte_Loinc_condition WHERE condition_cd='11065' (0 baseline
--   rows) — bug #16, OUT OF BOUNDS. THIS fixture does NOT chase those;
--   the `_1/_2/_3` lab columns it fills here belong to COVID_CASE_
--   DATAMART and are sourced from the investigation's repeating *page
--   answers* (NRT_PAGE_CASE_ANSWER), not from lab Observations, so they
--   are NOT seed-gated.
--
-- ALSO NOT TOUCHED (NULL but not authorable as additive page answers)
--   The remaining ~69 NULL columns are PHC-core scalars sourced from
--   NRT_INVESTIGATION fields (HSPTL_*, INV_*, ILLNESS_*, IMPORT_FROM_*,
--   NOTIFICATION_*, CONFIRMATION_*, CTT_*, DETECT_METHOD_CD,
--   TRANSMISSION_MODE_CD, etc.) and patient/provider dim scalars
--   (PHYS_*, RPT_PRV_*, RPT_ORG_*, HOSPITAL_NAME, PATIENT_*). Those are
--   not page answers; filling them means re-shaping the shared
--   public_health_case / D_PATIENT / D_PROVIDER rows, which the hard
--   rules forbid (never UPDATE shared dims; additive only). Left for a
--   dedicated PHC-scalar fixture / out of scope here.
--
-- UID block: 22045000 - 22045999  (catalog/uid_ranges.md R4-F)
--   22045000..22045104  nbs_case_answer.nbs_case_answer_uid for the
--                        35 repeating questions x 3 answer groups
--                        (IDENTITY_INSERT). No new act/PHC — reuses the
--                        existing COVID PHC act_uid 22003000.
--
-- Foundation/existing dependencies (read-only):
--   act_uid / public_health_case_uid 22003000  (COVID Investigation,
--     authored by covid_investigation_full_chain.sql; has the
--     SubjOfPHC patient link + page routing already).
--   @superuser_id 10009282
-- =====================================================================

USE [NBS_ODSE];
GO

DECLARE @su   bigint = 10009282;
DECLARE @phc  bigint = 22003000;   -- existing COVID PHC act_uid
DECLARE @t    datetime = '2026-04-03T00:00:00';

-- nbs_case_answer_uid is IDENTITY; let it AUTO-assign (LESSON 10:
-- hardcoded IDENTITY_INSERT UIDs collide with the auto-IDENTITY flood and
-- the guard silently skips the whole INSERT). The pipeline keys page
-- answers on (act_uid, nbs_question_uid, seq_nbr/group), so the surrogate
-- UID is irrelevant. Guard on the natural key.
-- Columns: act_uid, add_time, add_user_id,
--   answer_txt, nbs_question_uid, nbs_question_version_ctrl_nbr,
--   last_chg_time, last_chg_user_id, record_status_cd,
--   record_status_time, seq_nbr, answer_group_seq_nbr
-- seq_nbr is set = answer_group_seq_nbr (the RPT_DATA pivots do not
--   filter on seq_nbr; this is informational and matches block layout).
IF NOT EXISTS (SELECT 1 FROM [dbo].[nbs_case_answer]
               WHERE act_uid = @phc AND nbs_question_uid = 10001370 AND answer_group_seq_nbr = 1)
BEGIN
INSERT INTO [dbo].[nbs_case_answer]
    ([act_uid], [add_time], [add_user_id],
     [answer_txt], [nbs_question_uid], [nbs_question_version_ctrl_nbr],
     [last_chg_time], [last_chg_user_id], [record_status_cd],
     [record_status_time], [seq_nbr], [answer_group_seq_nbr])
VALUES
    -- =================================================================
    -- LAB / SPECIMEN repeating block
    -- =================================================================
    -- TEST_TYPE (INV290 q=10001370, coded TEST_TYPE_COVID)
    (@phc, @t, @su, N'94309-2', 10001370, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 1, 1),
    (@phc, @t, @su, N'94307-6', 10001370, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 2, 2),
    (@phc, @t, @su, N'94308-4', 10001370, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 3, 3),
    -- TEST_RESULT (INV291 q=10001371, coded PHVS_LABTESTINTERPRETATION_VPD_COVID19)
    (@phc, @t, @su, N'10828004',  10001371, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 1, 1),
    (@phc, @t, @su, N'10828004',  10001371, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 2, 2),
    (@phc, @t, @su, N'255370002', 10001371, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 3, 3),
    -- TEST_RESULT_COMMENTS (8251_1 q=10004226, free text 1009)
    (@phc, @t, @su, N'Detected, CT 24',          10004226, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 1, 1),
    (@phc, @t, @su, N'Detected, CT 27',          10004226, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 2, 2),
    (@phc, @t, @su, N'Specimen unsatisfactory',  10004226, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 3, 3),
    -- PERFORMING_LAB_TYPE (LAB606 q=10001374, coded PHVS_PERFORMINGLABORATORYTYPE_VPD_COVID19)
    (@phc, @t, @su, N'PHC1317', 10001374, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 1, 1),
    (@phc, @t, @su, N'PHC1316', 10001374, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 2, 2),
    (@phc, @t, @su, N'OTH',     10001374, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 3, 3),
    -- SPECIMEN_SOURCE (LAB165 q=10002114, coded SPECIMEN_TYPE_COVID)
    (@phc, @t, @su, N'258500001', 10002114, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 1, 1),
    (@phc, @t, @su, N'258411007', 10002114, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 2, 2),
    (@phc, @t, @su, N'119297000', 10002114, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 3, 3),
    -- SPCMN_COLLECTION_DT (LAB163 q=10002108, date 1008)
    (@phc, @t, @su, N'2026-03-28', 10002108, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 1, 1),
    (@phc, @t, @su, N'2026-03-30', 10002108, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 2, 2),
    (@phc, @t, @su, N'2026-04-01', 10002108, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 3, 3),
    -- SPECIMEN_ID (NBS674 q=10004225, text 1008)
    (@phc, @t, @su, N'SPEC-22003000-A', 10004225, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 1, 1),
    (@phc, @t, @su, N'SPEC-22003000-B', 10004225, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 2, 2),
    (@phc, @t, @su, N'SPEC-22003000-C', 10004225, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 3, 3),
    -- ADDL_SPECIMEN_ID (NBS670 q=10004233, text 1008)
    (@phc, @t, @su, N'ADDL-A1', 10004233, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 1, 1),
    (@phc, @t, @su, N'ADDL-B1', 10004233, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 2, 2),
    (@phc, @t, @su, N'ADDL-C1', 10004233, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 3, 3),
    -- CDC_SPECIMEN_ID (INV965 q=10004232, text 1008)
    (@phc, @t, @su, N'CDC-SPEC-001', 10004232, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 1, 1),
    (@phc, @t, @su, N'CDC-SPEC-002', 10004232, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 2, 2),
    (@phc, @t, @su, N'CDC-SPEC-003', 10004232, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 3, 3),
    -- STATE_ISOLATE_ID (FDD_Q_1141 q=10004229, text 1008)
    (@phc, @t, @su, N'STATE-ISO-01', 10004229, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 1, 1),
    (@phc, @t, @su, N'STATE-ISO-02', 10004229, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 2, 2),
    (@phc, @t, @su, N'STATE-ISO-03', 10004229, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 3, 3),
    -- WGS_ID_NBR (INV949 q=10010279, text 1008)
    (@phc, @t, @su, N'WGS-EPI-ISL-1', 10010279, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 1, 1),
    (@phc, @t, @su, N'WGS-EPI-ISL-2', 10010279, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 2, 2),
    (@phc, @t, @su, N'WGS-EPI-ISL-3', 10010279, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 3, 3),
    -- ISOLTE_SENT_STATE_LAB (LAB331 q=10004227, coded YNU)
    (@phc, @t, @su, N'Y', 10004227, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 1, 1),
    (@phc, @t, @su, N'Y', 10004227, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 2, 2),
    (@phc, @t, @su, N'N', 10004227, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 3, 3),
    -- SPEC_SENT_TO_SPHL_DT (NBS564 q=10004228, date 1008)
    (@phc, @t, @su, N'2026-03-29', 10004228, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 1, 1),
    (@phc, @t, @su, N'2026-03-31', 10004228, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 2, 2),
    (@phc, @t, @su, N'2026-04-02', 10004228, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 3, 3),
    -- SPCMN_SENT_TO_CDC_IND (LAB515 q=10004230, coded YNU)
    (@phc, @t, @su, N'Y', 10004230, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 1, 1),
    (@phc, @t, @su, N'N', 10004230, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 2, 2),
    (@phc, @t, @su, N'Y', 10004230, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 3, 3),
    -- SPCMN_SENT_TO_CDC_DT (LAB516 q=10004231, date 1008)
    (@phc, @t, @su, N'2026-03-30', 10004231, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 1, 1),
    (@phc, @t, @su, N'2026-04-01', 10004231, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 2, 2),
    (@phc, @t, @su, N'2026-04-03', 10004231, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 3, 3),
    -- LAB_RESULT_NUM_UNIT (LAB115 q=10002097, coded UNIT_ISO)
    (@phc, @t, @su, N'/mL', 10002097, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 1, 1),
    (@phc, @t, @su, N'/mL', 10002097, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 2, 2),
    (@phc, @t, @su, N'%',   10002097, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 3, 3),
    -- QUANT_TEST_RESULT (LAB628 q=10002143, numeric/text 1008)
    (@phc, @t, @su, N'24.5', 10002143, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 1, 1),
    (@phc, @t, @su, N'27.1', 10002143, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 2, 2),
    (@phc, @t, @su, N'0',    10002143, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 3, 3),
    -- OTH_PATHOGEN_TST (NBS669 q=10004253, text 1008)
    (@phc, @t, @su, N'Influenza A',  10004253, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 1, 1),
    (@phc, @t, @su, N'Influenza B',  10004253, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 2, 2),
    (@phc, @t, @su, N'RSV',          10004253, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 3, 3),
    -- OTH_PATHOGEN_TST_RSLT (NBS668 q=10004254, coded TEST_RESULT_RDT_COVID)
    (@phc, @t, @su, N'260385009', 10004254, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 1, 1),
    (@phc, @t, @su, N'260385009', 10004254, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 2, 2),
    (@phc, @t, @su, N'10828004',  10004254, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 3, 3),

    -- =================================================================
    -- TRAVEL repeating block
    -- =================================================================
    -- INTL_DESTINATIONS (TRAVEL05 q=10004154, coded PSL_CNTRY)
    (@phc, @t, @su, N'124', 10004154, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 1, 1),
    (@phc, @t, @su, N'840', 10004154, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 2, 2),
    (@phc, @t, @su, N'100', 10004154, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 3, 3),
    -- TRAVEL_STATE (82754_3 q=10004152, coded STATE_CCD)
    (@phc, @t, @su, N'13', 10004152, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 1, 1),
    (@phc, @t, @su, N'06', 10004152, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 2, 2),
    (@phc, @t, @su, N'01', 10004152, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 3, 3),
    -- TRAVEL_MODE (NBS453 q=10006157, coded PHVS_TRAVELMODE_CDC_COVID19)
    (@phc, @t, @su, N'21753002', 10006157, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 1, 1),
    (@phc, @t, @su, N'22674006', 10006157, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 2, 2),
    (@phc, @t, @su, N'21753002', 10006157, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 3, 3),
    -- ARRIVAL_TRVL_DEST_DT (TRAVEL06 q=10006158, date 1008)
    (@phc, @t, @su, N'2026-03-10', 10006158, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 1, 1),
    (@phc, @t, @su, N'2026-03-15', 10006158, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 2, 2),
    (@phc, @t, @su, N'2026-03-20', 10006158, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 3, 3),
    -- DEPART_TRVL_DEST_DT (TRAVEL07 q=10006159, date 1008)
    (@phc, @t, @su, N'2026-03-12', 10006159, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 1, 1),
    (@phc, @t, @su, N'2026-03-18', 10006159, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 2, 2),
    (@phc, @t, @su, N'2026-03-22', 10006159, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 3, 3),
    -- DURATION_OUTSIDE_US (82310_4 q=10006160, numeric/text 1008)
    (@phc, @t, @su, N'2',  10006160, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 1, 1),
    (@phc, @t, @su, N'3',  10006160, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 2, 2),
    (@phc, @t, @su, N'2',  10006160, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 3, 3),
    -- TRAVEL_INFORMATION (TRAVEL23 q=10006161, free text 1009)
    (@phc, @t, @su, N'Conference travel to Toronto', 10006161, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 1, 1),
    (@phc, @t, @su, N'Domestic flight to Atlanta',   10006161, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 2, 2),
    (@phc, @t, @su, N'Family visit',                 10006161, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 3, 3),
    -- VHF_TRAVEL_REASON (TRAVEL16 q=10001082, coded PHVS_TRAVELREASON_MALARIA)
    (@phc, @t, @su, N'2',  10001082, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 1, 1),
    (@phc, @t, @su, N'3',  10001082, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 2, 2),
    (@phc, @t, @su, N'10', 10001082, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 3, 3),

    -- =================================================================
    -- EXPOSURE-LOCATION repeating block
    -- =================================================================
    -- CNTRY_OF_EXP (INV502 q=10001008, coded PSL_CNTRY)
    (@phc, @t, @su, N'840', 10001008, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 1, 1),
    (@phc, @t, @su, N'124', 10001008, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 2, 2),
    (@phc, @t, @su, N'840', 10001008, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 3, 3),
    -- ST_OR_PROV_OF_EXP (INV503 q=10001009, coded PHVS_STATEPROVINCEOFEXPOSURE_CDC)
    (@phc, @t, @su, N'13', 10001009, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 1, 1),
    (@phc, @t, @su, N'06', 10001009, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 2, 2),
    (@phc, @t, @su, N'13', 10001009, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 3, 3),
    -- CITY_OF_EXP (INV504 q=10001010, free text 1008)
    (@phc, @t, @su, N'Atlanta',   10001010, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 1, 1),
    (@phc, @t, @su, N'Toronto',   10001010, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 2, 2),
    (@phc, @t, @su, N'Savannah',  10001010, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 3, 3),
    -- CNTY_OF_EXP (INV505 q=10001011, coded COUNTY_CCD)
    (@phc, @t, @su, N'13121', 10001011, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 1, 1),
    (@phc, @t, @su, N'13089', 10001011, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 2, 2),
    (@phc, @t, @su, N'13051', 10001011, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 3, 3),

    -- =================================================================
    -- OCCUPATION / INDUSTRY repeating block
    -- =================================================================
    -- CURRENT_OCCUPATION (85659_1 q=10005132, coded PHVS_OCCUPATION_CDC_CENSUS2010)
    (@phc, @t, @su, N'3255', 10005132, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 1, 1),
    (@phc, @t, @su, N'3258', 10005132, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 2, 2),
    (@phc, @t, @su, N'9140', 10005132, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 3, 3),
    -- CUR_OCCUPATION_TXT (85658_3 q=10005133, free text 1009)
    (@phc, @t, @su, N'Registered nurse',    10005133, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 1, 1),
    (@phc, @t, @su, N'Nurse practitioner',  10005133, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 2, 2),
    (@phc, @t, @su, N'Driver',              10005133, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 3, 3),
    -- CURRENT_INDUSTRY (85657_5 q=10005134, coded PHVS_INDUSTRY_CDC_CENSUS2010)
    (@phc, @t, @su, N'8190', 10005134, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 1, 1),
    (@phc, @t, @su, N'8190', 10005134, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 2, 2),
    (@phc, @t, @su, N'0170', 10005134, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 3, 3),
    -- CURRENT_INDUSTRY_TXT (85078_4 q=10005135, free text 1009)
    (@phc, @t, @su, N'Hospital',           10005135, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 1, 1),
    (@phc, @t, @su, N'Hospital system',    10005135, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 2, 2),
    (@phc, @t, @su, N'Agriculture',        10005135, 1, CAST(GETDATE() AS DATE), @su, N'ACTIVE', @t, 3, 3);
END
GO
