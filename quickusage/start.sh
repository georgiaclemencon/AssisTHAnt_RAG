#!/usr/bin/env bash
# Linux/macOS equivalent of Start.bat
set -u
cd "$(dirname "$0")/.."

echo "============================================"
echo "  Document Assistant - Starting"
echo "============================================"
echo

echo "Checking Docker..."
if ! docker info >/dev/null 2>&1; then
    echo
    echo "[ERROR] Docker does not seem to be running."
    echo
    echo "  1. Start Docker (Docker Desktop or the docker daemon)"
    echo "  2. Wait until it is ready"
    echo "  3. Run this script again"
    echo
    read -rp "Press Enter to exit..."
    exit 1
fi
echo "OK."
echo

echo "Starting services (may take a while the first time)..."
if ! docker compose up -d; then
    echo
    echo "[ERROR] Startup failed. Copy the message above and send it"
    echo "to whoever provided you this tool."
    echo
    read -rp "Press Enter to exit..."
    exit 1
fi

echo
echo "============================================"
echo "  First launch only:"
echo "  downloading the AI models (~2.5 GB)"
echo "  can take 5 to 15 minutes."
echo "  Next launches will be near-instant."
echo "============================================"
echo

echo "Waiting for the assistant to be ready..."
READY=0
for _ in $(seq 1 60); do
    HCODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:9621/health 2>/dev/null)
    if [ "$HCODE" = "200" ]; then
        READY=1
        break
    fi
    sleep 5
done

if [ "$READY" = "1" ]; then
    echo "Assistant ready. Indexing the knowledge base (knowledge_base/)..."
    curl -s -X POST http://localhost:9621/documents/scan >/dev/null 2>&1
else
    echo "The assistant is taking longer than expected (models still downloading)."
    echo "Open the link below once it's ready; the knowledge base will be indexed automatically."
fi

echo "Opening browser..."
URL="http://localhost:9621/webui/"
if command -v xdg-open >/dev/null 2>&1; then
    xdg-open "$URL" >/dev/null 2>&1 &
elif command -v open >/dev/null 2>&1; then
    open "$URL" >/dev/null 2>&1 &
else
    echo "Could not detect a way to open a browser automatically."
    echo "Open this URL manually: $URL"
fi

echo
echo "The assistant is running in the background. You can close this terminal."
echo "To stop it cleanly, use ./stop.sh"
echo
read -rp "Press Enter to exit..."
