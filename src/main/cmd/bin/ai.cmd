@echo off
setlocal enabledelayedexpansion

rem Try to get SMI_LIB_DIR via smi-lib-location
set SMI_LIB_DIR=
for /f "delims=" %%i in ('smi-lib-location.cmd 2^>nul') do set SMI_LIB_DIR=%%i
if "!SMI_LIB_DIR!"=="" set SMI_LIB_DIR=C:\pub\setmy.info\lib
set AI_LIB_DIR=!SMI_LIB_DIR!\ai

for %%p in (%*) do (
    call :process_arg %%p
)
goto :eof

:process_arg
set ARG=%1
set AI_FILE=!AI_LIB_DIR!\!ARG!.md
set GROUP_FILE=!AI_LIB_DIR!\!ARG!.group

if exist "!AI_FILE!" (
    for /f "usebackq tokens=*" %%l in ("!AI_FILE!") do (
        if not "%%l"=="" echo - %%l
    )
) else if exist "!GROUP_FILE!" (
    for /f "usebackq tokens=*" %%g in ("!GROUP_FILE!") do (
        if not "%%g"=="" call :process_arg %%g
    )
) else (
    echo Profile or group not found: !ARG! >&2
)
goto :eof
