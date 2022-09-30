REM C:\pub\term\lib\loader.cmd

set PROFILE_NAMES=%*
for %%x in (%*) do call %TERM_PROFILES_DIR%\%%x.cmd
