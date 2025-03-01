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

:: Extract Python version numbers for comparison
for /f "tokens=1,2 delims=." %%a in ("%PYTHON_VERSION%") do (
    set PYTHON_MAJOR=%%a
    set PYTHON_MINOR=%%b
)

:: Check if Python version is at least 3.6
if %PYTHON_MAJOR% LSS 3 (
    echo Error: Python 3.6 or higher is required.
    echo Please upgrade Python and try again.
    exit /b 1
) else (
    if %PYTHON_MAJOR% EQU 3 (
        if %PYTHON_MINOR% LSS 6 (
            echo Error: Python 3.6 or higher is required. Found version %PYTHON_VERSION%.
            echo Please upgrade Python and try again.
            exit /b 1
        )
    )
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

:: Fix numpy dependency issues first
echo Installing/upgrading core dependencies...
python -m pip install --upgrade pip wheel setuptools
python -m pip install --upgrade numpy pandas requests argparse chardet

:: Install ollama if needed
echo Checking for ollama...
python -c "import ollama" >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo Ollama not found. Installing ollama package...
    python -m pip install --upgrade ollama
)

:: Install SpeechRecognition
echo Installing SpeechRecognition...
python -m pip install --upgrade SpeechRecognition

:: Ask if user wants voice support
set /p VOICE_SUPPORT="Do you want to install voice support? (y/n): "
set INSTALL_VOICE=false
if /i "%VOICE_SUPPORT%"=="y" (
    set INSTALL_VOICE=true
    echo.
    echo Note: Voice support on Windows requires PyAudio.
    echo If installation fails, you may need to install PyAudio manually.
    echo Visit: https://www.lfd.uci.edu/~gohlke/pythonlibs/#pyaudio
    echo Download the appropriate .whl file for your Python version and run:
    echo python -m pip install [path-to-downloaded-whl-file]
    echo.
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
    
    :: Reinstall core dependencies in venv
    echo Installing core dependencies in virtual environment...
    python -m pip install --upgrade wheel setuptools
    python -m pip install --upgrade numpy pandas requests argparse chardet ollama SpeechRecognition
)

:: Install Agent-Balu
echo Installing Agent-Balu and dependencies...

if /i "%USE_VENV%"=="y" (
    :: In virtual environment, don't use --user flag
    if /i "%INSTALL_VOICE%"=="true" (
        echo Installing Agent-Balu with voice support...
        python -m pip install -e ".[voice]"
    ) else (
        echo Installing Agent-Balu without voice support...
        python -m pip install -e .
    )
) else (
    :: Outside virtual environment, use --user flag
    if /i "%INSTALL_VOICE%"=="true" (
        echo Installing Agent-Balu with voice support...
        python -m pip install -e ".[voice]" --user
    ) else (
        echo Installing Agent-Balu without voice support...
        python -m pip install -e . --user
    )
)

if %ERRORLEVEL% neq 0 (
    echo Error: Installation failed.
    exit /b 1
) else (
    echo Agent-Balu installed successfully!
)

:: Configure environment variables
echo Configuring environment variables...

:: Handle API URL configuration
if "%AI_API_URL%"=="" (
    echo AI_API_URL environment variable is not set.
    echo This is required for Agent-Balu to function properly.
) else (
    echo Found existing AI_API_URL: %AI_API_URL%
    echo You can keep this value or enter a new one.
)

:: Always prompt for API URL
set /p API_URL="Enter your AI API URL [%AI_API_URL%]: "

:: Use existing value if input is empty
if "!API_URL!"=="" (
    if not "%AI_API_URL%"=="" (
        set API_URL=%AI_API_URL%
        echo Keeping existing API URL.
    ) else (
        :: Loop until we get a non-empty value
        :api_url_loop
        echo Error: API URL cannot be empty. Please try again:
        set /p API_URL="Enter your AI API URL: "
        if "!API_URL!"=="" goto api_url_loop
    )
)

:: Set the environment variable
setx AI_API_URL "!API_URL!"
echo API URL set to: !API_URL!

:: Handle API Key configuration
if "%AI_API_KEY%"=="" (
    echo AI_API_KEY environment variable is not set.
    echo This is required for Agent-Balu to function properly.
) else (
    echo Found existing AI_API_KEY: [First 5 chars: %AI_API_KEY:~0,5%...%AI_API_KEY:~-5%]
    echo You can keep this value or enter a new one.
)

:: Always prompt for API Key
set /p API_KEY="Enter your AI API key [keep existing]: "

:: Use existing value if input is empty
if "!API_KEY!"=="" (
    if not "%AI_API_KEY%"=="" (
        set API_KEY=%AI_API_KEY%
        echo Keeping existing API key.
    ) else (
        :: Loop until we get a non-empty value
        :api_key_loop
        echo Error: API key cannot be empty. Please try again:
        set /p API_KEY="Enter your AI API key: "
        if "!API_KEY!"=="" goto api_key_loop
    )
)

:: Set the environment variable
setx AI_API_KEY "!API_KEY!"
echo API key set!

:: Display usage information
echo.
echo Agent-Balu has been installed. Here's how to use it:
echo Generate commit message: ai-commit --commit
echo Review code: ai-commit --review
echo Email management: ai-commit --email
if /i "%INSTALL_VOICE%"=="true" (
    echo Voice interaction: ai-commit --voice
)
echo Use local model: ai-commit --commit --local llama2
echo.
echo For more information, run: ai-commit --help
echo.
echo Installation complete!

:: Verify installation
echo Verifying installation...
where ai-commit >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo ai-commit command is available!
) else (
    echo ai-commit command not found in current PATH.
    echo You may need to restart your command prompt for the changes to take effect.
    echo If the command is still not recognized, you may need to add Python's Scripts directory to your PATH.
    
    :: Try to find the command
    for /f "tokens=*" %%i in ('where /r %USERPROFILE% ai-commit.exe 2^>nul') do (
        echo Found ai-commit at: %%i
        echo You can run it directly with: "%%i" --help
        goto found_command
    )
    
    :: If we get here, we didn't find the command
    echo Could not find ai-commit.exe in your user profile.
    
    :found_command
)

endlocal
