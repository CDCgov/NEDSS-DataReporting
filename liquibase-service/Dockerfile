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

#Copy liquibase source files
COPY liquibase-service/src/main/resources/db /liquibase/

#Set the Working Directory
WORKDIR /liquibase
USER liquibase

COPY --chown=liquibase liquibase-service/migrate.sh .

CMD ["./migrate.sh"]
