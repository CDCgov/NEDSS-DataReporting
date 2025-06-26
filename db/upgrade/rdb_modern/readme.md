# Database Upgrade Script

## Overview

The `upgrade_db` scripts (`upgrade_db.bat` for Windows and `upgrade_db.sh` for Linux) are designed to execute SQL scripts to upgrade the RDB_MODERN database . The scripts process `.sql` files in the script's directory and specific subdirectories (`tables`, `views`, `functions`, `routines`, `remove`, and optionally `data_load`). Execution details, including errors, are logged to `upgrade_db_execution.log`. 

The `upgrade_db` script do not requires modifications, unless the subdirectories names are modified or more subdirectories are added.

Both, (Windows and Linux) scripts support the same functionality:
- Accept required parameters: `server`, `database`, `user`, `password`.
- Support help flags (`/h`, `-h`, `--help`) and an optional `--load-data` flag to include scripts in the `data_load` folder.
- Allow flexible positioning of the `--load-data` flag only for Linux version. In Windows version it must be the first parameter.
- Execute `.sql` files and report success or failure.

### SQL Scripts
- To add more SQL scripts to the upgrade process, add them to the corresponding subdirectory taking into account the required execution order managed by the script name.
- To modify tables, add "ALTER TABLE" statements on the corresponding table script or add a new script after the table creation script.
- Views, Functions, and Stored Pocedures SQL scrips are designed to drop and recreate the corresponding element.

## Requirements

### Common Requirements
- **Database**: SQL Server (RDB_MODEN database without `nrt_afaik` tables the first time the script is executed).
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
   ./upgrade_db.sh server_name rdb_modern my_user my_password
   ```
2. **Include `data_load` Scripts**:
   ```bash
   ./upgrade_db.sh --load-data server_name rdb_modern my_user my_password
   ```
3. **Flexible Flag Positioning**:
   ```bash
   ./upgrade_db.sh --load-data server_name rdb_modern my_user my_password 
    ```
   ```bash
   ./upgrade_db.sh server_name rdb_modern my_user my_password --load-data
   ```
4. **Display Help**:
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
- **SQL Scripts**: Scripts are executed from current directory and subdirectories (`tables`, `views`, `functions`, `routines`, `remove`, and optionally `data_load`). Inside each subdirectory, scripts are execuetd by alphabetical order. To solve script dependencies just reorder scripts in the subdirectory.

## Troubleshooting
- **sqlcmd not found**:
  - Windows: Ensure SQL Server or its tools are installed.
  - Linux: Install `mssql-tools` or `msodbcsql18` (see Microsoft documentation for Linux).
- **Permission Denied (Linux)**: Run `chmod +x upgrade_db.sh` to make the script executable.
- **Invalid Parameters**: Use `--help` to check the correct syntax.
- **No .sql Files**: Ensure `.sql` files exist in the script's directory or subdirectories.
- **Case Sensitivity (Linux)**: Verify folder names (`tables`, `data_load`, etc.) and file extensions (`.sql`) match exactly.

## License
These scripts are provided as-is without any warranty. Modify and use them according to your project's needs.