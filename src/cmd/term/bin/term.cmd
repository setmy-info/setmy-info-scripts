@echo off

REM C:\pub\term\term.cmd

REM windows symbolic link target as:
REM C:\Windows\System32\cmd.exe /k C:\pub\term\bin\term.cmd latest
REM or
REM C:\Windows\System32\cmd.exe /k C:\pub\term\bin\term.cmd jdk17 mvn ant gradle node groovy mn grails jfx python smi leiningen cmake
REM Start in: C:\sources

set PUB_DIR=C:\pub
set TERM_DIR=%PUB_DIR%\term
set TERM_BIN_DIR=%TERM_DIR%\bin
set TERM_LIB_DIR=%TERM_DIR%\lib
set TERM_PROFILES_DIR=%TERM_LIB_DIR%\profiles
set LOADER_CMD=%TERM_LIB_DIR%\loader.cmd

set EXECUTABLE_NAME=%0
set FIRST_PARAMETER=%1
set ALL_PARAMETERS=%*

call %LOADER_CMD% %ALL_PARAMETERS%
