set PYTHON_MAJOR_MINOR_VERSION=%1%
call py -%PYTHON_MAJOR_MINOR_VERSION% -m venv ./.venv
call smi-venv
python -m pip install --upgrade pip
deactivate
