@echo off
cd /d "%~dp0"
chcp 65001 >nul
python query_enrichi.py
pause
