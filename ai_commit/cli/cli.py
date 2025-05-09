import argparse
import sys
from typing import List, Optional

from ai_commit.Agents.commit_agent import CommitAgent
from ai_commit.core.config import config


def create_parser() -> argparse.ArgumentParser:
    """
    creates the argument parser, it will return the parsed argument

    """
    parser = argparse.ArgumentParser(
        description="A multifunctional AI agent for committing, reviewing, or pushing code."
    )

    # Commit message

    parser.add_argument(
        "-c", "--commit",
        action="store_true",
        help="Generate an AI based commit message for your changes."
    )

    # Local model
    parser.add_argument(
        "-l", "--local", 
        type=str,
        help=("use a local llama model for generating the commit message or code review"
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
    
    return parser

def validate_local_model(model_name: str) -> bool:
    """
    will validate the provided model name if it is not empty

    """
    if not model_name.strip():
        print(
            "❌ Error: No Llama model name provided.\n"
            "Use `-l [model_name]` to specify a model.\n"
            f"Common models: {', '.join(config.common_models)}.\n"
            "Check installed models with: `ollama list`.\n"
            "You can download any model using `ollama pull [model name]`"
        )
        return False
    return True


def main() -> None:
    """
    Entry point for the CLI program

    """

    parser = create_parser()
    args = parser.parse_args()

    if args.commit:
        if args.local and not validate_local_model(args.local):
            sys.exit(1)
        commit_agent = CommitAgent()
        commit_agent.run(use_local=bool(args.local), local_llm=args.local or "")
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
        