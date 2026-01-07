#!/bin/sh
set -e

BASE="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

CLASSIC_PATH=$BASE/wildfly/builder/NEDSSDev
CLASSIC_VERSION=v6.0.16.0

echo "Building NBS6 Application"

if [ -d "$CLASSIC_PATH" ]; then
    echo "NEDSSDEV already cloned"
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