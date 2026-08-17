@echo off
setlocal

REM smi-sendmail.cmd recipient "subject" "message body" [host[:port]]

if not defined SMI_SMTP_HOST set SMI_SMTP_HOST=127.0.0.1
if not defined SMI_SMTP_PORT set SMI_SMTP_PORT=3025
if not defined SMI_SMTP_USER set SMI_SMTP_USER=%USERNAME%
if not defined SMI_SMTP_PASSWORD set SMI_SMTP_PASSWORD=%USERNAME%123
if not defined SMI_SMTP_FROM set SMI_SMTP_FROM=%USERNAME%@smtp.test

if "%~1"=="" (
    echo Usage: smi-sendmail.cmd RECIPIENT SUBJECT [MESSAGE [HOST[:PORT]]]
    exit /b 1
)
if "%~2"=="" (
    echo Usage: smi-sendmail.cmd RECIPIENT SUBJECT [MESSAGE [HOST[:PORT]]]
    exit /b 1
)

set TO=%~1
set SUBJECT=%~2
set BODY=%~3

if not "%~4"=="" (
    for /f "tokens=1,2 delims=:" %%a in ("%~4") do (
        set SMI_SMTP_HOST=%%a
        if not "%%b"=="" set SMI_SMTP_PORT=%%b
    )
)

(
    echo From: %SMI_SMTP_FROM%
    echo To: %TO%
    echo Subject: %SUBJECT%
    echo.
    echo %BODY%
) > "%TEMP%\smi-sendmail-message.txt"

curl.exe ^
    --url smtp://%SMI_SMTP_HOST%:%SMI_SMTP_PORT% ^
    --mail-from "%SMI_SMTP_FROM%" ^
    --mail-rcpt "%TO%" ^
    --user "%SMI_SMTP_USER%:%SMI_SMTP_PASSWORD%" ^
    --upload-file "%TEMP%\smi-sendmail-message.txt"

set RESULT=%ERRORLEVEL%

del "%TEMP%\smi-sendmail-message.txt" >nul 2>&1

exit /b %RESULT%
