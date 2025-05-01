FROM liquibase/liquibase:4.31.1-alpine

USER root

RUN apk add --no-cache wget unzip

RUN wget "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -O "awscliv2.zip" && \
  unzip awscliv2.zip && rm -rf awscliv2.zip && \
  ./aws/install


#Copy sources
#changelog
COPY liquibase-service/src/main/resources/db/changelog /liquibase/changelog
#master
COPY liquibase-service/src/main/resources/db/master /liquibase/changelog
COPY liquibase-service/src/main/resources/db/master/routines /liquibase/changelog
#odse
COPY liquibase-service/src/main/resources/db/odse /liquibase/changelog
COPY liquibase-service/src/main/resources/db/odse/routines /liquibase/changelog
COPY liquibase-service/src/main/resources/db/odse/views /liquibase/changelog
#rdb_modern
COPY liquibase-service/src/main/resources/db/rdb_modern /liquibase/changelog
COPY liquibase-service/src/main/resources/db/rdb_modern/routines /liquibase/changelog
COPY liquibase-service/src/main/resources/db/rdb_modern/tables /liquibase/changelog
COPY liquibase-service/src/main/resources/db/rdb_modern/views /liquibase/changelog
#rdb
COPY liquibase-service/src/main/resources/db/rdb /liquibase/changelog
COPY liquibase-service/src/main/resources/db/rdb/tables /liquibase/changelog
# srte
COPY liquibase-service/src/main/resources/db/srte /liquibase/changelog
COPY liquibase-service/src/main/resources/db/srte/tables /liquibase/changelog

#Set the Working Directory
WORKDIR /liquibase/changelog

USER liquibase

CMD ["sh", "-c", "tail -f /dev/null"]


