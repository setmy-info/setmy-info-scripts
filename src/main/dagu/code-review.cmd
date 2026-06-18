@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "WORKFLOW_NAME=%~1"
if not defined WORKFLOW_NAME set "WORKFLOW_NAME=code-review"

set "WORKFLOW_ROOT=%~dp0"
if "%WORKFLOW_ROOT:~-1%"=="\" set "WORKFLOW_ROOT=%WORKFLOW_ROOT:~0,-1%"
set "WORKFLOW_FILE=%WORKFLOW_ROOT%\%WORKFLOW_NAME%.yaml"
if not exist "%WORKFLOW_FILE%" (
  echo Workflow file not found: %WORKFLOW_FILE%
  exit /b 1
)

where dagu >nul 2>nul || (
  echo dagu is required and was not found in PATH.
  exit /b 1
)

if not defined MAIN_REPO_URL (
  echo MAIN_REPO_URL must be provided.
  exit /b 1
)

set "SOURCE_PROMPT_FILE=%PROMPT_FILE%"
if not defined SOURCE_PROMPT_FILE set "SOURCE_PROMPT_FILE=%WORKFLOW_ROOT%\PROMPT.md"
if not exist "%SOURCE_PROMPT_FILE%" (
  echo Prompt file not found: %SOURCE_PROMPT_FILE%
  exit /b 1
)

set "RUNS_ROOT=%WORKFLOW_ROOT%\runs"
if not exist "%RUNS_ROOT%" mkdir "%RUNS_ROOT%"

:allocateRunId
set "RUN_ID=%RANDOM%%RANDOM%-%RANDOM%%RANDOM%-%RANDOM%%RANDOM%"
set "RUN_ROOT=%RUNS_ROOT%\%RUN_ID%"
if exist "%RUN_ROOT%" goto allocateRunId

set "CHECKOUT_ROOT=%RUN_ROOT%\checkout"
set "RESULTS_ROOT=%RUN_ROOT%\results"
set "RESULT_FILE=%RESULTS_ROOT%\review.md"
set "COPIED_PROMPT_FILE=%RUN_ROOT%\PROMPT.md"

mkdir "%RUN_ROOT%" || exit /b 1
copy /y "%SOURCE_PROMPT_FILE%" "%COPIED_PROMPT_FILE%" >nul || exit /b 1

set "WORKFLOW_DIR=%WORKFLOW_ROOT%"
set "PROMPT_FILE=%COPIED_PROMPT_FILE%"

> "%RUN_ROOT%\run-id.txt" echo %RUN_ID%
> "%RUN_ROOT%\main-repo-url.txt" echo %MAIN_REPO_URL%

echo Prepared workflow run: %RUN_ID%
echo Run root: %RUN_ROOT%
echo Prompt file: %COPIED_PROMPT_FILE%

dagu run "%WORKFLOW_FILE%"
if errorlevel 1 (
  echo dagu run failed.
  exit /b 1
)

echo Workflow completed. Result file: %RESULT_FILE%
exit /b 0