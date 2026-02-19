@echo off

rem Copyright (C) 2026 Imre Tabur <imre.tabur@mail.ee>

set BRANCH_NAME=%1

git branch -D %BRANCH_NAME%
git push origin --delete %BRANCH_NAME%
