-- =====================================================================
-- Tier 3 — Enrich Phase-2 Investigation cores (ODSE-only conversion)
-- =====================================================================
-- ORIGINAL (pre-conversion) authored a single big UPDATE directly against
-- RDB_MODERN.dbo.nrt_investigation, setting ~60 columns (raw codes AND the
-- decoded text columns) on 21 PHCs. That is the violation: nrt_investigation
-- is the CDC mirror of NBS_ODSE.dbo.public_health_case and is rebuilt by the
-- service's sp_investigation_event (routine 056) off the ODSE rows. Fixtures
-- must author ONLY NBS_ODSE; the pipeline (CDC -> sink -> nrt_investigation ->
-- 005/056 SPs -> RDB_MODERN) derives everything else.
--
-- CONVERSION PRINCIPLE
--   * Author ONLY the raw, CDC-mirrored columns on public_health_case.
--   * Do NOT author any decoded *_desc / *_ind (text) column — 056 derives
--     them from the raw codes via SRTE codeset lookups. (Result: this file
--     is SMALLER than the original.)
--   * A closing public_health_case.last_chg_time bump re-emits each PHC over
--     CDC so the service rebuilds nrt_investigation + flows INVESTIGATION.
--
-- SCOPE NARROWED FROM 21 -> 7 PHCs (verified live 2026-06-05)
--   Only 7 of the original 21 target UIDs actually exist in
--   NBS_ODSE.dbo.public_health_case (they are real ODSE-backed full-chain
--   investigations):
--       22001000 TB (10220), 22002000 Varicella (10030),
--       22003000 COVID-19 (11065), 22004000 Syphilis (10311),
--       22005000 Strep pneumo (11717), 22006000 Pertussis-repeat (10190),
--       22007000 Pertussis (10190).
--   The other 14 original targets (22000010-22000100 multi_condition stubs,
--   22000200 tetanus, 22008000 foodborne, 22009000 summary, 22010000
--   aggregate) have NO public_health_case row and currently NO
--   nrt_investigation row either — the original UPDATE was already a no-op for
--   them. Those UIDs are owned by other fixtures (multi_condition_investigations.sql,
--   ldf_answers_tetanus.sql, summary_report_case.sql, aggregate_report.sql);
--   they cannot be enriched from THIS file without authoring ODSE entities we
--   do not own. They are intentionally dropped here. (See report.)
--
-- COLUMN GROUPS AUTHORED
--   (A) public_health_case raw scalars/codes/dates  (COALESCE-fill NULLs only)
--   (B) act_id STATE/CITY/LEGACY root-extensions  -> 056 act_ids JSON ->
--       service maps to inv_state_case_id / city_county_case_nbr /
--       legacy_case_id (proven path, see zz_covid_case_answer_gap.sql).
--   (C) InvestgrOfPHC participation (from_time) for the PHCs that lack one ->
--       056 person_participations -> investigator_id + investigator_assigned_datetime
--       (TB/COVID/STD already carry this from their *_dedicated_entities.sql).
--
-- INTENTIONALLY DECODED-BY-056 (NOT set here): hospitalized_ind,
--   transmission_mode(_desc_txt), die_frm_this_illness_ind, day_care_ind,
--   food_handler_ind, pregnant_ind, pat_age_at_onset_unit, curr_process_state,
--   rpt_src_cd_desc, referral_basis, outbreak_ind_val, outbreak_name_desc,
--   detection_method_desc_txt, disease_imported(_desc_txt), contact_inv_priority,
--   contact_inv_status (text), jurisdiction_nm, imported_from_country/state/county.
--
-- OUT OF REACH / TODO (NOT authored; see report):
--   * earliest_rpt_to_phd_dt / earliest_rpt_to_cdc_dt / import_frm_city_cd —
--     no ODSE/routine/service source feeds these nrt_investigation columns in
--     this branch (verified pipeline gap; same finding as zz_covid_case_answer_gap.sql).
--   * deceased_time — deliberately NOT filled: it would contradict outcome_cd
--     ('N' = did not die from this illness). Plausibility over coverage.
--
-- Raw codes chosen are valid SRTE codes (reused from values already present on
-- the live COVID/STD PHCs, e.g. transmission_mode_cd='OTH', curr_process_state_cd
-- ='OC' (CM_PROCESS_STAGE Open Case), rpt_source_cd='LA', detection_method_cd
-- ='PHC2112') and plausible for the (mostly respiratory) conditions; COALESCE
-- preserves any condition-specific value an upstream fixture already set.
-- =====================================================================

USE [NBS_ODSE];
GO

-- =====================================================================
-- (A) Raw public_health_case columns — COALESCE-fill NULLs only.
--     The trailing last_chg_time bump is an unconditional set so Debezium/
--     connect re-emits each PHC -> service re-runs sp_investigation_event.
-- =====================================================================
UPDATE [dbo].[public_health_case]
   SET hospitalized_ind_cd      = COALESCE(hospitalized_ind_cd,      N'Y'),
       hospitalized_admin_time  = COALESCE(hospitalized_admin_time,  '2026-03-25T00:00:00'),
       hospitalized_discharge_time = COALESCE(hospitalized_discharge_time, '2026-04-02T00:00:00'),
       hospitalized_duration_amt   = COALESCE(hospitalized_duration_amt, 8),
       diagnosis_time           = COALESCE(diagnosis_time,           '2026-03-23T00:00:00'),
       effective_from_time      = COALESCE(effective_from_time,      '2026-03-22T00:00:00'),
       effective_to_time        = COALESCE(effective_to_time,        '2026-04-10T00:00:00'),
       activity_from_time       = COALESCE(activity_from_time,       '2026-03-22T00:00:00'),
       rpt_form_cmplt_time      = COALESCE(rpt_form_cmplt_time,      '2026-04-04T00:00:00'),
       rpt_to_county_time       = COALESCE(rpt_to_county_time,       '2026-03-24T00:00:00'),
       rpt_to_state_time        = COALESCE(rpt_to_state_time,        '2026-03-26T00:00:00'),
       mmwr_week                = COALESCE(mmwr_week,                 N'14'),
       mmwr_year                = COALESCE(mmwr_year,                 N'2026'),
       outbreak_ind             = COALESCE(outbreak_ind,             N'N'),
       outbreak_name            = COALESCE(outbreak_name,            N'Cluster ' + CAST(public_health_case_uid AS varchar(20))),
       transmission_mode_cd     = COALESCE(transmission_mode_cd,     N'OTH'),
       disease_imported_cd      = COALESCE(disease_imported_cd,      N'OOS'),
       outcome_cd               = COALESCE(outcome_cd,               N'N'),
       day_care_ind_cd          = COALESCE(day_care_ind_cd,          N'N'),
       food_handler_ind_cd      = COALESCE(food_handler_ind_cd,      N'N'),
       pregnant_ind_cd          = COALESCE(pregnant_ind_cd,          N'N'),
       pat_age_at_onset         = COALESCE(pat_age_at_onset,         N'45'),
       pat_age_at_onset_unit_cd = COALESCE(pat_age_at_onset_unit_cd, N'Y'),
       investigator_assigned_time = COALESCE(investigator_assigned_time, '2026-04-02T00:00:00'),
       detection_method_cd      = COALESCE(detection_method_cd,      N'PHC2112'),
       infectious_from_date     = COALESCE(infectious_from_date,     '2026-03-22T00:00:00'),
       infectious_to_date       = COALESCE(infectious_to_date,       '2026-04-08T00:00:00'),
       inv_priority_cd          = COALESCE(inv_priority_cd,          N'HIGH'),
       curr_process_state_cd    = COALESCE(curr_process_state_cd,    N'OC'),
       rpt_source_cd            = COALESCE(rpt_source_cd,            N'LA'),
       referral_basis_cd        = COALESCE(referral_basis_cd,        N'P1'),
       coinfection_id           = COALESCE(coinfection_id,           N'COINF-' + CAST(public_health_case_uid AS varchar(20))),
       imported_country_cd      = COALESCE(imported_country_cd,      N'840'),
       imported_state_cd        = COALESCE(imported_state_cd,        N'13'),
       imported_county_cd       = COALESCE(imported_county_cd,       N'13121'),
       imported_city_desc_txt   = COALESCE(imported_city_desc_txt,   N'Atlanta'),
       contact_inv_status_cd    = COALESCE(contact_inv_status_cd,    N'O'),
       priority_cd              = COALESCE(priority_cd,              N'HIGH'),
       contact_inv_txt          = COALESCE(contact_inv_txt,          N'Contact tracing complete; no further leads.'),
       status_time              = COALESCE(status_time,              '2026-04-01T00:00:00'),
       record_status_time       = COALESCE(record_status_time,       '2026-04-01T00:00:00'),
       last_chg_time            =  CAST(GETDATE() AS DATE)
 WHERE public_health_case_uid IN (22001000, 22002000, 22003000, 22004000,
                                  22005000, 22006000, 22007000);
GO

-- =====================================================================
-- (B) act_id STATE / CITY / LEGACY root-extensions.
--   056 emits ALL act_id rows for the PHC as the act_ids JSON array
--   (056-sp_investigation_event-001.sql:410-422, keyed by act_uid); the
--   service's ProcessInvestigationDataUtil.transformActIds maps by type_cd:
--     STATE  -> inv_state_case_id
--     CITY   -> city_county_case_nbr
--     LEGACY -> legacy_case_id   (+ covid INV_LEGACY_CASE_ID)
--   (Proven path — see zz_covid_case_answer_gap.sql.)
--
--   IMPORTANT FOR LEGACY MASTERETL PARITY:
--   Some legacy flows behave positionally by act_id_seq. To keep those
--   consumers aligned with expected semantics, normalize to:
--      STATE=1, CITY=2, LEGACY=3
--   and move PHC_LOCAL_ID out of slot 1 (to seq 10) for these PHCs.
--
--   Guard on (act_uid, type_cd) so re-apply is a no-op for missing rows,
--   and normalize existing rows in-place for deterministic behavior.
-- =====================================================================
DECLARE @t datetime = '2026-04-04T00:00:00';
DECLARE @u bigint   = 10009282;

-- Normalize existing act_id seq positions for target PHCs.
-- 1) free seq 1 by moving PHC_LOCAL_ID -> 10
UPDATE a
SET a.act_id_seq = 10
FROM [dbo].[act_id] a
WHERE a.act_uid IN (22001000, 22002000, 22003000, 22004000, 22005000, 22006000, 22007000)
     AND a.type_cd = N'PHC_LOCAL_ID'
     AND a.act_id_seq <> 10;

-- 2) move STATE/CITY/LEGACY to a temporary range to avoid unique-key collisions
UPDATE a
SET a.act_id_seq = a.act_id_seq + 100
FROM [dbo].[act_id] a
WHERE a.act_uid IN (22001000, 22002000, 22003000, 22004000, 22005000, 22006000, 22007000)
     AND a.type_cd IN (N'STATE', N'CITY', N'LEGACY');

-- 3) assign canonical seq positions used by legacy positional consumers
UPDATE a
SET a.act_id_seq =
          CASE
                    WHEN a.type_cd = N'STATE' THEN 1
                    WHEN a.type_cd = N'CITY' THEN 2
                    WHEN a.type_cd = N'LEGACY' THEN 3
          END
FROM [dbo].[act_id] a
WHERE a.act_uid IN (22001000, 22002000, 22003000, 22004000, 22005000, 22006000, 22007000)
     AND a.type_cd IN (N'STATE', N'CITY', N'LEGACY');

INSERT INTO [dbo].[act_id]
    ([act_uid], [act_id_seq], [add_time], [add_user_id],
     [last_chg_time], [last_chg_user_id], [record_status_cd],
     [record_status_time], [root_extension_txt], [type_cd], [status_cd], [status_time])
SELECT s.phc, s.seq, @t, @u,  CAST(GETDATE() AS DATE), @u, N'ACTIVE', @t,
       s.prefix + CAST(s.phc AS varchar(20)), s.tcd, N'A', @t
FROM (VALUES
                    (CAST(22001000 AS bigint), 1, N'STATE',  N'GA-2026-STATE-'),
                    (22001000, 2, N'CITY',   N'FULTON-2026-CITY-'),
                    (22001000, 3, N'LEGACY', N'LEGACY-'),
                    (22002000, 1, N'STATE',  N'GA-2026-STATE-'),
                    (22002000, 2, N'CITY',   N'FULTON-2026-CITY-'),
                    (22002000, 3, N'LEGACY', N'LEGACY-'),
                    (22003000, 1, N'STATE',  N'GA-2026-STATE-'),
                    (22003000, 2, N'CITY',   N'FULTON-2026-CITY-'),
                    (22003000, 3, N'LEGACY', N'LEGACY-'),
                    (22004000, 1, N'STATE',  N'GA-2026-STATE-'),
                    (22004000, 2, N'CITY',   N'FULTON-2026-CITY-'),
                    (22004000, 3, N'LEGACY', N'LEGACY-'),
                    (22005000, 1, N'STATE',  N'GA-2026-STATE-'),
                    (22005000, 2, N'CITY',   N'FULTON-2026-CITY-'),
                    (22005000, 3, N'LEGACY', N'LEGACY-'),
                    (22006000, 1, N'STATE',  N'GA-2026-STATE-'),
                    (22006000, 2, N'CITY',   N'FULTON-2026-CITY-'),
                    (22006000, 3, N'LEGACY', N'LEGACY-'),
                    (22007000, 1, N'STATE',  N'GA-2026-STATE-'),
                    (22007000, 2, N'CITY',   N'FULTON-2026-CITY-'),
                    (22007000, 3, N'LEGACY', N'LEGACY-')
     ) AS s(phc, seq, tcd, prefix)
WHERE NOT EXISTS (SELECT 1 FROM [dbo].[act_id] a
                  WHERE a.act_uid = s.phc AND a.type_cd = s.tcd);
GO

-- =====================================================================
-- (C) InvestgrOfPHC participation -> investigator_id + investigator_assigned_datetime.
--   056 person_participations resolves the person via person_parent_uid;
--   investigator mapping requires person_cd='PRV'. Foundation Provider
--   20000010 is PSN, cd='PRV', self-parented (verified) — reused read-only.
--   TB (22001000), COVID (22003000), STD (22004000) already carry an
--   InvestgrOfPHC from their *_dedicated_entities.sql, so only the remaining
--   four get one here. Guard on (act_uid, type_cd) — idempotent.
--   from_time drives investigator_assigned_datetime.
-- =====================================================================
DECLARE @t2 datetime = '2026-04-02T00:00:00';
DECLARE @u2 bigint   = 10009282;
DECLARE @inv_prov bigint = 20000010;   -- foundation Provider (PSN/PRV)

INSERT INTO [dbo].[participation]
    ([act_uid], [subject_entity_uid], [type_cd], [act_class_cd], [subject_class_cd],
     [from_time], [add_time], [add_user_id], [last_chg_time], [last_chg_user_id],
     [record_status_cd], [record_status_time], [status_cd], [status_time], [type_desc_txt])
SELECT s.phc, @inv_prov, N'InvestgrOfPHC', N'CASE', N'PSN',
       @t2, @t2, @u2,  CAST(GETDATE() AS DATE), @u2, N'ACTIVE', @t2, N'A', @t2, N'Investigator'
FROM (VALUES
        (CAST(22002000 AS bigint)),
        (22005000),
        (22006000),
        (22007000)
     ) AS s(phc)
WHERE NOT EXISTS (SELECT 1 FROM [dbo].[participation] p
                  WHERE p.act_uid = s.phc AND p.type_cd = 'InvestgrOfPHC');
GO

PRINT 'zz_enrich_phase2_investigations.sql (ODSE-only) applied: COALESCE-filled raw public_health_case columns on 7 real ODSE PHCs (22001000/22002000/22003000/22004000/22005000/22006000/22007000) + act_id STATE/CITY/LEGACY + InvestgrOfPHC (22002000/22005000/22006000/22007000) + last_chg_time bump. nrt_investigation / INVESTIGATION / condition datamarts derive via the CDC + 056 path. TODO: earliest_rpt_to_phd/cdc_dt + import_frm_city_cd (pipeline gap); deceased_time intentionally skipped.';
GO
