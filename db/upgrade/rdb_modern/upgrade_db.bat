@REM This script is designed to be executed on Windows
@REM Required Parameters:
@REM     server: Server Name or IP address 
@REM     database: Database Name
@REM     user: User Name  
@REM     password: User Password

@REM Optional Parameters:
@REM    --load-data: Include or not the load_data subdirectory    

@REM Usage:
@REM upgrade_db.bat server_name rdb_modern my_user my_password
@REM upgrade_db.bat --load-data server_name rdb_modern my_user my_password

@echo off
setlocal EnableDelayedExpansion

:: Check for help flag
if /i "%1"=="/h" goto help
if /i "%1"=="-h" goto help
if /i "%1"=="--help" goto help

:: Parse optional --load-data flag
set "load_data=false"
if /i "%1"=="--load-data" (
    set "load_data=true"
    shift
)

:: Check if all parameters are provided
if "%~1"=="" (
    echo Usage: %0 [options] server database user password
    echo Type %0 /h for help
    exit /b 1
)
if "%~2"=="" (
    echo Usage: %0 [options] server database user password
    echo Type %0 /h for help
    exit /b 1
)
if "%~3"=="" (
    echo Usage: %0 [options] server database user password
    echo Type %0 /h for help
    exit /b 1
)
if "%~4"=="" (
    echo Usage: %0 [options] server database user password
    echo Type %0 /h for help
    exit /b 1
)

set SERVER_NAME=%1
set DATABASE=%2
set DB_USER=%3
set DB_PASS=%4

set SCRIPT_DIR=%~dp0
@REM  LOG file name "upgrade_db_execution.log" 
set LOG_FILE=%SCRIPT_DIR%upgrade_db_execution.log
@REM  array of folder names to execute scripts
set PATHS=(tables views functions routines remove)
if "!load_data!"=="true" (
    set "PATHS=(tables views functions routines remove data_load)"
) 
set ERROR_COUNT=0
@REM  array to store failed files
set FAILED_SCRIPTS=   

:: Initialize log
echo [%date% %time%] Starting script execution... >> "%LOG_FILE%"
if "!load_data!"=="true" (
    echo [%date% %time%] Load Data scripts have been included >> "%LOG_FILE%"
) else (
    echo [%date% %time%] Load Data scripts have been excluded >> "%LOG_FILE%"
)
echo [%date% %time%] Executing SQL scripts from current folder and children folders !PATHS!... >> "%LOG_FILE%"

:: Check if directory exists
if not exist "%SCRIPT_DIR%" (
    echo Directory not found: !SCRIPT_DIR!
    echo [%date% %time%] Directory not found: !SCRIPT_DIR! >> "%LOG_FILE%"
    exit /b 1
) else (
    :: Loop through all .sql files in the current directory
    for %%F in ("%SCRIPT_DIR%*.sql") do (
        echo Executing %%F...
        echo [%date% %time%] Executing %%F... >> "%LOG_FILE%"
        :: Using sqlcmd for SQL Server; modify if using a different database client
        sqlcmd -S %SERVER_NAME% -d %DATABASE% -U %DB_USER% -P %DB_PASS% -i "%%F" -b -C >> "%LOG_FILE%" 2>&1
        set CURRENT_ERROR=!errorlevel!
        if !CURRENT_ERROR! neq 0 (
            echo error: !CURRENT_ERROR! 
            echo Error executing %%F. Errorlevel: !CURRENT_ERROR!            
            echo [%date% %time%] Error executing %%F. Errorlevel: !CURRENT_ERROR! >> "%LOG_FILE%"
            set /a ERROR_COUNT+=1
            set FAILED_SCRIPTS=!FAILED_SCRIPTS! "%%F"
        )
    )
)

if !ERROR_COUNT! equ 0 (

    for %%p in %PATHS% do (
        set "f_dir=%SCRIPT_DIR%%%p\"

        for %%F in ("!f_dir!*.sql") do (
            echo Executing %%F...
            echo [%date% %time%] Executing %%F... >> "%LOG_FILE%"
            :: Using sqlcmd for SQL Server; modify if using a different database client
            sqlcmd -S %SERVER_NAME% -d %DATABASE% -U %DB_USER% -P %DB_PASS% -i "%%F" -b -C >> "%LOG_FILE%" 2>&1
            set CURRENT_ERROR=!errorlevel!
            if !CURRENT_ERROR! neq 0 (
                echo Error executing %%F. Errorlevel: !CURRENT_ERROR!
                echo [%date% %time%] Error executing %%F. Errorlevel: !CURRENT_ERROR! >> "%LOG_FILE%"
                set /a ERROR_COUNT+=1
                set FAILED_SCRIPTS=!FAILED_SCRIPTS! "%%F"
            )
        )
    )
)


if !ERROR_COUNT! equ 0 (
    echo Summary: All scripts executed successfully...
) else (
    echo Errors: !ERROR_COUNT! Scripts failed
    echo [%date% %time%] Errors: !ERROR_COUNT! Scripts have failed >> "%LOG_FILE%"
    for %%f in (%FAILED_SCRIPTS%) do (
        echo    - %%f
        echo    - %%f >> "%LOG_FILE%"
    )
    
)

exit /b 0

:help
echo Usage: %0 [options] server database user password
echo.
echo This script executes SQL scripts to upgrade the RDB_MODERN database.
echo.
echo Required Parameters:
echo   server            Server Name or IP address
echo   database          Database Name
echo   user              User Name (must have permissions to create/delete objects in database)
echo   password          User Password
echo.
echo Options:
echo   /h, -h, --help    Display this help message
echo   --load-data       Execute scripts in the data_load folder (default: false)
echo.
echo Examples:
echo   %0 server_name rdb_modern my_user my_password 
echo   %0 --load-data server_name rdb_modern my_user my_password  
exit /b 0


endlocal