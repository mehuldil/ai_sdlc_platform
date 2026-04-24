#!/usr/bin/env bash
# ============================================================================
# AI SDLC Story Management Commands - Simplified
# Version: 1.0.0
# ============================================================================

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLATFORM_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'
BLUE='\033[0;34m'

log_success() { echo -e "${GREEN}✓${NC} $@"; }
log_error() { echo -e "${RED}✗${NC} $@" >&2; }
log_warn() { echo -e "${YELLOW}⚠${NC} $@" >&2; }
log_info() { echo "[INFO] $@"; }
log_section() { echo ""; echo "=== $@ ==="; echo ""; }

# ============================================================================
# DESIGN-FIRST VALIDATION
# ============================================================================

# Check if system design stage is complete
check_design_complete() {
  local sdlc_dir="${SDLCDIR:-./.sdlc}"
  local complete_marker="${sdlc_dir}/stages/05-system-design/complete"
  
  if [[ -f "$complete_marker" ]]; then
    return 0
  else
    return 1
  fi
}

# Check if module is initialized
check_module_initialized() {
  local sdlc_dir="${SDLCDIR:-./.sdlc}"
  local manifest="${sdlc_dir}/module/manifest.yaml"
  
  if [[ -f "$manifest" ]]; then
    return 0
  else
    return 1
  fi
}

# Check if API contracts exist
check_api_contracts_exist() {
  local sdlc_dir="${SDLCDIR:-./.sdlc}"
  local api_contract="${sdlc_dir}/module/contracts/api.yaml"
  
  if [[ -f "$api_contract" ]] && [[ -s "$api_contract" ]]; then
    return 0
  else
    return 1
  fi
}

# Validate design prerequisites for implementation stories
validate_design_prerequisites() {
  local story_type="$1"
  local bypass_flag="${2:-false}"
  
  # Only enforce for tech and task stories (implementation stories)
  if [[ "$story_type" != "tech" && "$story_type" != "task" ]]; then
    return 0
  fi
  
  # Allow bypass with flag
  if [[ "$bypass_flag" == "true" ]]; then
    log_warn "Design validation bypassed (--skip-design-check flag used)"
    return 0
  fi
  
  local sdlc_dir="${SDLCDIR:-./.sdlc}"
  local missing_prereqs=()
  
  echo ""
  echo -e "${BLUE}🔍 Checking design-first prerequisites...${NC}"
  echo ""
  
  # Check 1: Module initialized
  if ! check_module_initialized; then
    missing_prereqs+=("Module not initialized: Run 'sdlc module init .'")
    echo -e "${RED}✗${NC} Module not initialized"
    echo "   Path checked: ${sdlc_dir}/module/manifest.yaml"
  else
    echo -e "${GREEN}✓${NC} Module initialized"
  fi
  
  # Check 2: System design complete
  if ! check_design_complete; then
    missing_prereqs+=("System design incomplete: Run 'sdlc stage run 05-system-design'")
    echo -e "${RED}✗${NC} System design not marked complete"
    echo "   Path checked: ${sdlc_dir}/stages/05-system-design/complete"
  else
    echo -e "${GREEN}✓${NC} System design complete"
  fi
  
  # Check 3: API contracts exist
  if ! check_api_contracts_exist; then
    missing_prereqs+=("API contracts missing: Define contracts in ${sdlc_dir}/module/contracts/api.yaml")
    echo -e "${RED}✗${NC} API contracts not found or empty"
    echo "   Path checked: ${sdlc_dir}/module/contracts/api.yaml"
  else
    echo -e "${GREEN}✓${NC} API contracts defined"
  fi
  
  # If any prerequisites missing, block creation
  if [[ ${#missing_prereqs[@]} -gt 0 ]]; then
    echo ""
    echo -e "${RED}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${RED}  DESIGN-FIRST WORKFLOW ENFORCEMENT${NC}"
    echo -e "${RED}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "Cannot create $story_type story until the following are complete:"
    echo ""
    for prereq in "${missing_prereqs[@]}"; do
      echo "  ${YELLOW}•${NC} $prereq"
    done
    echo ""
    echo -e "${YELLOW}Design-first workflow requires:${NC}"
    echo "  1. Module initialization with 'sdlc module init .'"
    echo "  2. System design completion (stage 05)"
    echo "  3. API contracts defined in .sdlc/module/contracts/api.yaml"
    echo ""
    echo -e "${YELLOW}To bypass this check (not recommended):${NC}"
    echo "  sdlc story create $story_type --skip-design-check"
    echo ""
    return 1
  fi
  
  echo ""
  log_success "All design prerequisites satisfied"
  echo ""
  return 0
}

# ============================================================================
# STORY COMMANDS
# ============================================================================

cmd_story_create() {
  local story_type="${1:-}"
  local output_dir="."
  local skip_design_check="false"

  if [[ -z "$story_type" ]]; then
    log_error "Usage: sdlc story create <type>"
    echo "Types: master, sprint, tech, task"
    return 1
  fi

  # Parse options
  while [[ $# -gt 1 ]]; do
    case "$2" in
      --output=*) output_dir="${2#*=}" ;;
      --parent=*) parent_id="${2#*=}" ;;
      --sprint=*) sprint_name="${2#*=}" ;;
      --skip-design-check) skip_design_check="true" ;;
      *) shift ;;
    esac
    shift
  done

  # Validate design prerequisites for implementation stories
  if ! validate_design_prerequisites "$story_type" "$skip_design_check"; then
    return 1
  fi

  mkdir -p "$output_dir"

  case "$story_type" in
    master)
      # Copy template
      cp "${PLATFORM_DIR}/templates/story-templates/master-story-template.md" \
         "$output_dir/MS-$(date +%s)-batch-upload.md"
      log_success "Master story created: $output_dir/MS-*.md"
      ;;
    sprint)
      cp "${PLATFORM_DIR}/templates/story-templates/sprint-story-template.md" \
         "$output_dir/SS-$(date +%s)-story.md"
      log_success "Sprint story created: $output_dir/SS-*.md"
      ;;
    tech)
      cp "${PLATFORM_DIR}/templates/story-templates/tech-story-template.md" \
         "$output_dir/TS-$(date +%s)-story.md"
      log_success "Tech story created: $output_dir/TS-*.md"
      ;;
    task)
      cp "${PLATFORM_DIR}/templates/story-templates/task-template.md" \
         "$output_dir/T-$(date +%s)-story.md"
      log_success "Task created: $output_dir/T-*.md"
      ;;
    *)
      log_error "Unknown story type: $story_type"
      return 1
      ;;
  esac

  log_info "Edit: nano $output_dir/*.md"
  log_info "Validate: sdlc story validate $output_dir/*.md"
}

cmd_story_list() {
  local story_type="${1:-all}"
  log_section "Stories"

  case "$story_type" in
    master)
      find . -name "MS-*.md" -type f 2>/dev/null | sort || echo "  (none)"
      ;;
    sprint)
      find . -name "SS-*.md" -type f 2>/dev/null | sort || echo "  (none)"
      ;;
    tech)
      find . -name "TS-*.md" -type f 2>/dev/null | sort || echo "  (none)"
      ;;
    task)
      find . -name "T-*.md" -type f 2>/dev/null | sort || echo "  (none)"
      ;;
    all)
      echo "Master Stories:"
      find . -name "MS-*.md" -type f 2>/dev/null | sort | sed 's/^/  /' || echo "  (none)"
      echo "Sprint Stories:"
      find . -name "SS-*.md" -type f 2>/dev/null | sort | sed 's/^/  /' || echo "  (none)"
      echo "Tech Stories:"
      find . -name "TS-*.md" -type f 2>/dev/null | sort | sed 's/^/  /' || echo "  (none)"
      echo "Tasks:"
      find . -name "T-*.md" -type f 2>/dev/null | sort | sed 's/^/  /' || echo "  (none)"
      ;;
  esac
}

cmd_story_validate() {
  local post_comment=""
  local story_file=""
  local ado_id=""
  local tmp_from_ado=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --post-ado-comment=*)
        post_comment="${1#--post-ado-comment=}"
        shift
        ;;
      --ado-id=*)
        ado_id="${1#--ado-id=}"
        shift
        ;;
      *)
        if [[ -z "$story_file" && -z "$ado_id" ]]; then
          if [[ -f "$1" ]]; then
            story_file="$1"
          elif [[ "$1" =~ ^[0-9]+$ ]] || [[ "$1" =~ ^#?[0-9]+$ ]] || [[ "$1" =~ ^(US|AB|us|ab)-[0-9]+$ ]] || [[ "$1" =~ ^AB#[0-9]+$ ]]; then
            ado_id="$1"
          else
            story_file="$1"
          fi
        fi
        shift
        ;;
    esac
  done

  if [[ -n "$ado_id" ]]; then
    local CLI_LIB="${PLATFORM_DIR}/cli/lib"
    # shellcheck source=/dev/null
    source "${CLI_LIB}/logging.sh"
    # shellcheck source=/dev/null
    source "${CLI_LIB}/config.sh"
    # shellcheck source=/dev/null
    source "${CLI_LIB}/ado.sh"
    _load_env
    if [[ -z "${ADO_PAT:-}" || -z "${ADO_ORG:-}" || -z "${ADO_PROJECT:-}" ]]; then
      log_error "ADO not configured (need ADO_PAT, ADO_ORG, ADO_PROJECT) to validate by work item id"
      return 1
    fi
    ado_id="$(_normalize_ado_wi_id "$ado_id")"
    if [[ ! "$ado_id" =~ ^[0-9]+$ ]]; then
      log_error "Invalid ADO work item id: $ado_id"
      return 1
    fi
    if ! command -v node &>/dev/null; then
      log_error "Node.js is required to convert ADO HTML description for validation"
      return 1
    fi
    local url response title desc_html
    url="https://dev.azure.com/${ADO_ORG}/${ADO_PROJECT}/_apis/wit/workitems/${ado_id}?api-version=7.0"
    log_info "Fetching work item $ado_id from ADO for validation..."
    response=$(_ado_curl -u ":${ADO_PAT}" "$url") || true
    if [[ -z "$response" ]] || ! echo "$response" | grep -q '"id"'; then
      log_error "Could not load work item $ado_id from ADO"
      return 1
    fi
    title=$(_ado_json_field "$response" "System.Title")
    desc_html=$(_ado_json_field "$response" "System.Description")
    if [[ -z "$desc_html" ]]; then
      log_error "Work item $ado_id has no System.Description to validate"
      return 1
    fi
    tmp_from_ado=$(mktemp "${TMPDIR:-/tmp}/sdlc-story-ado-XXXXXX.md")
    trap "rm -f '${tmp_from_ado}'" EXIT
    {
      echo "# ${title}"
      echo ""
      printf '%s' "$desc_html" | node "${CLI_LIB}/ado-html-to-validator-md.js"
    } > "$tmp_from_ado"
    story_file="$tmp_from_ado"
    log_info "Using ADO #$ado_id description as temporary markdown for validators"
  fi

  if [[ -z "$story_file" ]]; then
    log_error "Usage: sdlc story validate <file.md> | <adoWorkItemId> [--ado-id=<id>] [--post-ado-comment=<workItemId>]"
    return 1
  fi

  if [[ ! -f "$story_file" ]]; then
    log_error "File not found: $story_file"
    return 1
  fi

  # Auto-detect type (order matters: tech before sprint — sprint titles can mention "Sprint Story")
  local story_type=""
  local base
  base="$(basename "$story_file")"
  if grep -q "🧠 Master Story" "$story_file"; then
    story_type="master"
  elif grep -qE '^# .*Tech Story|🏗️ Tech Story' "$story_file"; then
    story_type="tech"
  elif grep -q "Parent Master Story:" "$story_file"; then
    story_type="sprint"
  elif grep -qE '^# ✅ Task —|^# .*Task —' "$story_file" || [[ "$base" =~ ^[Tt]-[0-9]+- ]]; then
    story_type="task"
  elif grep -q "Sprint Story:" "$story_file"; then
    story_type="task"
  fi

  log_info "Story type: $story_type"

  local validator=""
  if [[ "$story_type" == "task" ]]; then
    validator="${PLATFORM_DIR}/templates/story-templates/validators/task-validator.sh"
  else
    validator="${PLATFORM_DIR}/templates/story-templates/validators/${story_type}-story-validator.sh"
  fi
  if [[ ! -f "$validator" ]]; then
    log_error "Validator not found: $validator"
    return 1
  fi

  local out
  out=$(bash "$validator" "$story_file" 2>&1) || true
  echo "$out"

  if [[ -n "$post_comment" ]]; then
    local summary sdlc_cli="$PLATFORM_DIR/cli/sdlc.sh"
    summary=$(printf '%s' "$out" | sed 's/\x1b\[[0-9;]*m//g' | head -c 10000)
    if [[ -f "$sdlc_cli" ]]; then
      if bash "$sdlc_cli" ado comment "$post_comment" "$(printf '%s\n\n%s' "[SDLC] Story validation: $(basename "$story_file")" "$summary")" 2>/dev/null; then
        log_success "Posted validation summary to ADO #$post_comment"
      else
        log_warn "Could not post validation comment to ADO #$post_comment (check ADO_PAT / Discussion permissions)"
      fi
    else
      log_warn "sdlc CLI not found; skipping ADO comment"
    fi
  fi
}

cmd_story_push() {
  local f="${1:-}"
  shift || true
  if [[ -z "$f" ]]; then
    log_error "Usage: sdlc story push <file.md> [--parent=<adoWorkItemId>] [--type=story|feature|epic]"
    echo ""
    echo "Creates an Azure DevOps work item from a filled story markdown file."
    echo "Equivalent to: sdlc ado push-story <file.md> [--parent=...] [--type=...] (prints numeric work item id on success)."
    echo ""
    echo "  --type=story   User Story (default) — recommended for both master and sprint stories"
    echo "  --type=feature ADO Feature — only for large epics requiring portfolio tracking"
    echo "  --type=epic    ADO Epic — for strategic initiatives spanning multiple releases"
    echo ""
    echo "Recommendation: Use --type=story (default) for all stories including master stories."
    echo "Master stories are User Stories with detailed acceptance criteria, not Features."
    echo ""
    echo "Typical flow (same as chat + confirm):"
    echo "  1. sdlc story create master|sprint|tech|task --output=./stories/"
    echo "  2. Fill the file (or use Cursor/Claude with story-generator skill from PRD)"
    echo "  3. sdlc story validate <file.md>"
    echo "  4. After you confirm in chat, run: sdlc story push <file.md> [--parent=<id>]"
    return 1
  fi
  if [[ ! -f "$f" ]]; then
    log_error "File not found: $f"
    return 1
  fi
  local SDL="${PLATFORM_DIR}/cli/sdlc.sh"
  if [[ ! -f "$SDL" ]]; then
    log_error "sdlc CLI not found: $SDL"
    return 1
  fi
  exec bash "$SDL" ado push-story "$f" "$@"
}

cmd_story_help() {
  cat << 'HELP'
sdlc story <command> [options]

Commands:
  create <type>   Create new story file from template (master|sprint|tech|task)
                  Note: tech and task stories require design completion (see --skip-design-check)
  list [type]     List stories (master|sprint|tech|task|all)
  validate <file.md>|<adoId> [--ado-id=<id>] [--post-ado-comment=<id>]  Validate file or fetch WI description from ADO then validate
  push <file.md> [--parent=<id>]  Push story to ADO; optional --parent links as child of that work item
  show <file>     Show story contents

Create Options:
  --output=<dir>         Output directory for story file
  --parent=<id>          Parent story ID
  --sprint=<name>        Sprint name
  --skip-design-check    Bypass design-first validation (tech/task stories only; not recommended)

Design-First Workflow:
  Tech and task stories require:
    1. Module initialized: sdlc module init .
    2. System design complete: sdlc stage run 05-system-design
    3. API contracts defined: .sdlc/module/contracts/api.yaml

End-to-end (CLI + chat):
  • Create tier files with create, or let the IDE fill templates from PRD.
  • When the user confirms in chat, run:  sdlc story push <file.md>
  • Same API as:  sdlc ado push-story <file.md>

Examples:
  sdlc story create master --output=./stories/
  sdlc story create sprint --output=./stories/
  sdlc story create tech --output=./stories/   (requires design completion)
  sdlc story create task --output=./stories/ (requires design completion)
  sdlc story validate ./stories/MS-123.md
  sdlc story validate 864890
  sdlc story validate ./stories/SS-foo.md --post-ado-comment=863480
  sdlc story push ./stories/MS-123.md --type=feature
  sdlc story push ./stories/SS-family-hub-01.md --parent=863476
  sdlc story list all
HELP
}

# ============================================================================
# MAIN
# ============================================================================

cmd="${1:-help}"
shift || true

case "$cmd" in
  create)
    cmd_story_create "$@"
    ;;
  list)
    cmd_story_list "$@"
    ;;
  validate)
    cmd_story_validate "$@"
    ;;
  push)
    cmd_story_push "$@"
    ;;
  show)
    [[ -f "$1" ]] && cat "$1" || log_error "File not found: $1"
    ;;
  help|--help|-h|"")
    cmd_story_help
    ;;
  *)
    log_error "Unknown command: $cmd"
    cmd_story_help
    exit 1
    ;;
esac
