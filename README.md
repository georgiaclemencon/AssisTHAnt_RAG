# Assistant Documents — 100% local et confidentiel

Pose des questions sur tes documents. **Rien ne sort de ton PC** : pas de cloud,
pas d'API externe, tout tourne en local.

---

## Installation (une seule fois)

1. Installe **Docker Desktop** : https://www.docker.com/products/docker-desktop/
   (installation classique, "Suivant" à chaque étape)
2. Lance Docker Desktop et attends que l'icône baleine soit stable dans la
   barre des tâches.
3. Copie ce dossier entier où tu veux sur ton PC.

Prérequis : 8 Go de RAM minimum, ~5 Go d'espace disque.

### Pré-charger une base de connaissance existante

Avant le premier lancement, dépose les documents de l'entreprise (PDF, Word,
TXT, Markdown...) dans le dossier **`knowledge_base/`**. Ils seront indexés
automatiquement au démarrage — inutile de les envoyer manuellement via
l'interface. C'est aussi ce dossier qui reçoit les documents ajoutés plus
tard depuis l'onglet "Documents" du site.

---

## Démarrer

Double-clique sur **`Demarrer.bat`**.

- La 1ère fois : ça télécharge les modèles IA (~2.5 Go), compte **5 à 15 minutes**.
- Les fois suivantes : ça démarre en ~30 secondes.

Ton navigateur s'ouvre automatiquement sur l'assistant. Si la page ne
s'affiche pas tout de suite, patiente et rafraîchis (F5).

---

## Utiliser

- Onglet **Documents** → dépose tes fichiers
- Onglet **Retrieval** → pose tes questions
- Onglet **Knowledge Graph** → visualise les relations entre documents

---

## Arrêter

Double-clique sur **`Arreter.bat`**.

Tes documents et ton index sont conservés, rien n'est perdu.

---

## En cas de problème

- **"Docker Desktop ne semble pas démarré"** → ouvre Docker Desktop et
  réessaie une fois l'icône stable.
- **Ça n'a jamais fini de télécharger** → vérifie ta connexion internet,
  relance `Demarrer.bat`.
- Pour tout autre souci, contacte la personne qui t'a fourni cet outil en
  copiant le message d'erreur affiché.

---

## Notes techniques (pour la personne qui déploie)

- Tout tourne en conteneurs Docker (Ollama + LightRAG), aucune dépendance
  externe une fois les images téléchargées.
- Ports exposés uniquement sur `127.0.0.1` (localhost) — pas accessibles
  depuis le réseau.
- Modèle par défaut : `qwen2.5:3b` (léger, tourne sur CPU). Pour changer,
  édite `docker-compose.yml` / `.env`.
- Option LM Studio disponible dans `.env` (voir les commentaires), au prix
  de la portabilité 100%-Docker.
