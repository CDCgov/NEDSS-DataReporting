# Liquibase Execution

### Environment Variable set up

The following environment variables assume a local Database instance with ODSE and RDB databases
For any other instances, update the database url and credentials appropriately.

```
export DB_USERNAME=sa
export DB_PASSWORD=fake.fake.fake.1234
export DB_URL=localhost 
export DB_ODSE=NBS_ODSE
export DB_RDB=RDB_MODERN
```

### Liquibase script execution

* Make sure you are in the following project

    * `/NEDSS-DataReporting/liquibase-service`

* Run following to execute liquibase

    * ```./gradlew update```

### Liquibase Error Handling

<b>ValidationFailedException</b>: When change is made to existing change log. This can be handled by removing the conflicting id or revert the changes.
To remove the id, the following command can be run:

```
delete from database.dbo.databasechangelog where id = 'id'
```

