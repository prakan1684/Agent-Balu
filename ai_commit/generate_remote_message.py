import os
from ai_commit.utils import load_prompt
import sys
import json
import requests



API_KEY = os.getenv("AI_API_KEY")
API_URL = os.getenv("AI_API_URL")




def generate_remote_message(staged_changes: str, prompt_name:str):
    try:
        system_prompt = load_prompt(prompt_name)
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

        print(system_prompt)
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
