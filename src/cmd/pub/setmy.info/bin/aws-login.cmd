@echo off

set AWS_LOGIN_PROFILE=%1%

echo "Login with profile: %AWS_LOGIN_PROFILE%"
call aws sso login
call aws sts get-caller-identity
