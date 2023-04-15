@echo off

REM C:\pub\term\term.cmd

REM windows symbolic link target as:
REM C:\Windows\System32\cmd.exe /k C:\pub\term\bin\term.cmd latest
REM or
REM C:\Windows\System32\cmd.exe /k C:\pub\term\bin\term.cmd jdk17 mvn ant gradle node groovy mn grails jfx python smi leiningen cmake
REM Start in: C:\sources

set PATH_BACKUP=%PATH%
set PUB_DIR=C:\pub
set SMI_HOME=%PUB_DIR%\setmy.info
set SMI_BIN_DIR=%SMI_HOME%\bin
set SMI_LIB_DIR=%SMI_HOME%\lib

set TERM_PROFILES_DIR=%SMI_LIB_DIR%\profiles
set LOADER_CMD=%SMI_LIB_DIR%\loader.cmd

set EXECUTABLE_NAME=%0
set FIRST_PARAMETER=%1
set ALL_PARAMETERS=%*

call %LOADER_CMD% %ALL_PARAMETERS%
