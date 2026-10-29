@echo off
setlocal
cd /d "%~dp0"
set "PORT=8000"
set "URL=http://127.0.0.1:%PORT%/"

where py >nul 2>&1
if not errorlevel 1 goto use_py
where python >nul 2>&1
if not errorlevel 1 goto use_python

echo Python 3 was not found. Install Python and enable the py launcher, then try again.
pause
exit /b 1

:use_py
set "PYTHON=py -3"
goto check_server

:use_python
set "PYTHON=python"

:check_server
powershell -NoProfile -Command "try { $r = Invoke-WebRequest -UseBasicParsing -Uri '%URL%' -TimeoutSec 2; if ($r.Content -match 'Choisir un outil') { exit 0 } } catch {}; exit 1" >nul 2>&1
if not errorlevel 1 goto open_browser

powershell -NoProfile -Command "if (Test-NetConnection -ComputerName 127.0.0.1 -Port %PORT% -InformationLevel Quiet) { exit 0 } else { exit 1 }" >nul 2>&1
if not errorlevel 1 (
    echo Port %PORT% is already in use by another application.
    echo Close that application or change PORT in this file, then try again.
    pause
    exit /b 1
)

start "Alarms Automation server" /min %PYTHON% -m http.server %PORT% --bind 127.0.0.1

for /L %%I in (1,1,15) do (
    powershell -NoProfile -Command "try { $r = Invoke-WebRequest -UseBasicParsing -Uri '%URL%' -TimeoutSec 1; if ($r.Content -match 'Choisir un outil') { exit 0 } } catch {}; exit 1" >nul 2>&1
    if not errorlevel 1 goto open_browser
    timeout /t 1 /nobreak >nul
)

echo The local server did not start. Check that Python 3 is installed, then try again.
pause
exit /b 1

:open_browser
start "" "%URL%"
endlocal
exit /b 0
