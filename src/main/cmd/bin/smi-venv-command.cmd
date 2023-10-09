if not exist ".\.venv\" (
    smi-prepare-venv
)

call .\.venv\Scripts\activate
call %*
set RESULT_CODE=%errorlevel%
call deactivate
