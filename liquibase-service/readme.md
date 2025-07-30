<h1 align="center">Real Time Reporting – Database Upgrades</h1>

<p align="center">
A comprehensive collection of database objects required for implementation of real-time reporting.
</p>

---

## Getting Started

### Onboarding Steps

The onboarding process involves a combination of manual and automated steps. Required scripts are located under the `liquibase-service/src/main/resources/db` directory. 

Follow the sequence below to prepare the environment:

---

#### 1. Onboarding: Create Admin and Service Users (Manual Only)
Run the three scripts located under the following directory manually. This creates the admin user and individual service users with necessary permissions to create required database objects.

- [01_onboarding_scripts_user_creation](src/main/resources/db/001-master/01_onboarding_scripts_user_creation)

---
#### 2. Deploy Database Objects (Liquibase or Manual)

For each database ([001-master](src/main/resources/db/001-master),[002-srte](src/main/resources/db/002-srte), [003-odse](src/main/resources/db/003-odse), [004-rdb](src/main/resources/db/004-rdb), [005-rdb_modern](src/main/resources/db/005-rdb_modern)), deploy the following object types:

- `tables/`
- `views/`
- `functions/`
- `routines/`
- `remove/`

These objects can be deployed via:

- **Liquibase**: For automated rollout. Changelog are provided to execute scripts in required order.
- **Manual Execution**: For environments without Liquibase. Scripts are provided to create and update necessary objects.

Please note:
- [01_onboarding_scripts_user_creation](src/main/resources/db/001-master/01_onboarding_scripts_user_creation) and [02_onboarding_script_data_load](src/main/resources/db/001-master/02_onboarding_script_data_load) under the `001-master` folder are one time scripts intended to be run manually.
- The final script under `routines/999-<database_name>_database_object_permission_grants-001.sql` provides object level permissions and grants required for each service user. Please validate logs confirming successful execution of script. They can be validated using queries under [permissions_validation](src/main/resources/stlt/permissions_validation).

Future enhancements will be delivered under this section.

#### Option 1:  Liquibase Deployment

Automated deployment using Liquibase ensures consistent and traceable changes to your database schema. Please reference the [NEDSS-Helm](https://github.com/CDCgov/NEDSS-Helm) repository for required charts. 

- [Liquibase Deployment](https://github.com/CDCgov/NEDSS-Helm/tree/main/charts/liquibase)
  - Reporting Database:
      - RDB: If RDB is selected as the default reporting database, please ensure that scripts for [db.rdb_modern.changelog-16.1.yaml](changelog/db.rdb_modern.changelog-16.1.yaml) are run against the `RDB` database server.
      - RDB_MODERN: If RDB_MODERN is selected as the reporting database, please run both scripts under [db.rdb.changelog-16.1.yaml](changelog/db.rdb.changelog-16.1.yaml) with the `RDB` server_name and [db.rdb_modern.changelog-16.1.yaml](changelog/db.rdb_modern.changelog-16.1.yaml) with `RDB_MODERN` server_name.

    ```sql
    --Last script executed should be 999-<database_name>_database_object_permission_grants-001.sql.
    USE NBS_ODSE;
    SELECT TOP 1 *
    FROM NBS_ODSE.DBO.DATABASECHANGELOG
    ORDER BY DATEEXECUTED DESC;
    
    USE NBS_SRTE;
    SELECT TOP 1 *
    FROM NBS_SRTE.DBO.DATABASECHANGELOG
    ORDER BY DATEEXECUTED DESC;
    
    USE RDB;
    SELECT TOP 1 *
    FROM RDB.DBO.DATABASECHANGELOG
    ORDER BY DATEEXECUTED DESC;
    
    USE RDB_MODERN;
    SELECT TOP 1 *
    FROM RDB_MODERN.DBO.DATABASECHANGELOG
    ORDER BY DATEEXECUTED DESC;
    
    ```
#### Option 2: Manual Deployment

Manual deployment allows for more granular control and is suitable for environments without Liquibase.

- [Manual Deployment Documentation](liquibase-service/src/main/resources/stlt/manual_deployment/readme.md)

---
#### 3. Onboarding: Load Data and Start CDC (Manual or Batch Script)

After all objects have been successfully deployed, run the following scripts to complete database setup.

- [02_onboarding_script_data_load](src/main/resources/db/001-master/02_onboarding_script_data_load)

This loads key-uid mapping onto key tables for RTR and activates **Change Data Capture** for required tables in NBS_ODSE and NBS_SRTE.

> This can be automated via a **batch script** with the `--load-data` flag for the master database schema.  
> Note: Liquibase does **not** support this step directly.

---



## Project Tree

```bash
liquibase-service/
├── src/
│   └── main/
│       └── resources/
│           ├── db/
│           │   ├── 001-master/
│           │   │   ├── 01_onboarding_scripts_user_creation/
│           │   │   ├── 02_onboarding_script_data_load/
│           │   │   ├── functions/
│           │   ├── 002-srte/
│           │   │   ├── routines/
│           │   │   ├── tables/
│           │   ├── 003-odse/
│           │   │   ├── functions/
│           │   │   ├── routines/
│           │   │   ├── views/
│           │   ├── 004-rdb/
│           │   │   ├── routines/
│           │   │   ├── tables/
│           │   ├── 005-rdb_modern/
│           │   │   ├── functions/
│           │   │   ├── remove/
│           │   │   ├── routines/
│           │   │   ├── tables/
│           │   │   ├── views/
│           ├── stlt/
│           │   ├── manual_deployment/
│           │   ├── permissions_validation/
├── readme.md

