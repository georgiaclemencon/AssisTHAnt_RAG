@echo off
setlocal
cd /d "%~dp0.."
chcp 65001 >nul
title Document Assistant - Stopping

echo Stopping the document assistant...
docker compose down

echo.
echo Stopped. Your documents and index are preserved.
echo Use Start.bat to launch it again.
echo.
pause
