import os
import subprocess
import sys
import ollama
import requests
import json
import argparse

commands = {
    "is_git_repo": ["git", "rev-parse", "--git-dir"],
    "clear_screen": ["cls" if os.name == "nt" else "clear"],
    "commit": ["git", "commit", "-m"],
    "get_stashed_changes": ["git", "diff", "--cached"],
}
API_KEY = os.getenv("AI_API_KEY")
API_URL = os.getenv("AI_API_URL")
if not API_KEY or not API_URL:
    print("❌ Error: Please set the environment variables 'AI_API_KEY' and 'AI_API_URL'")
    sys.exit(1)

system_prompt = """
You are an expert AI commit message generator specialized in creating concise, informative commit messages that follow best practices in version control.

Your ONLY task is to generate a well-structured commit message based on the provided diff. The commit message must:
1. Use a clear, descriptive title in the imperative mood (50 characters max)
2. Provide a detailed explanation of changes in bullet points
3. Focus solely on the technical changes in the code
4. Use present tense and be specific about modifications

Key Guidelines:
- Analyze the entire diff comprehensively
- Capture the essence of only MAJOR changes
- Use technical, precise languages
- Avoid generic or vague descriptions
- Avoid quoting any word or sentences
- Avoid adding description for minor changes with not much context
- Return just the commit message, no additional text
- Don't return more bullet points than required
- Generate a single commit message

Output Format:
Concise Title Summarizing Changes

- Specific change description
- Another specific change description
- Rationale for key modifications
- Impact of changes
"""
def interaction_loop(staged_changes: str, use_local:bool, local_llm: str):
    while True:

        if use_local:
            commit_message = generate_commit_message(staged_changes, model_name=local_llm)
        else:
            commit_message = generate_remote_message(staged_changes)
        #commit_message = generate_commit_message(staged_changes)
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

def generate_remote_message(staged_changes: str):
    try:
        payload = {
            "model": "llama3.2:latest",
            "messages": [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": f"Here is the diff from staged changes:\n {staged_changes}"}
            ],
            "stream": True
        }

        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {API_KEY}",
        }

        print("\n✨ Sending request to remote Llama API...")
        response = requests.post(API_URL, json=payload, headers=headers, stream=True)

        # Check for HTTP errors
        if response.status_code != 200:
            print(f"\n❌ API Error: {response.status_code} - {response.text}")
            sys.exit(1)

        # Process streamed response
        commit_message = ""
        for chunk in response.iter_lines(decode_unicode=True):
            if chunk.startswith("data: "):  # Handle chunked response
                chunk = chunk[6:]
            if chunk.strip() == "[DONE]":  # End of stream
                break

            # Parse JSON and extract content
            try:
                chunk_data = json.loads(chunk)
                delta_content = chunk_data.get("choices", [{}])[0].get("delta", {}).get("content", "")
                commit_message += delta_content
                print(delta_content, end="", flush=True)  # Stream output
            except json.JSONDecodeError:
                # Handle non-JSON chunks
                if chunk.strip():  # Log non-empty invalid chunks
                    print(f"\n⚠️ Invalid JSON chunk: {chunk}")
                continue

        if not commit_message.strip():
            print("\n❌ No commit message generated.")
            sys.exit(1)

        return commit_message

    except requests.exceptions.RequestException as e:
        print(f"\n❌ Request error: {str(e)}")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Unexpected error: {str(e)}")
        import traceback
        traceback.print_exc()
        sys.exit(1)



def generate_commit_message(staged_changes: str, model_name : str):
    try:
        stream = ollama.chat(
            model=model_name,
            messages=[
                {
                    "role": "system",
                    "content": system_prompt
                },
                {
                    "role": "user",
                    "content": f"Here is the diff from staged changes:\n {staged_changes}",
                },
            ],
            stream=True,
        )

        print("✨ Generating commit message...")
        print("-" * 50 + "\n")
        commit_message = ""
        for chunk in stream:
            if chunk["done"] is False:
                content = chunk["message"]["content"]
                print(content, end="", flush=True)
                commit_message += content

        if not commit_message.strip():
            print("\n❌ No commit message generated.")
            sys.exit(1)

        return commit_message

    except Exception as e:
        print(f"❌ Error generating commit message: {str(e)}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

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

