@echo off
REM Windows batch script to configure git hooks for AI-SDLC Platform
REM Run this after cloning the repository

echo [Setup] Configuring git hooks for AI-SDLC Platform...

cd /d "%~dp0"
git config core.hooksPath hooks

if %ERRORLEVEL% neq 0 (
    echo ERROR: Failed to set core.hooksPath
    exit /b 1
)

echo [OK] Set core.hooksPath = hooks
echo.
echo Hook execution flow:
echo   pre-commit  - Before every commit (regenerates manual.html if docs change)
echo   pre-push    - Before every push (verifies manual.html is current)
echo   post-commit - After commit (updates registries)
echo.
echo [OK] Setup complete
