@echo off
setlocal

if "%~1"=="" (
    echo Usage:
    echo   cl file name [arguments...]
    echo Example:
    echo   cl build foo bar
    echo   ^(executes build.lisp^)
    exit /b 1
)

set SCRIPT=%~1
shift

if /i not "%SCRIPT:~-5%"==".lisp" (
    set SCRIPT=%SCRIPT%.lisp
)

if not exist "%SCRIPT%" (
    echo ERROR: Ei leia %SCRIPT%
    exit /b 1
)


sbcl --script "%SCRIPT%" %*

endlocal
