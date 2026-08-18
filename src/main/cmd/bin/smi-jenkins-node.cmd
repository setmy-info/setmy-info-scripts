@echo off
setlocal EnableExtensions

REM Windows is always development mode. See smi-jenkins-node(1).

if not defined SMI_JENKINS_CONTROLLER_HOST set "SMI_JENKINS_CONTROLLER_HOST=127.0.0.1"
if not defined SMI_JENKINS_CONTROLLER_PORT set "SMI_JENKINS_CONTROLLER_PORT=7070"
if not defined SMI_JENKINS_NODE_NAME set "SMI_JENKINS_NODE_NAME=%COMPUTERNAME%"

:parse
if "%~1"=="" goto parsed
if /i "%~1"=="--host" (
    if "%~2"=="" goto value_required
    set "SMI_JENKINS_CONTROLLER_HOST=%~2"
    shift & shift & goto parse
)
if /i "%~1"=="--port" (
    if "%~2"=="" goto value_required
    set "SMI_JENKINS_CONTROLLER_PORT=%~2"
    shift & shift & goto parse
)
if /i "%~1"=="--name" (
    if "%~2"=="" goto value_required
    set "SMI_JENKINS_NODE_NAME=%~2"
    shift & shift & goto parse
)
if /i "%~1"=="--workdir" (
    if "%~2"=="" goto value_required
    set "SMI_JENKINS_WORKDIR=%~2"
    shift & shift & goto parse
)
if /i "%~1"=="--help" goto usage
if /i "%~1"=="-h" goto usage

:parsed
set "AGENT_ARGS="

:collect
if "%~1"=="" goto run
set "AGENT_ARGS=%AGENT_ARGS% %1"
shift
goto collect

:run
if not defined SMI_JENKINS_SECRET (
    >&2 echo ERROR: SMI_JENKINS_SECRET is not set
    exit /b 1
)

if not defined JENKINS_DIR set "JENKINS_DIR=C:\pub\jenkins"
if not defined JENKINS_AGENT_JAR (
    if exist "%JENKINS_DIR%\jenkins-agent.jar" (
        set "JENKINS_AGENT_JAR=%JENKINS_DIR%\jenkins-agent.jar"
    ) else (
        set "JENKINS_AGENT_JAR=%JENKINS_DIR%\agent.jar"
    )
)
if not defined SMI_JENKINS_AGENT set "SMI_JENKINS_AGENT=%JENKINS_AGENT_JAR%"
if not defined SMI_JENKINS_HOME set "SMI_JENKINS_HOME=%USERPROFILE%\.setmy.info\.jenkins"
if not defined SMI_JENKINS_WORKDIR set "SMI_JENKINS_WORKDIR=%SMI_JENKINS_HOME%\nodes\%SMI_JENKINS_NODE_NAME%"

if not exist "%SMI_JENKINS_AGENT%" (
    >&2 echo ERROR: %SMI_JENKINS_AGENT%: not found
    exit /b 1
)

if not exist "%SMI_JENKINS_WORKDIR%" mkdir "%SMI_JENKINS_WORKDIR%" || exit /b 1

java %JAVA_OPTS% -jar "%SMI_JENKINS_AGENT%" -url http://%SMI_JENKINS_CONTROLLER_HOST%:%SMI_JENKINS_CONTROLLER_PORT%/ -secret %SMI_JENKINS_SECRET% -name "%SMI_JENKINS_NODE_NAME%" -workDir "%SMI_JENKINS_WORKDIR%" -webSocket%AGENT_ARGS%
exit /b %ERRORLEVEL%

:value_required
>&2 echo ERROR: %~1: option requires a value
exit /b 1

:usage
echo Usage: smi-jenkins-node [--host HOST] [--port PORT] [--name NAME] [--workdir DIR] [AGENT_ARGS...]
echo.
echo Connects this machine to a Jenkins controller as an agent node.
echo All arguments after wrapper options are passed to the agent JAR unchanged.
echo.
echo Windows runs in development mode only:
echo.
echo             nodes: %%USERPROFILE%%\.setmy.info\.jenkins\nodes
echo             jar  : %%JENKINS_DIR%%\agent.jar
echo.
echo The work directory of a node is the NAME directory under the nodes
echo directory, so several nodes can run side by side.
echo.
echo Environment variables:
echo   SMI_JENKINS_CONTROLLER_HOST    Controller host   (default: 127.0.0.1)
echo   SMI_JENKINS_CONTROLLER_PORT    Controller port   (default: 7070)
echo   SMI_JENKINS_NODE_NAME          Node name         (default: %%COMPUTERNAME%%)
echo   SMI_JENKINS_WORKDIR            Agent work dir    (default: NODES\NAME)
echo   SMI_JENKINS_AGENT              Agent JAR file    (default: %%JENKINS_DIR%%\agent.jar)
echo   SMI_JENKINS_HOME               Jenkins home      (default: %%USERPROFILE%%\.setmy.info\.jenkins)
echo   SMI_JENKINS_SECRET             Agent secret      (required, no default)
echo   JAVA_OPTS                      Additional JVM options
echo.
echo Precedence: --host/--port/--name/--workdir ^> environment variable ^> default
echo The secret must be provided via SMI_JENKINS_SECRET only (never via CLI).
echo.
echo Pass-through arguments containing '=' must be quoted, because cmd.exe
echo splits an unquoted NAME=VALUE argument into two arguments.
echo.
echo Examples:
echo   set SMI_JENKINS_SECRET=abc123
echo   smi-jenkins-node
echo   smi-jenkins-node --name build-01
echo   smi-jenkins-node --workdir %%USERPROFILE%%\temp\jenkins
exit /b 0
