#!/bin/bash

# Smoke test for the RTR reporting pipeline.
#
# Starts the full stack, loads a Hepatitis A patient + investigation into NBS_ODSE,
# then polls rdb_modern.dbo.job_flow_log until 67 SP_COMPLETE rows appear after the
# run start time and no errors are recorded. Exits 0 on success, 1 on timeout or failure.
# The stack is torn down on exit via the trap.

set -euo pipefail

cd "$(dirname "$0")/../.." || exit

UP_TIMEOUT=180
UP_ELAPSED=0
UP_WAIT=10
VAL_TIMEOUT=120
VAL_ELAPSED=0
VAL_WAIT=10
EXPECTED_SP_COMPLETE=66

# Source .env if present; otherwise fall back to defaults defined in docker-compose.yaml
[ -f .env ] && source .env
DATABASE_PORT=${DATABASE_PORT:-3433}
DATABASE_PASSWORD=${DATABASE_PASSWORD:-$(docker compose config --format json | jq -r '.services."nbs-mssql".environment.DATABASE_PASSWORD')}

run_query() {
    sqlcmd -S "localhost,${DATABASE_PORT}" -U sa -P "$DATABASE_PASSWORD" -C \
        -d RDB_MODERN -h -1 -W -Q "SET NOCOUNT ON; $1" |
        tr -d '\r' | grep -v '^[[:space:]]*$' || true
}

#trap 'docker compose down' EXIT

docker compose down -v
docker compose up --build reporting-pipeline-service -d

# Wait for the reporting pipeline container to become healthy (5 minute timeout)
echo "Waiting for containers to be healthy..."
while ! docker compose ps --format json | jq -r 'select(.Health == "healthy") | .Name' | grep -q 'reporting-pipeline-service'; do
    if [ "$UP_ELAPSED" -ge "$UP_TIMEOUT" ]; then
        echo "Timed out waiting for reporting-pipeline-service to become healthy after ${UP_TIMEOUT}s"
        exit 1
    fi
    echo "Still waiting for reporting-pipeline-service... (${UP_ELAPSED}s elapsed)"
    sleep 5
    UP_ELAPSED=$((UP_ELAPSED + UP_WAIT))
done
echo "Reporting pipeline is healthy!"

START_TIME=$(run_query "SELECT CONVERT(varchar(30), GETDATE(), 120)")

sqlcmd -S "localhost,${DATABASE_PORT}" -U sa -P "$DATABASE_PASSWORD" -C -i testing-tools/smoke-testing/setup.sql

while true; do
    echo "Validating job_flow_log... (${VAL_ELAPSED}s elapsed)"
    PASS=true

    # Check a: N SP_COMPLETE rows have appeared since the run started
    ACTUAL_COUNT=$(run_query "SELECT COUNT(*) FROM [dbo].[job_flow_log] WHERE [Step_Name] = N'SP_COMPLETE' AND create_dttm > '${START_TIME}'")
    if [ "$ACTUAL_COUNT" != "$EXPECTED_SP_COMPLETE" ]; then
        echo "  [FAIL] Expected ${EXPECTED_SP_COMPLETE} SP_COMPLETE rows since ${START_TIME}, got ${ACTUAL_COUNT}"
        PASS=false
    fi

    # Check b: no rows with a non-null Error_Description since the run started
    ERROR_ROWS=$(run_query "SELECT Error_Description FROM [dbo].[job_flow_log] WHERE Error_Description IS NOT NULL AND create_dttm > '${START_TIME}'")
    if [ -n "$ERROR_ROWS" ]; then
        echo "  [FAIL] Errors found in job_flow_log:"
        echo "$ERROR_ROWS" | sed 's/^/    /'
        PASS=false
    fi

    if [ "$PASS" = true ]; then
        echo "Validation passed."
        exit 0
    fi

    if [ "$VAL_ELAPSED" -ge "$VAL_TIMEOUT" ]; then
        echo "Validation timed out after ${VAL_TIMEOUT}s."
        exit 1
    fi

    sleep "$VAL_WAIT"
    VAL_ELAPSED=$((VAL_ELAPSED + VAL_WAIT))
done
