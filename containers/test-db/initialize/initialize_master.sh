#!/usr/bin/env bash
set -e
BASE="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

export SQLCMDSERVER="${SQLCMDSERVER:-127.0.0.1,1433}"
export SQLCMDUSER="${SQLCMDUSER:-sa}"

if [ -z "$SQLCMDPASSWORD" ]; then
    echo "Error: SQLCMDPASSWORD environment variable must be set"
    exit 1
fi

# Start SQL Server in the background
echo "Starting SQL Server..."
sqlservr -mSQLCMD & # Start sqlserver with the -m command to allow restore of master db
SQL_PID=$!

# 2. Wait for SQL Server to be ready
echo "Waiting for SQL Server to be ready..."
sleep 5

MAX_RETRIES=20
count=0
while [ $count -lt $MAX_RETRIES ]; do
    # Check if we can connect and if all databases are ONLINE (state = 0)
    # This ensures that system upgrades (like msdb) are complete before we proceed.
    if sqlcmd -C -b -Q "SET NOCOUNT ON; IF EXISTS (SELECT 1 FROM sys.databases WHERE state != 0) THROW 50000, 'Databases not online', 1;" &> /dev/null; then
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
echo "  Initializing NBS master database"
echo "*************************************************************************"
sqlcmd -C -i "$BASE/restore.d/00-restore-master.sql" # Restoring Master triggers a shutdown

wait $SQL_PID || echo "SQL Server process exited with code $?"

exit 0