-- =====================================================================
-- zz_covid_case_answer_gap.sql
-- =====================================================================
-- Round 6 tick 3 — NO-SHORTCUT, NON-OBS-HEAVY coverage fixture.
--
-- GOAL: close the remaining fully-NULL columns in
--   * RDB_MODERN.dbo.covid_case_datamart  (372/383 -> target +11)
--   * RDB_MODERN.dbo.investigation         (63/71  -> target +8)
-- by authoring a NEW dedicated COVID-19 (cd='11065') investigation in the
-- reserved UID block 22071xxx, carrying the PHC-CORE scalars / act_id /
-- NBS_Note / Confirmation_method values that feed those columns. The new
-- PHC rides the SAME real pipeline path as the existing COVID full-chain
-- (covid_case_datamart fires service-side via ProcessDatamartData, keyed
-- on cd=11065 in nrt_datamart_metadata + non-null nrt_investigation.patient_id;
-- a closing public_health_case.last_chg_time bump re-emits the PHC over CDC).
--
-- WHY A NEW PHC (not an UPDATE of 22003000 / 22063100):
--   The 19 currently-NULL target columns are NOT page-answer-driven; they
--   are PHC-core scalars / act_id root-extensions / NBS_Note / confirmation
--   that map to public_health_case + its child act_id / NBS_Note /
--   Confirmation_method rows. The two existing COVID PHCs are owned by other
--   fixtures (covid_investigation_full_chain.sql = 22003000 foundation;
--   zz_covid_contact_side.sql = 22063100) and are shared/foundation rows —
--   per the hard rules we must NOT UPDATE their core columns. Instead we add
--   an entirely NEW investigation row in OUR block and set the columns on it.
--   Coverage counts a datamart column non-NULL if ANY row carries a value, so
--   one richly-attributed COVID row fills every reachable target column.
--
-- NON-OBS-HEAVY (bug #20 obs fail-fast, bugs/20_obs_failfast_skips_on_any_throw):
--   This fixture authors ZERO observations. Only investigation-core rows:
--   act / public_health_case / act_id / NBS_Note / Confirmation_method /
--   participation (SubjOfPHC). No nbs_case_answer / observation / lab /
--   nrt_* / EXEC sp_*. Additive only, idempotent NOT EXISTS guards, closing
--   last_chg_time bump.
--
-- ---------------------------------------------------------------------
-- TARGET covid_case_datamart NULL columns (routine 310 source mapping):
--   INV_STATE_CASE_ID      <- act_id type_cd='STATE'  seq=1 (Java ProcessInvestigationDataUtil.transformActIds)
--   INV_LEGACY_CASE_ID     <- act_id type_cd='LEGACY' seq=3
--   NOTES                  <- NBS_Note (note_parent_uid=PHC) -> nrt_investigation phc_notes
--   OUTBREAK_NAME          <- public_health_case.outbreak_name (raw; needs outbreak_ind set)
--   CONFIRMATION_METHOD    <- Confirmation_method (PHC_CONF_M code -> code_short_desc_txt)
--   CONFIRMATION_DT        <- Confirmation_method.confirmation_method_time
--   NOTIFICATION_LOCAL_ID  } <- NRT_INVESTIGATION_NOTIFICATION  (notification chain;
--   NOTIFICATION_SENT_DT   }    SEE OUT-OF-REACH note below — not authored here)
--   NOTIFICATION_SUBMIT_DT }
--   PHYS_TEL_EXT_WORK      } <- D_PROVIDER (provider-entity derived;
--   RPT_PRV_TEL_EXT_WORK   }    SEE OUT-OF-REACH note below)
--
-- TARGET dbo.investigation NULL columns (routine 005 / 056 source mapping):
--   INV_STATE_CASE_ID      <- act_id STATE seq=1  (same root-extension as above)
--   LEGACY_CASE_ID         <- act_id LEGACY seq=3
--   CITY_COUNTY_CASE_NBR   <- act_id type_cd='CITY' seq=2
--   OUTBREAK_NAME_DESC     <- fn_get_value_by_cd_codeset(outbreak_name,'INV151')  (SEE note)
--   CURR_PROCESS_STATE     <- fn_get_value_by_cvg(curr_process_state_cd,'CM_PROCESS_STAGE')
--   EARLIEST_RPT_TO_PHD_DT } <- nrt_investigation.earliest_rpt_to_phd_dt  (OUT OF REACH)
--   EARLIEST_RPT_TO_CDC_DT }    no ODSE/routine/Java source feeds these nrt cols
--   IMPORT_FRM_CITY_CD       <- nrt_investigation.import_frm_city_cd       (OUT OF REACH)
--
-- OUT-OF-REACH (documented; NOT authored — would need obs / notification /
-- provider-entity / non-existent source, all banned or unfed in this seed):
--   * NOTIFICATION_LOCAL_ID / NOTIFICATION_SENT_DT / NOTIFICATION_SUBMIT_DT
--     (covid): require an NRT_INVESTIGATION_NOTIFICATION row, i.e. a real
--     notification chain (notification act + InvSubject participation + the
--     notification CDC event). Out of scope for a non-obs investigation-core
--     fixture (notification-derived, multi-entity).
--   * PHYS_TEL_EXT_WORK / RPT_PRV_TEL_EXT_WORK (covid): D_PROVIDER-derived
--     (provider phone-ext columns). Filling them additively needs dedicated
--     provider entities + PhysicianOfPHC / PerAsReporterOfPHC participations
--     carrying a work-phone extension — entity-graph work, not investigation
--     answers; deferred (the existing dedicated-entity fixtures own the
--     provider graph for 22003000).
--   * EARLIEST_RPT_TO_PHD_DT / EARLIEST_RPT_TO_CDC_DT / IMPORT_FRM_CITY_CD
--     (investigation): the nrt_investigation columns these read are NEVER
--     populated by any routine or service setter in this branch (verified:
--     no SET/INSERT source; only ever NULL). Genuinely unreachable via ODSE
--     data — a pipeline gap, not a fixture gap.
--   * OUTBREAK_NAME_DESC (investigation): derived via
--     fn_get_value_by_cd_codeset(outbreak_name,'INV151') but the baseline
--     SRTE seed ships ZERO INV151 rows (verified: 0), so the desc resolves
--     NULL regardless of the outbreak_name value. Seed-gated (fixtures-only)
--     -> the raw covid OUTBREAK_NAME still fills from outbreak_name.
--
-- EXPECTED LANDED (high confidence):
--   covid_case_datamart : INV_STATE_CASE_ID, INV_LEGACY_CASE_ID, NOTES,
--                         OUTBREAK_NAME, CONFIRMATION_METHOD, CONFIRMATION_DT (+6)
--   investigation       : INV_STATE_CASE_ID, LEGACY_CASE_ID,
--                         CITY_COUNTY_CASE_NBR, CURR_PROCESS_STATE (+4)
--
-- UIDs CONSUMED (all in reserved block 22071000-22071999):
--   22071000  act.act_uid + public_health_case.public_health_case_uid (the new COVID PHC)
--   (act_id rows keyed by (act_uid, act_id_seq) — no surrogate UID)
--   (NBS_Note via auto-IDENTITY — guarded on (note_parent_uid,type_cd))
--   (Confirmation_method keyed by public_health_case_uid — no surrogate UID)
--   (participation SubjOfPHC — auto/composite; subject_entity_uid=20000000 foundation patient)
--
-- SRTE codes verified live 2026-06-04:
--   condition_cd '11065' (COVID-19); jurisdiction '130001' (Fulton);
--   PHC_CONF_M 'CI' (Case/Outbreak Investigation) -> CONFIRMATION_METHOD;
--   CM_PROCESS_STAGE 'AI' (Awaiting Interview)     -> CURR_PROCESS_STATE.
-- =====================================================================

USE [NBS_ODSE];
GO

DECLARE @gap_phc_uid    bigint = 22071000;     -- act_uid + public_health_case_uid
DECLARE @gap_user       bigint = 10009282;      -- foundation superuser
DECLARE @gap_patient    bigint = 20000000;      -- foundation D_PATIENT (SubjOfPHC -> nrt_investigation.patient_id)

-- =====================================================================
-- (1) ODSE: act parent row
-- =====================================================================
IF NOT EXISTS (SELECT 1 FROM [dbo].[act] WHERE act_uid = @gap_phc_uid)
INSERT INTO [dbo].[act] ([act_uid], [class_cd], [mood_cd]) VALUES
    (@gap_phc_uid, N'CASE', N'EVN');
GO

-- =====================================================================
-- (2) ODSE: public_health_case row (COVID-19; cd='11065')
--     Carries the reachable PHC-core scalars that the existing full-chain
--     deliberately left NULL (NOTES/STATE/LEGACY are act_id/NBS_Note, set
--     in later steps; here we set outbreak_name + curr_process_state_cd +
--     a minimal valid COVID core so nrt_investigation/INVESTIGATION build).
--     GENERATED ALWAYS period cols omitted (none in this seed).
-- =====================================================================
DECLARE @gap_phc2 bigint = 22071000;
DECLARE @gap_user2 bigint = 10009282;
IF NOT EXISTS (SELECT 1 FROM [dbo].[public_health_case] WHERE public_health_case_uid = @gap_phc2)
INSERT INTO [dbo].[public_health_case]
    ([public_health_case_uid], [add_time], [add_user_id], [case_type_cd],
     [case_class_cd], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt],
     [investigation_status_cd], [last_chg_time], [last_chg_user_id], [local_id],
     [record_status_cd], [record_status_time], [status_cd], [status_time],
     [shared_ind], [version_ctrl_nbr], [prog_area_cd], [jurisdiction_cd],
     [program_jurisdiction_oid], [outbreak_ind], [outbreak_name],
     [curr_process_state_cd],
     [mmwr_week], [mmwr_year],
     [activity_from_time], [txt])
VALUES
    (@gap_phc2, '2026-04-10T00:00:00', @gap_user2, N'I',
     N'C', N'11065', N'2019 Novel Coronavirus', N'NND', N'NND',
     N'O', '2026-04-10T00:00:00', @gap_user2, N'CAS22071000GA01',
     N'OPEN', '2026-04-10T00:00:00', N'A', '2026-04-10T00:00:00',
     N'T', 1, N'COV', N'130001',
     @gap_phc2, N'Y', N'GA-COVID-OUTBREAK-2026-04',
     N'AI',
     N'15', N'2026',
     '2026-04-08T00:00:00', N'COVID-19 outbreak-associated confirmed case (answer-gap fixture).');
GO

-- =====================================================================
-- (3) ODSE: act_id root-extension rows
--   STATE  (seq 1) -> INV_STATE_CASE_ID    (covid + investigation)
--   CITY   (seq 2) -> CITY_COUNTY_CASE_NBR (investigation)
--   LEGACY (seq 3) -> INV_LEGACY_CASE_ID / LEGACY_CASE_ID
--   (Java ProcessInvestigationDataUtil.transformActIds keys EXACTLY on
--    type_cd + act_id_seq; PK = (act_uid, act_id_seq).)
-- =====================================================================
DECLARE @gap_phc3 bigint = 22071000;
DECLARE @gap_user3 bigint = 10009282;

IF NOT EXISTS (SELECT 1 FROM [dbo].[act_id] WHERE act_uid = @gap_phc3 AND act_id_seq = 1)
INSERT INTO [dbo].[act_id]
    ([act_uid], [act_id_seq], [add_time], [add_user_id],
     [last_chg_time], [last_chg_user_id], [record_status_cd],
     [record_status_time], [root_extension_txt], [type_cd], [status_cd], [status_time])
VALUES
    (@gap_phc3, 1, '2026-04-10T00:00:00', @gap_user3,
     '2026-04-10T00:00:00', @gap_user3, N'ACTIVE',
     '2026-04-10T00:00:00', N'GA-2026-STATE-22071000', N'STATE', N'A', '2026-04-10T00:00:00');

IF NOT EXISTS (SELECT 1 FROM [dbo].[act_id] WHERE act_uid = @gap_phc3 AND act_id_seq = 2)
INSERT INTO [dbo].[act_id]
    ([act_uid], [act_id_seq], [add_time], [add_user_id],
     [last_chg_time], [last_chg_user_id], [record_status_cd],
     [record_status_time], [root_extension_txt], [type_cd], [status_cd], [status_time])
VALUES
    (@gap_phc3, 2, '2026-04-10T00:00:00', @gap_user3,
     '2026-04-10T00:00:00', @gap_user3, N'ACTIVE',
     '2026-04-10T00:00:00', N'FULTON-2026-CITY-22071000', N'CITY', N'A', '2026-04-10T00:00:00');

IF NOT EXISTS (SELECT 1 FROM [dbo].[act_id] WHERE act_uid = @gap_phc3 AND act_id_seq = 3)
INSERT INTO [dbo].[act_id]
    ([act_uid], [act_id_seq], [add_time], [add_user_id],
     [last_chg_time], [last_chg_user_id], [record_status_cd],
     [record_status_time], [root_extension_txt], [type_cd], [status_cd], [status_time])
VALUES
    (@gap_phc3, 3, '2026-04-10T00:00:00', @gap_user3,
     '2026-04-10T00:00:00', @gap_user3, N'ACTIVE',
     '2026-04-10T00:00:00', N'LEGACY-22071000', N'LEGACY', N'A', '2026-04-10T00:00:00');
GO

-- =====================================================================
-- (4) ODSE: NBS_Note -> nrt_investigation phc_notes -> covid NOTES
--     (routine 056 ~line 938 aggregates NBS_Note by note_parent_uid=PHC).
--     nbs_note_uid is IDENTITY -> auto-assign (LESSON 10: no IDENTITY_INSERT
--     on a high-volume IDENTITY table). Guard on the natural key
--     (note_parent_uid, type_cd).
-- =====================================================================
DECLARE @gap_phc4 bigint = 22071000;
DECLARE @gap_user4 bigint = 10009282;
IF NOT EXISTS (SELECT 1 FROM [dbo].[NBS_Note]
               WHERE note_parent_uid = @gap_phc4 AND type_cd = 'COMMENT')
INSERT INTO [dbo].[NBS_Note]
    ([note_parent_uid], [record_status_cd], [record_status_time],
     [add_time], [add_user_id], [last_chg_time], [last_chg_user_id],
     [note], [private_ind_cd], [type_cd])
VALUES
    (@gap_phc4, N'ACTIVE', '2026-04-10T00:00:00',
     '2026-04-10T00:00:00', @gap_user4, '2026-04-10T00:00:00', @gap_user4,
     N'Investigation note: outbreak-associated COVID case; contacts under monitoring.',
     N'F', N'COMMENT');
GO

-- =====================================================================
-- (5) ODSE: Confirmation_method -> nrt_investigation_confirmation ->
--     covid CONFIRMATION_METHOD / CONFIRMATION_DT
--     (routine 056 emits investigation_confirmation_method JSON from this
--      ODSE table; routine 310 STRING_AGGs code_short_desc_txt via PHC_CONF_M.)
--     PK = public_health_case_uid + confirmation_method_cd.
-- =====================================================================
DECLARE @gap_phc5 bigint = 22071000;
IF NOT EXISTS (SELECT 1 FROM [dbo].[Confirmation_method]
               WHERE public_health_case_uid = @gap_phc5 AND confirmation_method_cd = 'CI')
INSERT INTO [dbo].[Confirmation_method]
    ([public_health_case_uid], [confirmation_method_cd],
     [confirmation_method_desc_txt], [confirmation_method_time])
VALUES
    (@gap_phc5, N'CI', N'Case/Outbreak Investigation', '2026-04-09T00:00:00');
GO

-- =====================================================================
-- (6) ODSE: SubjOfPHC participation -> the foundation patient 20000000.
--     Required so routine 056's person_participations JSON sets
--     nrt_investigation.patient_id (ProcessInvestigationDataUtil); without
--     it ProcessDatamartData.java:113-115 SILENTLY drops the COVID datamart.
--     subject_class_cd='PSN'; act_class_cd='CASE'; type_cd='SubjOfPHC'.
-- =====================================================================
DECLARE @gap_phc6 bigint = 22071000;
DECLARE @gap_user6 bigint = 10009282;
DECLARE @gap_pat6  bigint = 20000000;
IF NOT EXISTS (SELECT 1 FROM [dbo].[participation]
               WHERE act_uid = @gap_phc6 AND subject_entity_uid = @gap_pat6
                 AND type_cd = 'SubjOfPHC')
INSERT INTO [dbo].[participation]
    ([subject_entity_uid], [act_uid], [type_cd], [act_class_cd], [add_time], [add_user_id],
     [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time],
     [status_cd], [status_time], [subject_class_cd], [type_desc_txt])
VALUES
    (@gap_pat6, @gap_phc6, N'SubjOfPHC', N'CASE', '2026-04-10T00:00:00', @gap_user6,
     '2026-04-10T00:00:00', @gap_user6, N'ACTIVE', '2026-04-10T00:00:00',
     N'A', '2026-04-10T00:00:00', N'PSN', N'Subject of Public Health Case');
GO

-- =====================================================================
-- (7) CDC RE-TRIGGER: bump public_health_case.last_chg_time so Debezium/
--     connect re-emits PHC 22071000 -> the service re-runs
--     sp_investigation_event (rebuilds nrt_investigation w/ patient_id +
--     act_id root-extensions + phc_notes + confirmation) and, gated on
--     cd=11065 + non-null patient_id, fires sp_covid_case_datamart_post-
--     processing for this PHC. (Investigation's OWN row; no shared-dim
--     mutation; no nrt_* / EXEC sp_ here.)
-- =====================================================================
UPDATE [dbo].[public_health_case]
SET last_chg_time = '2026-06-04T00:00:02'
WHERE public_health_case_uid = 22071000;
GO

PRINT 'zz_covid_case_answer_gap.sql applied: new COVID PHC 22071000 (cd=11065) + act_id STATE/CITY/LEGACY + NBS_Note + Confirmation_method(CI) + curr_process_state(AI) + outbreak_name + SubjOfPHC(20000000). Pipeline -> nrt_investigation/INVESTIGATION/covid_case_datamart: INV_STATE_CASE_ID, INV_LEGACY_CASE_ID, NOTES, OUTBREAK_NAME, CONFIRMATION_METHOD/DT (covid +6); INV_STATE_CASE_ID, LEGACY_CASE_ID, CITY_COUNTY_CASE_NBR, CURR_PROCESS_STATE (investigation +4).';
