## Post Processing Service

### Run on Your Host Machine
The following instructions require that the Kafka and Database containers are running at a minimum. Also note that `application-local.yaml` is included in `.gitignore` so keep this file stored somewhere for reuse.

1. Create the properties file `src/main/resources/application-local.yaml` and populate with the following content:
```yaml
spring:
  kafka:
    group-id: ${KAFKA_CONSUMER_APP:post-processing-reporting-consumer-app}
    bootstrap-servers: ${KAFKA_BOOTSTRAP_SERVER:localhost:9092}
  datasource:
    password: ${DB_PASSWORD:PizzaIsGood33!}
    username: ${DB_USERNAME:sa}
    url: ${DB_HOST:jdbc:sqlserver://localhost:3433;databaseName=RDB_MODERN;encrypt=true;trustServerCertificate=true;}
```
2. Ensure the `kafka` and `rtr-mssql` containers running. <em>You likely want all your RTR containers running for complete testing!</em>
```shell
docker ps -a -f "name=kafka$" -f "name=rtr-mssql$"
```
3. In the root of this repository execute the following command (this service is configured to run in debug mode on port 17070 in `build.gradle` by previous dev team).
```shell
./gradlew :post-processing-service:bootRun --args='--spring.profiles.active=local'
```