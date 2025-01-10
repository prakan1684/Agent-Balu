import argparse
from ai_commit.app import run  # Import your main application logic
from ai_commit.app import generate_commit_message
def main():
    parser = argparse.ArgumentParser(description="A multifunctional AI Agent")
    

    parser.add_argument("-c", "--commit", 
                        action="store_true",
                        help="Creates an ai generated commit message based on your changes.")
    
    
    parser.add_argument("-l", "--local",
                        type=str,
                        help=(
                        "Use a remote Llama model for generating the commit message. "
                        "Provide the model name. Common models include:\n"
                        "  - llama2\n"
                        "  - llama-coder\n"
                        "  - vicuna\n\n"
                        "To see all locally available models, run: `ollama list`.")
    )


    
    args = parser.parse_args()


    if args.commit:
        if args.local:
            print('Running specified local model...')
            generate_commit_message(model_name=args.local)
        else:
            print("Running AI-based commit message generation...")
            run()
    else:
        parser.print_help()
    

if __name__ == "__main__":
    main()