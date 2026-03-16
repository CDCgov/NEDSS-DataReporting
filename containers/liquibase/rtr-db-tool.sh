#!/bin/bash
set -e

# RTR Database Automation Tool
# Supports:
#   1. Automatic setup via Liquibase
#   2. SQL generation for manual application (zip bundle)

# --- Configuration ---
DB_HOST=${DB_HOST:-""}
DB_USER=${DB_USERNAME:-""}
DB_PASS=${DB_PASSWORD:-""}
ENV_TYPE=${RTR_ENV:-"UAT"} # Default to UAT (rdb_modern)

# Liquibase common params
LB_COMMON="--searchPath=./ --username=${DB_USER} --password=${DB_PASS}"

print_help() {
    echo "RTR Database Automation Tool"
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  setup           Run all Liquibase migrations and onboarding scripts (auto-apply)"
    echo "  generate-sql    Produce a ZIP file with consolidated SQL for manual execution"
    echo "  help            Display this help message"
}

check_env() {
    if [[ -z "${DB_HOST}" || -z "${DB_USER}" || -z "${DB_PASS}" ]]; then
        echo "Error: DB_HOST, DB_USERNAME, and DB_PASSWORD must be set."
        exit 1
    fi
}

run_liquibase() {
    local changelog=$1
    local db_name=$2
    local mode=$3 # "update" or "update-sql"
    local output_file=$4

    local url="jdbc:sqlserver://${DB_HOST};databaseName=${db_name};integratedSecurity=false;encrypt=true;trustServerCertificate=true"
    
    if [[ "$mode" == "update-sql" ]]; then
        echo "-- Consolidated SQL for ${db_name} --" > "$output_file"
        liquibase ${LB_COMMON} --changelog-file="${changelog}" --url="${url}" update-sql >> "$output_file"
    else
        echo "Running Liquibase update for ${db_name}..."
        liquibase ${LB_COMMON} --changelog-file="${changelog}" --url="${url}" update
    fi
}

do_setup() {
    check_env
    echo "Starting RTR Database Setup (Mode: AUTO)..."

    # 1. Set ENV flag in NBS_Configuration
    echo "Setting ENV flag to ${ENV_TYPE} in NBS_ODSE..."
    local config_sql="IF NOT EXISTS(SELECT 1 FROM NBS_ODSE.DBO.NBS_configuration WHERE config_key ='ENV') 
        INSERT INTO NBS_ODSE.dbo.NBS_configuration (config_key, config_value, version_ctrl_nbr, add_time, last_chg_time, status_cd, status_time) 
        VALUES('ENV', '${ENV_TYPE}', 1, getdate(), getdate(), 'A', getdate());
        ELSE
        UPDATE NBS_ODSE.dbo.NBS_configuration SET config_value = '${ENV_TYPE}' WHERE config_key = 'ENV';"
    echo "$config_sql" | /opt/mssql-tools18/bin/sqlcmd -S "${DB_HOST}" -U "${DB_USER}" -P "${DB_PASS}"

    # 2. Run Liquibase Migrations
    run_liquibase "db.odse.admin.tasks.changelog-16.1.yaml" "NBS_ODSE" "update"
    run_liquibase "db.odse.changelog-16.1.yaml" "nbs_odse" "update"
    run_liquibase "db.srte.admin.tasks.changelog-16.1.yaml" "NBS_SRTE" "update"
    run_liquibase "db.srte.changelog-16.1.yaml" "nbs_srte" "update"
    
    local rdb_target="rdb_modern"
    if [[ "${ENV_TYPE}" == "PROD" ]]; then rdb_target="rdb"; fi
    
    run_liquibase "db.rdb.changelog-16.1.yaml" "${rdb_target}" "update"
    run_liquibase "db.rdb_modern.changelog-16.1.yaml" "${rdb_target}" "update"

    # 3. Apply Onboarding Scripts
    echo "Applying onboarding scripts..."
    for sql in $(find "./onboarding" -iname "*.sql" | sort) ; do
        echo "Executing: $sql"
        /opt/mssql-tools18/bin/sqlcmd -C -S "${DB_HOST}" -U "${DB_USER}" -P "${DB_PASS}" -i "$sql"
    done

    echo "Setup complete!"
}

do_generate_sql() {
    check_env
    echo "Generating consolidated SQL bundle..."
    local bundle_dir="rtr_sql_bundle"
    mkdir -p "${bundle_dir}/sql"

    # A. Generate Schema SQL from Liquibase
    run_liquibase "db.odse.changelog-16.1.yaml" "nbs_odse" "update-sql" "${bundle_dir}/sql/01_NBS_ODSE_SCHEMA.sql"
    run_liquibase "db.srte.changelog-16.1.yaml" "nbs_srte" "update-sql" "${bundle_dir}/sql/02_NBS_SRTE_SCHEMA.sql"
    
    local rdb_target="rdb_modern"
    if [[ "${ENV_TYPE}" == "PROD" ]]; then rdb_target="rdb"; fi
    run_liquibase "db.rdb_modern.changelog-16.1.yaml" "${rdb_target}" "update-sql" "${bundle_dir}/sql/03_${rdb_target^^}_SCHEMA.sql"

    # B. Concatenate User Creation (Master)
    echo "Adding user creation scripts..."
    # Note: Using individual files might be better for manual edits, but we'll consolidate for simplicity
    cat ./onboarding/000-create_rtr_admin_user-001.sql > "${bundle_dir}/sql/00_USER_CREATION.sql"
    cat ./onboarding/001-service_users_login_creation-001.sql >> "${bundle_dir}/sql/00_USER_CREATION.sql"
    cat ./onboarding/002-service_database_user_creation-001.sql >> "${bundle_dir}/sql/00_USER_CREATION.sql"

    # C. Concatenate Data Load & CDC (Master Load Data folder)
    echo "Adding data load and CDC scripts..."
    # These are in the onboarding folder too due to Dockerfile.local
    # We'll filter for them specifically
    cat /dev/null > "${bundle_dir}/sql/04_DATA_LOAD_AND_CDC.sql"
    for sql in $(ls ./onboarding/0*.sql | grep -vE "create_rtr_admin|user_login|user_creation" | sort); do
        cat "$sql" >> "${bundle_dir}/sql/04_DATA_LOAD_AND_CDC.sql"
        echo "GO" >> "${bundle_dir}/sql/04_DATA_LOAD_AND_CDC.sql"
    done
    for sql in $(ls ./onboarding/1*.sql | sort); do
        cat "$sql" >> "${bundle_dir}/sql/04_DATA_LOAD_AND_CDC.sql"
        echo "GO" >> "${bundle_dir}/sql/04_DATA_LOAD_AND_CDC.sql"
    done

    # D. Add README
    cat << 'REEOF' > "${bundle_dir}/README.txt"
RTR Consolidated SQL Bundle
===========================
This bundle contains all the SQL required to manually upgrade your NBS environment for RTR.

Execution Order:
1. 00_USER_CREATION.sql (Run as 'sa' against master)
   - IMPORTANT: Edit this file to set your desired passwords first.
2. 01_NBS_ODSE_SCHEMA.sql (Run against NBS_ODSE)
3. 02_NBS_SRTE_SCHEMA.sql (Run against NBS_SRTE)
4. 03_RDB_MODERN_SCHEMA.sql (Run against RDB_MODERN or RDB)
5. 04_DATA_LOAD_AND_CDC.sql (Run against master)
   - This handles data hydration and enables Change Data Capture.

Note: Ensure 'sqlcmd' is used with the -I (quoted identifiers) flag if applying manually.
REEOF

    # E. Zip it up
    if command -v zip &> /dev/null; then
        zip -r rtr_sql_upgrade.zip "${bundle_dir}"
    else
        tar -cvzf rtr_sql_upgrade.tar.gz "${bundle_dir}"
    fi

    echo "Consolidated SQL bundle created: $(ls rtr_sql_upgrade.*)"
}

# --- Main ---
case "$1" in
    setup)
        do_setup
        ;;
    generate-sql)
        do_generate_sql
        ;;
    *)
        print_help
        exit 1
        ;;
esac
