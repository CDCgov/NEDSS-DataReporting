#!/usr/bin/env bash
set -e
BASE="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

# Start SQL Server in the background
echo "Starting SQL Server..."
sqlservr &
SQL_PID=$!

# 2. Wait for SQL Server to be ready
echo "Waiting for SQL Server to accept connections..."
MAX_RETRIES=60
count=0
while [ $count -lt $MAX_RETRIES ]; do
    if sqlcmd -C -S localhost -U sa -Q "SELECT 1" &> /dev/null; then
        echo "SQL Server is ready."
        break
    fi
    
    # Check if the process is still running; fail fast if it died
    if ! kill -0 $SQL_PID 2>/dev/null; then
        echo "Error: SQL Server process exited unexpectedly."
        exit 1
    fi
    
    echo "Waiting for SQL Server... ($count/$MAX_RETRIES)"
    sleep 5
    count=$((count+1))
done

if [ $count -eq $MAX_RETRIES ]; then
    echo "Timeout waiting for SQL Server to start."
    kill -SIGTERM $SQL_PID
    exit 1
fi

echo "*************************************************************************"
echo "  Running NBS migrations"
echo "*************************************************************************"
# Run migrations as part of initialization to prevent liquibase errors
/var/data/run_migrations.sh ${DATABASE_VERSION}
echo "Migrations complete"

echo "*************************************************************************"
echo "  Initializing NBS databases"
echo "*************************************************************************"

echo "Enabling CLR"
sqlcmd -C -S localhost -U sa -Q "EXEC sp_configure 'clr enabled', 1; RECONFIGURE;"


for sql in $(find "$BASE/restore.d" -iname "*.sql" | sort) ;
do
    echo "Executing: $sql"
    sqlcmd -C -S localhost -U sa -i "$sql"

    echo "Completed: $sql"
done

echo "Enabling CDC for NBS_ODSE"
if ! sqlcmd -C -S localhost -U sa -Q "USE NBS_ODSE; EXEC sp_changedbowner 'sa'; EXEC sys.sp_cdc_enable_db;"; then
    echo "Error enabling CDC for ODSE database"
    exit 1
fi

for table in "Person" "Organization" "Observation" "Public_health_case" "Treatment" "state_defined_field_data" "Notification" "Interview" "Place" "CT_contact" "Auth_user" "Intervention" "Act_relationship"; do
    echo "Enabling CDC for NBS_ODSE.$table"
    sqlcmd -C -S localhost -U sa -Q "USE NBS_ODSE; EXEC sys.sp_cdc_enable_table @source_schema = 'dbo', @source_name = '$table', @role_name = NULL;"
done

echo "Enabling CDC for NBS_SRTE"
if ! sqlcmd -C -S localhost -U sa -Q "USE NBS_SRTE; EXEC sp_changedbowner 'sa'; EXEC sys.sp_cdc_enable_db;"; then
    echo "Error enabling CDC for the SRTE database"
    exit 1
fi
for table in "Condition_code" "Program_area_code" "Language_code" "State_code" "Unit_code" "Cntycity_code_value" "Lab_result" "Country_code" "Labtest_loinc" "ELR_XREF" "Loinc_condition" "Loinc_snomed_condition" "Lab_test" "Zip_code_value" "Zipcnty_code_value" "Lab_result_Snomed" "Investigation_code" "TotalIDM" "IMRDBMapping" "Anatomic_site_code" "Jurisdiction_code" "Lab_coding_system" "City_code_value" "LDF_page_set" "LOINC_code" "NAICS_Industry_code" "Codeset_Group_Metadata" "Country_Code_ISO" "Occupation_code" "Country_XREF" "Standard_XREF" "Code_value_clinical" "Code_value_general" "Race_code" "Participation_type" "Specimen_source_code" "Snomed_code"  "State_county_code_value" "State_model" "Codeset"  "Jurisdiction_participation" "Labtest_Progarea_Mapping" "Treatment_code"  "Snomed_condition"; do
    echo "Enabling CDC for NBS_SRTE.$table"
    sqlcmd -C -S localhost -U sa -Q "USE NBS_SRTE; EXEC sys.sp_cdc_enable_table @source_schema = 'dbo', @source_name = '$table', @role_name = NULL;"
done

echo "*************************************************************************"
echo "  NBS databases ready. Shutting down..."
echo "*************************************************************************"

# Send shutdown command
sqlcmd -C -S localhost -U sa -Q "SHUTDOWN WITH NOWAIT" || true

# Wait for the background sqlservr process to exit
# Use '|| true' to prevent script failure if sqlservr exits with a non-zero code
wait $SQL_PID || echo "SQL Server process exited with code $?"

echo "SQL Server stopped."
exit 0