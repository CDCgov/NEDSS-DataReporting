#!/bin/bash
set -e

# Get the list of all connectors from Debezium REST API
connectors=$(curl -s --fail "http://127.0.0.1:8083/connectors")

# Clean the array string and load into array
cleaned_connector_names=$(sed 's/[][]//g; s/"//g' <<< "$connectors")
IFS=',' read -r -a my_array <<< "$cleaned_connector_names"

# Check if MSQL connector is available
if [[ " ${my_array[@]} " =~ " Kafka-Connect-SqlServer-Sink " ]]; then
    echo "Kafka-Connect-SqlServer-Sink is enabled";
else
    echo "Kafka-Connect-SqlServer-Sink not found. Initializing...";
    curl -s --fail -X POST --header "Accept:application/json" --header "Content-Type:application/json" --data "@/kafka/healthcheck/mssql-connector.json" http://localhost:8083/connectors/
fi

exit 0