@echo off
setlocal enabledelayedexpansion

echo === Agent-Balu Installation Script for Windows ===
echo This script will install Agent-Balu globally on your system.
echo.

:: Check Python installation
echo Checking Python installation...
where python >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo Error: Python is not installed or not in PATH.
    echo Please install Python 3 and try again.
    exit /b 1
)

:: Check Python version
for /f "tokens=2" %%I in ('python --version 2^>^&1') do set PYTHON_VERSION=%%I
echo Found Python version: %PYTHON_VERSION%

:: Check if it's Python 3
echo %PYTHON_VERSION% | findstr /r "^3\." >nul
if %ERRORLEVEL% neq 0 (
    echo Error: Python 3 is required. Found version %PYTHON_VERSION%.
    echo Please install Python 3 and try again.
    exit /b 1
)

:: Check pip installation
echo Checking pip installation...
where pip >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo pip not found. Attempting to install pip...
    python -m ensurepip --upgrade
    if %ERRORLEVEL% neq 0 (
        echo Error: Failed to install pip.
        exit /b 1
    )
)

:: Ask if user wants to use a virtual environment
set /p USE_VENV="Do you want to install in a virtual environment? (y/n): "
if /i "%USE_VENV%"=="y" (
    echo Creating virtual environment...
    python -m venv venv
    
    echo Activating virtual environment...
    call venv\Scripts\activate.bat
    
    echo Upgrading pip in virtual environment...
    python -m pip install --upgrade pip
)

:: Install Agent-Balu
echo Installing Agent-Balu and dependencies...

if /i "%USE_VENV%"=="y" (
    :: In virtual environment, don't use --user flag
    python -m pip install -e .
) else (
    :: Outside virtual environment, use --user flag
    python -m pip install -e . --user
)

if %ERRORLEVEL% neq 0 (
    echo Error: Installation failed.
    exit /b 1
) else (
    echo Agent-Balu installed successfully!
)

:: Configure environment variables
echo Configuring environment variables...

:: Check if API key is already set
if "%AI_API_KEY%"=="" (
    echo AI_API_KEY environment variable is not set.
    set /p SET_API_KEY="Would you like to set it now? (y/n): "
    
    if /i "!SET_API_KEY!"=="y" (
        set /p API_KEY="Enter your AI API key: "
        setx AI_API_KEY "!API_KEY!"
        echo Added AI_API_KEY to user environment variables.
    )
) else (
    echo AI_API_KEY is already set.
)

:: Check if API URL is already set
if "%AI_API_URL%"=="" (
    echo AI_API_URL environment variable is not set.
    set /p SET_API_URL="Would you like to set it now? (y/n): "
    
    if /i "!SET_API_URL!"=="y" (
        set /p API_URL="Enter your AI API URL: "
        setx AI_API_URL "!API_URL!"
        echo Added AI_API_URL to user environment variables.
    )
) else (
    echo AI_API_URL is already set.
)

:: Display usage information
echo.
echo Agent-Balu has been installed. Here's how to use it:
echo Generate commit message: ai-commit --commit
echo Review code: ai-commit --review
echo Email management: ai-commit --email
echo Voice interaction: ai-commit --voice
echo Use local model: ai-commit --commit --local llama2
echo.
echo For more information, run: ai-commit --help
echo.
echo Installation complete!

:: Remind about PATH
echo Note: Make sure Python's Scripts directory is in your PATH.
echo If ai-commit command is not recognized, you may need to add it manually.

endlocal
