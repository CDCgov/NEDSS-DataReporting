<h1 align="center">Real Time Reporting – Database Upgrades</h1>

<p align="center">
A comprehensive collection of database objects required for implementation of real-time reporting.
</p>

---

## Getting Started

### Onboarding Steps

The onboarding process involves a combination of manual and automated steps. Follow the sequence below to prepare the environment:

#### 1. Create Admin and Service Users (Manual Only)
Run the scripts located in the following directories manually. This step creates an admin user and individual service users:

- `001-master/01_onboarding_scripts_user_creation/`

These scripts set up core roles and foundational database functions.

#### 2. Deploy Database Objects (Liquibase or Manual)

For each database (`001-master`,`002-srte`, `003-odse`, `004-rdb`, `005-rdb_modern`), deploy the following object types:

- `tables/`
- `views/`
- `functions/`
- `routines/`
- `jobs/`
- `remove/`

These objects can be deployed via:

- **Liquibase**: For automated rollout. Changelog are provided to execute scripts in required order.
- **Manual Execution**: For environments without Liquibase. Scripts are provided to create and update necessary objects. 

Future enhancements will be delivered under this section. 

#### 3. Load Data and Start CDC (Manual or Batch Script)

After all objects have been successfully deployed, run the following scripts to complete database setup.

- `001-master/02_onboarding_script_data_load/`

This loads key-uid mapping onto key tables for RTR and activates **Change Data Capture** for required tables in NBS_ODSE and NBS_SRTE.

> This can be automated via a **batch script** with the `--load-data` flag for the master database schema.  
> Note: Liquibase does **not** support this step directly.

---

### Script Execution

Choose your preferred deployment method below:

---

### Option 1:  Liquibase Deployment 

Automated deployment using Liquibase ensures consistent and traceable changes to your database schema.

📄 [Liquibase Deployment Documentation](liquibase-service/src/main/resources/db/readme.md)

---

### Option 2: Manual Deployment

Manual deployment allows for more granular control and is suitable for environments without Liquibase.

📄 [Manual Deployment Documentation](liquibase-service/src/main/resources/stlt/manual_deployment/readme.md)

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
│           │   │   ├── jobs/
│           │   │   ├── remove/
│           │   │   ├── routines/
│           │   │   ├── tables/
│           │   │   ├── views/
│           ├── stlt/
│           │   ├── manual_deployment/
│           │   ├── permissions_validation/
├── readme.md
