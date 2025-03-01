#!/bin/bash

# Non-interactive test script for installation
# Set environment variables for testing
export USE_VENV="no"
export SET_API_KEY="n"
export SET_API_URL="n"

# Source the functions from install.sh
source ./install.sh

# Run the installation with predefined answers
detect_os
check_python
check_pip
install_agent_balu
configure_env
add_to_path
display_usage

echo -e "${GREEN}Test installation complete!${NC}"
