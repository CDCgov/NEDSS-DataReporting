#!/bin/bash
set -e
set -o pipefail

if [[ -n "$RUN_MIGRATIONS" && "$RUN_MIGRATIONS" == "true" ]]; then
    # Run migrations
    echo "Starting migrations"
    # ODSE
    liquibase \
        --changelog-file="changelog/db.odse.changelog-16.1.yaml" \
        --searchPath="./" \
        --url="jdbc:sqlserver://${DB_HOST};databaseName=nbs_odse;integratedSecurity=false;encrypt=true;trustServerCertificate=true" \
        --username="${DB_USERNAME}" \
        --password="${DB_PASSWORD}" \
        update

    # Determine target reporting database based on NBS_ODSE configuration
    echo "Determining target reporting database..."
    ENV_CHECK=$(sqlcmd -b -C -S "${DB_HOST}" -d "NBS_ODSE" -U "${DB_USERNAME}" -P "${DB_PASSWORD}" -Q "SET NOCOUNT ON; SELECT config_value FROM dbo.NBS_configuration WHERE config_key = 'ENV'" -h -1 -W 2>/dev/null | tr -d '\r' | xargs)

    TARGET_DB="rdb"
    if [[ "$ENV_CHECK" == "UAT" ]]; then
        TARGET_DB="rdb_modern"
    fi
    echo "Target reporting database resolved to: $TARGET_DB"

    # RDB / RDB_Modern
    liquibase \
        --changelog-file="changelog/db.rdb.changelog-16.1.yaml" \
        --searchPath="./" \
        --url="jdbc:sqlserver://${DB_HOST};databaseName=${TARGET_DB};integratedSecurity=false;encrypt=true;trustServerCertificate=true" \
        --username="${DB_USERNAME}" \
        --password="${DB_PASSWORD}" \
        update

    echo "Migrations complete"
else
    echo "Skipping migrations as RUN_MIGRATIONS is not set to true"
    echo "Hanging process to allow for external migration execution"
    tail -f /dev/null
fi
