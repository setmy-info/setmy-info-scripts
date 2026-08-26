@echo off
call groovy %SMI_LIB_DIR%\jenkinsfile.groovy %*%
REM call groovy .\src\main\groovy\lib\jenkinsfile.groovy %*%
REM Hand the runner's exit code back to the caller: 0 only when the pipeline succeeded.
exit /b %ERRORLEVEL%
