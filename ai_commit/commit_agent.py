import os
import subprocess
import sys
import ollama
import requests
import json
import argparse
from ai_commit.generate_llm_message import generate_message
from ai_commit.utils import load_prompt
from ai_commit.generate_remote_message import generate_remote_message
commands = {
    "is_git_repo": ["git", "rev-parse", "--git-dir"],
    "clear_screen": ["cls" if os.name == "nt" else "clear"],
    "commit": ["git", "commit", "-m"],
    "get_stashed_changes": ["git", "diff", "--cached"],
}

def interaction_loop(staged_changes: str, use_local:bool, local_llm: str):
    while True:

        if use_local:
            commit_message = generate_message(staged_changes, model_name=local_llm, prompt_name="commit_message")
        else:
            commit_message = generate_remote_message(staged_changes, "commit_message")

        action = input("\n\nProceed to commit? [y(yes) | n[no] | r(regenerate)] ")

        match action:
            case "r" | "regenerate":
                subprocess.run(commands["clear_screen"])
                continue
            case "y" | "yes":
                print("committing...")
                res = run_command(commands["commit"] + [commit_message])
                print(f"\n{res}\n✨ Committed!")
                break
            case "n" | "no":
                print("\n❌ Discarding AI commit message.")
                break
            case _:
                print("\n🤖 Invalid action")
                break

#runs git command in CLI
def run_command(command: list[str] | str):
    try:
        result = subprocess.run(
            command,
            capture_output=True,
            text=True,
            encoding='utf-8',
            check=True,
            timeout=10,
        )
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        print(f"❌ Error: \n{e.stderr}")
        sys.exit(1)



def run(local_llm, use_local=False):
    try:
        # Ensure the directory is a Git repository
        run_command(commands["is_git_repo"])

        # Fetch staged changes
        staged_changes = run_command(commands["get_stashed_changes"])

        if not staged_changes.strip():
            print("\n❌ No staged changes detected. Please stage your changes first.")
            sys.exit(0)

        # Pass staged changes to the interaction loop
        interaction_loop(staged_changes, use_local=use_local, local_llm=local_llm)
    except KeyboardInterrupt:
        print("\n\n❌ AI commit exited.")

