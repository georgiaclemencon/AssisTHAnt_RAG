# Guide d'installation — Assistant Documents (RAG local)

Assistant de recherche documentaire 100% local. Aucune donnée ne sort du PC.

---

## 1. Prérequis

- **Docker Desktop** : https://www.docker.com/products/docker-desktop/
- **Python 3** (déjà installé sur la plupart des PC Windows pro ; sinon https://www.python.org/downloads/) — uniquement pour le script de question enrichie
- **8 Go de RAM** minimum, **6 Go d'espace disque** (modèles + index)

### Fix de performance recommandé (Windows + Docker Desktop)

Sans ça, l'indexation/les réponses peuvent être anormalement lentes (goulot d'étranglement mémoire de la VM WSL2). À faire une fois :

1. PowerShell :
   ```powershell
   notepad "$env:UserProfile\.wslconfig"
   ```
2. Colle (adapte `memory` à ~50% de la RAM totale du PC) :
   ```ini
   [wsl2]
   memory=16GB
   processors=8
   swap=0
   ```
3. Redémarre WSL (coupe les conteneurs Docker en cours, normal) :
   ```powershell
   wsl --shutdown
   ```
4. Relance Docker Desktop, attends que l'icône baleine soit stable.

---

## 2. Installation

1. Copie tout le dossier du projet où tu veux sur ton PC.
2. Ouvre un terminal dans ce dossier (clic droit → "Ouvrir dans le terminal", ou `cd` en PowerShell/Git Bash).
3. Lance :
   ```bash
   docker compose up -d
   ```

**Premier lancement uniquement** : télécharge Ollama, le modèle LLM (`phi4-mini`, ~2,5 Go) et le modèle d'embeddings (~275 Mo). Compte **5 à 15 minutes**. Les fois suivantes, ~30 secondes.

Alternative sans terminal : double-clic sur **`Demarrer.bat`**.

---

## 3. Structure du projet

| Élément | Rôle |
|---|---|
| `knowledge_base\` | Documents **permanents** de l'entreprise (savoir réutilisable) |
| `documents_confidentiels\` | Documents **ponctuels/sensibles** à analyser, isolés de la base permanente |
| `docker-compose.yml` | Config des services (Ollama, KB, Analyse) |
| `.env` | Choix du modèle LLM et autres réglages |
| `Demarrer.bat` / `Arreter.bat` | Démarrer/arrêter toute la stack sans terminal |
| `Purger-Analyse.bat` | Vide la zone d'analyse confidentielle (index + fichiers) |
| `query_enrichi.py` / `Query-Enrichi.bat` | Chat qui croise base permanente + document déposé, en une seule réponse |

Deux interfaces web séparées, volontairement isolées l'une de l'autre :
- **Base de connaissance** : http://localhost:9621/webui/
- **Analyse confidentielle** : http://localhost:9622/webui/

---

## 4. Utilisation

### Ajouter un document à la base permanente
1. Dépose le fichier dans `knowledge_base\`
2. Indexe-le : onglet **Documents** de http://localhost:9621/webui/ (ou `curl -X POST http://localhost:9621/documents/scan`)
3. Attends le statut **"Processed"**
4. Pose tes questions dans l'onglet **Retrieval** de la même page (chat multi-tours, historique conservé automatiquement)

### Analyser un document ponctuel/sensible
1. Dépose le fichier dans `documents_confidentiels\`
2. Indexe-le : onglet Documents de http://localhost:9622/webui/ (ou `curl -X POST http://localhost:9622/documents/scan`)
3. Attends **"Processed"**
4. Questions dans l'onglet Retrieval de cette même page — **sans** croisement avec la base permanente

### Poser une question enrichie (base permanente + document déposé, une seule réponse)
```bash
python query_enrichi.py
```
ou double-clic sur `Query-Enrichi.bat`. Conversation multi-tours (tape `quit` pour arrêter). Réponses toujours en français (modifiable dans `SYSTEM_INSTRUCTIONS` en haut du fichier).

### Purger la zone d'analyse après usage
Double-clic sur **`Purger-Analyse.bat`** — supprime tout ce qui est indexé dans la zone confidentielle. Ne touche jamais à la base permanente.

### Arrêter / relancer
```bash
docker compose down     # arrêt
docker compose up -d    # relance
```
ou `Arreter.bat` / `Demarrer.bat`.

---

## 5. Dépannage

| Symptôme | Cause probable | Solution |
|---|---|---|
| `dependency failed to start: container ollama is unhealthy` | Ancien souci de healthcheck | Déjà corrigé dans ce projet — si ça revient, vérifier `docker compose logs ollama` |
| Document en statut `Failed` avec `httpx.ReadTimeout` | CPU trop lent pour le délai imparti (900s) | Relancer un scan (`.../documents/scan`) — LightRAG reprend les documents en échec. Si ça persiste : voir le fix `.wslconfig` (section 1) |
| Réponses très lentes (plusieurs minutes) malgré peu de contenu | Goulot mémoire WSL2 | Appliquer le fix `.wslconfig` (section 1) |
| Erreur `"There was an error parsing the body"` sur une requête `curl` manuelle | Caractères accentués envoyés en ligne de commande directe | Écrire le JSON dans un fichier (`--data-binary @fichier.json`) plutôt qu'en `-d '...'` inline |

Logs d'un service : `docker compose logs -f lightrag` (ou `ollama`, `lightrag-analyse`).

---

## 6. Limites connues

- Recherche **sémantique**, pas un `grep` — pas de garantie de détecter un motif exact (email, IBAN, clé API...) mot pour mot.
- Temps de réponse dépendant de la taille du document et du CPU disponible (pas de GPU dans cette configuration).
- La zone d'analyse (9622) n'a par défaut **aucune connaissance** de la base permanente sauf via `query_enrichi.py` (évite de dupliquer l'indexation).
- Le croisement base permanente + document (`query_enrichi.py`) n'est pas disponible depuis l'interface web standard, uniquement via ce script.
