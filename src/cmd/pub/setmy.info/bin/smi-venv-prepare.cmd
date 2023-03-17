call .\project
call smi-create-venv %PROJECT_PYTHON_VERSION%
call smi-venv
call pip install -r %PROJECT_REQUIREMENTS%
call deactivate
REM project.cmd file
REM set PROJECT_PYTHON_VERSION=3.11
REM set PROJECT_REQUIREMENTS=requirements.txt
