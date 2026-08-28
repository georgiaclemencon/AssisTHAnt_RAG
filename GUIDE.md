# Installation Guide — Document Assistant (local RAG)

A 100% local document search assistant. No data ever leaves the machine.

---

## 1. Prerequisites

- **Docker** — Docker Desktop on Windows/macOS: https://www.docker.com/products/docker-desktop/, Docker Engine + Compose plugin on Linux: `curl -fsSL https://get.docker.com | sh`
- **Python 3** (already installed on most Windows/macOS/Linux machines; otherwise https://www.python.org/downloads/) — only needed for the enriched-query script
- **8 GB RAM** minimum, **6 GB disk space** (models + index)

### Recommended performance fix (Windows + Docker Desktop)

Without it, indexing/answers can be abnormally slow (a memory bottleneck in the WSL2 VM). Do this once:

1. PowerShell:
   ```powershell
   notepad "$env:UserProfile\.wslconfig"
   ```
2. Paste (adjust `memory` to ~50% of the machine's total RAM):
   ```ini
   [wsl2]
   memory=16GB
   processors=8
   swap=0
   ```
3. Restart WSL (this stops any running Docker containers, that's expected):
   ```powershell
   wsl --shutdown
   ```
4. Relaunch Docker Desktop and wait until the whale icon is stable.

Linux has no WSL2-style virtualization layer — Docker Engine uses host memory directly, so this fix doesn't apply. Just make sure the host has enough free RAM (8 GB+).

---

## 2. Installation

1. Copy the whole project folder anywhere on your machine.
2. Open a terminal in that folder (right-click → "Open in terminal", or `cd` in PowerShell/Git Bash/a Linux shell).
3. Run:
   ```bash
   docker compose up -d
   ```

**First launch only**: downloads Ollama, the LLM model (`phi4-mini`, ~2.5 GB) and the embedding model (~275 MB). Takes **5 to 15 minutes**. Subsequent launches: ~30 seconds.

Alternative without a terminal:
- Windows: double-click **`Start.bat`**.
- Linux/macOS: `./start.sh` (first time only: `chmod +x *.sh`).

---

## 3. Project structure

| Item | Role |
|---|---|
| `knowledge_base/` | **Permanent** company documents (reusable knowledge) |
| `documents_confidentiels/` | **One-off/sensitive** documents to analyze, isolated from the permanent base |
| `docker-compose.yml` | Service config (Ollama, KB, Analysis) |
| `.env` | LLM model choice and other settings |
| `Start.bat` / `Stop.bat` (Windows), `start.sh` / `stop.sh` (Linux/macOS) | Start/stop the whole stack without a terminal |
| `Purge-Analysis.bat` (Windows), `purge-analysis.sh` (Linux/macOS) | Empties the confidential analysis zone (index + files) |
| `enriched_query.py` / `Enriched-Query.bat` (Windows) / `enriched-query.sh` (Linux/macOS) | Chat that combines the permanent base + a deposited document, in a single answer |

Two separate web interfaces, deliberately isolated from each other:
- **Knowledge base**: http://localhost:9621/webui/
- **Confidential analysis**: http://localhost:9622/webui/

---

## 4. Usage

### Add a document to the permanent base
1. Drop the file into `knowledge_base/`
2. Index it: **Documents** tab at http://localhost:9621/webui/ (or `curl -X POST http://localhost:9621/documents/scan`)
3. Wait for the **"Processed"** status
4. Ask your questions in the **Retrieval** tab of the same page (multi-turn chat, history kept automatically)

### Analyze a one-off/sensitive document
1. Drop the file into `documents_confidentiels/`
2. Index it: Documents tab at http://localhost:9622/webui/ (or `curl -X POST http://localhost:9622/documents/scan`)
3. Wait for **"Processed"**
4. Ask questions in the Retrieval tab of that same page — **without** crossing over into the permanent base

### Ask an enriched question (permanent base + deposited document, single answer)
```bash
python enriched_query.py
```
or double-click `Enriched-Query.bat` (Windows) / run `./enriched-query.sh` (Linux/macOS). Multi-turn conversation (type `quit` to stop). Answers are always in English (configurable in `SYSTEM_INSTRUCTIONS` at the top of the file).

### Purge the analysis zone after use
Windows: double-click **`Purge-Analysis.bat`**. Linux/macOS: run **`./purge-analysis.sh`** — deletes everything indexed in the confidential zone. Never touches the permanent base.

### Stop / restart
```bash
docker compose down     # stop
docker compose up -d    # restart
```
or `Stop.bat` / `Start.bat` (Windows), `./stop.sh` / `./start.sh` (Linux/macOS).

---

## 5. Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `dependency failed to start: container ollama is unhealthy` | Old healthcheck issue | Already fixed in this project — if it recurs, check `docker compose logs ollama` |
| Document stuck in `Failed` status with `httpx.ReadTimeout` | CPU too slow for the configured timeout (900s) | Re-run a scan (`.../documents/scan`) — LightRAG retries failed documents. If it persists: see the `.wslconfig` fix (section 1) |
| Answers very slow (several minutes) despite little content | WSL2 memory bottleneck | Apply the `.wslconfig` fix (section 1) |
| `"There was an error parsing the body"` error on a manual `curl` request | Accented characters sent directly on the command line | Write the JSON to a file (`--data-binary @file.json`) instead of an inline `-d '...'` |

Logs for a service: `docker compose logs -f lightrag` (or `ollama`, `lightrag-analyse`).

---

## 6. Known limitations

- **Semantic** search, not `grep` — no guarantee of catching an exact pattern (email, IBAN, API key...) verbatim.
- Response time depends on document size and available CPU (no GPU in this configuration).
- The analysis zone (9622) has by default **no knowledge** of the permanent base except via `enriched_query.py` (avoids duplicating indexing).
- Crossing the permanent base with a deposited document (`enriched_query.py`) is not available from the standard web interface, only via this script.
