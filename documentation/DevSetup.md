# Local Development Setup

![Real Time Reporting diagram](./rtr_diagram.jpeg)

## Docker Containers

1. [mssql](https://github.com/cdcent/NEDSSDB/pkgs/container/nedssdb) - Restored MSSQL Server database pre-configured to work with RTR. Notable configurations
   2. RTR User creation scripts applied
   3. Change Data Capture (CDC) enabled for relevant databases and tables
3. [kafka](../docker-compose.yaml) - Message broker
4. [kafka-connect](../docker-compose.yaml) - Reads from the `nrt_*` topics and inserts into `rdb_modern` tables. The MSSQL JDBC sink connector is registered automatically by `reporting-pipeline-service` on startup from [mssql-connector.json](../reporting-pipeline-service/src/main/resources/connectors/kafka-connect/mssql-connector.json).
5. [debezium](../docker-compose.yaml) - Reads Change Data Capture logs and posts messages to Kafka. Source connectors are registered automatically by `reporting-pipeline-service` on startup from [connectors/debezium](../reporting-pipeline-service/src/main/resources/connectors/debezium).
6. [reporting-pipeline-service](../reporting-pipeline-service/Dockerfile) - Process Kafka messages for investigation, ldf, observation, organization, and person data (also handles key-uid mappings)

### Prerequisites:

- [Docker GHCR Authentication](DockerAuth.md)

### Build and run the RTR services

```sh
docker compose up -d
```

### Running the combined stack with NEDSS-DataIngestion

To run DataReporting and NEDSS-DataIngestion together against one shared
database, Kafka cluster, and Debezium/Connect worker (rather than this repo's
standalone `docker compose up` above), check out both repos as sibling
directories under one parent folder, then from either repo run:

```bash
./scripts/nbs7-deploy.sh up
```

This starts shared MSSQL, Kafka, and Debezium/Connect once, plus both
projects' app services (`reporting-pipeline-service`, `data-ingestion-service`,
`data-processing-service`, etc.) on one Docker network. See
`docker-compose.shared.yml` and `scripts/nbs7-deploy.sh` for details, and
`scripts/nbs7-deploy.sh` with no arguments (or `down`/`ps`/`logs`/`build`) for
other commands.

### Verifying functionality

1. Log into [NBS 6](http://localhost:7003/nbs/login) using the user: `superuser`. No password is required
2. Create a new patient
3. Add an investigation to the patient
4. View `RDB_MODERN.D_PATIENT` and `RDB_MODERN.INVESTIGATION` tables and verify the newly created patient and investigation are present.

### Running SAS
A SAS container is present in the docker compose witht the `sas` profile. This means it will not start by default.

To start only the SAS container and its dependencies
```sh
docker compose up sas -d
```

To start all containers including SAS
```sh
docker compose --profile sas up -d
```

To execute the MasterETL script the following 1 liner can be used
```sh
# Executes the MasterEtl script from outside the SAS container
docker compose exec -u SAS -it sas sh -c '/opt/wildfly-10.0.0.Final/nedssdomain/Nedss/BatchFiles/MasterEtl.sh'
```

To log into the SAS container and run it from within the following steps can be taken:

```sh
# Connect to SAS container as the SAS user
docker compose exec -u SAS -it sas bash

# Run MasterEtl script
/opt/wildfly-10.0.0.Final/nedssdomain/Nedss/BatchFiles/MasterEtl.sh
```
