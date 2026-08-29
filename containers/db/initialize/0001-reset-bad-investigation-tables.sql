---------------------------------------------------
-- This is temporary, some RDB tables in our
-- Golden Backups is in a bad state so we are going
-- to drop those tables early so RTR can rebuild.
----------------------------------------------------
USE RDB;

DROP TABLE IF EXISTS D_INVESTIGATION_REPEAT;
DROP TABLE IF EXISTS L_INVESTIGATION_REPEAT;
DROP TABLE IF EXISTS S_INVESTIGATION_REPEAT;

DROP TABLE IF EXISTS D_INVESTIGATION_REPEAT_INC;
DROP TABLE IF EXISTS L_INVESTIGATION_REPEAT_INC;
DROP TABLE IF EXISTS S_INVESTIGATION_REPEAT_INC;

GO
