#!/usr/bin/env python3
"""
Enriched conversation: for each question, retrieves context from the KB
(9621, read-only, no generation), then injects it into the question sent
to the Analysis instance (9622), which produces the final answer. The
conversation history is kept in memory for as long as the script runs.

Usage:
    python enriched_query.py
    (type 'quit' or Ctrl+C to stop)
"""
import json
import subprocess
import sys
import tempfile
from pathlib import Path

KB_URL = "http://127.0.0.1:9621/query"
ANALYSE_URL = "http://127.0.0.1:9622/query"
MAX_HISTORY_TURNS = 6  # number of turns (question+answer) kept in memory

# System instructions applied to every final answer (via user_prompt).
SYSTEM_INSTRUCTIONS = "Answer only in English, regardless of the language of the question or the source documents."


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
    print("[1/2] Searching the knowledge base (KB, 9621)...")
    kb_result = curl_post(KB_URL, {
        "query": question,
        "mode": "naive",
        "only_need_context": True,
    })
    kb_context = kb_result.get("response", "")
    if not kb_context:
        print("  -> No KB context found. Continuing without enrichment.")

    print("[2/2] Generating the enriched answer (Analysis, 9622)...")
    user_prompt = SYSTEM_INSTRUCTIONS
    if kb_context:
        user_prompt += (
            "\n\nAdditional context from the company knowledge base, "
            "use it if relevant to your answer:\n" + kb_context
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
    print("Enriched conversation (KB + document). Type 'quit' to stop.\n")
    history = []

    while True:
        try:
            question = input("You: ").strip()
        except (EOFError, KeyboardInterrupt):
            print("\nEnding the conversation.")
            break

        if not question:
            continue
        if question.lower() in ("quit", "exit", "q"):
            print("Ending the conversation.")
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
