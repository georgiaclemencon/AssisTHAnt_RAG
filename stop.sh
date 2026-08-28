#!/usr/bin/env bash
# Linux/macOS equivalent of Stop.bat
set -u
cd "$(dirname "$0")"

echo "Stopping the document assistant..."
docker compose down

echo
echo "Stopped. Your documents and index are preserved."
echo "Use ./start.sh to launch it again."
echo
