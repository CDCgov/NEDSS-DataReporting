# Local Development Setup

![Real Time Reporting diagram](./rtr_diagram.jpeg)

## Docker Containers

1. [mssql](https://github.com/cdcent/NEDSSDB/pkgs/container/nedssdb) - Restored MSSQL Server database pre-configured to work with RTR. Notable configurations
   1. NBS_ODSE.NBS_Configuration entry added with `config_key = 'ENV'`, `config_value = 'UAT'`
   2. RTR User creation scripts applied
   3. Change Data Capture (CDC) enabled for relevant databases and tables
2. [liquibase](../liquibase-service/Dockerfile.local) - Liquibase container with all migration scripts copied from `../liquibase-service/src/main/resources/db/`. Configured to automatically apply migrations and 1 time onboarding scripts and then close. Entrypoint: [migrate.sh](../containers/liquibase/migrate.sh)
3. [kafka](../docker-compose.yaml) - Message broker
4. [kafka-connect](../containers/kafka-connect/Dockerfile) - Reads from the `nrt_*` topics and inserts into `rdb_modern` tables. Requires POST of [mssql-connector.json](../containers/kafka-connect/initialize/mssql-connector.json) after container start up.
5. [debezium](../docker-compose.yaml) - Reads Change Data Capture logs and posts messages to Kafka. Requires POST for each connector to be sent after container start up.
6. [reporting-pipeline-service](../reporting-pipeline-service/Dockerfile) - Process Kafka messages for investigation, ldf, observation, organization, and person data (also handles key-uid mappings)

### Prerequisites:

- [Docker GHCR Authentication](DockerAuth.md)

### Build and run the RTR services

```sh
docker compose up -d
```

### Populate RDB_DATE
Currently, the stored procedure that populates `RDB_DATE` on RDB_MODERN does not work and is not expected for STLT use. However, for local development we need this table to have the same records as legacy RDB. This is an important step because there are datamarts and other tables that are dependent on the `RDB_DATE` table.

1. In the SAS container execute `MasterEtl` if you haven't already done so at least once.
2. On your local RDB_MODERN database execute the following sql
```sql
INSERT INTO RDB_MODERN.dbo.RDB_DATE (DATE_MM_DD_YYYY, DAY_OF_WEEK, DAY_NBR_IN_CLNDR_MON, DAY_NBR_IN_CLNDR_YR,
                                    WK_NBR_IN_CLNDR_MON, WK_NBR_IN_CLNDR_YR, CLNDR_MON_NAME, CLNDR_MON_IN_YR,
                                    CLNDR_QRTR, CLNDR_YR, DATE_KEY)
SELECT src.DATE_MM_DD_YYYY, src.DAY_OF_WEEK, src.DAY_NBR_IN_CLNDR_MON, src.DAY_NBR_IN_CLNDR_YR,
       src.WK_NBR_IN_CLNDR_MON, src.WK_NBR_IN_CLNDR_YR, src.CLNDR_MON_NAME, src.CLNDR_MON_IN_YR,
       src.CLNDR_QRTR, src.CLNDR_YR, src.DATE_KEY
FROM RDB.dbo.RDB_DATE src
WHERE NOT EXISTS (
  SELECT 1
  FROM RDB_MODERN.dbo.RDB_DATE tgt
  WHERE tgt.DATE_KEY = src.DATE_KEY
);
  ```
3. Verify `RDB_MODERN.dbo.RDB_DATE` contains the same number of records as `RDB.dbo.RDB_DATE`.
```sql
SELECT COUNT(*) FROM RDB.dbo.RDB_DATE;
SELECT COUNT(*) FROM RDB_MODERN.dbo.RDB_DATE;
```

### Verifying functionality

1. Log into [NBS 6](http://localhost:7003/nbs/login) using the user: `superuser`. No password is required
2. Create a new patient
3. Add an investigation to the patient
4. View `RDB_MODERN.D_PATIENT` and `RDB_MODERN.INVESTIGATION` tables and verify the newly created patient and investigation are present.