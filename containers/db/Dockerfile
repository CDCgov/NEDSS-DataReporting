# Build the base database image
FROM ghcr.io/cdcent/nedssdb:fdbd7a 

USER mssql

ARG DATABASE_PASSWORD

ENV SQLCMDPASSWORD=${DATABASE_PASSWORD} \
    DATABASE_PASSWORD=${DATABASE_PASSWORD}

# Copy the supplemental restore files for RTR
COPY --chown=mssql ./initialize /var/opt/database/initialize/

# Run RTR specific initialization scripts 
RUN /var/opt/database/initialize/initialize.sh && \
    rm -rf /var/opt/database/*
