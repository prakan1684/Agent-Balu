import subprocess
import ollama
import sys
import os
from ai_commit.commit_agent import run_command
from ai_commit.generate_llm_message import generate_message
from ai_commit.generate_remote_message import generate_remote_message
# Define a system prompt to guide the AI for code reviews

commands = {
    "is_git_repo": ["git", "rev-parse", "--git-dir"],
    "clear_screen": ["cls" if os.name == "nt" else "clear"],
    "commit": ["git", "commit", "-m"],
    "get_stashed_changes": ["git", "diff", "--cached"],
}



    

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

def review_code(local_llm, use_local=False):
    try:
        run_command(commands["is_git_repo"])


        staged_changes=run_command(commands["get_stashed_changes"])

        if not staged_changes.strip():
            print("\n❌ No staged changes detected. Please stage your changes first.")
            sys.exit(0)
        
        if use_local:
            generate_message(staged_changes, local_llm, "code_review")
        else:
            generate_remote_message(staged_changes, "code_review", "review")


    except KeyboardInterrupt:
        print("\n\n❌ AI code-review exited.")

