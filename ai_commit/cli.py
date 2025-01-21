import argparse
import speech_recognition as sr
from ai_commit.commit_agent import run as generate_commit # Import your main application logic
from ai_commit.review_agent import review_code
from ai_commit.email_agent import run_email_agent

COMMON_MODELS = ["llama2", "llama-coder", "vicuna"]


def validate_local_model(model_name: str) -> bool:
    """Validate if the provided model name is non-empty."""
    if not model_name.strip():
        print(
            "❌ Error: No Llama model name provided.\n"
            "Use `-l [model_name]` to specify a model.\n"
            f"Common models: {', '.join(COMMON_MODELS)}.\n"
            "Check installed models with: `ollama list`.\n"
            "You can download any model using `ollama pull [model name]`"
        )
        return False
    return True

def handle_local_model(model_name: str, use_local: bool, function):
    """Handle the logic for running a function with a local model."""
    if use_local:
        if validate_local_model(model_name):
            print(f"Running specified local model: {model_name}...")
            function(local_llm=model_name, use_local=True)
    else:
        print("Running AI-based operation...")
        function(local_llm="", use_local=False)


def listen_and_convert():
    recognizer = sr.Recognizer()
    with sr.Microphone() as source:
        print("Listening...")
        audio = recognizer.listen(source)
        try:
            text=recognizer.recognize_google(audio)
            print(f"You said : {text}")
            return text.lower()
        except sr.UnknownValueError:
            print("Sorry, I couldn't understand the audio.")
        except sr.RequestError:
            print("Sorry, there was an issue with the speech recognition service.")

def parse_voice_command(command: str):
    """Map voice commands to CLI arguments."""
    if "commit" in command:
        return ["--commit"]
    elif "review" in command:
        return ["--review"]
    elif "email" in command:
        return ["--email"]
    elif "pull request" in command:
        return ["--pull-request"]
    elif "local" in command:
        # Extract model name from the command (e.g., "use local llama2")
        model_name = command.split("local")[-1].strip()
        return ["--commit", "--local", model_name]
    else:
        print("Command not recognized.")
        return []

def main():
    parser = argparse.ArgumentParser(
        description="A multifunctional AI Agent for commit messages, code reviews, and email management."
    )

    # Commit message generation
    parser.add_argument(
        "-c", "--commit",
        action="store_true",
        help="Generate an AI-based commit message for your changes."
    )

    # Local model for commit or review
    parser.add_argument(
        "-l", "--local",
        type=str,
        help=(
            "Use a local Llama model for generating the commit message or code review. "
        )
    )

    # Pull request description
    parser.add_argument(
        "-pr", "--pull-request",
        action="store_true",
        help="Generate a pull request description."
    )

    # Code review
    parser.add_argument(
        "-r", "--review",
        action="store_true",
        help="Review code changes using AI."
    )

    # Email management
    parser.add_argument(
        "-e", "--email",
        action="store_true",
        help="Check spam emails and unsubscribe from recurring emails."
    )

    parser.add_argument(
        "-v", "--voice",
        action="store_true",
        help="Enable voice mode and interact with your voice and microphone."
    )

    args = parser.parse_args()
    
    if args.voice:
        print("Voice mode activated. Speak your command(commit, email, review)")
        command = listen_and_convert()
        if command:
            voice_args = parse_voice_command(command)
            args = parser.parse_args(voice_args)

    
    if args.commit:
        handle_local_model(args.local, bool(args.local), generate_commit)
    elif args.review:
        handle_local_model(args.local, bool(args.local), review_code)
    elif args.email:
        print("Running email agent...")
        run_email_agent()
    else:
        parser.print_help()

if __name__ == "__main__":
    main()