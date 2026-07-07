-- ---------------------------------------------------------------------------
-- Add default rows for certain dimension tables.
-- ---------------------------------------------------------------------------
--
-- Several RTR stored procedures fall back to a key=1 surrogate when a fact
-- row cannot be matched to a real dimension row -- e.g.
--   COALESCE(D_PATIENT.PATIENT_KEY, 1) AS PATIENT_KEY
--   COALESCE(CONDITION.CONDITION_KEY, 1) AS CONDITION_KEY
--
-- The legacy MasterETL pipeline adds a key=1 row in each of
-- these dimensions via its SAS %assign_key macro, so the fallback resolves
-- to an existing row. RTR's create scripts (006-, 008-, 013-create_nrt_*)
-- *reserve* the IDENTITY slot at 1 by reseeding to MAX(*_KEY)+1, but they
-- do not INSERT a row at key=1. In a production migration to RTR the
-- MasterETL-populated RDB should already have these default rows.
-- However, in development or greenfield install no seed exists, and any
-- COALESCE(*, 1) fallback writes an FK pointing to a row that does not
-- exist -- a latent dangling-reference bug.
--
-- This script defensively INSERTs (KEY = 1, other columns NULL) for selected tables,
-- to avoid future problems due to the default row being missing.
-- The tables selected are those which seem most likely to cause problems
-- due frequent use of COALESCE(...,1).
-- Further tables can be added to this list if needed.
-- The script is idempotent and therefore safe to re-run.
-- ---------------------------------------------------------------------------


-- D_PROVIDER
IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'D_PROVIDER' AND xtype = 'U')
   AND NOT EXISTS (SELECT 1 FROM dbo.D_PROVIDER WHERE PROVIDER_KEY = 1)
BEGIN
    INSERT INTO dbo.D_PROVIDER (PROVIDER_KEY) VALUES (1);
END
GO

-- D_ORGANIZATION
IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'D_ORGANIZATION' AND xtype = 'U')
   AND NOT EXISTS (SELECT 1 FROM dbo.D_ORGANIZATION WHERE ORGANIZATION_KEY = 1)
BEGIN
    INSERT INTO dbo.D_ORGANIZATION (ORGANIZATION_KEY) VALUES (1);
END
GO

-- D_PATIENT
IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'D_PATIENT' AND xtype = 'U')
   AND NOT EXISTS (SELECT 1 FROM dbo.D_PATIENT WHERE PATIENT_KEY = 1)
BEGIN
    INSERT INTO dbo.D_PATIENT (PATIENT_KEY) VALUES (1);
END
GO

-- CONDITION
IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'CONDITION' AND xtype = 'U')
   AND NOT EXISTS (SELECT 1 FROM dbo.CONDITION WHERE CONDITION_KEY = 1)
BEGIN
    INSERT INTO dbo.CONDITION (CONDITION_KEY) VALUES (1);
END
GO

-- NOTIFICATION
IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'NOTIFICATION' AND xtype = 'U')
   AND NOT EXISTS (SELECT 1 FROM dbo.NOTIFICATION WHERE NOTIFICATION_KEY = 1)
BEGIN
    INSERT INTO dbo.NOTIFICATION (NOTIFICATION_KEY) VALUES (1);
END
GO

-- GEOCODING_LOCATION
IF EXISTS (SELECT 1 FROM sysobjects WHERE name = 'GEOCODING_LOCATION' AND xtype = 'U')
   AND NOT EXISTS (SELECT 1 FROM dbo.GEOCODING_LOCATION WHERE GEOCODING_LOCATION_KEY = 1)
BEGIN
    INSERT INTO dbo.GEOCODING_LOCATION (GEOCODING_LOCATION_KEY) VALUES (1);
END
GO
