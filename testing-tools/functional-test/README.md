# functional-test

Run the reporting-pipeline **functional tests** against an **already-running**
database and application — for example a local or shared dev instance — instead
of spinning up the full Testcontainers stack.

This is a Python port of the test loop in
`reporting-pipeline-service/src/test/java/.../functional/DataDrivenFunctionalTests.java`.
It uses the same `testData/functional` directories, so the tests stay in sync
with the Java suite.

## How it works

For every selected test directory, in alphabetical step order:

1. Execute the step's `setup.sql` against the source database. The script
   begins with `USE [NBS_ODSE];` and inserts the source records the pipeline
   will process.
2. Split `query.sql` on `;` (dropping `--` comment lines) and, for each query,
   poll the reporting database until the rows returned match the corresponding
   entry in `expected.json`.
3. Matching is **lenient** (the same as Jackson + JSONAssert `LENIENT` in the
   Java tests): objects may have extra columns, and result arrays are unordered
   and may contain extra rows — every expected row just has to match some
   actual row. Dates are normalized to `yyyy-MM-ddTHH:mm:ss.SSS`.

A single database connection is used for both writes and reads: `setup.sql`
switches database with `USE [...]`, and every query uses three-part
`[RDB_MODERN].[dbo].[...]` names, so cross-database reads work from the same
connection (this mirrors the Java `adminClient`).

Because the pipeline is asynchronous, each query is retried up to
`--max-retry` times (default 40) with `--retry-delay` seconds between attempts
(default 6) — the same 4-minute ceiling the Java `Await` helper uses. This bounds
the run: it never waits indefinitely.

A test's steps run in order and each builds on the previous one's state, so the
first failing query stops the rest of that test (remaining queries in the step
and all later steps are skipped). Other tests still run — use `--fail-fast` to
stop the whole run at the first failing test instead.

## Setup

```sh
cd testing-tools/functional-test
uv sync
```

## Usage

```sh
uv run functional-test -d <data_dir> [-S <address>] [-U <user>] [-P <password>] [-t <test> ...]
```

The connection flags follow `sqlcmd` conventions. Only `-d` is required —
`-S`/`-U`/`-P` default to values read from a `.env` file (see below).

| Flag | Long form | Required | Description |
| ---- | --------- | -------- | ----------- |
| `-S` | `--server` | no | Database address: `host`, `host:port` or `host,port`. Defaults to `DATABASE_SERVER,DATABASE_PORT` (else `localhost,3433`). |
| `-U` | `--user` | no | Database user (needs write on `NBS_ODSE`, read on `RDB_MODERN`). Defaults to `DATABASE_USERNAME`. |
| `-P` | `--password` | no | Password. Defaults to `DATABASE_PASSWORD`. |
| `-d` | `--data-dir` | yes | The `testData/functional` directory. |
| `-t` | `--test` | no | A test name to run. Repeat `-t` to run several. If omitted, all tests run. |
| `-i` | `--id` | no | Override the test's starting UID; all IDs are shifted on the fly. Requires exactly one `-t`. |
| `-s` | `--shift-id` | no | Shift every test's UIDs by this integer delta on the fly. Works with any number of tests. Mutually exclusive with `-i`. |

### Connection defaults from `.env`

The connection settings are read from a `.env` file using the **same variable
names as the `local-db-tracing` tools**, so one `.env` configures both:

| Variable | Default | Used for |
| -------- | ------- | -------- |
| `DATABASE_SERVER` | `localhost` | host portion of `-S` |
| `DATABASE_PORT` | `3433` | port portion of `-S` |
| `DATABASE_USERNAME` | — | `-U` |
| `DATABASE_PASSWORD` | — | `-P` |

The `.env` is located by walking up from the current directory (then from the
tool's own location). Real environment variables override `.env` values, and
explicit `-S`/`-U`/`-P` flags override both.

### Examples

Run every test against a local dev instance (explicit connection flags):

```sh
uv run functional-test -S localhost:3433 -U rtr_admin -P rtr_admin \
    -d ../../reporting-pipeline-service/src/test/resources/testData/functional
```

Run two specific tests, taking connection details from `.env` (a `.env` with
`DATABASE_SERVER` / `DATABASE_USERNAME` / `DATABASE_PASSWORD` is enough):

```sh
uv run functional-test \
    -d ../../reporting-pipeline-service/src/test/resources/testData/functional \
    -t interview -t elrEColi
```

Run the `interview` test but shift its UID block to start at `1000014000`
(useful for running against a dev instance that already contains the original
range — the files on disk are left unchanged):

```sh
uv run functional-test -S localhost:3433 -U rtr_admin -P rtr_admin \
    -d ../../reporting-pipeline-service/src/test/resources/testData/functional \
    -t interview -i 1000014000
```

The original starting ID is detected as the low end of the largest contiguous
block of `DECLARE @... bigint = N;` literals in the test's `setup.sql` files
(shared IDs such as the superuser are excluded). Every reference to a block ID
in `setup.sql`, `query.sql` and `expected.json` is shifted by the same offset,
including IDs embedded in strings like `PSN1000004000GA01`.

To shift by a relative delta instead of an absolute start — which also works
when running several tests at once — use `-s`. Each test's block is detected
independently and shifted by the same delta:

```sh
uv run functional-test \
    -d ../../reporting-pipeline-service/src/test/resources/testData/functional \
    -t interview -t morbidityReport -s 100000
```

List the discovered tests without connecting:

```sh
uv run functional-test -S localhost:3433 -U rtr_admin \
    -d ../../reporting-pipeline-service/src/test/resources/testData/functional --list
```

### Options

| Option | Default | Description |
| ------ | ------- | ----------- |
| `--database` | `NBS_ODSE` | Initial database for the connection. |
| `--max-retry` | `40` | Maximum polls per query before failing. |
| `--retry-delay` | `6` | Seconds between polls. |
| `--fail-fast` | off | Stop after the first failing test. |
| `--debug` | off | Live-print each query's SQL and its expected vs actual results on every poll attempt. |
| `--list` | off | List discovered tests and exit (no DB connection). |

Failures are printed **live** — the moment a query exhausts its retries, not at
the end of the run. By default a failed query reports only which query failed
(and any error).

With `--debug`, each query additionally prints its SQL and its expected vs
actual JSON **on every poll attempt** — so you can watch a slow or failing
query's data change across retries instead of waiting for the timeout. This is
the fastest way to see *why* a query isn't matching.

The process exits `0` when all tests pass, `1` when any test fails, and `2` on
a usage/connection error.

## Development

Run the unit tests (they exercise the comparison, SQL splitting, discovery,
polling and CLI logic — no database required):

```sh
uv run pytest
```

## Notes

- `setup.sql` performs raw `INSERT`s. Running the same test twice against a
  persistent dev instance can fail on duplicate keys — the setup error is
  reported per step. Reset the relevant rows (see `shift_test_ids.py` and the
  ID ranges in `testData/functional/README.md`) between runs if needed.
- The application under test must be running and connected to the same
  databases so it can process the inserted source data into `RDB_MODERN`.
