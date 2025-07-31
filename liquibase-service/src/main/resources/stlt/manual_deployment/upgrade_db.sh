#!/bin/bash

# upgrade_db.sh
# Executes SQL scripts to upgrade the specified database.
# Usage:
#   ./upgrade_db.sh [options] server database user password
#   ./upgrade_db.sh --load-data server database user password

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
    echo "  $0 --load-data server_name master my_user my_password"
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

if ! command -v sqlcmd &> /dev/null; then
    echo "Error: sqlcmd is not installed or not found in PATH."
    exit 1
fi

# Check required parameters
if [[ $param_count -lt 4 ]]; then
    echo "Usage: $0 [options] server database user password"
    echo "Type $0 --help for help"
    exit 1
fi


DB_DIR="$BASE_DIR/../db"

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$BASE_DIR/../.." && pwd)"
echo "Detected PROJECT_ROOT: $PROJECT_ROOT"
echo "Detected BASE_DIR: $BASE_DIR"
lower_db=$(echo "$DATABASE" | tr '[:upper:]' '[:lower:]')
# Resolve SCRIPT_DIR
SCRIPT_DIR=""
case "$lower_db" in
    master)
        SCRIPT_DIR="$PROJECT_ROOT/db/001-master"
        ;;
    nbs_srte)
        SCRIPT_DIR="$PROJECT_ROOT/db/002-srte"
        ;;
    nbs_odse)
        SCRIPT_DIR="$PROJECT_ROOT/db/003-odse"
        ;;
    rdb_modern)
        SCRIPT_DIR="$PROJECT_ROOT/db/005-rdb_modern"
        ;;
    rdb)
        echo "Selected RDB database."
        while true; do
            read -p "Would you like to run the rdb_modern scripts on the RDB database? (Y/N): " yn
            case $yn in
                [Yy]*)
                    echo "User selected 'Yes'. Running modern scripts in RDB."
                    SCRIPT_DIR="$PROJECT_ROOT/db/005-rdb_modern"
                    break
                    ;;
                [Nn]*)
                    echo "User selected 'No'. Running RDB scripts."
                    SCRIPT_DIR="$PROJECT_ROOT/db/004-rdb"
                    break
                    ;;
                *)
                    echo "Please answer Y or N."
                    ;;
            esac
        done
        ;;
    *)
        echo "Unknown database: $DATABASE"
        exit 1
        ;;
esac

# Load data option handling
if [[ "$load_data" == "true" ]]; then
    if [[ "$lower_db" == "master" ]]; then
        SCRIPT_DIR="$SCRIPT_DIR/02_onboarding_script_data_load"
        PATHS=(".")
    else
        echo "Load data is only supported for the 'master' database."
        exit 1
    fi
else
    PATHS=("tables" "views" "functions" "routines" "remove")
fi

# Create logs directory and log file
mkdir -p "$PROJECT_ROOT/logs"
timestamp=$(date +%Y%m%d%H%M%S)
LOG_FILE="$PROJECT_ROOT/logs/manual_run_log_${timestamp}_${DATABASE}.log"


ERROR_COUNT=0
FAILED_SCRIPTS=()

# Start log
echo "[$(date '+%F %T')] Starting script execution..." >> "$LOG_FILE"
if [[ "$load_data" == "true" ]]; then
    echo "[$(date '+%F %T')] Load Data scripts included" >> "$LOG_FILE"
else
    echo "[$(date '+%F %T')] Load Data scripts excluded" >> "$LOG_FILE"
fi
echo "[$(date '+%F %T')] Executing SQL scripts from: $SCRIPT_DIR" >> "$LOG_FILE"

# Check script directory
if [[ ! -d "$SCRIPT_DIR" ]]; then
    echo "Directory not found: $SCRIPT_DIR"
    echo "[$(date '+%F %T')] Directory not found: $SCRIPT_DIR" >> "$LOG_FILE"
    exit 1
fi

# Execute scripts
for path in "${PATHS[@]}"; do
    f_dir="$SCRIPT_DIR/$path"
    if [[ -d "$f_dir" ]]; then
        for file in "$f_dir"/*.sql; do
            [[ -f "$file" ]] || continue
            echo "Executing $file..."
            echo "[$(date '+%F %T')] Executing $file..." >> "$LOG_FILE"
            sqlcmd -S "$SERVER_NAME" -d "$lower_db" -U "$DB_USER" -P "$DB_PASS" -i "$file" -I -b -C >> "$LOG_FILE" 2>&1
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

# Final summary
if [[ $ERROR_COUNT -eq 0 ]]; then
    echo ""
    echo "Summary: All scripts executed successfully."
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