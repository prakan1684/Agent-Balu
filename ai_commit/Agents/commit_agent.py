import os
import subprocess
import sys
from typing import List, Optional

from ai_commit.core.llm import generate_response
from ai_commit.Agents.base_agent import BaseAgent
from ai_commit.core.utils import load_prompt, run_command


class CommitAgent(BaseAgent):
    def __init__(self):
        self.commands = {
            "is_git_repo": ["git", "rev-parse", "--git-dir"],
            "clear_screen": ["cls" if os.name == "nt" else "clear"],
            "commit": ["git", "commit", "-m"],
            "get_stashed_changes": ["git", "diff", "--cached"],
        }
    
    def interaction_loop(self, staged_changes:str, use_local:bool, local_llm: str)-> None:
        """
        Here we have the main interaction loop for when the user uses the commit agent

        Args:
            staged_changes (str): The staged changes to be committed
            use_local (bool): Whether to use a local model
            local_llm (str): The name of the local model to use
        """

        while True:
            #load prompt
            prompt = load_prompt("commit_message")

            #generate commit message using llm
            commit_message = generate_response(
                prompt = prompt,
                context = staged_changes,
                use_local=use_local,
                model_name=local_llm
            )
            print("\n" + "="*50)
            print("GENERATED COMMIT MESSAGE:")
            print("="*50)
            print(commit_message)
            print("="*50 + "\n")



            action = input("\n\nProceed to commit? [y(yes) | n(no) | r(regenerate)] ")
            if action in ["r", "regenerate"]:
                subprocess.run(self.commands["clear_screen"], shell=True)
                continue
            elif action in ["y", "yes"]:
                print("committing...")
                res = run_command(self.commands["commit"] + [commit_message])
                print(f"\n{res}\n✨ Committed!")
                break
            elif action in ["n", "no"]:
                print("\n❌ Discarding AI commit message.")
                break
            else:
                print("\n🤖 Invalid action")
                break


    def run(self, use_local:bool = False, local_llm : str = "") -> None:
        try:
            run_command(self.commands["is_git_repo"])

            #get staged changes
            staged_changes = run_command(self.commands["get_stashed_changes"])

            if not staged_changes.strip():
                print("\n❌ No staged changes detected. Please stage your changes first.")
                sys.exit(0)

            # Pass staged changes to the interaction loop
            self.interaction_loop(staged_changes, use_local, local_llm)
        except KeyboardInterrupt:
            print("\n\n❌ AI commit exited.")
            

