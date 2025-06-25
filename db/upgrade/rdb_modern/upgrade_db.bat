@REM This script is designed to be executed in Windows
@REM This Script only can be executed over a copy of RDB database without nrt_afaik tables
@REM Parameters:
@REM     server: Server Name or IP address 
@REM     database: Database Name (usually RDB_MODERN)
@REM     user: User Name  (must have permissions to create/delete objects in database)
@REM     password: User Password

@REM EXAMPLE of command to execute the script:
@REM upgrade_db.bat server_name rdb_modern my_user my_password

@echo off
setlocal EnableDelayedExpansion

:: Check if all parameters are provided
if "%~1"=="" (
    echo Usage: %0 server database user password
    exit /b 1
)
if "%~2"=="" (
    echo Usage: %0 server database user password
    exit /b 1
)
if "%~3"=="" (
    echo Usage: %0 server database user password
    exit /b 1
)
if "%~4"=="" (
    echo Usage: %0 server database user password
    exit /b 1
)

set SERVER_NAME=%1
set DATABASE=%2
set DB_USER=%3
set DB_PASS=%4

set SCRIPT_DIR=%~dp0
@REM  LOG file name "script_execution.log" 
set LOG_FILE=%SCRIPT_DIR%script_execution.log
@REM  array of folder names to execute scripts
set PATHS=(tables views functions routines remove data_load)
set ERROR_COUNT=0
@REM  array to store failed files
set FAILED_SCRIPTS=   

:: Initialize log
echo [%date% %time%] Starting script execution... >> "%LOG_FILE%"

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
        sqlcmd -S %SERVER_NAME% -d %DATABASE% -U %DB_USER% -P %DB_PASS% -i "%%F" -b >> "%LOG_FILE%" 2>&1
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
            sqlcmd -S %SERVER_NAME% -d %DATABASE% -U %DB_USER% -P %DB_PASS% -i "%%F" -b >> "%LOG_FILE%" 2>&1
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

endlocal