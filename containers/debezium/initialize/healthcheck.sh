#!/bin/bash
set -e

# Get the list of all connectors from Debezium REST API
connectors=$(curl -s --fail --connect-timeout 2 "http://127.0.0.1:8083/connectors")

# Clean the array string and load into array
cleaned_connector_names=$(sed 's/[][]//g; s/"//g' <<<"$connectors")
IFS=',' read -r -a my_array <<<"$cleaned_connector_names"

# Check if ODSE main connector is available
if [[ " ${my_array[*]} " =~ " odse-main-connector " ]]; then
    echo "odse-main-connector is enabled"
else
    echo "odse-main-connector not found. Initializing..."
    curl -s --fail -X POST --header "Accept:application/json" --header "Content-Type:application/json" --data "@/kafka/healthcheck/odse_main_connector.json" http://localhost:8083/connectors/
fi

# Check if ODSE schema-only connector is available
if [[ " ${my_array[*]} " =~ " odse-schema-only-connector " ]]; then
    echo "odse-schema-only-connector is enabled"
else
    echo "odse-schema-only-connector not found. Initializing..."
    curl -s --fail -X POST --header "Accept:application/json" --header "Content-Type:application/json" --data "@/kafka/healthcheck/odse_schema_only_connector.json" http://localhost:8083/connectors/
fi

# Check if ODSE meta connector is available
if [[ " ${my_array[*]} " =~ " odse-meta-connector " ]]; then
    echo "odse-meta-connector is enabled"
else
    echo "odse-meta-connector not found. Initializing..."
    curl -s --fail -X POST --header "Accept:application/json" --header "Content-Type:application/json" --data "@/kafka/healthcheck/odse_meta_connector.json" http://localhost:8083/connectors/
fi

# Check if SRTE connector is available
if [[ " ${my_array[*]} " =~ " srte-connector " ]]; then
    echo "srte-connector is enabled"
else
    echo "srte-connector not found. Initializing..."
    curl -s --fail -X POST --header "Accept:application/json" --header "Content-Type:application/json" --data "@/kafka/healthcheck/srte_connector.json" http://localhost:8083/connectors/
fi

exit 0
