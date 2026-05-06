#! /bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
IMAGE_NAME="${IMAGE_NAME:-ghcr.io/cdcgov/nedss-datareporting-mssql:6.0.18.1}"
SQLCMDPASSWORD="${SQLCMDPASSWORD:-PizzaIsGood33!}"

# Build image from backups
echo "building new test-db image..."
docker build $SCRIPT_DIR/ --platform linux/amd64 --build-arg DATABASE_PASSWORD="$SQLCMDPASSWORD" -t "$IMAGE_NAME"
