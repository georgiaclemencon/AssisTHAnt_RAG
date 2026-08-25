# Architecture du projet

## Schéma statique — composants et stockage

```mermaid
flowchart TB
    Browser["Navigateur"]
    Script["query_enrichi.py<br/>(chat enrichi + historique)"]

    subgraph Host["PC Windows — tout en 127.0.0.1, rien exposé sur le réseau"]
        subgraph Compose["Docker Compose"]
            Ollama["ollama<br/>:11435<br/>phi4-mini:3.8b-q4_K_M<br/>nomic-embed-text"]
            Pull["ollama-pull<br/>(one-shot au 1er démarrage)"]
            KB["lightrag<br/>:9621<br/>workspace = kb"]
            Analyse["lightrag-analyse<br/>:9622<br/>workspace = confidentiel"]
        end

        VolOllama[("volume<br/>ollama_data")]
        VolKB[("volume<br/>lightrag_data")]
        VolAnalyse[("volume<br/>lightrag_analyse_data")]

        FolderKB["📁 knowledge_base/<br/>(savoir permanent)"]
        FolderConf["📁 documents_confidentiels/<br/>(ponctuel, à purger)"]
    end

    Pull -. télécharge modèles .-> Ollama
    KB -- LLM + embeddings --> Ollama
    Analyse -- LLM + embeddings --> Ollama

    Ollama --- VolOllama
    KB --- VolKB
    Analyse --- VolAnalyse

    FolderKB -. bind mount .-> KB
    FolderConf -. bind mount .-> Analyse

    Browser -->|":9621/webui/"| KB
    Browser -->|":9622/webui/"| Analyse
    Browser -.-> Script
    Script -->|"/query only_need_context"| KB
    Script -->|"/query + user_prompt"| Analyse
```

**Points clés d'isolation** : `lightrag` et `lightrag-analyse` sont deux processus séparés, deux volumes séparés, deux workspaces séparés. Rien ne circule automatiquement de l'un vers l'autre — seul `query_enrichi.py` fait le pont, à sens unique (KB → Analyse), et uniquement en mémoire (rien n'est stocké de façon permanente côté Analyse suite à cet enrichissement).

---

## Schéma dynamique — 3 flux

### 1. Indexation d'un document (dépôt → recherchable)

```mermaid
sequenceDiagram
    participant U as Utilisateur
    participant D as Dossier local
    participant L as LightRAG (kb ou analyse)
    participant O as Ollama

    U->>D: dépose un fichier
    U->>L: POST /documents/scan
    L->>D: lit le fichier
    L->>L: découpe en chunks (CHUNK_SIZE=2000, overlap=150)
    loop pour chaque chunk
        L->>O: extraction entités/relations (LLM, MAX_GLEANING=0)
        O-->>L: entités + relations
        L->>O: embedding du chunk (nomic-embed-text)
        O-->>L: vecteur
    end
    L->>L: met à jour graphe + index vectoriel (rag_storage)
    L-->>U: statut "Processed"
```

### 2. Question simple (une seule interface, sans croisement)

```mermaid
sequenceDiagram
    participant U as Utilisateur (UI web)
    participant L as LightRAG (kb ou analyse)
    participant O as Ollama

    U->>L: POST /query {question}
    L->>O: embedding de la question
    L->>L: recherche vectorielle/graphe (contexte pertinent)
    L->>O: génération de la réponse (contexte + question)
    O-->>L: réponse
    L-->>U: réponse + références
```

### 3. Question enrichie (`query_enrichi.py`) — KB + document, 1 seule génération

```mermaid
sequenceDiagram
    participant U as Utilisateur
    participant S as query_enrichi.py
    participant KB as lightrag (kb, 9621)
    participant AN as lightrag-analyse (9622)
    participant O as Ollama

    U->>S: pose une question
    S->>KB: POST /query only_need_context=true
    KB->>O: embedding de la question
    KB->>KB: recherche (retrieval only, pas de génération)
    KB-->>S: contexte KB (texte brut)
    S->>AN: POST /query<br/>user_prompt = instructions + contexte KB<br/>conversation_history = historique
    AN->>O: embedding de la question
    AN->>AN: recherche dans documents_confidentiels
    AN->>O: génération (contexte doc + contexte KB injecté)
    O-->>AN: réponse finale
    AN-->>S: réponse
    S-->>U: affiche la réponse (1 seule génération LLM au total)
```
