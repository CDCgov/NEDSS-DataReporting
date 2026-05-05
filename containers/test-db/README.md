# Real-Time Reporting Test Database

A test database has been created to remove the requirement of running liquibase prior to test execution.

## Building a new test-db image locally
The [create_bak_files.sh](./create_bak_files.sh) script has been provided that automates the process of creating `.bak` files from a fresh database following the application of liquibase migration scripts. The script uses defaults for the database and liquibase container names that may not work on your system. A `DATABASE_CONTAINER_NAME` and `LIQUIBASE_CONTAINER_NAME` environment variable can be provided to override the defaults.

The [build_image.sh](./build_image.sh) script will utilize the newly created `.bak` files and build a ready to run database image. The script provides a default `IMAGE_NAME` that matches what is published in GHCR.

## Publishing a new test-db image in GHCR
The [publish-test-db-image.yaml](../../.github/workflows/publish-test-db-image.yaml) Github workflow handles publishing a new `test-db` image. The workflow allows manual dispatch and selection of a target branch to build from. This will allow you to build an image from your branch.

## Creating a pull request that depends on test-db changes
In order to create a pull request that modifies liquibase and have those changes be available for the Github test runner:
1. Create a new `test-db` locally using the provided scripts
2. Verify all tests are passing
3. Push the branch with your changes to Github
4. Publish a new `test-db` image by manually triggering the workflow. Be sure to target your branch
5. Once the `test-db` build is completed, create a PR