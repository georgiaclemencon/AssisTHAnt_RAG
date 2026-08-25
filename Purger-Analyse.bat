@echo off
setlocal
cd /d "%~dp0"
chcp 65001 >nul
title Purger la zone Analyse Confidentielle

echo ============================================
echo   Purge de la zone "Analyse Confidentielle"
echo ============================================
echo.
echo Cette action supprime DEFINITIVEMENT tout ce qui a ete indexe
echo dans la zone d'analyse confidentielle (documents_confidentiels\
echo et son index).
echo.
echo La base de connaissance principale n'est PAS touchee.
echo.
set /p CONFIRM="Confirmer la purge ? (o/n) : "
if /i not "%CONFIRM%"=="o" (
    echo Annule.
    pause
    exit /b 0
)

echo.
echo Arret du service...
docker compose stop lightrag-analyse

echo Suppression du volume indexe...
docker compose rm -f lightrag-analyse
docker volume rm lightrag-docker_lightrag_analyse_data 2>nul

echo.
set /p CONFIRM2="Supprimer aussi les fichiers sources dans documents_confidentiels\ ? (o/n) : "
if /i "%CONFIRM2%"=="o" (
    del /q "documents_confidentiels\*" 2>nul
    for /d %%d in ("documents_confidentiels\*") do rmdir /s /q "%%d"
    echo Fichiers sources supprimes.
)

echo.
echo Redemarrage d'une zone d'analyse vierge...
docker compose up -d lightrag-analyse

echo.
echo Purge terminee. La zone d'analyse confidentielle est vide.
echo.
pause
