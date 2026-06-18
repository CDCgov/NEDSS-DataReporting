-- =====================================================================
-- zz_zzz_phc_ui_normalization.sql
--
-- LAST-SORTING Tier-3 fixture. Normalizes synthetic public_health_case rows
-- so they present correctly in the classic NBS UI (which reads NBS_ODSE
-- directly, not the pipeline output). Runs after every PHC insert but before
-- the Tier-3 drain, so CDC also carries the changes into RDB_MODERN. Both
-- passes are scoped to synthetic PHCs (uid >= 20000000) and are idempotent.
--
-- PASS 1 — program_jurisdiction_oid (row-level-security / visibility gate).
--   The fixtures author program_jurisdiction_oid = public_health_case_uid (a
--   self-reference). The patient file's row-level-security filter rejects a
--   non-structured OID, so the investigation never renders even with
--   record_status_cd='OPEN' and a SubjOfPHC participation. RDB_MODERN
--   population is unaffected (the OID is a routing/security field, not a
--   compared coverage column), which is why these passed the comparison
--   harness yet stayed invisible.
--   NBS forms the OID as jurisdiction.nbs_uid * 100000 + program_area.nbs_uid.
--   Verified live: stock VPD/130006 = 13006*100000+10 = 1300600010 (renders);
--   TB/130001 = 13001*100000+14 = 1300100014 (renders). superuser (role
--   SUPERUSER) sees all valid OIDs regardless of its Auth_user_role pairs, so
--   the gate is OID validity, not a per-user jurisdiction match.
--   The program area is derived from the PHC's CONDITION
--   (NBS_SRTE.dbo.condition_code.prog_area_cd), not the PHC's prog_area_cd
--   column: some fixtures set prog_area_cd to values not in program_area_code
--   (COV/VAC/MAL), but the condition always resolves (COVID 11065 -> GCD,
--   Malaria 10130 -> GCD, Pertussis 10190 -> VPD). prog_area_cd is left
--   untouched to avoid shifting any prog_area-keyed RDB_MODERN coverage.
--
-- PASS 2 — investigation dates (UI "Start Date" / "Reported").
--   The full-chain fixtures set activity_from_time (which renders as the
--   investigation "Start Date") and rpt_to_county_time, but the zz_* datamart
--   fill/enrich PHCs leave them NULL, so the UI Start Date column is blank for
--   them. Fill the NULLs from add_time (start a couple days before the record
--   was added; reported on the add date) so every investigation shows a
--   sensible Start Date. Only touches NULLs.
-- =====================================================================

USE [NBS_ODSE];
GO

-- ----- PASS 1: program_jurisdiction_oid -----
UPDATE phc
SET phc.program_jurisdiction_oid = j.nbs_uid * 100000 + pa.nbs_uid
FROM dbo.public_health_case phc
JOIN NBS_SRTE.dbo.condition_code cc
       ON cc.condition_cd = phc.cd
JOIN NBS_SRTE.dbo.program_area_code pa
       ON pa.prog_area_cd = cc.prog_area_cd
JOIN NBS_SRTE.dbo.jurisdiction_code j
       ON j.code = phc.jurisdiction_cd
WHERE phc.public_health_case_uid >= 20000000
  AND phc.program_jurisdiction_oid = phc.public_health_case_uid;
GO

-- ----- PASS 2: investigation dates -----
UPDATE dbo.public_health_case
SET activity_from_time = COALESCE(activity_from_time, DATEADD(day, -2, add_time)),
    rpt_to_county_time = COALESCE(rpt_to_county_time, add_time)
WHERE public_health_case_uid >= 20000000
  AND (activity_from_time IS NULL OR rpt_to_county_time IS NULL);
GO

-- ----- PASS 3: prog_area_cd (classic investigation DETAIL view) -----
-- Some fixtures set prog_area_cd to values not in NBS_SRTE.program_area_code
-- (COV/VAC/MAL). The classic investigation detail resolves its form via
-- CommonAction.getInvestigationFormCd(condition, prog_area), which returns NULL
-- when (prog_area, condition) doesn't resolve -> "Null object to
-- DSInvestigationFormCd" Error page. Set the canonical program area from the
-- condition (NBS_SRTE.dbo.condition_code) so the detail page renders. Only
-- touches PHCs whose prog_area_cd is invalid; idempotent.
UPDATE phc
SET phc.prog_area_cd = cc.prog_area_cd
FROM dbo.public_health_case phc
JOIN NBS_SRTE.dbo.condition_code cc ON cc.condition_cd = phc.cd
WHERE phc.public_health_case_uid >= 20000000
  AND NOT EXISTS (SELECT 1 FROM NBS_SRTE.dbo.program_area_code pac
                  WHERE pac.prog_area_cd = phc.prog_area_cd);
GO
