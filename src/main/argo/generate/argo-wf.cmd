@echo off
rem Submit the Minikube Argo Workflow with a freshly generated UUID.
rem
rem Usage:
rem   argo-wf.cmd [cc [org [prompt_file [model]]]]
rem
rem Examples:
rem   argo-wf.cmd
rem   argo-wf.cmd ee has
rem   argo-wf.cmd ee has PROMPT.md claude-opus-4-8
rem
rem Supported models: claude-opus-4-8  claude-sonnet-4-6  claude-haiku-4-5

set CC=%1
if "%CC%"=="" set CC=ee
set ORG=%2
if "%ORG%"=="" set ORG=has
set PROMPT_FILE=%3
if "%PROMPT_FILE%"=="" set PROMPT_FILE=PROMPT.md
set MODEL=%4
if "%MODEL%"=="" set MODEL=claude-sonnet-4-6

for /f "tokens=*" %%a in ('uuid') do set UUID=%%a

echo Submitting workflow: cc=%CC% org=%ORG% model=%MODEL% uuid=%UUID%

argo submit -n generator --watch ^
    -p cc=%CC% ^
    -p org=%ORG% ^
    -p uuid=%UUID% ^
    -p model=%MODEL% ^
    -p files="" ^
    09-minikube-generator-argo.yaml

echo All done.
