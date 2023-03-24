@echo off

set POD_NAME=%1%
set OUT_FILE_NAME="%POD_NAME%.log"

call argo-log %POD_NAME% > "%OUT_FILE_NAME%"
