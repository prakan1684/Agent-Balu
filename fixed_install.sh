#!/bin/bash

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Agent-Balu Fixed Installation Script ===${NC}"
echo -e "${BLUE}This script will install Agent-Balu directly from GitHub.${NC}"
echo ""

# Check for git
echo -e "${BLUE}Checking git installation...${NC}"
if ! command -v git &>/dev/null; then
    echo -e "${RED}Error: git is required but not found.${NC}"
    echo -e "${YELLOW}Please install git and try again.${NC}"
    exit 1
fi

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
if [[ "$(echo "$PY_VERSION" | awk -F. '{print $1}')" -lt 3 ]] || [[ "$(echo "$PY_VERSION" | awk -F. '{print $1}')" -eq 3 && "$(echo "$PY_VERSION" | awk -F. '{print $2}')" -lt 6 ]]; then
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

# Create a temporary directory
echo -e "${BLUE}Creating temporary directory...${NC}"
TEMP_DIR=$(mktemp -d)
echo -e "${GREEN}Created temporary directory: $TEMP_DIR${NC}"

# Clone the repository
echo -e "${BLUE}Cloning Agent-Balu repository...${NC}"
git clone https://github.com/prakan1684/Agent-Balu.git "$TEMP_DIR/Agent-Balu"
if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to clone repository.${NC}"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Set up API credentials
echo -e "${BLUE}Setting up API credentials...${NC}"
echo -e "${YELLOW}These credentials are required for Agent-Balu to function properly.${NC}"

# Handle API URL configuration
if [ -n "$AI_API_URL" ]; then
    echo -e "${GREEN}Found existing API URL in environment: $AI_API_URL${NC}"
    echo -e "${YELLOW}You can press Enter to keep this value or enter a new one.${NC}"
fi

# Always prompt for API URL
read -p "Please enter your AI API URL:
[Current: ${AI_API_URL:-None}] > " API_API_URL

# Use existing value if input is empty
if [ -z "$API_API_URL" ]; then
    if [ -n "$AI_API_URL" ]; then
        API_API_URL="$AI_API_URL"
        echo -e "${GREEN}Keeping existing API URL.${NC}"
    else
        # Loop until we get a non-empty value
        while [ -z "$API_API_URL" ]; do
            echo -e "${RED}Error: API URL cannot be empty. Please try again:${NC}"
            read -p "Please enter your AI API URL: " API_API_URL
        done
    fi
fi

echo -e "${GREEN}API URL set to: $API_API_URL${NC}"

# Handle API Key configuration
if [ -n "$AI_API_KEY" ]; then
    # Mask the API key to show only first and last 5 characters
    if [ ${#AI_API_KEY} -gt 10 ]; then
        MASKED_KEY="${AI_API_KEY:0:5}...${AI_API_KEY: -5}"
    else
        MASKED_KEY="$AI_API_KEY"
    fi
    echo -e "${GREEN}Found existing API key in environment.${NC}"
    echo -e "${YELLOW}You can press Enter to keep this value or enter a new one.${NC}"
fi

# Always prompt for API Key
read -p "Please enter your AI API key:
[Current: ${MASKED_KEY:-None}] > " API_KEY

# Use existing value if input is empty
if [ -z "$API_KEY" ]; then
    if [ -n "$AI_API_KEY" ]; then
        API_KEY="$AI_API_KEY"
        echo -e "${GREEN}Keeping existing API key.${NC}"
    else
        # Loop until we get a non-empty value
        while [ -z "$API_KEY" ]; do
            echo -e "${RED}Error: API key cannot be empty. Please try again:${NC}"
            read -p "Please enter your AI API key: " API_KEY
        done
    fi
fi

echo -e "${GREEN}API key set!${NC}"

# Determine shell configuration file
SHELL_CONFIG=""
if [ -f "$HOME/.zshrc" ]; then
    SHELL_CONFIG="$HOME/.zshrc"
elif [ -f "$HOME/.bashrc" ]; then
    SHELL_CONFIG="$HOME/.bashrc"
elif [ -f "$HOME/.profile" ]; then
    SHELL_CONFIG="$HOME/.profile"
else
    echo -e "${YELLOW}Could not find shell configuration file. Creating .profile...${NC}"
    touch "$HOME/.profile"
    SHELL_CONFIG="$HOME/.profile"
fi

# Function to update environment variables
update_env_var() {
    local var_name="$1"
    local var_value="$2"
    local config_file="$3"
    
    # Check if the variable already exists in the file
    if grep -q "export $var_name=" "$config_file"; then
        # Update existing variable
        echo -e "${YELLOW}$var_name already exists in $config_file. Updating...${NC}"
        # Use different sed syntax based on OS
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS requires an empty string for -i
            sed -i '' "s|export $var_name=.*|export $var_name=\"$var_value\"|g" "$config_file"
        else
            # Linux doesn't
            sed -i "s|export $var_name=.*|export $var_name=\"$var_value\"|g" "$config_file"
        fi
    else
        # Add new variable
        echo -e "${YELLOW}Adding $var_name to $config_file...${NC}"
        echo "export $var_name=\"$var_value\"" >> "$config_file"
    fi
}

# Update environment variables
update_env_var "AI_API_URL" "$API_API_URL" "$SHELL_CONFIG"
update_env_var "AI_API_KEY" "$API_KEY" "$SHELL_CONFIG"

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
if ! $PYTHON_CMD -c "import ollama" &>/dev/null; then
    echo -e "${YELLOW}Ollama not found. Installing ollama package...${NC}"
    $PIP_CMD install --upgrade ollama --user
fi

# Install SpeechRecognition
echo -e "${BLUE}Installing SpeechRecognition...${NC}"
$PIP_CMD install --upgrade SpeechRecognition --user

# Install the package
echo -e "${BLUE}Installing Agent-Balu...${NC}"
cd "$TEMP_DIR/Agent-Balu"

if [ "$INSTALL_VOICE" = true ]; then
    echo -e "${BLUE}Installing Agent-Balu with voice support...${NC}"
    $PIP_CMD install -e ".[voice]" --user
else
    echo -e "${BLUE}Installing Agent-Balu without voice support...${NC}"
    $PIP_CMD install -e . --user
fi

if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Installation failed.${NC}"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Add user bin directory to PATH if needed
USER_BIN_PATH=$(python3 -m site --user-base)/bin
if [[ ":$PATH:" != *":$USER_BIN_PATH:"* ]]; then
    echo -e "${YELLOW}Adding Python user bin directory to PATH...${NC}"
    
    if grep -q "export PATH=\"$USER_BIN_PATH:\$PATH\"" "$SHELL_CONFIG"; then
        echo -e "${YELLOW}PATH entry already exists in $SHELL_CONFIG.${NC}"
    else
        echo -e "${YELLOW}Adding PATH entry to $SHELL_CONFIG...${NC}"
        echo "export PATH=\"$USER_BIN_PATH:\$PATH\"" >> "$SHELL_CONFIG"
    fi
    
    # Update current PATH
    export PATH="$USER_BIN_PATH:$PATH"
fi

# Clean up
echo -e "${BLUE}Cleaning up...${NC}"
rm -rf "$TEMP_DIR"

# Display usage information
echo -e "${GREEN}Agent-Balu has been installed successfully!${NC}"
echo -e "${BLUE}Here's how to use it:${NC}"
echo -e "${YELLOW}Generate commit message: ${GREEN}ai-commit --commit${NC}"
echo -e "${YELLOW}Review code: ${GREEN}ai-commit --review${NC}"
echo -e "${YELLOW}Email management: ${GREEN}ai-commit --email${NC}"
if [ "$INSTALL_VOICE" = true ]; then
    echo -e "${YELLOW}Voice interaction: ${GREEN}ai-commit --voice${NC}"
fi
echo -e "${YELLOW}Use local model: ${GREEN}ai-commit --commit --local llama2${NC}"
echo -e ""
echo -e "${BLUE}For more information, run: ${GREEN}ai-commit --help${NC}"

# Verify installation
echo -e "${BLUE}Verifying installation...${NC}"
if command -v ai-commit &>/dev/null; then
    echo -e "${GREEN}ai-commit command is available!${NC}"
else
    echo -e "${YELLOW}ai-commit command not found in current PATH.${NC}"
    echo -e "${YELLOW}You may need to run 'source $SHELL_CONFIG' or restart your terminal for the changes to take effect.${NC}"
    
    # Try to find the command
    COMMAND_PATH=$(find "$HOME" -name ai-commit -type f -executable 2>/dev/null | head -n 1)
    if [ -n "$COMMAND_PATH" ]; then
        echo -e "${GREEN}Found ai-commit at: $COMMAND_PATH${NC}"
        echo -e "${YELLOW}You can run it directly with: ${GREEN}\"$COMMAND_PATH\" --help${NC}"
    else
        echo -e "${RED}Could not find ai-commit in your home directory.${NC}"
        echo -e "${YELLOW}Please check if the installation was successful.${NC}"
    fi
fi

echo -e "${GREEN}Installation complete!${NC}"
