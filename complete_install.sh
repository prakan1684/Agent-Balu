#!/bin/bash

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Agent-Balu Complete Installation Script ===${NC}"
echo -e "${BLUE}This script will install Agent-Balu and set up required environment variables.${NC}"
echo ""

# Check Python installation
echo -e "${BLUE}Checking Python installation...${NC}"
if command -v python3 &>/dev/null; then
    PYTHON_CMD="python3"
    echo -e "${GREEN}Found Python: $($PYTHON_CMD --version)${NC}"
else
    echo -e "${RED}Error: Python 3 is required but not found.${NC}"
    echo -e "${YELLOW}Please install Python 3 and try again.${NC}"
    exit 1
fi

# Check Python version
PY_VERSION=$($PYTHON_CMD -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
echo -e "${GREEN}Python version: $PY_VERSION${NC}"

# Ensure Python version is at least 3.6
if [[ "$PY_VERSION" < "3.6" ]]; then
    echo -e "${RED}Error: Python 3.6 or higher is required. Found version $PY_VERSION.${NC}"
    echo -e "${YELLOW}Please upgrade Python and try again.${NC}"
    exit 1
fi

# Check pip installation
echo -e "${BLUE}Checking pip installation...${NC}"
if command -v pip3 &>/dev/null; then
    PIP_CMD="pip3"
    echo -e "${GREEN}Found pip: $($PIP_CMD --version)${NC}"
else
    echo -e "${YELLOW}pip not found. Attempting to install pip...${NC}"
    $PYTHON_CMD -m ensurepip --upgrade
    if command -v pip3 &>/dev/null; then
        PIP_CMD="pip3"
        echo -e "${GREEN}Found pip: $($PIP_CMD --version)${NC}"
    else
        echo -e "${RED}Error: Failed to install pip.${NC}"
        exit 1
    fi
fi

# Prompt for API credentials
echo -e "${BLUE}Setting up API credentials...${NC}"
echo -e "${YELLOW}These credentials are required for Agent-Balu to function properly.${NC}"

# Check for existing API URL in environment
EXISTING_API_URL=""
if [ -n "$AI_API_URL" ]; then
    EXISTING_API_URL="$AI_API_URL"
    echo -e "${YELLOW}Found existing API URL in environment: $EXISTING_API_URL${NC}"
    echo -e "${YELLOW}You can press Enter to keep this value or enter a new one.${NC}"
fi

# Prompt for API URL
echo -e "${BLUE}Please enter your AI API URL:${NC}"
if [ -n "$EXISTING_API_URL" ]; then
    echo -e "${YELLOW}[Current: $EXISTING_API_URL]${NC}"
fi
read -p "> " INPUT_API_URL

# Use existing value if input is empty
if [ -z "$INPUT_API_URL" ] && [ -n "$EXISTING_API_URL" ]; then
    API_API_URL="$EXISTING_API_URL"
    echo -e "${GREEN}Keeping existing API URL.${NC}"
else
    # Otherwise, require a non-empty value
    API_API_URL="$INPUT_API_URL"
    while [ -z "$API_API_URL" ]; do
        echo -e "${RED}Error: API URL cannot be empty. Please try again:${NC}"
        read -p "> " API_API_URL
    done
fi
echo -e "${GREEN}API URL set to: $API_API_URL${NC}"

# Check for existing API key in environment
EXISTING_API_KEY=""
if [ -n "$AI_API_KEY" ]; then
    EXISTING_API_KEY="$AI_API_KEY"
    echo -e "${YELLOW}Found existing API key in environment.${NC}"
    echo -e "${YELLOW}You can press Enter to keep this value or enter a new one.${NC}"
fi

# Prompt for API key
echo -e "${BLUE}Please enter your AI API key:${NC}"
if [ -n "$EXISTING_API_KEY" ]; then
    echo -e "${YELLOW}[Current: $(echo $EXISTING_API_KEY | cut -c1-5)...$(echo $EXISTING_API_KEY | cut -c-5)]${NC}"
fi
read -p "> " INPUT_API_KEY

# Use existing value if input is empty
if [ -z "$INPUT_API_KEY" ] && [ -n "$EXISTING_API_KEY" ]; then
    AI_API_KEY="$EXISTING_API_KEY"
    echo -e "${GREEN}Keeping existing API key.${NC}"
else
    # Otherwise, require a non-empty value
    AI_API_KEY="$INPUT_API_KEY"
    while [ -z "$AI_API_KEY" ]; do
        echo -e "${RED}Error: API key cannot be empty. Please try again:${NC}"
        read -p "> " AI_API_KEY
    done
fi
echo -e "${GREEN}API key set!${NC}"

# Determine shell configuration file
if [[ "$SHELL" == *"zsh"* ]]; then
    SHELL_CONFIG="$HOME/.zshrc"
elif [[ "$SHELL" == *"bash"* ]]; then
    SHELL_CONFIG="$HOME/.bashrc"
else
    # Default to .profile if shell is not recognized
    SHELL_CONFIG="$HOME/.profile"
fi

# Simple function to update environment variable in shell config
update_env_var() {
    local var_name="$1"
    local var_value="$2"
    local config_file="$3"
    
    # Escape special characters in the variable value
    var_value=$(echo "$var_value" | sed 's/[\/&]/\\&/g')
    
    if grep -q "export $var_name=" "$config_file"; then
        echo -e "${YELLOW}$var_name already exists in $config_file. Updating...${NC}"
        # Use sed to replace the existing line
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS requires an empty string for -i
            sed -i '' "s|export $var_name=.*|export $var_name=\"$var_value\"|g" "$config_file"
        else
            # Linux and others
            sed -i "s|export $var_name=.*|export $var_name=\"$var_value\"|g" "$config_file"
        fi
    else
        echo -e "${GREEN}Adding $var_name to $config_file${NC}"
        echo "export $var_name=\"$var_value\"" >> "$config_file"
    fi
    
    # Set for current session
    export "$var_name"="$var_value"
}

# Update environment variables
update_env_var "AI_API_URL" "$API_API_URL" "$SHELL_CONFIG"
update_env_var "AI_API_KEY" "$AI_API_KEY" "$SHELL_CONFIG"

echo -e "${GREEN}API credentials set successfully!${NC}"
echo -e "${YELLOW}Note: You'll need to run 'source $SHELL_CONFIG' or restart your terminal for the changes to take effect in new sessions.${NC}"

# Install system dependencies if needed
echo -e "${BLUE}Checking for system dependencies...${NC}"

# Check if we need to install portaudio for voice features
INSTALL_VOICE=false
read -p "Do you want to install voice support? (y/n): " VOICE_SUPPORT
if [[ "$VOICE_SUPPORT" == "y" || "$VOICE_SUPPORT" == "Y" ]]; then
    INSTALL_VOICE=true
    
    # Install portaudio if on macOS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo -e "${BLUE}Checking for portaudio (required for voice support on macOS)...${NC}"
        if ! command -v brew &>/dev/null; then
            echo -e "${YELLOW}Homebrew not found. Voice support may require manual installation of portaudio.${NC}"
            echo -e "${YELLOW}You can install Homebrew and portaudio with:${NC}"
            echo -e "${BLUE}/bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"${NC}"
            echo -e "${BLUE}brew install portaudio${NC}"
        else
            echo -e "${BLUE}Installing portaudio using Homebrew...${NC}"
            brew install portaudio
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}Portaudio installed successfully.${NC}"
            else
                echo -e "${YELLOW}Failed to install portaudio. Voice support may not work correctly.${NC}"
            fi
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo -e "${BLUE}Checking for portaudio (required for voice support on Linux)...${NC}"
        if command -v apt-get &>/dev/null; then
            echo -e "${BLUE}Installing portaudio using apt...${NC}"
            sudo apt-get update && sudo apt-get install -y portaudio19-dev python3-pyaudio
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}Portaudio installed successfully.${NC}"
            else
                echo -e "${YELLOW}Failed to install portaudio. Voice support may not work correctly.${NC}"
            fi
        elif command -v dnf &>/dev/null; then
            echo -e "${BLUE}Installing portaudio using dnf...${NC}"
            sudo dnf install -y portaudio-devel
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}Portaudio installed successfully.${NC}"
            else
                echo -e "${YELLOW}Failed to install portaudio. Voice support may not work correctly.${NC}"
            fi
        else
            echo -e "${YELLOW}Could not determine package manager. Voice support may require manual installation of portaudio.${NC}"
        fi
    fi
fi

# Fix numpy dependency issue before installing
echo -e "${BLUE}Installing/upgrading core dependencies...${NC}"
$PIP_CMD install --upgrade pip wheel setuptools --user
$PIP_CMD install --upgrade numpy pandas requests argparse chardet --user

# Install ollama if needed
echo -e "${BLUE}Checking for ollama...${NC}"
if ! command -v ollama &>/dev/null; then
    echo -e "${YELLOW}Ollama not found. Installing ollama package...${NC}"
    $PIP_CMD install --upgrade ollama --user
fi

# Install SpeechRecognition
echo -e "${BLUE}Installing SpeechRecognition...${NC}"
$PIP_CMD install --upgrade SpeechRecognition --user

# Install the package
echo -e "${BLUE}Installing Agent-Balu...${NC}"

# Find the correct bin directory
USER_BIN_PATH="$HOME/.local/bin"

# Determine installation flags based on voice support
if $INSTALL_VOICE; then
    echo -e "${BLUE}Installing Agent-Balu with voice support...${NC}"
    $PIP_CMD install -e ".[voice]" --user
else
    echo -e "${BLUE}Installing Agent-Balu without voice support...${NC}"
    $PIP_CMD install -e . --user
fi

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Agent-Balu installed successfully!${NC}"
else
    echo -e "${RED}Installation failed.${NC}"
    exit 1
fi

# Add to PATH if needed
if [[ ":$PATH:" != *":$USER_BIN_PATH:"* ]]; then
    echo -e "${YELLOW}Adding Python user bin directory to PATH...${NC}"
    
    if grep -q "export PATH=\"$USER_BIN_PATH:\$PATH\"" "$SHELL_CONFIG"; then
        echo -e "${YELLOW}PATH entry already exists in $SHELL_CONFIG.${NC}"
    else
        echo -e "${GREEN}Adding $USER_BIN_PATH to PATH in $SHELL_CONFIG${NC}"
        echo "export PATH=\"$USER_BIN_PATH:\$PATH\"" >> "$SHELL_CONFIG"
    fi
    
    # Set for current session
    export PATH="$USER_BIN_PATH:$PATH"
    
    echo -e "${YELLOW}Note: You'll need to run 'source $SHELL_CONFIG' or restart your terminal for the PATH changes to take effect in new sessions.${NC}"
else
    echo -e "${GREEN}Python user bin directory is already in PATH.${NC}"
fi

# Display usage information
echo -e "${BLUE}Agent-Balu has been installed. Here's how to use it:${NC}"
echo -e "${GREEN}Generate commit message:${NC} ai-commit --commit"
echo -e "${GREEN}Review code:${NC} ai-commit --review"
echo -e "${GREEN}Email management:${NC} ai-commit --email"
if $INSTALL_VOICE; then
    echo -e "${GREEN}Voice interaction:${NC} ai-commit --voice"
fi
echo -e "${GREEN}Use local model:${NC} ai-commit --commit --local llama2"
echo ""
echo -e "${YELLOW}For more information, run:${NC} ai-commit --help"
echo ""
echo -e "${GREEN}Installation complete!${NC}"

# Source the shell config to make changes available immediately
echo -e "${BLUE}Activating environment variables...${NC}"
if [ -f "$SHELL_CONFIG" ]; then
    source "$SHELL_CONFIG"
    echo -e "${GREEN}Environment activated!${NC}"
else
    echo -e "${YELLOW}Could not source $SHELL_CONFIG. You may need to restart your terminal.${NC}"
fi

# Verify installation
echo -e "${BLUE}Verifying installation...${NC}"
if command -v ai-commit &>/dev/null; then
    echo -e "${GREEN}ai-commit command is available!${NC}"
    ai-commit --help
else
    echo -e "${YELLOW}ai-commit command not found in current PATH.${NC}"
    echo -e "${YELLOW}You may need to run:${NC} source $SHELL_CONFIG"
    echo -e "${YELLOW}Or manually run:${NC} $USER_BIN_PATH/ai-commit --help"
    
    # Try to find the command
    FOUND_CMD=$(find $HOME -name ai-commit -type f 2>/dev/null | head -n 1)
    if [ -n "$FOUND_CMD" ]; then
        echo -e "${GREEN}Found ai-commit at: $FOUND_CMD${NC}"
        echo -e "${YELLOW}You can run it directly with:${NC} $FOUND_CMD --help"
    fi
fi
