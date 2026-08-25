@echo off
setlocal
cd /d "%~dp0"
chcp 65001 >nul
title Assistant Documents - Arret

echo Arret de l'assistant documents...
docker compose down

echo.
echo Arrete. Tes documents et l'index restent conserves.
echo Utilise Demarrer.bat pour relancer.
echo.
pause
