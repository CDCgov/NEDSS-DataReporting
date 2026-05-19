#!/bin/bash

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

    # RDB - Applied to rdb_modern as dictated by liquibase-service/readme.md
    liquibase \
        --changelog-file="db.rdb.changelog-16.1.yaml" \
        --searchPath="./" \
        --url="jdbc:sqlserver://${DB_HOST};databaseName=rdb_modern;integratedSecurity=false;encrypt=true;trustServerCertificate=true" \
        --username="${DB_USERNAME}" \
        --password="${DB_PASSWORD}" \
        update

    # RDB_Modern
    liquibase \
        --changelog-file="db.rdb_modern.changelog-16.1.yaml" \
        --searchPath="./" \
        --url="jdbc:sqlserver://${DB_HOST};databaseName=rdb_modern;integratedSecurity=false;encrypt=true;trustServerCertificate=true" \
        --username="${DB_USERNAME}" \
        --password="${DB_PASSWORD}" \
        update

    # Apply onboarding scripts
    echo "Applying onboarding scripts"
    for sql in $(find "./02-onboarding" -iname "*.sql" | sort -V); do
        echo "Executing: $sql"
        sqlcmd -C -S "${DB_HOST}" -U "${DB_USERNAME}" -P "${DB_PASSWORD}" -i "$sql"

        echo "Completed: $sql"
    done

    echo "Migrations complete"
else
    echo "Skipping migrations as RUN_MIGRATIONS is not set to true"
    echo "Hanging process to allow for external migration execution"
    tail -f /dev/null
fi
