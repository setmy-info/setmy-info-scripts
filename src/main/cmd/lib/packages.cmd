@echo off

:downloadPackages
shift
:downloadLoop
if "%~1"=="" goto :eof
call :downloadPackage %1
shift
goto :downloadLoop

:installPackages
shift
:installLoop
if "%~1"=="" goto :eof
call :installPackage %1
shift
goto :installLoop

:downloadPackage
set PACKAGE_NAME=%1
echo Downloading package: %PACKAGE_NAME%
call :includePackage %PACKAGE_NAME%
if "%PACKAGE_DOWNLOAD_FUNC%"=="" (
    echo No download function for package: %PACKAGE_NAME%
) else (
    call %PACKAGE_FILE_TO_CALL% %PACKAGE_DOWNLOAD_FUNC%
)
goto :eof

:installPackage
set PACKAGE_NAME=%1
echo Installing package: %PACKAGE_NAME%
call :includePackage %PACKAGE_NAME%
if "%PACKAGE_INSTALL_FUNC%"=="" (
    echo No install function for package: %PACKAGE_NAME%
) else (
    call %PACKAGE_FILE_TO_CALL% %PACKAGE_INSTALL_FUNC%
)
goto :eof

:includePackage
set PACKAGE_NAME=%1
for /f "tokens=*" %%i in ('call %~dp0..\bin\smi-packages-location.cmd') do set SYSTEM_PACKAGES_DIR=%%i
for /f "tokens=*" %%i in ('call %~dp0..\bin\smi-home-packages-location.cmd') do set HOME_PACKAGES_DIR=%%i
set PACKAGE_SUFFIX=package.cmd

set SYS_PACKAGE_FILE_NAME=%SYSTEM_PACKAGES_DIR%\%PACKAGE_NAME%.%PACKAGE_SUFFIX%
set HOME_PACKAGE_FILE_NAME=%HOME_PACKAGES_DIR%\%PACKAGE_NAME%.%PACKAGE_SUFFIX%

set PACKAGE_DOWNLOAD_FUNC=
set PACKAGE_INSTALL_FUNC=
set PACKAGE_FILE_TO_CALL=

if exist "%SYS_PACKAGE_FILE_NAME%" (
    set PACKAGE_FILE_TO_CALL="%SYS_PACKAGE_FILE_NAME%"
    call "%SYS_PACKAGE_FILE_NAME%"
)
if exist "%HOME_PACKAGE_FILE_NAME%" (
    set PACKAGE_FILE_TO_CALL="%HOME_PACKAGE_FILE_NAME%"
    call "%HOME_PACKAGE_FILE_NAME%"
)
goto :eof
