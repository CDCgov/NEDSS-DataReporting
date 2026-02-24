## Observation Service

### Run on Your Host Machine
The following instructions require that the Kafka and Database containers are running at a minimum. Also note that `application-local.yaml` is included in `.gitignore` so keep this file stored somewhere for reuse.

1. Create the properties file `src/main/resources/application-local.yaml` and populate with the following content:
```yaml
spring:
  kafka:
    input:
      topic-name: nbs_Observation
      topic-name-ar: nbs_Act_relationship
    output:
      topic-name-reporting: nrt_observation
      topic-name-coded: nrt_observation_coded
      topic-name-date: nrt_observation_date
      topic-name-edx: nrt_observation_edx
      topic-name-material: nrt_observation_material
      topic-name-numeric: nrt_observation_numeric
      topic-name-reason: nrt_observation_reason
      topic-name-txt: nrt_observation_txt
    dlq:
      retry-suffix: _retry
      dlq-suffix: _dlt

    bootstrap-servers: ${KAFKA_BOOTSTRAP_SERVER:localhost:9092}
    group-id: ${KAFKA_CONSUMER_APP:observation-reporting-consumer-app}
    consumer:
      max-retry: 3
      maxPollIntervalMs: 30000
      maxPollRecs: ${KAFKA_CONSUMER_MAX_POLL_RECS:200}
    admin:
      auto-create: true
  application:
    name: observation-reporting-service
  datasource:
    password: ${DB_PASSWORD:PizzaIsGood33!}
    username: ${DB_USERNAME:sa}
    url: ${DB_HOST:jdbc:sqlserver://localhost:3433;databaseName=NBS_ODSE;encrypt=true;trustServerCertificate=true;}
  liquibase:
    change-log: db/changelog/db.changelog-master.yaml
featureFlag:
  thread-pool-size: ${FF_THREAD_POOL_SIZE:1}
server:
  port: "8094"

management:
  endpoint:
    prometheus:
      access: read_only
  endpoints:
    web:
      exposure:
        include: health,info,metrics,prometheus
  prometheus:
    metrics:
      export:
        enabled: true

```
2. Ensure the `kafka` and `rtr-mssql` containers running. <em>You likely want all your RTR containers running for complete testing!</em>
```shell
docker ps -a -f "name=kafka$" -f "name=rtr-mssql$"
```
3. In the root of this repository execute the following command so the service uses `application-local.yaml`.
```shell
./gradlew :observation-service:bootRun --args='--spring.profiles.active=local'
```
4. (Optional) Run the service in debug mode.
```shell
./gradlew :observation-service:bootRun --args='--spring.profiles.active=local' --debug-jvm
```