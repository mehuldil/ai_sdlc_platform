#!/bin/bash

################################################################################
# Pre-Push Hook: Documentation Consistency Check
#
# Safety net to ensure manual.html is current before pushing to remote.
# This catches any documentation drift that may have occurred outside of
# the normal pre-commit workflow (e.g., direct file edits, merges, etc.)
#
# Install: ln -s ../../hooks/pre-push.sh .git/hooks/pre-push
# Or: git config core.hooksPath hooks
################################################################################

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}[Pre-Push]${NC} Checking documentation consistency..."

# Get repository root
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "${REPO_ROOT}"

ERROR_COUNT=0

# ============================================================================
# Check 1: Verify manual.html exists
# ============================================================================
if [ ! -f "${REPO_ROOT}/User_Manual/manual.html" ]; then
    echo -e "${RED}✗${NC} User_Manual/manual.html not found"
    ERROR_COUNT=$((ERROR_COUNT + 1))
else
    echo -e "${GREEN}✓${NC} User_Manual/manual.html exists"
fi

# ============================================================================
# Check 2: Verify manual.html is not older than source documentation
# ============================================================================
if [ -f "${REPO_ROOT}/User_Manual/manual.html" ]; then
    MANUAL_HTML_MTIME=$(stat -c %Y "${REPO_ROOT}/User_Manual/manual.html" 2>/dev/null || stat -f %m "${REPO_ROOT}/User_Manual/manual.html" 2>/dev/null || echo "0")
    
    # Find all source documentation files that should be in manual.html
    SOURCE_FILES=$(find "${REPO_ROOT}/User_Manual" -name "*.md" -type f 2>/dev/null)
    SOURCE_FILES="${SOURCE_FILES} $(find "${REPO_ROOT}/docs" -name "*.md" -type f 2>/dev/null || true)"
    
    OUTDATED_SOURCES=""
    OUTDATED_COUNT=0
    
    for src_file in ${SOURCE_FILES}; do
        if [ -f "$src_file" ]; then
            src_mtime=$(stat -c %Y "$src_file" 2>/dev/null || stat -f %m "$src_file" 2>/dev/null || echo "0")
            if [ "$src_mtime" -gt "$MANUAL_HTML_MTIME" ]; then
                rel_path="${src_file#$REPO_ROOT/}"
                OUTDATED_SOURCES="${OUTDATED_SOURCES}${rel_path}\n"
                OUTDATED_COUNT=$((OUTDATED_COUNT + 1))
            fi
        fi
    done
    
    if [ $OUTDATED_COUNT -gt 0 ]; then
        echo -e "${YELLOW}⚠${NC} User_Manual/manual.html may be outdated"
        echo -e "${YELLOW}→${NC} Source files newer than manual.html:"
        echo -e "${OUTDATED_SOURCES}" | head -5 | sed 's/^/   /'
        [ $OUTDATED_COUNT -gt 5 ] && echo "   ... and $((OUTDATED_COUNT - 5)) more"
        
        # Try to auto-regenerate
        echo ""
        echo -e "${BLUE}→${NC} Attempting auto-regeneration..."
        
        if command -v node &>/dev/null && node -v &>/dev/null; then
            if (cd "${REPO_ROOT}" && node User_Manual/build-manual-html.mjs) 2>/dev/null; then
                git add "${REPO_ROOT}/User_Manual/manual.html" 2>/dev/null || true
                
                # Check if we can amend the last commit
                if git diff --cached --quiet 2>/dev/null; then
                    # manual.html wasn't staged yet, try to stage it
                    git add "${REPO_ROOT}/User_Manual/manual.html"
                    echo -e "${GREEN}✓${NC} Regenerated and staged updated manual.html"
                    echo -e "${YELLOW}⚠${NC} You need to commit the updated manual.html before pushing"
                    ERROR_COUNT=$((ERROR_COUNT + 1))
                else
                    echo -e "${GREEN}✓${NC} Regenerated and staged updated manual.html"
                fi
            else
                echo -e "${RED}✗${NC} Auto-regeneration failed"
                ERROR_COUNT=$((ERROR_COUNT + 1))
            fi
        else
            echo -e "${RED}✗${NC} Node.js not available for auto-regeneration"
            ERROR_COUNT=$((ERROR_COUNT + 1))
        fi
    else
        echo -e "${GREEN}✓${NC} User_Manual/manual.html is up-to-date"
    fi
fi

# ============================================================================
# Check 3: Verify manual.html contains expected documents (basic sanity check)
# ============================================================================
if [ -f "${REPO_ROOT}/User_Manual/manual.html" ]; then
    # Check for key documents in the generated HTML
    MISSING_DOCS=""
    
    for doc in "README.md" "INDEX.md" "CHANGELOG.md"; do
        if ! grep -q "\"file\":\"${doc}\"" "${REPO_ROOT}/User_Manual/manual.html" 2>/dev/null; then
            MISSING_DOCS="${MISSING_DOCS} ${doc}"
        fi
    done
    
    # Check for sdlc-stage-role-mapping if it exists as source
    if [ -f "${REPO_ROOT}/docs/sdlc-stage-role-mapping.md" ]; then
        if ! grep -q "sdlc-stage-role-mapping" "${REPO_ROOT}/User_Manual/manual.html" 2>/dev/null; then
            MISSING_DOCS="${MISSING_DOCS} sdlc-stage-role-mapping.md"
        fi
    fi
    
    if [ -n "${MISSING_DOCS}" ]; then
        echo -e "${YELLOW}⚠${NC} Potential missing documents in manual.html:${MISSING_DOCS}"
        # This is a warning, not a hard block
    fi
fi

# ============================================================================
# Summary & Decision
# ============================================================================
echo ""
echo -e "${BLUE}[Pre-Push]${NC} Summary:"

if [ $ERROR_COUNT -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Documentation consistency verified"
    echo -e "${GREEN}✓ Ready to push${NC}"
    exit 0
else
    echo -e "${RED}✗${NC} ${ERROR_COUNT} documentation issue(s) found"
    echo ""
    echo -e "${RED}PUSH BLOCKED${NC}"
    echo ""
    echo "To fix:"
    echo "  1. Run: node User_Manual/build-manual-html.mjs"
    echo "  2. Stage: git add User_Manual/manual.html"
    echo "  3. Commit: git commit -m \"Update manual.html\""
    echo "  4. Push again: git push"
    echo ""
    echo "To bypass (not recommended): git push --no-verify"
    exit 1
fi
