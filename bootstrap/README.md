# Bootstrapping

These scripts must be run **manually, once** per environment before the RTR pipeline can operate. They are not managed by Liquibase and are not idempotent in the sense that they set up infrastructure (CDC, SQL Agent jobs) that persists independently of application deployments.

## Database Users

Running the RTR pipeline requires SQL Server login accounts for two distinct purposes: running the bootstrap scripts and schema migrations, and running the application services. Depending on your environment, these can be two separate accounts or collapsed into one.

### Accounts at a Glance (v7.13.0+)

| Account | Purpose | Databases | Key Permissions |
| :--- | :--- | :--- | :--- |
| **Admin account** (e.g. `rtr-admin`) | Liquibase migrations | `NBS_ODSE`, `NBS_SRTE`, `RDB / RDB_MODERN`  | All NBS DBs: `db_owner` |
| **Service account** (e.g. `rtr-service-user`) | Application services reading source data and writing to the reporting database | `NBS_ODSE`, `NBS_SRTE`, `RDB / RDB_MODERN` | ODSE/SRTE: `db_datareader`<br>RDB/RDB_MODERN: `db_owner` |

Two accounts cover everything: `rtr-admin` handles migrations, `rtr-service-user` runs the application. A single account with both sets of permissions also works if your environment doesn't require separation.

### Account Names Are Flexible

Unlike the older per-service model (v7.12.0 and prior), **account names in v7.13.0+ are not hardcoded** — name them whatever fits your environment conventions. Just make sure the application configuration (Helm charts, `application.yaml`) reflects the chosen names and credentials.

### Who Runs the Bootstrap Scripts

The bootstrap scripts in this directory (CDC enablement, SQL Agent job creation) require the admin account. Specifically:

- Scripts 1001 and 1002 call `sys.sp_cdc_enable_db` / `msdb.dbo.rds_cdc_enable_db` — requires `sysadmin` locally or `setupadmin` + CDC stored procedure execute rights on RDS.
- Script 1003 creates and attaches a SQL Server Agent job — requires `SQLAgentOperatorRole` on `msdb`.

---

## Bootstrap Scripts

### 1001 — Enable CDC on NBS_ODSE

Enables Change Data Capture at the database level on `NBS_ODSE` and then enables CDC tracking on each RTR-relevant table. Handles both AWS RDS (`rds_cdc_enable_db`) and standard SQL Server (`sp_cdc_enable_db`) automatically.

**Run against:** `NBS_ODSE`

### 1002 — Enable CDC on NBS_SRTE

Same as 1001 but targets `NBS_SRTE` and its reference-data tables.

**Run against:** `NBS_SRTE`

### 1003 — Create Event Metric Cleanup Job

Creates a SQL Server Agent job (`EventMetricCleanup`) that runs `sp_event_metric_cleanup_postprocessing` daily at midnight. Targets `rdb_modern` in UAT environments and `rdb` everywhere else. The script is safe to re-run — it drops and recreates the job and schedule if they already exist.

**Run against:** `msdb` (requires SQL Server Agent)

## Prerequisites

- SQL Server Agent must be running (for script 1003)
- The executing login must be the admin account described above
- Scripts 1001 and 1002 should be run before starting the Debezium connectors

## Order of Execution

Run in numeric order: **1001 → 1002 → 1003**
