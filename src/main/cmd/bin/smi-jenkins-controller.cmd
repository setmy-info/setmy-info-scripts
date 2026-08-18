@echo off
setlocal EnableExtensions

REM Windows is always development mode. See smi-jenkins-controller(1).

if not defined SMI_JENKINS_HOST set "SMI_JENKINS_HOST=127.0.0.1"
if not defined SMI_JENKINS_PORT set "SMI_JENKINS_PORT=7070"

:parse
if "%~1"=="" goto parsed
if /i "%~1"=="--host" (
    if "%~2"=="" goto value_required
    set "SMI_JENKINS_HOST=%~2"
    shift & shift & goto parse
)
if /i "%~1"=="--port" (
    if "%~2"=="" goto value_required
    set "SMI_JENKINS_PORT=%~2"
    shift & shift & goto parse
)
if /i "%~1"=="--home" (
    if "%~2"=="" goto value_required
    set "SMI_JENKINS_HOME=%~2"
    shift & shift & goto parse
)
if /i "%~1"=="--help" goto usage
if /i "%~1"=="-h" goto usage

:parsed
set "JENKINS_ARGS="

:collect
if "%~1"=="" goto run
set "JENKINS_ARGS=%JENKINS_ARGS% %1"
shift
goto collect

:run
if not defined JENKINS_DIR set "JENKINS_DIR=C:\pub\jenkins"
if not defined JENKINS_WAR set "JENKINS_WAR=%JENKINS_DIR%\jenkins.war"
if not defined SMI_JENKINS_WAR set "SMI_JENKINS_WAR=%JENKINS_WAR%"
if not defined SMI_JENKINS_HOME set "SMI_JENKINS_HOME=%USERPROFILE%\.setmy.info\.jenkins"

if not exist "%SMI_JENKINS_WAR%" (
    >&2 echo ERROR: %SMI_JENKINS_WAR%: not found
    exit /b 1
)

if not exist "%SMI_JENKINS_HOME%" mkdir "%SMI_JENKINS_HOME%" || exit /b 1

set "JENKINS_HOME=%SMI_JENKINS_HOME%"

if not defined JENKINS_ADMIN_PASSWORD set "JENKINS_ADMIN_PASSWORD=bf69e89292704227868d15617de7e802"

cd /d "%JENKINS_DIR%"

java %JAVA_OPTS% -jar "%SMI_JENKINS_WAR%" --httpListenAddress=%SMI_JENKINS_HOST% --httpPort=%SMI_JENKINS_PORT% --enable-future-java%JENKINS_ARGS%
exit /b %ERRORLEVEL%

:value_required
>&2 echo ERROR: %~1: option requires a value
exit /b 1

:usage
echo Usage: smi-jenkins-controller [--host HOST] [--port PORT] [--home DIR] [JENKINS_ARGS...]
echo.
echo Starts the Jenkins controller. All arguments after wrapper options are passed
echo to jenkins.war unchanged.
echo.
echo Windows runs in development mode only:
echo.
echo             home: %%USERPROFILE%%\.setmy.info\.jenkins
echo             war : %%JENKINS_DIR%%\jenkins.war
echo             host: 127.0.0.1
echo.
echo Environment variables:
echo   SMI_JENKINS_HOST    Listen address  (default: 127.0.0.1)
echo   SMI_JENKINS_PORT    HTTP port       (default: 7070)
echo   SMI_JENKINS_HOME    Jenkins home    (default: %%USERPROFILE%%\.setmy.info\.jenkins)
echo   SMI_JENKINS_WAR     WAR file        (default: %%JENKINS_DIR%%\jenkins.war)
echo   JAVA_OPTS           Additional JVM options
echo.
echo Precedence: --host/--port/--home ^> environment variable ^> default
echo.
echo Pass-through arguments containing '=' must be quoted, because cmd.exe
echo splits an unquoted NAME=VALUE argument into two arguments.
echo.
echo Examples:
echo   smi-jenkins-controller
echo   smi-jenkins-controller --port 8080
echo   smi-jenkins-controller --home %%USERPROFILE%%\temp\jenkins
echo   smi-jenkins-controller --port 8080 "--prefix=/jenkins"
exit /b 0
