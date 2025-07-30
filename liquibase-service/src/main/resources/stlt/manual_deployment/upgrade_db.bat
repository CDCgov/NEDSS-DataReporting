@echo off
setlocal EnableDelayedExpansion

REM Help flag check
if /i "%1"=="/h" goto help
if /i "%1"=="-h" goto help
if /i "%1"=="--help" goto help

REM Parse optional --load-data flag
set "load_data=false"
if /i "%1"=="--load-data" (
    set "load_data=true"
    shift
)

REM Parameter check
if "%~4"=="" (
    echo Usage: %0 [options] server database user password
    echo Type %0 /h for help
    exit /b 1
)

set "SERVER_NAME=%1"
set "DATABASE=%2"
set "DB_USER=%3"
set "DB_PASS=%4"

REM Determine script directory
set "SCRIPT_DIR="
if /i "%DATABASE%"=="master" (
    set "SCRIPT_DIR=db\001-master"
) else if /i "%DATABASE%"=="nbs_srte" (
    set "SCRIPT_DIR=db\002-srte"
) else if /i "%DATABASE%"=="nbs_odse" (
    set "SCRIPT_DIR=db\003-odse"
) else if /i "%DATABASE%"=="rdb_modern" (
    set "SCRIPT_DIR=db\005-rdb_modern"
) else if /i "%DATABASE%"=="rdb" (
    echo Selected RDB database.
    choice /m "Would you like to run the rdb_modern scripts on the RDB database? Enter Y to run 005-rdb_modern scripts in RDB. Select N to run 004-rdb scripts in RDB."
	if errorlevel 2 (
		echo User selected 'No'. Running RDB scripts.
		set "SCRIPT_DIR=db\004-rdb"
	) else (
		echo User selected 'Yes'. Running modern scripts in RDB.
		set "SCRIPT_DIR=db\005-rdb_modern"
        )
) else (
    echo Unknown database: %DATABASE%
    exit /b 1
)

REM Add data load directory if required
if /i "!load_data!"=="true" (
    if /i "%DATABASE%"=="master" (
        set "SCRIPT_DIR=!SCRIPT_DIR!\02_onboarding_script_data_load"
    ) else (
        echo Load data option is only supported for 'master' database.
        exit /b 1
    )
)

REM Create timestamp for log file: yyyymmddss
for /f "tokens=1-3 delims=/" %%a in ("%date%") do (
    set "YYYY=%%c"
    set "MM=%%a"
    set "DD=%%b"
)
for /f "tokens=1-2 delims=:. " %%a in ("%time%") do (
    set "SS=%%b"
)
set "LOG_DATE=!YYYY!!MM!!DD!!SS!"
set "LOG_FILE=db\manual_run_log_!LOG_DATE!_%DATABASE%.log"

REM Optional: use a logs directory instead of db\
if not exist logs mkdir logs
set "LOG_FILE=logs\manual_run_log_!LOG_DATE!_%DATABASE%.log"

REM Determine paths to search for scripts
set "PATHS=tables views functions routines remove"
if /i "!load_data!"=="true" (
    set "PATHS=."
)

REM Logging start
echo [%date% %time%] Starting script execution... >> "!LOG_FILE!"
if "!load_data!"=="true" (
    echo [%date% %time%] Load Data scripts included >> "!LOG_FILE!"
) else (
    echo [%date% %time%] Load Data scripts excluded >> "!LOG_FILE!"
)
echo [%date% %time%] Executing SQL scripts from: !SCRIPT_DIR!\ >> "!LOG_FILE!"

REM Directory check
if not exist "!SCRIPT_DIR!" (
    echo Directory not found: !SCRIPT_DIR!
    echo [%date% %time%] Directory not found: !SCRIPT_DIR! >> "!LOG_FILE!"
    exit /b 1
)

REM Execution
set /a ERROR_COUNT=0
set "FAILED_SCRIPTS="

for %%p in (!PATHS!) do (
    set "f_dir=!SCRIPT_DIR!\%%p"
    if exist "!f_dir!" (
        for %%F in ("!f_dir!\*.sql") do (
            echo Executing %%F...
            echo [%date% %time%] Executing %%F... >> "!LOG_FILE!"
            sqlcmd -S %SERVER_NAME% -d %DATABASE% -U %DB_USER% -P %DB_PASS% -i "%%F" -I -b -C >> "!LOG_FILE!" 2>&1
            set "CURRENT_ERROR=!errorlevel!"
            if !CURRENT_ERROR! neq 0 (
                echo Error executing %%F. Errorlevel: !CURRENT_ERROR!
                echo [%date% %time%] Error executing %%F. Errorlevel: !CURRENT_ERROR! >> "!LOG_FILE!"
                set /a ERROR_COUNT+=1
                set "FAILED_SCRIPTS=!FAILED_SCRIPTS! %%F"
            )
        )
    )
)

REM Final summary
if !ERROR_COUNT! equ 0 (
    echo Summary: All scripts executed successfully.
    echo [%date% %time%] All scripts executed successfully. >> "!LOG_FILE!"
) else (
    echo Errors: !ERROR_COUNT! scripts failed.
    echo [%date% %time%] Errors: !ERROR_COUNT! scripts failed >> "!LOG_FILE!"
    for %%f in (!FAILED_SCRIPTS!) do (
        echo - %%f
        echo - %%f >> "!LOG_FILE!"
    )
)

exit /b 0

:help
echo Usage: %0 [options] server database user password
echo.
echo This script executes SQL scripts to upgrade the specified database.
echo.
echo Required Parameters:
echo   server      Server Name or IP address
echo   database    Database Name (master, rdb, odse, srte, rdb_modern)
echo   user        User Name
echo   password    User Password
echo.
echo Options:
echo   /h, -h, --help         Display this help message
echo   --load-data           Execute scripts in the data_load folder (only valid for 'master')
echo.
echo Examples:
echo   %0 my_server master my_user my_password
echo   %0 --load-data my_server master my_user my_password
exit /b 0
