# NRT Table Population and SQL Script Documentation

## Overview
Documentation of procedures and scripts used for populating NRT (Near-Real-Time) tables in RDB_MODERN from ODSE (Operational Data Store Entry) sources.

## NRT Population Process

### Stored Procedures
Two main stored procedures handle NRT population:

#### 1. sp_populate_nrt
**Purpose**: Populates NRT tables with single-key data
**Used for**: Organization, Person, Observation, Investigation, Interview, Auth_user, Place, Treatment, Notification, CT_contact

**Key Parameters**:
- `@ODSETable`: Source table name in NBS_ODSE
- `@ODSEUidColumn`: UID column name in source
- `@SetStatement`: Custom SET statement for timestamp handling
- `@BatchSize`: Number of rows to process per batch (default: 1000)
- `@NRTTable`: Target NRT table in RDB_MODERN
- `@NRTUIDColumn`: UID column in target table

**Execution Flow**:
1. Loads all existing UIDs from NRT table into memory
2. Compares against ODSE source by UID
3. Updates only missing/changed rows with timestamp
4. Logs progress and results to job_flow_log

#### 2. sp_populate_nrt_multikey
**Purpose**: Populates NRT tables requiring multiple keys
**Used for**: state_defined_field_data (LDF)

**Key Differences**:
- Accepts two key columns (`@Key1`, `@Key2`)
- Uses composite keys for uniqueness checking
- Handles complex business logic scenarios

### Table Examples

#### Organization Population
```sql
exec rdb_modern.dbo.sp_populate_nrt
    @ODSETable         = 'Organization',
    @ODSEUidColumn     = 'organization_uid',
    @SetStatement      = 'SET t.last_chg_time = COALESCE(DATEADD(millisecond, 2, t.last_chg_time), GETDATE())',
    @BatchSize         = '1000',
    @NRTTable          = 'rdb_modern.dbo.nrt_organization',
    @NRTUIDColumn      = 'organization_uid';
```

#### Investigation Population (Renamed from Public_health_case)
```sql
exec rdb_modern.dbo.sp_populate_nrt
    @ODSETable         = 'Public_health_case',
    @ODSEUidColumn     = 'public_health_case_uid',
    @SetStatement      = 'SET t.last_chg_time = COALESCE(DATEADD(millisecond, 2, t.last_chg_time), GETDATE())',
    @BatchSize         = '1000',
    @NRTTable          = 'rdb_modern.dbo.nrt_investigation',
    @NRTUIDColumn      = 'public_health_case_uid';
```

#### LDF (State-Defined Field) Population - Multi-Key
```sql
exec rdb_modern.dbo.sp_populate_nrt_multikey
    @ODSETable         = 'state_defined_field_data',
    @Key1              = 'ldf_uid',
    @Key2              = 'business_object_uid',
    @SetStatement      = 'SET t.last_chg_time = COALESCE(DATEADD(millisecond, 2, t.last_chg_time), GETDATE())',
    @BatchSize         = '1000',
    @NRTTable          = 'rdb_modern.dbo.nrt_ldf_data',
    @NRTKey1           = 'ldf_uid',
    @NRTKey2           = 'business_object_uid';
```

## Script Location and Format

**Location**: `liquibase-service/src/main/resources/db/001-master/02_onboarding_script_data_load/`

### Key Scripts
- **021-sp_populate_nrt-001.sql**: Main sp_populate_nrt procedure definition
- **022-sp_populate_nrt_multikey-001.sql**: Multi-key procedure definition  
- **023-load_nrt_data-001.sql**: Data loading script calling the procedures

### Code Formatting Standard
- Parameter assignments aligned with `=` at column 24
- Indentation: 4 spaces for parameter lines
- Example format:
```sql
exec rdb_modern.dbo.sp_populate_nrt
    @ODSETable         = 'Organization',
    @ODSEUidColumn     = 'organization_uid',
```

## Database Context

### Active Database Tracking
- Scripts now explicitly use `USE [rdb_modern];` at the beginning
- All references qualified with `rdb_modern.dbo.` schema prefix
- Prevents context switching issues during execution

### Timestamp Handling
- GETDATE() used for current server time
- DATEADD(millisecond, 2, ...) adds 2ms offset for sequential ordering
- COALESCE handles NULL values to ensure timestamp is always set

## Feature Flags

### Deployment Dependencies
After running all NRT population stored procedures:

1. **Person/Investigation/Organization Services**:
   - Redeploy with `phc-datamart-disable` set to **false**

2. **Post-Processing Service**:
   - Redeploy with `service-disable` set to **false**

These features allow the system to utilize the newly populated NRT data.

## Verification Steps

1. Check job_flow_log table for execution records
2. Verify row counts in each nrt_* table
3. Compare timestamps with source data
4. Validate no duplicate UIDs exist
5. Confirm all expected row collections were processed

## Related Documentation
- [Database Tracing Workflow](./database-tracing-workflow.md)
- Liquibase Changelog: 001-master changelog
- Onboarding Documentation: Database initialization procedures
