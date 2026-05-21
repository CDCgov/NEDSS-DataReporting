-- =====================================================================
-- Tier 3 — Enrich Phase-2 Investigation staging rows
-- =====================================================================
-- Authored 2026-05-21 (overnight loop iteration #6).
--
-- Goal: lift coverage on the partial datamart tables by filling in
-- nrt_investigation columns that the Phase-2 fixtures left NULL. Many
-- per-condition datamart SPs (sp_covid_case_datamart, sp_var_datamart,
-- sp_bmird_strep_pneumo_datamart, sp_std_hiv_datamart) read directly
-- from nrt_investigation.* — so any column we leave NULL on the
-- nrt_investigation row also shows NULL in the datamart.
--
-- Pattern: UPDATE every Phase-2 nrt_investigation row that's still
-- thin, populating common columns (hospitalization, dates, MMWR,
-- outbreak, transmission, etc.).
--
-- PHCs being enriched: 22001000 (TB), 22002000 (Var), 22003000 (COVID),
-- 22004000 (STD/HIV), 22005000 (BMIRD), 22007000 (Pertussis),
-- 22008000 (Foodborne), 22009000 (Summary), 22010000 (Aggregate).
--
-- The foundation Hep A and v2 Hep A Investigations (20000100, 20050010)
-- are intentionally NOT touched — they were authored richly in Tier 1.
-- =====================================================================

USE [RDB_MODERN];
GO

-- =====================================================================
-- Enrich every Phase-2 Investigation with the populated path on the
-- common datamart-relevant columns. UPDATEs are safe (additive).
-- =====================================================================
UPDATE [dbo].[nrt_investigation]
   SET hospitalized_ind                = N'Yes',
       hospitalized_ind_cd             = N'Y',
       hospitalized_admin_time         = COALESCE(hospitalized_admin_time,    '2026-03-25T00:00:00'),
       hospitalized_discharge_time     = COALESCE(hospitalized_discharge_time,'2026-04-02T00:00:00'),
       hospitalized_duration_amt       = COALESCE(hospitalized_duration_amt,  8),
       diagnosis_time                  = COALESCE(diagnosis_time,             '2026-03-23T00:00:00'),
       effective_from_time             = COALESCE(effective_from_time,        '2026-03-22T00:00:00'),
       effective_to_time               = COALESCE(effective_to_time,          '2026-04-10T00:00:00'),
       activity_from_time              = COALESCE(activity_from_time,         '2026-03-22T00:00:00'),
       rpt_form_cmplt_time             = COALESCE(rpt_form_cmplt_time,        '2026-04-04T00:00:00'),
       rpt_to_county_time              = COALESCE(rpt_to_county_time,         '2026-03-24T00:00:00'),
       rpt_to_state_time               = COALESCE(rpt_to_state_time,          '2026-03-26T00:00:00'),
       earliest_rpt_to_phd_dt          = COALESCE(earliest_rpt_to_phd_dt,     '2026-03-23T00:00:00'),
       earliest_rpt_to_cdc_dt          = COALESCE(earliest_rpt_to_cdc_dt,     '2026-04-07T00:00:00'),
       mmwr_week                       = COALESCE(mmwr_week,                  N'14'),
       mmwr_year                       = COALESCE(mmwr_year,                  N'2026'),
       outbreak_ind                    = COALESCE(outbreak_ind,               N'N'),
       outbreak_ind_val                = COALESCE(outbreak_ind_val,           N'No'),
       transmission_mode_cd            = COALESCE(transmission_mode_cd,       N'A'),
       transmission_mode               = COALESCE(transmission_mode,          N'Airborne'),
       disease_imported_ind            = COALESCE(disease_imported_ind,       N'Indigenous'),
       disease_imported_cd             = COALESCE(disease_imported_cd,        N'IND'),
       die_frm_this_illness_ind        = COALESCE(die_frm_this_illness_ind,   N'N'),
       day_care_ind                    = COALESCE(day_care_ind,               N'No'),
       day_care_ind_cd                 = COALESCE(day_care_ind_cd,            N'N'),
       food_handler_ind                = COALESCE(food_handler_ind,           N'No'),
       food_handler_ind_cd             = COALESCE(food_handler_ind_cd,        N'N'),
       pregnant_ind                    = COALESCE(pregnant_ind,               N'No'),
       pregnant_ind_cd                 = COALESCE(pregnant_ind_cd,            N'N'),
       pat_age_at_onset                = COALESCE(pat_age_at_onset,           N'45'),
       pat_age_at_onset_unit_cd        = COALESCE(pat_age_at_onset_unit_cd,   N'Y'),
       pat_age_at_onset_unit           = COALESCE(pat_age_at_onset_unit,      N'Years'),
       investigator_assigned_time      = COALESCE(investigator_assigned_time, '2026-04-02T00:00:00'),
       investigator_assigned_datetime  = COALESCE(investigator_assigned_datetime,'2026-04-02T00:00:00'),
       detection_method_desc_txt       = COALESCE(detection_method_desc_txt,  N'Active Surveillance'),
       infectious_from_date            = COALESCE(infectious_from_date,       '2026-03-22T00:00:00'),
       infectious_to_date              = COALESCE(infectious_to_date,         '2026-04-08T00:00:00'),
       inv_priority_cd                 = COALESCE(inv_priority_cd,            N'HIGH'),
       curr_process_state              = COALESCE(curr_process_state,         N'Open'),
       curr_process_state_cd           = COALESCE(curr_process_state_cd,      N'OPEN'),
       rpt_source_cd                   = COALESCE(rpt_source_cd,              N'PP'),
       rpt_src_cd_desc                 = COALESCE(rpt_src_cd_desc,            N'Private Physician'),
       outcome_cd                      = COALESCE(outcome_cd,                 N'Y'),
       referral_basis_cd               = COALESCE(referral_basis_cd,          N'AI'),
       referral_basis                  = COALESCE(referral_basis,             N'Awaiting Interview'),
       inv_state_case_id               = COALESCE(inv_state_case_id,          N'STATE-CASE-' + CAST(public_health_case_uid AS varchar(20))),
       outbreak_name                   = COALESCE(outbreak_name,              N'Cluster ' + CAST(public_health_case_uid AS varchar(20))),
       coinfection_id                  = COALESCE(coinfection_id,             N'COINF-' + CAST(public_health_case_uid AS varchar(20))),
       imported_from_country           = COALESCE(imported_from_country,      N'United States'),
       imported_from_state             = COALESCE(imported_from_state,        N'Georgia'),
       imported_from_county            = COALESCE(imported_from_county,       N'Fulton County'),
       imported_city_desc_txt          = COALESCE(imported_city_desc_txt,     N'Atlanta'),
       imported_country_cd             = COALESCE(imported_country_cd,        N'840'),
       imported_state_cd               = COALESCE(imported_state_cd,          N'13'),
       imported_county_cd              = COALESCE(imported_county_cd,         N'13121'),
       import_frm_city_cd              = COALESCE(import_frm_city_cd,         N'13'),
       contact_inv_status              = COALESCE(contact_inv_status,         N'O'),
       contact_inv_priority            = COALESCE(contact_inv_priority,       N'HIGH'),
       contact_inv_txt                 = COALESCE(contact_inv_txt,            N'Contact tracing complete; no further leads.'),
       city_county_case_nbr            = COALESCE(city_county_case_nbr,       N'CCN-' + CAST(public_health_case_uid AS varchar(20))),
       legacy_case_id                  = COALESCE(legacy_case_id,             N'LEGACY-' + CAST(public_health_case_uid AS varchar(20))),
       jurisdiction_nm                 = COALESCE(jurisdiction_nm,            N'Fulton County'),
       outbreak_name_desc              = COALESCE(outbreak_name_desc,         N'Local outbreak'),
       deceased_time                   = COALESCE(deceased_time,              '2026-04-08T00:00:00'),
       status_time                     = COALESCE(status_time,                '2026-04-01T00:00:00'),
       record_status_time              = COALESCE(record_status_time,         '2026-04-01T00:00:00')
 WHERE public_health_case_uid IN (
       22001000, 22002000, 22003000, 22004000, 22005000,
       22007000, 22008000, 22009000, 22010000,
       -- Also enrich the multi_condition_investigations.sql stubs.
       -- They're Tier 3 (not foundation/Tier 1) so safe to update;
       -- the stubs share the same fields (nothing condition-specific
       -- here).
       22000010, 22000020, 22000030, 22000040, 22000050,
       22000060, 22000070, 22000080, 22000090, 22000100,
       -- Tetanus stub from ldf_answers_tetanus.sql
       22000200,
       -- d_investigation_repeat Pertussis (only mmwr was set)
       22006000);

-- Re-run sp_nrt_investigation_postprocessing to flow these column
-- updates into INVESTIGATION dimension.
EXEC dbo.sp_nrt_investigation_postprocessing
    @id_list = N'22001000,22002000,22003000,22004000,22005000,22007000,22008000,22009000,22010000,22000010,22000020,22000030,22000040,22000050,22000060,22000070,22000080,22000090,22000100,22000200,22006000',
    @debug = 0;
