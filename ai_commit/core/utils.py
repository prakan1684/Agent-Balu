import os
import subprocess
import sys
from typing import List, Dict, Any, Optional, Union

def load_prompt(prompt_name:str) -> str:
    """
    Load a prompt from prompt registry

    Args:
        prompt_name: The name of the prompt file (without .txt extension)
    """

    prompt_path = os.path.join(
        os.path.dirname(os.path.dirname(__file__)),
        "prompts",
        f"{prompt_name}.txt"
    )
    try:
        with open(prompt_path, "r", encoding="utf-8") as f:
            return f.read()
    except FileNotFoundError:
        print(f"❌ Error: Prompt file '{prompt_name}.txt' not found.")
        return ""



def run_command(command: Union[List[str], str]) -> str:
    """
    Runs a shell command and returns the output

    Args:
        command: The command to run

    Returns:
        str: The output of the command
    """
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