call .\project
call smi-create-venv %SMI_PROJECT_PYTHON_VERSION%
call .\.venv\Scripts\activate
call pip install %SMI_PROJECT_REQUIREMENTS%
call deactivate
REM project.cmd file
REM set SMI_PROJECT_PYTHON_VERSION=3.11
REM set SMI_PROJECT_REQUIREMENTS=-r requirements.txt -r another.txt
