import os

def load_prompt(prompt_name: str) -> str:
    """
    Load a prompt text file from the prompts directory.
    Args:
        prompt_name (str): The name of the prompt file (without .txt extension).
    Returns:
        str: The content of the prompt file.
    Raises:
        FileNotFoundError: If the prompt file does not exist.
    """
    prompt_path = os.path.join(os.path.dirname(__file__), "prompts", f"{prompt_name}.txt")
    if not os.path.exists(prompt_path):
        raise FileNotFoundError(f"Prompt file '{prompt_name}.txt' not found in the prompts directory.")
    
    with open(prompt_path, "r") as file:
        return file.read()