set FROM_URL=%1%
set TO_FILE=%2%
REM Windows curl doesn't support -C option. If developers install Git on PATH option, then curl is aslo installed.
REM  call curl -L -C - %FROM_URL% -o %TO_FILE%
call curl -L %FROM_URL% -o %TO_FILE%
