@echo off
cd /d %~dp0flutter_server
taskkill /f /im python.exe >nul 2>&1
echo Riavvio server Flask...
start cmd /k "python server.py"