# Functional Test Validation
Currently, functional tests are validated using the changes captured on the RDB_MODERN database. This document provides instructions using the tools in this repository to capture the changes performed by MasterEtl on the legacy RDB database. These instructions assume your functional test files `query.sql` and `expected.json` enforce the functional test standards agreed upon by the team including the use of id fields (e.g., `local_id` or `act_uid`) and respective file syntax expected by `reporting-pipeline-service/src/test/java/gov/cdc/nbs/report/pipeline/integration/functional/DataDrivenFunctionalTests.java`. Additionally, `setup.sql` is expected to be completed, but may require changes based on your unique functional tests - <strong>those details are provided here</strong>.

This documentation was produced as a deliverable for the Jira Ticket [APP-473](https://cdc-nbs.atlassian.net/browse/APP-473).

## Process
These instructions should be performed in the order displayed here.

### 1) Prepare test SQL inputs (steps 1–3)

1. Create temporary copies of `setup.sql`.
2. Update all `last_chg_time` values to the current UTC timestamp using `GETDATE()`.
3. (OPTIONAL) Increment all UIDs declared at the top of `setup.sql` by 1. This step will likely be needed if the instructions were not followed in order, requiring a <em>retry</em>. (ONLY FOR GENERATING DATA!).

### 2) Prepare for tracing and execute SQL in sequence (steps 4–5)

4. Using `sqlcmd`, execute the SQL files.
```shell
sqlcmd -S localhost,3433 -U sa -P "PizzaIsGood33\!" -b -C -i 010-<xxx-myFunctionalTestStep>/setup.sql
```
5. Run `trace_db_logical_changes.py` pointing to RDB.
```shell
python utilities/local-db-tracing/trace_db_logical_changes.py --database RDB --user sa --password PizzaIsGood33\!
```
6. Execute the SQL files in the most logical order (e.g., first patient, then morbidity report).

### 3) Run MasterEtl and capture changes (steps 6–11)
7. When the program prompts you to press **ENTER**, run Master ETL.
8. After MasterEtl has completed, press **ENTER** in the Python program to capture changes.
9. Fill in the prompts at your discretion.
10. Review results in the Python program output.
11. Use `logical_changes.md` or `logical_changes.json` to focus on relevant changes.

### 4) Update validation artifacts (steps 12–16)

12. Compare inserts of expected RDB tables to your `query.sql` file.
13. Modify `query.sql` as needed.
14. Compare inserts of expected RDB tables to your `expected.json` file.
15. Modify `expected.json` as needed.
16. Consider any additional non-log tables that may need validation.

### 5) Functional Tests
Execute the functional tests and determine what modifications are needed!

## Example Using Morbidity Report Functional Test Suite
### Using setup.sql to Create Data on ODSE
1. The existing `setup.sql` file was copied and all inserts for `last_chg_time` for all tables where updated to use `GETDATE()`. Consider the truncated example below. Note that there were files to copy/modify in this case for creating a patient and creating their morbidity report!
```sql
-- dbo.Entity_id (ORIGINAL)
INSERT INTO [dbo].[entity_id]
            ([entity_uid],
             [entity_id_seq],
             [add_time],
             [assigning_authority_cd],
             [last_chg_time],
             ...)
VALUES      (@dbo_Entity_entity_uid,
             1,
             N'2026-04-10T20:26:11.673',
             N'GA',
             N'2026-04-10T20:26:11.673',
             ...
-- dbo.Entity_id (TEMP COPY)
INSERT INTO [dbo].[entity_id]
            ([entity_uid],
             [entity_id_seq],
             [add_time],
             [assigning_authority_cd],
             [last_chg_time],
             ...
VALUES      (@dbo_Entity_entity_uid,
             1,
             N'2026-04-23T22:34:46.000',
             N'GA',
             GETDATE(),
             ...)
```
3. Example of incrementing the UIDs and Local ID (ONLY FOR GENERATING DATA!). <strong>You want to avoid this because it will require having to consider the UIDS in your original validation file which can become tedious so that you do not override them with the incremented ones</strong>.
```sql
-- ORIGINAL
DECLARE @dbo_Entity_entity_uid bigint = 20100001
DECLARE @dbo_Postal_locator_postal_locator_uid bigint = 20100011
DECLARE @dbo_Tele_locator_tele_locator_uid bigint = 20100012
DECLARE @dbo_Act_act_uid bigint = 20100013
DECLARE @dbo_Act_act_uid_2 bigint = 20100014
DECLARE @dbo_Act_act_uid_3 bigint = 20100015
DECLARE @dbo_Act_act_uid_4 bigint = 20100016
DECLARE @dbo_Act_act_uid_5 bigint = 20100017
DECLARE @dbo_Act_act_uid_6 bigint = 20100018
...
DECLARE @dbo_Act_act_uid_15 bigint = 20100027
DECLARE @dbo_Person_local_id nvarchar(40) = N'PSN20100000GA01'
-- TEMP COPY
DECLARE @dbo_Entity_entity_uid bigint = 20100002
DECLARE @dbo_Postal_locator_postal_locator_uid bigint = 20100012
DECLARE @dbo_Tele_locator_tele_locator_uid bigint = 20100013
DECLARE @dbo_Act_act_uid bigint = 20100028
DECLARE @dbo_Act_act_uid_2 bigint = 20100029
DECLARE @dbo_Act_act_uid_3 bigint = 20100030
DECLARE @dbo_Act_act_uid_4 bigint = 20100031
DECLARE @dbo_Act_act_uid_5 bigint = 20100032
DECLARE @dbo_Act_act_uid_6 bigint = 20100033
...
DECLARE @dbo_Act_act_uid_15 bigint = 20100042
DECLARE @dbo_Person_local_id nvarchar(40) = N'PSN20100000GA02'
```
4. `trace_db_logical_changes.py` was executed pointing to the RDB.
```shell
python utilities/local-db-tracing/trace_db_logical_changes.py --database RDB --user sa --password PizzaIsGood33\!
```
5. The following commands were executed to first create the patient, then create their morbidity report:
```shell
sqlcmd -S localhost,3433 -U sa -P "PizzaIsGood33\!" -b -C -i 010-addPatient/setup.sql
```
```shell
sqlcmd -S localhost,3433 -U sa -P "PizzaIsGood33\!" -b -C -i 020-addMorbidityReport/setup.sql
```
6. Press **ENTER** in the python tracing program...
7. Review the results in `utilities/local-db-tracing/output/20260423-183127-RDB/logical-changes.md`. Sample below:
## 113. INSERT dbo.MORBIDITY_REPORT

| Metric | Value |
| --- | --- |
| Identity | business_keys: MORB_RPT_LOCAL_ID="OBS20100086GA01" |
| Transaction end | 2026-04-23T22:22:34.720 |
| LSN | 0x00006bf6000312400004 |

### Inserted Row

| Field | Value |
| --- | --- |
| DAYCARE_IND | "N" |
| DIAGNOSIS_DT | "2026-04-05T00:00:00" |
| DIE_FROM_ILLNESS_IND | "Y" |
| ELECTRONIC_IND | "N" |
| FOOD_HANDLER_IND | "N" |
| HEALTHCARE_ORG_ASSOCIATE_IND | "UNK" |
| HOSPITALIZED_IND | "Y" |
| HSPTL_ADMISSION_DT | "2026-04-03T00:00:00" |
| JURISDICTION_CD | "130001" |
| JURISDICTION_NM | "Fulton County" |
| MORB_RPT_CREATE_BY | 10009282 |
| MORB_RPT_KEY | 3 |
| MORB_RPT_LAST_UPDATE_BY | 10009282 |
| MORB_RPT_LAST_UPDATE_DT | "2026-04-23T22:20:11.717" |
| MORB_RPT_LOCAL_ID | "OBS20100086GA01" |
| MORB_RPT_OID | 1300100009 |
| MORB_RPT_OTHER_SPECIFY | "other something" |
| MORB_RPT_SHARE_IND | "T" |
| MORB_RPT_TYPE | "INIT" |
| MORB_RPT_UID | 20100086 |
| NURSING_HOME_ASSOCIATE_IND | "Y" |
| PH_RECEIVE_DT | "2026-04-10T00:00:00" |
| PREGNANT_IND | "Y" |
| RDB_LAST_REFRESH_TIME | "2026-04-23T22:22:34.717" |
| RECORD_STATUS_CD | "ACTIVE" |
| SUSPECT_FOOD_WTRBORNE_ILLNESS | "N" |

### Updating `query.sql` and `expected.json`.
The existing files for this functional test suite were accurate based on MasterEtl's output with the exception of 1 table: `MORBIDITY_REPORT`. This table was missing completely from validation! To account for this the following was performed:
1. A new entry added to `query.sql` to get the columns modified on the table.
```sql
...
-- 5: MORBIDITY_REPORT
SELECT
    [DAYCARE_IND],
    [DIAGNOSIS_DT],
    [DIE_FROM_ILLNESS_IND],
    [ELECTRONIC_IND],
    [FOOD_HANDLER_IND],
    [HEALTHCARE_ORG_ASSOCIATE_IND],
    [HOSPITALIZED_IND],
    [HSPTL_ADMISSION_DT],
    [JURISDICTION_CD],
    [JURISDICTION_NM],
    [MORB_RPT_CREATE_BY],
    [MORB_RPT_KEY],
    [MORB_RPT_LAST_UPDATE_BY],
    [MORB_RPT_LAST_UPDATE_DT],
    [MORB_RPT_LOCAL_ID],
    [MORB_RPT_OID],
    [MORB_RPT_OTHER_SPECIFY],
    [MORB_RPT_SHARE_IND],
    [MORB_RPT_TYPE],
    [MORB_RPT_UID],
    [NURSING_HOME_ASSOCIATE_IND],
    [PH_RECEIVE_DT],
    [PREGNANT_IND],
    [RDB_LAST_REFRESH_TIME],
    [RECORD_STATUS_CD],
    [SUSPECT_FOOD_WTRBORNE_ILLNESS]
FROM [RDB_MODERN].[dbo].[MORBIDITY_REPORT]
WHERE [MORB_RPT_LOCAL_ID] = 'OBS20100027GA01';
```
2. A new entry added to `expected.json`.
```json
...
"5": [
    {
      "DAYCARE_IND": "N",
      "DIAGNOSIS_DT": "2026-04-05T00:00:00.000",
      "DIE_FROM_ILLNESS_IND": "Y",
      "ELECTRONIC_IND": "N",
      "FOOD_HANDLER_IND": "N",
      "HEALTHCARE_ORG_ASSOCIATE_IND": "UNK",
      "HOSPITALIZED_IND": "Y",
      "HSPTL_ADMISSION_DT": "2026-04-03T00:00:00.000",
      "JURISDICTION_CD": "130001",
      "JURISDICTION_NM": "Fulton County",
      "MORB_RPT_CREATE_BY": 10009282,
      "MORB_RPT_LAST_UPDATE_BY": 10009282,
      "MORB_RPT_LAST_UPDATE_DT": "2026-04-10T20:26:11.853",
      "MORB_RPT_LOCAL_ID": "OBS20100027GA01",
      "MORB_RPT_OID": 1300100009,
      "MORB_RPT_OTHER_SPECIFY": "other something",
      "MORB_RPT_SHARE_IND": "T",
      "MORB_RPT_TYPE": "INIT",
      "MORB_RPT_UID": 20100027,
      "NURSING_HOME_ASSOCIATE_IND": "Y",
      "PH_RECEIVE_DT": "2026-04-10T00:00:00.000",
      "PREGNANT_IND": "Y",
      "RECORD_STATUS_CD": "ACTIVE",
      "SUSPECT_FOOD_WTRBORNE_ILLNESS": "N"
    }
  ]
```
3. Execute the functional test suite!