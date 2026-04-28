#! /bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
CONTAINER_NAME="${CONTAINER_NAME:-rtr-nbs-mssql-1}"
SQLCMDUSER="${SQLCMDUSER:-sa}"
SQLCMDPASSWORD="${SQLCMDPASSWORD:-PizzaIsGood33!}"
IMAGE_NAME="${IMAGE_NAME:-ghcr.io/cdcgov/nedss-datareporting-mssql:6.0.18.1}"
BUILD_IMAGE="${BUILD_IMAGE:-false}"

# Create clean backups by starting a fresh nedssdb and applying liquibase migrations
echo "starting database and applying liquibase migrations..."
docker compose up nbs-mssql liquibase --build -d

# Wait for liquibase to complete
echo "waiting for liquibase to complete..."
EXIT_CODE=$(docker wait rtr-liquibase-1)
echo "liquibase completed with code: $EXIT_CODE"

# Create backups of databases
echo "creating backup of MASTER database..."
mkdir -p $SCRIPT_DIR/backups/

docker exec \
  -e SQLCMDPASSWORD="$SQLCMDPASSWORD" \
  -e SQLCMDUSER="$SQLCMDUSER" "$CONTAINER_NAME" \
  /opt/mssql-tools18/bin/sqlcmd -b -V16 -C \
  -Q "BACKUP DATABASE [MASTER] \
  TO DISK = N'/var/opt/mssql/backups/MASTER.bak' \
  WITH NOFORMAT, NOINIT, NAME = 'MASTER-full', SKIP, NOREWIND, NOUNLOAD, STATS = 10"

docker cp $CONTAINER_NAME:/var/opt/mssql/backups/MASTER.bak $SCRIPT_DIR/backups/

echo "creating backup of NBS_ODSE database..."

docker exec \
  -e SQLCMDPASSWORD="$SQLCMDPASSWORD" \
  -e SQLCMDUSER="$SQLCMDUSER" "$CONTAINER_NAME" \
  /opt/mssql-tools18/bin/sqlcmd -b -V16 -C \
  -Q "BACKUP DATABASE [NBS_ODSE] \
  TO DISK = N'/var/opt/mssql/backups/NBS_ODSE.bak' \
  WITH NOFORMAT, NOINIT, NAME = 'NBS_ODSE-full', SKIP, NOREWIND, NOUNLOAD, STATS = 10"

docker cp $CONTAINER_NAME:/var/opt/mssql/backups/NBS_ODSE.bak $SCRIPT_DIR/backups/

echo "creating backup of NBS_SRTE database..."

docker exec \
  -e SQLCMDPASSWORD="$SQLCMDPASSWORD" \
  -e SQLCMDUSER="$SQLCMDUSER" "$CONTAINER_NAME" \
  /opt/mssql-tools18/bin/sqlcmd -b -V16 -C \
  -Q "BACKUP DATABASE [NBS_SRTE] \
  TO DISK = N'/var/opt/mssql/backups/NBS_SRTE.bak' \
  WITH NOFORMAT, NOINIT, NAME = 'NBS_SRTE-full', SKIP, NOREWIND, NOUNLOAD, STATS = 10"

docker cp $CONTAINER_NAME:/var/opt/mssql/backups/NBS_SRTE.bak $SCRIPT_DIR/backups/

echo "creating backup of NBS_MSGOUTE database..."

docker exec \
  -e SQLCMDPASSWORD="$SQLCMDPASSWORD" \
  -e SQLCMDUSER="$SQLCMDUSER" "$CONTAINER_NAME" \
  /opt/mssql-tools18/bin/sqlcmd -b -V16 -C \
  -Q "BACKUP DATABASE [NBS_MSGOUTE] \
  TO DISK = N'/var/opt/mssql/backups/NBS_MSGOUTE.bak' \
  WITH NOFORMAT, NOINIT, NAME = 'NBS_MSGOUTE-full', SKIP, NOREWIND, NOUNLOAD, STATS = 10"

docker cp $CONTAINER_NAME:/var/opt/mssql/backups/NBS_MSGOUTE.bak $SCRIPT_DIR/backups/

echo "creating backup of RDB database..."

docker exec \
  -e SQLCMDPASSWORD="$SQLCMDPASSWORD" \
  -e SQLCMDUSER="$SQLCMDUSER" "$CONTAINER_NAME" \
  /opt/mssql-tools18/bin/sqlcmd -b -V16 -C \
  -Q "BACKUP DATABASE [RDB] \
  TO DISK = N'/var/opt/mssql/backups/RDB.bak' \
  WITH NOFORMAT, NOINIT, NAME = 'RDB-full', SKIP, NOREWIND, NOUNLOAD, STATS = 10"

docker cp $CONTAINER_NAME:/var/opt/mssql/backups/RDB.bak $SCRIPT_DIR/backups/

echo "creating backup of RDB_MODERN database..."

docker exec \
  -e SQLCMDPASSWORD="$SQLCMDPASSWORD" \
  -e SQLCMDUSER="$SQLCMDUSER" "$CONTAINER_NAME" \
  /opt/mssql-tools18/bin/sqlcmd -b -V16 -C \
  -Q "BACKUP DATABASE [RDB_MODERN] \
  TO DISK = N'/var/opt/mssql/backups/RDB_MODERN.bak' \
  WITH NOFORMAT, NOINIT, NAME = 'RDB_MODERN-full', SKIP, NOREWIND, NOUNLOAD, STATS = 10"

docker cp $CONTAINER_NAME:/var/opt/mssql/backups/RDB_MODERN.bak $SCRIPT_DIR/backups/

# Stop containers
echo "database backups completed and saved to $SCRIPT_DIR/backups/. Stopping docker containers"
docker compose down

# Build image from backups
if [ $BUILD_IMAGE == true ]; then
  echo "building new test-db image..."
  docker build $SCRIPT_DIR/ --platform linux/amd64 --build-arg DATABASE_PASSWORD="$SQLCMDPASSWORD" -t "$IMAGE_NAME"
fi
