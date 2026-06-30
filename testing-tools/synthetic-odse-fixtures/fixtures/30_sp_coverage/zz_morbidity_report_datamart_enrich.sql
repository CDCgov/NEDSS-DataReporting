USE [NBS_ODSE];
GO

-- =====================================================================
-- Tier 3 ENRICHMENT — MORBIDITY_REPORT_DATAMART column expansion
-- (ODSE-ONLY REWRITE)
-- =====================================================================
-- PRINCIPLE
--   This fixture authors ONLY NBS_ODSE source rows. The RTR pipeline
--   (CDC -> sink -> nrt_* -> sp_*_postprocessing -> D_*/F_*/MORBIDITY_REPORT/
--   MORBIDITY_REPORT_EVENT/LAB_TEST*/TREATMENT*/...-> MORBIDITY_REPORT_DATAMART)
--   derives every RDB_MODERN dim/fact row. The previous version of this
--   fixture wrote ~14 RDB_MODERN dim/fact tables directly (MORB_RPT_KEY
--   22015000 etc.); those direct writes are the violation and have been
--   removed entirely. Nothing in this file touches RDB_MODERN.
--
-- WHAT IT BUILDS (a third, richly-attributed morbidity-report cluster)
--   A Morb Order observation (ctrl_cd_display_form='MorbReport') with 16
--   INV/MRB followup observations + C_Order/C_Result user-comment pair, a
--   full-demographics patient, two provider entities (physician + reporter),
--   two organization entities (reporting facility + hospital), one
--   investigation (public_health_case), three embedded lab Result
--   observations, and three treatment acts. Cross-subject act_relationship
--   edges + participations wire them together so the RTR SPs derive:
--     - MORBIDITY_REPORT + MORBIDITY_REPORT_EVENT (patient/physician/reporter/
--       hospital/rep-fac/health-care/investigation/condition keys via
--       participations + the MorbReport edge)
--     - LAB_TEST / LAB_TEST_RESULT / LAB_RESULT_VAL / LAB_RESULT_COMMENT
--       (the 3 embedded labs share the SAME investigation as the morb so the
--       datamart lab-pivot columns populate; see CRITICAL note below)
--     - TREATMENT / TREATMENT_EVENT (3 treatments wired to the morb + inv)
--   and the Step-9 datamart SP folds them into MORBIDITY_REPORT_DATAMART.
--
-- CRITICAL (lab pivot population)
--   The morb postprocessing SP (016) disassociates LAB_TEST_RESULT
--   (sets MORB_RPT_KEY=1) for any morb WITHOUT an associated investigation
--   (016 lines 333-358, keyed on nrt_observation.associated_phc_uids). The
--   lab result SP (017 lines 113-134) resolves LAB_TEST_RESULT.MORB_RPT_KEY
--   by joining nrt_observation.report_observation_uid = MORBIDITY_REPORT.
--   morb_rpt_uid. So BOTH conditions must hold:
--     (a) the morb has an associated investigation (MorbReport edge), AND
--     (b) each lab's report_observation_uid points at the morb Order.
--   We satisfy (b) by authoring a COMP act_relationship from each lab
--   observation (source) to the morb Order (target, Order-domain) — the
--   reporting-pipeline-service sets report_observation_uid to the parent
--   whose obs_domain contains 'Order' (ProcessObservationDataUtil
--   transformParentObservations, line 353-355). The labs use
--   ctrl_cd_display_form='LabReportMorb' + obs_domain_cd_st_1='Order_rslt'
--   (the embedded-lab-in-morb shape the lab test SP supports at 018:219-220,
--   373, 526). We ALSO wire each lab to the SAME investigation via a
--   LabReport edge so the lab + morb agree on the investigation.
--
-- DERIVATION MAP (participation/edge -> nrt field -> dim key)
--   observation participations on the Morb Order
--   (ProcessObservationDataUtil 113-128 person / 232-245 org):
--     PATSBJ              -> patient_id          -> PATIENT_KEY
--     PhysicianOfMorb     -> morb_physician_id   -> PHYSICIAN_KEY
--     ReporterOfMorbReport(PSN) -> morb_reporter_id -> REPORTER_KEY
--     HCFAC               -> health_care_id      -> HEALTH_CARE_KEY
--     HospOfMorbObs       -> morb_hosp_id        -> HSPTL_KEY
--     ReporterOfMorbReport(ORG) -> morb_hosp_reporter_id -> MORB_RPT_SRC_ORG_KEY
--     AUT                 -> author_organization_id
--   act_relationship MorbReport (Morb Order -> PHC) -> associated_phc_uids
--                                                     -> INVESTIGATION_KEY
--   (016 lines 962-1007 key resolution; 988-1007 d_provider/d_organization/
--    investigation joins on those nrt fields.)
--
-- UID BLOCK (this fixture): 22015000-22015999 (fresh NBS_ODSE source UIDs).
--   22015010            Morb Order observation (ctrl='MorbReport')
--   22015020/22015021   C_Order / C_Result (user comment)
--   22015101-22015116   16 INV/MRB followup observations
--   22015200            public_health_case (investigation)
--   22015201            case_management (IDENTITY table)
--   22015300            patient person/entity (full demographics)
--   22015301-22015306   patient locators
--   22015400            physician provider person/entity
--   22015401-22015403   physician locators
--   22015410            reporter provider person/entity
--   22015411-22015412   reporter locators
--   22015500            reporting-facility organization
--   22015501-22015503   rep-fac locators
--   22015510            hospital organization
--   22015511-22015512   hospital locators
--   22015600-22015602   3 embedded lab Result observations
--   22015700-22015702   3 treatment acts
--
-- IDEMPOTENCY
--   Whole body guarded by IF NOT EXISTS on the Morb Order observation
--   (22015010). Re-run is a no-op. case_management is the only IDENTITY
--   table written; IDENTITY_INSERT is toggled tightly around its INSERT.
--
-- ORCHESTRATOR ADDITIONS REQUIRED (REPORT-ONLY — do NOT edit here)
--   scripts/merge_and_verify.sh readonly lists:
--     MORB_OBS_UIDS  += 22015010                 (Step-9 morb datamart @obs_uids)
--     PHC_UIDS       += 22015200                 (Step-9 @inv_uids + inv chain)
--     LAB_OBS_UIDS   += 22015600,22015601,22015602
--     PAT_UIDS       += 22015300
--     PRV_UIDS       += 22015400,22015410
--     ORG_UIDS       += 22015500,22015510
--   (Treatment is CDC-driven; treatment_uids list extension 22015700-702 is
--   optional — the morb datamart treatment pivot reads TREATMENT_EVENT by
--   MORB_RPT_KEY, populated by CDC processing of the TreatmentToMorb edge.)
--
-- COLUMN-LEVEL CAVEATS (accepted, not blockers)
--   - bug #15: MORB_REPORT_CREATED_BY / MORB_REPORT_LAST_UPDATED_BY may be
--     NULL (EVENT_METRIC user-name propagation). Not forced here.
--   - bug #04: a few D_PROVIDER columns may drop. Accepted.
--   - The embedded-lab pivot (LabReportMorb / report_observation_uid->morb)
--     is the highest-risk element; if a lab-pivot column stays NULL the rows
--     are still harmless ODSE source rows that do not corrupt the chain.
-- =====================================================================

IF NOT EXISTS (SELECT 1 FROM dbo.observation WHERE observation_uid = 22015010)
BEGIN
    DECLARE @su bigint = 10009282;                 -- conventional NBS superuser id

    -- ---------- New source UIDs ----------
    DECLARE @morb_order  bigint = 22015010;
    DECLARE @morb_corder bigint = 22015020;
    DECLARE @morb_crslt  bigint = 22015021;
    DECLARE @INV128 bigint = 22015101, @INV145 bigint = 22015102,
            @INV148 bigint = 22015103, @INV149 bigint = 22015104,
            @INV178 bigint = 22015105, @MRB100 bigint = 22015106,
            @MRB102 bigint = 22015107, @MRB122 bigint = 22015108,
            @MRB129 bigint = 22015109, @MRB130 bigint = 22015110,
            @MRB161 bigint = 22015111, @MRB165 bigint = 22015112,
            @MRB166 bigint = 22015113, @MRB167 bigint = 22015114,
            @MRB168 bigint = 22015115, @MRB169 bigint = 22015116;

    DECLARE @inv bigint = 22015200, @cm bigint = 22015201;

    DECLARE @patient bigint = 22015300;
    DECLARE @pat_home bigint = 22015301, @pat_bir bigint = 22015302,
            @pat_tphone bigint = 22015303, @pat_twork bigint = 22015304,
            @pat_tcell bigint = 22015305, @pat_temail bigint = 22015306;

    DECLARE @phys bigint = 22015400;
    DECLARE @phys_postal bigint = 22015401, @phys_tphone bigint = 22015402,
            @phys_temail bigint = 22015403;

    DECLARE @rptr bigint = 22015410;
    DECLARE @rptr_postal bigint = 22015411, @rptr_tphone bigint = 22015412;

    DECLARE @repfac bigint = 22015500;
    DECLARE @repfac_postal bigint = 22015501, @repfac_tphone bigint = 22015502,
            @repfac_tfax bigint = 22015503;

    DECLARE @hosp bigint = 22015510;
    DECLARE @hosp_postal bigint = 22015511, @hosp_tphone bigint = 22015512;

    DECLARE @lab1 bigint = 22015600, @lab2 bigint = 22015601, @lab3 bigint = 22015602;
    DECLARE @trt1 bigint = 22015700, @trt2 bigint = 22015701, @trt3 bigint = 22015702;

    -- =================================================================
    -- act parent rows for every Act-class UID.
    -- =================================================================
    INSERT INTO [dbo].[act] ([act_uid], [class_cd], [mood_cd]) VALUES
        (@morb_order, N'OBS', N'EVN'), (@morb_corder, N'OBS', N'EVN'),
        (@morb_crslt, N'OBS', N'EVN'),
        (@INV128, N'OBS', N'EVN'), (@INV145, N'OBS', N'EVN'),
        (@INV148, N'OBS', N'EVN'), (@INV149, N'OBS', N'EVN'),
        (@INV178, N'OBS', N'EVN'), (@MRB100, N'OBS', N'EVN'),
        (@MRB102, N'OBS', N'EVN'), (@MRB122, N'OBS', N'EVN'),
        (@MRB129, N'OBS', N'EVN'), (@MRB130, N'OBS', N'EVN'),
        (@MRB161, N'OBS', N'EVN'), (@MRB165, N'OBS', N'EVN'),
        (@MRB166, N'OBS', N'EVN'), (@MRB167, N'OBS', N'EVN'),
        (@MRB168, N'OBS', N'EVN'), (@MRB169, N'OBS', N'EVN'),
        (@inv, N'CASE', N'EVN'),
        (@lab1, N'OBS', N'EVN'), (@lab2, N'OBS', N'EVN'), (@lab3, N'OBS', N'EVN'),
        (@trt1, N'TRMT', N'EVN'), (@trt2, N'TRMT', N'EVN'), (@trt3, N'TRMT', N'EVN');

    -- =================================================================
    -- PATIENT — full-demographics person/entity.
    -- =================================================================
    INSERT INTO [dbo].[entity] ([entity_uid], [class_cd]) VALUES (@patient, N'PSN');

    INSERT INTO [dbo].[person]
        ([person_uid], [add_time], [add_user_id],
         [birth_gender_cd], [birth_time], [cd], [curr_sex_cd], [deceased_ind_cd],
         [deceased_time], [ethnic_group_ind], [last_chg_time], [last_chg_user_id],
         [local_id], [record_status_cd], [record_status_time], [status_cd], [status_time],
         [first_nm], [middle_nm], [last_nm], [nm_suffix], [version_ctrl_nbr],
         [as_of_date_general], [as_of_date_admin], [as_of_date_morbidity], [as_of_date_sex],
         [electronic_ind], [person_parent_uid], [edx_ind],
         [age_reported], [age_reported_unit_cd], [marital_status_cd],
         [description])
    VALUES
        (@patient, '2026-04-01T00:00:00', @su,
         N'F', '1990-06-15T00:00:00', N'PAT', N'F', N'Y',
         '2026-04-15T00:00:00', N'2186-5', '2026-04-01T00:00:00', @su,
         N'PSN22015300GA01', N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
         N'Sandra', N'Rose', N'Coleman', N'JR', 1,
         '2026-04-01T00:00:00', '2026-04-01T00:00:00', '2026-04-01T00:00:00', '2026-04-01T00:00:00',
         N'Y', @patient, N'Y',
         N'36', N'Y', N'M',
         N'Morb-datamart enrichment full-demographic patient.');

    INSERT INTO [dbo].[person_name]
        ([person_uid], [person_name_seq], [add_time], [add_user_id],
         [first_nm], [middle_nm], [last_nm], [nm_suffix], [nm_use_cd],
         [record_status_cd], [record_status_time], [status_cd], [status_time])
    VALUES
        (@patient, 1, '2026-04-01T00:00:00', @su,
         N'Sandra', N'Rose', N'Coleman', N'JR', N'L',
         N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00');

    INSERT INTO [dbo].[person_race]
        ([person_uid], [race_cd], [race_category_cd], [add_time], [add_user_id],
         [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time], [as_of_date])
    VALUES
        (@patient, N'2106-3', N'2106-3', '2026-04-01T00:00:00', @su,
         '2026-04-01T00:00:00', @su, N'ACTIVE', '2026-04-01T00:00:00', '2026-04-01T00:00:00');

    INSERT INTO [dbo].[entity_id]
        ([entity_uid], [entity_id_seq], [add_time], [add_user_id],
         [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time],
         [status_cd], [status_time], [root_extension_txt], [type_cd], [type_desc_txt], [as_of_date])
    VALUES
        (@patient, 1, '2026-04-01T00:00:00', @su,
         '2026-04-01T00:00:00', @su, N'ACTIVE', '2026-04-01T00:00:00',
         N'A', '2026-04-01T00:00:00', N'111-22-3333', N'SS', N'Social Security', '2026-04-01T00:00:00');

    INSERT INTO [dbo].[postal_locator]
        ([postal_locator_uid], [add_time], [add_user_id], [city_desc_txt],
         [cntry_cd], [cnty_cd], [last_chg_time], [last_chg_user_id],
         [record_status_cd], [record_status_time], [state_cd],
         [street_addr1], [street_addr2], [zip_cd])
    VALUES
        (@pat_home, '2026-04-01T00:00:00', @su, N'Atlanta',
         N'840', N'13121', '2026-04-01T00:00:00', @su,
         N'ACTIVE', '2026-04-01T00:00:00', N'13',
         N'500 Coverage Drive Unit A', N'Apartment B-12', N'30303');
    INSERT INTO [dbo].[postal_locator]
        ([postal_locator_uid], [add_time], [add_user_id], [city_desc_txt],
         [cntry_cd], [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time])
    VALUES
        (@pat_bir, '2026-04-01T00:00:00', @su, N'Atlanta',
         N'840', '2026-04-01T00:00:00', @su, N'ACTIVE', '2026-04-01T00:00:00');

    INSERT INTO [dbo].[tele_locator]
        ([tele_locator_uid], [add_time], [add_user_id], [cntry_cd],
         [last_chg_time], [last_chg_user_id], [phone_nbr_txt], [extension_txt],
         [record_status_cd], [record_status_time])
    VALUES
        (@pat_tphone, '2026-04-01T00:00:00', @su, N'1', '2026-04-01T00:00:00', @su, N'404-555-9000', N'7777', N'ACTIVE', '2026-04-01T00:00:00'),
        (@pat_twork,  '2026-04-01T00:00:00', @su, N'1', '2026-04-01T00:00:00', @su, N'404-555-9001', N'8888', N'ACTIVE', '2026-04-01T00:00:00'),
        (@pat_tcell,  '2026-04-01T00:00:00', @su, N'1', '2026-04-01T00:00:00', @su, N'404-555-9002', NULL,   N'ACTIVE', '2026-04-01T00:00:00');
    INSERT INTO [dbo].[tele_locator]
        ([tele_locator_uid], [add_time], [add_user_id], [cntry_cd],
         [last_chg_time], [last_chg_user_id], [email_address], [record_status_cd], [record_status_time])
    VALUES
        (@pat_temail, '2026-04-01T00:00:00', @su, N'1', '2026-04-01T00:00:00', @su, N'coverage.patient@nbs.test', N'ACTIVE', '2026-04-01T00:00:00');

    INSERT INTO [dbo].[entity_locator_participation]
        ([entity_uid], [locator_uid], [add_time], [add_user_id], [cd], [class_cd],
         [last_chg_time], [last_chg_user_id], [locator_desc_txt],
         [record_status_cd], [record_status_time], [status_cd], [status_time],
         [use_cd], [version_ctrl_nbr], [as_of_date])
    VALUES
        (@patient, @pat_home,  '2026-04-01T00:00:00', @su, N'H',   N'PST',  '2026-04-01T00:00:00', @su, N'patient home',  N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00', N'H',  1, '2026-04-01T00:00:00'),
        (@patient, @pat_bir,   '2026-04-01T00:00:00', @su, N'BIR', N'PST',  '2026-04-01T00:00:00', @su, N'patient birth', N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00', N'BIR',1, '2026-04-01T00:00:00'),
        (@patient, @pat_tphone,'2026-04-01T00:00:00', @su, N'PH',  N'TELE', '2026-04-01T00:00:00', @su, N'patient home ph', N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00', N'H',  1, '2026-04-01T00:00:00'),
        (@patient, @pat_twork, '2026-04-01T00:00:00', @su, N'PH',  N'TELE', '2026-04-01T00:00:00', @su, N'patient work ph', N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00', N'WP', 1, '2026-04-01T00:00:00'),
        (@patient, @pat_tcell, '2026-04-01T00:00:00', @su, N'CP',  N'TELE', '2026-04-01T00:00:00', @su, N'patient cell',   N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00', N'H',  1, '2026-04-01T00:00:00'),
        (@patient, @pat_temail,'2026-04-01T00:00:00', @su, N'NET', N'TELE', '2026-04-01T00:00:00', @su, N'patient email',  N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00', N'H',  1, '2026-04-01T00:00:00');

    -- =================================================================
    -- PROVIDERS — physician + reporter.
    -- =================================================================
    INSERT INTO [dbo].[entity] ([entity_uid], [class_cd]) VALUES (@phys, N'PSN'), (@rptr, N'PSN');

    INSERT INTO [dbo].[person]
        ([person_uid], [add_time], [add_user_id], [cd],
         [last_chg_time], [last_chg_user_id], [local_id],
         [record_status_cd], [record_status_time], [status_cd], [status_time],
         [first_nm], [middle_nm], [last_nm], [nm_prefix], [nm_suffix],
         [version_ctrl_nbr], [as_of_date_general], [electronic_ind], [person_parent_uid], [edx_ind])
    VALUES
        (@phys, '2026-04-01T00:00:00', @su, N'PRV',
         '2026-04-01T00:00:00', @su, N'PSN22015400GA01',
         N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
         N'Phys', N'Q', N'Coverage', N'DR', N'JR',
         1, '2026-04-01T00:00:00', N'Y', @phys, N'Y'),
        (@rptr, '2026-04-01T00:00:00', @su, N'PRV',
         '2026-04-01T00:00:00', @su, N'PSN22015410GA01',
         N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
         N'Repr', N'R', N'Coverage', N'DR', NULL,
         1, '2026-04-01T00:00:00', N'Y', @rptr, N'Y');

    INSERT INTO [dbo].[person_name]
        ([person_uid], [person_name_seq], [add_time], [add_user_id],
         [first_nm], [middle_nm], [last_nm], [nm_prefix], [nm_suffix], [nm_use_cd],
         [record_status_cd], [record_status_time], [status_cd], [status_time])
    VALUES
        (@phys, 1, '2026-04-01T00:00:00', @su, N'Phys', N'Q', N'Coverage', N'DR', N'JR', N'L', N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00'),
        (@rptr, 1, '2026-04-01T00:00:00', @su, N'Repr', N'R', N'Coverage', N'DR', NULL, N'L', N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00');

    INSERT INTO [dbo].[entity_id]
        ([entity_uid], [entity_id_seq], [add_time], [add_user_id],
         [assigning_authority_cd], [assigning_authority_desc_txt],
         [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time],
         [status_cd], [status_time], [root_extension_txt], [type_cd], [type_desc_txt], [as_of_date])
    VALUES
        (@phys, 1, '2026-04-01T00:00:00', @su, N'CMS', N'Centers for Medicare & Medicaid Services',
         '2026-04-01T00:00:00', @su, N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
         N'1114015400', N'NPI', N'National provider identifier', '2026-04-01T00:00:00'),
        (@rptr, 1, '2026-04-01T00:00:00', @su, N'CMS', N'Centers for Medicare & Medicaid Services',
         '2026-04-01T00:00:00', @su, N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
         N'1114015410', N'NPI', N'National provider identifier', '2026-04-01T00:00:00');

    INSERT INTO [dbo].[postal_locator]
        ([postal_locator_uid], [add_time], [add_user_id], [city_desc_txt],
         [cntry_cd], [cnty_cd], [last_chg_time], [last_chg_user_id],
         [record_status_cd], [record_status_time], [state_cd], [street_addr1], [street_addr2], [zip_cd])
    VALUES
        (@phys_postal, '2026-04-01T00:00:00', @su, N'Atlanta', N'840', N'13121', '2026-04-01T00:00:00', @su,
         N'ACTIVE', '2026-04-01T00:00:00', N'13', N'600 Physician Plaza Suite 3A', N'Building West Wing', N'30303'),
        (@rptr_postal, '2026-04-01T00:00:00', @su, N'Atlanta', N'840', N'13121', '2026-04-01T00:00:00', @su,
         N'ACTIVE', '2026-04-01T00:00:00', N'13', N'700 Reporter Way', N'Floor 5', N'30303');

    INSERT INTO [dbo].[tele_locator]
        ([tele_locator_uid], [add_time], [add_user_id], [cntry_cd],
         [last_chg_time], [last_chg_user_id], [phone_nbr_txt], [extension_txt],
         [record_status_cd], [record_status_time])
    VALUES
        (@phys_tphone, '2026-04-01T00:00:00', @su, N'1', '2026-04-01T00:00:00', @su, N'404-555-9110', N'1111', N'ACTIVE', '2026-04-01T00:00:00'),
        (@rptr_tphone, '2026-04-01T00:00:00', @su, N'1', '2026-04-01T00:00:00', @su, N'404-555-9111', N'2222', N'ACTIVE', '2026-04-01T00:00:00');
    INSERT INTO [dbo].[tele_locator]
        ([tele_locator_uid], [add_time], [add_user_id], [cntry_cd],
         [last_chg_time], [last_chg_user_id], [email_address], [record_status_cd], [record_status_time])
    VALUES
        (@phys_temail, '2026-04-01T00:00:00', @su, N'1', '2026-04-01T00:00:00', @su, N'phys.coverage@nbs.test', N'ACTIVE', '2026-04-01T00:00:00');

    INSERT INTO [dbo].[entity_locator_participation]
        ([entity_uid], [locator_uid], [add_time], [add_user_id], [cd], [class_cd],
         [last_chg_time], [last_chg_user_id], [locator_desc_txt],
         [record_status_cd], [record_status_time], [status_cd], [status_time],
         [use_cd], [version_ctrl_nbr], [as_of_date])
    VALUES
        (@phys, @phys_postal, '2026-04-01T00:00:00', @su, N'O',  N'PST',  '2026-04-01T00:00:00', @su, N'phys work addr',  N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00', N'WP', 1, '2026-04-01T00:00:00'),
        (@phys, @phys_tphone, '2026-04-01T00:00:00', @su, N'O',  N'TELE', '2026-04-01T00:00:00', @su, N'phys work phone', N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00', N'WP', 1, '2026-04-01T00:00:00'),
        (@phys, @phys_temail, '2026-04-01T00:00:00', @su, N'O',  N'TELE', '2026-04-01T00:00:00', @su, N'phys work email', N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00', N'WP', 1, '2026-04-01T00:00:00'),
        (@rptr, @rptr_postal, '2026-04-01T00:00:00', @su, N'O',  N'PST',  '2026-04-01T00:00:00', @su, N'rptr work addr',  N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00', N'WP', 1, '2026-04-01T00:00:00'),
        (@rptr, @rptr_tphone, '2026-04-01T00:00:00', @su, N'O',  N'TELE', '2026-04-01T00:00:00', @su, N'rptr work phone', N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00', N'WP', 1, '2026-04-01T00:00:00');

    -- =================================================================
    -- ORGANIZATIONS — reporting facility + hospital.
    -- =================================================================
    INSERT INTO [dbo].[entity] ([entity_uid], [class_cd]) VALUES (@repfac, N'ORG'), (@hosp, N'ORG');

    INSERT INTO [dbo].[organization]
        ([organization_uid], [add_time], [add_user_id], [description],
         [last_chg_time], [last_chg_user_id], [local_id],
         [record_status_cd], [record_status_time], [status_cd], [status_time],
         [display_nm], [version_ctrl_nbr], [electronic_ind],
         [standard_industry_class_cd], [standard_industry_desc_txt], [edx_ind])
    VALUES
        (@repfac, '2026-04-01T00:00:00', @su, N'Coverage reporting facility',
         '2026-04-01T00:00:00', @su, N'ORG22015500GA01',
         N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
         N'Coverage Reporting Facility', 1, N'Y',
         N'622110', N'General Medical and Surgical Hospitals', N'Y'),
        (@hosp, '2026-04-01T00:00:00', @su, N'Coverage hospital',
         '2026-04-01T00:00:00', @su, N'ORG22015510GA01',
         N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
         N'Coverage Hospital', 1, N'Y',
         N'622110', N'General Medical and Surgical Hospitals', N'Y');

    INSERT INTO [dbo].[organization_name]
        ([organization_uid], [organization_name_seq], [nm_txt], [nm_use_cd], [record_status_cd], [default_nm_ind])
    VALUES
        (@repfac, 1, N'Coverage Reporting Facility', N'L', N'ACTIVE', N'Y'),
        (@hosp,   1, N'Coverage Hospital',           N'L', N'ACTIVE', N'Y');

    INSERT INTO [dbo].[entity_id]
        ([entity_uid], [entity_id_seq], [add_time], [add_user_id],
         [assigning_authority_cd], [assigning_authority_desc_txt],
         [last_chg_time], [last_chg_user_id], [record_status_cd], [record_status_time],
         [status_cd], [status_time], [root_extension_txt], [type_cd], [type_desc_txt], [as_of_date])
    VALUES
        (@repfac, 1, '2026-04-01T00:00:00', @su, N'CLIA', N'Clinical Laboratory Improvement Amendments',
         '2026-04-01T00:00:00', @su, N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
         N'11D2015500', N'FI', N'Facility identifier', '2026-04-01T00:00:00'),
        (@hosp, 1, '2026-04-01T00:00:00', @su, N'CLIA', N'Clinical Laboratory Improvement Amendments',
         '2026-04-01T00:00:00', @su, N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
         N'11D2015510', N'FI', N'Facility identifier', '2026-04-01T00:00:00');

    INSERT INTO [dbo].[postal_locator]
        ([postal_locator_uid], [add_time], [add_user_id], [city_desc_txt],
         [cntry_cd], [cnty_cd], [last_chg_time], [last_chg_user_id],
         [record_status_cd], [record_status_time], [state_cd], [street_addr1], [street_addr2], [zip_cd])
    VALUES
        (@repfac_postal, '2026-04-01T00:00:00', @su, N'Atlanta', N'840', N'13121', '2026-04-01T00:00:00', @su,
         N'ACTIVE', '2026-04-01T00:00:00', N'13', N'800 Reporting Facility Blvd', N'Suite 200', N'30303'),
        (@hosp_postal, '2026-04-01T00:00:00', @su, N'Atlanta', N'840', N'13121', '2026-04-01T00:00:00', @su,
         N'ACTIVE', '2026-04-01T00:00:00', N'13', N'900 Hospital Drive Suite 100', N'East Tower 4F', N'30303');

    INSERT INTO [dbo].[tele_locator]
        ([tele_locator_uid], [add_time], [add_user_id], [cntry_cd],
         [last_chg_time], [last_chg_user_id], [phone_nbr_txt], [extension_txt],
         [record_status_cd], [record_status_time])
    VALUES
        (@repfac_tphone, '2026-04-01T00:00:00', @su, N'1', '2026-04-01T00:00:00', @su, N'404-555-9120', N'3333', N'ACTIVE', '2026-04-01T00:00:00'),
        (@repfac_tfax,   '2026-04-01T00:00:00', @su, N'1', '2026-04-01T00:00:00', @su, N'404-555-9129', NULL,   N'ACTIVE', '2026-04-01T00:00:00'),
        (@hosp_tphone,   '2026-04-01T00:00:00', @su, N'1', '2026-04-01T00:00:00', @su, N'404-555-9121', N'4444', N'ACTIVE', '2026-04-01T00:00:00');

    INSERT INTO [dbo].[entity_locator_participation]
        ([entity_uid], [locator_uid], [add_time], [add_user_id], [cd], [class_cd],
         [last_chg_time], [last_chg_user_id], [locator_desc_txt],
         [record_status_cd], [record_status_time], [status_cd], [status_time],
         [use_cd], [version_ctrl_nbr], [as_of_date])
    VALUES
        (@repfac, @repfac_postal, '2026-04-01T00:00:00', @su, N'O',   N'PST',  '2026-04-01T00:00:00', @su, N'rep-fac addr',  N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00', N'WP', 1, '2026-04-01T00:00:00'),
        (@repfac, @repfac_tphone, '2026-04-01T00:00:00', @su, N'PH',  N'TELE', '2026-04-01T00:00:00', @su, N'rep-fac phone', N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00', N'WP', 1, '2026-04-01T00:00:00'),
        (@repfac, @repfac_tfax,   '2026-04-01T00:00:00', @su, N'FAX', N'TELE', '2026-04-01T00:00:00', @su, N'rep-fac fax',   N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00', N'WP', 1, '2026-04-01T00:00:00'),
        (@hosp,   @hosp_postal,   '2026-04-01T00:00:00', @su, N'O',   N'PST',  '2026-04-01T00:00:00', @su, N'hospital addr', N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00', N'WP', 1, '2026-04-01T00:00:00'),
        (@hosp,   @hosp_tphone,   '2026-04-01T00:00:00', @su, N'PH',  N'TELE', '2026-04-01T00:00:00', @su, N'hospital phone',N'ACTIVE', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00', N'WP', 1, '2026-04-01T00:00:00');

    -- =================================================================
    -- INVESTIGATION — public_health_case (the shared investigation).
    -- cd '10110' (Hep A acute) matches the morb + lab condition so the
    -- datamart condition + lab pivots agree.
    -- =================================================================
    INSERT INTO [dbo].[public_health_case]
        ([public_health_case_uid], [add_time], [add_user_id], [case_type_cd],
         [case_class_cd], [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt],
         [investigation_status_cd], [last_chg_time], [last_chg_user_id], [local_id],
         [record_status_cd], [record_status_time], [status_cd], [status_time],
         [shared_ind], [version_ctrl_nbr], [prog_area_cd], [jurisdiction_cd],
         [program_jurisdiction_oid], [hospitalized_ind_cd], [outbreak_ind],
         [diagnosis_time], [hospitalized_admin_time], [hospitalized_discharge_time],
         [rpt_source_cd], [rpt_source_cd_desc_txt], [txt])
    VALUES
        (@inv, '2026-04-01T00:00:00', @su, N'I',
         N'C', N'10110', N'Hepatitis A, acute', N'NND', N'NND',
         N'O', '2026-04-01T00:00:00', @su, N'CAS22015200GA01',
         N'OPEN', '2026-04-01T00:00:00', N'A', '2026-04-01T00:00:00',
         N'T', 1, N'HEP', N'130001',
         @inv, N'Y', N'N',
         '2026-04-02T00:00:00', '2026-04-02T08:30:00', '2026-04-04T00:00:00',
         N'PP', N'Private Physician Office', N'Morb-datamart enrichment investigation.');

    INSERT INTO [dbo].[act_id]
        ([act_uid], [act_id_seq], [add_time], [add_user_id],
         [assigning_authority_cd], [assigning_authority_desc_txt],
         [last_chg_time], [last_chg_user_id], [record_status_cd],
         [record_status_time], [root_extension_txt], [type_cd],
         [type_desc_txt], [status_cd], [status_time])
    VALUES
        (@inv, 1, '2026-04-01T00:00:00', @su, N'2.16.840.1.114222.4.5.1.1', N'NEDSS_LOCAL',
         '2026-04-01T00:00:00', @su, N'ACTIVE', '2026-04-01T00:00:00',
         N'CAS22015200GA01', N'PHC_LOCAL_ID', N'Local Public Health Case Identifier', N'A', '2026-04-01T00:00:00');

    SET IDENTITY_INSERT [dbo].[case_management] ON;
    INSERT INTO [dbo].[case_management]
        ([case_management_uid], [public_health_case_uid], [status_900], [field_record_number])
    VALUES
        (@cm, @inv, N'C', N'FRN-22015200');
    SET IDENTITY_INSERT [dbo].[case_management] OFF;

    -- =================================================================
    -- MORB ORDER observation — root (ctrl_cd_display_form='MorbReport').
    -- =================================================================
    INSERT INTO [dbo].[observation]
        ([observation_uid], [add_time], [add_user_id], [cd], [cd_desc_txt],
         [cd_system_cd], [cd_system_desc_txt],
         [last_chg_time], [last_chg_user_id], [local_id],
         [obs_domain_cd_st_1], [obs_domain_cd], [ctrl_cd_display_form],
         [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_person_uid],
         [shared_ind], [version_ctrl_nbr], [prog_area_cd], [jurisdiction_cd],
         [program_jurisdiction_oid], [electronic_ind],
         [activity_to_time], [effective_from_time], [rpt_to_state_time], [activity_from_time],
         [txt], [priority_cd], [processing_decision_cd], [pregnant_ind_cd])
    VALUES
        (@morb_order, '2026-04-04T09:00:00', @su, N'10110', N'Hepatitis A, acute',
         N'2.16.840.1.114222.4.5.277', N'PHIN_CONDITION',
         '2026-04-05T10:30:00', @su, N'OBS22015010GA01',
         N'Order', N'Order', N'MorbReport',
         N'PROCESSED', '2026-04-05T10:30:00', N'A', '2026-04-05T10:30:00', @patient,
         N'T', 1, N'STD', N'130001',
         @morb_order, N'Y',
         '2026-04-04T09:00:00', '2026-04-01T00:00:00', '2026-04-04T09:00:00', '2026-04-01T00:00:00',
         N'Morb-datamart enrichment fully attributed morbidity report.',
         N'R', N'PROCESS', N'N');

    -- C_Order / C_Result (user comment) observations.
    INSERT INTO [dbo].[observation]
        ([observation_uid], [add_time], [add_user_id], [cd], [cd_desc_txt],
         [last_chg_time], [last_chg_user_id], [local_id],
         [obs_domain_cd_st_1], [obs_domain_cd],
         [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_person_uid],
         [shared_ind], [version_ctrl_nbr], [prog_area_cd], [jurisdiction_cd],
         [program_jurisdiction_oid], [electronic_ind], [activity_to_time])
    VALUES
        (@morb_corder, '2026-04-04T09:00:00', @su, N'NTE', N'Notes Comment Order',
         '2026-04-04T09:00:00', @su, N'OBS22015020GA01', N'C_Order', N'C_Order',
         N'PROCESSED', '2026-04-04T09:00:00', N'A', '2026-04-04T09:00:00', @patient,
         N'T', 1, N'STD', N'130001', @morb_order, N'Y', '2026-04-04T09:00:00'),
        (@morb_crslt, '2026-04-04T09:30:00', @su, N'NTE', N'Notes Comment Result',
         '2026-04-04T09:30:00', @su, N'OBS22015021GA01', N'C_Result', N'C_Result',
         N'PROCESSED', '2026-04-04T09:30:00', N'A', '2026-04-04T09:30:00', @patient,
         N'T', 1, N'STD', N'130001', @morb_order, N'Y', '2026-04-04T09:30:00');

    -- 16 INV/MRB followup observations (one cd each, Result-domain).
    INSERT INTO [dbo].[observation]
        ([observation_uid], [add_time], [add_user_id], [cd],
         [last_chg_time], [last_chg_user_id], [local_id],
         [obs_domain_cd_st_1], [obs_domain_cd],
         [record_status_cd], [record_status_time], [status_cd], [status_time],
         [subject_person_uid], [shared_ind], [version_ctrl_nbr])
    VALUES
        (@INV128, '2026-04-04T00:00:00', @su, N'INV128', '2026-04-04T00:00:00', @su, N'OBS22015101GA01', N'Result', N'Result', N'PROCESSED', '2026-04-04T00:00:00', N'A', '2026-04-04T00:00:00', @patient, N'T', 1),
        (@INV145, '2026-04-04T00:00:00', @su, N'INV145', '2026-04-04T00:00:00', @su, N'OBS22015102GA01', N'Result', N'Result', N'PROCESSED', '2026-04-04T00:00:00', N'A', '2026-04-04T00:00:00', @patient, N'T', 1),
        (@INV148, '2026-04-04T00:00:00', @su, N'INV148', '2026-04-04T00:00:00', @su, N'OBS22015103GA01', N'Result', N'Result', N'PROCESSED', '2026-04-04T00:00:00', N'A', '2026-04-04T00:00:00', @patient, N'T', 1),
        (@INV149, '2026-04-04T00:00:00', @su, N'INV149', '2026-04-04T00:00:00', @su, N'OBS22015104GA01', N'Result', N'Result', N'PROCESSED', '2026-04-04T00:00:00', N'A', '2026-04-04T00:00:00', @patient, N'T', 1),
        (@INV178, '2026-04-04T00:00:00', @su, N'INV178', '2026-04-04T00:00:00', @su, N'OBS22015105GA01', N'Result', N'Result', N'PROCESSED', '2026-04-04T00:00:00', N'A', '2026-04-04T00:00:00', @patient, N'T', 1),
        (@MRB100, '2026-04-04T00:00:00', @su, N'MRB100', '2026-04-04T00:00:00', @su, N'OBS22015106GA01', N'Result', N'Result', N'PROCESSED', '2026-04-04T00:00:00', N'A', '2026-04-04T00:00:00', @patient, N'T', 1),
        (@MRB102, '2026-04-04T00:00:00', @su, N'MRB102', '2026-04-04T00:00:00', @su, N'OBS22015107GA01', N'Result', N'Result', N'PROCESSED', '2026-04-04T00:00:00', N'A', '2026-04-04T00:00:00', @patient, N'T', 1),
        (@MRB122, '2026-04-04T00:00:00', @su, N'MRB122', '2026-04-04T00:00:00', @su, N'OBS22015108GA01', N'Result', N'Result', N'PROCESSED', '2026-04-04T00:00:00', N'A', '2026-04-04T00:00:00', @patient, N'T', 1),
        (@MRB129, '2026-04-04T00:00:00', @su, N'MRB129', '2026-04-04T00:00:00', @su, N'OBS22015109GA01', N'Result', N'Result', N'PROCESSED', '2026-04-04T00:00:00', N'A', '2026-04-04T00:00:00', @patient, N'T', 1),
        (@MRB130, '2026-04-04T00:00:00', @su, N'MRB130', '2026-04-04T00:00:00', @su, N'OBS22015110GA01', N'Result', N'Result', N'PROCESSED', '2026-04-04T00:00:00', N'A', '2026-04-04T00:00:00', @patient, N'T', 1),
        (@MRB161, '2026-04-04T00:00:00', @su, N'MRB161', '2026-04-04T00:00:00', @su, N'OBS22015111GA01', N'Result', N'Result', N'PROCESSED', '2026-04-04T00:00:00', N'A', '2026-04-04T00:00:00', @patient, N'T', 1),
        (@MRB165, '2026-04-04T00:00:00', @su, N'MRB165', '2026-04-04T00:00:00', @su, N'OBS22015112GA01', N'Result', N'Result', N'PROCESSED', '2026-04-04T00:00:00', N'A', '2026-04-04T00:00:00', @patient, N'T', 1),
        (@MRB166, '2026-04-04T00:00:00', @su, N'MRB166', '2026-04-04T00:00:00', @su, N'OBS22015113GA01', N'Result', N'Result', N'PROCESSED', '2026-04-04T00:00:00', N'A', '2026-04-04T00:00:00', @patient, N'T', 1),
        (@MRB167, '2026-04-04T00:00:00', @su, N'MRB167', '2026-04-04T00:00:00', @su, N'OBS22015114GA01', N'Result', N'Result', N'PROCESSED', '2026-04-04T00:00:00', N'A', '2026-04-04T00:00:00', @patient, N'T', 1),
        (@MRB168, '2026-04-04T00:00:00', @su, N'MRB168', '2026-04-04T00:00:00', @su, N'OBS22015115GA01', N'Result', N'Result', N'PROCESSED', '2026-04-04T00:00:00', N'A', '2026-04-04T00:00:00', @patient, N'T', 1),
        (@MRB169, '2026-04-04T00:00:00', @su, N'MRB169', '2026-04-04T00:00:00', @su, N'OBS22015116GA01', N'Result', N'Result', N'PROCESSED', '2026-04-04T00:00:00', N'A', '2026-04-04T00:00:00', @patient, N'T', 1);

    -- Morb act_id (local id).
    INSERT INTO [dbo].[act_id]
        ([act_uid], [act_id_seq], [add_time], [add_user_id],
         [assigning_authority_cd], [assigning_authority_desc_txt],
         [last_chg_time], [last_chg_user_id], [record_status_cd],
         [record_status_time], [root_extension_txt], [type_cd],
         [type_desc_txt], [status_cd], [status_time])
    VALUES
        (@morb_order, 1, '2026-04-04T09:00:00', @su, N'2.16.840.1.114222.4.5.1.1', N'NEDSS_LOCAL',
         '2026-04-04T09:00:00', @su, N'ACTIVE', '2026-04-04T09:00:00',
         N'OBS22015010GA01', N'OBS_LOCAL_ID', N'Local Observation Identifier', N'A', '2026-04-04T09:00:00');

    -- =================================================================
    -- obs_value_* for followups + C_Result user comment.
    -- =================================================================
    INSERT INTO [dbo].[obs_value_coded]
        ([observation_uid], [code], [code_system_cd], [code_system_desc_txt], [display_name])
    VALUES
        (@INV128, N'Y', N'2.16.840.1.114222.4.5.232', N'YNU', N'Yes'),
        (@INV145, N'N', N'2.16.840.1.114222.4.5.232', N'YNU', N'No'),
        (@INV148, N'N', N'2.16.840.1.114222.4.5.232', N'YNU', N'No'),
        (@INV149, N'N', N'2.16.840.1.114222.4.5.232', N'YNU', N'No'),
        (@INV178, N'N', N'2.16.840.1.114222.4.5.232', N'YNU', N'No'),
        (@MRB100, N'INIT', N'L', N'Local', N'Initial'),
        (@MRB129, N'N', N'2.16.840.1.114222.4.5.232', N'YNU', N'No'),
        (@MRB130, N'N', N'2.16.840.1.114222.4.5.232', N'YNU', N'No'),
        (@MRB161, N'Web', N'L', N'Local', N'Web Entry'),
        (@MRB168, N'Y', N'2.16.840.1.114222.4.5.232', N'YNU', N'Yes');

    INSERT INTO [dbo].[obs_value_date]
        ([observation_uid], [obs_value_date_seq], [from_time])
    VALUES
        (@MRB122, 1, '2026-04-01T00:00:00'),   -- illness onset
        (@MRB165, 1, '2026-04-02T00:00:00'),   -- diagnosis
        (@MRB166, 1, '2026-04-02T08:30:00'),   -- hosp admission
        (@MRB167, 1, '2026-04-04T00:00:00');   -- hosp discharge

    INSERT INTO [dbo].[obs_value_txt]
        ([observation_uid], [obs_value_txt_seq], [txt_type_cd], [value_txt])
    VALUES
        (@MRB102, 1, N'FT', N'Morb-datamart enrichment comments narrative.'),
        (@MRB169, 1, N'FT', N'Suspect foodborne; ill at restaurant.'),
        (@morb_crslt, 1, N'N', N'Clinician user comment on the morbidity report.');

    -- =================================================================
    -- Morb-internal act_relationship rows (followups + comment -> Order).
    -- =================================================================
    INSERT INTO [dbo].[act_relationship]
        ([source_act_uid], [target_act_uid], [type_cd], [add_time], [add_user_id],
         [last_chg_time], [last_chg_user_id], [record_status_cd],
         [record_status_time], [sequence_nbr], [source_class_cd],
         [target_class_cd], [status_cd], [status_time], [type_desc_txt])
    VALUES
        (@morb_corder, @morb_order, N'COMP', '2026-04-04T09:00:00', @su, '2026-04-04T09:00:00', @su, N'ACTIVE', '2026-04-04T09:00:00', 1, N'OBS', N'OBS', N'A', '2026-04-04T09:00:00', N'Component'),
        (@morb_crslt,  @morb_corder, N'COMP', '2026-04-04T09:30:00', @su, '2026-04-04T09:30:00', @su, N'ACTIVE', '2026-04-04T09:30:00', 1, N'OBS', N'OBS', N'A', '2026-04-04T09:30:00', N'Component'),
        (@INV128, @morb_order, N'COMP', '2026-04-04T00:00:00', @su, '2026-04-04T00:00:00', @su, N'ACTIVE', '2026-04-04T00:00:00', 1,  N'OBS', N'OBS', N'A', '2026-04-04T00:00:00', N'Component'),
        (@INV145, @morb_order, N'COMP', '2026-04-04T00:00:00', @su, '2026-04-04T00:00:00', @su, N'ACTIVE', '2026-04-04T00:00:00', 2,  N'OBS', N'OBS', N'A', '2026-04-04T00:00:00', N'Component'),
        (@INV148, @morb_order, N'COMP', '2026-04-04T00:00:00', @su, '2026-04-04T00:00:00', @su, N'ACTIVE', '2026-04-04T00:00:00', 3,  N'OBS', N'OBS', N'A', '2026-04-04T00:00:00', N'Component'),
        (@INV149, @morb_order, N'COMP', '2026-04-04T00:00:00', @su, '2026-04-04T00:00:00', @su, N'ACTIVE', '2026-04-04T00:00:00', 4,  N'OBS', N'OBS', N'A', '2026-04-04T00:00:00', N'Component'),
        (@INV178, @morb_order, N'COMP', '2026-04-04T00:00:00', @su, '2026-04-04T00:00:00', @su, N'ACTIVE', '2026-04-04T00:00:00', 5,  N'OBS', N'OBS', N'A', '2026-04-04T00:00:00', N'Component'),
        (@MRB100, @morb_order, N'COMP', '2026-04-04T00:00:00', @su, '2026-04-04T00:00:00', @su, N'ACTIVE', '2026-04-04T00:00:00', 6,  N'OBS', N'OBS', N'A', '2026-04-04T00:00:00', N'Component'),
        (@MRB102, @morb_order, N'COMP', '2026-04-04T00:00:00', @su, '2026-04-04T00:00:00', @su, N'ACTIVE', '2026-04-04T00:00:00', 7,  N'OBS', N'OBS', N'A', '2026-04-04T00:00:00', N'Component'),
        (@MRB122, @morb_order, N'COMP', '2026-04-04T00:00:00', @su, '2026-04-04T00:00:00', @su, N'ACTIVE', '2026-04-04T00:00:00', 8,  N'OBS', N'OBS', N'A', '2026-04-04T00:00:00', N'Component'),
        (@MRB129, @morb_order, N'COMP', '2026-04-04T00:00:00', @su, '2026-04-04T00:00:00', @su, N'ACTIVE', '2026-04-04T00:00:00', 9,  N'OBS', N'OBS', N'A', '2026-04-04T00:00:00', N'Component'),
        (@MRB130, @morb_order, N'COMP', '2026-04-04T00:00:00', @su, '2026-04-04T00:00:00', @su, N'ACTIVE', '2026-04-04T00:00:00', 10, N'OBS', N'OBS', N'A', '2026-04-04T00:00:00', N'Component'),
        (@MRB161, @morb_order, N'COMP', '2026-04-04T00:00:00', @su, '2026-04-04T00:00:00', @su, N'ACTIVE', '2026-04-04T00:00:00', 11, N'OBS', N'OBS', N'A', '2026-04-04T00:00:00', N'Component'),
        (@MRB165, @morb_order, N'COMP', '2026-04-04T00:00:00', @su, '2026-04-04T00:00:00', @su, N'ACTIVE', '2026-04-04T00:00:00', 12, N'OBS', N'OBS', N'A', '2026-04-04T00:00:00', N'Component'),
        (@MRB166, @morb_order, N'COMP', '2026-04-04T00:00:00', @su, '2026-04-04T00:00:00', @su, N'ACTIVE', '2026-04-04T00:00:00', 13, N'OBS', N'OBS', N'A', '2026-04-04T00:00:00', N'Component'),
        (@MRB167, @morb_order, N'COMP', '2026-04-04T00:00:00', @su, '2026-04-04T00:00:00', @su, N'ACTIVE', '2026-04-04T00:00:00', 14, N'OBS', N'OBS', N'A', '2026-04-04T00:00:00', N'Component'),
        (@MRB168, @morb_order, N'COMP', '2026-04-04T00:00:00', @su, '2026-04-04T00:00:00', @su, N'ACTIVE', '2026-04-04T00:00:00', 15, N'OBS', N'OBS', N'A', '2026-04-04T00:00:00', N'Component'),
        (@MRB169, @morb_order, N'COMP', '2026-04-04T00:00:00', @su, '2026-04-04T00:00:00', @su, N'ACTIVE', '2026-04-04T00:00:00', 16, N'OBS', N'OBS', N'A', '2026-04-04T00:00:00', N'Component');

    -- =================================================================
    -- Morb Order participations (drive physician/reporter/org/patient keys).
    --   subject_class_cd routes person vs org in the event SP / Java.
    -- =================================================================
    INSERT INTO [dbo].[participation]
        ([act_uid], [subject_entity_uid], [type_cd], [act_class_cd], [subject_class_cd],
         [add_time], [add_user_id], [last_chg_time], [last_chg_user_id],
         [record_status_cd], [record_status_time], [status_cd], [status_time], [type_desc_txt])
    VALUES
        (@morb_order, @patient, N'PATSBJ',              N'OBS', N'PSN', '2026-04-04T00:00:00', @su, '2026-04-04T00:00:00', @su, N'ACTIVE', '2026-04-04T00:00:00', N'A', '2026-04-04T00:00:00', N'Patient Subject'),
        (@morb_order, @phys,    N'PhysicianOfMorb',     N'OBS', N'PSN', '2026-04-04T00:00:00', @su, '2026-04-04T00:00:00', @su, N'ACTIVE', '2026-04-04T00:00:00', N'A', '2026-04-04T00:00:00', N'Physician of Morb'),
        (@morb_order, @rptr,    N'ReporterOfMorbReport',N'OBS', N'PSN', '2026-04-04T00:00:00', @su, '2026-04-04T00:00:00', @su, N'ACTIVE', '2026-04-04T00:00:00', N'A', '2026-04-04T00:00:00', N'Reporter of Morb (person)'),
        (@morb_order, @repfac,  N'HCFAC',               N'OBS', N'ORG', '2026-04-04T00:00:00', @su, '2026-04-04T00:00:00', @su, N'ACTIVE', '2026-04-04T00:00:00', N'A', '2026-04-04T00:00:00', N'Health Care Facility'),
        (@morb_order, @repfac,  N'ReporterOfMorbReport',N'OBS', N'ORG', '2026-04-04T00:00:00', @su, '2026-04-04T00:00:00', @su, N'ACTIVE', '2026-04-04T00:00:00', N'A', '2026-04-04T00:00:00', N'Reporter of Morb (org)'),
        (@morb_order, @repfac,  N'AUT',                 N'OBS', N'ORG', '2026-04-04T00:00:00', @su, '2026-04-04T00:00:00', @su, N'ACTIVE', '2026-04-04T00:00:00', N'A', '2026-04-04T00:00:00', N'Author Organization'),
        (@morb_order, @hosp,    N'HospOfMorbObs',       N'OBS', N'ORG', '2026-04-04T00:00:00', @su, '2026-04-04T00:00:00', @su, N'ACTIVE', '2026-04-04T00:00:00', N'A', '2026-04-04T00:00:00', N'Hospital of Morb');

    -- UI visibility: link the patient as SubjOfPHC of the investigation. Without
    -- this the investigation never renders under the patient in classic NBS
    -- (the morb participations above link the patient to the OBS, not the PHC).
    -- This was the lone synthetic investigation with no SubjOfPHC link.
    INSERT INTO [dbo].[participation]
        ([act_uid], [subject_entity_uid], [type_cd], [act_class_cd], [subject_class_cd],
         [add_time], [add_user_id], [last_chg_time], [last_chg_user_id],
         [record_status_cd], [record_status_time], [status_cd], [status_time], [type_desc_txt])
    VALUES
        (@inv, @patient, N'SubjOfPHC', N'CASE', N'PSN', '2026-04-04T00:00:00', @su, '2026-04-04T00:00:00', @su, N'ACTIVE', '2026-04-04T00:00:00', N'A', '2026-04-04T00:00:00', N'Subject of Public Health Case');

    -- =================================================================
    -- CROSS-SUBJECT edge: Morb Order -> Investigation (MorbReport).
    -- Drives nrt_observation.associated_phc_uids -> INVESTIGATION_KEY and
    -- keeps the labs associated to the morb (016 disassociation guard).
    -- =================================================================
    INSERT INTO [dbo].[act_relationship]
        ([target_act_uid], [source_act_uid], [type_cd], [source_class_cd], [target_class_cd],
         [add_time], [add_user_id], [from_time], [last_chg_time], [last_chg_user_id],
         [record_status_cd], [record_status_time], [sequence_nbr], [status_cd], [status_time])
    VALUES
        (@inv, @morb_order, N'MorbReport', N'OBS', N'CASE',
         '2026-04-04T00:00:00', @su, '2026-04-04T00:00:00', '2026-04-04T00:00:00', @su,
         N'ACTIVE', '2026-04-04T00:00:00', 1, N'A', '2026-04-04T00:00:00');

    -- =================================================================
    -- EMBEDDED LAB Result observations (3) — LabReportMorb / Order_rslt.
    --   COMP -> Morb Order makes report_observation_uid point at the morb
    --   (017 join no2.report_observation_uid = morb_rpt_uid -> MORB_RPT_KEY).
    --   LabReport -> Investigation makes morb + labs share the inv.
    -- =================================================================
    INSERT INTO [dbo].[observation]
        ([observation_uid], [add_time], [add_user_id], [cd], [cd_desc_txt],
         [cd_system_cd], [cd_system_desc_txt],
         [last_chg_time], [last_chg_user_id], [local_id],
         [obs_domain_cd_st_1], [obs_domain_cd], [ctrl_cd_display_form],
         [record_status_cd], [record_status_time], [status_cd], [status_time], [subject_person_uid],
         [shared_ind], [version_ctrl_nbr], [prog_area_cd], [jurisdiction_cd],
         [program_jurisdiction_oid], [electronic_ind],
         [activity_to_time], [effective_from_time], [rpt_to_state_time],
         [target_site_cd], [target_site_desc_txt])
    VALUES
        (@lab1, '2026-04-04T08:00:00', @su, N'80375-5', N'Hepatitis A virus IgM Ab',
         N'2.16.840.1.113883.6.1', N'LN',
         '2026-04-05T10:30:00', @su, N'OBS22015600GA01',
         N'Order_rslt', N'Order_rslt', N'LabReportMorb',
         N'PROCESSED', '2026-04-05T10:30:00', N'A', '2026-04-05T10:30:00', @patient,
         N'T', 1, N'STD', N'130001', @lab1, N'Y',
         '2026-04-04T08:00:00', '2026-04-03T18:00:00', '2026-04-04T09:00:00', N'SER', N'Serum'),
        (@lab2, '2026-04-05T09:00:00', @su, N'22314-9', N'Hepatitis A virus IgG Ab',
         N'2.16.840.1.113883.6.1', N'LN',
         '2026-04-05T11:30:00', @su, N'OBS22015601GA01',
         N'Order_rslt', N'Order_rslt', N'LabReportMorb',
         N'PROCESSED', '2026-04-05T11:30:00', N'A', '2026-04-05T11:30:00', @patient,
         N'T', 1, N'STD', N'130001', @lab2, N'Y',
         '2026-04-05T09:00:00', '2026-04-04T18:00:00', '2026-04-05T11:00:00', N'PLAS', N'Plasma'),
        (@lab3, '2026-04-06T09:00:00', @su, N'1742-6', N'Alanine aminotransferase (ALT)',
         N'2.16.840.1.113883.6.1', N'LN',
         '2026-04-06T11:30:00', @su, N'OBS22015602GA01',
         N'Order_rslt', N'Order_rslt', N'LabReportMorb',
         N'PROCESSED', '2026-04-06T11:30:00', N'A', '2026-04-06T11:30:00', @patient,
         N'T', 1, N'STD', N'130001', @lab3, N'Y',
         '2026-04-06T09:00:00', '2026-04-05T18:00:00', '2026-04-06T11:00:00', N'SER', N'Serum');

    INSERT INTO [dbo].[obs_value_coded]
        ([observation_uid], [code], [code_system_cd], [code_system_desc_txt], [display_name])
    VALUES
        (@lab1, N'10828004', N'2.16.840.1.113883.6.96', N'SCT', N'Positive'),
        (@lab2, N'260385009', N'2.16.840.1.113883.6.96', N'SCT', N'Negative'),
        (@lab3, N'75540009', N'2.16.840.1.113883.6.96', N'SCT', N'High');

    INSERT INTO [dbo].[obs_value_numeric]
        ([observation_uid], [obs_value_numeric_seq], [comparator_cd_1],
         [numeric_value_1], [numeric_unit_cd], [low_range], [high_range])
    VALUES
        (@lab1, 1, NULL, 1.50, N'Index', N'0.00', N'0.90'),
        (@lab2, 1, NULL, 0.80, N'Index', N'0.00', N'0.90'),
        (@lab3, 1, N'>', 215.0, N'U/L', N'0', N'40');

    INSERT INTO [dbo].[obs_value_txt]
        ([observation_uid], [obs_value_txt_seq], [txt_type_cd], [value_txt])
    VALUES
        (@lab1, 1, N'FT', N'Reactive — IgM antibody to HAV detected.'),
        (@lab2, 1, N'FT', N'Non-reactive — IgG antibody to HAV not detected.'),
        (@lab3, 1, N'FT', N'Elevated; ULN ~40 U/L.'),
        (@lab1, 2, N'N',  N'IgM positive — acute Hep A.'),
        (@lab2, 2, N'N',  N'IgG negative — no prior immunity.'),
        (@lab3, 2, N'N',  N'ALT elevated — consistent with hepatitis.');

    INSERT INTO [dbo].[obs_value_date]
        ([observation_uid], [obs_value_date_seq], [from_time])
    VALUES
        (@lab1, 1, '2026-04-04T08:00:00'),
        (@lab2, 1, '2026-04-05T09:00:00'),
        (@lab3, 1, '2026-04-06T09:00:00');

    -- Lab participations (patient subject) + edges.
    INSERT INTO [dbo].[participation]
        ([act_uid], [subject_entity_uid], [type_cd], [act_class_cd], [subject_class_cd],
         [add_time], [add_user_id], [last_chg_time], [last_chg_user_id],
         [record_status_cd], [record_status_time], [status_cd], [status_time], [type_desc_txt])
    VALUES
        (@lab1, @patient, N'PATSBJ', N'OBS', N'PSN', '2026-04-04T00:00:00', @su, '2026-04-04T00:00:00', @su, N'ACTIVE', '2026-04-04T00:00:00', N'A', '2026-04-04T00:00:00', N'Patient Subject'),
        (@lab2, @patient, N'PATSBJ', N'OBS', N'PSN', '2026-04-04T00:00:00', @su, '2026-04-04T00:00:00', @su, N'ACTIVE', '2026-04-04T00:00:00', N'A', '2026-04-04T00:00:00', N'Patient Subject'),
        (@lab3, @patient, N'PATSBJ', N'OBS', N'PSN', '2026-04-04T00:00:00', @su, '2026-04-04T00:00:00', @su, N'ACTIVE', '2026-04-04T00:00:00', N'A', '2026-04-04T00:00:00', N'Patient Subject');

    INSERT INTO [dbo].[act_relationship]
        ([source_act_uid], [target_act_uid], [type_cd], [source_class_cd], [target_class_cd],
         [add_time], [add_user_id], [from_time], [last_chg_time], [last_chg_user_id],
         [record_status_cd], [record_status_time], [sequence_nbr], [status_cd], [status_time], [type_desc_txt])
    VALUES
        -- lab -> morb Order (COMP) so report_observation_uid resolves to the morb
        (@lab1, @morb_order, N'COMP', N'OBS', N'OBS', '2026-04-04T08:00:00', @su, '2026-04-04T08:00:00', '2026-04-04T08:00:00', @su, N'ACTIVE', '2026-04-04T08:00:00', 1, N'A', '2026-04-04T08:00:00', N'Component'),
        (@lab2, @morb_order, N'COMP', N'OBS', N'OBS', '2026-04-05T09:00:00', @su, '2026-04-05T09:00:00', '2026-04-05T09:00:00', @su, N'ACTIVE', '2026-04-05T09:00:00', 2, N'A', '2026-04-05T09:00:00', N'Component'),
        (@lab3, @morb_order, N'COMP', N'OBS', N'OBS', '2026-04-06T09:00:00', @su, '2026-04-06T09:00:00', '2026-04-06T09:00:00', @su, N'ACTIVE', '2026-04-06T09:00:00', 3, N'A', '2026-04-06T09:00:00', N'Component');

    INSERT INTO [dbo].[act_relationship]
        ([target_act_uid], [source_act_uid], [type_cd], [source_class_cd], [target_class_cd],
         [add_time], [add_user_id], [from_time], [last_chg_time], [last_chg_user_id],
         [record_status_cd], [record_status_time], [sequence_nbr], [status_cd], [status_time])
    VALUES
        -- lab -> investigation (LabReport) so morb + labs share the same inv
        (@inv, @lab1, N'LabReport', N'OBS', N'CASE', '2026-04-04T08:00:00', @su, '2026-04-04T08:00:00', '2026-04-04T08:00:00', @su, N'ACTIVE', '2026-04-04T08:00:00', 1, N'A', '2026-04-04T08:00:00'),
        (@inv, @lab2, N'LabReport', N'OBS', N'CASE', '2026-04-05T09:00:00', @su, '2026-04-05T09:00:00', '2026-04-05T09:00:00', @su, N'ACTIVE', '2026-04-05T09:00:00', 1, N'A', '2026-04-05T09:00:00'),
        (@inv, @lab3, N'LabReport', N'OBS', N'CASE', '2026-04-06T09:00:00', @su, '2026-04-06T09:00:00', '2026-04-06T09:00:00', @su, N'ACTIVE', '2026-04-06T09:00:00', 1, N'A', '2026-04-06T09:00:00');

    -- =================================================================
    -- TREATMENT acts (3) — treatment + treatment_administered + act_id.
    --   TreatmentToMorb -> Morb Order  => nrt_treatment.morbidity_uid => MORB_RPT_KEY
    --   TreatmentToPHC  -> Investigation => associated_phc_uids => INVESTIGATION_KEY
    --   SubjOfTrmt/ProviderOfTrmt/ReporterOfTrmt participations => keys
    -- =================================================================
    INSERT INTO [dbo].[treatment]
        ([treatment_uid], [add_time], [add_user_id], [cd], [cd_desc_txt],
         [cd_system_cd], [cd_system_desc_txt], [class_cd],
         [last_chg_time], [last_chg_user_id], [local_id],
         [prog_area_cd], [jurisdiction_cd], [program_jurisdiction_oid],
         [record_status_cd], [record_status_time], [shared_ind], [status_cd], [status_time],
         [version_ctrl_nbr], [activity_from_time], [activity_to_time], [txt])
    VALUES
        (@trt1, '2026-04-04T00:00:00', @su, N'1', N'Hepatitis A IG, 0.1 mL/kg, IM, x 1',
         N'2.16.840.1.114222.4.5.1', N'NEDSS Base System', N'TRMT',
         '2026-04-04T00:00:00', @su, N'TRT22015700GA01', N'STD', N'130001', @trt1,
         N'ACTIVE', '2026-04-04T00:00:00', N'T', N'A', '2026-04-04T00:00:00',
         1, '2026-04-04T00:00:00', '2026-04-04T00:00:00', N'Post-exposure prophylaxis.'),
        (@trt2, '2026-04-04T00:00:00', @su, N'1', N'Acetaminophen, 500 mg, PO, q6h, x 5d',
         N'2.16.840.1.114222.4.5.1', N'NEDSS Base System', N'TRMT',
         '2026-04-04T00:00:00', @su, N'TRT22015701GA01', N'STD', N'130001', @trt2,
         N'ACTIVE', '2026-04-04T00:00:00', N'T', N'A', '2026-04-04T00:00:00',
         1, '2026-04-04T00:00:00', '2026-04-08T00:00:00', N'Antipyretic; max 3 g/day.'),
        (@trt3, '2026-04-04T00:00:00', @su, N'OTH', N'IV Fluids, normal saline, 1L, x 1',
         N'2.16.840.1.114222.4.5.1', N'NEDSS Base System', N'TRMT',
         '2026-04-04T00:00:00', @su, N'TRT22015702GA01', N'STD', N'130001', @trt3,
         N'ACTIVE', '2026-04-04T00:00:00', N'T', N'A', '2026-04-04T00:00:00',
         1, '2026-04-04T00:00:00', '2026-04-04T00:00:00', N'Supportive hydration (custom name).');

    INSERT INTO [dbo].[treatment_administered]
        ([treatment_uid], [treatment_administered_seq],
         [cd], [cd_desc_txt], [cd_system_cd], [cd_system_desc_txt],
         [dose_qty], [dose_qty_unit_cd], [effective_duration_amt], [effective_duration_unit_cd],
         [effective_from_time], [effective_to_time], [interval_cd], [interval_desc_txt],
         [route_cd], [route_desc_txt], [status_cd], [status_time])
    VALUES
        (@trt1, 1, N'500', N'HepA IG', N'TREAT_DRUG', N'NEDSS Treatment Drug',
         N'0.1', N'mL/kg', N'1', N'D', '2026-04-04T00:00:00', '2026-04-04T00:00:00',
         N'ONCE', N'Once', N'C0205531', N'IM', N'A', '2026-04-04T00:00:00'),
        (@trt2, 1, N'500', N'Acetaminophen', N'TREAT_DRUG', N'NEDSS Treatment Drug',
         N'500', N'mg', N'5', N'D', '2026-04-04T00:00:00', '2026-04-08T00:00:00',
         N'Q6H', N'Every 6 hours', N'C0205531', N'PO', N'A', '2026-04-04T00:00:00'),
        (@trt3, 1, N'500', N'Normal Saline 0.9%', N'TREAT_DRUG', N'NEDSS Treatment Drug',
         N'1000', N'mL', N'1', N'D', '2026-04-04T00:00:00', '2026-04-04T00:00:00',
         N'ONCE', N'Once', N'C0205531', N'IV', N'A', '2026-04-04T00:00:00');

    INSERT INTO [dbo].[act_id]
        ([act_uid], [act_id_seq], [add_time], [add_user_id],
         [assigning_authority_cd], [assigning_authority_desc_txt],
         [last_chg_time], [last_chg_user_id], [record_status_cd],
         [record_status_time], [root_extension_txt], [type_cd], [type_desc_txt], [status_cd], [status_time])
    VALUES
        (@trt1, 1, '2026-04-04T00:00:00', @su, N'2.16.840.1.114222.4.5.1.1', N'NEDSS_LOCAL', '2026-04-04T00:00:00', @su, N'ACTIVE', '2026-04-04T00:00:00', N'TRT22015700GA01', N'TRMT_LOCAL_ID', N'Local Treatment Identifier', N'A', '2026-04-04T00:00:00'),
        (@trt2, 1, '2026-04-04T00:00:00', @su, N'2.16.840.1.114222.4.5.1.1', N'NEDSS_LOCAL', '2026-04-04T00:00:00', @su, N'ACTIVE', '2026-04-04T00:00:00', N'TRT22015701GA01', N'TRMT_LOCAL_ID', N'Local Treatment Identifier', N'A', '2026-04-04T00:00:00'),
        (@trt3, 1, '2026-04-04T00:00:00', @su, N'2.16.840.1.114222.4.5.1.1', N'NEDSS_LOCAL', '2026-04-04T00:00:00', @su, N'ACTIVE', '2026-04-04T00:00:00', N'TRT22015702GA01', N'TRMT_LOCAL_ID', N'Local Treatment Identifier', N'A', '2026-04-04T00:00:00');

    INSERT INTO [dbo].[participation]
        ([act_uid], [subject_entity_uid], [type_cd], [act_class_cd], [subject_class_cd],
         [add_time], [add_user_id], [last_chg_time], [last_chg_user_id],
         [record_status_cd], [record_status_time], [status_cd], [status_time], [type_desc_txt])
    VALUES
        (@trt1, @patient, N'SubjOfTrmt',     N'TRMT', N'PSN', '2026-04-04T00:00:00', @su, '2026-04-04T00:00:00', @su, N'ACTIVE', '2026-04-04T00:00:00', N'A', '2026-04-04T00:00:00', N'Subject of Treatment'),
        (@trt1, @phys,    N'ProviderOfTrmt', N'TRMT', N'PSN', '2026-04-04T00:00:00', @su, '2026-04-04T00:00:00', @su, N'ACTIVE', '2026-04-04T00:00:00', N'A', '2026-04-04T00:00:00', N'Provider of Treatment'),
        (@trt1, @hosp,    N'ReporterOfTrmt', N'TRMT', N'ORG', '2026-04-04T00:00:00', @su, '2026-04-04T00:00:00', @su, N'ACTIVE', '2026-04-04T00:00:00', N'A', '2026-04-04T00:00:00', N'Reporter of Treatment'),
        (@trt2, @patient, N'SubjOfTrmt',     N'TRMT', N'PSN', '2026-04-04T00:00:00', @su, '2026-04-04T00:00:00', @su, N'ACTIVE', '2026-04-04T00:00:00', N'A', '2026-04-04T00:00:00', N'Subject of Treatment'),
        (@trt2, @phys,    N'ProviderOfTrmt', N'TRMT', N'PSN', '2026-04-04T00:00:00', @su, '2026-04-04T00:00:00', @su, N'ACTIVE', '2026-04-04T00:00:00', N'A', '2026-04-04T00:00:00', N'Provider of Treatment'),
        (@trt2, @hosp,    N'ReporterOfTrmt', N'TRMT', N'ORG', '2026-04-04T00:00:00', @su, '2026-04-04T00:00:00', @su, N'ACTIVE', '2026-04-04T00:00:00', N'A', '2026-04-04T00:00:00', N'Reporter of Treatment'),
        (@trt3, @patient, N'SubjOfTrmt',     N'TRMT', N'PSN', '2026-04-04T00:00:00', @su, '2026-04-04T00:00:00', @su, N'ACTIVE', '2026-04-04T00:00:00', N'A', '2026-04-04T00:00:00', N'Subject of Treatment'),
        (@trt3, @phys,    N'ProviderOfTrmt', N'TRMT', N'PSN', '2026-04-04T00:00:00', @su, '2026-04-04T00:00:00', @su, N'ACTIVE', '2026-04-04T00:00:00', N'A', '2026-04-04T00:00:00', N'Provider of Treatment'),
        (@trt3, @hosp,    N'ReporterOfTrmt', N'TRMT', N'ORG', '2026-04-04T00:00:00', @su, '2026-04-04T00:00:00', @su, N'ACTIVE', '2026-04-04T00:00:00', N'A', '2026-04-04T00:00:00', N'Reporter of Treatment');

    INSERT INTO [dbo].[act_relationship]
        ([target_act_uid], [source_act_uid], [type_cd], [source_class_cd], [target_class_cd],
         [add_time], [add_user_id], [from_time], [last_chg_time], [last_chg_user_id],
         [record_status_cd], [record_status_time], [sequence_nbr], [status_cd], [status_time])
    VALUES
        -- TreatmentToPHC (TRMT -> CASE)
        (@inv, @trt1, N'TreatmentToPHC', N'TRMT', N'CASE', '2026-04-04T00:00:00', @su, '2026-04-04T00:00:00', '2026-04-04T00:00:00', @su, N'ACTIVE', '2026-04-04T00:00:00', 1, N'A', '2026-04-04T00:00:00'),
        (@inv, @trt2, N'TreatmentToPHC', N'TRMT', N'CASE', '2026-04-04T00:00:00', @su, '2026-04-04T00:00:00', '2026-04-04T00:00:00', @su, N'ACTIVE', '2026-04-04T00:00:00', 1, N'A', '2026-04-04T00:00:00'),
        (@inv, @trt3, N'TreatmentToPHC', N'TRMT', N'CASE', '2026-04-04T00:00:00', @su, '2026-04-04T00:00:00', '2026-04-04T00:00:00', @su, N'ACTIVE', '2026-04-04T00:00:00', 1, N'A', '2026-04-04T00:00:00'),
        -- TreatmentToMorb (TRMT -> OBS Morb Order)
        (@morb_order, @trt1, N'TreatmentToMorb', N'TRMT', N'OBS', '2026-04-04T00:00:00', @su, '2026-04-04T00:00:00', '2026-04-04T00:00:00', @su, N'ACTIVE', '2026-04-04T00:00:00', 1, N'A', '2026-04-04T00:00:00'),
        (@morb_order, @trt2, N'TreatmentToMorb', N'TRMT', N'OBS', '2026-04-04T00:00:00', @su, '2026-04-04T00:00:00', '2026-04-04T00:00:00', @su, N'ACTIVE', '2026-04-04T00:00:00', 1, N'A', '2026-04-04T00:00:00'),
        (@morb_order, @trt3, N'TreatmentToMorb', N'TRMT', N'OBS', '2026-04-04T00:00:00', @su, '2026-04-04T00:00:00', '2026-04-04T00:00:00', @su, N'ACTIVE', '2026-04-04T00:00:00', 1, N'A', '2026-04-04T00:00:00');

END
GO

-- =====================================================================
-- No RDB_MODERN writes. nrt_* tables self-allocate via the RTR pipeline
-- (CDC -> sink -> nrt_* -> sp_*_postprocessing). The Step-9 datamart SP
-- (sp_morbidity_report_datamart_postprocessing) folds the derived
-- MORBIDITY_REPORT / MORBIDITY_REPORT_EVENT / LAB_TEST* / TREATMENT* rows
-- into MORBIDITY_REPORT_DATAMART once the orchestrator UID lists include
-- this cluster's UIDs (see ORCHESTRATOR ADDITIONS REQUIRED in the header).
-- =====================================================================
GO
