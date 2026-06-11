#!/bin/bash
set -euo pipefail

if [ -z "${DB_CONNECTION_URL:-}" ]; then
    echo "ERROR: DB_CONNECTION_URL is required" >&2
    exit 1
fi

RDB_DATABASE_NAME=$(echo "$DB_CONNECTION_URL" | sed 's/.*databaseName=\([^;]*\).*/\1/')

if [ -z "$RDB_DATABASE_NAME" ]; then
    echo "ERROR: Could not parse databaseName from DB_CONNECTION_URL: $DB_CONNECTION_URL" >&2
    exit 1
fi

export RDB_DATABASE_NAME

exec java -jar reporting-pipeline-service.jar
