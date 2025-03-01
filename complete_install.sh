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

# Function to prompt for input with validation
get_input() {
    local prompt="$1"
    local var_name="$2"
    local value=""
    local max_attempts=3
    local attempt=1
    
    while [ -z "$value" ] && [ $attempt -le $max_attempts ]; do
        read -p "$prompt" value
        if [ -z "$value" ]; then
            echo -e "${RED}Error: Input cannot be empty. Attempt $attempt of $max_attempts.${NC}"
            attempt=$((attempt + 1))
        fi
    done
    
    if [ -z "$value" ]; then
        echo -e "${RED}Error: Failed to get valid input after $max_attempts attempts.${NC}"
        exit 1
    fi
    
    eval "$var_name='$value'"
}

# Prompt for API URL first
get_input "Enter your AI API URL: " AI_API_URL
echo -e "${GREEN}API URL set successfully!${NC}"

# Then prompt for API key
get_input "Enter your AI API key: " AI_API_KEY
echo -e "${GREEN}API key set successfully!${NC}"

# Validate the inputs one more time
if [ -z "$AI_API_URL" ] || [ -z "$AI_API_KEY" ]; then
    echo -e "${RED}Error: Both API URL and API key must be provided.${NC}"
    exit 1
fi

# Determine shell configuration file
if [[ "$SHELL" == *"zsh"* ]]; then
    SHELL_CONFIG="$HOME/.zshrc"
else
    SHELL_CONFIG="$HOME/.bashrc"
fi

# Function to update environment variable in shell config
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
update_env_var "AI_API_URL" "$AI_API_URL" "$SHELL_CONFIG"
update_env_var "AI_API_KEY" "$AI_API_KEY" "$SHELL_CONFIG"

echo -e "${GREEN}API credentials set successfully!${NC}"
echo -e "${YELLOW}Note: You'll need to run 'source $SHELL_CONFIG' or restart your terminal for the changes to take effect in new sessions.${NC}"

# Install the package
echo -e "${BLUE}Installing Agent-Balu...${NC}"
$PIP_CMD install -e . --user --break-system-packages

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Agent-Balu installed successfully!${NC}"
else
    echo -e "${RED}Installation failed.${NC}"
    exit 1
fi

# Add to PATH if needed
if [[ ":$PATH:" != *":$HOME/Library/Python/3."*"/bin:"* ]]; then
    echo -e "${YELLOW}Adding Python user bin directory to PATH...${NC}"
    
    # Find Python version
    PY_VERSION=$($PYTHON_CMD -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
    USER_BIN_PATH="$HOME/Library/Python/$PY_VERSION/bin"
    
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
