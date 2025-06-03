@echo off
cd /d %~dp0
git add .
git commit -m "📝 Backup automatico"
git push origin main
pause
