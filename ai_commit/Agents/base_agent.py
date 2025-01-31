import os
import subprocess
import sys
from ai_commit.utils import load_prompt

class BaseAgent:
    def __init__(self):
        self.commands = {
            "is_git_repo": ["git", "rev-parse", "--git-dir"],
            "clear_screen": ["cls" if os.name == "nt" else "clear"],
            "commit": ["git", "commit", "-m"],
            "get_stashed_changes": ["git", "diff", "--cached"],
        }

    def run_command(self, command: list[str] | str ):
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

    def load_prompt(self, prompt_name: str) -> str:
        return load_prompt(prompt_name)
    



    
