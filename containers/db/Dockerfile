# Build the base database image
FROM mcr.microsoft.com/mssql/server:2022-latest AS build

# The name of the golden backup to initially restore the DB with
ARG DATABASE_BACKUP
ARG DATABASE_PASSWORD
ARG DB_VERSION
ARG RUN_SEEDING

ENV ACCEPT_EULA=Y \
    MSSQL_PID='Developer' \
    SQLCMDPASSWORD=${DATABASE_PASSWORD} \
    MSSQL_SA_PASSWORD=${DATABASE_PASSWORD} 

USER root

RUN apt-get update \
    && apt-get install mssql-tools18 unixodbc-dev bzip2 -y

COPY --chown=mssql ./NEDSSDB/initialize /var/opt/database/initialize/

# Copy the specified golden snapshot archives into the container, unzip its contents 
# and move the backup files into the initialize directory
COPY ./NEDSSDB/src/golden_backups/${DATABASE_BACKUP} /tmp/snapshots/

RUN bunzip2 /tmp/snapshots/NBS_MSGOUTE.bak.bz2 \
    /tmp/snapshots/NBS_ODSE.bak.bz2 \
    /tmp/snapshots/NBS_SRTE.bak.bz2 \
    /tmp/snapshots/RDB.bak.bz2 && \
    mv /tmp/snapshots/*.bak /var/opt/database/initialize/restore.d/ && \
    chown mssql:mssql /var/opt/database/initialize/restore.d/*.bak && \
    rm -rf /tmp/snapshots

USER mssql

ENV DB_VERSION=${DB_VERSION} \
    RUN_SEEDING=${RUN_SEEDING}

# Start the database and execute initialization scripts so the data becomes part of the base image, then remove the .bak files
# This is intended for development only
RUN /opt/mssql/bin/sqlservr & \
    /var/opt/database/initialize/initialize.sh && \
    rm -rf /var/opt/database/*


# Copy the migration scripts
WORKDIR /tmp/db
COPY --chown=mssql ./NEDSSDB/src/migrations /tmp/db/src/migrations/
COPY --chown=mssql ./NEDSSDB/src/seed_data /tmp/db/src/seed_data/
COPY --chown=mssql ./NEDSSDB/init-migrations.sh /tmp/db/init-migrations.sh
COPY --chown=mssql ./NEDSSDB/run_migrations.sh /tmp/db/run_migrations.sh

# Execute migration scripts and remove files
ENV PATH="/opt/mssql-tools18/bin:${PATH}"
RUN /opt/mssql/bin/sqlservr & \
    ./init-migrations.sh 

# Copy the supplemental restore files for rtr
COPY --chown=mssql ./initialize /var/opt/database/initialize/

RUN /opt/mssql/bin/sqlservr & \
    /var/opt/database/initialize/initialize.sh && \
    rm -rf /var/opt/database/*

# Copy database files into final image (reduces image size by approx 2GB)
FROM mcr.microsoft.com/mssql/server:2022-latest
COPY --from=build /var/opt/mssql /var/opt/mssql

USER root

# Update and Enable SQL Agent
RUN apt-get update \
    && apt-get install mssql-tools18 unixodbc-dev -y \
    && /opt/mssql/bin/mssql-conf set sqlagent.enabled true

# The `-T 460` flag enables better sql truncation errors in the logs
ENTRYPOINT [ "/opt/mssql/bin/sqlservr", "-T", "460" ]
