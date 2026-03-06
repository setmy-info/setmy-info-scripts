@echo off

if "%~1"=="" (
    echo Usage: tab [URL] [URL] ...
    exit /b 1
)

:loop
if "%~1"=="" goto end
start "" "C:\Program Files\Mozilla Firefox\firefox.exe" --new-tab "%~1"
shift
goto loop

:end
