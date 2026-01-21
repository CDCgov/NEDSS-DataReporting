# Run migrations
echo "Starting migrations"
# ODSE Admin tasks
liquibase \
    --changelog-file="db.odse.admin.tasks.changelog-16.1.yaml" \
    --searchPath="./" \
    --url="jdbc:sqlserver://rtr-mssql:1433;databaseName=NBS_ODSE;integratedSecurity=false;encrypt=true;trustServerCertificate=true" \
    --username="${DB_USERNAME}" \
    --password="${DB_PASSWORD}"\
    update

# ODSE
liquibase \
    --changelog-file="db.odse.changelog-16.1.yaml" \
    --searchPath="./" \
    --url="jdbc:sqlserver://rtr-mssql:1433;databaseName=nbs_odse;integratedSecurity=false;encrypt=true;trustServerCertificate=true" \
    --username="${DB_USERNAME}" \
    --password="${DB_PASSWORD}"\
    update

# SRTE Admin tasks
liquibase \
    --changelog-file="db.srte.admin.tasks.changelog-16.1.yaml" \
    --searchPath="./" \
    --url="jdbc:sqlserver://rtr-mssql:1433;databaseName=NBS_SRTE;integratedSecurity=false;encrypt=true;trustServerCertificate=true" \
    --username="${DB_USERNAME}" \
    --password="${DB_PASSWORD}" \
    update

# RDB - Applied to rdb_modern as dictated by liquibase-service/readme.md
liquibase \
    --changelog-file="db.rdb.changelog-16.1.yaml" \
    --searchPath="./" \
    --url="jdbc:sqlserver://rtr-mssql:1433;databaseName=rdb_modern;integratedSecurity=false;encrypt=true;trustServerCertificate=true" \
    --username="${DB_USERNAME}" \
    --password="${DB_PASSWORD}" \
    update


# RDB_Modern
liquibase \
    --changelog-file="db.rdb_modern.changelog-16.1.yaml" \
    --searchPath="./" \
    --url="jdbc:sqlserver://rtr-mssql:1433;databaseName=rdb_modern;integratedSecurity=false;encrypt=true;trustServerCertificate=true" \
    --username="${DB_USERNAME}" \
    --password="${DB_PASSWORD}" \
    update


# Apply onboarding scripts
echo "Applying onboarding scripts"
for sql in $(find "./onboarding" -iname "*.sql" | sort) ;
do
    echo "Executing: $sql"
    /opt/mssql-tools18/bin/sqlcmd -C -S rtr-mssql -U sa -P "PizzaIsGood33!" -i "$sql"

    echo "Completed: $sql"
done

echo "Migrations complete"