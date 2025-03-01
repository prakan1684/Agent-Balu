#!/bin/bash

# Simple installation script for testing
echo "=== Quick Agent-Balu Installation Test ==="

# Check Python installation
echo "Checking Python installation..."
python3 --version

# Install the package without optional dependencies
echo "Installing Agent-Balu (core only, no voice support)..."
pip3 install -e . --user --break-system-packages

if [ $? -eq 0 ]; then
    echo "Installation successful!"
    echo "You can now run: ai-commit --help"
    echo ""
    echo "Note: Voice features are not installed. To install voice support:"
    echo "pip3 install -e '.[voice]' --user --break-system-packages"
    echo ""
    echo "For voice support on macOS, you may need to install portaudio first:"
    echo "brew install portaudio"
else
    echo "Installation failed."
    exit 1
fi
