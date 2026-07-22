# Reporting Pipeline Service

## Local Dev Setup
If you don't already have a local application config create one using the existing `application.yaml`:

```shell
cp src/main/resources/application.yaml src/main/resources/application-local.yaml
```

Create a `src/main/resources/application-local.yaml` file. Sample below:

```yaml
spring:
  datasource:
    password: PizzaIsGood33!
    username: sa
    url: jdbc:sqlserver://localhost:3433;databaseName=RDB_MODERN;encrypt=true;trustServerCertificate=true;
  kafka:
    bootstrap-servers: ${KAFKA_BOOTSTRAP_SERVER:localhost:9092}
  kafka-connect:
    url: http://localhost:8083

  liquibase:
    enabled: true
    change-log: classpath:db/changelog/db.changelog-master.yaml
    user: sa
    password: PizzaIsGood33!

  featureFlag:
    person-service-direct-write: true
```

Stop the container if it is running:
```shell
docker stop nedss-datareporting-pipeline-service-1
```
Run `reporting-pipeline-service` using the following Gradle command:

```shell
./gradlew reporting-pipeline-service:bootRun --args='--spring.profiles.active=local'
```

If you would like to debug with your IDE, use the following:

```shell
./gradlew reporting-pipeline-service:bootRun --args='--spring.profiles.active=local' --debug-jvm
```

and you can attach your debugger on port `5005`.

## Actuator Endpoints

The service exposes Spring Boot Actuator on port `8095` under `/actuator`. The following endpoints are enabled:

| Endpoint | URL | Purpose |
|---|---|---|
| `health` | `/actuator/health` | Overall service health including database, connectors, and Kafka |
| `lag` | `/actuator/lag` | Kafka consumer-group backlog — how many messages each group is behind |
| `metrics` | `/actuator/metrics` | Micrometer metric names; append `/{name}` for a specific metric |
| `prometheus` | `/actuator/prometheus` | Prometheus-format metrics scrape target |
| `liquibase` | `/actuator/liquibase` | Applied Liquibase changesets and their status |

### `/actuator/health`

Aggregates several health indicators under `components`:

- **`db`** — JDBC connectivity to `RDB_MODERN`.
- **`connectors`** — checks that each Debezium source connector and each Kafka Connect JDBC sink connector is in `RUNNING` state by calling the respective Connect REST APIs.

`ping`, `diskSpace`, and `ssl` are disabled. Full component detail is always shown (`show-details: always`).

### `/actuator/lag`

A dedicated on-demand endpoint (not aggregated into `/actuator/health`) that reports how far behind the pipeline's consumer groups are from the topics they consume. Useful for verifying a seeding or migration has fully drained before running downstream queries.

Two groups are reported:

- **`pipeline`** — the application's own consumer group (`pipeline-consumer-app` by default), which processes `nbs_*` Debezium events.
- **`sink`** — the Kafka Connect JDBC sink group (`connect-Kafka-Connect-SqlServer-Sink` by default), which drains `nrt_*` topics into `RDB_MODERN`.

**Status values:**

| Status | Meaning |
|---|---|
| `READY` | Both groups are fully caught up — no backlog. |
| `PROCESSING` | At least one group has unconsumed messages. |
| `UP` + `"status": "DISABLED"` | Lag reporting is turned off (`LAG_REPORT_ENABLED=false`). |
| `DOWN` | Kafka offsets could not be read. |

Example response when caught up:

```json
{
  "status": "READY",
  "details": {
    "caughtUp": true,
    "pipeline": { "messagesQueued": 0, "byTopic": {} },
    "sink":     { "messagesQueued": 0, "byTopic": {} }
  }
}
```

Example response when the sink is still draining:

```json
{
  "status": "PROCESSING",
  "details": {
    "caughtUp": false,
    "pipeline": { "messagesQueued": 0, "byTopic": {} },
    "sink": {
      "messagesQueued": 42,
      "byTopic": { "nrt_investigation": 42 }
    }
  }
}
```

### `/actuator/prometheus`

Standard Prometheus scrape endpoint. Excludes actuator URIs from HTTP-server-request histograms (see the Grafana dashboards under `src/main/resources/grafana-dashboard/` for pre-built panels).
