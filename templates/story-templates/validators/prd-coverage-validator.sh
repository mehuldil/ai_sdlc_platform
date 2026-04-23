#!/usr/bin/env bash
# PRD Coverage Validator
# Checks that Master Stories cover all PRD requirements (Notifications, Rules, Scenarios, Dependencies, Errors)
# Prevents the gaps found in ADO-865620 feedback

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

validate_prd_coverage() {
  local story_file=$1
  local prd_file=${2:-}  # Optional: path to PRD for comparison

  if [[ ! -f "$story_file" ]]; then
    echo -e "${RED}✗ Story file not found: $story_file${NC}"
    return 1
  fi

  local warnings=0
  local passes=0
  local critical=0

  echo "PRD Coverage Validation: $story_file"
  echo "================================================"
  echo ""

  # Clean up Windows line endings
  local _tmp="${TMPDIR:-/tmp}/coverage-val-$$.md"
  tr -d '\r' < "$story_file" > "$_tmp" 2>/dev/null || true
  if [[ -s "$_tmp" ]]; then story_file="$_tmp"; trap 'rm -f "$_tmp"' RETURN; fi

  # ============================================
  # CHECK 1: PRD Coverage Matrix Section Present
  # ============================================
  echo -e "${BLUE}1. PRD Coverage Matrix Section${NC}"
  echo "-------------------------------------------"
  
  if grep -q "PRD Coverage Matrix" "$story_file" || grep -q "Coverage %" "$story_file"; then
    echo -e "${GREEN}✓${NC} PRD Coverage Matrix section present"
    passes=$((passes + 1))
  else
    echo -e "${YELLOW}⚠${NC} Missing PRD Coverage Matrix section"
    echo "   Add the coverage table from PRD_COVERAGE_CHECKLIST.md"
    warnings=$((warnings + 1))
  fi
  echo ""

  # ============================================
  # CHECK 2: Notification Coverage (N# patterns)
  # ============================================
  echo -e "${BLUE}2. Notification Coverage (N# patterns)${NC}"
  echo "-------------------------------------------"
  
  local notification_ids=$(grep -oE '\bN[0-9]+\b' "$story_file" | sort -u | wc -l)
  local notification_table_rows=$(grep -c "N[0-9].*|.*|.*|" "$story_file" 2>/dev/null || echo 0)
  
  echo "   Found $notification_ids unique N# references"
  echo "   Found ~$notification_table_rows notification table rows"
  
  # Check for common omissions
  if ! grep -q "N4\|N5" "$story_file"; then
    echo -e "${YELLOW}⚠${NC} N4/N5 (Decline/Expiry notifications) not found"
    echo "   Common gap: These have NO push, only status update"
    warnings=$((warnings + 1))
  else
    echo -e "${GREEN}✓${NC} N4/N5 referenced"
    passes=$((passes + 1))
  fi
  
  if ! grep -q "N14" "$story_file"; then
    echo -e "${YELLOW}⚠${NC} N14 (Owner account deletion push) not found"
    warnings=$((warnings + 1))
  else
    echo -e "${GREEN}✓${NC} N14 referenced"
    passes=$((passes + 1))
  fi
  
  # Check for timing requirements on removal notifications
  if grep -q "N7.*N8\|N8.*N7" "$story_file"; then
    if grep -qi "60.*second\|within.*60\|60s" "$story_file"; then
      echo -e "${GREEN}✓${NC} N7+N8 timing requirement (within 60s) found"
      passes=$((passes + 1))
    else
      echo -e "${YELLOW}⚠${NC} N7+N8 present but timing requirement (within 60s) not found"
      warnings=$((warnings + 1))
    fi
  fi
  echo ""

  # ============================================
  # CHECK 3: Rules Coverage (R# patterns)
  # ============================================
  echo -e "${BLUE}3. Rules Coverage (R# patterns)${NC}"
  echo "-------------------------------------------"
  
  local rule_patterns=("R2" "R3" "R5" "R6" "R15")
  local rule_names=("Delete before new" "X out of 5 display" "Declined hidden" "Resend behavior" "Owner storage visibility")
  
  for i in "${!rule_patterns[@]}"; do
    if grep -q "${rule_patterns[$i]}" "$story_file"; then
      echo -e "${GREEN}✓${NC} ${rule_patterns[$i]} (${rule_names[$i]}) referenced"
      passes=$((passes + 1))
    else
      echo -e "${YELLOW}⚠${NC} ${rule_patterns[$i]} (${rule_names[$i]}) not found"
      echo "   Common gap from ADO-865620 feedback"
      warnings=$((warnings + 1))
    fi
  done
  echo ""

  # ============================================
  # CHECK 4: Scenario Coverage (S# patterns)
  # ============================================
  echo -e "${BLUE}4. Scenario Coverage (S# patterns)${NC}"
  echo "-------------------------------------------"
  
  local scenario_patterns=("S6" "S7" "S8")
  local scenario_names=("Degraded state" "Over-quota leave" "Storage consumption order")
  
  for i in "${!scenario_patterns[@]}"; do
    if grep -q "${scenario_patterns[$i]}" "$story_file"; then
      echo -e "${GREEN}✓${NC} ${scenario_patterns[$i]} (${scenario_names[$i]}) referenced"
      passes=$((passes + 1))
    else
      echo -e "${YELLOW}⚠${NC} ${scenario_patterns[$i]} (${scenario_names[$i]}) not found"
      echo "   Common gap from ADO-865620 feedback"
      warnings=$((warnings + 1))
    fi
  done
  echo ""

  # ============================================
  # CHECK 5: Dependency Coverage (D# patterns)
  # ============================================
  echo -e "${BLUE}5. Dependency Coverage (D# patterns)${NC}"
  echo "-------------------------------------------"
  
  if grep -q "D6\|D7" "$story_file"; then
    echo -e "${GREEN}✓${NC} D6/D7 API dependencies referenced"
    passes=$((passes + 1))
  else
    echo -e "${YELLOW}⚠${NC} D6/D7 API dependencies not explicitly found"
    warnings=$((warnings + 1))
  fi
  echo ""

  # ============================================
  # CHECK 6: Common Contradiction Patterns
  # ============================================
  echo -e "${BLUE}6. Contradiction Checks${NC}"
  echo "-------------------------------------------"
  
  # Check for "Create Family Hub" flow contradiction
  if grep -qi "taps.*Create.*Family.*Hub\|confirms.*creation" "$story_file"; then
    if ! grep -qi "auto.*created\|background.*created\|no separate.*Create" "$story_file"; then
      echo -e "${RED}✗ CRITICAL:${NC} May have Create Family Hub flow contradiction"
      echo "   PRD says hub created automatically on first invite"
      echo "   Story describes separate Create step"
      critical=$((critical + 1))
    else
      echo -e "${GREEN}✓${NC} Auto-creation flow correctly documented"
      passes=$((passes + 1))
    fi
  fi
  
  # Check for member count contradiction
  if grep -qi "including.*owner\|includes.*owner" "$story_file"; then
    if grep -qi "max.*5.*member" "$story_file"; then
      echo -e "${YELLOW}⚠${NC} Verify: "including owner" + "max 5" = 5 total"
      echo "   PRD may say 5 excluding owner = 6 total"
      echo "   Check PRD R3 wording exactly"
      warnings=$((warnings + 1))
    fi
  fi
  
  # Check for leave dialog copy
  if grep -qi "personal library is unaffected" "$story_file"; then
    if grep -A2 -B2 "personal library" "$story_file" | grep -qi "Leave Family Hub"; then
      echo -e "${YELLOW}⚠${NC} Leave dialog may have extra text"
      echo "   PRD dialog copy: 'Leave Family Hub?' only"
      echo "   Extra text may be scenario description, not dialog copy"
      warnings=$((warnings + 1))
    fi
  fi
  echo ""

  # ============================================
  # CHECK 7: Entry Points Coverage
  # ============================================
  echo -e "${BLUE}7. Entry Points Coverage${NC}"
  echo "-------------------------------------------"
  
  local entry_points=0
  if grep -qi "See All" "$story_file"; then
    entry_points=$((entry_points + 1))
    echo -e "${GREEN}✓${NC} 'See All' entry path documented"
  fi
  if grep -qi "+ icon\|plus icon" "$story_file"; then
    entry_points=$((entry_points + 1))
    echo -e "${GREEN}✓${NC} '+' icon entry path documented"
  fi
  
  if [[ $entry_points -eq 0 ]]; then
    echo -e "${YELLOW}⚠${NC} No entry points explicitly documented"
    warnings=$((warnings + 1))
  fi
  echo ""

  # ============================================
  # CHECK 8: Redirection Behaviors
  # ============================================
  echo -e "${BLUE}8. Redirection Behaviors${NC}"
  echo "-------------------------------------------"
  
  if grep -qi "redirect.*after.*removal\|redirected.*removed" "$story_file"; then
    echo -e "${GREEN}✓${NC} Post-removal redirection documented"
    passes=$((passes + 1))
  else
    echo -e "${YELLOW}⚠${NC} Post-removal redirection not documented"
    warnings=$((warnings + 1))
  fi
  
  if grep -qi "redirect.*after.*leave\|redirected.*leave" "$story_file"; then
    echo -e "${GREEN}✓${NC} Post-leave redirection documented"
    passes=$((passes + 1))
  else
    echo -e "${YELLOW}⚠${NC} Post-leave redirection not documented"
    warnings=$((warnings + 1))
  fi
  echo ""

  # ============================================
  # SUMMARY
  # ============================================
  echo "================================================"
  echo -e "Validation Results: ${GREEN}$passes passed${NC}, ${YELLOW}$warnings warnings${NC}, ${RED}$critical critical${NC}"
  echo ""
  
  if [[ $critical -gt 0 ]]; then
    echo -e "${RED}CRITICAL ISSUES FOUND${NC}"
    echo "Fix contradictions before ADO push."
    echo "See PRD_COVERAGE_CHECKLIST.md for guidance."
    return 1
  fi
  
  if [[ $warnings -gt 0 ]]; then
    echo -e "${YELLOW}WARNINGS FOUND${NC}"
    echo "Review gaps above. Some may be intentional (mark N/A in PRD)."
    echo "For ADO-865620-type issues, fix before push."
    return 0  # Non-blocking
  fi
  
  echo -e "${GREEN}✓ All PRD coverage checks passed${NC}"
  return 0
}

# Run if called directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  story_file=${1:-}
  prd_file=${2:-}

  if [[ -z "$story_file" ]]; then
    echo "Usage: $0 <story-file.md> [optional-prd-file.docx/.md]"
    echo ""
    echo "Validates Master Story has covered all PRD requirements"
    echo "Prevents ADO-865620-type gaps (missing N4/N5, R2/R3/R5/R6/R15, S6/S7/S8, etc.)"
    exit 1
  fi

  validate_prd_coverage "$story_file" "$prd_file"
fi
