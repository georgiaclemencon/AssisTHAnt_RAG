#!/usr/bin/env bash
# Linux/macOS equivalent of Enriched-Query.bat
set -u
cd "$(dirname "$0")/.."

if command -v python3 >/dev/null 2>&1; then
    python3 enriched_query.py
else
    python enriched_query.py
fi
