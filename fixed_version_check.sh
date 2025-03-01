#!/bin/bash

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Python Version Check Test ===${NC}"
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

echo -e "${BLUE}Testing old version check (string comparison):${NC}"
if [[ "$PY_VERSION" < "3.6" ]]; then
    echo -e "${RED}FAILED: Python 3.6 or higher is required. Found version $PY_VERSION.${NC}"
else
    echo -e "${GREEN}PASSED: Python version $PY_VERSION meets the requirement.${NC}"
fi

echo -e "${BLUE}Testing new version check (numeric comparison):${NC}"
if [[ "$(echo "$PY_VERSION" | awk -F. '{print $1}')" -lt 3 ]] || [[ "$(echo "$PY_VERSION" | awk -F. '{print $1}')" -eq 3 && "$(echo "$PY_VERSION" | awk -F. '{print $2}')" -lt 6 ]]; then
    echo -e "${RED}FAILED: Python 3.6 or higher is required. Found version $PY_VERSION.${NC}"
else
    echo -e "${GREEN}PASSED: Python version $PY_VERSION meets the requirement.${NC}"
fi

echo -e "\n${BLUE}=== Test Complete ===${NC}"
