@echo off
echo Running Build Automation...
powershell -ExecutionPolicy Bypass -File .\automation.ps1

if %ERRORLEVEL% NEQ 0 (
    echo Build failed. Aborting release.
    exit /b %ERRORLEVEL%
)

echo Starting Release via Gemini CLI...
gemini "Release the contents of the 'output' directory as a new version on GitHub. Use the current date for the version name if no tag is provided."

pause
