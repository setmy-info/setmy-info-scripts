@echo off
if "%SMI_HOME_DIR%"=="" (
    set SMI_HOME_DIR=%USERPROFILE%\.setmy.info
)
echo %SMI_HOME_DIR%
