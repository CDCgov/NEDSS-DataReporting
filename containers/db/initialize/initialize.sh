#!/usr/bin/env bash
set -e
BASE="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

until /opt/mssql-tools18/bin/sqlcmd -C -S localhost -U sa -Q "select 1" &> /dev/null; do
    sleep 1s
done;

echo "*************************************************************************"
echo "  Initializing NBS databases"
echo "*************************************************************************"

# Enable CLR
echo "*************************************************************************"
echo "  Enabling CLR"
echo "*************************************************************************"
/opt/mssql-tools18/bin/sqlcmd -C -S localhost -U sa -Q "EXEC sp_configure 'clr enabled', 1; RECONFIGURE;"

for sql in $(find "$BASE/restore.d" -iname "*.sql" | sort) ;
do
    echo "Executing: $sql"
    /opt/mssql-tools18/bin/sqlcmd -C -S localhost -U sa -i "$sql"

    echo "Completed: $sql"
done

echo "*************************************************************************"
echo "  NBS databases ready"
echo "*************************************************************************"


# Enable CDC for ODSE database
echo "*************************************************************************"
echo "  Enabling CDC for ODSE"
echo "*************************************************************************"
if ! /opt/mssql-tools18/bin/sqlcmd -C -S localhost -U sa -Q "USE NBS_ODSE; EXEC sp_changedbowner 'sa'; EXEC sys.sp_cdc_enable_db;"; then
    echo "Error enabling CDC for ODSE database"
    exit 1
fi

# Enable CDC for each ODSE tables
echo "*************************************************************************"
echo "  Enabling CDC for ODSE tables"
echo "*************************************************************************"
for table in "Person" "Organization" "Observation" "Public_health_case" "Treatment" "state_defined_field_data" "Notification" "Interview" "Place" "CT_contact" "Auth_user" "Intervention" "Act_relationship"; do
    echo "Enabling CDC for table: $table"
    /opt/mssql-tools18/bin/sqlcmd -C -S localhost -U sa -Q "USE NBS_ODSE; EXEC sys.sp_cdc_enable_table @source_schema = 'dbo', @source_name = '$table', @role_name = NULL;"
done
echo "*************************************************************************"
echo " CDC has been enabled for ODSE tables."
echo "*************************************************************************"

# Enable CDC for SRTE database
echo "*************************************************************************"
echo "  Enabling CDC for SRTE"
echo "*************************************************************************"
if ! /opt/mssql-tools18/bin/sqlcmd -C -S localhost -U sa -Q "USE NBS_SRTE; EXEC sp_changedbowner 'sa'; EXEC sys.sp_cdc_enable_db;"; then
    echo "Error enabling CDC for the SRTE database"
    exit 1
fi

# Enable CDC for each SRTE tables
echo "*************************************************************************"
echo "  Enabling CDC for SRTE tables"
echo "*************************************************************************"
for table in "Condition_code" "Program_area_code" "Language_code" "State_code" "Unit_code" "Cntycity_code_value" "Lab_result" "Country_code" "Labtest_loinc" "ELR_XREF" "Loinc_condition" "Loinc_snomed_condition" "Lab_test" "Zip_code_value" "Zipcnty_code_value" "Lab_result_Snomed" "Investigation_code" "TotalIDM" "IMRDBMapping" "Anatomic_site_code" "Jurisdiction_code" "Lab_coding_system" "City_code_value" "LDF_page_set" "LOINC_code" "NAICS_Industry_code" "Codeset_Group_Metadata" "Country_Code_ISO" "Occupation_code" "Country_XREF" "Standard_XREF" "Code_value_clinical" "Code_value_general" "Race_code" "Participation_type" "Specimen_source_code" "Snomed_code"  "State_county_code_value" "State_model" "Codeset"  "Jurisdiction_participation" "Labtest_Progarea_Mapping" "Treatment_code"  "Snomed_condition"; do
    echo "Enabling CDC for table: $table"
    /opt/mssql-tools18/bin/sqlcmd -C -S localhost -U sa -Q "USE NBS_SRTE; EXEC sys.sp_cdc_enable_table @source_schema = 'dbo', @source_name = '$table', @role_name = NULL;"
done
echo "*************************************************************************"
echo " CDC has been enabled for SRTE tables."
echo "*************************************************************************"
