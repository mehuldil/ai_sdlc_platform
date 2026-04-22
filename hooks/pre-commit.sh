#!/bin/bash

################################################################################
# Pre-Commit Hook
# Standard pre-commit validation: secrets, formatting, stage documentation
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}[Pre-Commit Hook]${NC} Validating staged changes..."

# ============================================================================
# 1. Check for secrets in staged files
# ============================================================================
echo -e "${BLUE}Step 1:${NC} Scanning for secrets in staged files..."

SECRETS_FOUND=0

# Get list of staged files
STAGED_FILES=$(git diff --cached --name-only 2>/dev/null || echo "")

if [ -z "$STAGED_FILES" ]; then
    echo -e "${YELLOW}→${NC} No staged files found"
else
    # Patterns to detect potential secrets
    SECRET_PATTERNS=(
        "aws_access_key_id"
        "aws_secret_access_key"
        "AKIA[0-9A-Z]\{16\}"
        "password\s*=\s*['\"]"
        "api_key\s*=\s*['\"]"
        "bearer\s*[A-Za-z0-9._-]\{20,\}"
        # PEM blocks; pattern must not be passed as grep flags — use -- below. Leading dashes OK with --.
        "BEGIN .*(PRIVATE|PUBLIC) KEY"
        "private_key\s*=\s*['\"]"
        "token\s*=\s*['\"]"
    )

    for file in $STAGED_FILES; do
        # Skip certain file types and hook scripts (they embed pattern names as data)
        if [[ $file == *.lock ]] || [[ $file == *.log ]] || [[ $file == *.bin ]] || [[ $file == hooks/* ]]; then
            continue
        fi

        for pattern in "${SECRET_PATTERNS[@]}"; do
            # -- ends option parsing so patterns starting with - are not interpreted as flags (Windows grep)
            if git show ":$file" 2>/dev/null | grep -i -E -- "$pattern" > /dev/null; then
                echo -e "${RED}⚠ SECRET DETECTED${NC} in $file (pattern: $pattern)"
                SECRETS_FOUND=$((SECRETS_FOUND + 1))
            fi
        done
    done

    if [ $SECRETS_FOUND -gt 0 ]; then
        echo -e "${RED}ERROR:${NC} Found $SECRETS_FOUND potential secrets in staged files"
        echo -e "${RED}Please remove secrets before committing${NC}"
        exit 1
    else
        echo -e "${GREEN}✓${NC} No secrets detected in staged files"
    fi
fi

# ============================================================================
# 2. Code formatting validation
# ============================================================================
echo -e "${BLUE}Step 2:${NC} Checking code formatting..."

FORMATTING_ISSUES=0

# Check for markdown formatting issues
MARKDOWN_FILES=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null | grep "\.md$" || echo "")

if [ ! -z "$MARKDOWN_FILES" ]; then
    for file in $MARKDOWN_FILES; do
        # Basic markdown checks: trailing spaces, tabs
        if git show ":$file" 2>/dev/null | grep -E "[[:space:]]$" > /dev/null; then
            echo -e "${YELLOW}⚠ Trailing whitespace${NC} in $file"
            FORMATTING_ISSUES=$((FORMATTING_ISSUES + 1))
        fi
    done
fi

# Check for JSON formatting (if applicable)
JSON_FILES=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null | grep "\.json$" || echo "")

if [ ! -z "$JSON_FILES" ]; then
    for file in $JSON_FILES; do
        if ! git show ":$file" 2>/dev/null | jq . > /dev/null 2>&1; then
            echo -e "${RED}ERROR:${NC} Invalid JSON in $file"
            FORMATTING_ISSUES=$((FORMATTING_ISSUES + 1))
        fi
    done
fi

if [ $FORMATTING_ISSUES -gt 0 ]; then
    echo -e "${YELLOW}⚠ Found $FORMATTING_ISSUES formatting issues${NC}"
    echo -e "${YELLOW}Recommendation: Fix formatting and re-stage${NC}"
else
    echo -e "${GREEN}✓${NC} Code formatting is valid"
fi

# ============================================================================
# 2b. SDLC auto-sync — module KB + semantic team JSONL (staged for commit)
# ============================================================================
if [ "${SDL_AUTO_SYNC:-1}" != "0" ]; then
    echo -e "${BLUE}Step 2b:${NC} SDLC auto-sync (module KB + semantic memory export)..."
    SYNC_SCRIPT=""
    for candidate in "${SCRIPT_DIR}/../scripts/sdlc-auto-sync.sh" \
                     "$(cd "${SCRIPT_DIR}/.." && pwd)/scripts/sdlc-auto-sync.sh"; do
        if [ -f "$candidate" ]; then
            SYNC_SCRIPT="$candidate"
            break
        fi
    done
    if [ -n "$SYNC_SCRIPT" ]; then
        bash "$SYNC_SCRIPT" pre-commit || true
    fi
fi

# ============================================================================
# 2c. User_Manual/manual.html — regenerate when ANY documentation sources are staged
# ============================================================================
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# Extended pattern: regenerate manual.html when any documentation-related files change
# Includes: User_Manual docs, platform docs, rules, skills, agents, stages, templates
STAGED_DOCS=$(git diff --cached --name-only 2>/dev/null | grep -E '^User_Manual/.*\.md$|^docs/.*\.md$|^rules/.*\.md$|^skills/.*\.md$|^agents/.*\.md$|^stages/.*\.md$|^templates/.*\.md$|^User_Manual/VERSION$|^User_Manual/build-manual-html\.mjs$|^User_Manual/manual-client\.js$' || true)

if [ -n "$STAGED_DOCS" ] && [ -f "$REPO_ROOT/User_Manual/build-manual-html.mjs" ]; then
    echo -e "${BLUE}Step 2c:${NC} Documentation changes detected. Regenerating User_Manual/manual.html..."
    
    # Show what triggered the regeneration
    echo -e "${BLUE}→${NC} Changes in:"
    echo "$STAGED_DOCS" | head -5 | sed 's/^/   /'
    [ $(echo "$STAGED_DOCS" | wc -l) -gt 5 ] && echo "   ... and $(( $(echo "$STAGED_DOCS" | wc -l) - 5 )) more"
    
    if command -v node &>/dev/null && node -v &>/dev/null; then
        (cd "$REPO_ROOT" && node User_Manual/build-manual-html.mjs) || {
            echo -e "${RED}BLOCKED:${NC} manual.html generation failed"
            exit 1
        }
        git add "$REPO_ROOT/User_Manual/manual.html" 2>/dev/null || git add User_Manual/manual.html
        echo -e "${GREEN}✓${NC} Regenerated and staged User_Manual/manual.html (v$(cat "$REPO_ROOT/User_Manual/VERSION" 2>/dev/null || echo "unknown"))"
    else
        echo -e "${RED}BLOCKED:${NC} Node.js is required to regenerate User_Manual/manual.html (install Node 18+)"
        exit 1
    fi
fi

# ============================================================================
# 3. Verify stage completion is documented
# ============================================================================
echo -e "${BLUE}Step 3:${NC} Checking stage completion documentation..."

if [ -f ".sdlc/stage" ]; then
    CURRENT_STAGE=$(cat .sdlc/stage)
    STAGE_NAME=$(echo "$CURRENT_STAGE" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
    COMPLETION_FILE=".sdlc/memory/${STAGE_NAME}-completion.md"

    if [ -f "$COMPLETION_FILE" ]; then
        echo -e "${GREEN}✓${NC} Stage completion documented: $COMPLETION_FILE"
    else
        echo -e "${YELLOW}⚠ Stage completion not yet documented${NC}"
        echo -e "${YELLOW}  Expected: $COMPLETION_FILE${NC}"
    fi
else
    echo -e "${YELLOW}→${NC} Not in SDLC project context (.sdlc/stage not found)"
fi

# ============================================================================
# 4. Summary
# ============================================================================
echo -e "${BLUE}[Pre-Commit Hook]${NC} Validation complete!"

if [ $SECRETS_FOUND -gt 0 ]; then
    echo -e "${RED}BLOCKED: Secrets detected${NC}"
    exit 1
fi

# ============================================================================
# 5. Chain doc-change-check (hard block if system files changed w/o doc update)
# ============================================================================

DOC_CHECK="${SCRIPT_DIR}/doc-change-check.sh"

if [ -f "$DOC_CHECK" ] && [ -x "$DOC_CHECK" ]; then
    echo -e "${BLUE}Step 5:${NC} Running doc-change-check..."
    if ! bash "$DOC_CHECK"; then
        echo -e "${RED}BLOCKED: Documentation change check failed${NC}"
        exit 1
    fi
elif [ -f "$DOC_CHECK" ]; then
    bash "$DOC_CHECK" || {
        echo -e "${RED}BLOCKED: Documentation change check failed${NC}"
        exit 1
    }
fi

echo -e "${GREEN}✓ Ready to commit${NC}"
exit 0
