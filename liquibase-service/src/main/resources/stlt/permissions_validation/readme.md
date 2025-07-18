# Microservice Permissions Validation

## Overview

This document provides comprehensive validation and troubleshooting procedures for microservice database permissions after running database upgrade scripts or Liquibase deployments.

### When to Use This Guide
- After executing `upgrade_db` scripts
- After Liquibase database deployments
- When microservices experience database connectivity issues
- For routine permission auditing

## Why Permission Validation is Critical

When database objects (stored procedures, functions, views) are dropped and recreated during deployments, **all database permissions are lost**. Each microservice requires specific database access to function properly.

### Impact of Missing Permissions
- Microservice startup failures
- Runtime database access errors
- Data processing interruptions
- Service degradation

## Permission Restoration Process

### Step 1: Execute Permission Script

After any database deployment, run the microservice permission script:

```bash
sqlcmd -S [SERVER] -d [DATABASE] -U [USER] -P [PASSWORD] -i "routines/001-service_users_login_creation.sql"
```

#### Example
```bash
sqlcmd -S myserver -d rdb_modern -U admin_user -P mypassword -i "routines/001-service_users_login_creation.sql"
```

### Step 2: Validate Permissions

Run the comprehensive validation script below to verify all permissions are correctly configured.

## Comprehensive Validation Script

```sql
-- ==========================================
-- MICROSERVICE PERMISSIONS VALIDATION
-- ==========================================
-- Comprehensive validation for all service users and permissions

PRINT 'Validating microservice permissions...';
PRINT '';

-- ==========================================
-- 1. SERVER LOGINS VALIDATION
-- ==========================================
PRINT '1. Checking server logins...';

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

-- ==========================================
-- 2. DATABASE USERS VALIDATION
-- ==========================================
PRINT '';
PRINT '2. Checking database users across all databases...';

-- NBS_ODSE users (6 services: all except Kafka and Post Processing)
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

-- ==========================================
-- 3. ROLE MEMBERSHIPS VALIDATION
-- ==========================================
PRINT '';
PRINT '3. Checking role memberships in rdb_modern (should only be 3 services):';

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

PRINT '';
PRINT 'Validation completed. Review results above.';
```

## Expected Validation Results

### ✅ Successful Validation Should Show

| Check | Expected Result |
|-------|----------------|
| **Server Logins** | All 8 server logins exist |
| **NBS_ODSE Users** | 6 users (all except Kafka and Post Processing) |
| **NBS_SRTE Users** | 7 users (all except Kafka) |
| **rdb_modern Users** | 7 users (all except Debezium) |
| **Role Members** | 3 services with roles (Investigation, Post Processing, Kafka only) |

### Expected Role Memberships in rdb_modern

| Service | Roles |
|---------|-------|
| **Investigation Service** | `db_datareader`, `db_datawriter` |
| **Post Processing Service** | `db_owner` |
| **Kafka Sync Service** | `db_datareader`, `db_datawriter` |

### Services WITHOUT Role Memberships
**Organization, Observation, Person, LDF Services** should have **table-level permissions only** (INSERT on `job_flow_log`)

## Microservice Permission Summary

### Complete Service Permissions Matrix
**Note**: Permissions are run against either RDB or rdb_modern. If rdb_modern is created, the permission scripts will be run against it. 

| Service | Databases | Permissions                                                                                                     |
|---------|-----------|-----------------------------------------------------------------------------------------------------------------|
| **Organization** | NBS_ODSE, NBS_SRTE, rdb_modern | `SRTE/ODSE:db_datareader` + `ODSE: sp_organization_event` + `ODSE: sp_place_event` + `RDB/rdb_modern: job_flow_log INSERT` |
| **Observation** | NBS_ODSE, NBS_SRTE, rdb_modern | `SRTE/ODSE:db_datareader` + `ODSE:sp_observation_event` + `RDB/rdb_modern: job_flow_log INSERT`                            |
| **Person** | NBS_ODSE, NBS_SRTE, rdb_modern | `SRTE/ODSE:db_datareader` + `ODSE:4 SPs` + `RDB/rdb_modern: job_flow_log INSERT`                                           |
| **Investigation** | NBS_ODSE, NBS_SRTE, rdb_modern | `db_datawriter/db_datareader` on ODSE + full READ/WRITE on rdb/rdb_modern                                       |
| **LDF** | NBS_ODSE, NBS_SRTE, rdb_modern | `db_datareader` + 7 SPs + `job_flow_log INSERT`                                                                 |
| **Post Processing** | rdb, rdb_modern, NBS_SRTE | `ODSEdb_datareader`,`db_owner` on RDB/rdb_modern + `db_datareader` on SRTE                                                 |
| **Kafka Sync** | rdb_modern | `db_datareader/db_datawriter` (full READ/WRITE)                                                                 |
| **Debezium** | NBS_ODSE, NBS_SRTE | `db_datareader` only                                                                                            |

## Stored Procedures by Service

### Organization Service
- `sp_organization_event`
- `sp_place_event`

### Observation Service
- `sp_observation_event`

### Person Service
- `sp_patient_event`
- `sp_patient_race_event`
- `sp_provider_event`
- `sp_auth_user_event`

### Investigation Service
- `sp_investigation_event`
- `sp_contact_record_event`
- `sp_interview_event`
- `sp_notification_event`
- `sp_treatment_event`
- `sp_vaccination_event`
- `sp_public_health_case_fact_datamart_event`

### LDF Service
- `sp_ldf_data_event`
- `sp_ldf_patient_event`
- `sp_ldf_provider_event`
- `sp_ldf_organization_event`
- `sp_ldf_observation_event`
- `sp_ldf_phc_event`
- `sp_ldf_intervention_event`

### Post Processing, Kafka Sync, Debezium Services
No specific stored procedures (use role-based permissions for direct table access)

## Troubleshooting Permission Issues

### Issue: Missing Server Logins

#### Solution
Re-run the permission script:

```bash
sqlcmd -S [SERVER] -d [DATABASE] -U [USER] -P [PASSWORD] -i "routines/001-service_users_login_creation.sql"
```

### Issue: Wrong Database User Counts

#### Expected Counts
- **NBS_ODSE:** 6 users (all except Kafka and Post Processing)
- **NBS_SRTE:** 7 users (all except Kafka)
- **rdb_modern:** 7 users (all except Debezium)

#### Solution
Check for extra/missing users and remove/create as needed

### Issue: Wrong Role Membership Count

#### Expected
Only 3 services should have roles in rdb_modern

#### Solution
Remove unexpected role memberships:
```sql
USE [rdb_modern];
-- Remove incorrect role (example)
EXEC sp_droprolemember 'db_owner', 'incorrect_service_rdb';
```

### Issue: Unexpected Role Memberships

#### Security Risk
Organization, Observation, Person, LDF services should NOT have role memberships

#### Critical Fix
If these services show role memberships (especially `db_owner`):
```sql
-- CRITICAL: Remove dangerous role assignments
EXEC sp_droprolemember 'db_owner', 'organization_service_rdb';
EXEC sp_droprolemember 'db_datawriter', 'person_service_rdb';
-- etc.
```

### Issue: Microservice Connection Failures

#### Diagnostic Steps
1. Run validation script above
2. Check microservice logs for specific error messages
3. Verify service connection strings point to correct databases
4. Test individual service user connections:
   ```bash
   sqlcmd -S [SERVER] -d [DATABASE] -U [SERVICE_USER] -P [PASSWORD] -Q "SELECT GETDATE()"
   ```

## Advanced Diagnostics

### Check Specific Service Permissions
```sql
-- Check permissions for specific service
USE [rdb_modern];
SELECT
    p.state_desc,
    p.permission_name,
    s.name as principal_name,
    o.name as object_name
FROM sys.database_permissions p
LEFT JOIN sys.objects o ON p.major_id = o.object_id
LEFT JOIN sys.database_principals s ON p.grantee_principal_id = s.principal_id
WHERE s.name = 'organization_service_rdb';
```

### Verify Stored Procedure Access
```sql
-- Test stored procedure execution permission
USE [NBS_ODSE];
EXEC sp_organization_event -- Should work for organization_service_rdb
```

## Security Best Practices

### Principle of Least Privilege
- Services only get minimum required permissions
- No service should have `db_owner` unless specifically designed (Post Processing only)
- Table-level permissions preferred over broad role assignments

### Regular Auditing
- Run validation script monthly
- Monitor for unauthorized permission changes
- Document any manual permission modifications

### Change Management
- Always run permission script after deployments
- Validate before releasing to production
- Maintain permission documentation updates

---
