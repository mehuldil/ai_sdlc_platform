#!/usr/bin/env bash
# ============================================================================
# AI SDLC Platform — CLI Entrypoint
# Version: 2.0.0
# ============================================================================
#
# Thin entrypoint that sources modular libraries from cli/lib/ and dispatches
# commands. Each module is self-contained and independently testable.
#
# Modules:
#   lib/logging.sh  — Colors, icons, log_info/warn/error/success/section
#   lib/config.sh   — Constants, validators, config I/O, symlinks, init
#   lib/guards.sh   — Context guard, TTY detection, chat-first ASK
#   lib/executor.sh — Stage run, workflows, agents, skills, templates, gates, tokens
#   lib/ado.sh      — Azure DevOps API (CRUD, links, push-story)
#
# ============================================================================

set -eo pipefail

# Resolve real directory of this script (follows symlinks)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLATFORM_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
export PLATFORM_DIR

# ============================================================================
# Source modules
# ============================================================================

# shellcheck source=lib/logging.sh
source "${SCRIPT_DIR}/lib/logging.sh"

# shellcheck source=lib/config.sh
source "${SCRIPT_DIR}/lib/config.sh"

# shellcheck source=lib/guards.sh
source "${SCRIPT_DIR}/lib/guards.sh"

# shellcheck source=lib/executor.sh
source "${SCRIPT_DIR}/lib/executor.sh"

# shellcheck source=lib/ado.sh
source "${SCRIPT_DIR}/lib/ado.sh"

# shellcheck source=lib/setup.sh
source "${SCRIPT_DIR}/lib/setup.sh"

# shellcheck source=lib/repos.sh
source "${SCRIPT_DIR}/lib/repos.sh"

# Full app-repo bootstrap (symlinks, hooks): cli/sdlc-setup.sh [project-path]

# ============================================================================
# Initialize subsystems
# ============================================================================

_init_systems

# ============================================================================
# Help & Version
# ============================================================================

cmd_help() {
  cat <<'HELP'
AI SDLC Platform CLI v2.0.0

Usage: sdlc <command> [options]

Context:
  use <role> [--stack=<stack>]   Set active role (and optional stack)
  context                        Show current role, stack, stage, project
  init                           Initialize SDLC workspace in current directory
  setup [--from-env] [--ide=…]   One-shot env + .sdlc + IDE links (see setup --help)

Execution:
  run <stage> [--story=<id>]     Run a stage with current role context
  flow <workflow|list>           Run or list workflows
  route <task-description>       Classify task type and recommend routing (see IDE for full routing)
  gate-check <stage> [--ado-id=] Advisory gate check for a stage

Catalog:
  agent {list|show|invoke}       Browse and invoke agents
  skills {list|show|invoke}      Browse and invoke skills
  template {list|validate|generate}  Manage story/task templates
  story {create|validate|push|…}  4-tier story files; push → ADO work item id

Memory:
  memory init                    Initialize memory for story on branch
  memory list-branches           List all branches working on story
  memory prepare-merge           Prepare merge with validation
  memory sync                    Sync memory across repositories
  memory status                  Show memory status for story
  memory semantic-status         Show unified semantic memory stats
  memory semantic-upsert ...     Upsert semantic memory entry
  memory semantic-query --text=  Query ranked semantic memory
  memory semantic-lifecycle      Apply memory lifecycle governance
  memory semantic-export         Export team JSONL (also runs on pre-commit via hooks)
  memory semantic-import         Import team JSONL into local DB (also runs after pull)
  sync                           Sync .sdlc/memory to git
  publish                        Push memory to remote
  memory show                    Show memory contents (default)

Testing:
  skip-tests --reason="…" (≥10 chars) --work-item=<id> [--master-story=path]   Marker + ADO discussion (mandatory WI)
  show-test-skips                Show test skip history
  clear-test-skips [branch]      Clear skip marker for a branch

Repositories (Multi-Repo):
  repos add [path]               Register current or specified repository
  repos list                     List all registered repositories
  repos switch <repo-id>         Switch context to another repository
  repos detect                   Auto-detect repositories in common directories
  repos depend <a> <b>           Set repo A depends on repo B
  repos deps                     Show dependency graph between repositories
  repos check [repo-id]          Check impact on dependent repositories
  repos notify <repo-id>         Notify dependents of changes

Azure DevOps:
  ado create <type> --title="…" [--yes]  Create work item (non-TTY: --yes or SDLC_ADO_CONFIRM=yes)
  ado list [--type=…] [--state=…]  List work items
  ado show <id>                  Show work item details (full)
  ado search <query> [--top N]   Search work items by text/state/type/assignee
  ado get <id>                   Get work item summary (formatted)
  ado update <id> --state=… [--assigned-to=email]  Update state and/or assignee
  ado link <id> --parent=<id>    Link child to parent
  ado description <id> --file=…  Set description from file
  ado push-story <file.md> [--type=story|feature|epic] [--yes]  Create WI from markdown (default: User Story)
  ado sync <id>                  Two-way sync with ADO (fetch + push)
  ado sync-from <id>             Fetch work item state from ADO
  ado sync-to <id>               Push local state to ADO
  qa <subcommand>                Control QA orchestrator API (start/status/approve/kb/archive/health)

Budget:
  tokens                         Show token budget report
  cost <stage>                   Show token cost for a stage

Other:
  rpi <phase> <story-id>         RPI workflow (research|plan|implement|verify|status)
  doctor [--verbose]             Environment, validators, docs drift + generated registries
  version                        Show version
  help                           Show this help

Setup (Cursor / Claude Code / terminal):
  sdlc setup                     Interactive (terminal) or uses env / env/.env in agent chat
  sdlc setup --from-env          Non-interactive: require ADO_* in ~/.sdlc/ado.env, env/.env, or environment
  sdlc setup --ide=auto          Detect Cursor vs Claude (default)
  sdlc setup --ide=both          Symlink rules/commands for Cursor and Claude
  sdlc setup --ide=cursor|claude-code
HELP
}

cmd_version() {
  echo "AI SDLC Platform CLI v${SDLC_VERSION}"
}

# ============================================================================
# Token cost model per stage
# ============================================================================

cmd_cost() {
  local stage="${1:-}"
  if [[ -z "$stage" ]]; then
    log_section "Token Cost Model — All Stages"
    echo "Stage                    Budget (tokens)"
    echo "───────────────────────  ───────────────"
    echo "01-requirement-intake           2 000"
    echo "02-prd-review                   3 000"
    echo "03-pre-grooming                 3 000"
    echo "04-grooming                     4 000"
    echo "05-system-design                8 000"
    echo "06-design-review                3 000"
    echo "07-task-breakdown               3 000"
    echo "08-implementation               6 000"
    echo "09-code-review                  5 000"
    echo "10-test-design                  6 000"
    echo "11-test-execution               4 000"
    echo "12-commit-push                  2 000"
    echo "13-documentation                2 000"
    echo "14-release-signoff              2 000"
    echo "15-summary-close                2 000"
    echo ""
    echo "Budgets sourced from scripts/token-blocker.sh STAGE_BUDGET."
    return 0
  fi

  local stage_num="${stage%%-*}"
  if command -v check_token_limit &>/dev/null 2>&1; then
    local budget="${STAGE_BUDGET[$stage_num]:-}"
  else
    local budget=""
  fi

  load_config
  local role="${SDLC_ROLE:-product}"

  log_section "Token Cost: $stage"
  log_info "Stage number: $stage_num"
  log_info "Role:         $role"

  if [[ -n "$budget" ]]; then
    log_info "Stage budget: $budget tokens"
  else
    log_warn "Stage budget not found (expected key '$stage_num' in STAGE_BUDGET)"
  fi

  local state_file="${SDLC_PROJECT_DIR:-.}/.sdlc/state.json"
  if [[ -f "$state_file" ]] && command -v jq &>/dev/null; then
    local spent
    spent=$(jq --arg s "$stage_num" --arg r "$role" \
      '[.token_spent // {} | to_entries[] | select(.key | startswith($s + ":" + $r)) | .value] | add // 0' \
      "$state_file" 2>/dev/null || echo "0")
    log_info "Spent so far: $spent tokens"
    if [[ -n "$budget" && "$budget" -gt 0 ]]; then
      log_info "Remaining:    $(( budget - spent )) tokens"
    fi
  else
    log_info "No spend data available (no .sdlc/state.json or jq missing)"
  fi
}

cmd_doctor() {
  local verbose=0
  local arg
  for arg in "$@"; do
    case "$arg" in
      --verbose|-v) verbose=1 ;;
    esac
  done

  _doctor_run() {
    local script="$1"
    shift
    if [[ "$verbose" -eq 1 ]]; then
      bash "$script" "$@"
    else
      bash "$script" "$@" >/dev/null 2>&1
    fi
  }

  # Scripts that must run with platform root as cwd (relative paths to agents/, .claude/, etc.)
  _doctor_run_repo() {
    local rel="$1"
    shift
    if [[ ! -f "${PLATFORM_DIR}/${rel}" ]]; then
      return 127
    fi
    if [[ "$verbose" -eq 1 ]]; then
      (cd "$PLATFORM_DIR" && bash "$rel" "$@")
    else
      (cd "$PLATFORM_DIR" && bash "$rel" "$@" >/dev/null 2>&1)
    fi
  }

  log_section "SDLC Doctor — Comprehensive System Health Check"

  if [[ "$verbose" -eq 1 ]]; then
    log_info "Verbose mode: validator scripts print full output"
  fi

  # Initialize report
  local pass_count=0
  local warn_count=0
  local fail_count=0

  # ========================================================================
  # ENVIRONMENT CHECK
  # ========================================================================

  log_section "1. Environment & Dependencies"

  # Check bash version
  log_info "Bash: ${BASH_VERSION}"

  # Check required tools (setup.sh hard-requires Node 18+ and npm)
  local tools=(curl jq git node npm npx)
  for tool in "${tools[@]}"; do
    if command -v "$tool" &>/dev/null; then
      log_success "$tool"
      pass_count=$((pass_count + 1))
    else
      log_warn "$tool: not found (some features may be limited)"
      warn_count=$((warn_count + 1))
    fi
  done

  # Python 3 — semantic memory CLI, distributed memory JSON tooling
  local py_cmd="" py_arg="" candidate=""
  for candidate in python3 python; do
    if command -v "$candidate" &>/dev/null && "$candidate" -V >/dev/null 2>&1; then
      py_cmd="$candidate"
      break
    fi
  done
  if [[ -z "$py_cmd" ]] && command -v py &>/dev/null && py -3 -V >/dev/null 2>&1; then
    py_cmd="py"
    py_arg="-3"
  fi

  _run_py() {
    if [[ -n "$py_arg" ]]; then
      "$py_cmd" "$py_arg" "$@"
    else
      "$py_cmd" "$@"
    fi
  }

  if [[ -n "$py_cmd" ]]; then
    local py_ver
    py_ver="$(_run_py -V 2>&1 | head -1)"
    log_success "Python: $py_ver"
    pass_count=$((pass_count + 1))
    local sem_script="${PLATFORM_DIR}/scripts/semantic-memory.py"
    if [[ -f "$sem_script" ]]; then
      if _run_py "$sem_script" status >/dev/null 2>&1; then
        log_success "Unified semantic memory CLI: OK"
        pass_count=$((pass_count + 1))
      else
        log_warn "Unified semantic memory CLI: status check failed (see scripts/semantic-memory.py)"
        warn_count=$((warn_count + 1))
      fi
    fi
  else
    log_warn "Python 3 not found — install for semantic memory (python3, python, or py -3 on Windows)"
    warn_count=$((warn_count + 1))
  fi

  # Optional: local QA orchestrator stack
  if command -v docker &>/dev/null; then
    log_success "docker (optional: orchestrator/qa/docker-compose.yml)"
    pass_count=$((pass_count + 1))
  else
    log_info "docker: not installed (optional — use for orchestrator/qa/docker-compose.yml)"
  fi

  # Check platform directory
  if [[ -d "$PLATFORM_DIR" ]]; then
    log_success "Platform dir: $PLATFORM_DIR"
    pass_count=$((pass_count + 1))
  else
    log_error "Platform dir not found: $PLATFORM_DIR"
    fail_count=$((fail_count + 1))
  fi

  # ========================================================================
  # CONFIGURATION CHECK
  # ========================================================================

  log_section "2. Configuration"

  # Check config
  load_config
  if [[ -n "$SDLC_ROLE" ]]; then
    log_success "Role: $SDLC_ROLE"
    pass_count=$((pass_count + 1))
  else
    log_warn "Role: not set (run 'sdlc use <role>')"
    warn_count=$((warn_count + 1))
  fi

  # Check ADO credentials
  _load_env
  if [[ -n "${ADO_PAT:-}" && -n "${ADO_ORG:-}" ]]; then
    log_success "ADO credentials: configured"
    pass_count=$((pass_count + 1))
  else
    log_warn "ADO credentials: not configured (set in env/.env)"
    warn_count=$((warn_count + 1))
  fi

  # ========================================================================
  # RULE VALIDATION
  # ========================================================================

  log_section "3. Rule Validation (validate-rules.sh)"

  if [[ -f "${PLATFORM_DIR}/scripts/validate-rules.sh" ]]; then
    if _doctor_run "${PLATFORM_DIR}/scripts/validate-rules.sh" "$PLATFORM_DIR"; then
      log_success "Rule bypass detection PASSED"
      pass_count=$((pass_count + 1))
    else
      log_warn "Rule validation found issues (run: sdlc doctor --verbose for details)"
      warn_count=$((warn_count + 1))
    fi
  else
    log_warn "validate-rules.sh not found"
    warn_count=$((warn_count + 1))
  fi

  # ========================================================================
  # COMMAND CONSISTENCY
  # ========================================================================

  log_section "4. Command Consistency (validate-commands.sh)"

  if [[ -f "${PLATFORM_DIR}/scripts/validate-commands.sh" ]]; then
    if _doctor_run "${PLATFORM_DIR}/scripts/validate-commands.sh" "$PLATFORM_DIR"; then
      log_success "Command consistency check PASSED"
      pass_count=$((pass_count + 1))
    else
      log_warn "Command consistency check found issues (run: sdlc doctor --verbose for details)"
      warn_count=$((warn_count + 1))
    fi
  else
    log_warn "validate-commands.sh not found"
    warn_count=$((warn_count + 1))
  fi

  # ========================================================================
  # DOCUMENTATION DRIFT
  # ========================================================================

  log_section "5. Documentation (drift + generated registries)"

  if [[ -f "${PLATFORM_DIR}/scripts/detect-doc-drift.sh" ]]; then
    if _doctor_run "${PLATFORM_DIR}/scripts/detect-doc-drift.sh" "$PLATFORM_DIR"; then
      log_success "Doc drift: README/COMMANDS/ROLES/QUICKSTART align with repo"
      pass_count=$((pass_count + 1))
    else
      log_warn "Documentation drift — run: bash scripts/detect-doc-drift.sh \"$PLATFORM_DIR\" --verbose"
      warn_count=$((warn_count + 1))
    fi
  else
    log_warn "detect-doc-drift.sh not found"
    warn_count=$((warn_count + 1))
  fi

  if [[ -f "${PLATFORM_DIR}/scripts/regenerate-registries.sh" ]]; then
    if _doctor_run_repo "scripts/regenerate-registries.sh" --check; then
      log_success "Generated registries current (agents/skills/commands vs CAPABILITY_MATRIX, SKILL, COMMANDS_REGISTRY)"
      pass_count=$((pass_count + 1))
    else
      log_warn "Registries need update — run: bash scripts/regenerate-registries.sh --update (from platform root)"
      warn_count=$((warn_count + 1))
    fi
  else
    log_warn "regenerate-registries.sh not found"
    warn_count=$((warn_count + 1))
  fi

  # ========================================================================
  # MEMORY FRESHNESS
  # ========================================================================

  log_section "6. Memory Freshness (memory-freshness.sh)"

  if [[ -f "${PLATFORM_DIR}/scripts/memory-freshness.sh" ]]; then
    if _doctor_run "${PLATFORM_DIR}/scripts/memory-freshness.sh" --check; then
      log_success "Memory freshness check PASSED"
      pass_count=$((pass_count + 1))
    else
      log_warn "Memory freshness check found stale files (run: sdlc memory sync)"
      warn_count=$((warn_count + 1))
    fi
  else
    log_warn "memory-freshness.sh not found"
    warn_count=$((warn_count + 1))
  fi

  # ========================================================================
  # SYMLINK VALIDATION
  # ========================================================================

  log_section "7. Symlink Integrity"

  local broken_symlinks=0
  while IFS= read -r symlink; do
    if [[ ! -L "$symlink" ]]; then
      continue
    fi
    target=$(readlink "$symlink")
    if [[ ! -e "$symlink" ]]; then
      broken_symlinks=$((broken_symlinks + 1))
      log_warn "Broken symlink: $symlink → $target"
    fi
  done < <(find "$PLATFORM_DIR" -type l 2>/dev/null || true)

  if [[ $broken_symlinks -eq 0 ]]; then
    log_success "No broken symlinks"
    pass_count=$((pass_count + 1))
  else
    log_warn "Found $broken_symlinks broken symlinks (run 'sdlc setup' to recreate)"
    warn_count=$((warn_count + 1))
  fi

  # ========================================================================
  # TOKEN BUDGET STATUS
  # ========================================================================

  log_section "8. Token Budget Status"

  if [[ -f "${PLATFORM_DIR}/.sdlc/state.json" ]]; then
    # Try to extract token spend if jq is available
    if command -v jq &>/dev/null; then
      total_spent=$(jq '.token_spent // 0' "${PLATFORM_DIR}/.sdlc/state.json" 2>/dev/null || echo "0")
      log_info "Total tokens spent: $total_spent"
      pass_count=$((pass_count + 1))
    else
      log_info "Token tracking available (jq required for detailed view)"
    fi
  else
    log_warn "No token state file found (.sdlc/state.json)"
    warn_count=$((warn_count + 1))
  fi

  # ========================================================================
  # ADO CONNECTIVITY TEST
  # ========================================================================

  log_section "9. Azure DevOps Connectivity"

  if [[ -n "${ADO_PAT:-}" && -n "${ADO_ORG:-}" ]]; then
    # Try a simple ADO API call
    if command -v curl &>/dev/null; then
      ado_test=$(curl -s -w "%{http_code}" \
        -H "Authorization: Basic $(echo -n ":${ADO_PAT}" | base64)" \
        "https://dev.azure.com/${ADO_ORG}/_apis/projects?api-version=7.0" \
        -o /dev/null 2>/dev/null || echo "000")

      if [[ "$ado_test" == "200" ]]; then
        log_success "ADO connectivity: OK (HTTP 200)"
        pass_count=$((pass_count + 1))
      else
        log_warn "ADO connectivity: HTTP $ado_test (check credentials or network)"
        warn_count=$((warn_count + 1))
      fi
    else
      log_warn "curl not available for ADO connectivity test"
      warn_count=$((warn_count + 1))
    fi
  else
    log_info "ADO credentials not configured (skipped connectivity test)"
  fi

  # ========================================================================
  # MODULES & FEATURES
  # ========================================================================

  log_section "10. Modules & Features"

  log_info "Loaded modules: logging, config, guards, executor, ado, setup"

  # Check for critical directories
  critical_dirs=(".claude" "scripts" "cli" ".sdlc")
  for dir in "${critical_dirs[@]}"; do
    if [[ -d "$PLATFORM_DIR/$dir" ]]; then
      log_success "Directory: $dir"
      pass_count=$((pass_count + 1))
    else
      log_warn "Directory missing: $dir"
      warn_count=$((warn_count + 1))
    fi
  done

  # ========================================================================
  # GIT HOOKS (post-clone / setup)
  # ========================================================================

  log_section "11. Git Hooks"

  local hook_root
  hook_root="$(pwd)"
  if [[ -f "${PLATFORM_DIR}/scripts/verify-git-hooks.sh" ]]; then
    local hooks_ok=1
    if [[ "$verbose" -eq 1 ]]; then
      bash "${PLATFORM_DIR}/scripts/verify-git-hooks.sh" "$hook_root" || hooks_ok=0
    else
      bash "${PLATFORM_DIR}/scripts/verify-git-hooks.sh" "$hook_root" 2>/dev/null || hooks_ok=0
    fi
    if [[ "$hooks_ok" -eq 1 ]]; then
      log_success "Git hooks: installed and verified"
      pass_count=$((pass_count + 1))
    else
      log_warn "Git hooks: missing — run ./setup.sh (platform clone) or sdlc setup (app repo)"
      warn_count=$((warn_count + 1))
    fi
  else
    log_warn "verify-git-hooks.sh not found under platform"
    warn_count=$((warn_count + 1))
  fi

  # ========================================================================
  # SYSTEM INTEGRITY (agents, skills, workflows, symlinks)
  # ========================================================================

  log_section "12. System Integrity"

  if [[ -f "${PLATFORM_DIR}/scripts/validate-system-integrity.sh" ]]; then
    if _doctor_run_repo "scripts/validate-system-integrity.sh" "$PLATFORM_DIR"; then
      log_success "System integrity: agents, skills, workflow-stage deps, symlinks"
      pass_count=$((pass_count + 1))
    else
      log_warn "System integrity issues (run: bash scripts/validate-system-integrity.sh \"$PLATFORM_DIR\")"
      warn_count=$((warn_count + 1))
    fi
  else
    log_warn "validate-system-integrity.sh not found"
    warn_count=$((warn_count + 1))
  fi

  # ========================================================================
  # TRACEABILITY (E2E report)
  # ========================================================================

  log_section "13. Traceability"

  if [[ -f "${PLATFORM_DIR}/scripts/trace-e2e-report.sh" ]]; then
    if _doctor_run "${PLATFORM_DIR}/scripts/trace-e2e-report.sh" "."; then
      log_success "End-to-end traceability: templates have PRD/parent fields"
      pass_count=$((pass_count + 1))
    else
      log_warn "Traceability gaps found (run: bash scripts/trace-e2e-report.sh)"
      warn_count=$((warn_count + 1))
    fi
  else
    log_info "trace-e2e-report.sh not found (optional)"
  fi

  # ========================================================================
  # CI PIPELINE (in-repo definitions)
  # ========================================================================

  log_section "14. CI Pipeline"

  if [[ -f "${PLATFORM_DIR}/scripts/ci-sdlc-platform.sh" ]]; then
    log_success "ci-sdlc-platform.sh: present (run: bash scripts/ci-sdlc-platform.sh)"
    pass_count=$((pass_count + 1))
  else
    log_warn "ci-sdlc-platform.sh missing"
    warn_count=$((warn_count + 1))
  fi

  if [[ -f "${PLATFORM_DIR}/.github/workflows/sdlc-ci.yml" ]]; then
    log_success "GitHub Actions: .github/workflows/sdlc-ci.yml"
    pass_count=$((pass_count + 1))
  else
    log_info "GitHub Actions workflow not found (optional if using Azure DevOps only)"
  fi

  if [[ -f "${PLATFORM_DIR}/azure-pipelines.yml" ]]; then
    log_success "Azure Pipelines: azure-pipelines.yml"
    pass_count=$((pass_count + 1))
  else
    log_info "azure-pipelines.yml not found (optional if using GitHub only)"
  fi

  # ========================================================================
  # FINAL REPORT
  # ========================================================================

  echo ""
  log_section "Health Report Summary"

  echo "PASS:  $pass_count ✓"
  echo "WARN:  $warn_count ⚠"
  echo "FAIL:  $fail_count ✗"
  echo ""

  local total=$((pass_count + warn_count + fail_count))
  [[ "$total" -lt 1 ]] && total=1
  local health_percent=$((pass_count * 100 / total))

  if [[ $fail_count -eq 0 && $warn_count -eq 0 ]]; then
    log_success "System Health: EXCELLENT ($health_percent%)"
    echo ""
    echo "Your SDLC platform is in great shape!"
    return 0
  elif [[ $fail_count -eq 0 ]]; then
    log_warn "System Health: GOOD ($health_percent%)"
    echo ""
    echo "Minor warnings detected. Review above for details."
    return 0
  else
    log_error "System Health: NEEDS ATTENTION ($health_percent%)"
    echo ""
    echo "Critical issues found. Review above for details."
    echo ""
    echo "Next steps:"
    echo "  • Run validators with --verbose flag for details"
    echo "  • Check .sdlc/logs/ for detailed error logs"
    echo "  • Read TROUBLESHOOT.md for common issues"
    return 1
  fi
}

# ============================================================================
# Distributed Memory Commands — Multi-branch, multi-repo support
# ============================================================================

cmd_memory() {
  local subcommand="${1:-show}"
  local verify_fresh=0
  local py_cmd=""
  local py_arg=""
  shift 2>/dev/null || true

  # Extract --verify-fresh flag if present
  for arg in "$@"; do
    case "$arg" in
      --verify-fresh) verify_fresh=1 ;;
    esac
  done

  # Check if distributed memory script exists
  local memory_script="${SCRIPT_DIR}/commands/memory-distributed.sh"
  local semantic_script="${PLATFORM_DIR}/scripts/semantic-memory.py"
  local candidate=""
  for candidate in python3 python; do
    if command -v "$candidate" &>/dev/null && "$candidate" -V >/dev/null 2>&1; then
      py_cmd="$candidate"
      break
    fi
  done
  if [[ -z "$py_cmd" ]] && command -v py &>/dev/null && py -3 -V >/dev/null 2>&1; then
    py_cmd="py"
    py_arg="-3"
  fi

  _run_python() {
    if [[ -n "$py_arg" ]]; then
      "$py_cmd" "$py_arg" "$@"
    else
      "$py_cmd" "$@"
    fi
  }

  case "$subcommand" in
    init|list-branches|prepare-merge|sync|status)
      # Route to distributed memory system
      if [[ ! -f "$memory_script" ]]; then
        log_error "Distributed memory script not found: $memory_script"
        return 1
      fi
      bash "$memory_script" "$subcommand" "$@"
      ;;
    show)
      # Freshness check before loading (R5)
      if [[ $verify_fresh -eq 1 ]]; then
        local freshness_script="${PLATFORM_DIR}/scripts/memory-freshness.sh"
        if [[ -f "$freshness_script" ]]; then
          if ! bash "$freshness_script" --verify-fresh 2>&1; then
            log_error "Memory freshness check failed. Use 'sdlc memory sync' to refresh."
            return 1
          fi
        fi
      fi
      # Fall back to existing memory show command
      cmd_memory_show "$@"
      ;;
    semantic-status)
      if [[ ! -f "$semantic_script" ]]; then
        log_error "Semantic memory script not found: $semantic_script"
        return 1
      fi
      if [[ -z "$py_cmd" ]]; then
        log_error "Python runtime not found (python3/python/py -3). Cannot run semantic memory commands."
        return 1
      fi
      _run_python "$semantic_script" status
      ;;
    semantic-upsert)
      if [[ ! -f "$semantic_script" ]]; then
        log_error "Semantic memory script not found: $semantic_script"
        return 1
      fi
      if [[ -z "$py_cmd" ]]; then
        log_error "Python runtime not found (python3/python/py -3). Cannot run semantic memory commands."
        return 1
      fi
      _run_python "$semantic_script" upsert "$@"
      ;;
    semantic-query)
      if [[ ! -f "$semantic_script" ]]; then
        log_error "Semantic memory script not found: $semantic_script"
        return 1
      fi
      if [[ -z "$py_cmd" ]]; then
        log_error "Python runtime not found (python3/python/py -3). Cannot run semantic memory commands."
        return 1
      fi
      local text=""
      local extra=()
      for arg in "$@"; do
        case "$arg" in
          --text=*) text="${arg#--text=}" ;;
          *) extra+=("$arg") ;;
        esac
      done
      if [[ -z "$text" ]]; then
        log_error "Usage: sdlc memory semantic-query --text=\"query\" [--orchestrator=qa] [--namespace=...] [--limit=N]"
        return 1
      fi
      _run_python "$semantic_script" query --text "$text" "${extra[@]}"
      ;;
    semantic-lifecycle)
      if [[ ! -f "$semantic_script" ]]; then
        log_error "Semantic memory script not found: $semantic_script"
        return 1
      fi
      if [[ -z "$py_cmd" ]]; then
        log_error "Python runtime not found (python3/python/py -3). Cannot run semantic memory commands."
        return 1
      fi
      _run_python "$semantic_script" lifecycle "$@"
      ;;
    semantic-export)
      if [[ ! -f "$semantic_script" ]]; then
        log_error "Semantic memory script not found: $semantic_script"
        return 1
      fi
      if [[ -z "$py_cmd" ]]; then
        log_error "Python runtime not found (python3/python/py -3). Cannot run semantic memory commands."
        return 1
      fi
      _run_python "$semantic_script" export "$@"
      ;;
    semantic-import)
      if [[ ! -f "$semantic_script" ]]; then
        log_error "Semantic memory script not found: $semantic_script"
        return 1
      fi
      if [[ -z "$py_cmd" ]]; then
        log_error "Python runtime not found (python3/python/py -3). Cannot run semantic memory commands."
        return 1
      fi
      _run_python "$semantic_script" import "$@"
      ;;
    doctor)
      # Clean up deprecated `.sdlc/module-kb/` and sanity-check layout
      bash "${SCRIPT_DIR}/commands/remember.sh" doctor "$@"
      ;;
    *)
      log_error "Unknown memory command: $subcommand"
      echo ""
      echo "Memory Commands:"
      echo "  sdlc memory init              Initialize memory for story on branch"
      echo "  sdlc memory list-branches     List all branches working on story"
      echo "  sdlc memory prepare-merge     Prepare merge with validation"
      echo "  sdlc memory sync              Sync memory across repositories"
      echo "  sdlc memory status            Show memory status for story"
      echo "  sdlc memory show [--verify-fresh]  Show memory contents (optionally verify freshness)"
      echo "  sdlc memory semantic-status   Show unified semantic memory stats"
      echo "  sdlc memory semantic-upsert   Upsert entry (see scripts/semantic-memory.py --help)"
      echo "  sdlc memory semantic-query    Query ranked memory"
      echo "  sdlc memory semantic-lifecycle  Run lifecycle governance"
      echo "  sdlc memory semantic-export   Export team JSONL (git-tracked; auto in pre-commit)"
      echo "  sdlc memory semantic-import   Import team JSONL into local SQLite (auto after pull)"
      echo "  sdlc memory doctor [--fix]    Remove dead .sdlc/module-kb/; sanity-check layout"
      echo ""
      echo "Unified shortcuts (auto-routed):"
      echo "  sdlc remember \"<text>\" [--to=...] [--kind=...]  Save to semantic|module|shared"
      echo "  sdlc recall   \"<query>\" [--scope=all|this|cross] Federated read"
      return 1
      ;;
  esac
}

cmd_qa() {
  local sub="${1:-help}"
  shift 2>/dev/null || true

  local base_url="${QA_ORCHESTRATOR_URL:-http://localhost:8000}"

  if ! command -v curl &>/dev/null; then
    log_error "curl is required for sdlc qa commands"
    return 1
  fi

  case "$sub" in
    start)
      local story_id="${1:-}"
      shift || true
      if [[ -z "$story_id" ]]; then
        log_error "Usage: sdlc qa start <story-id> [--priority=<level>] [--tags=<a,b>]"
        return 1
      fi
      local priority="medium"
      local tags=""
      for arg in "$@"; do
        case "$arg" in
          --priority=*) priority="${arg#--priority=}" ;;
          --tags=*) tags="${arg#--tags=}" ;;
        esac
      done
      local payload="{\"story_id\":\"${story_id}\",\"priority\":\"${priority}\",\"tags\":["
      if [[ -n "$tags" ]]; then
        local first=1 tag
        IFS=',' read -ra _tags <<< "$tags"
        for tag in "${_tags[@]}"; do
          [[ -z "$tag" ]] && continue
          if [[ $first -eq 0 ]]; then payload+=", "; fi
          payload+="\"${tag}\""
          first=0
        done
      fi
      payload+="]}"
      curl -sS -X POST "${base_url}/trigger" -H "Content-Type: application/json" -d "$payload"
      echo ""
      ;;
    status)
      local run_id="${1:-}"
      [[ -z "$run_id" ]] && { log_error "Usage: sdlc qa status <run-id>"; return 1; }
      curl -sS "${base_url}/status/${run_id}"
      echo ""
      ;;
    approve)
      local run_id="${1:-}"
      local checkpoint="${2:-}"
      local decision="${3:-}"
      shift 3 2>/dev/null || true
      [[ -z "$run_id" || -z "$checkpoint" || -z "$decision" ]] && {
        log_error "Usage: sdlc qa approve <run-id> <checkpoint> <APPROVED|REJECTED|REFINE> [--reason=...]"
        return 1
      }
      local reason=""
      for arg in "$@"; do
        case "$arg" in
          --reason=*) reason="${arg#--reason=}" ;;
        esac
      done
      curl -sS -X POST "${base_url}/approve?run_id=${run_id}" \
        -H "Content-Type: application/json" \
        -d "{\"checkpoint\":\"${checkpoint}\",\"decision\":\"${decision}\",\"reason\":\"${reason}\"}"
      echo ""
      ;;
    kb)
      local run_id="${1:-}"
      shift || true
      [[ -z "$run_id" ]] && { log_error "Usage: sdlc qa kb <run-id> [--store=<name>] [--format=json|summary]"; return 1; }
      local store=""
      local format="json"
      for arg in "$@"; do
        case "$arg" in
          --store=*) store="${arg#--store=}" ;;
          --format=*) format="${arg#--format=}" ;;
        esac
      done
      if [[ -n "$store" ]]; then
        curl -sS "${base_url}/kb/${run_id}/${store}"
      elif [[ "$format" == "summary" ]]; then
        curl -sS "${base_url}/kb/${run_id}/summary"
      else
        curl -sS "${base_url}/kb/${run_id}"
      fi
      echo ""
      ;;
    archive)
      local run_id="${1:-}"
      [[ -z "$run_id" ]] && { log_error "Usage: sdlc qa archive <run-id>"; return 1; }
      curl -sS -X POST "${base_url}/archive/${run_id}"
      echo ""
      ;;
    health)
      curl -sS "${base_url}/health"
      echo ""
      ;;
    *)
      echo ""
      echo "QA Orchestrator Commands:"
      echo "  sdlc qa start <story-id> [--priority=<level>] [--tags=<tag1,tag2>]"
      echo "  sdlc qa status <run-id>"
      echo "  sdlc qa approve <run-id> <checkpoint> <APPROVED|REJECTED|REFINE> [--reason=...]"
      echo "  sdlc qa kb <run-id> [--store=<name>] [--format=json|summary]"
      echo "  sdlc qa archive <run-id>"
      echo "  sdlc qa health"
      echo ""
      echo "Optional env: QA_ORCHESTRATOR_URL (default: http://localhost:8000)"
      return 1
      ;;
  esac
}

# ============================================================================
# Smart Routing — Classify task type and recommend gate depth
# ============================================================================

cmd_route() {
  local task_description="${*}"

  if [[ -z "$task_description" ]]; then
    log_error "Usage: sdlc route <task-description>"
    echo ""
    echo "Examples:"
    echo "  sdlc route 'review the PRD for this feature'"
    echo "  sdlc route 'create a master story for multi-language support'"
    echo "  sdlc route 'run load test for the API'"
    echo ""
    echo "Smart routing delegates to agents/shared/smart-routing.md"
    echo "For advanced routing, use IDE chat: /project or describe in natural language"
    return 1
  fi

  log_info "Smart Routing — Task Classification"
  echo ""
  echo "Task: $task_description"
  echo ""
  log_warn "Note: Detailed routing is available in IDE chat (/project) or via agents."
  log_warn "CLI routing provides basic classification only."
  echo ""
  echo "For full smart routing with gate recommendations and stage mapping:"
  echo "  • Use Cursor IDE: describe task in chat or use /project command"
  echo "  • Use Claude Code: describe task in chat or use /project command"
  echo "  • Or invoke agent: sdlc agent invoke smart-routing --task=\"...\" --role=$SDLC_ROLE"
  return 0
}

# ============================================================================

# ============================================================================
# Unified Module System (replaces kb + mis)
# ============================================================================

cmd_module() {
  local subcmd="${1:-help}"
  shift 2>/dev/null || true

  local scripts_dir="${PLATFORM_DIR}/scripts"

  _run_script() {
    local script="$1"; shift
    if [[ ! -f "$scripts_dir/$script" ]]; then
      log_error "$script not found at $scripts_dir/$script"
      log_hint "Re-clone ai-sdlc-platform or run: sdlc doctor"
      log_recovery_footer
      return 1
    fi
    bash "$scripts_dir/$script" "$@"
  }

  case "$subcmd" in
    init)        _run_script "module-init.sh" "${1:-.}" ;;
    update)      _run_script "module-update.sh" "${1:-.}" ;;
    show)        _run_script "module-show.sh" "$@" ;;
    load)        _run_script "module-load.sh" "$@" ;;
    validate)    _run_script "module-validate.sh" "${1:-.}" ;;
    report)      _run_script "module-report.sh" "${1:-.}" ;;
    budget)      _run_script "module-budget.sh" "${1:-.}" ;;
    link-issues) _run_script "module-link-issues.sh" "${1:-.}" ;;
    *)
      echo ""
      echo "Unified Module System Commands:"
      echo "  sdlc module init [path]                    Initialize module system (contracts + knowledge)"
      echo "  sdlc module update [path]                  Incremental update (if code changed)"
      echo "  sdlc module show [section] [filter]        View contracts/knowledge (api|data|events|deps|manifest|issues|impact|tech|all)"
      echo "  sdlc module load [api|data|events|logic|all]  Smart load (auto-detect change type, 70% token savings)"
      echo "  sdlc module validate [path]                Pre-merge contract validation"
      echo "  sdlc module report [path]                  Impact analysis report"
      echo "  sdlc module budget [path]                  Token budget for current stage/role"
      echo "  sdlc module link-issues [path]             Find ADO issue references"
      echo ""
      echo "Stacks: Java, Kotlin/Android, Swift/iOS, React Native, Node.js, C/C++"
      echo ""
      return 1
      ;;
  esac
}

# Backward compatibility aliases
cmd_kb()  { log_warn "DEPRECATED: 'sdlc kb' is now 'sdlc module'. Redirecting..."; cmd_module "$@"; }
cmd_mis() { log_warn "DEPRECATED: 'sdlc mis' is now 'sdlc module'. Redirecting..."; cmd_module "$@"; }

cmd_story() {
  bash "${SCRIPT_DIR}/commands/story.sh" "$@"
}

# Workspace-level setup (parent folder with multiple repos)
cmd_workspace() {
  bash "${SCRIPT_DIR}/commands/workspace.sh" "$@"
}

# Unified memory surface: single entry point that auto-routes across
# semantic / module / shared layers. Existing `sdlc memory *` remains.
cmd_remember() {
  bash "${SCRIPT_DIR}/commands/remember.sh" remember "$@"
}

cmd_recall() {
  bash "${SCRIPT_DIR}/commands/remember.sh" recall "$@"
}

# Main dispatcher
# ============================================================================

main() {
  local cmd="${1:-help}"
  shift 2>/dev/null || true

  case "$cmd" in
    module)          cmd_module "$@" ;;
    kb)              cmd_kb "$@" ;;
    mis)             cmd_mis "$@" ;;
    repos)           case "${1:-help}" in
                        add|detect) shift; cmd_repos_add "$@" ;;
                        list|ls) cmd_repos_list ;;
                        switch|use) shift; cmd_repos_switch "$@" ;;
                        depend|dep) shift; cmd_repos_depend "$@" ;;
                        deps|graph) cmd_repos_deps ;;
                        check) shift; cmd_repos_check "$@" ;;
                        notify) shift; cmd_repos_notify "$@" ;;
                        help|--help|-h) cmd_repos_help ;;
                        *) cmd_repos_help ;;
                      esac
                      ;;
    use)         cmd_use "$@" ;;
    context)     cmd_context "$@" ;;
    setup)       cmd_setup "$@" ;;
    init)        cmd_init "$@" ;;
    run)         cmd_run "$@" ;;
    flow)        cmd_flow "$@" ;;
    route)       cmd_route "$@" ;;
    gate-check)  cmd_gate_check "$@" ;;
    agent)            cmd_agent "$@" ;;
    skills)           cmd_skills "$@" ;;
    story)       cmd_story "$@" ;;
    template)         cmd_template "$@" ;;
    memory)           cmd_memory "$@" ;;
    workspace)        cmd_workspace "$@" ;;
    remember)         cmd_remember "$@" ;;
    recall)           cmd_recall "$@" ;;
    qa)               cmd_qa "$@" ;;
    sync)             cmd_sync "$@" ;;
    publish)          cmd_publish "$@" ;;
    ado)              cmd_ado "$@" ;;
    tokens)           cmd_tokens "$@" ;;
    cost)             cmd_cost "$@" ;;
    skip-tests)       cmd_skip_tests "$@" ;;
    show-test-skips)  cmd_show_test_skips "$@" ;;
    clear-test-skips) cmd_clear_test_skips "$@" ;;
    rpi)              cmd_rpi "$@" ;;
    doc)              cmd_doc "$@" ;;
    doctor)           cmd_doctor "$@" ;;
    version|--version) cmd_version ;;
    help|--help|-h)    cmd_help ;;
    *)
      log_error "Unknown command: $cmd"
      echo ""
      log_info "Try: sdlc help   |   sdlc doctor"
      log_recovery_footer
      return 1
      ;;
  esac
}

# ============================================================================
# Main entrypoint
# ============================================================================

main "$@"