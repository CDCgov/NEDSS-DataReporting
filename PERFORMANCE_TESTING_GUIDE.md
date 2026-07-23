# NBS7 Local Suite: Deployment, ELR Generation, and Performance Testing

This guide covers standing up the full combined `NEDSS-DataIngestion` +
`NEDSS-DataReporting` + `NEDSS-Modernization` (if checked out) stack locally,
generating synthetic ELR test data, and running/observing a performance test
- all without needing a shared environment or a Prometheus/Grafana instance.

This file is intentionally duplicated (kept byte-identical) in
`NEDSS-DataReporting/PERFORMANCE_TESTING_GUIDE.md` and
`NEDSS-Modernization/PERFORMANCE_TESTING_GUIDE.md`. If you update it, please
mirror the change in the other two repos' copies.

## 1. Prerequisites

- Docker + Docker Compose v2
- The repos checked out as **sibling directories** under one common parent
  folder, e.g.:
  ```
  ~/dev/nbs7/
    NEDSS-DataIngestion/
    NEDSS-DataReporting/
    NEDSS-Modernization/      (optional - included automatically if present)
  ```
- Python 3.9+ (for the ELR generation/ingest tool and the metrics script)
- Microsoft ODBC Driver 17 for SQL Server - optional, only needed for
  `--check-status` on the ingest tool and the database checks in
  `nbs7_metrics.py`

## 2. Deploy the full nbs7 suite locally

```bash
./scripts/nbs7-deploy.sh up
```

Run from any of the three repos' root - it drives each checked-out repo's
`docker-compose.shared.yml` together as one Compose project (`nbs7`).
`NEDSS-Modernization` is included automatically if its directory is present
as a sibling checkout, and silently skipped otherwise - the
DataIngestion+DataReporting-only workflow keeps working unchanged if you
don't have it cloned. Add `--build` to rebuild images, `--sas` to also start
the SAS container.

This starts: shared MSSQL (serving all projects' databases), shared Kafka,
shared Debezium/Kafka Connect, shared Keycloak, and every checked-out
project's app services - `data-ingestion-service`, `data-processing-service`,
`reporting-pipeline-service`, `di-record-linker`, `wildfly`, and (if
`NEDSS-Modernization` is present) `modernization-api`, `nbs-gateway`,
`pagebuilder-api`, `report-execution` - all on one Docker network
(`nbs7-shared`).

Useful endpoints (printed on startup):

| Service | URL |
| --- | --- |
| NBS 6 (Wildfly) | http://localhost:7003/nbs/login |
| Keycloak | http://localhost:8100 |
| data-ingestion-service | http://localhost:8081/ingestion/swagger-ui/index.html |
| data-processing-service | http://localhost:8082/rti/swagger-ui/index.html |
| reporting-pipeline-service | http://localhost:8095 |
| Kafka Connect (JDBC sink) | http://localhost:8083/connectors |
| Debezium (CDC source) | http://localhost:8085/connectors |
| Shared MSSQL | `localhost:3433` (alias `localhost:2433`), `sa` / `DATABASE_PASSWORD` (default `fake.fake.fake.1234`) |
| nbs-gateway *(if NEDSS-Modernization present)* | http://localhost:8000 |
| modernization-api *(if NEDSS-Modernization present)* | http://localhost:8080/swagger-ui/index.html |
| pagebuilder-api / question-bank *(if NEDSS-Modernization present)* | http://localhost:8096 (remapped from its own default 8095 - that port is already `reporting-pipeline-service`'s) |
| report-execution *(if NEDSS-Modernization present)* | http://localhost:8001 |

Other commands: `down [--volumes]`, `restart [--build] [--sas]`, `ps`,
`logs [service...]`, `build`, `register-connectors`.

### Known gotcha: Debezium connectors after an MSSQL restart

If the `nbs-mssql` container restarts (host reboot, manual restart, resource
pressure, etc.), the ODSE-facing Debezium source connectors
(`odse-main-connector`, `odse-schema-only-connector`, `odse-meta-connector`)
can come back with the *connector* marked `RUNNING` but the underlying *task*
`FAILED` - and they do not self-heal.

**Symptom:** `reporting-pipeline-service`'s domain counters
(`person_msg_processed_total`, etc.) stop moving entirely even though
ingestion (RTI) is completing successfully, while `/actuator/lag` still
reports `READY` / `caughtUp: true`. That's misleading here - a dead source
connector simply means there's nothing new arriving to lag behind, so it
looks identical to "caught up, all good."

Check connector/task health directly:
```bash
curl -s http://localhost:8085/connectors/odse-main-connector/status | python3 -m json.tool
```
If a task shows `FAILED`, restart it:
```bash
curl -X POST http://localhost:8085/connectors/odse-main-connector/restart
# or just the failed task:
curl -X POST http://localhost:8085/connectors/odse-main-connector/tasks/0/restart
```

### Known gaps: NEDSS-Modernization integration

This integration pass wires `modernization-api`, `nbs-gateway`,
`pagebuilder-api` (question-bank), and `report-execution` against the
*existing* shared `nbs-mssql` (`NBS_ODSE`) and *existing* shared
`di-keycloak` - it does not start a second database or auth server. Two
things are intentionally incomplete, see
`NEDSS-Modernization/docker-compose.shared.yml` for the full rationale:

- **Auth realm mismatch.** `modernization-api`/`pagebuilder-api`/
  `nbs-gateway` default to Keycloak realm `nbs-users` (per
  `NEDSS-Modernization/sample.env`), but the shared `di-keycloak` container
  only imports realm `NBS`. `NBS_SECURITY_OIDC_URI` is pointed at the `NBS`
  realm instead, but OIDC itself stays **disabled by default**
  (`NBS_SECURITY_OIDC_ENABLED=false`, matching `NEDSS-Modernization`'s own
  default) since it's unverified whether realm `NBS`'s client/role config is
  actually compatible with what `modernization-api` expects. Flip it on and
  test before relying on it.
- **No Elasticsearch/Kibana/NiFi.** `NEDSS-Modernization`'s own
  `cdc-sandbox/docker-compose.yml` includes these; this integration
  deliberately leaves them out for now. `modernization-api` will still boot
  (its Elasticsearch connection appears to be used on-demand for search
  requests, not required at startup), but patient/case search features that
  depend on it will fail at request time. Add them to
  `NEDSS-Modernization/docker-compose.shared.yml` as a follow-up if/when
  search needs testing.

## 3. Liquibase across all three repos

Each repo's Liquibase migrations target a **different database** on the
shared `nbs-mssql` instance, so there is no `DATABASECHANGELOG`
collision risk between them today, even though all three independently
converged on the same generic `author: liquibase` + small-integer-id
convention (Liquibase's actual uniqueness key is `id + author + changelog
file path`, and each repo's changelog files are entirely disjoint from the
others):

| Repo | Service | Target database | Liquibase config |
| --- | --- | --- | --- |
| DataIngestion | `data-ingestion-service` | `NBS_DATAINGEST` + `NBS_MSGOUTE` (two independent `SpringLiquibase` beans, custom `LiquibaseConfig.java`) | `db/changelog/dataingest-changelog.yaml` (4 changesets), `db/changelog/msgoute-changelog.yaml` (12 changesets) |
| DataReporting | `reporting-pipeline-service` | `RDB_MODERN` only (standard Spring Boot auto-config) | `db/changelog/db.changelog-master.yaml` -> `includeAll` of `migrations/v7.13/rdb/*.yaml` (387 changesets) |
| Modernization | `modernization-api` | `NBS_ODSE` only (two independent `SpringLiquibase` beans, custom `LiquibaseConfig.java`) | `db/changelog/odse-changelog.yml` (1 changeset), `db/changelog/report-execution-changelog.yml` (1 changeset chaining 31 `sqlFile` scripts, gated behind the `nbs.ui.features.report.execution.enabled` flag - enabled by default in `docker-compose.shared.yml` so `report-execution`'s tables actually get created) |

No two repos target the same database, so each app's `DATABASECHANGELOG` /
`DATABASECHANGELOGLOCK` tracking tables live in `dbo` of a database none of
the others touch - they can run concurrently at stack startup with no
coordination needed beyond each depending on `nbs-mssql: condition:
service_healthy` (already the case for all of them). If a future repo/service
ever needs to add Liquibase migrations against `NBS_ODSE`, `NBS_MSGOUTE`, or
`NBS_DATAINGEST` (the databases already claimed above), give its changesets a
distinct changelog filename (Liquibase's real uniqueness boundary) and prefer
ticket-scoped ids/authors over the bare `1, 2, 3...` / `liquibase` convention
used everywhere today, to make any future cross-repo migration history easier
to reason about.

Separately, note that `NBS_ODSE` is now written to by *three* different
concurrent writers under load - `data-processing-service` (RTI, the subject
of the deadlock-storm bug in APP-884), `reporting-pipeline-service` (CDC
reads only, not a writer), and now `modernization-api`/`report-execution`
(day-to-day UI reads/writes). That's a data-contention consideration, not a
Liquibase one - worth keeping in mind if deadlock-storm testing (section 4)
is ever run with `modernization-api` also live and in active use.

## 4. Generate ELRs

The `nbs7-e2e-elr-ingest` CLI (`testing-tools/e2e-elr-ingest/`) generates
synthetic HL7 v2.5.1 ELRs and/or ingests existing ones through the full auth
chain (Keycloak -> data-processing-service -> data-ingestion-service).

Setup:
```bash
cd testing-tools/e2e-elr-ingest
python3 -m venv .venv
source .venv/bin/activate
pip install -e .
pip install -e ".[db]"   # optional: needed for --check-status
```

Generate + ingest in one step:
```bash
python main.py --input-dir ./generated --generate 1000
```
This generates 1,000 fake HL7 ELRs into `./generated`, normalizes their
segment terminators into a sibling `./generated-formatted` directory,
authenticates through the two-hop token chain, and submits each file to
`data-ingestion-service` - automatically refreshing and retrying once if a
token gets rejected mid-run.

Ingest existing files instead of generating:
```bash
python main.py --input-dir /path/to/existing/hl7/files
```

Every host/port/credential defaults to the local `nbs7-deploy.sh` stack and
can be overridden via `.env` (copy `.env.example`), real environment
variables, or CLI flags - see `testing-tools/e2e-elr-ingest/README.md` for
the full flag reference and a detailed explanation of the auth flow.

(This tool lives only in `NEDSS-DataIngestion` and `NEDSS-DataReporting` -
it's specific to the ELR ingestion pipeline those two repos own, so it isn't
duplicated into `NEDSS-Modernization`.)

## 5. Execute performance testing

Combine ELR generation with `scripts/nbs7_metrics.py` to run and observe a
load test without standing up Prometheus/Grafana.

### Basic flow

```bash
# 1. Baseline snapshot before the run
python3 scripts/nbs7_metrics.py snapshot --out baseline.json

# 2. Generate + ingest a large batch
cd testing-tools/e2e-elr-ingest
python main.py --input-dir ./perf-batch --generate 20000
cd ../..

# 3. Watch it drain through data-processing-service and reporting-pipeline-service
python3 scripts/nbs7_metrics.py watch-drain

# 4. Compare against the baseline once drained
python3 scripts/nbs7_metrics.py diff --baseline baseline.json
```

`watch-drain` accepts `--interval` (seconds between checks, default 30),
`--consecutive` (drained checks required before declaring done, default 3),
and `--stall-after` (checks with no progress before warning, default 10).

### What `watch-drain` checks

Polls `NBS_interface.record_status_cd` (specifically `RTI_PENDING`) in
`NBS_MSGOUTE` and `reporting-pipeline-service`'s `/actuator/lag`, declaring
the batch fully drained once `RTI_PENDING` reaches 0 and Kafka lag is caught
up, held across several consecutive checks.

It also detects the specific stall failure mode found during APP-850
performance testing (see **APP-884**, reproduced twice): if `RTI_PENDING`
stops changing for several checks while still > 0, that's not "slow" - it's
a silently stalled async processing queue, triggered by a SQL Server
deadlock storm concentrated on `NBS_ODSE.EDX_activity_log` under concurrent
load. If you see this warning, check `data-processing-service` logs for
`SQLState: 40001` / "chosen as the deadlock victim" errors around the time
progress stopped, and see APP-884 for the full reproduction recipe.

### What "healthy" looks like

- `NBS_interface`: everything reaches `RTI_SUCCESS` (a handful of
  pre-existing `RTI_FAILURE_STEP_1`/`Failure`/`QUEUED` rows are normal
  baseline noise; a small number of new failures per run is expected
  data-quality noise in synthetic samples, not necessarily a bug)
- `RDB_MODERN.nrt_dead_letter_log` / `nrt_backfill`: no growth
- HikariCP (`reporting-pipeline-service`): 0 pending, 0 timeouts throughout
- `reporting-pipeline-service` domain counters (`person_msg`, `org_msg`,
  `obs_msg`, `post_msg`): failure counters stay at 0, processed counters
  climb roughly in line with the batch size

### Interpreting a stall (no reporting-side movement)

If ingestion (RTI) succeeds but `reporting-pipeline-service`'s counters never
move, don't assume it's just slow - check Debezium connector/task status
directly (see the gotcha in section 2). `/actuator/lag` alone can look
"caught up" even when the underlying CDC source is completely dead.

## Reference

- `scripts/nbs7-deploy.sh` - stack orchestrator (duplicated identically in all three repos)
- `scripts/nbs7_metrics.py` - metrics polling: `snapshot` / `diff` / `watch-drain` (duplicated identically in all three repos)
- `testing-tools/e2e-elr-ingest/` - ELR generation/ingestion CLI (duplicated identically in DataIngestion and DataReporting only)
- Findings referenced above (the deadlock-driven async stall, the Debezium connector recovery gap) are documented in detail on APP-850 and APP-884.
