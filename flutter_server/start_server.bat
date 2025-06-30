@echo off
cd /d %~dp0flutter_server
echo Avvio server Flask...
python server.py
pause