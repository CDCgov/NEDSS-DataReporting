# Database Upgrade Script

## Overview

The `upgrade_db` scripts (`upgrade_db.bat` for Windows and `upgrade_db.sh` for Linux) are designed to execute SQL scripts to upgrade the RDB_MODERN database . The scripts process `.sql` files in the script's directory and specific subdirectories (`tables`, `views`, `functions`, `routines`, `remove`, and optionally `data_load`). Execution details, including errors, are logged to `upgrade_db_execution.log`. 

The `upgrade_db` scripts do not requires modifications, unless the subdirectories names are modified or more subdirectories are added.

Both, (Windows and Linux) scripts support the same functionality:
- Accept required parameters: `server`, `database`, `user`, `password`.
- Support help flags (`/h`, `-h`, `--help`) and an optional `--load-data` flag to include scripts in the `data_load` folder.
- Allow flexible positioning of the `--load-data` flag only for Linux version. In Windows version it must be the first parameter.
- Execute `.sql` files and report success or failure.

### SQL Scripts
- To add more SQL scripts to the upgrade process, add them to the corresponding subdirectory taking into account the required execution order managed by the script name.
- To modify tables, add "ALTER TABLE" statements on the corresponding table script or add a new script after the table creation script.
- Views, Functions, and Stored Pocedures SQL scrips are designed to drop and recreate the corresponding element.

## **MANDATORY POST-UPGRADE STEP: Microservice Permissions**

CRITICAL: After running the upgrade_db script, you MUST execute the microservice permission script to ensure all service users have proper database access.

### Why This Step Is Required

When stored procedures are dropped and recreated during upgrades, database permissions are lost. All microservices require specific permissions to function properly.

### Execute Permission Script

After the upgrade_db script completes successfully, run:

# Location: routines/001-service_users_login_creation.sql
sqlcmd -S [SERVER] -d [DATABASE] -U [USER] -P [PASSWORD] -i "routines/001-service_users_login_creation.sql"

Example:

sqlcmd -S myserver -d rdb_modern -U admin_user -P mypassword -i "routines/001-service_users_login_creation.sql"

### Validate Permissions

After running the permission script, validate that all microservice users are properly configured:

-- ==========================================
-- MICROSERVICE PERMISSIONS VALIDATION
-- ==========================================
-- Quick validation to verify all service users are properly configured

PRINT 'Validating microservice permissions...';
PRINT '';

-- Check all server logins exist
SELECT
CASE WHEN COUNT(*) = 8
THEN '✓ All 8 server logins exist'
ELSE '✗ Missing server logins: ' + CAST((8 - COUNT(*)) AS VARCHAR(2))
END as Server_Logins_Status
FROM sys.server_principals
WHERE name IN (
'debezium_service_rdb',
'kafka_sync_connector_service_rdb',
'post_processing_service_rdb',
'ldf_service_rdb',
'investigation_service_rdb',
'person_service_rdb',
'observation_service_rdb',
'organization_service_rdb'
);

-- Check users across all databases
PRINT 'Checking database users across all databases...';

-- NBS_ODSE users (6 services: all except Kafka and postprocessing)
EXEC('USE [NBS_ODSE];
SELECT ''NBS_ODSE'' as Database_Name, COUNT(*) as User_Count,
CASE WHEN COUNT(*) = 6 THEN ''✓ Expected count'' ELSE ''✗ Wrong count'' END as Status
FROM sys.database_principals
WHERE name LIKE ''%_service_rdb''');

-- NBS_SRTE users (7 services: all except Kafka)
EXEC('USE [NBS_SRTE];
SELECT ''NBS_SRTE'' as Database_Name, COUNT(*) as User_Count,
CASE WHEN COUNT(*) = 7 THEN ''✓ Expected count'' ELSE ''✗ Wrong count'' END as Status
FROM sys.database_principals
WHERE name LIKE ''%_service_rdb''');

-- rdb_modern users (7 services: all except Debezium)
USE [rdb_modern];
SELECT 'rdb_modern' as Database_Name, COUNT(*) as User_Count,
CASE WHEN COUNT(*) = 7 THEN '✓ Expected count' ELSE '✗ Wrong count' END as Status
FROM sys.database_principals
WHERE name LIKE '%_service_rdb';

-- Check role memberships in rdb_modern (should only be 3 services)
PRINT '';
PRINT 'Role memberships in rdb_modern (should only be 3 services):';

SELECT
'rdb_modern' as Database_Name,
mp.name as Service_User,
STRING_AGG(rp.name, ', ') as Roles_Granted
FROM sys.database_role_members rm
JOIN sys.database_principals rp ON rm.role_principal_id = rp.principal_id
JOIN sys.database_principals mp ON rm.member_principal_id = mp.principal_id
WHERE mp.name LIKE '%_service_rdb'
GROUP BY mp.name
ORDER BY mp.name;

-- Count role memberships
SELECT
'Role Members Count' as Check_Type,
COUNT(DISTINCT mp.name) as Actual_Count,
CASE WHEN COUNT(DISTINCT mp.name) = 3
THEN '✓ Expected 3 services with roles'
ELSE '✗ Wrong count - should be 3'
END as Status
FROM sys.database_role_members rm
JOIN sys.database_principals mp ON rm.member_principal_id = mp.principal_id
WHERE mp.name LIKE '%_service_rdb';

PRINT 'Validation completed. Review results above.';

### Expected Validation Results

✅ All 8 server logins exist
✅ NBS_ODSE: 6 users (all except Kafka and postprocessing)
✅ NBS_SRTE: 7 users (all except Kafka)
✅ rdb_modern: 7 users (all except Debezium)
✅ Role Members Count: 3 services (Investigation, Post Processing, Kafka only)

### Expected Role Memberships in rdb_modern:

- Investigation: db_datareader, db_datawriter
- Post Processing: db_owner
- Kafka: db_datareader, db_datawriter

### Services WITHOUT role memberships (table-level permissions only):

- Organization, Observation, Person, LDF: Only INSERT ON job_flow_log

### Troubleshooting Permission Issues

If validation fails:

- Missing server logins: Re-run the permission script
- Wrong user counts:
  NBS_ODSE should have 6 users (all except Kafka and postprocessing)
  NBS_SRTE should have 7 users (all except Kafka)
  rdb_modern should have 7 users (all except Debezium)
- Wrong role membership count: Only 3 services should have roles in rdb_modern
- Unexpected role memberships: Organization, Observation, Person, LDF should NOT have any role memberships - only table-level INSERT permissions
- Security Issue: If Organization/Observation/Person/LDF services show role memberships (especially db_owner), this is a security problem - remove these roles immediately

## Microservice Permission Summary

Service	                          Databases	                                 Permissions	                                                    
Organization	                  NBS_ODSE, NBS_SRTE, rdb_modern	         db_datareader + sp_organization_event + job_flow_log INSERT	    
Observation	                      NBS_ODSE, NBS_SRTE, rdb_modern	         db_datareader + 2 SPs + job_flow_log INSERT	
Person	                          NBS_ODSE, NBS_SRTE, rdb_modern	         db_datareader + 4 SPs + job_flow_log INSERT	
Investigation	                  NBS_ODSE, NBS_SRTE, rdb_modern	         db_datawriter on ODSE + full READ/WRITE on rdb_modern	
LDF	                              NBS_ODSE, NBS_SRTE, rdb_modern	         db_datareader + 7 SPs + job_flow_log INSERT	
Post Processing	                  rdb, rdb_modern, NBS_SRTE	                 db_owner on rdb/rdb_modern + db_datareader on SRTE	
Kafka Sync	                      rdb_modern	                             db_datareader + db_datawriter (full READ/WRITE)	
Debezium	                      NBS_ODSE, NBS_SRTE	                     db_datareader only	

### Stored Procedures by Service
## Organization Service:
- sp_organization_event
## Observation Service:
- sp_observation_event
- sp_place_event
## Person Service:
- sp_patient_event
- sp_patient_race_event
- sp_provider_event
- sp_auth_user_event
## Investigation Service:
- sp_investigation_event
- sp_contact_record_event
- sp_interview_event
- sp_notification_event
- sp_treatment_event
- sp_vaccination_event
- sp_public_health_case_fact_datamart_event
## LDF Service:
- sp_ldf_data_event
- sp_ldf_patient_event
- sp_ldf_provider_event
- sp_ldf_organization_event
- sp_ldf_observation_event
- sp_ldf_phc_event
- sp_ldf_intervention_event
## Post Processing, Kafka Sync, Debezium Services:
- No specific stored procedures (use role-based permissions for direct table access)

## Pre-requisites
- **Database**: RDB_MODEN database without `nrt_afaik` tables the first time the script is executed.

## Requirements

### Common Requirements
- **Database**: SQL Server 2016 or higher.
- **Database Client**: Microsoft SQL Server `sqlcmd`.
- **Permissions**: The database user must have permissions to create and delete objects in the specified database.
- **Directory Structure**: The script expects `.sql` files in its directory and optional subdirectories: `tables`, `views`, `functions`, `routines`, `remove`, and `data_load`. Folder names are case-sensitive on Linux.

### Windows-Specific Requirements
- **Operating System**: Windows (e.g., Windows 10, Windows Server).
- **Database Client**: `sqlcmd` is typically included with SQL Server or can be installed via Microsoft SQL Server tools.

### Linux-Specific Requirements
- **Operating System**: Linux (e.g., Ubuntu, CentOS).
- **Database Client**: Install `mssql-tools` or `msodbcsql18` for `sqlcmd` (e.g., `sudo apt-get install mssql-tools` on Ubuntu). 
- **NOTE**: `mssql-tools` or `msodbcsql18` is not supported by all Ubuntu versions. Last supported version is Ubuntu 18.04 
- **Permissions**: The script must be executable (`chmod +x upgrade_db.sh`).

## Usage

Run the script from the command line with the required parameters and optional flags.

### Windows
```cmd
upgrade_db.bat [options] server database user password
```

### Linux
```bash
./upgrade_db.sh [options] server database user password
```

### Parameters
- `server`: Server name or IP address of the SQL Server instance.
- `database`: Database name (usually `RDB_MODERN`).
- `user`: Database user name with permissions to create/delete objects.
- `password`: Database user password.

### Options
- `/h`, `-h`, `--help`: Display the help message and exit.
- `--load-data`: Include scripts in the `data_load` folder (default: excluded).

### Examples

#### Windows
1. **Basic Execution** (excludes `data_load` folder):
   ```cmd
   upgrade_db.bat server_name rdb_modern my_user my_password
   ```
2. **Include `data_load` Scripts**:
   ```cmd
   upgrade_db.bat --load-data server_name rdb_modern my_user my_password
   ```
3. **Display Help**:
   ```cmd
   upgrade_db.bat --help | -h | /h
   ```
   
#### Linux
1. **Basic Execution** (excludes `data_load` folder):
   ```bash
   ./upgrade_db.sh server_name rdb_modern my_user my_password
   ```
2. **Include `data_load` Scripts**:
   ```bash
   ./upgrade_db.sh --load-data server_name rdb_modern my_user my_password
   ```
3. **Flexible Flag Positioning**:
   ```bash
   ./upgrade_db.sh --load-data server_name rdb_modern my_user my_password 
    ```
   ```bash
   ./upgrade_db.sh server_name rdb_modern my_user my_password --load-data
   ```
4. **Display Help**:
   ```bash
   ./upgrade_db.sh --help | -h | /h
   ```
   
## Complete Deployment Process

### Recommended Deployment Steps

1.Execute upgrade_db script (as documented above)
2.⚠️ MANDATORY: Run permission script (see "MANDATORY POST-UPGRADE STEP" section)
3.Validate permissions (run validation query)
4.Test microservice connectivity (optional but recommended)

### Example Complete Deployment

# Step 1: Run database upgrade
./upgrade_db.sh myserver rdb_modern admin_user mypassword

# Step 2: MANDATORY - Restore microservice permissions
sqlcmd -S myserver -d rdb_modern -U admin_user -P mypassword -i "routines/001-service_users_login_creation.sql"

# Step 3: Validate (copy validation SQL above into a file and run it)
sqlcmd -S myserver -d rdb_modern -U admin_user -P mypassword -i "validate_permissions.sql"

## Output
- **Log File**: Execution details, including errors, are logged to `upgrade_db_execution.log` in the script's directory.
- **Console Output**: Displays progress, errors, and a summary of execution (success or failure count).
- **Exit Codes**:
  - `0`: Successful execution.
  - `1`: Error (e.g., missing parameters, directory not found, or script execution failures).

## Notes
- **Database Client**: Both scripts use `sqlcmd` for SQL Server. 
- **Password Security**: Avoid special characters in passwords or quote them properly (e.g., `"my$password"` on Windows, `'my$password'` on Linux). Alternatively, use environment variables:
  - Windows: `set DB_PASS=my$password & upgrade_db.bat server_name rdb_modern my_user %DB_PASS%`
  - Linux: `export DB_PASS="my$password"; ./upgrade_db.sh server_name rdb_modern my_user "$DB_PASS"`
- **Case Sensitivity**: Folder names and file extensions (`.sql`) are case-sensitive on Linux but not on Windows.
- **Error Handling**: The scripts stop executing subdirectory scripts if any `.sql` file in the main directory fails. Failed scripts are listed in the log and console output.
- **SQL Scripts**: Scripts are executed from current directory and subdirectories (`tables`, `views`, `functions`, `routines`, `remove`, and optionally `data_load`). Inside each subdirectory, scripts are execuetd by alphabetical order. To solve script dependencies just reorder scripts in the subdirectory.

## Troubleshooting
- **sqlcmd not found**:
  - Windows: Ensure SQL Server or its tools are installed.
  - Linux: Install `mssql-tools` or `msodbcsql18` (see Microsoft documentation for Linux).
- **Permission Denied (Linux)**: Run `chmod +x upgrade_db.sh` to make the script executable.
- **Invalid Parameters**: Use `--help` to check the correct syntax.
- **No .sql Files**: Ensure `.sql` files exist in the script's directory or subdirectories.
- **Case Sensitivity (Linux)**: Verify folder names (`tables`, `data_load`, etc.) and file extensions (`.sql`) match exactly.
- Microservice Connection Issues: First run the permission validation query to ensure all users and roles are properly configured.

