# Data Verification Queries

This document contains SQL queries to verify data loading completeness between operational tables (NBS_ODSE) and reporting dimension tables (rdb).

## Overview

These queries identify records that exist in the operational source system but are missing FROM the corresponding dimension tables in the reporting database. Each query follows the pattern of comparing active records FROM source tables with their target dimension tables.

## Considerations 

- Each validation query below works under a specific context of `rdb`/`rdb_modern` database. Specific references to nbs_odse database is explicitly specified
- The expectation is that each of the query returns 0 results indicating that both historical and current/delta records are in-sync and we have no missed events.
- Each query lists 
  - the unique ids (uid) for that table along with the `update_time` which is the last change time or add time if it is the first record
  - provide `local_id` and `record_status_cd` if available
  - provide details from `NRT_BACKFILL` table to provide additional debugging and investigation information
- Some queries filter for `record_status_cd <> 'LOG_DEL'`
  

### Troubleshooting Tips
1. Check if the ETL pipeline is running and processing recent changes
2. Verify Kafka topics are flowing properly for the specific data types
   ```
    NBS_ODSE (Source) 
        ↓ CDC/Debezium
    Kafka Topics (nbs_*) 
        ↓ Java Services
    Kafka Topics (nrt_*) 
        ↓ Sink Connectors
    Stage Tables (nrt_*) 
        ↓ Post-processing SPs
    rdb Dimensions
    ```
3. The below verification queries list the `update_time` which is a good indicator to determine if it was a historical record that was missed because of a prior Classic ETL run.
4. Review stored procedure logs for any processing errors. Here are some sample queries that could help with debugging.
   1. Below query helps to display all related stored procedure executions related to a <uid>
        ```sql
        SELECT * FROM job_flow_log 
        WHERE batch_id in (SELECT distinct batch_id FROM job_flow_log WHERE Msg_Description1 like '%<uid>%' ) 
        and create_dttm >= '<YYYY-MM-DD>'
        order by batch_id, record_id;
        ```
    2. Below query filters for error steps alone
        ```sql
        SELECT * FROM job_flow_log jfl WHERE jfl.create_dttm >= '<YYYY-MM-DD>' and Status_type='ERROR' ;
        ```
5. Consider if there are data quality issues preventing transformation



## Validation Queries

### 1. D_PROVIDER Verification

**Purpose**: Check for missed provider records by comparing operational Person table with D_PROVIDER dimension.

**Source**: `nbs_odse.dbo.Person` (WHERE cd='PRV')  
**Target**: `dbo.D_PROVIDER`  
**Key**: `person_uid` → `PROVIDER_UID`

```sql
SELECT
  src.*
     , nb.record_uid_list as backfill_retry_list
     , nb.batch_id as backfill_batch_id
     , nb.retry_count as backfill_retry_count
     , nb.err_description as backfill_err_desc
FROM (
    SELECT person_uid, local_id, ISNULL(p.last_chg_time,p.add_time) as update_time, p.record_status_cd
    FROM nbs_odse.dbo.Person p
    WHERE p.cd = 'PRV'
) src
LEFT JOIN dbo.D_PROVIDER dp ON dp.PROVIDER_UID = src.person_uid
LEFT JOIN dbo.NRT_BACKFILL nb
ON nb.entity = 'PROVIDER'
    AND EXISTS (
    SELECT 1
    FROM STRING_SPLIT(nb.record_uid_list, ',') s
    WHERE TRY_CAST(s.value AS BIGINT) = src.person_uid
)
WHERE dp.PROVIDER_UID IS NULL
ORDER BY update_time;
```

### 2. D_PATIENT Verification

**Purpose**: Check for missed patient records by comparing operational Person table with D_PATIENT dimension.

**Source**: `nbs_odse.dbo.Person` (WHERE cd='PAT')  
**Target**: `dbo.D_PATIENT`  
**Key**: `person_uid` → `patient_uid`

```sql
SELECT 
    src.*
     , nb.record_uid_list as backfill_retry_list
     , nb.batch_id as backfill_batch_id
     , nb.retry_count as backfill_retry_count
     , nb.err_description as backfill_err_desc
FROM (
    SELECT person_uid, local_id, ISNULL(p.last_chg_time,p.add_time) as update_time, p.record_status_cd   
    FROM nbs_odse.dbo.Person p 
    WHERE p.cd = 'PAT' 
) src
LEFT JOIN dbo.D_PATIENT dp ON dp.patient_uid = src.person_uid
LEFT JOIN dbo.NRT_BACKFILL nb
ON nb.entity = 'PATIENT'
AND EXISTS (
    SELECT 1
    FROM STRING_SPLIT(nb.record_uid_list, ',') s
    WHERE TRY_CAST(s.value AS BIGINT) = src.person_uid
)
WHERE dp.patient_uid IS NULL
ORDER BY update_time;
```

### 3. D_ORGANIZATION Verification

**Purpose**: Check for missed organization records by comparing operational Organization tables with D_ORGANIZATION dimension.

**Source**: `nbs_odse.dbo.Organization` 
**Target**: `dbo.D_ORGANIZATION`  
**Key**: `organization_uid` → `ORGANIZATION_UID`

```sql
SELECT
    src.*
     , nb.record_uid_list as backfill_retry_list
     , nb.batch_id as backfill_batch_id
     , nb.retry_count as backfill_retry_count
     , nb.err_description as backfill_err_desc
FROM (
    SELECT organization_uid, local_id, ISNULL(o.last_chg_time,o.add_time) as update_time, o.record_status_cd   
    FROM nbs_odse.dbo.Organization o 
) src
LEFT JOIN dbo.D_ORGANIZATION do ON do.organization_uid = src.organization_uid
LEFT JOIN NRT_BACKFILL nb
ON nb.entity = 'ORGANIZATION'
AND EXISTS (
    SELECT 1
    FROM STRING_SPLIT(nb.record_uid_list, ',') s
    WHERE TRY_CAST(s.value AS BIGINT) = src.organization_uid
)
WHERE do.organization_uid IS NULL
ORDER BY update_time;
```

### 4. INVESTIGATION Verification

**Purpose**: Check for missed investigation records by comparing operational Public_health_case with INVESTIGATION dimension.

**Source**: `nbs_odse.dbo.Public_health_case`  
**Target**: `dbo.INVESTIGATION`  
**Key**: `public_health_case_uid` → `CASE_UID`

```sql
SELECT
    src.*
     , nb.record_uid_list as backfill_retry_list
     , nb.batch_id as backfill_batch_id
     , nb.retry_count as backfill_retry_count
     , nb.err_description as backfill_err_desc
FROM (
    SELECT public_health_case_uid, 
           local_id, 
           cd, 
           investigation_status_cd,
           ISNULL(last_chg_time, add_time) as update_time,
           record_status_cd   
    FROM nbs_odse.dbo.Public_health_case phc 
) src
LEFT JOIN dbo.INVESTIGATION inv ON inv.case_uid = src.public_health_case_uid
LEFT JOIN dbo.NRT_BACKFILL nb
ON nb.entity = 'INVESTIGATION'
AND EXISTS (
    SELECT 1
    FROM STRING_SPLIT(nb.record_uid_list, ',') s
    WHERE TRY_CAST(s.value AS BIGINT) = src.public_health_case_uid
)
WHERE inv.case_uid IS NULL
ORDER BY update_time;
```

### 5. TREATMENT Verification

**Purpose**: Check for missed treatment records by comparing operational Treatment with TREATMENT dimension. 

**Source**: `nbs_odse.dbo.Treatment`  
**Target**: `dbo.TREATMENT`  
**Key**: `treatment_uid` → `TREATMENT_UID`

```sql
SELECT 
    src.* 
    , nb.record_uid_list as backfill_retry_list
    , nb.batch_id as backfill_batch_id
    , nb.retry_count as backfill_retry_count
    , nb.err_description as backfill_err_desc
FROM (
    SELECT treatment_uid, 
           local_id, 
           record_status_cd,
           ISNULL(last_chg_time, add_time) as update_time
    FROM nbs_odse.dbo.Treatment t 
) src
LEFT JOIN dbo.TREATMENT dt ON dt.treatment_uid = src.treatment_uid
LEFT JOIN dbo.NRT_BACKFILL nb
ON nb.entity = 'TREATMENT'
AND EXISTS (
    SELECT 1
    FROM STRING_SPLIT(nb.record_uid_list, ',') s
    WHERE TRY_CAST(s.value AS BIGINT) = src.treatment_uid
)
WHERE dt.treatment_uid IS NULL
ORDER BY update_time;
```

### 6. D_CASE_MANAGEMENT Verification

**Purpose**: Check for missed case management records by comparing operational case_management with D_CASE_MANAGEMENT dimension.

**Source**: `nbs_odse.dbo.case_management`  
**Target**: `dbo.D_CASE_MANAGEMENT`  
**Key**: `public_health_case_uid` → `public_health_case_uid`

```sql
SELECT 
    src.* 
    , nb.record_uid_list as backfill_retry_list
    , nb.batch_id as backfill_batch_id
    , nb.retry_count as backfill_retry_count
    , nb.err_description as backfill_err_desc
FROM (
    SELECT cm.public_health_case_uid, 
           local_id, 
           investigation_status_cd,
           ISNULL(last_chg_time, add_time) as update_time,
           record_status_cd   
    FROM nbs_odse.dbo.case_management cm 
    INNER JOIN nbs_odse.dbo.Public_health_case phc on cm.public_health_case_uid = phc.public_health_case_uid
) src
LEFT JOIN (
    SELECT case_uid 
    FROM dbo.D_CASE_MANAGEMENT dcm 
    INNER JOIN dbo.INVESTIGATION i on i.investigation_key = dcm.investigation_key
) tgt
ON tgt.case_uid = src.public_health_case_uid
LEFT JOIN dbo.NRT_BACKFILL nb
ON nb.entity = 'CASE_MANAGEMENT'
AND EXISTS (
    SELECT 1
    FROM STRING_SPLIT(nb.record_uid_list, ',') s
    WHERE TRY_CAST(s.value AS BIGINT) = src.public_health_case_uid
)
WHERE tgt.case_uid IS NULL
ORDER BY update_time;
```

### 7. D_VACCINATION Verification

**Purpose**: Check for missed vaccination records by comparing operational Intervention with D_VACCINATION dimension.

**Source**: `nbs_odse.dbo.Intervention` 
**Target**: `dbo.D_VACCINATION`  
**Key**: `intervention_uid` → `vaccination_uid`

```sql
SELECT 
    src.* 
    , nb.record_uid_list as backfill_retry_list
    , nb.batch_id as backfill_batch_id
    , nb.retry_count as backfill_retry_count
    , nb.err_description as backfill_err_desc
FROM (
    SELECT intervention_uid AS vaccination_uid, 
           local_id, 
           record_status_cd,
           ISNULL(last_chg_time, add_time) as update_time
    FROM nbs_odse.dbo.Intervention i 
) src
LEFT JOIN dbo.D_VACCINATION dv ON dv.vaccination_uid = src.vaccination_uid
LEFT JOIN dbo.NRT_BACKFILL nb
ON nb.entity = 'VACCINATION'
AND EXISTS (
    SELECT 1
    FROM STRING_SPLIT(nb.record_uid_list, ',') s
    WHERE TRY_CAST(s.value AS BIGINT) = src.vaccination_uid
)
WHERE dv.vaccination_uid IS NULL
ORDER BY update_time;
```

### 8. D_INTERVIEW Verification

**Purpose**: Check for missed interview records by comparing operational Interview with D_INTERVIEW dimension.

**Source**: `nbs_odse.dbo.Interview`  
**Target**: `dbo.D_INTERVIEW`  
**Key**: `interview_uid` → `INTERVIEW_UID` (but is not available in base dimension hence using `LOCAL_ID`)

```sql
SELECT
    src.* 
    , nb.record_uid_list as backfill_retry_list
    , nb.batch_id as backfill_batch_id
    , nb.retry_count as backfill_retry_count
    , nb.err_description as backfill_err_desc 
FROM (
    SELECT interview_uid, 
           local_id, 
           record_status_cd,
           ISNULL(last_chg_time,add_time) as update_time
    FROM nbs_odse.dbo.Interview i 
) src
LEFT JOIN (
    SELECT n.interview_uid, d.local_id
    FROM dbo.NRT_INTERVIEW_KEY n
    INNER JOIN dbo.D_INTERVIEW d 
    ON d.d_interview_key = n.d_interview_key
) di
ON di.interview_uid = src.interview_uid
LEFT JOIN dbo.NRT_BACKFILL nb
ON nb.entity = 'INTERVIEW'
AND EXISTS (
    SELECT 1
    FROM STRING_SPLIT(nb.record_uid_list, ',') s
    WHERE TRY_CAST(s.value AS BIGINT) = src.interview_uid
)
WHERE di.LOCAL_ID IS NULL
ORDER BY update_time;
```

### 9. LAB_TEST Verification

**Purpose**: Check for missed lab test records by comparing operational Observation with LAB_TEST dimension.

**Source**: `nbs_odse.dbo.Observation`  
**Target**: `dbo.LAB_TEST`  
**Key**: `observation_uid` → `lab_test_uid`

```sql
SELECT 
    src.* 
    , nb.record_uid_list as backfill_retry_list
    , nb.batch_id as backfill_batch_id
    , nb.retry_count as backfill_retry_count
    , nb.err_description as backfill_err_desc 
FROM (
    SELECT 
        observation_uid,
        local_id,
        record_status_cd,
        ISNULL(last_chg_time, add_time) as update_time,
        obs_domain_cd_st_1
    FROM nbs_odse.dbo.Observation obs 
    WHERE obs.record_status_cd <> 'LOG_DEL'
    AND obs.obs_domain_cd_st_1 IN ('Order', 'Result', 'R_Order', 'R_Result', 'I_Order', 'I_Result', 'Order_rslt')
            AND (obs.CTRL_CD_DISPLAY_FORM IN ('LabReport', 'LabReportMorb') OR obs.CTRL_CD_DISPLAY_FORM IS NULL)
) src
LEFT JOIN dbo.LAB_TEST lt ON lt.LAB_TEST_UID = src.observation_uid
LEFT JOIN dbo.NRT_BACKFILL nb
ON nb.entity = 'OBSERVATION'
AND EXISTS (
    SELECT 1
    FROM STRING_SPLIT(nb.record_uid_list, ',') s
    WHERE TRY_CAST(s.value AS BIGINT) = src.observation_uid
)
WHERE lt.LAB_TEST_UID IS NULL
ORDER BY update_time;
```

### 10. LAB_TEST_RESULT Verification

**Purpose**: Check for missed lab test result records by comparing operational Observation with LAB_TEST_RESULT dimension.

**Source**: `nbs_odse.dbo.Observation` (WHERE obs_domain_cd_st_1='Result')  
**Target**: `dbo.LAB_TEST_RESULT`  
**Key**: `observation_uid` → `lab_test_uid`

```sql
SELECT 
    src.* 
    , nb.record_uid_list as backfill_retry_list
    , nb.batch_id as backfill_batch_id
    , nb.retry_count as backfill_retry_count
    , nb.err_description as backfill_err_desc 
FROM (
    SELECT 
        observation_uid,
        local_id,
        record_status_cd,
        ISNULL(last_chg_time, add_time) as update_time,
        obs_domain_cd_st_1
    FROM nbs_odse.dbo.Observation obs 
    WHERE obs.record_status_cd <> 'LOG_DEL'
    AND obs.obs_domain_cd_st_1 IN ( 'Result', 'R_Result', 'I_Result', 'Order_rslt')
            AND (obs.CTRL_CD_DISPLAY_FORM IN ('LabReport', 'LabReportMorb') OR obs.CTRL_CD_DISPLAY_FORM IS NULL)
) src
LEFT JOIN dbo.LAB_TEST_RESULT lt ON lt.LAB_TEST_UID = src.observation_uid
LEFT JOIN dbo.NRT_BACKFILL nb
ON nb.entity = 'OBSERVATION'
AND EXISTS (
    SELECT 1
    FROM STRING_SPLIT(nb.record_uid_list, ',') s
    WHERE TRY_CAST(s.value AS BIGINT) = src.observation_uid
)
WHERE lt.LAB_TEST_UID IS NULL
ORDER BY update_time;
```


### 11. HEPATITIS_DATAMART Verification

**Purpose**: Check for missed hepatitis datamart records by comparing operational Public_health_case with HEPATITIS_DATAMART fact table.

**Source**: `nbs_odse.dbo.Public_health_case` (hepatitis conditions)  
**Target**: `dbo.HEPATITIS_DATAMART`  
**Key**: `public_health_case_uid` → `investigation_key`

```sql
SELECT 
    src.* 
    , nb.record_uid_list as backfill_retry_list
    , nb.batch_id as backfill_batch_id
    , nb.retry_count as backfill_retry_count
    , nb.err_description as backfill_err_desc 
FROM (
    SELECT public_health_case_uid,
           local_id,
           investigation_status_cd,
           record_status_cd,
           ISNULL(last_chg_time, add_time) as update_time,
           cd_desc_txt
    FROM nbs_odse.dbo.Public_health_case phc 
    WHERE phc.record_status_cd <> 'LOG_DEL'
      AND (phc.cd_desc_txt LIKE '%HEPATITIS%' OR phc.cd LIKE 'HEP%')
) src
LEFT JOIN (
    SELECT i.case_uid 
    FROM dbo.HEPATITIS_DATAMART c 
    INNER JOIN dbo.INVESTIGATION i 
    on i.investigation_key = c.investigation_key
) hd
ON hd.case_uid = src.public_health_case_uid
LEFT JOIN dbo.NRT_BACKFILL nb
ON (nb.entity = 'INVESTIGATION' or nb.entity like '%HEPATITIS_DATAMART%')
AND EXISTS (
    SELECT 1
    FROM STRING_SPLIT(nb.record_uid_list, ',') s
    WHERE TRY_CAST(s.value AS BIGINT) = src.public_health_case_uid
)
WHERE hd.case_uid IS NULL
ORDER BY update_time;
```

### 12. HEPATITIS_CASE Verification

**Purpose**: Check for missed hepatitis case records by comparing operational Public_health_case with HEPATITIS_CASE dimension.

**Source**: `nbs_odse.dbo.Public_health_case` (hepatitis conditions)  
**Target**: `dbo.HEPATITIS_CASE`  
**Key**: `public_health_case_uid` → `investigation_key`

```sql
SELECT 
    src.* 
    , nb.record_uid_list as backfill_retry_list
    , nb.batch_id as backfill_batch_id
    , nb.retry_count as backfill_retry_count
    , nb.err_description as backfill_err_desc 
FROM (
    SELECT 
        public_health_case_uid,
        local_id,
        investigation_form_cd,
        record_status_cd,
        ISNULL(last_chg_time, add_time) as update_time,
        cd_desc_txt
    FROM nbs_odse.dbo.Public_health_case phc 
    INNER JOIN nbs_srte.dbo.condition_code cc with (nolock)
    on
     cc.condition_cd = phc.cd
 	WHERE phc.record_status_cd <> 'LOG_DEL'
      AND investigation_form_cd like 'INV_FORM_HEP%'
) src
LEFT JOIN (
    SELECT i.case_uid 
    FROM dbo.HEPATITIS_CASE c 
    INNER JOIN dbo.INVESTIGATION i 
    on i.investigation_key = c.investigation_key
) hc 
ON hc.case_uid  = src.public_health_case_uid
LEFT JOIN dbo.NRT_BACKFILL nb
ON (nb.entity = 'INVESTIGATION'or nb.entity like '%HEPATITIS_CASE%')
AND EXISTS (
    SELECT 1
    FROM STRING_SPLIT(nb.record_uid_list, ',') s
    WHERE TRY_CAST(s.value AS BIGINT) = src.public_health_case_uid
)
WHERE hc.case_uid IS NULL
ORDER BY update_time;
```



### 13. HEP100 Verification

**Purpose**: Check for missed HEP100 datamart records by comparing operational Public_health_case with HEP100 fact table.

**Source**: `nbs_odse.dbo.Public_health_case` (HEP100 condition)  
**Target**: `dbo.HEP100`  
**Key**: `public_health_case_uid` → `investigation_key`

```sql
SELECT 
    src.* 
    , nb.record_uid_list as backfill_retry_list
    , nb.batch_id as backfill_batch_id
    , nb.retry_count as backfill_retry_count
    , nb.err_description as backfill_err_desc 
FROM (
    SELECT public_health_case_uid,
           local_id,
           investigation_form_cd,
           record_status_cd,
           ISNULL(last_chg_time,add_time) as update_time,
           cd_desc_txt
    FROM nbs_odse.dbo.Public_health_case phc 
    inner join nbs_srte.dbo.condition_code cc with (nolock)
    on
     cc.condition_cd = phc.cd
 	WHERE phc.record_status_cd <> 'LOG_DEL'
      AND investigation_form_cd like 'INV_FORM_HEP%'
) src
LEFT JOIN (
    SELECT i.case_uid 
    FROM dbo.HEP100 c 
    inner join dbo.INVESTIGATION i 
    on i.investigation_key = c.investigation_key
) hd
ON hd.case_uid = src.public_health_case_uid
LEFT JOIN dbo.NRT_BACKFILL nb
ON (nb.entity = 'INVESTIGATION' or nb.entity like '%HEPATITIS_CASE%' or nb.entity like '%HEP100%')
AND EXISTS (
    SELECT 1
    FROM STRING_SPLIT(nb.record_uid_list, ',') s
    WHERE TRY_CAST(s.value AS BIGINT) = src.public_health_case_uid
)
WHERE hd.CASE_UID IS NULL
ORDER BY update_time;
```


### 14. NOTIFICATION Verification

**Purpose**: Check for missed notification records by comparing operational Notification with NOTIFICATION dimension.

**Source**: `nbs_odse.dbo.Notification`  
**Target**: `dbo.NOTIFICATION`  
**Key**: `notification_uid` → `notification_key` 

```sql
SELECT 
    src.*
    , nb.record_uid_list as backfill_retry_list
    , nb.batch_id as backfill_batch_id
    , nb.retry_count as backfill_retry_count
    , nb.err_description as backfill_err_desc 
FROM (
    SELECT 
        notification_uid,
        local_id,
        record_status_cd,
        ISNULL(last_chg_time,add_time) as update_time
    FROM nbs_odse.dbo.Notification n
) src
LEFT JOIN (
    SELECT i.notification_uid 
    FROM dbo.NOTIFICATION n 
    inner join dbo.NRT_NOTIFICATION_KEY i 
    on i.d_notification_key = n.notification_key
) nt 
ON nt.notification_uid = src.notification_uid
LEFT JOIN dbo.NRT_BACKFILL nb
ON nb.entity = 'NOTIFICATION' 
AND EXISTS (
    SELECT 1
    FROM STRING_SPLIT(nb.record_uid_list, ',') s
    WHERE TRY_CAST(s.value AS BIGINT) = src.notification_uid
)
WHERE nt.notification_uid IS NULL
ORDER BY update_time;
```

### 16. NOTIFICATION_EVENT Verification

**Purpose**: Check for missed notification event records by comparing operational Notification and Act_Relationship with NOTIFICATION_EVENT.

**Source**: `nbs_odse.dbo.Notification`
**Target**: `dbo.NOTIFICATION_EVENT`  
**Key**: `notification_uid` → `notification_key`

```sql
SELECT 
    src.*
    , nb.record_uid_list as backfill_retry_list
    , nb.batch_id as backfill_batch_id
    , nb.retry_count as backfill_retry_count
    , nb.err_description as backfill_err_desc 
FROM (
    SELECT 
        notif.notification_uid,
        notif.local_id,
        act.target_act_uid as phc_uid,
        ISNULL(act.last_chg_time,ISNULL(notif.last_chg_time,notif.add_time)) as update_time
    FROM nbs_odse.dbo.Notification notif
    INNER JOIN nbs_odse.dbo.act_relationship act
        ON act.source_act_uid = notif.notification_uid
        AND notif.cd not in ('EXP_NOTF', 'SHARE_NOTF', 'EXP_NOTF_PHDC','SHARE_NOTF_PHDC')
        AND act.source_class_cd = 'NOTF'
        AND act.target_class_cd = 'CASE' 
) src
LEFT JOIN (
    SELECT 
        k.notification_uid, n.notification_local_id, i.case_uid
    FROM 
        dbo.NOTIFICATION_EVENT nt
    INNER JOIN dbo.NRT_NOTIFICATION_KEY k 
        ON nt.notification_key = k.d_notification_key
    INNER JOIN dbo.NOTIFICATION n
        ON nt.notification_key = n.notification_key
    LEFT JOIN dbo.INVESTIGATION i
        ON i.investigation_key = nt.investigation_key
) tgt
ON tgt.notification_uid = src.notification_uid and src.phc_uid = tgt.case_uid
LEFT JOIN dbo.NRT_BACKFILL nb
ON nb.entity = 'NOTIFICATION' 
AND EXISTS (
    SELECT 1
    FROM STRING_SPLIT(nb.record_uid_list, ',') s
    WHERE TRY_CAST(s.value AS BIGINT) = src.notification_uid
)
WHERE tgt.notification_uid IS NULL
ORDER BY update_time;
```

### 18. TREATMENT_EVENT Verification

**Purpose**: Check for missed treatment event records by comparing operational Treatment with TREATMENT_EVENT dimension.

**Source**: `nbs_odse.dbo.Treatment` (event processing)  
**Target**: `dbo.TREATMENT_EVENT`  
**Key**: `treatment_uid` → `TREATMENT_UID`

```sql
SELECT 
    src.* 
    , nb.record_uid_list as backfill_retry_list
    , nb.batch_id as backfill_batch_id
    , nb.retry_count as backfill_retry_count
    , nb.err_description as backfill_err_desc 
FROM (
    SELECT t.treatment_uid,
           local_id,
           record_status_cd,
           ISNULL(last_chg_time,add_time) as update_time
    FROM nbs_odse.dbo.Treatment t 
    INNER JOIN nbs_odse.dbo.Treatment_administered td
    ON td.treatment_uid = t.treatment_uid
) src
LEFT JOIN (
	SELECT t.treatment_uid
	FROM dbo.TREATMENT t 
	INNER JOIN dbo.TREATMENT_EVENT tet 
	ON tet.treatment_key = t.treatment_key
) te
ON te.treatment_uid = src.treatment_uid 
LEFT JOIN dbo.NRT_BACKFILL nb
ON nb.entity = 'TREATMENT'
AND EXISTS (
    SELECT 1
    FROM STRING_SPLIT(nb.record_uid_list, ',') s
    WHERE TRY_CAST(s.value AS BIGINT) = src.treatment_uid
)
WHERE te.treatment_uid IS NULL
ORDER BY update_time;
```