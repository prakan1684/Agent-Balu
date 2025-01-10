# AgentBalu - AI Commit Message Generator

AgentBalu is a Python-based tool that uses AI to generate concise and informative Git commit messages based on staged changes. It's designed to simplify the commit process and improve commit quality for developers.

---

## Features

- Automatically analyzes staged Git changes to generate meaningful commit messages.
- Utilizes a remote AI model for commit message generation.
- Lightweight and easy to integrate into any development workflow.

---

## Installation

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/yourusername/AgentBalu.git
   cd AgentBalu
2. **Setup environment variables for API_KEY and API_URL(Linux/MacOS)**:
   ```bash
   export AI_API_KEY="your_api_key_here"
   export AI_API_URL="https://your.api.url"

   #reload shell

   source ~/.bashrc  # Or source ~/.zshrc for MacOS
3. **Environment variables for (Windows)**:
   ```bash
   $env:AI_API_KEY="your_api_key_here"
   $env:AI_API_URL="https://your.api.url"
4. **Run the makefile for seamless setup and cleanup:
   ```bash
   make setup
## Usage

AgentBalu is configured to be used globally in any project.

1. Stage Your Changes: Make sure you have staged changes in your Git repository:

   ```bash
   git add <file>
2. Run the Tool: Simply type:

   ```bash
   AgentBalu [command]
3. Example Output `AgentBalu -c`:
   ```bash
   Running AI-based commit message generation...
   ✨ Generating commit message:
   - Updated logic for user authentication
   - Improved error handling for invalid inputs

## Cleanup

You can run `make clean` to clean the package when you are done using it to uninstall the package.
Alternatively you can run `pip uninstall ai-commit` or `pip3 uninstall ai-commit`.
