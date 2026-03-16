# Playbook: End-to-End Testing of Bulk Loading ELRs into RTR

## 1. Overview
This playbook provides instructions for conducting end-to-end (E2E) testing of bulk loading Electronic Laboratory Reports (ELRs) into the Real Time Reporting (RTR) system. It is designed to guide STLTs through the process of initiating tests and capturing metrics for quality, performance, and latency.

## 2. Objectives
- Provide clear instructions for test data selection and execution.
- Define a systematic approach to verify data quality and integrity in the reporting database (`RDB_MODERN`).
- Establish a baseline for measuring system performance and end-to-end processing latency.
- Identify gaps in RTR that would prevent successful execution of this playbook.

## 3. Test Data Preparation

### 3.1 Test Data Selection
Instead of using synthetic data, select a set of **real, but de-identified testing ELRs** from your existing test environment. 

- **Target Volume:** More than a few dozen, but less than 1000 (Recommended: 50–500 messages).
- **Format:** HL7 v2.5.1 (.hl7 files).

1.  **Prepare HL7 Files:**
    Place your HL7 message files into a local directory (e.g., `./test_data/`).

### 3.2 Diversity of Test Data
Ensure the selected data includes:
- Multiple conditions (LOINC codes).
- New patients vs. existing patients.
- Various demographics (Race, Ethnicity, Age).

## 4. Test Execution

### 4.1 Loading Data via Data Ingestion (DI) API
The primary method for loading ELRs is using the **RTR ELR Bulk Upload Utility** script. This script authenticates with the DI service and uploads each file in your test directory.

> **Note:** We'll need to create a bulk_upload_elr.py script for testing

> Note: We'll need to provide instructions for creating a JWT token

### 4.2 Monitoring the Pipeline
- **Kafka Topics:** Monitor topics like `nbs.Observation`.
- **RTR Logs:** Check logs for `observation-reporting-service` and `post-processing-reporting-service`.
- Resource Usage: Monitor K8 cluster CPU and RAM utilization

### 4.3 Triggering Legacy MasterETL
To verify data parity between the new RTR system and the legacy ETL process, you must trigger the legacy MasterETL.

*Note: This process may take several minutes depending on the volume of data.*

## 5. Quality Assurance: Data Parity Verification

Once both RTR and MasterETL have completed, perform a comparison between the legacy `RDB` and the modernized `RDB_MODERN` databases to ensure parity.

### 5.1 Quality Comparison Query: D_PATIENT
Use this query to identify field-level mismatches for patient records across both databases.

```sql
SELECT 
    modern.PATIENT_UID,
    -- NULL if matches, otherwise "LegacyValue | ModernValue"
    CASE WHEN ISNULL(legacy.PATIENT_LOCAL_ID, '') = ISNULL(modern.PATIENT_LOCAL_ID, '') THEN NULL 
         ELSE ISNULL(legacy.PATIENT_LOCAL_ID, 'NULL') + ' | ' + ISNULL(modern.PATIENT_LOCAL_ID, 'NULL') END AS LOCAL_ID_DIFF,
    CASE WHEN ISNULL(legacy.PATIENT_LAST_NAME, '') = ISNULL(modern.PATIENT_LAST_NAME, '') THEN NULL 
         ELSE ISNULL(legacy.PATIENT_LAST_NAME, 'NULL') + ' | ' + ISNULL(modern.PATIENT_LAST_NAME, 'NULL') END AS LAST_NAME_DIFF,
    CASE WHEN ISNULL(legacy.PATIENT_FIRST_NAME, '') = ISNULL(modern.PATIENT_FIRST_NAME, '') THEN NULL 
         ELSE ISNULL(legacy.PATIENT_FIRST_NAME, 'NULL') + ' | ' + ISNULL(modern.PATIENT_FIRST_NAME, 'NULL') END AS FIRST_NAME_DIFF,
    CASE WHEN ISNULL(legacy.PATIENT_BIRTH_TIME, '1900-01-01') = ISNULL(modern.PATIENT_BIRTH_TIME, '1900-01-01') THEN NULL 
         ELSE CAST(legacy.PATIENT_BIRTH_TIME AS VARCHAR) + ' | ' + CAST(modern.PATIENT_BIRTH_TIME AS VARCHAR) END AS DOB_DIFF,
    CASE WHEN ISNULL(legacy.PATIENT_STREET_ADDRESS_1, '') = ISNULL(modern.PATIENT_STREET_ADDRESS_1, '') THEN NULL 
         ELSE ISNULL(legacy.PATIENT_STREET_ADDRESS_1, 'NULL') + ' | ' + ISNULL(modern.PATIENT_STREET_ADDRESS_1, 'NULL') END AS ADDRESS_DIFF
FROM RDB.dbo.D_PATIENT legacy
JOIN RDB_MODERN.dbo.D_PATIENT modern ON legacy.PATIENT_UID = modern.PATIENT_UID
WHERE modern.ADD_TIME > [TEST_START_TIME]
AND (
    legacy.PATIENT_LOCAL_ID <> modern.PATIENT_LOCAL_ID OR
    legacy.PATIENT_LAST_NAME <> modern.PATIENT_LAST_NAME OR
    legacy.PATIENT_FIRST_NAME <> modern.PATIENT_FIRST_NAME OR
    legacy.PATIENT_BIRTH_TIME <> modern.PATIENT_BIRTH_TIME
);
```

### 5.2 Quality Comparison Query: LAB_TEST
Use this query to identify field-level mismatches for lab report data.

```sql
SELECT 
    modern.LAB_TEST_UID,
    CASE WHEN ISNULL(legacy.LAB_RPT_LOCAL_ID, '') = ISNULL(modern.LAB_RPT_LOCAL_ID, '') THEN NULL 
         ELSE ISNULL(legacy.LAB_RPT_LOCAL_ID, 'NULL') + ' | ' + ISNULL(modern.LAB_RPT_LOCAL_ID, 'NULL') END AS LOCAL_ID_DIFF,
    CASE WHEN ISNULL(legacy.LAB_TEST_CD, '') = ISNULL(modern.LAB_TEST_CD, '') THEN NULL 
         ELSE ISNULL(legacy.LAB_TEST_CD, 'NULL') + ' | ' + ISNULL(modern.LAB_TEST_CD, 'NULL') END AS TEST_CD_DIFF,
    CASE WHEN ISNULL(legacy.LAB_TEST_DT, '1900-01-01') = ISNULL(modern.LAB_TEST_DT, '1900-01-01') THEN NULL 
         ELSE CAST(legacy.LAB_TEST_DT AS VARCHAR) + ' | ' + CAST(modern.LAB_TEST_DT AS VARCHAR) END AS TEST_DATE_DIFF,
    CASE WHEN ISNULL(legacy.LAB_RPT_STATUS, '') = ISNULL(modern.LAB_RPT_STATUS, '') THEN NULL 
         ELSE ISNULL(legacy.LAB_RPT_STATUS, 'NULL') + ' | ' + ISNULL(modern.LAB_RPT_STATUS, 'NULL') END AS STATUS_DIFF
FROM RDB.dbo.LAB_TEST legacy
JOIN RDB_MODERN.dbo.LAB_TEST modern ON legacy.LAB_TEST_UID = modern.LAB_TEST_UID
WHERE modern.LAB_RPT_CREATED_DT > [TEST_START_TIME]
AND (
    legacy.LAB_RPT_LOCAL_ID <> modern.LAB_RPT_LOCAL_ID OR
    legacy.LAB_TEST_CD <> modern.LAB_TEST_CD OR
    legacy.LAB_RPT_STATUS <> modern.LAB_RPT_STATUS
);
```

### 5.3 Event Metric Comparison
Verify that the high-level metrics captured by RTR match expectations.

```sql
SELECT EVENT_TYPE, COUNT(*) 
FROM RDB_MODERN.dbo.EVENT_METRIC 
WHERE ADD_TIME > [TEST_START_TIME] 
GROUP BY EVENT_TYPE;
```

## 6. Performance and Latency Metrics

### 6.1 Throughput
Calculate the number of ELRs processed per minute.
- **Formula:** `Total ELRs / (Finish Time - Start Time)`

### 6.2 Latency
Measure the time from the start of the upload script to availability in `RDB_MODERN`.

1.  **Capture Start Timestamp:** Note the time you execute the `bulk_upload_elr.py` script.
2.  **Capture End Timestamp:**
    ```sql
    SELECT MAX(RECORD_STATUS_TIME) 
    FROM RDB_MODERN.dbo.EVENT_METRIC 
    WHERE EVENT_TYPE = 'LabReport' AND ELECTRONIC_IND = 'Y';
    ```

## 7. Identified Gaps

1.  **Automated Latency Tracking:** There is no built-in "arrival timestamp" in `RDB_MODERN` that reflects when RTR finished processing, making precise E2E latency calculations difficult without log analysis.
2.  **Native Bulk Upload Endpoint:** The DI service currently only supports single-message uploads via REST. A native bulk endpoint would improve performance and reduce overhead.
3.  **Data Completeness for Templates:** Some page-builder-based conditions may show errors in logs due to missing lookup data in dev snapshots.
4.  **Test Result Visualization:** Lack of a dashboard or automated reporting tool to visualize test results and performance trends.
