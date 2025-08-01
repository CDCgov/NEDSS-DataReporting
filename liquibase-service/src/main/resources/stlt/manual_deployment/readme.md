 # Database Upgrade Script
 

## Overview

The `upgrade_db` scripts (`upgrade_db.bat` for Windows and `upgrade_db.sh` for Linux) are designed to execute SQL scripts to upgrade each database . The scripts process `.sql` files in the script's directory and specific subdirectories (`tables`, `views`, `functions`, `routines`, `jobs`,`remove`, and optionally `data_load`). Execution details, including errors, are logged to `upgrade_db_execution.log`. 

The `upgrade_db` scripts does not require modifications, unless the subdirectories names are modified or more subdirectories are added.

Both, (Windows and Linux) scripts support the same functionality:
- Accept required parameters: `server`, `database`, `user`, `password`.
- Support help flags (`/h`, `-h`, `--help`) and an optional `--load-data` flag to include scripts in the `data_load` folder.
- Allow flexible positioning of the `--load-data` flag only for Linux version. In Windows version it must be the first parameter.
- Execute `.sql` files and report success or failure.

### SQL Scripts
- To add more SQL scripts to the upgrade process, add them to the corresponding subdirectory taking into account the required execution order managed by the script name.
- To modify tables, add "ALTER TABLE" statements on the corresponding table script or add a new script after the table creation script.
- Views, Functions, and Stored Pocedures SQL scrips are designed to drop and recreate the corresponding element.

## Pre-requisites
- Required environment variable has been inserted into NBS_ODSE's NBS_Configuration to run scripts against the selected reporting database. 
- **Database**: The following databases should exist-
  - **master**: Scripts under [001-master](../../db/001-master) are intended to be run manually and require admin permissions to run against NBS_ODSE, NBS_SRTE and the reporting database. 
    - Please review the Onboarding: Create Admin and Service Users steps under [readme.md](../../../../../readme.md) to create the necessary users. 
  - **NBS_SRTE**: Scripts under [002-srte](../../db/002-srte) will be run with the NBS_SRTE database server name. 
  - **NBS_ODSE**: Scripts under [003-odse](../../db/003-odse) will be run with the NBS_ODSE database server name.
  - Reporting Database:
    - **RDB**: If RDB is selected as the default reporting database, please ensure that scripts for RDB_MODERN are run against the RDB database server. 
    - **RDB_MODERN**: 
      - If RDB_MODERN is selected as the reporting database, please run both scripts under [004-rdb](../../db/004-rdb) with the RDB server_name and [005-rdb_modern](../../db/005-rdb_modern) with RDB_MODERN server_name. 
      - `nrt_<>` tables should not exist the first time the scripts are executed.

## Requirements

### Common Requirements
- **Database**: SQL Server 2016 or higher.
- **Database Client**: Microsoft SQL Server `sqlcmd`.
- **Permissions**: The database user must have permissions to create and delete objects in the specified database. 
- **Directory Structure**: The script expects `.sql` files in its directory and optional subdirectories: `tables`, `views`, `functions`, `routines`, `remove`, and `data_load`. Folder names are case-sensitive on Linux.

### Windows-Specific Requirements
- **Operating System**: Windows (e.g., Windows 10, Windows Server).
- **Database Client**: `sqlcmd` is typically included with SQL Server or can be installed via Microsoft SQL Server tools.

### Linux-Specific Requirements
- **Operating System**: Linux (e.g., Ubuntu, CentOS).
- **Database Client**: Install `mssql-tools` or `msodbcsql18` for `sqlcmd` (e.g., `sudo apt-get install mssql-tools` on Ubuntu). 
- **NOTE**: `mssql-tools` or `msodbcsql18` is not supported by all Ubuntu versions. Last supported version is Ubuntu 18.04 
- **Permissions**: The script must be executable (`chmod +x upgrade_db.sh`).

## Usage

Run the script from the command line with the required parameters and optional flags.

### Windows
```cmd
upgrade_db.bat [options] server database user password
```

### Linux
```bash
./upgrade_db.sh [options] server database user password
```

### Parameters
- `server`: Server name or IP address of the SQL Server instance.
- `database`: Database name (usually `RDB_MODERN`).
- `user`: Database user name with permissions to create/delete objects.
- `password`: Database user password.

### Options
- `/h`, `-h`, `--help`: Display the help message and exit.
- `--load-data`: Include scripts in the `data_load` folder (default: excluded).

### Examples

#### Windows
1. **Basic Execution** (excludes `data_load` folder):
   ```cmd
   upgrade_db.bat server_name rdb_modern my_user my_password
   ```
2. **Include `data_load` Scripts**:
   ```cmd
   upgrade_db.bat --load-data server_name rdb_modern my_user my_password
   ```
3. **Display Help**:
   ```cmd
   upgrade_db.bat --help | -h | /h
   ```
   
#### Linux
1. **Basic Execution** (excludes `data_load` folder): 
   ```bash
   ./upgrade_db.sh server_name nbs_odse my_user my_password
   ```
2. **Include `data_load` Scripts**:
   ```bash
   ./upgrade_db.sh --load-data server_name master my_user my_password
   ```
3. **Flexible Flag Positioning**:
   ```bash
   ./upgrade_db.sh --load-data server_name master my_user my_password 
    ```
   ```bash
   ./upgrade_db.sh server_name master my_user my_password --load-data
   ```
4. **Run 005-rdb_modern scripts against rdb database**: Required for environments where rdb is the default Real Time Reporting database.
   ```bash
   ./upgrade_db.sh server_name rdb my_user my_password
   ```
   Follow the prompts after selecting rdb. 
    ```text
   Selected RDB database.
   Do you want to run rdb_modern scripts in the RDB database? Enter Y to run 005-rdb_modern scripts in RDB. Select N to run 004-rdb scripts in RDB. [Y,N]?
   ```
   If 005-rdb_modern scripts are required in RDB, please select Y. 
   ```text
   Y
   User selected 'Yes'. Running modern scripts in RDB.
    ```

   If scripts are not required in RDB, please select N. This will run minimal required scripts (004-rdb) for RDB. 
   ```text
   N
   User selected 'No'. Running RDB scripts.
    ```
6. **Display Help**:
   ```bash
   ./upgrade_db.sh --help | -h | /h
   ```

## Output
- **Log File**: Execution details, including errors, are logged to `upgrade_db_execution.log` in the script's directory.
- **Console Output**: Displays progress, errors, and a summary of execution (success or failure count).
- **Exit Codes**:
  - `0`: Successful execution.
  - `1`: Error (e.g., missing parameters, directory not found, or script execution failures).

## Notes
- **Database Client**: Both scripts use `sqlcmd` for SQL Server. 
- **Password Security**: Avoid special characters in passwords or quote them properly (e.g., `"my$password"` on Windows, `'my$password'` on Linux). Alternatively, use environment variables:
  - Windows: `set DB_PASS=my$password & upgrade_db.bat server_name rdb_modern my_user %DB_PASS%`
  - Linux: `export DB_PASS="my$password"; ./upgrade_db.sh server_name rdb_modern my_user "$DB_PASS"`
- **Case Sensitivity**: Folder names and file extensions (`.sql`) are case-sensitive on Linux but not on Windows.
- **Error Handling**: The scripts stop executing subdirectory scripts if any `.sql` file in the main directory fails. Failed scripts are listed in the log and console output.
- **SQL Scripts**: Scripts are executed from liquibase-service\src\main\resources\ directory and subdirectories (`tables`, `views`, `functions`, `routines`, `remove`, and optionally `data_load`) based on the database specified. Inside each subdirectory, scripts are executed in alphabetical order. To solve script dependencies just reorder scripts in the subdirectory.

## Troubleshooting
- **sqlcmd not found**:
  - Windows: Ensure SQL Server or its tools are installed.
  - Linux: Install `mssql-tools` or `msodbcsql18` (see Microsoft documentation for Linux).
- **Permission Denied (Linux)**: Run `chmod +x upgrade_db.sh` to make the script executable.
- **Invalid Parameters**: Use `--help` to check the correct syntax.
- **No .sql Files**: Ensure `.sql` files exist in the script's directory or subdirectories.
- **Case Sensitivity (Linux)**: Verify folder names (`tables`, `data_load`, etc.) and file extensions (`.sql`) match exactly.
