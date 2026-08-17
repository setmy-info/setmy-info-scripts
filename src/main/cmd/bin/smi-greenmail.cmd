@echo off

if not defined GREENMAIL_JAR set GREENMAIL_JAR=%SMI_LIB_DIR%\greenmail-standalone.jar

if not exist "%GREENMAIL_JAR%" (
    echo ERROR: %GREENMAIL_JAR%: not found
    exit /b 1
)

set GREENMAIL_WORKDIR=%USERPROFILE%\.setmy.info\greenmail
if not exist "%GREENMAIL_WORKDIR%" mkdir "%GREENMAIL_WORKDIR%"

echo Starting GreenMail...
echo.
echo SMTP   : 127.0.0.1:3025
echo SMTPS  : 127.0.0.1:3465
echo IMAP   : 127.0.0.1:3143
echo IMAPS  : 127.0.0.1:3993
echo POP3   : 127.0.0.1:3110
echo POP3S  : 127.0.0.1:3995
echo API    : http://127.0.0.1:8025
echo.
echo User   : %USERNAME%
echo Email  : %USERNAME%@smtp.test
echo Pass   : %USERNAME%123
echo.

cd /d "%GREENMAIL_WORKDIR%"

java %JAVA_OPTS% ^
    -Dgreenmail.setup.test.all ^
    -Dgreenmail.hostname=127.0.0.1 ^
    -Dgreenmail.api.hostname=127.0.0.1 ^
    -Dgreenmail.api.port=8025 ^
    "-Dgreenmail.users=%USERNAME%:%USERNAME%123@smtp.test" ^
    -jar "%GREENMAIL_JAR%" ^
    %*
