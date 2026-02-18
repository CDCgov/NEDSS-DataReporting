## Initialization

To initialize the connectors, a POST request must be sent to the debezium container for each conector.

```sh
curl -i -X POST -H "Accept:application/json" -H "Content-Type:application/json" localhost:8085/connectors/ -d @containers/debezium/odse_connector.json
curl -i -X POST -H "Accept:application/json" -H "Content-Type:application/json" localhost:8085/connectors/ -d @containers/debezium/odse_meta_connector.json
curl -i -X POST -H "Accept:application/json" -H "Content-Type:application/json" localhost:8085/connectors/ -d @containers/debezium/srte_connector.json
```
