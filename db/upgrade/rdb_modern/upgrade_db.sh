#!/bin/bash

# This script is designed to be executed on Unix/Linux (e.g., Ubuntu, CentOS)
# Parameters:
#     server: Server Name or IP address 
#     database: Database Name
#     user: User Name
#     password: User Password

# Optional Parameters:
#    --load-data: Include or not the load_data subdirectory 

# Usage:
# ./upgrade_db.sh server_name rdb_modern my_user my_password
# ./upgrade_db.sh --load-data server_name rdb_modern my_user my_password

# Initialize variables
load_data="false"
param_count=0
SERVER_NAME=""
DATABASE=""
DB_USER=""
DB_PASS=""

# Print help function
print_help() {
    echo "Usage: $0 [options] server database user password"
    echo ""
    echo "This script executes SQL scripts to upgrade the RDB_MODERN database."
    echo ""
    echo "Required Parameters:"
    echo "  server            Server Name or IP address"
    echo "  database          Database Name"
    echo "  user              User Name (must have permissions to create/delete objects in database)"
    echo "  password          User Password"
    echo ""
    echo "Options:"
    echo "  /h, -h, --help    Display this help message"
    echo "  --load-data       Execute scripts in the data_load folder (default: false)"
    echo ""
    echo "Examples:"
    echo "  $0 server_name rdb_modern my_user my_password"
    echo "  $0 --load-data server_name rdb_modern my_user my_password"
    echo "  $0 server_name rdb_modern my_user my_password --load-data"
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
            if [[ $param_count -eq 0 ]]; then
                SERVER_NAME="$1"
            elif [[ $param_count -eq 1 ]]; then
                DATABASE="$1"
            elif [[ $param_count -eq 2 ]]; then
                DB_USER="$1"
            elif [[ $param_count -eq 3 ]]; then
                DB_PASS="$1"
            fi
            ((param_count++))
            shift
            ;;
    esac
done

# Check if all required parameters are provided
if [[ $param_count -lt 4 ]]; then
    echo "Usage: $0 [options] server database user password"
    echo "Type $0 --help for help"
    exit 1
fi

# Set variables
SCRIPT_DIR="$(dirname "$(realpath "$0")")"
LOG_FILE="$SCRIPT_DIR/upgrade_db_execution.log"
PATHS=("tables" "views" "functions" "routines" "remove")
if [[ "$load_data" == "true" ]]; then
    PATHS+=("data_load")
fi
ERROR_COUNT=0
FAILED_SCRIPTS=()

# Initialize log
echo "[$(date '+%a %m/%d/%Y %H:%M:%S.%2N')] Starting script execution..." >> "$LOG_FILE"
if [[ "$load_data" == "true" ]]; then
    echo "[$(date '+%a %m/%d/%Y %H:%M:%S.%2N')] Load Data scripts have been included" >> "$LOG_FILE"
else
    echo "[$(date '+%a %m/%d/%Y %H:%M:%S.%2N')] Load Data scripts have been excluded" >> "$LOG_FILE"
fi
echo "[$(date '+%a %m/%d/%Y %H:%M:%S.%2N')] Executing SQL scripts from current folder and children folders (${PATHS[*]})..." >> "$LOG_FILE"

# Check if directory exists
if [ ! -d "$SCRIPT_DIR" ]; then
    echo "Directory not found: $SCRIPT_DIR"
    echo "[$(date '+%a %m/%d/%Y %H:%M:%S.%2N')] Directory not found: $SCRIPT_DIR" >> "$LOG_FILE"
    exit 1
else
    # Loop through all .sql files in the current directory
    for file in "$SCRIPT_DIR"/*.sql; do
        if [ -f "$file" ]; then
            echo "Executing $file..."
            echo "[$(date '+%a %m/%d/%Y %H:%M:%S.%2N')] Executing $file..." >> "$LOG_FILE"
            sqlcmd -S "$SERVER_NAME" -d "$DATABASE" -U "$DB_USER" -P "$DB_PASS" -i "$file" -b -C >> "$LOG_FILE" 2>&1
            CURRENT_ERROR=$?
            if [ $CURRENT_ERROR -ne 0 ]; then
                echo "Error executing $file. Error code: $CURRENT_ERROR"
                echo "[$(date '+%a %m/%d/%Y %H:%M:%S.%2N')] Error executing $file. Error code: $CURRENT_ERROR" >> "$LOG_FILE"
                ((ERROR_COUNT++))
                FAILED_SCRIPTS+=("$file")
            fi
        fi
    done
fi

# Execute scripts in specified folders if no errors so far
if [ $ERROR_COUNT -eq 0 ]; then
    for path in "${PATHS[@]}"; do
        f_dir="$SCRIPT_DIR/$path/"
        if [ -d "$f_dir" ]; then
            for file in "$f_dir"*.sql; do
                if [ -f "$file" ]; then
                    echo "Executing $file..."
                    echo "[$(date '+%a %m/%d/%Y %H:%M:%S.%2N')] Executing $file..." >> "$LOG_FILE"
                    sqlcmd -S "$SERVER_NAME" -d "$DATABASE" -U "$DB_USER" -P "$DB_PASS" -i "$file" -b -C >> "$LOG_FILE" 2>&1
                    CURRENT_ERROR=$?
                    if [ $CURRENT_ERROR -ne 0 ]; then
                        echo "Error executing $file. Error code: $CURRENT_ERROR"
                        echo "[$(date '+%a %m/%d/%Y %H:%M:%S.%2N')] Error executing $file. Error code: $CURRENT_ERROR" >> "$LOG_FILE"
                        ((ERROR_COUNT++))
                        FAILED_SCRIPTS+=("$file")
                    fi
                fi
            done
        fi
    done
fi

if [ $ERROR_COUNT -eq 0 ]; then
    echo ""
    echo "Summary: All scripts executed successfully..."
else
    echo ""
    echo "Errors: $ERROR_COUNT Scripts failed"
    echo "[$(date '+%a %m/%d/%Y %H:%M:%S.%2N')] Errors: $ERROR_COUNT Scripts have failed" >> "$LOG_FILE"
    for file in "${FAILED_SCRIPTS[@]}"; do
        echo "    - $file"
        echo "    - $file" >> "$LOG_FILE"
    done
fi

exit 0
