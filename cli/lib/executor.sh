#!/usr/bin/env bash
# cli/lib/executor.sh — Stage execution, workflows, agents, skills, templates, gates
# Part of AI SDLC Platform v2.0.0
# Depends on: logging.sh, config.sh, guards.sh
# -----------------------------------------------------------

# ============================================================================
# ROLE / CONTEXT MANAGEMENT
# ============================================================================

cmd_use() {
  local role=""
  local stack=""

  for arg in "$@"; do
    case "$arg" in
      --stack=*) stack="${arg#--stack=}" ;;
      -*)        log_warn "Unknown flag: $arg" ;;
      *)         if [[ -z "$role" ]]; then role="$arg"; fi ;;
    esac
  done

  if ! validate_role "$role"; then
    log_error "Invalid role: $role"
    log_info "Available roles: ${ROLES[*]}"
    log_recovery_footer
    return 1
  fi

  if [[ -n "$stack" ]] && ! validate_stack "$stack"; then
    log_error "Invalid stack: $stack"
    log_info "Available stacks: ${STACKS[*]}"
    log_recovery_footer
    return 1
  fi

  load_config

  # Bind project dir when running from a repo that ran sdlc-setup
  if [[ -z "$SDLC_PROJECT_DIR" && -d "${PWD}/.sdlc" ]]; then
    SDLC_PROJECT_DIR="$(cd "$PWD" && pwd)"
  fi

  SDLC_ROLE="$role"
  if [[ -n "$stack" ]]; then SDLC_STACK="$stack"; fi
  SDLC_STAGE=""

  save_config

  # Save to state.json as well
  if command -v save_context &>/dev/null; then
    save_context "$role" "${SDLC_STACK}" ""
  fi

  log_success "Switched to role: ${ROLE_ICON} $role"
  if [[ -n "$stack" ]]; then log_success "Stack set to: ${STACK_ICON} $stack"; fi

  if [[ -f "${PLATFORM_DIR}/roles/${role}.md" ]]; then
    log_info "Loaded role definition from roles/${role}.md"
  fi

  if [[ -n "$SDLC_PROJECT_DIR" && -d "$SDLC_PROJECT_DIR" ]]; then
    _setup_symlinks "$role"
  fi
}

cmd_context() {
  load_config

  log_section "Current Context"

  echo -e "${ROLE_ICON}  Role:       ${SDLC_ROLE:-"(not set)"}"
  echo -e "${STACK_ICON}  Stack:      ${SDLC_STACK:-"(default)"}"
  echo -e "${STAGE_ICON}  Stage:      ${SDLC_STAGE:-"(not in stage)"}"
  echo -e "${BLUE}📁  Project:    ${SDLC_PROJECT_DIR:-"(not set)"}"
  echo -e "${BLUE}🏢  Platform:   ${SDLC_PLATFORM_DIR:-$PLATFORM_DIR}"

  if [[ -n "$SDLC_PROJECT_DIR" && -d "$SDLC_PROJECT_DIR/.sdlc" ]]; then
    echo -e "\n${MEMORY_ICON}  Local Memory:"
    ls -lh "$SDLC_PROJECT_DIR/.sdlc/" 2>/dev/null | tail -5 | sed 's/^/     /'
  fi
}

cmd_init() {
  log_section "Initializing SDLC workspace"

  mkdir -p .sdlc/memory
  touch .sdlc/role .sdlc/stack .sdlc/stage

  SDLC_PROJECT_DIR="$(pwd)"
  save_config

  if command -v init_state &>/dev/null; then
    init_state
    log_success ".sdlc/state.json created"
  fi

  _setup_symlinks "${SDLC_ROLE:-product}"

  if git rev-parse --git-dir > /dev/null 2>&1; then
    log_success "Git repo detected — memory will be git-synced"
  else
    log_success "No git repo — using local flat-file memory"
  fi

  log_success "Workspace initialized at $(pwd)/.sdlc/"
}

# ============================================================================
# STAGE EXECUTION
# ============================================================================

cmd_run() {
  local stage=""
  local story=""
  local from_stage=""
  local to_stage=""

  for arg in "$@"; do
    case "$arg" in
      --story=*) story="${arg#--story=}" ;;
      --from=*)  from_stage="${arg#--from=}" ;;
      --to=*)    to_stage="${arg#--to=}" ;;
      -*)        log_warn "Unknown flag: $arg" ;;
      *)         if [[ -z "$stage" ]]; then stage="$arg"; fi ;;
    esac
  done

  if ! validate_stage "$stage"; then
    log_error "Invalid stage: $stage"
    log_info "Available stages:"
    printf '%s\n' "${STAGES[@]}" | sed 's/^/  - /'
    log_hint "Example: sdlc run 04-grooming"
    log_recovery_footer
    return 1
  fi

  if ! _context_guard true true false; then
    return 1
  fi

  load_config

  if [[ -z "$SDLC_ROLE" ]]; then
    log_error_recovery "No role set. Run 'sdlc use <role>' first (or ASK in chat, then run that command)" \
<<<<<<< HEAD
      "Example: sdlc use product   or   sdlc use backend --stack=java"
=======
      "Example: sdlc use product   or   sdlc use backend --stack=java"
>>>>>>> 5a6d807 (Final commit of AI-SDLC Platform)
    return 1
  fi

  SDLC_STAGE="$stage"
  save_config

  # Check token budget before running stage
  if command -v check_token_limit &>/dev/null; then
    local stage_num="${stage%%-*}"
    local stage_budget="${STAGE_BUDGET[$stage_num]:-5000}"
    if ! check_token_limit "$stage" "$SDLC_ROLE" "$stage_budget"; then
      log_error_recovery "Stage execution blocked due to token budget limit" \
        "See spend: sdlc tokens   |   Per-stage budget: sdlc cost $stage"
      return 1
    fi
  fi

  # Completion re-run guard (v2.1.2) — warn if .sdlc/memory/<stage>-completion.md exists.
  # Stage results are written by hooks/post-stage.sh; re-running spends tokens again.
  # Set SDL_FORCE_RERUN=1 to suppress this warning (for deliberate re-executions).
  local completion_file="${SDLC_PROJECT_DIR:-.}/.sdlc/memory/${stage}-completion.md"
  if [[ -f "$completion_file" && "${SDL_FORCE_RERUN:-0}" != "1" ]]; then
    log_warn "Stage '$stage' already has completion memory at ${completion_file}."
    log_warn "  Token cost: re-running will spend the full stage budget again."
    log_warn "  Options:"
    log_warn "    1. Load prior output:  cat $completion_file"
    log_warn "    2. Recall decisions:   sdlc recall \"${stage}\""
    log_warn "    3. Force re-run:       SDL_FORCE_RERUN=1 sdlc run $stage"
  fi

  log_section "Running Stage: $stage"
  log_info "Role:   ${ROLE_ICON} $SDLC_ROLE"
  if [[ -n "$SDLC_STACK" ]]; then log_info "Stack:  ${STACK_ICON} $SDLC_STACK"; fi
  if [[ -n "$story" ]]; then log_info "Work item: $story"; fi

  # Load stage metadata
  local stage_file="${PLATFORM_DIR}/stages/${stage}/STAGE.md"
  if [[ ! -f "$stage_file" ]]; then
    log_warn "Stage definition not found: $stage_file"
  else
    log_info "Loaded stage definition from stages/${stage}/STAGE.md"
  fi

  # Load role definition
  local role_file="${PLATFORM_DIR}/roles/${SDLC_ROLE}.md"
  if [[ -f "$role_file" ]]; then
    log_info "Loaded role definition from roles/${SDLC_ROLE}.md"
  fi

  # Load stack variant if applicable
  if [[ -n "$SDLC_STACK" ]]; then
    local variant_name="${STACK_VARIANT_MAP[$SDLC_STACK]:-$SDLC_STACK}"
    local stack_variant="${PLATFORM_DIR}/stages/${stage}/variants/${variant_name}.md"
    if [[ -f "$stack_variant" ]]; then
      log_info "Loaded stack variant: ${STACK_ICON} $SDLC_STACK (${variant_name})"
    else
      case "$SDLC_STACK" in
        kotlin-android|swift-ios|react-native)
          local mobile_variant="${PLATFORM_DIR}/stages/${stage}/variants/mobile-frontend.md"
          if [[ -f "$mobile_variant" ]]; then
            log_info "Loaded mobile variant: ${STACK_ICON} mobile-frontend"
          fi
          ;;
      esac
    fi
  fi

  log_success "Stage context loaded. Ready for AI execution."
  echo ""
}

# ============================================================================
# WORKFLOWS
# ============================================================================

cmd_flow() {
  local workflow="$1"
  local workflows_dir="${PLATFORM_DIR}/workflows"

  _resolve_workflow_file() {
    local wf_name="$1"
    local candidate
    for ext in yml yaml md; do
      candidate="${workflows_dir}/${wf_name}.${ext}"
      if [[ -f "$candidate" ]]; then
        echo "$candidate"
        return 0
      fi
    done
    return 1
  }

  if [[ "$workflow" == "list" ]]; then
    log_section "Available Workflows"
    if [[ -d "$workflows_dir" ]]; then
      local found=0
      local wf
      for wf in "$workflows_dir"/*; do
        [[ -f "$wf" ]] || continue
        case "$wf" in
          *.yml|*.yaml|*.md)
            echo "  - $(basename "$wf" | sed -E 's/\.(yml|yaml|md)$//')"
            found=1
            ;;
        esac
      done
      if [[ $found -eq 0 ]]; then
        log_info "No workflows defined yet"
      fi
    else
      log_warn "No workflows directory found"
    fi
    return 0
  fi

  if ! _context_guard true false false; then
    return 1
  fi

  load_config

  if [[ -z "$SDLC_ROLE" ]]; then
    log_error_recovery "No role set. Run 'sdlc use <role>' first (or ASK in chat, then run that command)" \
      "Example: sdlc use product"
    return 1
  fi

  local workflow_file=""
  workflow_file="$(_resolve_workflow_file "$workflow")" || true
  if [[ -z "$workflow_file" || ! -f "$workflow_file" ]]; then
    log_error "Workflow not found: $workflow"
    log_info "Run: sdlc flow list"
    log_recovery_footer
    return 1
  fi

  log_section "Running Workflow: ${WORKFLOW_ICON} $workflow"
  log_info "Role: ${ROLE_ICON} $SDLC_ROLE"
  log_info "Loaded workflow from workflows/$(basename "$workflow_file")"
  log_success "Workflow context loaded."
}

# ============================================================================
# MEMORY / STATE SYNC
# ============================================================================

cmd_sync() {
  load_config

  log_section "Syncing Memory to Git"

  if [[ -z "$SDLC_PROJECT_DIR" ]]; then
    log_error_recovery "No project directory set" \
      "cd to your app repo containing .sdlc/ or run: sdlc init"
    return 1
  fi

  if [[ ! -d "$SDLC_PROJECT_DIR/.sdlc/memory" ]]; then
    log_warn "No local memory directory found"
    return 0
  fi

  cd "$SDLC_PROJECT_DIR" || return 1

  if ! git rev-parse --git-dir > /dev/null 2>&1; then
    log_warn "Not a git repo — memory is local only"
    return 0
  fi

  git add .sdlc/memory 2>/dev/null || true

  if git diff --cached --quiet .sdlc/memory; then
    log_success "Memory already synced"
  else
    git commit -m "sdlc: sync memory at $(date +%Y-%m-%d\ %H:%M:%S)" 2>/dev/null || log_warn "No changes to commit"
    log_success "Memory synced to git"
  fi

  if git remote | grep -q origin; then
    git push origin HEAD 2>/dev/null && log_success "Pushed to origin" || log_warn "Push failed"
  fi
}

cmd_publish() {
  load_config

  log_section "Publishing Memory"

  if [[ -z "$SDLC_PROJECT_DIR" ]]; then
    log_error_recovery "No project directory set" \
      "cd to your app repo containing .sdlc/ or run: sdlc init"
    return 1
  fi

  cd "$SDLC_PROJECT_DIR"
  if ! git rev-parse --git-dir > /dev/null 2>&1; then
    log_info "Local mode: memory saved to .sdlc/memory/"
    return 0
  fi

  if [[ -f .gitignore ]] && grep -q "^\.sdlc/$" .gitignore 2>/dev/null; then
    log_warn ".sdlc/ is fully gitignored. Adjusting to track .sdlc/memory/ while ignoring .sdlc/config..."
    sed -i 's|^\.sdlc/$|.sdlc/config|' .gitignore
    log_info "Updated .gitignore: .sdlc/config ignored, .sdlc/memory/ now tracked"
  fi

  log_info "Pushing memory changes..."
  git add .sdlc/memory/ 2>/dev/null || true
  git commit -m "SDLC: Memory checkpoint [$(date +%Y-%m-%dT%H:%M)]" 2>/dev/null || log_warn "No changes to commit"

  local current_branch
  current_branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo main)"
  git push origin "$current_branch" 2>/dev/null || log_warn "Could not push to origin/$current_branch"
  log_success "Memory published to $current_branch"
}

cmd_memory_show() {
  load_config

  log_section "Shared Memory State"

  if [[ -z "$SDLC_PROJECT_DIR" ]]; then
    log_error "No project directory set"
    return 1
  fi

  if [[ ! -d "$SDLC_PROJECT_DIR/.sdlc/memory" ]]; then
    log_warn "No local memory directory found"
    return 0
  fi

  echo -e "${MEMORY_ICON}  Memory contents:\n"
  find "$SDLC_PROJECT_DIR/.sdlc/memory" -type f -name "*.md" 2>/dev/null | while read -r file; do
    echo -e "  ${BLUE}$(basename "$file")${NC}"
  done
}

# ============================================================================
# AGENTS & SKILLS
# ============================================================================

cmd_agent() {
  local sub="${1:-list}"
  shift 2>/dev/null || true

  case "$sub" in
    list)
      log_section "Available Agents"
      if [[ -f "${PLATFORM_DIR}/agents/agent-registry.json" ]] && command -v jq &>/dev/null; then
        log_info "Tier 1 (Universal):"
        jq -r '.tier_1_universal | to_entries[] | "  \(.key): \(.value.description)"' "${PLATFORM_DIR}/agents/agent-registry.json"
        echo ""
        log_info "Tier 2 (Domain):"
        jq -r '.tier_2_domain | to_entries[] | "  [\(.key)]" , (.value | to_entries[] | "    \(.key): \(.value.description // "no description")")' "${PLATFORM_DIR}/agents/agent-registry.json" 2>/dev/null || true
      else
        log_warn "Agent registry not found or jq not available"
      fi
      ;;
    show)
      local agent="$1"
      if [[ -f "${PLATFORM_DIR}/agents/agent-registry.json" ]] && command -v jq &>/dev/null; then
        jq ".tier_1_universal.$agent // .tier_2_domain[][] | select(.key == \"$agent\")" "${PLATFORM_DIR}/agents/agent-registry.json"
      else
        log_warn "Agent not found or jq not available"
      fi
      ;;
    invoke)
      local agent="$1"
      log_info "Invoke agent: $agent"
      log_warn "Agent invocation requires Claude/Cursor integration. See agents/agent-registry.json"
      ;;
    *)
      log_error "Usage: sdlc agent {list | show <agent-id> | invoke <agent-id>}"
      log_recovery_footer
      return 1
      ;;
  esac
}

cmd_skills() {
  local sub="${1:-list}"
  shift 2>/dev/null || true

  case "$sub" in
    list)
      log_section "Available Skills"
      if [[ -d "${PLATFORM_DIR}/skills" ]]; then
        find "${PLATFORM_DIR}/skills" -mindepth 2 -name "SKILL.md" -type f | while read -r skill_md; do
          skill_dir=$(dirname "$skill_md")
          skill_name=$(basename "$skill_dir")
          echo "  - $skill_name"
        done
      else
        log_warn "Skills directory not found"
      fi
      ;;
    show)
      local skill="$1"
      if [[ -f "${PLATFORM_DIR}/skills/${skill}/SKILL.md" ]]; then
        log_section "Skill: $skill"
        head -50 "${PLATFORM_DIR}/skills/${skill}/SKILL.md"
      else
        log_warn "Skill not found: $skill"
      fi
      ;;
    invoke)
      local skill="$1"
      log_info "Invoke skill: $skill"
      log_warn "Skill invocation requires Claude/Cursor integration. See skills/SKILL.md"
      ;;
    *)
      log_error "Usage: sdlc skills {list | show <skill-id> | invoke <skill-id>}"
      log_recovery_footer
      return 1
      ;;
  esac
}

# ============================================================================
# TEMPLATES
# ============================================================================

cmd_template() {
  local sub="${1:-list}"
  shift 2>/dev/null || true

  case "$sub" in
    list)
      log_section "Story Templates (4-Tier System)"
      if [[ -d "${PLATFORM_DIR}/templates/story-templates" ]]; then
        echo "Master Story:"
        echo "  sdlc story create master --output=./stories/"
        echo ""
        echo "Sprint Story:"
        echo "  sdlc story create sprint --parent=MS-001"
        echo ""
        echo "Tech Story (optional for complex features):"
        echo "  sdlc story create tech --relates-to=SS-001"
        echo ""
        echo "Task (atomic work unit):"
        echo "  sdlc story create task --parent=SS-001"
        echo ""
        echo "See full docs: cat templates/story-templates/STORY_TEMPLATE_REGISTRY.md"
      else
        log_warn "Templates directory not found"
      fi
      ;;
    validate)
      local file="$1"
      if [[ -f "$file" ]]; then
        log_info "Validating: $file"
        bash "${PLATFORM_DIR}/templates/story-templates/validators/"*"-story-validator.sh" "$file" 2>/dev/null || \
          log_warn "Auto-detection failed. Try: sdlc story validate $file"
      else
        log_error_recovery "File not found: $file" \
          "Create a story first: sdlc story create master --output=./stories/"
        return 1
      fi
      ;;
    generate)
      local type="$1"
      local output="${2:-.}"
      log_info "Use: sdlc story create $type instead"
      log_info "  sdlc story create master --output=$output"
      ;;
    *)
      log_error "Usage: sdlc template {list | validate <file>}"
      log_info "For story creation, use: sdlc story create <type>"
      log_recovery_footer
      return 1
      ;;
  esac
}

# ============================================================================
# GATES
# ============================================================================

cmd_gate_check() {
  local stage="${1:-}"
  local ado_id=""

  for arg in "$@"; do
    case "$arg" in
      --ado-id=*) ado_id="${arg#--ado-id=}" ;;
    esac
  done

  if [[ -z "$stage" ]]; then
    log_error "Usage: sdlc gate-check <stage-id> [--ado-id=<id>]"
    log_hint "Example: sdlc gate-check 04-grooming"
    log_recovery_footer
    return 1
  fi

  if ! validate_stage "$stage"; then
    log_error "Invalid stage: $stage"
    log_info "Run: sdlc flow list  (workflows)  |  stages: 01-requirement-intake … 15-summary-close"
    log_recovery_footer
    return 1
  fi

  log_section "Gate Check: Stage $stage"
  [[ -n "$ado_id" ]] && log_info "Work Item: $ado_id"

  log_warn "Gate checking requires Claude integration. See agents/shared/gate-informant.md"
  log_info "Gates are informational only — they warn but never block execution."
}

# ============================================================================
# TOKEN BUDGET TRACKING
# ============================================================================

cmd_tokens() {
  load_config
  _load_env

  log_section "Token Budget Report"

  local role="${SDLC_ROLE:-}"
  if [[ -z "$role" ]]; then
    log_warn "No role set. Run 'sdlc use <role>' first"
    return 0
  fi

  local state_file="${SDLC_PROJECT_DIR:-.}/.sdlc/state.json"

  if command -v get_daily_spend &>/dev/null; then
    echo ""
    log_info "Role: $role"
    echo ""

    local daily_spend=0
    local sprint_spend=0

    if [[ -f "$state_file" ]] && command -v jq &>/dev/null; then
      daily_spend=$(jq "[.token_spent | to_entries[] | select(.key | startswith(\"$(date +%Y-%m-%d):$role\")) | .value] | add // 0" "$state_file" 2>/dev/null)
      sprint_spend=$(jq "[.token_spent | to_entries[] | select(.key | contains(\"$role\")) | .value] | add // 0" "$state_file" 2>/dev/null)
    fi

    if [[ -z "$daily_spend" ]] || [[ "$daily_spend" == "null" ]]; then daily_spend=0; fi
    if [[ -z "$sprint_spend" ]] || [[ "$sprint_spend" == "null" ]]; then sprint_spend=0; fi

    log_info "Daily Budget:"
    echo "  Spent: ${daily_spend:-0} tokens"
    case "$role" in
      product) echo "  Budget: 8000 tokens" ;;
      backend|frontend) echo "  Budget: 6000 tokens" ;;
      qa) echo "  Budget: 4000 tokens" ;;
      performance|ui) echo "  Budget: 5000 tokens" ;;
      tpm) echo "  Budget: 3000 tokens" ;;
      boss) echo "  Budget: 5000 tokens" ;;
    esac

    echo ""
    log_info "Sprint Budget:"
    echo "  Spent: ${sprint_spend:-0} tokens"
    case "$role" in
      product) echo "  Budget: 80000 tokens" ;;
      backend|frontend) echo "  Budget: 60000 tokens" ;;
      qa) echo "  Budget: 40000 tokens" ;;
      performance) echo "  Budget: 50000 tokens" ;;
      ui) echo "  Budget: 40000 tokens" ;;
      tpm) echo "  Budget: 30000 tokens" ;;
      boss) echo "  Budget: 50000 tokens" ;;
    esac

    echo ""
    log_info "To track usage, run a stage: sdlc run <stage>"
  else
    log_warn "Token tracking requires state.json. Run 'sdlc init' first"
  fi

  # Show sprint budget
  echo ""
  set +e
  if command -v show_sprint &>/dev/null; then
    show_sprint || true
  fi
  set -e

  # Show recent log entries
  local log_file="${TOKEN_LOG_FILE:-${PLATFORM_DIR}/env/.token-usage.log}"
  if [[ -f "$log_file" ]]; then
    echo ""
    log_section "Recent Entries"
    tail -10 "$log_file"
  fi
}

# ============================================================================
# RPI WORKFLOW COMMANDS
# ============================================================================
# Research-Plan-Implement-Verify workflow for complex tasks
# See: rules/rpi-workflow.md

cmd_rpi() {
  local phase="$1"
  local story_id="$2"

  if [[ -z "$phase" || -z "$story_id" ]]; then
    log_error "Usage: sdlc rpi <research|plan|implement|verify|status> <story-id>"
    log_info "Example: sdlc rpi research US-1234"
    return 1
  fi

  load_config

  # Validate story ID format
  if ! [[ "$story_id" =~ ^US-[0-9]+$ ]]; then
    log_error "Invalid story ID format: $story_id (expected: US-XXXX)"
    return 1
  fi

  # Create RPI directory
  local rpi_dir=".sdlc/rpi/${story_id}"
  mkdir -p "$rpi_dir"

  case "$phase" in
    research)
      log_section "RPI Phase 1: Research"
      log_info "Starting scope isolation for ${story_id}"
      log_info "Expected output: ${rpi_dir}/research.md"
      log_info ""
      log_info "This phase will:"
      log_info "  1. Fetch ADO work item details"
      log_info "  2. Identify relevant codebase files (max 10)"
      log_info "  3. Search Wiki.js for architecture/design docs"
      log_info "  4. Document risks, edge cases, dependencies"
      log_info "  5. Estimate token budget for Plan + Implement phases"
      log_info ""
      log_info "Run '/project:rpi-research $story_id' to execute research phase"
      log_success "Research phase initialized. Waiting for human to start research..."
      ;;

    plan)
      if [[ ! -f "${rpi_dir}/research.md" ]]; then
        log_error "research.md not found. Run 'sdlc rpi research $story_id' first"
        return 1
      fi
      if [[ ! -f "${rpi_dir}/.approved-research" ]]; then
        log_error "Research not approved. Cannot proceed to planning"
        log_info "After human review of research.md, create marker:"
        log_info "  touch ${rpi_dir}/.approved-research"
        return 1
      fi

      log_section "RPI Phase 2: Plan"
      log_info "Planning implementation for ${story_id}"
      log_info "Input: ${rpi_dir}/research.md (approved)"
      log_info "Output: ${rpi_dir}/plan.md"
      log_info ""
      log_info "This phase will:"
      log_info "  1. Load and verify research approval"
      log_info "  2. Specify line-level changes for each file"
      log_info "  3. Plan test additions and modifications"
      log_info "  4. Document rollback strategy per file"
      log_info "  5. Lock scope (note out-of-scope items)"
      log_info ""
      log_info "Run '/project:rpi-plan $story_id' to execute planning phase"
      log_success "Planning phase initialized. Waiting for human to start planning..."
      ;;

    implement)
      if [[ ! -f "${rpi_dir}/plan.md" ]]; then
        log_error "plan.md not found. Run 'sdlc rpi plan $story_id' first"
        return 1
      fi
      if [[ ! -f "${rpi_dir}/.approved-plan" ]]; then
        log_error "Plan not approved. Cannot proceed to implementation"
        log_info "After human review of plan.md, create marker:"
        log_info "  touch ${rpi_dir}/.approved-plan"
        return 1
      fi

      log_section "RPI Phase 3: Implement"
      log_info "Implementing changes for ${story_id}"
      log_info "Input: ${rpi_dir}/plan.md (approved)"
      log_info "Output: Modified files (staged, not committed)"
      log_info ""
      log_info "This phase will:"
      log_info "  1. Load and verify plan approval"
      log_info "  2. Execute changes file-by-file (exact plan adherence)"
      log_info "  3. Run tests specified in plan"
      log_info "  4. Generate diff summary"
      log_info "  5. Stage changes for review (NO COMMIT)"
      log_info ""
      log_info "Run '/project:rpi-implement $story_id' to execute implementation phase"
      log_success "Implementation phase initialized. Waiting for human to start implementation..."
      ;;

    verify)
      if [[ ! -f "${rpi_dir}/plan.md" ]]; then
        log_error "plan.md not found. Run 'sdlc rpi implement' first"
        return 1
      fi

      log_section "RPI Phase 4: Verify"
      log_info "Verifying implementation matches plan for ${story_id}"
      log_info "Input: ${rpi_dir}/plan.md + staged git diff"
      log_info "Output: ${rpi_dir}/verify.md"
      log_info ""
      log_info "This phase will:"
      log_info "  1. Load plan.md and compare to actual staged changes"
      log_info "  2. Verify all planned changes are in git diff (completeness)"
      log_info "  3. Detect unplanned changes (scope creep)"
      log_info "  4. Validate test results match plan"
      log_info "  5. Check coverage ≥80% minimum"
      log_info ""
      log_info "Run '/project:rpi-verify $story_id' to execute verification phase"
      log_success "Verification phase initialized. Waiting for human to start verification..."
      ;;

    status)
      log_section "RPI Workflow Status: ${story_id}"

      if [[ -f "${rpi_dir}/research.md" ]]; then
        log_success "Phase 1 (Research): COMPLETE"
        if [[ -f "${rpi_dir}/.approved-research" ]]; then
          log_success "  Approval: ✓ APPROVED"
        else
          log_info "  Approval: ⏳ PENDING"
        fi
      else
        log_info "Phase 1 (Research): NOT STARTED"
      fi

      if [[ -f "${rpi_dir}/plan.md" ]]; then
        log_success "Phase 2 (Plan): COMPLETE"
        if [[ -f "${rpi_dir}/.approved-plan" ]]; then
          log_success "  Approval: ✓ APPROVED"
        else
          log_info "  Approval: ⏳ PENDING"
        fi
      else
        log_info "Phase 2 (Plan): NOT STARTED"
      fi

      if [[ -f "${rpi_dir}/verify.md" ]]; then
        log_success "Phase 3 (Implement) + Phase 4 (Verify): COMPLETE"
      else
        log_info "Phase 3 (Implement): NOT STARTED"
        log_info "Phase 4 (Verify): NOT STARTED"
      fi

      log_info ""
      log_info "RPI Directory: ${rpi_dir}/"
      ls -lh "$rpi_dir" 2>/dev/null | tail -n +2 | sed 's/^/  /'
      ;;

    *)
      log_error "Unknown RPI phase: $phase"
      log_info "Available phases: research | plan | implement | verify | status"
      return 1
      ;;
  esac
}

# ============================================================================
# TEST SKIP COMMANDS
# ============================================================================

_sdlc_resolve_ab_id_from_context() {
  local branch="$1"
  local id=""
  if [[ -f .sdlc/story-id ]]; then
    id=$(tr -d '\r\n' < .sdlc/story-id)
    id="${id//AB#/}"
    id="${id//#/}"
    [[ "$id" =~ ^[0-9]+$ ]] || id=""
  fi
  if [[ -z "$id" ]] && [[ "$branch" =~ AB#([0-9]+) ]]; then
    id="${BASH_REMATCH[1]}"
  fi
  if [[ -z "$id" ]] && [[ "$branch" =~ -([0-9]{4,})- ]]; then
    id="${BASH_REMATCH[1]}"
  fi
  if [[ -z "$id" ]]; then
    id=$(git log -1 --format=%B 2>/dev/null | grep -oE 'AB#[0-9]+' | head -1 | sed 's/AB#//' || true)
  fi
  echo "$id"
}

_sdlc_sync_test_skip_artifacts() {
  local branch="$1"
  local reason="$2"
  local wi_override="$3"
  local master_override="$4"
  local ts
  ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  local wi_id="${wi_override:-}"
  if [[ -z "$wi_id" ]]; then
    wi_id=$(_sdlc_resolve_ab_id_from_context "$branch")
  fi

  mkdir -p .sdlc/memory
  {
    echo "#### Test skip / branch sync — $ts"
    echo "- **Branch:** \`$branch\`"
    echo "- **Reason:** $reason"
    [[ -n "$wi_id" ]] && echo "- **ADO work item:** #$wi_id"
    echo ""
  } >> .sdlc/memory/branch-test-skip.md

  if [[ -f .sdlc/memory/tracing-log.md ]]; then
    echo "- $ts | branch=$branch | test-skip | reason=$reason | wi=${wi_id:-none}" >> .sdlc/memory/tracing-log.md
  fi

  local ms_path="${master_override:-}"
  if [[ -z "$ms_path" ]] && [[ -f .sdlc/memory/active-master-story.path ]]; then
    ms_path=$(grep -v '^#' .sdlc/memory/active-master-story.path 2>/dev/null | head -1 | tr -d '\r\n')
  fi
  if [[ -n "$ms_path" ]] && [[ -f "$ms_path" ]]; then
    {
      echo ""
      echo "## Test execution (recorded automatically)"
      echo "- **$ts** — branch \`$branch\`: unit tests **skipped** for this branch."
      echo "- **Reason:** $reason"
      [[ -n "$wi_id" ]] && echo "- **ADO:** discussion comment posted on work item #$wi_id (when online)"
    } >> "$ms_path"
    log_success "Master story file updated: $ms_path"
  elif [[ -n "$ms_path" ]]; then
    log_warn "Master story path set but file not found: $ms_path (set .sdlc/memory/active-master-story.path)"
  fi

  if [[ -n "$wi_id" ]] && type _ado_add_work_item_comment &>/dev/null; then
    local msg="[AI-SDLC] Unit test enforcement skipped for branch **${branch}** at ${ts}. Reason: ${reason}"
    _ado_add_work_item_comment "$wi_id" "$msg" || log_warn "ADO comment not posted (offline, auth, or API)"
  elif [[ -z "$wi_id" ]]; then
    log_warn "No AB# work item resolved — set .sdlc/story-id, use branch feature/AB#12345-*, or --work-item=12345"
  fi
}

cmd_skip_tests() {
  local reason=""
  local explicit_reason=0
  local wi_override=""
  local master_override=""

  for arg in "$@"; do
    case "$arg" in
      --reason=*) reason="${arg#--reason=}"; explicit_reason=1 ;;
      --work-item=*) wi_override="${arg#--work-item=}" ;;
      --master-story=*) master_override="${arg#--master-story=}" ;;
    esac
  done

  # Normalize AB#12345 → 12345
  if [[ -n "${wi_override:-}" ]]; then
    wi_override="${wi_override#AB#}"
    wi_override="${wi_override// /}"
    if [[ ! "$wi_override" =~ ^[0-9]+$ ]]; then
      log_error "--work-item must be a numeric Azure Boards id (e.g. 12345 or AB#12345)."
      return 1
    fi
  fi

  # Audit: user must document why unit tests are not run / not applicable (min 10 chars)
  if [[ "$explicit_reason" -ne 1 ]] || [[ ${#reason} -lt 10 ]]; then
    log_error "skip-tests requires --reason=\"...\" (min 10 characters) explaining why tests are skipped or not applicable."
    log_info "Example: sdlc skip-tests --work-item=12345 --reason=\"Infrastructure shell scripts only; no unit-test harness in this repo path.\""
    return 1
  fi

  load_config

  # Check if .sdlc directory exists
  if [[ ! -d ".sdlc" ]]; then
    log_error_recovery "Not in SDLC project context (.sdlc directory not found)" \
      "Run: sdlc init   or   cd to an app repo after ./setup.sh"
    return 1
  fi

  # Get current branch
  local branch
  branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")

  if [ "$branch" = "unknown" ]; then
    log_error_recovery "Not in a git repository" \
      "cd to a git clone of your application repo"
    return 1
  fi

  local wi_id="${wi_override:-}"
  if [[ -z "$wi_id" ]]; then
    wi_id=$(_sdlc_resolve_ab_id_from_context "$branch")
  fi
  if [[ -z "$wi_id" ]]; then
    log_error "Unit-test bypass is mandatory to trace to Azure Boards. Provide --work-item=<numeric-id>, set .sdlc/story-id, use a branch name containing AB#<id>, or ensure the latest commit message contains AB#<id>."
    log_info "Policy: post the bypass rationale on that work item (automated when ADO credentials are available). See rules/pre-merge-test-enforcement.md"
    return 1
  fi

  # Create skip marker file (structured — hooks require work_item line)
  local skip_marker=".sdlc/skip-tests-${branch}"
  mkdir -p ".sdlc"
  {
    echo "# AI-SDLC test skip marker — keep in sync with ADO discussion on work item #${wi_id}"
    echo "work_item=${wi_id}"
    echo "reason=${reason}"
    echo "created_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "user=$(git config user.name 2>/dev/null || whoami 2>/dev/null || echo unknown)"
  } > "$skip_marker"

  log_success "Test skip marker created: $skip_marker"
  log_info "Branch: $branch"
  log_info "Reason: $reason"
  log_info "Work item: #${wi_id}"

  # Log to skip log
  local skip_log=".sdlc/memory/test-skips.log"
  mkdir -p ".sdlc/memory"

  {
    echo "--- Test Skip Record ---"
    echo "Timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "Branch: $branch"
    echo "Work item: #${wi_id}"
    echo "User: $(git config user.name 2>/dev/null || whoami 2>/dev/null || echo "unknown")"
    echo "Reason: $reason"
    echo ""
  } >> "$skip_log"

  log_success "Skip decision logged to: $skip_log"
  log_info "Pre-merge policy: marker + ADO traceability — see rules/pre-merge-test-enforcement.md"
  log_info "If tests fail without this path, use: sdlc approve-test-skip --approver=... --role=tpm --reason=..."
  _sdlc_sync_test_skip_artifacts "$branch" "$reason" "$wi_id" "$master_override"
  echo ""
}

cmd_show_test_skips() {
  local skip_log=".sdlc/memory/test-skips.log"

  if [[ ! -f "$skip_log" ]]; then
    log_warn "No test skip log found: $skip_log"
    return 0
  fi

  log_section "Test Skip History"
  cat "$skip_log"
}

# Clear test-skip markers for the current branch (or --all for every branch).
# History is preserved in .sdlc/memory/test-skips.log (see `sdlc show-test-skips`).
# Confirmation is required unless --force is passed (Ask-First protocol).
cmd_clear_test_skips() {
  local clear_all=0
  local force=0
  for arg in "$@"; do
    case "$arg" in
      --all)   clear_all=1 ;;
      --force) force=1 ;;
      -h|--help)
        log_section "sdlc clear-test-skips — Remove test-skip markers"
        echo "  sdlc clear-test-skips              Clear marker for current branch"
        echo "  sdlc clear-test-skips --all        Clear markers for every branch"
        echo "  sdlc clear-test-skips [--all] --force   Skip confirmation prompt"
        echo ""
        log_info "History preserved in: .sdlc/memory/test-skips.log"
        log_info "See: sdlc show-test-skips"
        return 0
        ;;
    esac
  done

  if [[ ! -d ".sdlc" ]]; then
    log_error_recovery "Not in SDLC project context (.sdlc directory not found)" \
      "Run: sdlc init   or   cd to an app repo after ./setup.sh"
    return 1
  fi

  local targets=()
  if [[ "$clear_all" -eq 1 ]]; then
    while IFS= read -r f; do targets+=("$f"); done < <(ls -1 .sdlc/skip-tests-* 2>/dev/null)
  else
    local branch
    branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
    if [[ "$branch" == "unknown" ]]; then
      log_error_recovery "Not in a git repository" \
        "cd to a git clone of your application repo"
      return 1
    fi
    local marker=".sdlc/skip-tests-${branch}"
    [[ -f "$marker" ]] && targets+=("$marker")
  fi

  if [[ ${#targets[@]} -eq 0 ]]; then
    log_info "No test-skip markers to clear."
    return 0
  fi

  log_section "Test-skip markers to clear"
  for t in "${targets[@]}"; do
    echo "  $t"
  done
  echo ""

  if [[ "$force" -ne 1 ]]; then
    read -r -p "Remove ${#targets[@]} marker(s)? [y/N] " answer </dev/tty 2>/dev/null || answer=""
    if [[ "$answer" != "y" && "$answer" != "Y" ]]; then
      log_info "Aborted — no markers removed."
      return 0
    fi
  fi

  local removed=0
  for t in "${targets[@]}"; do
    if rm -f "$t" 2>/dev/null; then
      removed=$((removed+1))
    fi
  done

  # Audit: append clear event to the history log (do NOT truncate the log)
  local skip_log=".sdlc/memory/test-skips.log"
  mkdir -p ".sdlc/memory"
  {
    echo "--- Test Skip Cleared ---"
    echo "Timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo "User: $(git config user.name 2>/dev/null || whoami 2>/dev/null || echo "unknown")"
    echo "Markers removed: $removed"
    for t in "${targets[@]}"; do echo "  - $t"; done
    echo ""
  } >> "$skip_log"

  log_success "Cleared ${removed} test-skip marker(s)."
  log_info "History preserved in: $skip_log"
}

# Pick first Python 3 on PATH that actually runs (Windows Store python3 shim is a common false positive).
_sdlc_resolve_python_cmd() {
  local candidate first
  for candidate in python3 python "py -3"; do
    first="${candidate%% *}"
    if command -v "$first" &>/dev/null; then
      if $candidate -c "import sys" &>/dev/null 2>&1; then
        printf '%s\n' "$candidate"
        return 0
      fi
    fi
  done
  return 1
}

cmd_doc() {
  local sub="${1:-help}"
  shift 2>/dev/null || true

  local PYTHON_CMD=""
  PYTHON_CMD="$(_sdlc_resolve_python_cmd || true)"

  local DOC_SCRIPT="${PLATFORM_DIR}/scripts/doc-to-md.py"

  case "$sub" in
    convert)
      if [[ $# -eq 0 ]]; then
        log_error "Usage: sdlc doc convert <file|dir> [--output-dir <dir>]"
        log_info  "Supported: .docx  .xlsx  .pptx  .html/.htm  .pdf"
        log_info  "Output: .sdlc/import/<name>.extracted.md  (default)"
        return 1
      fi
      if [[ -z "$PYTHON_CMD" ]]; then
        log_error "Python not found. Install Python 3 to use sdlc doc convert."
        log_info  "See: User_Manual/Prerequisites.md"
        return 1
      fi
      if [[ ! -f "$DOC_SCRIPT" ]]; then
        log_error "doc-to-md.py not found: $DOC_SCRIPT"
        return 1
      fi
      log_info "Converting document(s) to Markdown…"
      $PYTHON_CMD "$DOC_SCRIPT" "$@"
      ;;
    deps)
      log_info "Install Python libraries for all formats:"
      echo "  pip install pypdf pdfplumber mammoth python-docx openpyxl python-pptx beautifulsoup4 html2text trafilatura"
      log_info "All are optional; the script falls back gracefully if some are missing."
      ;;
    list)
      log_info "Extracted documents in .sdlc/import/:"
      if [[ -d ".sdlc/import" ]]; then
        ls -lh .sdlc/import/*.extracted.md 2>/dev/null || log_warn "No extracted files found."
      else
        log_warn ".sdlc/import/ does not exist yet. Run: sdlc doc convert <file>"
      fi
      ;;
    help|--help|-h|*)
      log_section "sdlc doc — Document ingestion"
      echo "  sdlc doc convert <file|dir> [--output-dir <path>]"
      echo "    Convert Office / PDF / HTML file(s) to Markdown for AI ingestion."
      echo "    Output default: .sdlc/import/<name>.extracted.md"
      echo ""
      echo "  sdlc doc deps"
      echo "    Show the pip install command for all doc-convert libraries."
      echo ""
      echo "  sdlc doc list"
      echo "    List extracted documents in .sdlc/import/."
      echo ""
      log_info "Output default: .sdlc/import/<name>.extracted.md"
      log_info "Supported formats: .docx .xlsx .pptx .html/.htm .pdf"
      ;;
  esac
}
