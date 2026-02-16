@echo off
if exist ".\.venv\" (
    call .\.venv\Scripts\activate
) else (
    echo Error: .\.venv directory not found.
    exit /b 1
)
