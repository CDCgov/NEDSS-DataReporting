-- =====================================================================
-- zz_zzz_phc_program_jurisdiction_oid.sql
--
-- UI-VISIBILITY NORMALIZATION (runs last in Tier 3, before the Tier-3 drain).
--
-- Problem: the synthetic investigation fixtures author
-- public_health_case.program_jurisdiction_oid = public_health_case_uid
-- (a self-reference). The classic NBS patient file applies a row-level
-- security filter on program_jurisdiction_oid, so a self-referencing /
-- non-structured OID hides the investigation in the UI even when
-- record_status_cd='OPEN' and a SubjOfPHC participation exist. RDB_MODERN
-- population is unaffected (the OID is a routing/security field, not a
-- compared coverage column), which is why these investigations passed the
-- comparison harness yet never rendered under their patient.
--
-- Fix: set a valid structured OID. NBS forms it as
--   jurisdiction.nbs_uid * 100000 + program_area.nbs_uid
-- Verified live (2026-06-17): stock VPD/130006 = 13006*100000+10 =
-- 1300600010 (renders); TB/130001 = 13001*100000+14 = 1300100014 (renders).
-- superuser (role SUPERUSER) sees all valid OIDs regardless of its
-- Auth_user_role pairs, so the gate is OID validity, not a per-user match.
--
-- The program area is derived from the PHC's CONDITION
-- (NBS_SRTE.dbo.condition_code.prog_area_cd), not the PHC's own
-- prog_area_cd column. Some fixtures set prog_area_cd to values that are not
-- in program_area_code (COV/VAC/MAL); the condition always resolves
-- (COVID 11065 -> GCD, Malaria 10130 -> GCD, Pertussis 10190 -> VPD). We do
-- NOT touch prog_area_cd here, to avoid shifting any prog_area-keyed
-- RDB_MODERN coverage; only program_jurisdiction_oid changes.
--
-- Scope: synthetic PHCs only (uid >= 20000000) that still carry the
-- self-referencing OID. Idempotent: re-running is a no-op once corrected.
--
-- Ordering: named to sort LAST in 30_sp_coverage so every PHC insert (incl.
-- the datamart-fill zz_* files) has already run. It runs before the Tier-3
-- drain, so CDC captures the public_health_case update and the pipeline
-- carries the corrected OID into RDB_MODERN as well.
-- =====================================================================

USE [NBS_ODSE];
GO

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
