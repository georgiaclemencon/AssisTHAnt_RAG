@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"
chcp 65001 >nul
title Assistant Documents - Demarrage

echo ============================================
echo   Assistant Documents - Demarrage
echo ============================================
echo.

echo Verification de Docker Desktop...
docker info >nul 2>&1
if errorlevel 1 (
    echo.
    echo [ERREUR] Docker Desktop ne semble pas demarre.
    echo.
    echo   1. Ouvre Docker Desktop
    echo   2. Attends que l'icone baleine soit stable
    echo   3. Relance ce fichier
    echo.
    pause
    exit /b 1
)
echo OK.
echo.

echo Demarrage des services (peut prendre du temps la 1ere fois)...
docker compose up -d
if errorlevel 1 (
    echo.
    echo [ERREUR] Le demarrage a echoue. Copie le message ci-dessus
    echo et envoie-le a la personne qui t'a fourni cet outil.
    echo.
    pause
    exit /b 1
)

echo.
echo ============================================
echo   Premier lancement uniquement :
echo   le telechargement des modeles IA (~2.5 Go)
echo   peut prendre 5 a 15 minutes.
echo   Les fois suivantes, ce sera quasi instantane.
echo ============================================
echo.

echo Attente que l'assistant soit pret...
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
    echo Assistant pret. Indexation de la base de connaissance ^(knowledge_base\^)...
    curl -s -X POST http://localhost:9621/documents/scan >nul 2>&1
) else (
    echo L'assistant met plus de temps que prevu ^(telechargement des modeles en cours^).
    echo Ouvre le lien ci-dessous une fois pret ; la base sera indexee automatiquement.
)

echo Ouverture du navigateur...
start "" "http://localhost:9621/webui/"

echo.
echo L'assistant tourne en arriere-plan. Tu peux fermer cette fenetre.
echo Pour tout arreter proprement, utilise Arreter.bat
echo.
pause
