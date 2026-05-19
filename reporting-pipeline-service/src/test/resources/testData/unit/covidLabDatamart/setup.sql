-- ============================================================
-- COVID_LAB_DATAMART Post-Processing Stored Procedure
-- Happy path unit test for sp_covid_lab_datamart_postprocessing
--  - assumes all entities are present in nrt tables
--  - skips code branch to populate AOE columns
-- ============================================================

USE [RDB_Modern];

-- ------------------------------------------------------------
-- UIDs
-- ------------------------------------------------------------
DECLARE @patient_uid        BIGINT = 90001001;
DECLARE @org_uid_perform    BIGINT = 90002001;   -- Testing lab
DECLARE @org_uid_author     BIGINT = 90002002;   -- Reporting facility
DECLARE @org_uid_order      BIGINT = 90002003;   -- Ordering facility
DECLARE @provider_uid       BIGINT = 90003001;
DECLARE @material_id        BIGINT = 90004001;
DECLARE @phc_uid            BIGINT = 90005001;
DECLARE @obs_uid_order      BIGINT = 90006001;
DECLARE @obs_uid_result     BIGINT = 90006002;

-- ------------------------------------------------------------
-- Reference / SRTE tables
-- ------------------------------------------------------------

-- Add condition mapping for Covid LOINCs
INSERT INTO dbo.nrt_srte_Loinc_condition (loinc_cd, condition_cd)
SELECT '94500-6', '11065'
    WHERE NOT EXISTS (SELECT 1 FROM dbo.nrt_srte_Loinc_condition WHERE loinc_cd = '94500-6' AND condition_cd = '11065');

INSERT INTO dbo.nrt_srte_Loinc_condition (loinc_cd, condition_cd)
SELECT '94309-2', '11065'
    WHERE NOT EXISTS (SELECT 1 FROM dbo.nrt_srte_Loinc_condition WHERE loinc_cd = '94309-2' AND condition_cd = '11065');

-- Ensure our LOINC values don't have invalid details
DELETE FROM dbo.nrt_srte_Loinc_code
WHERE loinc_cd IN ('94500-6', '94309-2') AND time_aspect = 'Pt' AND system_cd = '^Patient';

-- ------------------------------------------------------------
-- Patient
-- ------------------------------------------------------------
INSERT INTO dbo.nrt_patient
(patient_uid, local_id, last_name, middle_name, first_name, curr_sex_cd,
 age_reported, age_reported_unit_cd, dob, phone_home,
 street_address_1, city, state_code, zip, county_code, county,
 race_calculated, ethnic_group_ind)
VALUES
    (@patient_uid, 'PSN-TEST-' + CAST(@patient_uid AS VARCHAR), 'Smith', 'A', 'John', 'M',
     '45', 'a', '1979-03-15', '4045550100',
     '123 Main St', 'Atlanta', '13', '30301', '063', 'Fulton',
     'White', 'N');

INSERT INTO dbo.nrt_patient_key (patient_uid)
VALUES (@patient_uid);

-- ------------------------------------------------------------
-- Organizations
-- ------------------------------------------------------------
INSERT INTO dbo.nrt_organization
(organization_uid, organization_name, street_address_1, city, state_code, state, zip, county_code, county, country_code, facility_id, phone_work, phone_ext_work)
VALUES
    (@org_uid_perform, 'State Reference Lab',      '456 Lab Blvd',     'Atlanta', '13', 'Georgia', '30302', '063', 'Fulton', 'US', '10D2289533', '4045550200', ''),
    (@org_uid_author,  'Emory University Hospital', '789 Clifton Rd',  'Atlanta', '13', 'Georgia', '30322', '063', 'Fulton', 'US', '10D0123456', '4045550300', ''),
    (@org_uid_order,   'Peachtree Urgent Care',    '321 Peachtree St', 'Atlanta', '13', 'Georgia', '30303', '063', 'Fulton', 'US', '10D9876543', '4045550400', '');

-- ------------------------------------------------------------
-- Provider
-- ------------------------------------------------------------
INSERT INTO dbo.nrt_provider
(provider_uid, first_name, last_name, street_address_1, city, state_code, zip, county_code, county, country_code, phone_work_phone, phone_ext_work_phone, provider_npi)
VALUES
    (@provider_uid, 'Jane', 'Doe', '555 Provider Ave', 'Atlanta', '13', '30308', '063', 'Fulton', 'US', '4045550500', '', '1234567890');

-- ------------------------------------------------------------
-- Observation material (specimen)
-- ------------------------------------------------------------
INSERT INTO dbo.nrt_observation_material (act_uid, material_id, material_cd, material_desc, material_details)
VALUES (@obs_uid_order, @material_id, 'NP', 'Nasopharyngeal Swab', 'Combined Naso/Oropharyngeal Swab');

-- ------------------------------------------------------------
-- Investigation
-- ------------------------------------------------------------
INSERT INTO dbo.nrt_investigation (public_health_case_uid, local_id)
VALUES (@phc_uid, 'CAS-TEST-' + CAST(@phc_uid AS VARCHAR));

-- ------------------------------------------------------------
-- Observations (order and result)
-- ------------------------------------------------------------
INSERT INTO dbo.nrt_observation
(observation_uid, local_id, record_status_cd, cd, cd_desc_txt, cd_system_cd,
 electronic_ind, version_ctrl_nbr, prog_area_cd, jurisdiction_cd,
 activity_to_time, rpt_to_state_time, activity_from_time, effective_from_time,
 target_site_cd, target_site_desc_txt, status_cd,
 accession_number, add_time, last_chg_time,
 result_observation_uid, obs_domain_cd_st_1,
 material_id, patient_id,
 performing_organization_id, author_organization_id, ordering_organization_id,
 ordering_person_id, associated_phc_uids, batch_id,
 method_cd, method_desc_txt, device_instance_id_1, device_instance_id_2,
 interpretation_cd, interpretation_desc_txt)
VALUES
    -- ORDER row
    (@obs_uid_order, 'LAB-TEST-' + CAST(@obs_uid_order AS VARCHAR), 'ACTIVE', '94500-6', 'SARS-CoV-2 RNA panel', 'LN',
     'Y', 1, 'STD', '130001',
     '2021-01-10 12:00:00', '2021-01-10 14:00:00', '2021-01-09 09:00:00', '2021-01-09 09:00:00',
     'NP', 'Nasopharynx', 'D',
     'ACC-2021-001', '2021-01-10 08:00:00', '2021-01-10 15:00:00',
     CAST(@obs_uid_result AS NVARCHAR(MAX)), 'Order',
     @material_id, @patient_uid,
     @org_uid_perform, @org_uid_author, @org_uid_order,
     CAST(@provider_uid AS NVARCHAR(MAX)), CAST(@phc_uid AS NVARCHAR(MAX)), 1,
     NULL, NULL, NULL, NULL, NULL, NULL),

    -- RESULT row
    (@obs_uid_result, 'LAB-TEST-' + CAST(@obs_uid_result AS VARCHAR), 'ACTIVE', '94309-2', 'SARS-CoV-2 RNA Ql NAA+probe', 'LN',
     'Y', 1, 'STD', 'GA',
     '2021-01-10 12:00:00', NULL, NULL, NULL,
     NULL, NULL, 'D',
     NULL, '2021-01-10 08:00:00', '2021-01-10 15:00:00',
     NULL, 'Result',
     NULL, @patient_uid,
     @org_uid_perform, @org_uid_author, @org_uid_order,
     CAST(@provider_uid AS NVARCHAR(MAX)), CAST(@phc_uid AS NVARCHAR(MAX)), 1,
     'EUA001', 'RT-PCR', 'DEVICE-SERIAL-001', NULL,
     'POS', 'Positive');

-- ------------------------------------------------------------
-- Observation results
-- ------------------------------------------------------------

-- Coded result — "Detected"
INSERT INTO dbo.nrt_observation_coded (observation_uid, ovc_code, ovc_code_system_cd, ovc_display_name)
VALUES (@obs_uid_result, '260373001', 'SCT', 'Detected');

-- Text result (type 'O') and comment (type 'N')
INSERT INTO dbo.nrt_observation_txt (observation_uid, ovt_seq, ovt_txt_type_cd, ovt_value_txt)
VALUES
    (@obs_uid_result, 1, 'O', 'SARS-CoV-2 RNA Detected'),
    (@obs_uid_result, 2, 'N', 'Specimen received in good condition.');

-- ------------------------------------------------------------
-- Execute the stored procedure
-- ------------------------------------------------------------
DECLARE @obs_id_list NVARCHAR(MAX) = CAST(@obs_uid_order AS NVARCHAR(MAX));

EXEC dbo.sp_covid_lab_datamart_postprocessing
    @observation_id_list = @obs_id_list,
    @debug               = 'false';