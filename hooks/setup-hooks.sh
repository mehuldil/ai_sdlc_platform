#!/bin/bash

################################################################################
# Setup Git Hooks
#
# Configures git to use the AI-SDLC Platform hooks directory.
# Run once after cloning the repository.
#
# Usage:
#   bash hooks/setup-hooks.sh        # Setup hooks
#   bash hooks/setup-hooks.sh --check # Verify setup
################################################################################

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

function print_usage() {
    echo "Usage: bash hooks/setup-hooks.sh [--check]"
    echo ""
    echo "Options:"
    echo "  --check    Verify hooks are properly configured"
    echo ""
    echo "This script configures git to use the AI-SDLC Platform hooks."
}

function setup_hooks() {
    echo -e "${BLUE}[Setup]${NC} Configuring git hooks for AI-SDLC Platform..."
    
    cd "${REPO_ROOT}"
    
    # Configure core.hooksPath to use our hooks directory
    git config core.hooksPath hooks
    
    echo -e "${GREEN}✓${NC} Set core.hooksPath = hooks"
    
    # Verify hooks exist
    local hooks_found=0
    for hook in pre-commit pre-push post-commit; do
        if [ -f "${REPO_ROOT}/hooks/${hook}.sh" ]; then
            hooks_found=$((hooks_found + 1))
            echo -e "${GREEN}✓${NC} Found ${hook}.sh"
        else
            echo -e "${YELLOW}⚠${NC} Missing ${hook}.sh"
        fi
    done
    
    echo ""
    echo -e "${BLUE}[Setup]${NC} Hooks configured successfully!"
    echo ""
    echo "Hook execution flow:"
    echo "  pre-commit  → Before every commit (regenerates manual.html if docs change)"
    echo "  pre-push    → Before every push (verifies manual.html is current)"
    echo "  post-commit → After commit (updates registries)"
    echo ""
    echo -e "${GREEN}✓ Setup complete${NC}"
}

function check_setup() {
    echo -e "${BLUE}[Check]${NC} Verifying git hooks configuration..."
    
    cd "${REPO_ROOT}"
    
    local errors=0
    
    # Check core.hooksPath
    local hooks_path
    hooks_path=$(git config core.hooksPath 2>/dev/null || echo "")
    
    if [ "$hooks_path" = "hooks" ]; then
        echo -e "${GREEN}✓${NC} core.hooksPath = hooks"
    else
        echo -e "${RED}✗${NC} core.hooksPath not set (current: ${hooks_path:-not set})"
        errors=$((errors + 1))
    fi
    
    # Check hook files exist
    for hook in pre-commit pre-push post-commit; do
        if [ -f "${REPO_ROOT}/hooks/${hook}.sh" ]; then
            echo -e "${GREEN}✓${NC} ${hook}.sh exists"
        else
            echo -e "${RED}✗${NC} ${hook}.sh missing"
            errors=$((errors + 1))
        fi
    done
    
    # Check if hooks are executable (Unix only)
    if [[ "$OSTYPE" != "msys" && "$OSTYPE" != "win32" ]]; then
        for hook in pre-commit pre-push post-commit; do
            if [ -x "${REPO_ROOT}/hooks/${hook}.sh" ]; then
                echo -e "${GREEN}✓${NC} ${hook}.sh is executable"
            else
                echo -e "${YELLOW}⚠${NC} ${hook}.sh not executable (chmod +x hooks/${hook}.sh)"
            fi
        done
    fi
    
    echo ""
    if [ $errors -eq 0 ]; then
        echo -e "${GREEN}✓ All checks passed${NC}"
        return 0
    else
        echo -e "${RED}✗ ${errors} issue(s) found${NC}"
        echo "Run: bash hooks/setup-hooks.sh"
        return 1
    fi
}

# Main
if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
    print_usage
    exit 0
elif [ "${1:-}" = "--check" ]; then
    check_setup
    exit $?
else
    setup_hooks
    exit 0
fi
