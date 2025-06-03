@echo off
cd /d %~dp0flutter_server

:: Verifica se qualcosa ascolta sulla porta 5000
powershell -Command "(Test-NetConnection -ComputerName localhost -Port 5000).TcpTestSucceeded" > port_check.txt
findstr /C:"True" port_check.txt >nul
if %errorlevel%==0 (
    echo Il server Flask è già attivo su http://localhost:5000
    start http://localhost:5000/login
) else (
    echo Avvio server Flask...
    start http://localhost:5000/login
    start cmd /k "python server.py"
)

del port_check.txt >nul 2>&1
pause
