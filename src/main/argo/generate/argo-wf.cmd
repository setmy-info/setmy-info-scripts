@echo off

set CC=ee
set ORG=has
for /f "tokens=*" %%a in ('uuid') do set UUID=%%a

argo submit -n generator --watch ^
    -p cc=%CC% ^
    -p org=%ORG% ^
    -p uuid=%UUID% ^
    09-generator-argo.yaml

echo All done.
