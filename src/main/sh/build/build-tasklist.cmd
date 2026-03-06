@echo off

REM Copyright (C) 2026 Imre Tabur <imre.tabur@mail.ee>
REM Usage: .\src\main\sh\build\build-tasklist.cmd [file1.md file2.md ...]
REM If no files given, defaults to TASKLIST-CONTENT.md

type src\main\resources\tasklist\AGENTS-INTRO.md > TASKLIST.md
call src\main\cmd\bin\ai.cmd sh linux setmy-info-scripts cmake groovy git cleancode bottom-up fhs >> TASKLIST.md
echo.>> TASKLIST.md
echo ## Tasklist >> TASKLIST.md
echo.>> TASKLIST.md

if "%~1"=="" (
    type TASKLIST-CONTENT.md >> TASKLIST.md
) else (
    :loop
    if "%~1"=="" goto end
    type "%~1" >> TASKLIST.md
    shift
    goto loop
)

:end
exit /b 0
