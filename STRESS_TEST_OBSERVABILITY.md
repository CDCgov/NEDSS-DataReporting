# Stress Testing `reporting-pipeline-service`: What to Watch

Context: load-testing the pipeline (Debezium → Kafka → `reporting-pipeline-service` →
Kafka Connect JDBC sink → SQL Server) to check for data loss from insufficient
concurrency guard rails. No standalone Prometheus is deployed; Rancher is the
container platform. This documents what's already available in the existing
toolset, grounded in the current code/config.

## 1. The service already exports Prometheus metrics — no Prometheus server required to use them

`reporting-pipeline-service/src/main/resources/application.yaml` sets:

```yaml
management:
  endpoints:
    web:
      exposure:
        include: health,metrics,prometheus,liquibase,lag
  prometheus:
    metrics:
      export:
        enabled: true
```

So the running service (port `8095`) already serves `GET /actuator/prometheus`
in plain-text exposition format. You can scrape it by hand during the load run:

```bash
watch -n2 'curl -s localhost:8095/actuator/prometheus | grep -E "hikaricp_connections|jvm_memory_used|jvm_threads_live"'
```

Or stand up a throwaway Prometheus + Grafana pointed at it and reuse the
dashboards **already checked into the repo**:
`reporting-pipeline-service/src/main/resources/grafana-dashboard/*.json`
(`person`, `organization`, `investigation`, `observation`, `ldfdata`,
`postprocessing`). They're wired to an `aws-prometheus` datasource UID for
prod — swap that UID for a local one and the panels render as-is.

### Metrics that matter most for the concurrency hypothesis

- **`hikaricp_connections_active` / `hikaricp_connections_idle` /
  `hikaricp_connections_pending` / `hikaricp_connections_timeout_total`** —
  the likely smoking gun. No `spring.datasource.hikari.maximum-pool-size` is
  set anywhere, so it runs the Spring Boot default (10 connections). Every
  domain service spins up its **own** `Executors.newFixedThreadPool` doing
  synchronous JDBC/stored-proc calls against that one shared pool:

  | Service | Executors |
  |---|---|
  | `PersonService` | `rtrExecutor` (`nproc*2`), `prsExecutor` (`featureFlag.thread-pool-size`) |
  | `OrganizationService` | `rtrExecutor` (`nproc*2`), `org` pool (`thread-pool-size`) |
  | `InvestigationService` | `phc` pool (`nProc*2`), `inv` pool (`thread-pool-size`) |
  | `ObservationService` | `obs` pool (`thread-pool-size`) |
  | `LdfDataService` | `ldf` pool (`thread-pool-size`) |
  | `ProcessDatamartData` | `dynDmExecutor` (`nProc`) |

  If `hikaricp_connections_pending > 0` and `hikaricp_connections_timeout_total`
  climbs during the load test, that confirms the connection pool as the
  concurrency bottleneck.

- **`jvm_memory_used_bytes` / `jvm_gc_pause_seconds`** — `Executors.newFixedThreadPool`
  backs onto an **unbounded** `LinkedBlockingQueue`. There's no bound tying
  queued work to consumer throughput, so under sustained high volume the queue
  can grow without limit. A memory climb followed by a crash, with Kafka lag
  looking fine right up until the crash, is the signature of this.

- **Per-domain counters/timers** — e.g. `person_msg_processed`,
  `person_msg_success`, `person_msg_failure`, `inv_msg_failure_total`,
  `post_dm_success`, `post_dm_failure`, `*_msg_processing_seconds`. Diff
  processed vs. success vs. failure to spot silent drops.

## 2. The custom `/actuator/lag` endpoint

`gov.cdc.nbs.report.pipeline.lag.LagEndpoint` reports real-time backlog for
both the pipeline consumer group and the Kafka Connect sink group, with a
per-topic breakdown:

```bash
curl -s localhost:8095/actuator/lag | jq
```

Status is `READY` when both groups are caught up, `PROCESSING` otherwise.
Poll this on an interval during the load test:

- Sink group lag growing while the pipeline group stays caught up → the JDBC
  sink connector (writing to SQL Server) is the bottleneck.
- Pipeline group lag growing → the service's own thread pools/DB contention
  are the bottleneck.

## 3. Kafka / Kafka Connect layer (no extra tooling needed)

- From inside the `kafka` container:
  ```bash
  kafka-consumer-groups.sh --bootstrap-server kafka:29092 --describe --group pipeline-consumer-app
  kafka-consumer-groups.sh --bootstrap-server kafka:29092 --describe --group connect-Kafka-Connect-SqlServer-Sink
  ```
  Same data as `/actuator/lag` but per-partition, straight from the source.
- Kafka Connect REST API for connector/task health:
  ```bash
  curl -s localhost:8083/connectors/<name>/status | jq   # JDBC sink
  curl -s localhost:8085/connectors/<name>/status | jq   # Debezium source
  ```
  A task going `FAILED` (not just lagging) is a distinct data-loss mode from
  consumer-side loss — worth ruling out separately.
- Retry/DLT topics (from `spring.kafka.dlq.retry-suffix` / `dlq-suffix` in
  `application.yaml`): consume `*_retry` / `*_dlt` topics directly with
  `kafka-console-consumer` to see exactly which payloads are dying, correlated
  with `nrt_dead_letter_log`.

## 4. SQL Server side — the three tables plus DMVs

- **`nrt_dead_letter_log`** — columns: `origin_topic`, `payload_key`,
  `payload`, `original_consumer_group`, `exception_stack_trace`,
  `exception_message`, `exception_fqcn`, `exception_cause_fqcn`,
  `received_at`. Query the rate of growth during the load window
  (`COUNT(*) GROUP BY DATEPART(minute, received_at)`), and group by
  `exception_fqcn` — failures clustering around one exception type (timeout
  vs. deadlock vs. constraint violation) points to very different root causes.
- **`nrt_backfill`** — columns: `entity`, `record_uid_list`, `batch_id`,
  `err_description`, `status_cd`, `retry_count`. Watch for rows stuck at high
  `retry_count` with a non-terminal `status_cd` — that's the backfill-retry
  path failing to keep up, a second concurrency-guardrail symptom distinct
  from the DLQ.
- **`job_flow_log`** — correlate stored-proc start/end/failure timestamps
  against the HikariCP pending/timeout spikes above. If proc executions start
  queuing or timing out at the same moment `hikaricp_connections_pending`
  spikes, that directly implicates the shared connection pool.
- **SQL Server DMVs** — none of the above show lock contention directly:
  ```sql
  SELECT * FROM sys.dm_exec_requests;
  SELECT * FROM sys.dm_os_waiting_tasks;
  SELECT * FROM sys.dm_exec_session_wait_stats
    WHERE wait_type IN ('THREADPOOL','LCK_M_X','RESOURCE_SEMAPHORE');
  ```
  These distinguish connection-pool starvation, row/table lock contention
  (plausible since multiple threads across multiple executors may hit the
  same stored procs concurrently for related entities), and SQL Server
  worker-thread starvation.

## 5. Rancher (in place of Prometheus/Grafana-as-infra)

Rancher's built-in cluster monitoring UI (project/workload metrics view) gives
per-pod CPU, memory, and **restart count** without a dedicated Prometheus.
Watch `reporting-pipeline-service`'s memory graph and restart count during the
load test:

- Restart correlated with a memory climb → corroborates the unbounded-queue
  hypothesis above.
- Restart with flat memory but Kafka rebalance activity → points elsewhere,
  e.g. a health/liveness probe failing due to blocked DB calls.

## Suggested sequence

1. Watch `/actuator/lag` and Rancher pod memory/restarts live — cheapest signals.
2. If memory climbs unbounded, pull `/actuator/prometheus` for
   `hikaricp_connections_pending` / `hikaricp_connections_timeout_total` to
   confirm pool exhaustion is the trigger.
3. Cross-reference timestamps against `nrt_dead_letter_log` and
   `job_flow_log` to identify which entity/stored-proc path is actually
   dropping or failing data.
