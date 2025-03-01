import os
from ai_commit.utils import load_prompt
import sys
import json
import requests
import re


API_KEY = os.getenv("AI_API_KEY")
API_URL = os.getenv("AI_API_URL")

# Check if environment variables are set
if not API_KEY or not API_URL:
    print("\n❌ Error: AI_API_KEY and AI_API_URL environment variables must be set.")
    print("Please set them using:")
    print("  export AI_API_KEY='your_api_key_here'")
    print("  export AI_API_URL='https://your.api.url'")
    sys.exit(1)


def filter_code_blocks(text):
    """
    Filter out code blocks and snippets from the text.
    
    Args:
        text (str): The text to filter
        
    Returns:
        str: Text with code blocks removed
    """
    # Remove triple backtick code blocks (including language specifier)
    text = re.sub(r'```[\w]*[\s\S]*?```', '', text)
    
    # Remove single backtick inline code
    text = re.sub(r'`[^`]*`', '', text)
    
    # Remove HTML code tags
    text = re.sub(r'<code>[\s\S]*?</code>', '', text)
    
    # Clean up multiple newlines
    text = re.sub(r'\n{3,}', '\n\n', text)
    
    return text.strip()


def generate_remote_message(staged_changes: str, prompt_name: str, task_type: str = None):
    try:
        
        if task_type == "commit":
            user_prompt = f"Here is the diff from staged changes:\n{staged_changes}"
        elif task_type == "review":
            user_prompt = f"Here is the code to review:\n{staged_changes}"
        elif task_type == "email":
            user_prompt = f"Here is the email content:\n{staged_changes}"
        else:
            user_prompt = f"Here is the input:\n{staged_changes}"


        system_prompt = load_prompt(prompt_name)
        payload = {
            "model": "llama3.2:latest",
            "messages": [
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt}
            ],
            "stream": True
        }

        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {API_KEY}",
        }
        print(f"\n✨ Sending request to {API_URL}...")
        response = requests.post(API_URL, json=payload, headers=headers, stream=True)

        # Check for HTTP errors
        if response.status_code != 200:
            print(f"\n❌ API Error: {response.status_code} - {response.text}")
            sys.exit(1)

        # Process streamed response
        message_content = ""
        in_code_block = False
        
        for chunk in response.iter_lines(decode_unicode=True):
            if chunk.startswith("data: "):  # Handle chunked response
                chunk = chunk[6:]
            if chunk.strip() == "[DONE]":  # End of stream
                break

            # Parse JSON and extract content
            try:
                chunk_data = json.loads(chunk)
                delta_content = chunk_data.get("choices", [{}])[0].get("delta", {}).get("content", "")
                
                # Track if we're in a code block to skip content
                if '```' in delta_content:
                    if delta_content.strip().startswith('```'):
                        in_code_block = True
                        if task_type == "commit":
                            # For commit messages, we don't want to show code blocks at all
                            delta_content = ""
                        else:
                            delta_content = "[Code block removed]\n"
                    elif delta_content.strip() == '```':
                        in_code_block = False
                        delta_content = ""
                
                # Skip content inside code blocks for commit messages
                if in_code_block and task_type == "commit":
                    continue
                
                message_content += delta_content
                print(delta_content, end="", flush=True)  # Stream output
            except json.JSONDecodeError:
                # Handle non-JSON chunks
                if chunk.strip():  # Log non-empty invalid chunks
                    print(f"\n⚠️ Invalid JSON chunk: {chunk}")
                continue

        if not message_content.strip():
            print(f"\n❌ No {task_type} message generated.")
            sys.exit(1)

        # For commit messages, filter out any remaining code blocks
        if task_type == "commit":
            filtered_message = filter_code_blocks(message_content)
            return filtered_message
        
        return message_content

    except requests.exceptions.RequestException as e:
        print(f"\n❌ Request error: {str(e)}")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Unexpected error: {str(e)}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
