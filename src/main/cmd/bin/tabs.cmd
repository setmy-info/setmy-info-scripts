@echo off
:: Copyright (C) 2026 Imre Tabur <imre.tabur@mail.ee>
setlocal enabledelayedexpansion

set CONFIG_PREFIXES=%*
if "%CONFIG_PREFIXES%"=="" set CONFIG_PREFIXES=tabs

for %%P in (%CONFIG_PREFIXES%) do (
    set TABS_CONFIG_FILE=%USERPROFILE%\.setmy.info\%%P.conf
    if exist "!TABS_CONFIG_FILE!" (
        set TABS=
        for /f "usebackq tokens=1,2 delims==" %%a in ("!TABS_CONFIG_FILE!") do (
            if "%%a"=="TABS" set TABS=%%b
        )
        if not "!TABS!"=="" (
            for %%u in (!TABS!) do (
                call tab "%%u"
            )
        ) else (
            echo TABS variable not found in !TABS_CONFIG_FILE!
        )
    ) else (
        echo Tabs configuration file not found: !TABS_CONFIG_FILE!
    )
)
