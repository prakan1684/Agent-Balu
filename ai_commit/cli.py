import argparse
from ai_commit.commit_agent import run  # Import your main application logic
from ai_commit.review_agent import review_code
def main():
    parser = argparse.ArgumentParser(description="A multifunctional AI Agent")
    

    parser.add_argument("-c", "--commit", 
                        action="store_true",
                        help="Creates an ai generated commit message based on your changes.")
    
    
    parser.add_argument("-l", "--local",
                        type=str,
                        help=(
                        "Use a remote Llama model for generating the commit message. "
                        "AgentBalu -c -l [model name]")
    )

    parser.add_argument("-pr", "--pull-request", action="store_true", help="Generate a pull request desrcription")

    parser.add_argument("-r", "--review", action="store_true", help="review code changes")



    args = parser.parse_args()


    if args.commit:
        if args.local:
            if args.local.strip()=="":
                print(
                "❌ Error: No Llama model name provided.\n"
                "Use `-l [model_name]` to specify a model.\n"
                "Common models: llama2, llama-coder, vicuna.\n"
                "Check installed models with: `ollama list`.\n"
                "You can download any model using `ollama pull [model name]`"
                )
            else:
                print('Running specified local model...')
                run(local_llm=args.local, use_local=True)
        else:
            print("Running AI-based commit message generation...")
            run(local_llm="")
    elif args.review:
        if args.local:
            if args.local.strip()=="":
                print(
                "❌ Error: No Llama model name provided.\n"
                "Use `-l [model_name]` to specify a model.\n"
                "Common models: llama2, llama-coder, vicuna.\n"
                "Check installed models with: `ollama list`.\n"
                "You can download any model using `ollama pull [model name]`"
                )
            else:
                print('Running specified local model...')
                review_code(local_llm=args.local, use_local=True)
        else:
            print('Running specified local model...')
            review_code(local_llm="")
    else:
        parser.print_help()


if __name__ == "__main__":
    main()