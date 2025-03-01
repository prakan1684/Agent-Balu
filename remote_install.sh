#!/bin/bash

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Agent-Balu Remote Installation Script ===${NC}"
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
TEMP_DIR=$(mktemp -d)
echo -e "${BLUE}Created temporary directory: ${TEMP_DIR}${NC}"

# Clone the repository
echo -e "${BLUE}Cloning Agent-Balu repository...${NC}"
git clone https://github.com/prakan1684/Agent-Balu.git "${TEMP_DIR}/Agent-Balu"
if [ $? -ne 0 ]; then
    echo -e "${RED}Error: Failed to clone repository.${NC}"
    rm -rf "${TEMP_DIR}"
    exit 1
fi

# Change to the repository directory
cd "${TEMP_DIR}/Agent-Balu"

# Prompt for API credentials
echo -e "${BLUE}Setting up API credentials...${NC}"
echo -e "${YELLOW}These credentials are required for Agent-Balu to function properly.${NC}"

# Prompt for API key
read -p "Enter your AI API key: " AI_API_KEY
if [ -z "$AI_API_KEY" ]; then
    echo -e "${RED}Error: API key cannot be empty.${NC}"
    rm -rf "${TEMP_DIR}"
    exit 1
fi

# Prompt for API URL
read -p "Enter your AI API URL: " AI_API_URL
if [ -z "$AI_API_URL" ]; then
    echo -e "${RED}Error: API URL cannot be empty.${NC}"
    rm -rf "${TEMP_DIR}"
    exit 1
fi

# Determine shell configuration file
if [[ "$SHELL" == *"zsh"* ]]; then
    SHELL_CONFIG="$HOME/.zshrc"
elif [[ "$SHELL" == *"bash"* ]]; then
    SHELL_CONFIG="$HOME/.bashrc"
else
    # Default to .profile if shell is not recognized
    SHELL_CONFIG="$HOME/.profile"
fi

# Check if variables already exist in shell config
if grep -q "export AI_API_KEY" "$SHELL_CONFIG"; then
    echo -e "${YELLOW}AI_API_KEY already exists in $SHELL_CONFIG. Updating...${NC}"
    # Use sed to replace the existing line
    sed -i.bak "s|export AI_API_KEY=.*|export AI_API_KEY=\"$AI_API_KEY\"|g" "$SHELL_CONFIG"
else
    echo -e "${GREEN}Adding AI_API_KEY to $SHELL_CONFIG${NC}"
    echo "export AI_API_KEY=\"$AI_API_KEY\"" >> "$SHELL_CONFIG"
fi

if grep -q "export AI_API_URL" "$SHELL_CONFIG"; then
    echo -e "${YELLOW}AI_API_URL already exists in $SHELL_CONFIG. Updating...${NC}"
    # Use sed to replace the existing line
    sed -i.bak "s|export AI_API_URL=.*|export AI_API_URL=\"$AI_API_URL\"|g" "$SHELL_CONFIG"
else
    echo -e "${GREEN}Adding AI_API_URL to $SHELL_CONFIG${NC}"
    echo "export AI_API_URL=\"$AI_API_URL\"" >> "$SHELL_CONFIG"
fi

# Set variables for current session
export AI_API_KEY="$AI_API_KEY"
export AI_API_URL="$AI_API_URL"

echo -e "${GREEN}API credentials set successfully!${NC}"
echo -e "${YELLOW}Note: You'll need to run 'source $SHELL_CONFIG' or restart your terminal for the changes to take effect in new sessions.${NC}"

# Install the package
echo -e "${BLUE}Installing Agent-Balu...${NC}"

# Determine installation flags based on OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    $PIP_CMD install -e . --user --break-system-packages
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    $PIP_CMD install -e . --user
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
    # Windows
    $PIP_CMD install -e .
else
    # Default
    $PIP_CMD install -e . --user
fi

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Agent-Balu installed successfully!${NC}"
else
    echo -e "${RED}Installation failed.${NC}"
    rm -rf "${TEMP_DIR}"
    exit 1
fi

# Find Python user bin directory
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    PY_VERSION=$($PYTHON_CMD -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
    USER_BIN_PATH="$HOME/Library/Python/$PY_VERSION/bin"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    USER_BIN_PATH="$HOME/.local/bin"
else
    # Default/Windows
    USER_BIN_PATH="$HOME/.local/bin"
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

# Clean up
echo -e "${BLUE}Cleaning up temporary files...${NC}"
cd "$HOME"
rm -rf "${TEMP_DIR}"

# Display usage information
echo -e "${BLUE}Agent-Balu has been installed. Here's how to use it:${NC}"
echo -e "${GREEN}Generate commit message:${NC} ai-commit --commit"
echo -e "${GREEN}Review code:${NC} ai-commit --review"
echo -e "${GREEN}Email management:${NC} ai-commit --email"
echo -e "${GREEN}Voice interaction:${NC} ai-commit --voice"
echo -e "${GREEN}Use local model:${NC} ai-commit --commit --local llama2"
echo ""
echo -e "${YELLOW}For more information, run:${NC} ai-commit --help"
echo ""
echo -e "${GREEN}Installation complete!${NC}"

# Verify installation
echo -e "${BLUE}Verifying installation...${NC}"
if command -v ai-commit &>/dev/null; then
    echo -e "${GREEN}ai-commit command is available!${NC}"
    ai-commit --help
else
    echo -e "${YELLOW}ai-commit command not found in current PATH.${NC}"
    echo -e "${YELLOW}You may need to run:${NC} source $SHELL_CONFIG"
    echo -e "${YELLOW}Or manually run:${NC} $USER_BIN_PATH/ai-commit --help"
fi
