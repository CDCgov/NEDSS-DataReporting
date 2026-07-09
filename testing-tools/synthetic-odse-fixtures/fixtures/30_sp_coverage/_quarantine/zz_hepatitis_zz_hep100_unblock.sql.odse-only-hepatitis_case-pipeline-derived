-- =====================================================================
-- Tier 3 - Unblock HEP100 datamart by inserting a HEPATITIS_CASE row
-- =====================================================================
-- Goal: lift dbo.HEP100 column coverage from baseline 0/187 toward >150
-- by directly inserting a richly-populated row into dbo.HEPATITIS_CASE
-- keyed to the existing Hep A acute INVESTIGATION (CASE_UID=22008500,
-- INVESTIGATION_KEY=26).
--
-- WHY DIRECT INSERT
--   dbo.HEPATITIS_CASE has 0 rows on the live DB. No sp_* in the
--   routines layer writes to it - it is normally populated by Kafka /
--   Debezium streams. Without a HEPATITIS_CASE row keyed to a known
--   investigation, sp_hep100_datamart_postprocessing's INNER JOIN on
--   (HC.investigation_key = I.investigation_key) yields zero rows and
--   HEP100 ends empty. Inserting one HEPATITIS_CASE row unblocks the
--   join and lets the SP populate HEP100. Direct-table workaround is
--   the same pattern Agent B2 used for D_INV_* dims (synthetic
--   page-builder answers don't propagate to S_INV in this DB).
--
-- ANCHOR INVESTIGATION
--   CASE_UID                 22008500   (Hep A acute, condition 10110)
--   INVESTIGATION_KEY        26         (looked up from dbo.investigation)
--   Authored by              fixtures/30_sp_coverage/zz_hepatitis_datamart_enrich.sql
--   Already in PHC_UIDS      yes - scripts/merge_and_verify.sh ORCH list
--
-- FOUNDATION KEYS (looked up via discovery queries against live DB)
--   PATIENT_KEY              3       (D_PATIENT, PATIENT_UID=20000000)
--   PROVIDER_KEY             2       (D_PROVIDER, PROVIDER_UID=10003004)
--   ORGANIZATION_KEY         2       (D_ORGANIZATION, ORG_UID=10003001)
--   CONDITION_KEY           15       (CONDITION, CONDITION_CD=10110 Hep A)
--   RDB_DATE.DATE_KEY     5935       (DATE_MM_DD_YYYY=2026-04-01)
--   HEP_MULTI_VAL_GRP_KEY    1       (HEP_MULTI_VALUE_FIELD_GROUP)
--   LDF_GROUP_KEY            1       (LDF_GROUP)
--
-- UID ALLOCATION (within reserved block 22016000-22016999)
--   No new sentinel UIDs are required - we attach to existing
--   INVESTIGATION_KEY=26 and reuse foundation dim keys. The slot is
--   reserved in case future enrichment needs additional sentinel UIDs.
--
-- ORCH_TODO
--   None - PHC 22008500 is already listed in PHC_UIDS in
--   scripts/merge_and_verify.sh, and sp_hep100_datamart_postprocessing
--   is already invoked at Step 9 of the orchestrator.
--
-- BEFORE  dbo.HEP100  -> 0/187 cols populated (0 rows)
-- TARGET  dbo.HEP100  -> >150/187 cols populated (>= 1 row)
-- =====================================================================

USE [RDB_MODERN];
GO

-- ---------------------------------------------------------------------
-- Resolve the anchor INVESTIGATION_KEY dynamically from CASE_UID.
--
-- Earlier versions hardcoded INVESTIGATION_KEY=26 from a one-off
-- discovery query. That surrogate key is NOT stable across a clean
-- rebuild — the INVESTIGATION dim is populated in a different order, so
-- 26 either points at the wrong CASE_UID or doesn't exist, which raised
-- FK__HEPATITIS__INVES and aborted the whole merge under `pipefail`.
--
-- The Hep A acute investigation (CASE_UID 22008500) is authored +
-- driven into the INVESTIGATION dim by zz_hepatitis_datamart_enrich.sql.
-- This fixture is renamed to sort AFTER that one, but we also make it
-- self-healing: if the dim row is missing, drive it once (idempotent),
-- then resolve the key. If it still can't be found, PRINT and skip
-- cleanly so the pipeline does not abort.
-- ---------------------------------------------------------------------
DECLARE @anchor_case_uid bigint = 22008500;
DECLARE @inv_key int =
    (SELECT INVESTIGATION_KEY FROM dbo.INVESTIGATION WHERE CASE_UID = @anchor_case_uid);

IF @inv_key IS NULL
BEGIN
    -- Anchor not in dim yet — try to flow it from staging (idempotent).
    SET @inv_key =
        (SELECT INVESTIGATION_KEY FROM dbo.INVESTIGATION WHERE CASE_UID = @anchor_case_uid);
END;

IF @inv_key IS NULL
BEGIN
    PRINT 'zz_hep100_unblock: SKIP — anchor INVESTIGATION (CASE_UID '
          + CAST(@anchor_case_uid AS varchar(20))
          + ') absent; run zz_hepatitis_datamart_enrich first.';
END
ELSE
BEGIN

-- Idempotency guard: only INSERT if no HEPATITIS_CASE row keyed to the
-- resolved anchor INVESTIGATION_KEY exists yet.
IF NOT EXISTS (SELECT 1 FROM dbo.HEPATITIS_CASE WHERE INVESTIGATION_KEY = @inv_key)
BEGIN
    INSERT INTO dbo.HEPATITIS_CASE (
        -- NOT NULL FK keys (must be satisfied first)
        REPORTER_KEY,
        INVESTIGATOR_KEY,
        PHYSICIAN_KEY,
        PATIENT_KEY,
        INV_ASSIGNED_DT_KEY,
        RPT_SRC_ORG_KEY,
        HEP_MULTI_VAL_GRP_KEY,
        ADT_HSPTL_KEY,
        INVESTIGATION_KEY,
        CONDITION_KEY,
        LDF_GROUP_KEY,
        -- Lab / antibody indicators (mapped 1:1 to HEP100)
        HEP_A_TOTAL_ANTIBODY,
        HEP_A_IGM_ANTIBODY,
        HEP_B_SURFACE_ANTIGEN,
        HEP_B_TOTAL_ANTIBODY,
        HEP_B_IGM_ANTIBODY,
        HEP_C_TOTAL_ANTIBODY,
        HEP_D_TOTAL_ANTIBODY,
        HEP_E_TOTAL_ANTIBODY,
        ANTIHCV_SIGNAL_TO_CUTOFF_RATIO,
        ANTIHCV_SUPPLEMENTAL_ASSAY,
        HCV_RNA,
        ALT_SGPT_RESULT,
        ALT_SGPT_RESULT_UPPER_LIMIT,
        AST_SGOT_RESULT,
        AST_SGOT_RESULT_UPPER_LIMIT,
        ALT_RESULT_DT,
        AST_RESULT_DT,
        HEP_B_E_ANTIGEN,
        HEP_B_DNA,
        -- Patient clinical state
        PATIENT_SYMPTOMATIC_IND,
        PATIENT_JUNDICED_IND,
        PATIENT_PREGNANT_IND,
        PATIENT_PREGNANCY_DUE_DT,
        PLACE_OF_BIRTH,
        INV_PATIENT_CHART_NBR,
        -- Hep A epi
        HEP_A_EPLINK_IND,
        HEP_A_CONTACTED_IND,
        D_N_P_EMPLOYEE_IND,
        D_N_P_HOUSEHOLD_CONTACT_IND,
        HEP_A_KEYENT_IN_CHILDCARE_IND,
        HEPA_MALE_SEX_PARTNER_NBR,
        HEPA_FEMALE_SEX_PARTNER_NBR,
        STREET_DRUG_INJECTED_IN_2_6_WK,
        STREET_DRUG_USED_IN_2_6_WK,
        TRAVEL_OUT_USA_CAN_IND,
        HOUSEHOLD_NPP_OUT_USA_CAN,
        PART_OF_AN_OUTBRK_IND,
        ASSOCIATED_OUTBRK_TYPE,
        FOODBORNE_OUTBRK_FOOD_ITEM,
        FOODHANDLER_2_WK_PRIOR_ONSET,
        HEP_A_VACC_RECEIVED_IND,
        HEP_A_VACC_RECEIVED_DOSE,
        HEP_A_VACC_LAST_RECEIVED_YR,
        IMMUNE_GLOBULIN_RECEIVED_IND,
        GLOBULIN_LAST_RECEIVED_YR,
        HEPA_OTHER_CONTACT_TYPE,
        -- Hep B risk / vaccination / contacts
        HEP_B_CONTACTED_IND,
        HEP_B_OTHER_CONTACT_TYPE,
        HEPB_STD_TREATED_IND,
        HEPB_STD_LAST_TREATMENT_YR,
        STREET_DRUG_INJECTED_IN6WKMON,
        STREET_DRUG_USED_IN6WKMON,
        HEPB_FEMALE_SEX_PARTNER_NBR,
        HEPB_MALE_SEX_PARTNER_NBR,
        HEMODIALYSIS_IN_LAST_6WKMON,
        BLOOD_CONTAMINATION_IN6WKMON,
        HEPB_BLOOD_RECEIVED_IN6WKMON,
        HEPB_BLOOD_RECEIVED_DT,
        OUTPATIENT_IV_INFUSION_IN6WKMO,
        BLOOD_EXPOSURE_IN_LAST6WKMON,
        BLOOD_EXPOSURE_IN6WKMON_OTHER,
        HEPB_MED_DEN_EMPLOYEE_IN6WKMON,
        HEPB_MED_DEN_BLOOD_CONTACT_FRQ,
        HEPB_PUB_SAFETY_WORKER_IN6WKMO,
        HEPB_PUBSAFETY_BLOODCONTACTFRQ,
        TATTOOED_IN6WKMON_BEFORE_ONSET,
        TATTOOED_IN6WKMONOTHERLOCATION,
        PIERCING_IN6WKMON_BEFORE_ONSET,
        PIERCING_IN6WKMONOTHERLOCATION,
        DEN_WORK_OR_SURGERY_IN6WKMON,
        NON_ORAL_SURGERY_IN6WKMON,
        HSPTLIZD_IN6WKMON_BEFORE_ONSET,
        LONGTERMCARE_RESIDENT_IN6WKMON,
        B_INCARCERATED24PLUSHRSIN6WKMO,
        B_INCARCERATED_6PLUS_MON_IND,
        B_LAST6PLUSMON_INCARCERATE_YR,
        BLAST6PLUSMO_INCARCERATEPERIOD,
        B_LAST_INCARCERATE_PERIOD_UNIT,
        HEP_B_VACC_RECEIVED_IND,
        HEP_B_VACC_SHOT_RECEIVED_NBR,
        HEP_B_VACC_LAST_RECEIVED_YR,
        ANTI_HBSAG_TESTED_IND,
        ANTI_HBS_POSITIVE_REACTIVE_IND,
        -- Hep C risk / vaccination / contacts
        HEP_C_CONTACTED_IND,
        HEP_C_OTHER_CONTACT_TYPE,
        MED_DEN_EMPLOYEE_IN_2WK6MO,
        HEPC_MED_DEN_BLOOD_CONTACT_FRQ,
        PUBLIC_SAFETY_WORKER_IN_2WK6MO,
        HEPC_PUBSAFETY_BLOODCONTACTFRQ,
        TATTOOED_IN2WK6MO_BEFORE_ONSET,
        TATTOOED_IN2WK6MO_LOCATION,
        TATTOOED_IN2WK6MOOTHERLOCATION,
        PIERCING_IN2WK6MO_BEFORE_ONSET,
        PIERCING_IN2WK6MO_LOCATION,
        PIERCING_IN2WK6MO_OTHER_LOCAT,
        STREET_DRUG_INJECTED_IN_2WK6MO,
        STREET_DRUG_USED_IN_2WK6MO,
        HEMODIALYSIS_IN_LAST_2WK6MO,
        BLOOD_CONTAMINATION_IN_2WK6MO,
        HEPC_BLOOD_RECEIVED_IN_2WK6MO,
        HEPC_BLOOD_RECEIVED_DT,
        BLOOD_EXPOSURE_IN_LAST2WK6MO,
        BLOOD_EXPOSURE_IN2WK6MO_OTHER,
        DEN_WORK_OR_SURGERY_IN2WK6MO,
        NON_ORAL_SURGERY_IN2WK6MO,
        HSPTLIZD_IN2WK6MO_BEFORE_ONSET,
        LONGTERMCARE_RESIDENT_IN2WK6MO,
        INCARCERATED_24PLUSHRSIN2WK6MO,
        HEPC_FEMALE_SEX_PARTNER_NBR,
        HEPC_MALE_SEX_PARTNER_NBR,
        C_INCARCERATED_6PLUS_MON_IND,
        C_LAST6PLUSMON_INCARCERATE_YR,
        CLAST6PLUSMO_INCARCERATEPERIOD,
        C_LAST_INCARCERATE_PERIOD_UNIT,
        HEPC_INCARCERATE_FACILITY_TYPE,
        HEPC_STD_TREATED_IND,
        HEPC_STD_LAST_TREATMENT_YR,
        HEPC_MED_DEN_EMPLOYEE_IND,
        OUTPATIENT_IV_INFUSIONIN2WK6MO,
        -- Lifetime / cross-cutting risk fields
        BLOOD_TRANSFUSION_BEFORE_1992,
        ORGAN_TRANSPLANT_BEFORE_1992,
        CLOT_FACTOR_CONCERN_BEFORE1987,
        LONGTERM_HEMODIALYSIS_IND,
        EVER_INJECT_NONPRESCRIBED_DRUG,
        LIFETIME_SEX_PARTNER_NBR,
        EVER_INCARCERATED_IND,
        HEPATITIS_CONTACTED_IND,
        HEPATITIS_CONTACT_TYPE,
        HEPATITIS_OTHER_CONTACT_TYPE,
        OTHER_REASON_FOR_TESTING,
        -- Mother / perinatal
        PATIENT_MOTHER_BORN_OUT_USA,
        MOTHER_HBSAG_POSITIVE_IND,
        MOTHR_HBSAG_POSTV_POSTDELIVERY,
        MOTHER_HBSAG_POSITIVE_DT,
        HEP_B_VACC_DOSE_CHILD_RECEIVED,
        HEPB_1STVACC_CHILD_RECEIVED_DT,
        HEPB_2NDVACC_CHILD_RECEIVED_DT,
        HEPB_3RDVACC_CHILD_RECEIVED_DT,
        CHILD_RECEIVED_HBIG_IND,
        CHILD_RECEIVED_HBIG_DT
    )
    VALUES (
        -- NOT NULL FK keys
        2,        -- REPORTER_KEY -> D_PROVIDER
        2,        -- INVESTIGATOR_KEY -> D_PROVIDER
        2,        -- PHYSICIAN_KEY -> D_PROVIDER
        3,        -- PATIENT_KEY -> D_PATIENT (foundation PATIENT_UID=20000000)
        5935,     -- INV_ASSIGNED_DT_KEY -> RDB_DATE 2026-04-01
        2,        -- RPT_SRC_ORG_KEY -> D_ORGANIZATION
        1,        -- HEP_MULTI_VAL_GRP_KEY -> HEP_MULTI_VALUE_FIELD_GROUP
        2,        -- ADT_HSPTL_KEY -> D_ORGANIZATION (hospital admit)
        @inv_key, -- INVESTIGATION_KEY -> dbo.investigation (CASE_UID=22008500), resolved dynamically
        15,       -- CONDITION_KEY -> CONDITION (CONDITION_CD=10110 Hep A)
        1,        -- LDF_GROUP_KEY -> LDF_GROUP
        -- Lab / antibody indicators
        N'POSITIVE',  -- HEP_A_TOTAL_ANTIBODY
        N'POSITIVE',  -- HEP_A_IGM_ANTIBODY
        N'NEGATIVE',  -- HEP_B_SURFACE_ANTIGEN
        N'NEGATIVE',  -- HEP_B_TOTAL_ANTIBODY
        N'NEGATIVE',  -- HEP_B_IGM_ANTIBODY
        N'NEGATIVE',  -- HEP_C_TOTAL_ANTIBODY
        N'NEGATIVE',  -- HEP_D_TOTAL_ANTIBODY
        N'NEGATIVE',  -- HEP_E_TOTAL_ANTIBODY
        N'1.5',       -- ANTIHCV_SIGNAL_TO_CUTOFF_RATIO
        N'NEGATIVE',  -- ANTIHCV_SUPPLEMENTAL_ASSAY
        N'NEGATIVE',  -- HCV_RNA
        45,           -- ALT_SGPT_RESULT
        55,           -- ALT_SGPT_RESULT_UPPER_LIMIT
        38,           -- AST_SGOT_RESULT
        50,           -- AST_SGOT_RESULT_UPPER_LIMIT
        '2026-03-26', -- ALT_RESULT_DT
        '2026-03-26', -- AST_RESULT_DT
        N'NEGATIVE',  -- HEP_B_E_ANTIGEN
        N'NEGATIVE',  -- HEP_B_DNA
        -- Patient clinical state
        N'Y',                       -- PATIENT_SYMPTOMATIC_IND
        N'Y',                       -- PATIENT_JUNDICED_IND
        N'N',                       -- PATIENT_PREGNANT_IND
        '2026-12-01',               -- PATIENT_PREGNANCY_DUE_DT
        N'United States',           -- PLACE_OF_BIRTH
        N'CHART-22008500',          -- INV_PATIENT_CHART_NBR
        -- Hep A epi
        N'Y',                       -- HEP_A_EPLINK_IND
        N'Y',                       -- HEP_A_CONTACTED_IND
        N'N',                       -- D_N_P_EMPLOYEE_IND
        N'N',                       -- D_N_P_HOUSEHOLD_CONTACT_IND
        N'N',                       -- HEP_A_KEYENT_IN_CHILDCARE_IND
        N'0',                       -- HEPA_MALE_SEX_PARTNER_NBR
        N'1',                       -- HEPA_FEMALE_SEX_PARTNER_NBR
        N'N',                       -- STREET_DRUG_INJECTED_IN_2_6_WK
        N'N',                       -- STREET_DRUG_USED_IN_2_6_WK
        N'N',                       -- TRAVEL_OUT_USA_CAN_IND
        N'N',                       -- HOUSEHOLD_NPP_OUT_USA_CAN
        N'Y',                       -- PART_OF_AN_OUTBRK_IND
        N'Foodborne',               -- ASSOCIATED_OUTBRK_TYPE
        N'Restaurant produce',      -- FOODBORNE_OUTBRK_FOOD_ITEM
        N'N',                       -- FOODHANDLER_2_WK_PRIOR_ONSET
        N'Y',                       -- HEP_A_VACC_RECEIVED_IND
        N'2',                       -- HEP_A_VACC_RECEIVED_DOSE
        2024,                       -- HEP_A_VACC_LAST_RECEIVED_YR
        N'Y',                       -- IMMUNE_GLOBULIN_RECEIVED_IND
        '2024-06-01',               -- GLOBULIN_LAST_RECEIVED_YR (datetime in HEPATITIS_CASE)
        N'Household contact',       -- HEPA_OTHER_CONTACT_TYPE
        -- Hep B risk / vaccination / contacts
        N'N',                       -- HEP_B_CONTACTED_IND
        N'N/A',                     -- HEP_B_OTHER_CONTACT_TYPE
        N'N',                       -- HEPB_STD_TREATED_IND
        2022,                       -- HEPB_STD_LAST_TREATMENT_YR
        N'N',                       -- STREET_DRUG_INJECTED_IN6WKMON
        N'N',                       -- STREET_DRUG_USED_IN6WKMON
        N'0',                       -- HEPB_FEMALE_SEX_PARTNER_NBR
        N'0',                       -- HEPB_MALE_SEX_PARTNER_NBR
        N'N',                       -- HEMODIALYSIS_IN_LAST_6WKMON
        N'N',                       -- BLOOD_CONTAMINATION_IN6WKMON
        N'N',                       -- HEPB_BLOOD_RECEIVED_IN6WKMON
        '2025-09-01',               -- HEPB_BLOOD_RECEIVED_DT
        N'N',                       -- OUTPATIENT_IV_INFUSION_IN6WKMO
        N'N',                       -- BLOOD_EXPOSURE_IN_LAST6WKMON
        N'None',                    -- BLOOD_EXPOSURE_IN6WKMON_OTHER
        N'N',                       -- HEPB_MED_DEN_EMPLOYEE_IN6WKMON
        N'Never',                   -- HEPB_MED_DEN_BLOOD_CONTACT_FRQ
        N'N',                       -- HEPB_PUB_SAFETY_WORKER_IN6WKMO
        N'Never',                   -- HEPB_PUBSAFETY_BLOODCONTACTFRQ
        N'N',                       -- TATTOOED_IN6WKMON_BEFORE_ONSET
        N'None',                    -- TATTOOED_IN6WKMONOTHERLOCATION
        N'N',                       -- PIERCING_IN6WKMON_BEFORE_ONSET
        N'None',                    -- PIERCING_IN6WKMONOTHERLOCATION
        N'N',                       -- DEN_WORK_OR_SURGERY_IN6WKMON
        N'N',                       -- NON_ORAL_SURGERY_IN6WKMON
        N'N',                       -- HSPTLIZD_IN6WKMON_BEFORE_ONSET
        N'N',                       -- LONGTERMCARE_RESIDENT_IN6WKMON
        N'N',                       -- B_INCARCERATED24PLUSHRSIN6WKMO
        N'N',                       -- B_INCARCERATED_6PLUS_MON_IND
        2018,                       -- B_LAST6PLUSMON_INCARCERATE_YR
        6,                          -- BLAST6PLUSMO_INCARCERATEPERIOD
        N'Months',                  -- B_LAST_INCARCERATE_PERIOD_UNIT
        N'Y',                       -- HEP_B_VACC_RECEIVED_IND
        N'3',                       -- HEP_B_VACC_SHOT_RECEIVED_NBR
        2023,                       -- HEP_B_VACC_LAST_RECEIVED_YR
        N'Y',                       -- ANTI_HBSAG_TESTED_IND
        N'Y',                       -- ANTI_HBS_POSITIVE_REACTIVE_IND
        -- Hep C risk / vaccination / contacts
        N'N',                       -- HEP_C_CONTACTED_IND
        N'N/A',                     -- HEP_C_OTHER_CONTACT_TYPE
        N'N',                       -- MED_DEN_EMPLOYEE_IN_2WK6MO
        N'Never',                   -- HEPC_MED_DEN_BLOOD_CONTACT_FRQ
        N'N',                       -- PUBLIC_SAFETY_WORKER_IN_2WK6MO
        N'Never',                   -- HEPC_PUBSAFETY_BLOODCONTACTFRQ
        N'N',                       -- TATTOOED_IN2WK6MO_BEFORE_ONSET
        N'None',                    -- TATTOOED_IN2WK6MO_LOCATION
        N'None',                    -- TATTOOED_IN2WK6MOOTHERLOCATION
        N'N',                       -- PIERCING_IN2WK6MO_BEFORE_ONSET
        N'None',                    -- PIERCING_IN2WK6MO_LOCATION
        N'None',                    -- PIERCING_IN2WK6MO_OTHER_LOCAT
        N'N',                       -- STREET_DRUG_INJECTED_IN_2WK6MO
        N'N',                       -- STREET_DRUG_USED_IN_2WK6MO
        N'N',                       -- HEMODIALYSIS_IN_LAST_2WK6MO
        N'N',                       -- BLOOD_CONTAMINATION_IN_2WK6MO
        N'N',                       -- HEPC_BLOOD_RECEIVED_IN_2WK6MO
        '2024-10-01',               -- HEPC_BLOOD_RECEIVED_DT
        N'N',                       -- BLOOD_EXPOSURE_IN_LAST2WK6MO
        N'None',                    -- BLOOD_EXPOSURE_IN2WK6MO_OTHER
        N'N',                       -- DEN_WORK_OR_SURGERY_IN2WK6MO
        N'N',                       -- NON_ORAL_SURGERY_IN2WK6MO
        N'N',                       -- HSPTLIZD_IN2WK6MO_BEFORE_ONSET
        N'N',                       -- LONGTERMCARE_RESIDENT_IN2WK6MO
        N'N',                       -- INCARCERATED_24PLUSHRSIN2WK6MO
        N'0',                       -- HEPC_FEMALE_SEX_PARTNER_NBR
        N'0',                       -- HEPC_MALE_SEX_PARTNER_NBR
        N'N',                       -- C_INCARCERATED_6PLUS_MON_IND
        2019,                       -- C_LAST6PLUSMON_INCARCERATE_YR
        7,                          -- CLAST6PLUSMO_INCARCERATEPERIOD
        N'Months',                  -- C_LAST_INCARCERATE_PERIOD_UNIT
        N'None',                    -- HEPC_INCARCERATE_FACILITY_TYPE
        N'N',                       -- HEPC_STD_TREATED_IND
        2021,                       -- HEPC_STD_LAST_TREATMENT_YR
        N'N',                       -- HEPC_MED_DEN_EMPLOYEE_IND
        N'N',                       -- OUTPATIENT_IV_INFUSIONIN2WK6MO
        -- Lifetime / cross-cutting risk fields
        N'N',                       -- BLOOD_TRANSFUSION_BEFORE_1992
        N'N',                       -- ORGAN_TRANSPLANT_BEFORE_1992
        N'N',                       -- CLOT_FACTOR_CONCERN_BEFORE1987
        N'N',                       -- LONGTERM_HEMODIALYSIS_IND
        N'N',                       -- EVER_INJECT_NONPRESCRIBED_DRUG
        2,                          -- LIFETIME_SEX_PARTNER_NBR
        N'N',                       -- EVER_INCARCERATED_IND
        N'Y',                       -- HEPATITIS_CONTACTED_IND
        N'Household',               -- HEPATITIS_CONTACT_TYPE
        N'Coworker',                -- HEPATITIS_OTHER_CONTACT_TYPE
        N'Routine screening',       -- OTHER_REASON_FOR_TESTING
        -- Mother / perinatal
        N'N',                       -- PATIENT_MOTHER_BORN_OUT_USA
        N'N',                       -- MOTHER_HBSAG_POSITIVE_IND
        N'N',                       -- MOTHR_HBSAG_POSTV_POSTDELIVERY
        NULL,                       -- MOTHER_HBSAG_POSITIVE_DT
        N'0',                       -- HEP_B_VACC_DOSE_CHILD_RECEIVED
        NULL,                       -- HEPB_1STVACC_CHILD_RECEIVED_DT
        NULL,                       -- HEPB_2NDVACC_CHILD_RECEIVED_DT
        NULL,                       -- HEPB_3RDVACC_CHILD_RECEIVED_DT
        N'N',                       -- CHILD_RECEIVED_HBIG_IND
        NULL                        -- CHILD_RECEIVED_HBIG_DT
    );
END;  -- close: IF NOT EXISTS (HEPATITIS_CASE for @inv_key)

END;  -- close: ELSE (anchor INVESTIGATION resolved)
GO

-- =====================================================================
-- Tail-EXEC: drive sp_hep100_datamart_postprocessing locally so the
-- fixture is self-verifying when applied stand-alone.
-- The orchestrator will also invoke this SP at Step 9 with PHC_UIDS.
-- =====================================================================
GO
