-- ============================================================
-- Provider_Event Stored Procedure
-- Unit tests for sp_provider_event
--     Provider 1: baseline happy path
--     Provider 2: inactive cell phone filtered out
-- ============================================================

USE [NBS_ODSE];

-- ------------------------------------------------------------
-- UIDs
-- ------------------------------------------------------------
DECLARE @entity_id_seq       SMALLINT = 1;
DECLARE @add_user_id         BIGINT = 10009282;   -- superuser

-- Provider 1
DECLARE @person_uid          BIGINT = 90010001;
DECLARE @postal_locator_uid  BIGINT = 90011001;
DECLARE @tele_locator_uid_ph BIGINT = 90011002;  -- work phone
DECLARE @tele_locator_uid_em BIGINT = 90011003;  -- email

-- Provider 2
DECLARE @person_uid_2           BIGINT = 90010002;
DECLARE @postal_locator_uid_2   BIGINT = 90011004;
DECLARE @tele_locator_uid_ph_2  BIGINT = 90011005;  -- work phone
DECLARE @tele_locator_uid_cp_2  BIGINT = 90011006;  -- active cell phone
DECLARE @tele_locator_uid_cp_3  BIGINT = 90011007;  -- inactive cell phone
DECLARE @tele_locator_uid_em_2  BIGINT = 90011008;  -- email

-- ------------------------------------------------------------
-- Entity
-- ------------------------------------------------------------
INSERT INTO nbs_odse.dbo.Entity (entity_uid, class_cd)
VALUES
    (@person_uid,   'PSN'),
    (@person_uid_2, 'PSN');

-- ------------------------------------------------------------
-- Person
-- ------------------------------------------------------------
INSERT INTO nbs_odse.dbo.Person
(person_uid, add_time, add_user_id, last_chg_time, last_chg_user_id,
 cd, cd_desc_txt, first_nm, last_nm, middle_nm,
 record_status_cd, record_status_time,
 status_cd, status_time,
 local_id, version_ctrl_nbr, electronic_ind,
 person_parent_uid)
VALUES
    (@person_uid,   '2024-01-15 09:00:00', @add_user_id, '2024-01-15 10:00:00', @add_user_id,
     'PRV', 'Provider', 'Jane', 'Doe', 'A',
     'ACTIVE', '2024-01-15 09:00:00',
     'A', '2024-01-15 09:00:00',
     'PRV-TEST-' + CAST(@person_uid AS VARCHAR), 1, 'Y',
     @person_uid),
    (@person_uid_2, '2024-02-01 09:00:00', @add_user_id, '2024-02-01 10:00:00', @add_user_id,
     'PRV', 'Provider', 'James', 'Smith', 'B',
     'ACTIVE', '2024-02-01 09:00:00',
     'A', '2024-02-01 09:00:00',
     'PRV-TEST-' + CAST(@person_uid_2 AS VARCHAR), 1, 'Y',
     @person_uid_2);

-- ------------------------------------------------------------
-- Person name
-- ------------------------------------------------------------
INSERT INTO nbs_odse.dbo.Person_name
(person_uid, person_name_seq, first_nm, last_nm, middle_nm,
 nm_use_cd, nm_prefix, nm_suffix, nm_degree,
 record_status_cd, record_status_time,
 status_cd, status_time, last_chg_time)
VALUES
    (@person_uid,   1, 'Jane',  'Doe',   'A', 'L', 'Dr', 'MD', 'MD',
     'ACTIVE', '2024-01-15 09:00:00', 'A', '2024-01-15 09:00:00', '2024-01-15 09:00:00'),
    (@person_uid_2, 1, 'James', 'Smith', 'B', 'L', NULL, NULL,  'MD',
     'ACTIVE', '2024-02-01 09:00:00', 'A', '2024-02-01 09:00:00', '2024-02-01 09:00:00');

-- ------------------------------------------------------------
-- Postal locator
-- ------------------------------------------------------------
INSERT INTO nbs_odse.dbo.Postal_locator
(postal_locator_uid, street_addr1, street_addr2, city_desc_txt,
 state_cd, zip_cd, cnty_cd, cntry_cd,
 record_status_cd, record_status_time)
VALUES
    (@postal_locator_uid,   '555 Provider Ave', 'Suite 100', 'Atlanta', '13', '30308', '13121', '840',
     'ACTIVE', '2024-01-15 09:00:00'),
    (@postal_locator_uid_2, '100 Test Blvd',    NULL,        'Atlanta', '13', '30301', '13121', '840',
     'ACTIVE', '2024-02-01 09:00:00');

-- ------------------------------------------------------------
-- Tele locator
-- ------------------------------------------------------------
INSERT INTO nbs_odse.dbo.Tele_locator
(tele_locator_uid, phone_nbr_txt, extension_txt, record_status_cd, record_status_time)
VALUES
    (@tele_locator_uid_ph,  '4045550500', '123', 'ACTIVE', '2024-01-15 09:00:00'),  -- P1 work phone
    (@tele_locator_uid_ph_2,'4045550600', NULL,  'ACTIVE', '2024-02-01 09:00:00'),  -- P2 work phone
    (@tele_locator_uid_cp_2,'4045550601', NULL,  'ACTIVE', '2024-02-01 09:00:00'),  -- P2 active cell
    (@tele_locator_uid_cp_3,'4045550602', NULL,  'ACTIVE', '2024-02-01 09:00:00');  -- P2 inactive cell (ELP inactive)

INSERT INTO nbs_odse.dbo.Tele_locator
(tele_locator_uid, email_address, record_status_cd, record_status_time)
VALUES
    (@tele_locator_uid_em,   'jane.doe@statelab.org',   'ACTIVE', '2024-01-15 09:00:00'),
    (@tele_locator_uid_em_2, 'james.smith@statelab.org','ACTIVE', '2024-02-01 09:00:00');

-- ------------------------------------------------------------
-- Entity locator participation
-- ------------------------------------------------------------
INSERT INTO nbs_odse.dbo.Entity_locator_participation
(entity_uid, locator_uid, class_cd, cd, use_cd,
 record_status_cd, record_status_time, status_cd, version_ctrl_nbr)
VALUES
    -- Provider 1
    (@person_uid, @postal_locator_uid,  'PST',  'O',  'WP', 'ACTIVE',   '2024-01-15 09:00:00', 'A', 1),
    (@person_uid, @tele_locator_uid_ph, 'TELE', 'PH', 'WP', 'ACTIVE',   '2024-01-15 09:00:00', 'A', 1),
    (@person_uid, @tele_locator_uid_em, 'TELE', 'O',  'WP', 'ACTIVE',   '2024-01-15 09:00:00', 'A', 1),
    -- Provider 2
    (@person_uid_2, @postal_locator_uid_2,  'PST',  'O',  'WP', 'ACTIVE',   '2024-02-01 09:00:00', 'A', 1),
    (@person_uid_2, @tele_locator_uid_ph_2, 'TELE', 'PH', 'WP', 'ACTIVE',   '2024-02-01 09:00:00', 'A', 1),
    (@person_uid_2, @tele_locator_uid_cp_2, 'TELE', 'CP', 'MC', 'ACTIVE',   '2024-02-01 09:00:00', 'A', 1),
    (@person_uid_2, @tele_locator_uid_cp_3, 'TELE', 'CP', 'MC', 'INACTIVE', '2024-02-01 09:00:00', 'I', 1),
    (@person_uid_2, @tele_locator_uid_em_2, 'TELE', 'O',  'WP', 'ACTIVE',   '2024-02-01 09:00:00', 'A', 1);

-- ------------------------------------------------------------
-- Entity ID
-- ------------------------------------------------------------
INSERT INTO nbs_odse.dbo.Entity_id
(entity_uid, entity_id_seq, type_cd, root_extension_txt,
 assigning_authority_cd, record_status_cd, record_status_time,
 status_cd, add_time)
VALUES
    (@person_uid,   1, 'NPI', '1234567890', 'CMS', 'ACTIVE', '2024-01-15 09:00:00', 'A', '2024-01-15 09:00:00'),
    (@person_uid_2, 1, 'NPI', '0987654321', 'CMS', 'ACTIVE', '2024-02-01 09:00:00', 'A', '2024-02-01 09:00:00');