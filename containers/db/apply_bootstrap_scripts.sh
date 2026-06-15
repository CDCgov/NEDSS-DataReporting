#!/bin/bash
set -e

export PATH=/opt/mssql-tools18/bin:$PATH

SCRIPT_DIR="${1:?Usage: apply_bootstrap_scripts.sh <script-dir>}"

: "${DB_SERVER:?DB_SERVER is required}"
: "${DB_USER:?DB_USER is required}"
: "${DB_PASSWORD:?DB_PASSWORD is required}"

echo "Waiting for database at $DB_SERVER..."
until sqlcmd -C -S "$DB_SERVER" -U "$DB_USER" -P "$DB_PASSWORD" -Q "SELECT 1" 2>&1; do
    echo "Not ready, retrying in 3s..."
    sleep 3
done

for f in "$SCRIPT_DIR"/*.sql; do
    echo "Applying $f"
    sqlcmd -C -S "$DB_SERVER" -U "$DB_USER" -P "$DB_PASSWORD" -i "$f"
done

echo "Bootstrap complete"
