## Post Processing Service

### Run on Your Host Machine
The following instructions require that the Kafka and Database containers are running at a minimum. Also note that `application-local.yaml` is included in `.gitignore` so keep this file stored somewhere for reuse.

1. Create the properties file `src/main/resources/application-local.yaml` and populate with the following content:
```yaml
spring:
  kafka:
    topic:
      investigation: nrt_investigation
      observation: nrt_observation
      organization: nrt_organization
      patient: nrt_patient
      provider: nrt_provider
      notification: nrt_investigation_notification
      treatment: nrt_treatment
      case_management: nrt_investigation_case_management
      interview: nrt_interview
      ldf_data: nrt_ldf_data
      place: nrt_place
      auth_user: nrt_auth_user
      contact_record: nrt_contact
      vaccination: nrt_vaccination
      page: nrt_odse_NBS_page
      datamart: nbs_Datamart
      state_defined_field_metadata: nrt_odse_state_defined_field_metadata
      condition: nrt_srte_Condition_code
    investigation-topic:
      topic-name-phc: nbs_Public_health_case
      topic-name-ntf: nbs_Notification
      topic-name-int: nbs_Interview
      topic-name-ctr: nbs_CT_contact
      topic-name-vac: nbs_Intervention
      topic-name-tmt: nbs_Treatment
      topic-name-ar: nbs_Act_relationship
    ldf-topic:
      topic-name: nbs_state_defined_field_data
    observation-topic:
      topic-name: nbs_Observation
      topic-name-ar: nbs_Act_relationship
    organization-topic:
      topic-name: ${INPUT_TOPIC_ORGANIZATION:nbs_Organization}
      topic-name-place: ${INPUT_TOPIC_PLACE:nbs_Place}
    person-topic:
      topic-name: ${INPUT_TOPIC_PERSON:nbs_Person}
      topic-name-user: ${INPUT_TOPIC_USER:nbs_Auth_user}
    dlq:
      retry-suffix: -retry
      dlq-suffix: -dlt
      dlq-suffix-format-2: _dlt
    group-id: ${KAFKA_CONSUMER_APP:post-processing-reporting-consumer-app}
    dlt-group-id: rtr-dlt-group
    bootstrap-servers: ${KAFKA_BOOTSTRAP_SERVER:localhost:9092}
    consumer:
      max-retry: 3
      maxPollIntervalMs: 30000
      maxPollRecs: ${KAFKA_CONSUMER_MAX_POLL_RECS:200}
      maxConcurrency: 5
    admin:
      auto-create: true
  application:
    name: post-processing-reporting-service
  datasource:
    password: ${DB_PASSWORD:PizzaIsGood33!}
    username: ${DB_USERNAME:sa}
    url: ${DB_HOST:jdbc:sqlserver://localhost:3433;databaseName=RDB_MODERN;encrypt=true;trustServerCertificate=true;}
  jpa:
    properties:
      jakarta.persistence.query.timeout: -1
featureFlag:
  service-disable: ${FF_SERVICE_DISABLE:false}
service:
  fixed-delay:
    cached-ids: ${FIXED_DELAY_ID:20000}
    datamart: ${FIXED_DELAY_DM:60000}
    backfill: ${FIXED_DELAY_BF:600000}
  max-retries: ${MAX_RETRIES:3}
server:
  port: "8095"

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
3. In the root of this repository execute the following command (this service is configured to run in debug mode on port 17070 in `build.gradle` by previous dev team).
```shell
./gradlew :post-processing-service:bootRun --args='--spring.profiles.active=local'
```