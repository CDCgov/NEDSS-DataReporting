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
(default 6) — the same 4-minute ceiling the Java `Await` helper uses.

## Setup

```sh
cd testing-tools/functional-test
uv sync
```

## Usage

```sh
uv run functional-test -S <address> -U <user> -P <password> -d <data_dir> [-t <test> ...]
```

The connection flags follow `sqlcmd` conventions:

| Flag | Long form | Required | Description |
| ---- | --------- | -------- | ----------- |
| `-S` | `--server` | yes | Database address: `host`, `host:port` or `host,port` (e.g. `localhost:3433`). |
| `-U` | `--user` | yes | Database user (needs write on `NBS_ODSE`, read on `RDB_MODERN`). |
| `-P` | `--password` | no | Password. If omitted, read from the `FUNCTIONAL_TEST_DB_PASSWORD` env var. |
| `-d` | `--data-dir` | yes | The `testData/functional` directory. |
| `-t` | `--test` | no | A test name to run. Repeat `-t` to run several. If omitted, all tests run. |
| `-i` | `--id` | no | Override the test's starting UID; all IDs are shifted on the fly. Requires exactly one `-t`. |

### Examples

Run every test against a local dev instance:

```sh
uv run functional-test -S localhost:3433 -U rtr_admin -P rtr_admin \
    -d ../../reporting-pipeline-service/src/test/resources/testData/functional
```

Run two specific tests, keeping the password out of the command line:

```sh
export FUNCTIONAL_TEST_DB_PASSWORD=rtr_admin
uv run functional-test -S localhost:3433 -U rtr_admin \
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
| `--list` | off | List discovered tests and exit (no DB connection). |

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
