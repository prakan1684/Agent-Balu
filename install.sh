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

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Detect OS
detect_os() {
    case "$(uname -s)" in
        Linux*)     OS="Linux";;
        Darwin*)    OS="macOS";;
        CYGWIN*)    OS="Windows";;
        MINGW*)     OS="Windows";;
        MSYS*)      OS="Windows";;
        *)          OS="Unknown";;
    esac
    echo -e "${BLUE}Detected OS: ${OS}${NC}"
}

# Check Python installation
check_python() {
    echo -e "${BLUE}Checking Python installation...${NC}"
    
    if command_exists python3; then
        PYTHON_CMD="python3"
    elif command_exists python; then
        # Check if python is Python 3
        PY_VERSION=$(python --version 2>&1)
        if [[ $PY_VERSION == *"Python 3"* ]]; then
            PYTHON_CMD="python"
        else
            echo -e "${RED}Error: Python 3 is required but not found.${NC}"
            echo -e "${YELLOW}Please install Python 3 and try again.${NC}"
            exit 1
        fi
    else
        echo -e "${RED}Error: Python 3 is required but not found.${NC}"
        echo -e "${YELLOW}Please install Python 3 and try again.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Found Python: $($PYTHON_CMD --version)${NC}"
}

# Check pip installation
check_pip() {
    echo -e "${BLUE}Checking pip installation...${NC}"
    
    if command_exists pip3; then
        PIP_CMD="pip3"
    elif command_exists pip; then
        PIP_CMD="pip"
    else
        echo -e "${YELLOW}pip not found. Attempting to install pip...${NC}"
        $PYTHON_CMD -m ensurepip --upgrade
        if command_exists pip3; then
            PIP_CMD="pip3"
        elif command_exists pip; then
            PIP_CMD="pip"
        else
            echo -e "${RED}Error: Failed to install pip.${NC}"
            exit 1
        fi
    fi
    
    echo -e "${GREEN}Found pip: $($PIP_CMD --version)${NC}"
}

# Install dependencies and Agent-Balu
install_agent_balu() {
    echo -e "${BLUE}Installing Agent-Balu and dependencies...${NC}"
    
    # Create a virtual environment if requested
    if [[ "$USE_VENV" == "yes" ]]; then
        echo -e "${BLUE}Creating virtual environment...${NC}"
        $PYTHON_CMD -m venv venv
        
        # Activate the virtual environment based on OS
        if [[ "$OS" == "Windows" ]]; then
            source venv/Scripts/activate
        else
            source venv/bin/activate
        fi
        
        # Update pip in the virtual environment
        $PIP_CMD install --upgrade pip
        
        # In virtual environment, don't use --user flag
        $PIP_CMD install -e .
    else
        # Outside virtual environment, use --user flag
        if [[ "$OS" == "Windows" ]]; then
            # On Windows, we don't use --break-system-packages
            $PIP_CMD install -e . --user
        else
            # On Unix systems, we use --break-system-packages for global installation
            $PIP_CMD install -e . --user --break-system-packages
        fi
    fi
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Agent-Balu installed successfully!${NC}"
    else
        echo -e "${RED}Installation failed.${NC}"
        exit 1
    fi
}

# Configure environment variables
configure_env() {
    echo -e "${BLUE}Configuring environment variables...${NC}"
    
    # Check if API key is already set
    if [ -z "$AI_API_KEY" ]; then
        echo -e "${YELLOW}AI_API_KEY environment variable is not set.${NC}"
        read -p "Would you like to set it now? (y/n): " SET_API_KEY
        
        if [[ "$SET_API_KEY" == "y" || "$SET_API_KEY" == "Y" ]]; then
            read -p "Enter your AI API key: " API_KEY
            
            # Determine the shell configuration file
            if [[ "$OS" == "macOS" || "$OS" == "Linux" ]]; then
                if [[ "$SHELL" == *"zsh"* ]]; then
                    SHELL_CONFIG="$HOME/.zshrc"
                else
                    SHELL_CONFIG="$HOME/.bashrc"
                fi
                
                # Add environment variable to shell config
                echo "export AI_API_KEY=\"$API_KEY\"" >> "$SHELL_CONFIG"
                echo -e "${GREEN}Added AI_API_KEY to $SHELL_CONFIG${NC}"
                echo -e "${YELLOW}Please run 'source $SHELL_CONFIG' to apply changes.${NC}"
            elif [[ "$OS" == "Windows" ]]; then
                echo -e "${YELLOW}On Windows, please set the environment variable manually:${NC}"
                echo -e "${YELLOW}1. Right-click on 'This PC' and select 'Properties'${NC}"
                echo -e "${YELLOW}2. Click on 'Advanced system settings'${NC}"
                echo -e "${YELLOW}3. Click on 'Environment Variables'${NC}"
                echo -e "${YELLOW}4. Add a new user variable named 'AI_API_KEY' with your API key${NC}"
            fi
        fi
    else
        echo -e "${GREEN}AI_API_KEY is already set.${NC}"
    fi
    
    # Check if API URL is already set
    if [ -z "$AI_API_URL" ]; then
        echo -e "${YELLOW}AI_API_URL environment variable is not set.${NC}"
        read -p "Would you like to set it now? (y/n): " SET_API_URL
        
        if [[ "$SET_API_URL" == "y" || "$SET_API_URL" == "Y" ]]; then
            read -p "Enter your AI API URL: " API_URL
            
            # Determine the shell configuration file
            if [[ "$OS" == "macOS" || "$OS" == "Linux" ]]; then
                if [[ "$SHELL" == *"zsh"* ]]; then
                    SHELL_CONFIG="$HOME/.zshrc"
                else
                    SHELL_CONFIG="$HOME/.bashrc"
                fi
                
                # Add environment variable to shell config
                echo "export AI_API_URL=\"$API_URL\"" >> "$SHELL_CONFIG"
                echo -e "${GREEN}Added AI_API_URL to $SHELL_CONFIG${NC}"
                echo -e "${YELLOW}Please run 'source $SHELL_CONFIG' to apply changes.${NC}"
            elif [[ "$OS" == "Windows" ]]; then
                echo -e "${YELLOW}On Windows, please set the environment variable manually:${NC}"
                echo -e "${YELLOW}1. Right-click on 'This PC' and select 'Properties'${NC}"
                echo -e "${YELLOW}2. Click on 'Advanced system settings'${NC}"
                echo -e "${YELLOW}3. Click on 'Environment Variables'${NC}"
                echo -e "${YELLOW}4. Add a new user variable named 'AI_API_URL' with your API URL${NC}"
            fi
        fi
    else
        echo -e "${GREEN}AI_API_URL is already set.${NC}"
    fi
}

# Add to PATH (if needed)
add_to_path() {
    if [[ "$OS" == "Windows" ]]; then
        echo -e "${YELLOW}On Windows, please ensure the Python Scripts directory is in your PATH.${NC}"
    else
        # Check if ~/.local/bin is in PATH
        if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
            echo -e "${YELLOW}Adding ~/.local/bin to PATH...${NC}"
            
            if [[ "$SHELL" == *"zsh"* ]]; then
                SHELL_CONFIG="$HOME/.zshrc"
            else
                SHELL_CONFIG="$HOME/.bashrc"
            fi
            
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_CONFIG"
            echo -e "${GREEN}Added ~/.local/bin to PATH in $SHELL_CONFIG${NC}"
            echo -e "${YELLOW}Please run 'source $SHELL_CONFIG' to apply changes.${NC}"
        else
            echo -e "${GREEN}~/.local/bin is already in PATH.${NC}"
        fi
    fi
}

# Display usage information
display_usage() {
    echo -e "${BLUE}Agent-Balu has been installed. Here's how to use it:${NC}"
    echo -e "${GREEN}Generate commit message:${NC} ai-commit --commit"
    echo -e "${GREEN}Review code:${NC} ai-commit --review"
    echo -e "${GREEN}Email management:${NC} ai-commit --email"
    echo -e "${GREEN}Voice interaction:${NC} ai-commit --voice"
    echo -e "${GREEN}Use local model:${NC} ai-commit --commit --local llama2"
    echo ""
    echo -e "${YELLOW}For more information, run:${NC} ai-commit --help"
}

# Main installation process
main() {
    detect_os
    check_python
    check_pip
    
    # Ask if user wants to use a virtual environment
    read -p "Do you want to install in a virtual environment? (y/n): " USE_VENV_INPUT
    if [[ "$USE_VENV_INPUT" == "y" || "$USE_VENV_INPUT" == "Y" ]]; then
        USE_VENV="yes"
    else
        USE_VENV="no"
    fi
    
    install_agent_balu
    configure_env
    add_to_path
    display_usage
    
    echo -e "${GREEN}Installation complete!${NC}"
}

# Run the main function
main
