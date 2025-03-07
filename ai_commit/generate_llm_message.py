import ollama
import sys
from ai_commit.utils import load_prompt

def generate_message(staged_changes: str, model_name : str, prompt_name:str):
    try:

        system_prompt = load_prompt(prompt_name)


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

        print("✨ Generating message...")
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