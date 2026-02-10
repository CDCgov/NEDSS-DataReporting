# Build the base database image
FROM ghcr.io/cdcent/nedssdb:fdbd7a 

USER mssql

ARG DATABASE_BACKUP
ARG DATABASE_PASSWORD
ARG DB_VERSION
ARG RUN_SEEDING

ENV ACCEPT_EULA=Y \
    MSSQL_PID='Developer' \
    SQLCMDPASSWORD=${DATABASE_PASSWORD} \
    MSSQL_SA_PASSWORD=${DATABASE_PASSWORD} \
    BUILD_DATABASE_PASSWORD=${DATABASE_PASSWORD} \
    DATABASE_PASSWORD=${DATABASE_PASSWORD} \
    PATH="$PATH:/opt/mssql/bin:/opt/mssql-tools18/bin" \
    MIGRATIONS_DIR="/var/data/migrations" \
    SEED_DATA_DIR="/var/data/seed_data"

# Copy the supplemental restore files for RTR
COPY --chown=mssql ./initialize /var/opt/database/initialize/

# Run RTR specific initialization scripts 
RUN /opt/mssql/bin/sqlservr & \
    /var/opt/database/initialize/initialize.sh && \
    rm -rf /var/opt/database/*

ENTRYPOINT [ "/entrypoint.sh" ]
