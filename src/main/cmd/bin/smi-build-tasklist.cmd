@echo off

REM Copyright (C) 2026 Imre Tabur <imre.tabur@mail.ee>

REM Usage: smi-build-tasklist [--output OUTPUT_FILE] [CONTENT_FILE...]
REM If no files given, defaults to TASKLIST-CONTENT.md
REM Reads AGENTS-INTRO.md if present.
REM Reads profiles from ai.profiles if present.

set TARGET_FILE=TASKLIST.md
set INTRO_FILE=AGENTS-INTRO.md
set PROFILES_FILE=ai.profiles
set DEFAULT_CONTENT_FILE=TASKLIST-CONTENT.md

REM Parse --output option
if "%~1"=="--output" (
    set TARGET_FILE=%~2
    shift
    shift
)

REM Clear or create the target file
if exist "%INTRO_FILE%" (
    type "%INTRO_FILE%" > "%TARGET_FILE%"
) else (
    REM Start fresh if no intro
    type nul > "%TARGET_FILE%"
)

REM Add AI profiles if the file exists
if exist "%PROFILES_FILE%" (
    for /f "delims=" %%i in (%PROFILES_FILE%) do (
        set PROFILES=%%i
        goto :call_ai
    )
)
goto :after_ai

:call_ai
if not "%PROFILES%"=="" (
    call ai %PROFILES% >> "%TARGET_FILE%"
)

:after_ai
echo.>> "%TARGET_FILE%"

REM Append content files
if "%~1"=="" (
    if exist "%DEFAULT_CONTENT_FILE%" (
        type "%DEFAULT_CONTENT_FILE%" >> "%TARGET_FILE%"
    )
) else (
    :loop
    if "%~1"=="" goto end
    if exist "%~1" (
        type "%~1" >> "%TARGET_FILE%"
    )
    shift
    goto loop
)

:end
exit /b 0
