-- =====================================================================
-- zz_zzz_phc_patient_redistribution.sql
--
-- LAST-SORTING Tier-3 fixture (runs after every SubjOfPHC link is authored,
-- before the Tier-3 drain so CDC carries the change into RDB_MODERN).
--
-- Problem: most synthetic investigations were linked (SubjOfPHC) to the single
-- foundation patient 20000000 because it has a complete D_PATIENT row. The
-- result is one patient owning ~23 investigations across every disease, which
-- is unrealistic and noisy in the classic NBS patient file.
--
-- Fix: spread the foundation patient's investigations round-robin across the
-- pool of fully-attributed patients (each has name, DOB, sex, race, address,
-- phone and a complete D_PATIENT), so each patient owns a handful. Only the
-- SubjOfPHC subject_entity_uid moves; exactly one SubjOfPHC per investigation
-- is preserved. The dedicated condition patients keep their own intentional
-- investigation (those are not linked to 20000000, so they are untouched) and
-- simply gain a few more. RDB_MODERN coverage is unaffected: the datamart SPs
-- derive PATIENT_KEY from this participation, so columns stay populated; only
-- which patient they resolve to changes (consistently on both RDB and
-- RDB_MODERN, since both read the same ODSE).
--
-- The foundation investigation 20000100 (jurisdiction '1', the deliberate
-- no-jurisdiction-match artifact) is left on the foundation patient.
--
-- Idempotent: guarded to fire only when the foundation patient is overloaded,
-- so re-running on an already-balanced DB is a no-op.
-- =====================================================================

USE [NBS_ODSE];
GO

IF (SELECT COUNT(*)
    FROM dbo.participation
    WHERE type_cd = 'SubjOfPHC'
      AND subject_entity_uid = 20000000
      AND act_uid >= 20000000
      AND act_uid <> 20000100) > 6
BEGIN
    ;WITH found_invs AS (
        SELECT act_uid,
               ROW_NUMBER() OVER (ORDER BY act_uid) AS rn
        FROM dbo.participation
        WHERE type_cd = 'SubjOfPHC'
          AND subject_entity_uid = 20000000
          AND act_uid >= 20000000
          AND act_uid <> 20000100          -- keep the no-match foundation inv here
    ),
    targets AS (
        SELECT uid, ROW_NUMBER() OVER (ORDER BY uid) - 1 AS idx
        FROM (VALUES (20000000),   -- Raymond Foster (foundation)
                     (20020010),   -- Diane Whitfield (v2)
                     (22015300),   -- Sandra Coleman
                     (22055000),   -- Carlos Vega
                     (22057000),   -- Marcus Harlow
                     (22058000),   -- Priya Ramanathan
                     (22063000),   -- Maria Contreras
                     (22073000)    -- Daniel Okafor
             ) v(uid)
    )
    UPDATE p
    SET p.subject_entity_uid = t.uid
    FROM dbo.participation p
    JOIN found_invs fi
           ON fi.act_uid = p.act_uid
    JOIN targets t
           ON t.idx = (fi.rn % 8)
    WHERE p.type_cd = 'SubjOfPHC'
      AND p.subject_entity_uid = 20000000
      AND p.act_uid >= 20000000
      AND p.act_uid <> 20000100
      AND t.uid <> 20000000;              -- rows mapped back to foundation stay put
END
GO
