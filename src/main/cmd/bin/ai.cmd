@echo off
setlocal enabledelayedexpansion

set PATH_BACKUP=%PATH%
set PUB_DIR=C:\pub
set SMI_HOME=%PUB_DIR%\setmy.info
set SMI_BIN_DIR=%SMI_HOME%\bin
set SMI_LIB_DIR=%SMI_HOME%\lib
set TERM_PROFILES_DIR=%SMI_LIB_DIR%\profiles
set AI_PROFILES_DIR=%SMI_LIB_DIR%\ai

for %%p in (%*) do (
    call :process_arg %%p
)
goto :eof

:process_arg
set ARG=%1
set AI_FILE=!AI_PROFILES_DIR!\!ARG!.md

if exist "!AI_FILE!" (
    for /f "usebackq tokens=*" %%l in ("!AI_FILE!") do (
        if not "%%l"=="" echo %%l
    )
) else (
    echo Profile not found: !ARG! >&2
)
goto :eof
