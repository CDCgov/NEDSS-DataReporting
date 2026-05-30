#!/bin/bash
set -e
set -o pipefail

if [[ -n "$RUN_MIGRATIONS" && "$RUN_MIGRATIONS" == "true" ]]; then
    # Run migrations
    echo "Starting migrations"
    # ODSE Admin tasks
    liquibase \
        --changelog-file="db.odse.admin.tasks.changelog-16.1.yaml" \
        --searchPath="./" \
        --url="jdbc:sqlserver://${DB_HOST};databaseName=NBS_ODSE;integratedSecurity=false;encrypt=true;trustServerCertificate=true" \
        --username="${DB_USERNAME}" \
        --password="${DB_PASSWORD}" \
        update

    # ODSE
    liquibase \
        --changelog-file="db.odse.changelog-16.1.yaml" \
        --searchPath="./" \
        --url="jdbc:sqlserver://${DB_HOST};databaseName=nbs_odse;integratedSecurity=false;encrypt=true;trustServerCertificate=true" \
        --username="${DB_USERNAME}" \
        --password="${DB_PASSWORD}" \
        update

    # SRTE Admin tasks
    liquibase \
        --changelog-file="db.srte.admin.tasks.changelog-16.1.yaml" \
        --searchPath="./" \
        --url="jdbc:sqlserver://${DB_HOST};databaseName=NBS_SRTE;integratedSecurity=false;encrypt=true;trustServerCertificate=true" \
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
        --changelog-file="db.rdb_modern.changelog-16.1.yaml" \
        --searchPath="./" \
        --url="jdbc:sqlserver://${DB_HOST};databaseName=${TARGET_DB};integratedSecurity=false;encrypt=true;trustServerCertificate=true" \
        --username="${DB_USERNAME}" \
        --password="${DB_PASSWORD}" \
        update

    # Apply onboarding scripts
    echo "Applying onboarding scripts"
    for sql in $(find "./02-onboarding" -iname "*.sql" | sort -V); do
        echo "Executing: $sql"
        sqlcmd -b -C -S "${DB_HOST}" -U "${DB_USERNAME}" -P "${DB_PASSWORD}" -i "$sql"

        echo "Completed: $sql"
    done

    echo "Migrations complete"
else
    echo "Skipping migrations as RUN_MIGRATIONS is not set to true"
    echo "Hanging process to allow for external migration execution"
    tail -f /dev/null
fi
