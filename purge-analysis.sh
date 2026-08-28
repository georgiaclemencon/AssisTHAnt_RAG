#!/usr/bin/env bash
# Linux/macOS equivalent of Purge-Analysis.bat
set -u
cd "$(dirname "$0")"

echo "============================================"
echo "  Purging the \"Confidential Analysis\" zone"
echo "============================================"
echo
echo "This PERMANENTLY deletes everything indexed in the"
echo "confidential analysis zone (documents_confidentiels/"
echo "and its index)."
echo
echo "The main knowledge base is NOT affected."
echo
read -rp "Confirm purge? (y/n): " CONFIRM
case "$CONFIRM" in
    [yY]) ;;
    *)
        echo "Cancelled."
        exit 0
        ;;
esac

echo
echo "Stopping the service..."
docker compose stop lightrag-analyse

echo "Removing the indexed volume..."
docker compose rm -f lightrag-analyse
docker volume rm assisthant-rag_lightrag_analyse_data 2>/dev/null

echo
read -rp "Also delete the source files in documents_confidentiels/ ? (y/n): " CONFIRM2
case "$CONFIRM2" in
    [yY])
        find documents_confidentiels -mindepth 1 -delete 2>/dev/null
        echo "Source files deleted."
        ;;
esac

echo
echo "Restarting a clean analysis zone..."
docker compose up -d lightrag-analyse

echo
echo "Purge complete. The confidential analysis zone is empty."
echo
