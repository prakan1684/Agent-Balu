#!/bin/bash

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Agent-Balu Installation Script ===${NC}"
echo -e "${BLUE}This script will install Agent-Balu globally on your system.${NC}"
echo ""

# Check for Python
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

# Ensure Python version is at least 3.8
if [[ "$(echo "$PY_VERSION" | awk -F. '{print $1}')" -lt 3 ]] || [[ "$(echo "$PY_VERSION" | awk -F. '{print $1}')" -eq 3 && "$(echo "$PY_VERSION" | awk -F. '{print $2}')" -lt 8 ]]; then
    echo -e "${RED}Error: Python 3.8 or higher is required. Found version $PY_VERSION.${NC}"
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

# Install dependencies
echo -e "${BLUE}Installing dependencies...${NC}"
$PIP_CMD install --upgrade pip
$PIP_CMD install ollama requests SpeechRecognition

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
echo -e "${BLUE}source $SHELL_CONFIG${NC}"

# Apply to current session
export AI_API_URL="$API_API_URL"
export AI_API_KEY="$API_KEY"
echo -e "${GREEN}API credentials have also been applied to your current terminal session.${NC}"

# Install the package
echo -e "${BLUE}Installing Agent-Balu globally...${NC}"
$PIP_CMD install -e .

echo -e "${GREEN}Installation complete!${NC}"
echo -e "${BLUE}You can now use Agent-Balu from anywhere by running:${NC}"
echo -e "${YELLOW}ai-commit --commit${NC} - Generate commit messages"
echo -e "${YELLOW}ai-commit --review${NC} - Review code changes"
echo -e "${YELLOW}ai-commit --email${NC} - Manage emails"
echo -e "${YELLOW}ai-commit --local llama2${NC} - Use local LLM model"

echo -e "\n${GREEN}Thank you for installing Agent-Balu!${NC}"
