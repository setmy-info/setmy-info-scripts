set PROFILE_NAMES=%*

for %%x in (%PROFILE_NAMES%) do if exist %TERM_PROFILES_DIR%\%%x.cmd (call %TERM_PROFILES_DIR%\%%x.cmd) else (if exist %USERPROFILE%\.term\profiles\%%x.cmd (call %USERPROFILE%\.term\profiles\%%x.cmd))
