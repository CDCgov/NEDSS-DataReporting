FROM liquibase/liquibase:5.0.3-alpine

USER root

# Dependencies for Microsoft ODBC Driver
RUN apk update && apk upgrade --no-cache && \
    apk add --no-cache ca-certificates libc6-compat && \
    lpm add mssql --global

#Copy sources
#changelog
COPY liquibase-service/src/main/resources/db/changelog /liquibase/changelog
# srte
COPY liquibase-service/src/main/resources/db/002-srte /liquibase/changelog
COPY liquibase-service/src/main/resources/db/002-srte/tables /liquibase/changelog
# odse
COPY liquibase-service/src/main/resources/db/003-odse /liquibase/changelog
COPY liquibase-service/src/main/resources/db/003-odse/views /liquibase/changelog
# rdb / rdb_modern
COPY liquibase-service/src/main/resources/db/005-rdb_modern /liquibase/changelog
COPY liquibase-service/src/main/resources/db/005-rdb_modern/routines /liquibase/changelog
COPY liquibase-service/src/main/resources/db/005-rdb_modern/functions /liquibase/changelog
COPY liquibase-service/src/main/resources/db/005-rdb_modern/tables /liquibase/changelog
COPY liquibase-service/src/main/resources/db/005-rdb_modern/views /liquibase/changelog
COPY liquibase-service/src/main/resources/db/005-rdb_modern/onboarding /liquibase/changelog

#Set the Working Directory
WORKDIR /liquibase/changelog
USER liquibase

COPY --chown=liquibase liquibase-service/migrate.sh .

CMD ["./migrate.sh"]
