import subprocess
import ollama
import sys
import os
from ai_commit.commit_agent import run_command
from ai_commit.generate_llm_message import generate_message
# Define a system prompt to guide the AI for code reviews


def list_files_in_directory(directory="."):
    """
    List all files in the given directory.
    Args:
        directory (str): The directory to list files from.
    Returns:
        list: A list of file paths.
    """
    return [
        f for f in os.listdir(directory)
        if os.path.isfile(os.path.join(directory, f))
    ]


def choose_directory():
    """
    Allow the user to select a directory for file review.
    Returns:
        str: The selected directory.
    """
    print("Available directories:")
    directories = [d for d in os.listdir() if os.path.isdir(d)]
    directories.insert(0, ". (current directory)")  # Add current directory as an option

    for idx, directory in enumerate(directories, start=1):
        print(f"{idx}: {directory}")

    while True:
        try:
            choice = int(input("Enter the number of the directory you want to use: "))
            if 1 <= choice <= len(directories):
                return directories[choice - 1]
            else:
                print("Invalid choice. Please select a valid directory number.")
        except ValueError:
            print("Invalid input. Please enter a number.")


def choose_file(files):
    """
    Prompt the user to select a file from the list.
    Args:
        files (list): List of files to choose from.
    Returns:
        str: The selected file.
    """
    print("Available Files")
    for idx, file in enumerate(files, start=1):
        print(f"{idx}: {file}")

    while True:
        try:

            choice = int(input("Enter the number of the file you want to review: "))
            if 1 <= choice <= len(files):
                return files[choice-1]
            else:
                print("Invalid Choice. please select a valid file number")

        except ValueError:
            print("Invalid input. Please enter a number.")



def read_file_content(file_path):
    """
    Read the contents of the selected file.
    Args:
        file_path (str): Path to the file to read.
    Returns:
        str: The contents of the file.
    """
    try:
        with open(file_path, "r") as file:
            return file.read()
    except Exception as e:
        print(f"❌ Error reading file: {e}")
        sys.exit(1)

def review_file(file_content, model_name="llama3.2:1b"):
    """
    Generate a review for the given file content using the LLM.
    Args:
        file_content (str): The content of the file to review.
        model_name (str): The LLM model to use for review.
    """

    prompt_name="code_review"

    review=generate_message(staged_changes=file_content, model_name=model_name, prompt_name=prompt_name)

def get_git_diff():
    return run_command(['git', 'diff', '--unified=0'])

def review_code():
    selected_directory=choose_directory()
    if selected_directory == ". (current directory)":
        selected_directory = "."  # Normalize to current directory


    selected_directory = os.path.abspath(selected_directory)  # Absolute path
    print(f"DEBUG: Absolute directory path: {selected_directory}")

    files = list_files_in_directory(selected_directory)
    if not files:
        print(f"No files found in the selected directory: {selected_directory}")
        sys.exit(0)
    selected_file = choose_file(files)
    selected_file_path = os.path.join(selected_directory, selected_file)
    selected_file_path = os.path.abspath(selected_file_path)
    print(f"Selected file: {selected_file_path}")

    file_content = read_file_content(selected_file_path)
    print("\nCode Review Feedback:")
    generate_message(file_content, "llama3.2:1b", "code_review")