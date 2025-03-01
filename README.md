# AgentBalu - AI Commit Message Generator

AgentBalu is a Python-based tool that uses AI to generate concise and informative Git commit messages based on staged changes. It's designed to simplify the commit process and improve commit quality for developers.

---

## Features

- Automatically analyzes staged Git changes to generate meaningful commit messages.
- Utilizes a remote AI model for commit message generation.
- Lightweight and easy to integrate into any development workflow.

---

## Installation

### Remote Installation (Recommended)

You can install Agent-Balu directly from GitHub with a single command:

#### For macOS/Linux:

```bash
curl -fsSL https://raw.githubusercontent.com/prakan1684/Agent-Balu/master/remote_install.sh | bash
```

or

````bash
curl -fsSL https://raw.githubusercontent.com/prakan1684/Agent-Balu/master/remote_install.sh -o /tmp/agent_balu_install.sh && chmod +x /tmp/agent_balu_install.sh && bash /tmp/agent_balu_install.sh

#### For Windows (using PowerShell):

```powershell
iwr -useb https://raw.githubusercontent.com/prakan1684/Agent-Balu/master/remote_install.sh | iex
````

This will:

1. Clone the repository
2. Prompt for your AI API credentials
3. Install all dependencies
4. Configure your environment

### Quick Installation

You can install Agent-Balu using the provided installation scripts:

#### For macOS/Linux:

```bash
# Make the script executable
chmod +x install.sh

# Run the installation script
./install.sh
```

#### For Windows:

```bash
# Run the installation script
install.bat
```

The installation scripts will:

- Check for Python 3 and pip
- Install Agent-Balu and its dependencies
- Configure environment variables (AI_API_KEY and AI_API_URL)
- Add the command to your PATH (if needed)

### Manual Installation

If you prefer to install manually:

```bash
# Clone the repository
git clone https://github.com/prakan1684/Agent-Balu.git
cd Agent-Balu

# Install the package
pip install -e . --user --break-system-packages  # On Unix systems
pip install -e . --user                          # On Windows
```

### Environment Variables

Agent-Balu requires the following environment variables:

- `AI_API_KEY`: Your API key for the AI service
- `AI_API_URL`: The URL of the AI API service

You can set these variables in your shell profile or using the installation scripts.

## Usage

AgentBalu is configured to be used globally in any project.

1. Stage Your Changes: Make sure you have staged changes in your Git repository:

   ```bash
   git add <file>
   ```

2. Run the Tool: Simply type:

   ```bash
   AgentBalu [command]
   ```

3. Example Output `AgentBalu -c`:
   ```bash
   Running AI-based commit message generation...
   ✨ Generating commit message:
   - Updated logic for user authentication
   - Improved error handling for invalid inputs
   ```

## Test Line

This is a test line to verify commit message generation.

## Cleanup

You can run `make clean` to clean the package when you are done using it to uninstall the package.
Alternatively you can run `pip uninstall ai-commit` or `pip3 uninstall ai-commit`.
