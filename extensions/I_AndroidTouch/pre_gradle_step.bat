@echo off
if /i not "%YYPLATFORM_name%"=="Android" exit /b 0
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0native\patch_runner_audio.ps1"
if errorlevel 1 exit /b %ERRORLEVEL%
powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0native\prepare_package.ps1"
exit /b %ERRORLEVEL%
