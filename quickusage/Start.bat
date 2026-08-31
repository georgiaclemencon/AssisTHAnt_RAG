@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0.."
chcp 65001 >nul
title Document Assistant - Starting

echo ============================================
echo   Document Assistant - Starting
echo ============================================
echo.

echo Checking Docker Desktop...
docker info >nul 2>&1
if errorlevel 1 (
    echo.
    echo [ERROR] Docker Desktop does not seem to be running.
    echo.
    echo   1. Open Docker Desktop
    echo   2. Wait until the whale icon is stable
    echo   3. Run this file again
    echo.
    pause
    exit /b 1
)
echo OK.
echo.

echo Starting services (may take a while the first time)...
docker compose up -d
if errorlevel 1 (
    echo.
    echo [ERROR] Startup failed. Copy the message above and send it
    echo to whoever provided you this tool.
    echo.
    pause
    exit /b 1
)

echo.
echo ============================================
echo   First launch only:
echo   downloading the AI models (~2.5 GB)
echo   can take 5 to 15 minutes.
echo   Next launches will be near-instant.
echo ============================================
echo.

echo Waiting for the assistant to be ready...
set READY=0
for /l %%i in (1,1,60) do (
    if "!READY!"=="0" (
        for /f %%c in ('curl -s -o nul -w "%%{http_code}" http://localhost:9621/health 2^>nul') do set HCODE=%%c
        if "!HCODE!"=="200" (
            set READY=1
        ) else (
            timeout /t 5 /nobreak >nul
        )
    )
)

if "!READY!"=="1" (
    echo Assistant ready. Indexing the knowledge base ^(knowledge_base\^)...
    curl -s -X POST http://localhost:9621/documents/scan >nul 2>&1
) else (
    echo The assistant is taking longer than expected ^(models still downloading^).
    echo Open the link below once it's ready ; the knowledge base will be indexed automatically.
)

echo Opening browser...
start "" "http://localhost:9621/webui/"

echo.
echo The assistant is running in the background. You can close this window.
echo To stop it cleanly, use Stop.bat
echo.
pause
