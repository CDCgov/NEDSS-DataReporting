# Builder stage to compile sqlcmd from source with the latest Go compiler.
FROM golang:alpine AS builder

# Install build dependencies
RUN apk add --no-cache git

ARG SQLCMD_VERSION=1.10.0

# Clone and build sqlcmd statically
# Instead of fetching outdated pre-compiled binaries from Go releases that are compiled
# with vulnerable older Go standard libraries, we use a multi-stage build using a
# Go compiler builder to ensure everything is built with the latest secure Go release.
RUN git clone --depth 1 --branch v${SQLCMD_VERSION} https://github.com/microsoft/go-sqlcmd.git /go-sqlcmd && \
    cd /go-sqlcmd && \
    CGO_ENABLED=0 go build -ldflags="-w -s" -o /sqlcmd ./cmd/modern

FROM liquibase/liquibase:5.0.3-alpine

USER root

# Dependencies for Microsoft ODBC Driver
RUN apk update && apk upgrade --no-cache && \
    apk add --no-cache ca-certificates libc6-compat && \
    lpm add mssql --global

COPY --from=builder /sqlcmd /usr/local/bin/sqlcmd
RUN chmod +x /usr/local/bin/sqlcmd

#Copy sources
#changelog
COPY liquibase-service/src/main/resources/db/changelog /liquibase/changelog
# master
COPY liquibase-service/src/main/resources/db/001-master /liquibase/changelog
COPY liquibase-service/src/main/resources/db/001-master/functions /liquibase/changelog
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

# Onboarding
COPY liquibase-service/src/main/resources/db/001-master/02_onboarding_script_data_load/ /liquibase/changelog/02-onboarding/

#Set the Working Directory
WORKDIR /liquibase/changelog
USER liquibase

COPY --chown=liquibase liquibase-service/migrate.sh .

CMD ["./migrate.sh"]
