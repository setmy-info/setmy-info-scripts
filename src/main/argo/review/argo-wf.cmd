@echo off

set REPO_LIST=%1
if "%REPO_LIST%"=="" set REPO_LIST="[{\"url\": \"git@bitbucket.org:example/example-app.git\", \"branch\": \"master\", \"from\": \"HEAD~1\", \"to\": \"HEAD\"}]"
set MAIN_PROJECT_FOLDER=%2
if "%MAIN_PROJECT_FOLDER%"=="" set MAIN_PROJECT_FOLDER=example-app
set AGENT=%3
if "%AGENT%"=="" set AGENT=claude
set MODE=%4
if "%MODE%"=="" set MODE=review
for /f "tokens=*" %%a in ('uuid') do set UUID=%%a

set CLONES_DIR=clones

mkdir %CLONES_DIR%

echo Submitting Argo Workflow with repo-list: %REPO_LIST% (main-project-folder: %MAIN_PROJECT_FOLDER%, agent: %AGENT%, mode: %MODE%, uuid: %UUID%)
argo submit -n review --watch ^
    -p repo-list=%REPO_LIST% ^
    -p main-project-folder=%MAIN_PROJECT_FOLDER% ^
    -p agent=%AGENT% ^
    -p mode=%MODE% ^
    -p uuid=%UUID% ^
    argo-wf.yaml

echo All done.
