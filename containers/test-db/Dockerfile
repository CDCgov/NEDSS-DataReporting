FROM mcr.microsoft.com/mssql/server:2022-CU23-ubuntu-22.04 AS builder

ARG DATABASE_PASSWORD

# Required MS SQL Server configuration/licensing.
# SQLCMDPASSWORD is explicitly set to allow initialization scripts to
# connect to the database non-interactively.
ENV ACCEPT_EULA=Y \
    MSSQL_PID='Developer' \
    MSSQL_SA_PASSWORD=${DATABASE_PASSWORD} \
    SQLCMDPASSWORD=${DATABASE_PASSWORD}

USER root

RUN apt-get update \
    && apt-get install --no-install-recommends unixodbc-dev bzip2 -y

# Add mssql, mssql-tools to PATH
ENV PATH="$PATH:/opt/mssql/bin:/opt/mssql-tools18/bin"

# copy backups
COPY ./backups/ /tmp/snapshots/

# Copy the initialization scripts to restore the database backups
COPY --chown=mssql ./initialize /var/opt/database/initialize/

# 1. unzip all the database snapshots archives
# 2. move the snapshot files into the initialize directory
# 3. change the ownership of the snapshot files to mssql
# 4. remove the original archived files
# 5. start the database and execute initialization scripts so the data becomes part of the image
# 6. remove all the snapshot files
RUN mv /tmp/snapshots/*.bak /var/opt/database/initialize/restore.d/ && \
    chown mssql:mssql /var/opt/database/initialize/restore.d/*.bak && \
    rm -rf /tmp/snapshots && \
    /var/opt/database/initialize/initialize.sh && \
    /var/opt/database/initialize/initialize_master.sh  && \
    rm -rf /var/opt/database/initialize/restore.d/*.bak

# Copy data into final image
FROM ghcr.io/cdcent/nedssdb:latest

COPY --chown=mssql:mssql --from=builder /var/opt/mssql /var/opt/mssql
