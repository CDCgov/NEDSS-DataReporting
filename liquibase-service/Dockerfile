FROM liquibase/liquibase:4.32.0-alpine

USER root

RUN apk add --no-cache wget unzip

RUN wget "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -O "awscliv2.zip" && \
  unzip awscliv2.zip && rm -rf awscliv2.zip && \
  ./aws/install


#Copy sources
#changelog
COPY liquibase-service/src/main/resources/db/changelog /liquibase/changelog
#master
COPY liquibase-service/src/main/resources/db/001-master /liquibase/changelog
COPY liquibase-service/src/main/resources/db/001-master/routines /liquibase/changelog
COPY liquibase-service/src/main/resources/db/001-master/functions /liquibase/changelog
# srte
COPY liquibase-service/src/main/resources/db/002-srte /liquibase/changelog
COPY liquibase-service/src/main/resources/db/002-srte/tables /liquibase/changelog
#odse
COPY liquibase-service/src/main/resources/db/003-odse /liquibase/changelog
COPY liquibase-service/src/main/resources/db/003-odse/routines /liquibase/changelog
COPY liquibase-service/src/main/resources/db/003-odse/functions /liquibase/changelog
COPY liquibase-service/src/main/resources/db/003-odse/views /liquibase/changelog
#rdb
COPY liquibase-service/src/main/resources/db/004-rdb /liquibase/changelog
COPY liquibase-service/src/main/resources/db/004-rdb/tables /liquibase/changelog
#rdb_modern
COPY liquibase-service/src/main/resources/db/005-rdb_modern /liquibase/changelog
COPY liquibase-service/src/main/resources/db/005-rdb_modern/routines /liquibase/changelog
COPY liquibase-service/src/main/resources/db/005-rdb_modern/functions /liquibase/changelog
COPY liquibase-service/src/main/resources/db/005-rdb_modern/tables /liquibase/changelog
COPY liquibase-service/src/main/resources/db/005-rdb_modern/views /liquibase/changelog


#Set the Working Directory
WORKDIR /liquibase/changelog

USER liquibase

CMD ["sh", "-c", "tail -f /dev/null"]


