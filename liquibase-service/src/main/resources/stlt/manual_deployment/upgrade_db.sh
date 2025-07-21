#!/bin/bash

# This script is designed to be executed on Unix/Linux (e.g., Ubuntu, CentOS)
# Parameters:
#     server: Server Name or IP address 
#     database: Database Name
#     user: User Name
#     password: User Password
# Optional Parameters:
#     --load-data: Include or not the load_data subdirectory

# Usage:
# ./upgrade_db.sh server_name rdb my_user my_password
# ./upgrade_db.sh --load-data server_name rdb my_user my_password

# Initialize variables
load_data="false"
param_count=0
SERVER_NAME=""
DATABASE=""
DB_USER=""
DB_PASS=""

print_help() {
    echo "Usage: $0 [options] server database user password"
    echo ""
    echo "This script executes SQL scripts to upgrade the specified database."
    echo ""
    echo "Required Parameters:"
    echo "  server            Server Name or IP address"
    echo "  database          Database Name (master, rdb, nbs_odse, nbs_srte, rdb_modern)"
    echo "  user              User Name"
    echo "  password          User Password"
    echo ""
    echo "Options:"
    echo "  /h, -h, --help    Display this help message"
    echo "  --load-data       Execute scripts in the data_load folder (only valid for 'master')"
    echo ""
    echo "Examples:"
    echo "  $0 server_name rdb my_user my_password"
    echo "  $0 --load-data server_name rdb my_user my_password"
}

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        /h|-h|--help)
            print_help
            exit 0
            ;;
        --load-data)
            load_data="true"
            shift
            ;;
        *)
            case $param_count in
                0) SERVER_NAME="$1" ;;
                1) DATABASE="$1" ;;
                2) DB_USER="$1" ;;
                3) DB_PASS="$1" ;;
            esac
            ((param_count++))
            shift
            ;;
    esac
done

# Check required parameters
if [[ $param_count -lt 4 ]]; then
    echo "Usage: $0 [options] server database user password"
    echo "Type $0 --help for help"
    exit 1
fi

# Resolve script base directory
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Resolve SQL folder based on database
case "${DATABASE,,}" in
    master) SCRIPT_DIR="$BASE_DIR/db/001-master" ;;
    nbs_srte) SCRIPT_DIR="$BASE_DIR/db/002-srte" ;;
    nbs_odse) SCRIPT_DIR="$BASE_DIR/db/003-odse" ;;
    rdb) SCRIPT_DIR="$BASE_DIR/db/004-rdb" ;;
    rdb_modern) SCRIPT_DIR="$BASE_DIR/db/005-rdb_modern" ;;
    *)
        echo "Unknown database: $DATABASE"
        exit 1
        ;;
esac

# Load data support only for 'master'
if [[ "$load_data" == "true" ]]; then
    if [[ "${DATABASE,,}" == "master" ]]; then
        SCRIPT_DIR="$SCRIPT_DIR/02_onboarding_script_data_load"
        PATHS=(".")
    else
        echo "Load data is only supported for the 'master' database."
        exit 1
    fi
else
    PATHS=("tables" "views" "functions" "routines" "jobs" "remove")
fi

# Generate log filename (yyyymmddss format)
timestamp=$(date +%Y%m%d%S)
LOG_FILE="$BASE_DIR/db/manual_run_log_${timestamp}_${DATABASE}.log"

ERROR_COUNT=0
FAILED_SCRIPTS=()

# Initialize log
echo "[$(date '+%F %T')] Starting script execution..." >> "$LOG_FILE"
if [[ "$load_data" == "true" ]]; then
    echo "[$(date '+%F %T')] Load Data scripts have been included" >> "$LOG_FILE"
else
    echo "[$(date '+%F %T')] Load Data scripts have been excluded" >> "$LOG_FILE"
fi
echo "[$(date '+%F %T')] Executing SQL scripts from: $SCRIPT_DIR (${PATHS[*]})" >> "$LOG_FILE"

# Check script dir
if [[ ! -d "$SCRIPT_DIR" ]]; then
    echo "Directory not found: $SCRIPT_DIR"
    echo "[$(date '+%F %T')] Directory not found: $SCRIPT_DIR" >> "$LOG_FILE"
    exit 1
fi

# Execute SQL files
for path in "${PATHS[@]}"; do
    f_dir="$SCRIPT_DIR/$path"
    if [[ -d "$f_dir" ]]; then
        for file in "$f_dir"/*.sql; do
            [[ -f "$file" ]] || continue
            echo "Executing $file..."
            echo "[$(date '+%F %T')] Executing $file..." >> "$LOG_FILE"
            sqlcmd -S "$SERVER_NAME" -d "$DATABASE" -U "$DB_USER" -P "$DB_PASS" -i "$file" -I -b -C >> "$LOG_FILE" 2>&1
            CURRENT_ERROR=$?
            if [[ $CURRENT_ERROR -ne 0 ]]; then
                echo "Error executing $file. Error code: $CURRENT_ERROR"
                echo "[$(date '+%F %T')] Error executing $file. Error code: $CURRENT_ERROR" >> "$LOG_FILE"
                ((ERROR_COUNT++))
                FAILED_SCRIPTS+=("$file")
            fi
        done
    fi
done

# Summary
if [[ $ERROR_COUNT -eq 0 ]]; then
    echo ""
    echo "Summary: All scripts executed successfully..."
    echo "[$(date '+%F %T')] All scripts executed successfully." >> "$LOG_FILE"
else
    echo ""
    echo "Errors: $ERROR_COUNT scripts failed"
    echo "[$(date '+%F %T')] Errors: $ERROR_COUNT scripts failed" >> "$LOG_FILE"
    for file in "${FAILED_SCRIPTS[@]}"; do
        echo "    - $file"
        echo "    - $file" >> "$LOG_FILE"
    done
fi

exit 0