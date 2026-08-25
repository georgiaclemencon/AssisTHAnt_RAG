#!/usr/bin/env python3
"""
Conversation enrichie : a chaque question, recherche le contexte dans la KB
(9621, lecture seule, pas de generation), puis l'injecte dans la question
posee a l'instance Analyse (9622) qui fait la synthese finale. L'historique
de la conversation est conserve tant que le script tourne.

Usage:
    python query_enrichi.py
    (tape 'quit' ou Ctrl+C pour arreter)
"""
import json
import subprocess
import sys
import tempfile
from pathlib import Path

KB_URL = "http://127.0.0.1:9621/query"
ANALYSE_URL = "http://127.0.0.1:9622/query"
MAX_HISTORY_TURNS = 6  # nombre de tours (question+reponse) gardes en memoire

# Instructions systeme appliquees a chaque reponse finale (via user_prompt).
SYSTEM_INSTRUCTIONS = "Reponds uniquement en francais, quelle que soit la langue de la question ou des documents sources."


def curl_post(url: str, payload: dict) -> dict:
    with tempfile.NamedTemporaryFile(mode="w", suffix=".json", delete=False, encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False)
        tmp_path = f.name
    try:
        result = subprocess.run(
            ["curl", "-s", "--noproxy", "*", "-X", "POST", url,
             "-H", "Content-Type: application/json",
             "--data-binary", f"@{tmp_path}"],
            capture_output=True, text=True, encoding="utf-8", check=True,
        )
    finally:
        Path(tmp_path).unlink(missing_ok=True)
    return json.loads(result.stdout)


def ask(question: str, history: list) -> str:
    print("[1/2] Recherche dans la base de connaissance (KB, 9621)...")
    kb_result = curl_post(KB_URL, {
        "query": question,
        "mode": "naive",
        "only_need_context": True,
    })
    kb_context = kb_result.get("response", "")
    if not kb_context:
        print("  -> Aucun contexte KB trouve. On continue sans enrichissement.")

    print("[2/2] Generation de la reponse enrichie (Analyse, 9622)...")
    user_prompt = SYSTEM_INSTRUCTIONS
    if kb_context:
        user_prompt += (
            "\n\nContexte additionnel de la base de connaissance de l'entreprise, "
            "utilise-le si pertinent pour ta reponse:\n" + kb_context
        )

    payload = {
        "query": question,
        "mode": "naive",
        "conversation_history": history,
        "user_prompt": user_prompt,
    }

    final_result = curl_post(ANALYSE_URL, payload)
    return final_result.get("response", str(final_result))


def main():
    print("Conversation enrichie (KB + document). Tape 'quit' pour arreter.\n")
    history = []

    while True:
        try:
            question = input("You : ").strip()
        except (EOFError, KeyboardInterrupt):
            print("\nFin de la conversation.")
            break

        if not question:
            continue
        if question.lower() in ("quit", "exit", "q"):
            print("Fin de la conversation.")
            break

        answer = ask(question, history)

        print("\n" + "=" * 60)
        print(answer)
        print("=" * 60 + "\n")

        history.append({"role": "user", "content": question})
        history.append({"role": "assistant", "content": answer})
        history = history[-(MAX_HISTORY_TURNS * 2):]


if __name__ == "__main__":
    main()
