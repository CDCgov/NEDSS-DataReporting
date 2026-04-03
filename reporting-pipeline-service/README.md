# Reporting Hydration Service

## Local Dev Setup
Before running `reporting-hydration-service` ensure both the database and Kafka containers are up and running:

```shell
docker compose up kafka liquibase nbs-mssql -d
```

If you don't already have a local application config create one using the existing `application.yaml`:

```shell
cp src/main/resources/application.yaml src/main/resources/application-local.yaml
```

Update `src/main/resources/application-local.yaml` with the following values:

```yaml
spring:
  datasource:
    password: reporting_hydration_service
    username: reporting_hydration_service_rdb
    url: jdbc:sqlserver://localhost:3433;databaseName=RDB_MODERN;encrypt=true;trustServerCertificate=true;
  kafka:
    bootstrap-servers: ${KAFKA_BOOTSTRAP_SERVER:localhost:9092}
```

Run `reporting-hydration-service` using the following Gradle command:

```shell
./gradlew reporting-hydration-service:bootRun --args='--spring.profiles.active=local'
```

If you would like to debug with your IDE, use the following:

```shell
./gradlew reporting-hydration-service:bootRun --args='--spring.profiles.active=local' --debug-jvm
```

and you can attach your debugger on port `5005`.