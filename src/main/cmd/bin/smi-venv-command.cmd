if not exist ".\.venv\" (
    smi-prepare-venv
)

call .\.venv\Scripts\activate
%*
set RESULT_CODE=%errorlevel%
call deactivate
