SHELL := /bin/bash

.PHONY: clean check setup install-script install-windows fix help
.DEFAULT_GOAL = help

check: # Ruff check
	@ruff check .
	@echo "✅ Check complete!"

fix: # Fix auto-fixable linting issues
	@ruff check app.py --fix
	@echo "✅ Auto-fix complete!"

clean: # Clean temporary and build files
	@echo "🧹 Cleaning up..."
	@rm -rf __pycache__ .pytest_cache
	@rm -rf build dist *.egg-info
	@find . -name '*.pyc' -delete
	@find . -name '__pycache__' -delete
	@echo "✅ Clean-up complete!"

setup: # Install the package globally (legacy method)
	@echo "🔧 Installing the package globally..."
	@if ! command -v pip3 &>/dev/null; then \
		echo "❌ Error: 'pip' is not installed. Please install pip first."; \
		exit 1; \
	fi
	@if [ "$$(id -u)" -eq 0 ]; then \
		pip3 install . --break-system-packages; \
	else \
		echo "Running with sudo to ensure global installation..."; \
		sudo -H pip3 install . --break-system-packages; \
	fi
	@if [ -z "$$AI_API_KEY" ] || [ -z "$$AI_API_URL" ]; then \
		echo "❌ Error: 'AI_API_KEY' and 'AI_API_URL' environment variables are not set."; \
		echo "➡️  Please set them using the following commands (Linux/MacOS):"; \
		echo "   export AI_API_KEY='your_api_key_here'"; \
		echo "   export AI_API_URL='https://your.api.url'"; \
		echo "➡️  Or (Windows):"; \
		echo "   setx AI_API_KEY 'your_api_key_here'"; \
		echo "   setx AI_API_URL 'https://your.api.url'"; \
		exit 1; \
	fi
	@echo -e "\n✅ Installation complete! Run the following command to verify:\n\n ➡️ ai-commit --help"

install-script: # Install using the shell script (recommended for Unix systems)
	@echo "🔧 Installing using the shell script..."
	@chmod +x install.sh
	@./install.sh

install-windows: # Install using the batch script (recommended for Windows)
	@echo "🔧 Installing using the Windows batch script..."
	@echo "Please run install.bat from a Command Prompt or PowerShell window."

help: # Show this help
	@egrep -h '\s#\s' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?# "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
