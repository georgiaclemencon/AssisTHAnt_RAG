@echo off
setlocal
cd /d "%~dp0.."
chcp 65001 >nul
title Purge the Confidential Analysis Zone

echo ============================================
echo   Purging the "Confidential Analysis" zone
echo ============================================
echo.
echo This PERMANENTLY deletes everything indexed in the
echo confidential analysis zone (confidential_documents\
echo and its index).
echo.
echo The main knowledge base is NOT affected.
echo.
set /p CONFIRM="Confirm purge? (y/n): "
if /i not "%CONFIRM%"=="y" (
    echo Cancelled.
    pause
    exit /b 0
)

echo.
echo Stopping the service...
docker compose stop lightrag-analyse

echo Removing the indexed volume...
docker compose rm -f lightrag-analyse
docker volume rm assisthant-rag_lightrag_analyse_data 2>nul

echo.
set /p CONFIRM2="Also delete the source files in confidential_documents\ ? (y/n): "
if /i "%CONFIRM2%"=="y" (
    del /q "confidential_documents\*" 2>nul
    for /d %%d in ("confidential_documents\*") do rmdir /s /q "%%d"
    echo Source files deleted.
)

echo.
echo Restarting a clean analysis zone...
docker compose up -d lightrag-analyse

echo.
echo Purge complete. The confidential analysis zone is empty.
echo.
pause
