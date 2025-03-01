#!/bin/bash

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Quick Agent-Balu Installation Test ===${NC}"

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

# Install the package without optional dependencies
echo -e "${BLUE}Installing Agent-Balu (core only, no voice support)...${NC}"

# Find the correct bin directory
USER_BIN_PATH="$HOME/.local/bin"

# Install the package
$PIP_CMD install -e . --user

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Installation successful!${NC}"
    
    # Add to PATH if needed
    if [[ ":$PATH:" != *":$USER_BIN_PATH:"* ]]; then
        echo -e "${YELLOW}Note: You may need to add $USER_BIN_PATH to your PATH.${NC}"
        echo -e "${YELLOW}Add this to your shell configuration file (.bashrc, .zshrc, etc.):${NC}"
        echo -e "${BLUE}export PATH=\"$USER_BIN_PATH:\$PATH\"${NC}"
    fi
    
    echo -e "${GREEN}You can now run:${NC} ai-commit --help"
    echo ""
    echo -e "${YELLOW}Note: Voice features are not installed. To install voice support:${NC}"
    
    # Check if portaudio is needed
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo -e "${YELLOW}For voice support on macOS, you need to install portaudio first:${NC}"
        echo -e "${BLUE}brew install portaudio${NC}"
        echo -e "${YELLOW}Then install the voice dependencies:${NC}"
        echo -e "${BLUE}$PIP_CMD install -e '.[voice]' --user${NC}"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo -e "${YELLOW}For voice support on Linux, you need to install portaudio first:${NC}"
        if command -v apt-get &>/dev/null; then
            echo -e "${BLUE}sudo apt-get update && sudo apt-get install -y portaudio19-dev python3-pyaudio${NC}"
        elif command -v dnf &>/dev/null; then
            echo -e "${BLUE}sudo dnf install -y portaudio-devel${NC}"
        else
            echo -e "${YELLOW}Install portaudio using your package manager${NC}"
        fi
        echo -e "${YELLOW}Then install the voice dependencies:${NC}"
        echo -e "${BLUE}$PIP_CMD install -e '.[voice]' --user${NC}"
    else
        echo -e "${BLUE}$PIP_CMD install -e '.[voice]' --user${NC}"
    fi
    
    # Verify installation
    echo -e "${BLUE}Verifying installation...${NC}"
    if command -v ai-commit &>/dev/null; then
        echo -e "${GREEN}ai-commit command is available!${NC}"
    else
        echo -e "${YELLOW}ai-commit command not found in current PATH.${NC}"
        
        # Try to find the command
        FOUND_CMD=$(find $HOME -name ai-commit -type f 2>/dev/null | head -n 1)
        if [ -n "$FOUND_CMD" ]; then
            echo -e "${GREEN}Found ai-commit at: $FOUND_CMD${NC}"
            echo -e "${YELLOW}You can run it directly with:${NC} $FOUND_CMD --help"
        fi
    fi
else
    echo -e "${RED}Installation failed.${NC}"
    exit 1
fi
