@echo off
setlocal

set REPO_URL=%1
set CLONE_NAME=%2
set REPO_CHECKOUT=%3

set CLONES_DIR=clones

cd %CLONES_DIR%

echo Working directory: %CD%
echo Cloning %REPO_URL% into %CLONE_NAME%...
git clone %REPO_URL% %CLONE_NAME%
cd %CLONE_NAME%
git checkout %REPO_CHECKOUT%

cd ..\..

echo Done %CLONE_NAME%
endlocal
