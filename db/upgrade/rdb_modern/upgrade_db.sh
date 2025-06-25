#!/bin/bash
    
# This script is designed to be executed in Unix/Linux
# It is required to install msodbcsql18
# This Script only can be executed over a copy of RDB database without nrt_afaik tables
# Parameters:
#     server: Server Name or IP address 
#     database: Database Name (usually RDB_MODERN)
#     user: User Name  (must have permissions to create/delete objects in database)
#     password: User Password

# EXAMPLE of command to execute the script:
# bash upgrade_db.sh server_name rdb_modern my_user my_password

# Check if all parameters are provided
if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ]; then
    echo "Usage: $0 server database user password"
    exit 1
fi

SERVER_NAME="$1"
DATABASE="$2"
DB_USER="$3"
DB_PASS="$4"

SCRIPT_DIR="$(dirname "$(realpath "$0")")"
LOG_FILE="$SCRIPT_DIR/upgrade_db_execution.log"
PATHS=("tables" "views" "functions" "routines" "remove" "data_load")
ERROR_COUNT=0
FAILED_SCRIPTS=()

# Initialize log
echo "[$(date)] Starting script execution..." >> "$LOG_FILE"

# Check if directory exists
if [ ! -d "$SCRIPT_DIR" ]; then
    echo "Directory not found: $SCRIPT_DIR"
    echo "[$(date)] Directory not found: $SCRIPT_DIR" >> "$LOG_FILE"
    exit 1
else
    # Loop through all .sql files in the current directory
    for file in "$SCRIPT_DIR"/*.sql; do
        if [ -f "$file" ]; then
            echo "Executing $file..."
            echo "[$(date)] Executing $file..." >> "$LOG_FILE"
            sqlcmd -S "$SERVER_NAME" -d "$DATABASE" -U "$DB_USER" -P "$DB_PASS" -i "$file" -b -C >> "$LOG_FILE" 2>&1
            CURRENT_ERROR=$?
            if [ $CURRENT_ERROR -ne 0 ]; then
                echo "Error executing $file. Error code: $CURRENT_ERROR"
                echo "[$(date)] Error executing $file. Error code: $CURRENT_ERROR" >> "$LOG_FILE"
                ((ERROR_COUNT++))
                FAILED_SCRIPTS+=("$file")
            fi
        fi
    done
fi

if [ $ERROR_COUNT -eq 0 ]; then
    for path in "${PATHS[@]}"; do
        f_dir="$SCRIPT_DIR/$path/"
        if [ -d "$f_dir" ]; then
            for file in "$f_dir"*.sql; do
                if [ -f "$file" ]; then
                    echo "Executing $file..."
                    echo "[$(date)] Executing $file..." >> "$LOG_FILE"
                    sqlcmd -S "$SERVER_NAME" -d "$DATABASE" -U "$DB_USER" -P "$DB_PASS" -i "$file" -b -C >> "$LOG_FILE" 2>&1
                    CURRENT_ERROR=$?
                    if [ $CURRENT_ERROR -ne 0 ]; then
                        echo "Error executing $file. Error code: $CURRENT_ERROR"
                        echo "[$(date)] Error executing $file. Error code: $CURRENT_ERROR" >> "$LOG_FILE"
                        ((ERROR_COUNT++))
                        FAILED_SCRIPTS+=("$file")
                    fi
                fi
            done
        fi
    done
fi

if [ $ERROR_COUNT -eq 0 ]; then
    echo "Summary: All scripts executed successfully..."
else
    echo "Errors: $ERROR_COUNT Scripts failed"
    echo "[$(date)] Errors: $ERROR_COUNT Scripts have failed" >> "$LOG_FILE"
    for file in "${FAILED_SCRIPTS[@]}"; do
        echo "    - $file"
        echo "    - $file" >> "$LOG_FILE"
    done
fi