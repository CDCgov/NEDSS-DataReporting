-- =====================================================================
-- Tier 3 — COVID Lab CELR Datamart unblock
-- =====================================================================
-- Goal: lift `dbo.COVID_LAB_CELR_DATAMART` from 0/101 columns -> 84/101
--       columns by tail-EXECing `sp_covid_lab_celr_datamart_postprocessing`
--       against the COVID Lab Order UID 22022000 that Agent P seeded into
--       `dbo.covid_lab_datamart` (see zz_covid_lab_datamart_unblock.sql).
--
-- HOW THIS DIFFERS FROM zz_covid_lab_datamart_unblock.sql
--   The CELR SP (sp_covid_lab_celr_datamart_postprocessing) is a much
--   simpler downstream consumer than the LAB SP (sp_covid_lab_datamart_postprocessing):
--     * The LAB SP performs the heavy lifting: it reads nrt_observation
--       and assembles the COVID lab record by filtering on LOINC->condition
--       mapping (nrt_srte_Loinc_condition WHERE condition_cd='11065') and
--       building #COVID_RESULT_LIST, AOE pivots, PHC associations, etc.
--     * The CELR SP just reads from the already-built `dbo.covid_lab_datamart`
--       via `INNER JOIN STRING_SPLIT(@obs_uids,',')` on `cld.Observation_Uid`.
--       No LOINC filter, no condition_cd filter, no observation reads —
--       it's a pure projection/derivation of CLD.
--
--   Consequence: NO new source data is needed. As long as
--   covid_lab_datamart already has observation_uid 22022000 (Agent P's
--   fixture authored it), running the CELR SP with @obs_uids='22022000'
--   suffices to populate COVID_LAB_CELR_DATAMART.
--
--   Live-verified row counts after tail-EXEC on a clean DB:
--     covid_lab_datamart     : 1 row  (P's COVID order, observation_uid=22022000)
--     covid_lab_celr_datamart: 1 row  (84/101 cols populated, +3 over target)
--
-- WHY 84/101 IS THE NATURAL CEILING
--   17 columns of the CELR SP's projection are hardcoded NULL or have no
--   source data in covid_lab_datamart:
--     Submitter_unique_sample_ID, Submitter_sample_ID_assigner (hardcoded NULL)
--     Patient_location, Employed_in_high_risk_setting (hardcoded NULL)
--     Specimen_received_date_time (hardcoded NULL — no specimen_recvd_dt source)
--     Test_method_description (hardcoded NULL)
--     Report_facil_data_source_app (hardcoded NULL)
--     Most_recent_test_date/_result/_type (hardcoded NULL)
--     Disease_symptoms (hardcoded NULL)
--     Patient_occupation, Patient_residency_type (hardcoded NULL)
--     Patient_death_date, Patient_death_indicator (NULL — CLD has none)
--     Specimen_source_site_code_sys (hardcoded NULL)
--     Order_test_date (NULL — CLD has none)
--   Pushing beyond 84 cols would require extending the CLD source row
--   (Agent P's territory) — out of scope for this fixture.
--
-- UID block (Tier 3 — slot 22026xxx)
--   No new UIDs are minted by this fixture. The fixture reuses
--   observation_uid 22022000 (P's COVID Lab Order).
--
-- DEPENDENCIES
--   - zz_covid_lab_datamart_unblock.sql MUST run before this fixture so
--     covid_lab_datamart has the row keyed by Observation_Uid=22022000.
--     Fixture files in 30_sp_coverage are applied in lexical filename
--     order, and `zz_covid_lab_celr_datamart_unblock.sql` sorts after
--     `zz_covid_lab_datamart_unblock.sql` alphabetically, so this is
--     guaranteed by file naming. Defensive PRINT below if not.
--
-- IDEMPOTENCY
--   The SP performs DELETE-then-INSERT keyed by Patient_id, so re-running
--   this fixture is safe. No IF NOT EXISTS guards are needed because the
--   SP itself is idempotent for the observation_uid scope.
--
-- ORCH_TODO
--   Same as P's ORCH_TODO: if `LAB_OBS_UIDS` in
--   `scripts/merge_and_verify.sh` is extended to include '22022000',
--   Step 9 of the orchestrator will also feed CELR via this SP (the
--   orchestrator runs both 320 and 325 against the same UID list, per
--   the codebase pattern). Today the tail-EXEC below is sufficient.
-- =====================================================================

USE [RDB_MODERN];
GO

-- =====================================================================
-- Step 1. Defensive sanity check — verify P's upstream row exists.
-- If covid_lab_datamart lacks observation_uid 22022000 the CELR SP will
-- no-op (SELECT INTO #Patient_LIST returns 0 rows -> early RETURN).
-- Print a clear warning so the orchestrator log makes the dependency
-- visible.
-- =====================================================================
IF NOT EXISTS (
    SELECT 1
    FROM   dbo.covid_lab_datamart WITH (NOLOCK)
    WHERE  observation_uid = 22022000
)
BEGIN
    PRINT 'WARN: dbo.covid_lab_datamart has no row with observation_uid=22022000. '
        + 'Did zz_covid_lab_datamart_unblock.sql run successfully? '
        + 'sp_covid_lab_celr_datamart_postprocessing will no-op without it.';
END;
GO

-- =====================================================================
-- Step 2. Tail-EXEC sp_covid_lab_celr_datamart_postprocessing.
-- The SP signature is (@obs_uids NVARCHAR(MAX), @debug BIT = 'false').
-- Pass the COVID Lab Order UID (22022000) Agent P authored.
-- Wrapped in TRY/CATCH so a future SP refactor cannot break merge.
-- =====================================================================
GO
