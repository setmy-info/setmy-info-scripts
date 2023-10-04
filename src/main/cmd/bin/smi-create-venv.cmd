set PYTHON_MAJOR_MINOR_VERSION=%1%
call py -%PYTHON_MAJOR_MINOR_VERSION% -m venv ./.venv
call .\.venv\Scripts\activate
python -m pip install --upgrade pip
deactivate
