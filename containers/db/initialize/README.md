# docker-entrypoint-initdb.d

These scripts are executed automatically by the `nbs-mssql` container on startup, in filename sort order. They are organized into three numbered buckets.

## Buckets

### 001–006 — Dev/CI Setup

Custom scripts that prepare the SQL Server instance for local development and CI. These run first and establish the baseline database state that everything else depends on.

| File | Purpose |
| :--- | :--- |
| `001-restore-modern.sql` | Restores the RDB_MODERN database |
| `002-initialize-rdb-modern.sql` | Initializes RDB_MODERN schema |
| `003-fix-database-ownership.sql` | Corrects database ownership settings |
| `004-fix-lab-test.sql` | Fixes lab test data |
| `005-prep-for-masterEtl-trace.sql` | Prepares trace settings for MasterETL |
| `006-clear-job_flow_log.sql` | Clears the job flow log table |

### 098–099 — User Accounts

Creates the SQL Server logins and database users required by the application and migrations.

| File | Purpose |
| :--- | :--- |
| `098-rtr-admin.sql` | Creates the `rtr-admin` migration account |
| `099-rtr-service-user.sql` | Creates the `rtr-service-user` application account |

### 101–103 — Bootstrap

One-time scripts that enable CDC and create the SQL Server Agent cleanup job. These are the same scripts in the [`/bootstrap`](/bootstrap) directory at the repo root, where they are documented in detail. Unlike the scripts above, these are not specific to local dev — they must also be run manually in every environment (staging, production) before the RTR pipeline can operate.

| File | Purpose |
| :--- | :--- |
| `101-enable_cdc_on_odse_database-001.sql` | Enables CDC on `NBS_ODSE` and its tracked tables |
| `102-enable_cdc_on_srte_database-001.sql` | Enables CDC on `NBS_SRTE` and its tracked tables |
| `103-create_event_metric_cleanup_job-001.sql` | Creates the `EventMetricCleanup` SQL Agent job |

## Adding New Scripts

Place new scripts in the appropriate bucket range and leave a gap for future insertions (e.g. use `010`, `020` rather than filling every number). Scripts outside the `101–103` range are only executed by the local dev container — if a script needs to run in all environments, it belongs in `/bootstrap`.
