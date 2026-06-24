# docker-entrypoint-initdb.d

These scripts are executed automatically by the `nbs-mssql` container on startup, in filename sort order. They are organized into three numbered buckets.

## Buckets

### 001–005 — Dev/CI Setup

Custom scripts that prepare the SQL Server instance for local development and CI. These run first and establish the baseline database state that everything else depends on.

| File | Purpose |
| :--- | :--- |
| `001-restore-modern.sql` | Restores the RDB_MODERN database |
| `002-fix-database-ownership.sql` | Corrects database ownership settings |
| `003-fix-lab-test.sql` | Fixes lab test data |
| `004-prep-for-masterEtl-trace.sql` | Prepares trace settings for MasterETL |
| `005-clear-job_flow_log.sql` | Clears the job flow log table |

# 099 — User Account

Creates the SQL Server logins and database users required by the application and testing harnesses.

| File | Purpose |
| :--- | :--- |
| `099-rtr-service-user.sql` | Creates the `rtr-service-user` application account |

