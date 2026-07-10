# Bootstrapping

These scripts must be run **manually, once** per environment before the RTR pipeline can operate. They are not managed by Liquibase and are not idempotent in the sense that they set up infrastructure (CDC, SQL Agent jobs) that persists independently of application deployments.

## Database User

Running the RTR pipeline requires a SQL Server login account for two distinct purposes: configuring the database and running the application services. 

### Account Permissions (v7.13.0+)

1. **Name**: Any name works, but we recommend using a name descriptive to the role, such as `rtr-service-user`.
1. **Purpose**: The application services reading source database and writing to the reporting database.
1. **Databases Permissions**:
  - `NBS_ODSE`: `db_datareader`
  - `NBS_SRTE`: `db_datareader`
  - `RDB` / `RDB_MODERN`: `db_owner`

### Who Runs the Bootstrap Scripts

The bootstrap script in this directory (CDC enablement, SQL Agent job creation) require the admin account. Specifically:

- Script 101 checks for `sysadmin` and then calls `sys.sp_cdc_enable_db` / `msdb.dbo.rds_cdc_enable_db` — requires `sysadmin` locally or `setupadmin` + CDC stored procedure execute rights on RDS.

---

## Bootstrap Scripts

### 101 — Enable CDC on NBS_ODSE + NBS_SRTE

**File:** `101-enable_cdc_on_odse_srte_databases-001.sql`

Enables Change Data Capture at the database level on `NBS_ODSE` and `NBS_SRTE`, then enables CDC tracking on each RTR-relevant table. Handles both AWS RDS (`rds_cdc_enable_db`) and standard SQL Server (`sp_cdc_enable_db`) automatically.

**Run against:** `NBS_ODSE` and `NBS_SRTE`

## Prerequisites

- The executing login must be the admin account described above
- Script 101 should be run before starting the reporting-pipeline-service
