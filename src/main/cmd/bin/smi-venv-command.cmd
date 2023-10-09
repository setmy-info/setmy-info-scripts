if not exist ".\.venv\" (
    call smi-prepare-venv
)

call .\.venv\Scripts\activate
call %*
set RESULT_CODE=%errorlevel%
call deactivate
