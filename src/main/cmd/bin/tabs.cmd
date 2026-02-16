@echo off

set TABS_CONFIG_FILE=%USERPROFILE%\.setmy.info\tabs.conf

if not exist "%TABS_CONFIG_FILE%" (
    echo Tabs configuration file not found: %TABS_CONFIG_FILE%
    echo Please create it with: TABS=google.com example.com
    exit /b 1
)

for /f "tokens=1,2 delims==" %%a in (%TABS_CONFIG_FILE%) do (
    if "%%a"=="TABS" set TABS=%%b
)

if "%TABS%"=="" (
    echo TABS variable not found in %TABS_CONFIG_FILE%
    exit /b 1
)

for %%a in (%TABS%) do (
    call tab "%%a"
)
