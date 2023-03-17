@echo off

set FILE_NAME=%1%
set K8S_NAMESPACE=argo

echo "Start workflow: %FILE_NAME%"
call argo submit %FILE_NAME% -n %K8S_NAMESPACE%
