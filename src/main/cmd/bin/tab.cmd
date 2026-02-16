@echo off

if "%1"=="" (
    echo Usage: tab [URL]
    exit /b 1
)

start "" "C:\Program Files\Mozilla Firefox\firefox.exe" --new-tab %1
