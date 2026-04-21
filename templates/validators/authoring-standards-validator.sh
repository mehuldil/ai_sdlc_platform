#!/bin/bash
# authoring-standards-validator.sh
# Validates story files against AUTHORING_STANDARDS.md
# Part of AI-SDLC Platform v2.0.0

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

STORY_FILE="$1"
ERRORS=0
WARNINGS=0

if [[ -z "$STORY_FILE" ]]; then
    echo "Usage: $0 <story-file.md>"
    echo ""
    echo "Validates story files against AUTHORING_STANDARDS.md"
    echo ""
    echo "Checks:"
    echo "  - Required sections present"
    echo "  - No emojis in content"
    echo "  - PRD-sourced specifics present"
    echo "  - Tables for structured content"
    echo "  - No Azure DevOps CLI sections"
    echo "  - USER_INPUT_REQUIRED for missing data"
    exit 1
fi

if [[ ! -f "$STORY_FILE" ]]; then
    echo -e "${RED}Error: File not found: $STORY_FILE${NC}"
    exit 1
fi

echo "=== AUTHORING STANDARDS VALIDATION ==="
echo "File: $STORY_FILE"
echo ""

# Determine story type
if grep -q "^#.*Master Story" "$STORY_FILE"; then
    STORY_TYPE="master"
    echo "Type: Master Story"
elif grep -q "^#.*Sprint Story" "$STORY_FILE"; then
    STORY_TYPE="sprint"
    echo "Type: Sprint Story"
elif grep -q "^#.*Tech Story" "$STORY_FILE"; then
    STORY_TYPE="tech"
    echo "Type: Tech Story"
else
    STORY_TYPE="unknown"
    echo "Type: Unknown (assuming generic)"
fi
echo ""

# Function to check section exists
check_section() {
    local section="$1"
    local pattern="$2"
    
    if grep -qE "$pattern" "$STORY_FILE"; then
        echo -e "  ${GREEN}✓${NC} $section"
        return 0
    else
        echo -e "  ${RED}✗${NC} $section (MISSING)"
        ((ERRORS++))
        return 1
    fi
}

# 1. Check for emojis
echo "1. Checking for emojis..."
EMOJI_COUNT=$(grep -oP '[\x{1F300}-\x{1F9FF}\x{2600}-\x{26FF}\x{2700}-\x{27BF}]' "$STORY_FILE" | wc -l)
if [[ $EMOJI_COUNT -gt 0 ]]; then
    echo -e "  ${RED}✗${NC} Found $EMOJI_COUNT emoji(s)"
    echo -e "  ${YELLOW}   Remove emojis per ado-html-formatting.md rule${NC}"
    ((ERRORS++))
else
    echo -e "  ${GREEN}✓${NC} No emojis found"
fi
echo ""

# 2. Check for Azure DevOps CLI sections
echo "2. Checking for Azure DevOps CLI sections..."
if grep -qE "^## Azure DevOps" "$STORY_FILE"; then
    echo -e "  ${RED}✗${NC} Found '## Azure DevOps' section (should be removed)"
    echo -e "  ${YELLOW}   Remove per AUTHORING_STANDARDS.md${NC}"
    ((ERRORS++))
else
    echo -e "  ${GREEN}✓${NC} No Azure DevOps CLI section"
fi
echo ""

# 3. Check required sections based on type
echo "3. Checking required sections..."

if [[ "$STORY_TYPE" == "master" ]]; then
    check_section "Outcome" "^##.*Outcome"
    check_section "Problem Definition" "^##.*Problem"
    check_section "JTBD" "^##.*Job To Be Done|JTBD"
    check_section "Solution Hypothesis" "^##.*Solution"
    check_section "Capabilities" "^##.*Capability"
    check_section "PRD-sourced specifics" "^##.*PRD-sourced"
    check_section "Acceptance Criteria" "^##.*Acceptance"
    check_section "Dependencies" "^##.*Dependencies"
elif [[ "$STORY_TYPE" == "sprint" ]]; then
    check_section "What We're Building" "^##.*What We're Building"
    check_section "Context" "^##.*Context"
    check_section "Scope" "^##.*Scope"
    check_section "Acceptance Criteria" "^##.*Acceptance"
    check_section "Dependencies" "^##.*Dependencies"
    check_section "Definition of Done" "^##.*Definition of Done|DoD"
fi
echo ""

# 4. Check PRD-sourced specifics content
echo "4. Checking PRD-sourced specifics..."
if grep -qE "^##.*PRD-sourced|^##.*PRD.*lift" "$STORY_FILE"; then
    HAS_NOTIFICATIONS=$(grep -cE "N[0-9]+|Notification" "$STORY_FILE" || true)
    HAS_ERRORS=$(grep -cE "E[0-9]+|Error" "$STORY_FILE" || true)
    
    if [[ $HAS_NOTIFICATIONS -gt 0 ]]; then
        echo -e "  ${GREEN}✓${NC} Notifications referenced ($HAS_NOTIFICATIONS occurrences)"
    else
        echo -e "  ${YELLOW}⚠${NC} No notification references found (N1, N2, etc.)"
        ((WARNINGS++))
    fi
    
    if [[ $HAS_ERRORS -gt 0 ]]; then
        echo -e "  ${GREEN}✓${NC} Errors referenced ($HAS_ERRORS occurrences)"
    else
        echo -e "  ${YELLOW}⚠${NC} No error references found (E1, E2, etc.)"
        ((WARNINGS++))
    fi
else
    echo -e "  ${YELLOW}⚠${NC} No PRD-sourced specifics section found"
    ((WARNINGS++))
fi
echo ""

# 5. Check for tables
echo "5. Checking for tables..."
TABLE_COUNT=$(grep -cE "^\|.*\|$" "$STORY_FILE" || true)
if [[ $TABLE_COUNT -gt 2 ]]; then
    echo -e "  ${GREEN}✓${NC} Tables found ($TABLE_COUNT lines)"
else
    echo -e "  ${YELLOW}⚠${NC} Few table lines found ($TABLE_COUNT) - should use tables for structured content"
    ((WARNINGS++))
fi
echo ""

# 6. Check for USER_INPUT_REQUIRED usage
echo "6. Checking USER_INPUT_REQUIRED usage..."
UI_COUNT=$(grep -c "USER_INPUT_REQUIRED" "$STORY_FILE" || true)
if [[ $UI_COUNT -gt 0 ]]; then
    echo -e "  ${GREEN}✓${NC} USER_INPUT_REQUIRED used ($UI_COUNT occurrences)"
    echo -e "     for missing data (per no-invention rule)"
else
    echo -e "  ${YELLOW}⚠${NC} No USER_INPUT_REQUIRED found"
    echo -e "     Verify all data is from PRD/source, not invented"
fi
echo ""

# 7. Check character count (for ADO limit)
echo "7. Checking character count (ADO limit: 32,000)..."
CHAR_COUNT=$(wc -m < "$STORY_FILE")
if [[ $CHAR_COUNT -gt 32000 ]]; then
    echo -e "  ${RED}✗${NC} Character count: $CHAR_COUNT (exceeds 32,000 limit)"
    echo -e "  ${YELLOW}   Create condensed version + attach full file${NC}"
    ((ERRORS++))
elif [[ $CHAR_COUNT -gt 25000 ]]; then
    echo -e "  ${YELLOW}⚠${NC} Character count: $CHAR_COUNT (approaching limit)"
    echo -e "     Consider creating condensed version"
    ((WARNINGS++))
else
    echo -e "  ${GREEN}✓${NC} Character count: $CHAR_COUNT (under limit)"
fi
echo ""

# 8. Check for Gherkin format in AC
echo "8. Checking Acceptance Criteria format..."
AC_GHERKIN=$(grep -cE "^\s*\*\*Given\*\*|^\s*\*\*When\*\*|^\s*\*\*Then\*\*" "$STORY_FILE" || true)
if [[ $AC_GHERKIN -gt 0 ]]; then
    echo -e "  ${GREEN}✓${NC} Gherkin format found (Given/When/Then)"
else
    echo -e "  ${YELLOW}⚠${NC} Gherkin format not detected"
    echo -e "     Use: **Given** [context], **When** [action], **Then** [result]"
fi
echo ""

# Summary
echo "=================================="
if [[ $ERRORS -eq 0 && $WARNINGS -eq 0 ]]; then
    echo -e "${GREEN}✓ VALIDATION PASSED${NC}"
    exit 0
elif [[ $ERRORS -eq 0 ]]; then
    echo -e "${YELLOW}⚠ VALIDATION PASSED WITH WARNINGS${NC}"
    echo "Warnings: $WARNINGS"
    exit 0
else
    echo -e "${RED}✗ VALIDATION FAILED${NC}"
    echo "Errors: $ERRORS"
    echo "Warnings: $WARNINGS"
    exit 1
fi
