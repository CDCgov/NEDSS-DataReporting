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


    echo "Migrations complete"
else
    echo "Skipping migrations as RUN_MIGRATIONS is not set to true"
    echo "Hanging process to allow for external migration execution"
    tail -f /dev/null
fi
