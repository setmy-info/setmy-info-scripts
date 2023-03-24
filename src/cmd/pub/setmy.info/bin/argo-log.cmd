@echo off

set K8S_POD_NAME=%1%
set K8S_NAMESPACE=argo

echo "Getting logs for %K8S_POD_NAME%"
call kubectl logs %K8S_POD_NAME% -c main -n %K8S_NAMESPACE%
