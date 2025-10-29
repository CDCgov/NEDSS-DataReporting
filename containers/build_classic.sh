#!/bin/sh
set -e

BASE="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

CLASSIC_PATH=$BASE/wildfly/builder/NEDSSDev
CLASSIC_VERSION=lts/6.0.16

# docker compose up mssql -d

echo "Building NBS6 Application"

if [ -d "$CLASSIC_PATH" ]; then
    echo "NEDSSDEV already cloned, verifying branch"
    pushd $CLASSIC_PATH
    git checkout $CLASSIC_VERSION && git pull
    popd
else
    echo "NEDSSDEV not found, cloning..."
    git clone -b $CLASSIC_VERSION git@github.com:cdcent/NEDSSDev.git $CLASSIC_PATH
fi

docker compose -f $BASE/../docker-compose.yaml up wildfly --build -d

echo "**** Classic build complete ****"
echo "http://localhost:7003/nbs/login"
echo ""
echo "**** Available users ****"
echo "*\tmsa"
echo "*\tsuperuser"
echo ""