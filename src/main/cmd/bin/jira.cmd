@echo off
set JIRA_URL_FILE=%USERPROFILE%\.setmy.info\jira.url
if not exist "%JIRA_URL_FILE%" (
    echo Jira URL file not found: %JIRA_URL_FILE%
    echo Please create it with your Jira base URL, e.g., JIRA_BASE_URL=https://jira.example.com/browse/
    exit /b 1
)

for /f "tokens=1,2 delims==" %%a in (%JIRA_URL_FILE%) do (
    if "%%a"=="JIRA_BASE_URL" set JIRA_BASE_URL=%%b
)

if "%JIRA_BASE_URL%"=="" (
    set /p JIRA_BASE_URL=<%JIRA_URL_FILE%
)

if "%1"=="" (
    echo Usage: jira [TASK_ID]
    exit /b 1
)

start "" "C:\Program Files\Mozilla Firefox\firefox.exe" --new-tab %JIRA_BASE_URL%%1
