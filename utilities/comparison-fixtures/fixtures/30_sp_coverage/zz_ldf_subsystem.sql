USE [NBS_ODSE];
GO

-- =====================================================================
-- Tier 3 — LDF (Local Data Field) subsystem, no-shortcut / ODSE-only
-- =====================================================================
-- Agent R6t3.  UID block 22069000-22069999.
--
-- GOAL
--   Populate the empty / partial LDF RDB_MODERN tables (ldf_data,
--   ldf_group, ldf_dimensional_data, d_ldf_meta_data, ldf_datamart_column_ref,
--   patient_ldf_group, organization_ldf_group, and the per-condition
--   ldf datamarts) using ONLY faithful ODSE source rows, with NO
--   nrt_* INSERTs and NO `EXEC sp_*` (branch aw/remove-nrt-shortcut rules).
--
-- HOW THE LDF PIPELINE WORKS (verified against routines + service)
--   The LDF subsystem is fed entirely from ODSE
--   `dbo.State_Defined_Field_Data` (the per-entity LDF *answer*) joined to
--   `dbo.State_Defined_Field_MetaData` (the LDF *field definition*) and the
--   SRTE `code_value_general` LDF_DATA_TYPE reference.
--     1. CDC on dbo.state_defined_field_data (odse_main_connector
--        table.include.list) emits a change event on topic
--        nbs.state-defined-field-data.
--     2. LdfDataService.processLdfData calls sp_ldf_data_event, which
--        dispatches by State_Defined_Field_Data.business_object_nm:
--          PAT->sp_ldf_patient_event, PRV->sp_ldf_provider_event,
--          ORG->sp_ldf_organization_event, PHC/BMD/HEP/NIP->sp_ldf_phc_event.
--        Each event proc SELECTs from
--          State_Defined_Field_MetaData m
--            JOIN State_Defined_Field_Data d ON m.ldf_uid=d.ldf_uid
--                                            AND d.business_object_nm=<type>
--            JOIN nbs_srte.code_value_general (code_set_nm='LDF_DATA_TYPE')
--            JOIN Person/Organization (by business_object_uid)
--        and the row is sunk to nrt_ldf_data.
--     3. PostProcessingService (LDF_DATA topic) runs, with no manual EXEC:
--          sp_nrt_ldf_postprocessing            -> ldf_data, ldf_group,
--                                                  PATIENT/ORG/PROVIDER_LDF_GROUP
--          sp_nrt_ldf_dimensional_data_postproc -> d_ldf_meta_data,
--                                                  ldf_datamart_column_ref,
--                                                  ldf_dimensional_data
--        and the per-condition LDF datamart SPs keyed on the PHC uid.
--
--   So a single ODSE State_Defined_Field_Data row, applied in Tier 3 and
--   drained in Step 9, lands the whole downstream chain faithfully —
--   exactly the path the (now gutted) hand-authored nrt_ldf_data fixtures
--   used to short-circuit.
--
-- WHAT THIS FIXTURE POPULATES (reachable ODSE-only)
--   * PATIENT_LDF_GROUP      — PAT answer on Person 10000008 (cd='PAT',
--                              person_uid<>person_parent_uid; d_patient key 2).
--   * ORGANIZATION_LDF_GROUP — ORG answer on Organization 10003001
--                              (d_organization key 2).
--   * LDF_DIMENSIONAL_DATA / D_LDF_META_DATA / LDF_DATAMART_COLUMN_REF /
--     LDF_DATA / LDF_GROUP   — PHC answers on the existing Trichinellosis
--                              investigation 22047500 (cd=10270, which is in
--                              LDF_DATAMART_TABLE_REF -> LDF_FOODBORNE). The
--                              dimensional SP's hard gate is
--                                nrt_ldf_data.business_object_uid = inv.PHC_uid
--                                AND inv.cd IN LDF_DATAMART_TABLE_REF
--                              (routine 265 lines 654-657); 10270 satisfies it
--                              and has 43 ST + 34 CV seeded PHC metadata rows.
--
--   The chosen ldf_uids (10002099/10002100/10002105) are baseline PHC, ST,
--   class_cd=CDC, free-text (no code translation) metadata rows that are
--   active_ind='Y'. Reused across PAT/ORG/PHC answers — the event procs key
--   metadata by ldf_uid only (no business_object_nm filter on the metadata
--   side), so PHC-defined fields attach cleanly to PAT/ORG answers; ldf_value
--   passes through as COL1.
--
-- ---------------------------------------------------------------------
-- SEED / DATA-SHAPE GATED (OUT OF BOUNDS for ODSE-only fixtures) — evidence
-- ---------------------------------------------------------------------
-- The remaining empty LDF tables are NOT authorable without editing seed /
-- SRTE reference data or building heavy new investigation chains:
--
--   * LDF_BMIRD (0/7), LDF_HEPATITIS (0/7) — SEED-GATED.
--       Both datamart SPs admit a dimensional row only when its
--       LDF_DATAMART_COLUMN_REF.CONDITION_CD is one of the datamart's mapped
--       conditions, OR LDF_PAGE_SET resolves to 'BMIRD'/'HEP' (which requires
--       business_object_nm 'BMD'/'HEP' metadata; routine 265 lines 100-103).
--       Baseline NBS_ODSE.State_Defined_Field_MetaData ships ZERO rows for any
--       BMIRD condition (10650,11710,11715,10590,10150,11700,11716,11717,11720)
--       and ZERO for any HEP condition (10110,10100,10104,10105,10101,10106,
--       10102,10103,10481), and ZERO with business_object_nm IN ('BMD','HEP').
--       Verified live: for LDF_BMIRD and LDF_HEPATITIS the count of seeded
--       metadata conditions intersecting the datamart's ref set = 0.
--       Populating them requires adding LDF field-definition rows to the
--       seeded metadata table — out of bounds (same class of seed gap as
--       bugs/16_covid_lab_loinc_condition_seed_gap).
--
--   * LDF_FOODBORNE (0/7), LDF_MUMPS (0/7), LDF_TETANUS (0/7) — CHAIN-GATED.
--       These three datamart SPs inner-join GENERIC_CASE (routine 290 lines
--       216-223; mumps/tetanus identical). GENERIC_CASE is empty (0 rows) and
--       is populated only by sp_generic_case_datamart_postprocessing, which
--       filters investigation_form_cd LIKE 'INV_FORM_GEN%'. No existing
--       investigation uses that form, and conditions 10180 (Mumps) and 10210
--       (Tetanus) do not route to Generic_Case in nrt_datamart_metadata at all.
--       Reaching them needs a full new INV_FORM_GEN investigation chain
--       (Public_health_case + patient subject link + datamart-column page
--       answers) so GENERIC_CASE fires first — that is investigation-fixture /
--       page-answer territory owned elsewhere, not an LDF-answer fixture, and
--       is the large "real ODSE chains" effort flagged in NO_SHORTCUT_FINDINGS.
--       (The PHC answers this fixture adds on 22047500 DO populate
--       LDF_DIMENSIONAL_DATA for cd=10270; only the LDF_FOODBORNE datamart
--       projection is blocked, pending GENERIC_CASE.)
--
--   * TB_PAM_LDF (0/3), VAR_PAM_LDF (0/3) — SEED-GATED (different path).
--       These do NOT use State_Defined_Field_Data. sp_nrt_tb_pam_ldf_/
--       sp_nrt_var_pam_ldf_postprocessing read nrt_page_case_answer filtered
--       LDF_STATUS_CD IN ('LDF_UPDATE','LDF_CREATE','LDF_PROCESSED') for
--       INV_FORM_RVCT / INV_FORM_VAR (routine 220 lines 60-85). Those columns
--       are sourced by sp_investigation_event from ODSE nbs_ui_metadata.
--       ldf_status_cd + nbs_question.datamart_column_nm (routine 056 lines
--       550-567). Verified live: ldf_status_cd is NULL for ALL 12531
--       nbs_ui_metadata rows, and zero RVCT/VAR questions carry both an
--       ldf_status_cd flag and a datamart_column_nm. Flagging them requires
--       editing the seeded ODSE/SRTE page metadata — out of bounds. (Also,
--       the page-answer fixtures are owned by zz_page_answers*.sql.)
--
--   * PROVIDER_LDF_GROUP (0/3) — DATA-SHAPE GATED.
--       sp_ldf_provider_event joins Person p ON d.business_object_uid=
--       p.person_uid AND p.cd='PRV' AND p.person_uid<>p.person_parent_uid
--       (routine 057 lines 84-85). Verified live: all 21 seeded PRV persons
--       have person_uid = person_parent_uid (parent=self), so the event proc
--       filters every one out — there is no provider answer to author against.
--       A new Person(cd='PRV', parent<>self) plus a matching d_provider
--       dimension row would be required; d_provider is a foundation dimension
--       produced by the provider pipeline, so this is a foundation-fixture
--       concern, not an LDF-answer fixture. Left as a documented gap.
--
-- ---------------------------------------------------------------------
-- UIDs consumed: NONE from 22069000-22069999.
--   State_Defined_Field_Data's PK is (ldf_uid, business_object_uid); both
--   are existing baseline UIDs (ldf_uid = seeded metadata; business_object_uid
--   = existing PHC/patient/org). This fixture allocates no new surrogate UIDs.
--   GENERATED columns: none (State_Defined_Field_Data has no identity/computed
--   columns — 7 plain columns).
-- =====================================================================

PRINT '[zz_ldf_subsystem] start';

-- ---------------------------------------------------------------------
-- 1. PHC LDF answers on the Trichinellosis investigation 22047500
--    (cd=10270 -> LDF_DATAMART_TABLE_REF -> LDF_FOODBORNE).
--    Drives D_LDF_META_DATA / LDF_DATAMART_COLUMN_REF / LDF_DIMENSIONAL_DATA
--    / LDF_DATA / LDF_GROUP. business_object_nm='PHC' -> sp_ldf_phc_event.
-- ---------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM dbo.State_Defined_Field_Data
               WHERE ldf_uid = 10002099 AND business_object_uid = 22047500)
BEGIN
    INSERT INTO dbo.State_Defined_Field_Data
        (ldf_uid, business_object_uid, add_time, business_object_nm,
         last_chg_time, ldf_value, version_ctrl_nbr)
    VALUES
        (10002099, 22047500, '2026-06-04T00:00:00', 'PHC',
         '2026-06-04T00:00:00', 'RTR LDF foodborne answer A', 1),
        (10002100, 22047500, '2026-06-04T00:00:00', 'PHC',
         '2026-06-04T00:00:00', 'RTR LDF foodborne answer B', 1);
    PRINT '[zz_ldf_subsystem] inserted 2 PHC LDF answers on 22047500 (cd 10270)';
END
GO

-- ---------------------------------------------------------------------
-- 2. PAT LDF answer on Person 10000008 (cd='PAT', uid<>parent;
--    d_patient key 2) -> sp_ldf_patient_event -> PATIENT_LDF_GROUP.
-- ---------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM dbo.State_Defined_Field_Data
               WHERE ldf_uid = 10002100 AND business_object_uid = 10000008)
BEGIN
    INSERT INTO dbo.State_Defined_Field_Data
        (ldf_uid, business_object_uid, add_time, business_object_nm,
         last_chg_time, ldf_value, version_ctrl_nbr)
    VALUES
        (10002100, 10000008, '2026-06-04T00:00:00', 'PAT',
         '2026-06-04T00:00:00', 'RTR LDF patient answer', 1);
    PRINT '[zz_ldf_subsystem] inserted PAT LDF answer on Person 10000008';
END
GO

-- ---------------------------------------------------------------------
-- 3. ORG LDF answer on Organization 10003001 (d_organization key 2)
--    -> sp_ldf_organization_event -> ORGANIZATION_LDF_GROUP.
-- ---------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM dbo.State_Defined_Field_Data
               WHERE ldf_uid = 10002105 AND business_object_uid = 10003001)
BEGIN
    INSERT INTO dbo.State_Defined_Field_Data
        (ldf_uid, business_object_uid, add_time, business_object_nm,
         last_chg_time, ldf_value, version_ctrl_nbr)
    VALUES
        (10002105, 10003001, '2026-06-04T00:00:00', 'ORG',
         '2026-06-04T00:00:00', 'RTR LDF organization answer', 1);
    PRINT '[zz_ldf_subsystem] inserted ORG LDF answer on Organization 10003001';
END
GO

-- ---------------------------------------------------------------------
-- 4. Closing change-time bump on the seeded LDF metadata rows we lean on,
--    so the metadata change is re-captured by CDC and re-projected to
--    nrt_odse_state_defined_field_metadata (odse_meta_connector captures
--    dbo.state_defined_field_metadata), keeping the metadata in sync with
--    the new answers. The State_Defined_Field_MetaData table has no
--    last_chg_time column; record_status_time is its change-tracked time
--    column. Idempotent (fixed ts; no-op once applied). NOT strictly
--    required for the chain — the LDF_DATA topic itself re-runs the
--    dimensional SP — but mirrors the existing-fixture closing-bump
--    convention and guarantees a metadata re-projection.
-- ---------------------------------------------------------------------
UPDATE dbo.State_Defined_Field_MetaData
SET record_status_time = '2026-06-04T00:00:01'
WHERE ldf_uid IN (10002099, 10002100, 10002105)
  AND (record_status_time IS NULL OR record_status_time <> '2026-06-04T00:00:01');
PRINT '[zz_ldf_subsystem] bumped record_status_time on 3 LDF metadata rows';
GO

PRINT '[zz_ldf_subsystem] done';
GO
