#!/usr/bin/env bash
# cli/lib/ado.sh — Azure DevOps API integration (CRUD, links, push-story)
# Part of AI SDLC Platform v2.0.0
# Depends on: logging.sh, config.sh
# -----------------------------------------------------------

# ============================================================================
# ADO HELPERS
# ============================================================================

# curl wrapper with HTTP status code handling
_ado_curl() {
  local response
  local http_code
  local output

  output=$(curl -sS -w '\n%{http_code}' --connect-timeout "${SDLC_CONNECT_TIMEOUT:-15}" --max-time "${SDLC_MAXTIME:-60}" "$@" 2>&1)

  http_code=$(echo "$output" | tail -1)
  response=$(echo "$output" | sed '$d')

  if [[ ! "$http_code" =~ ^2[0-9]{2}$ ]]; then
    case "$http_code" in
      000) log_error "Connection error: network timeout or cannot reach server" >&2 ;;
      401) log_error "Authentication failed: ADO_PAT invalid or expired (HTTP 401)" >&2 ;;
      403) log_error "Access denied: insufficient permissions (HTTP 403)" >&2 ;;
      404) log_error "Not found: check ADO_ORG and ADO_PROJECT (HTTP 404)" >&2 ;;
      *)   log_error "HTTP error: $http_code" >&2 ;;
    esac
  fi

  echo "$response"

  if [[ ! "$http_code" =~ ^2[0-9]{2}$ ]]; then
    return 1
  fi
  return 0
}

# Accept numeric id or UI-style refs (US-851789, Bug-123, #851789)
_normalize_ado_wi_id() {
  local s="${1// /}"
  s="${s#\#}"
  if [[ "$s" =~ [0-9]+ ]]; then
    if [[ "$s" =~ ([0-9]+)$ ]]; then
      echo "${BASH_REMATCH[1]}"
    fi
  else
    echo "$s"
  fi
}

# Extract field from ADO work item JSON (uses jq, else node — never sed: HTML fields break sed)
_ado_json_field() {
  local json="$1" key="$2" out=""
  if command -v jq >/dev/null 2>&1; then
    out=$(printf '%s' "$json" | jq -r --arg k "$key" '.fields[$k] // empty' 2>/dev/null | tr -d '\r' | head -1)
    if [[ -n "$out" && "$out" != "null" ]]; then
      echo "$out"
      return
    fi
  fi
  if command -v node &>/dev/null; then
    out=$(printf '%s' "$json" | node -e "
      const field = process.argv[1];
      let buf = '';
      process.stdin.on('data', (c) => { buf += c; });
      process.stdin.on('end', () => {
        try {
          const j = JSON.parse(buf);
          const v = j.fields && j.fields[field];
          if (v == null) return;
          if (typeof v === 'string' || typeof v === 'number' || typeof v === 'boolean') {
            process.stdout.write(String(v));
          } else if (typeof v === 'object' && v.displayName) {
            process.stdout.write(String(v.displayName));
          }
        } catch (e) { process.exit(1); }
      });
    " "$key" 2>/dev/null | tr -d '\r')
    if [[ -n "$out" ]]; then
      echo "$out"
      return
    fi
  fi
  echo ""
}

# JSON escape helper to prevent injection
_json_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\r'/\\r}"
  s="${s//$'\t'/\\t}"
  echo "$s"
}

# Build AssignedTo string: ADO needs "Display Name <email>"
_ado_assignee_patch_value() {
  local email="${1:-}"
  email="${email//$'\r'/}"
  [[ -n "$email" ]] || return 0
  local name="${ADO_USER_NAME:-}"
  name="${name//$'\r'/}"
  if [[ -n "$name" ]]; then
    echo "${name} <${email}>"
    return 0
  fi
  if command -v node &>/dev/null && [[ -n "${ADO_ORG:-}" && -n "${ADO_PAT:-}" ]]; then
    local url="https://dev.azure.com/${ADO_ORG}/_apis/connectionData?api-version=7.0"
    local json
    json=$(curl -sS --connect-timeout "${SDLC_CONNECT_TIMEOUT:-15}" --max-time "${SDLC_MAXTIME:-60}" -u ":${ADO_PAT}" "$url" 2>/dev/null) || true
    local dn
    dn=$(printf '%s' "$json" | node -e '
const fs=require("fs"); let d,t=""; try { d=JSON.parse(fs.readFileSync(0,"utf8")); } catch(e){ process.exit(1); }
const u=d.authenticatedUser; if(u){ t=u.providerDisplayName||u.customDisplayName||u.displayName||""; }
process.stdout.write(String(t).trim());
' 2>/dev/null) || true
    if [[ -n "$dn" ]]; then
      echo "${dn} <${email}>"
      return 0
    fi
  fi
  echo "$email"
}

# Convert markdown to HTML for ADO System.Description
# Uses cli/lib/markdown-to-html.js when node is available (paragraphs, lists, spacing).
<<<<<<< HEAD
=======
# If content already contains HTML tags (like <div>, <table>), returns as-is.
>>>>>>> 5a6d807 (Final commit of AI-SDLC Platform)
_markdown_to_html() {
  local md="$1"
  local html
  local _md_js="${PLATFORM_DIR}/cli/lib/markdown-to-html.js"

<<<<<<< HEAD
=======
  # Check if content is already HTML (contains <div> or <table> or <p> tags)
  if echo "$md" | grep -qE '<(div|table|p|h[1-6]|ul|ol|li|span|br)' ; then
    # Content is already HTML, return as-is but ensure proper wrapping
    if ! echo "$md" | grep -q '^<div' ; then
      # Wrap in div if not already wrapped
      echo "<div style=\"font-family:Segoe UI,sans-serif;\">$md</div>"
    else
      echo "$md"
    fi
    return 0
  fi

>>>>>>> 5a6d807 (Final commit of AI-SDLC Platform)
  if command -v node &>/dev/null && [[ -f "$_md_js" ]]; then
    html=$(printf '%s' "$md" | node "$_md_js" 2>/dev/null) || true
    if [[ -n "$html" ]]; then
      echo "$html"
      return 0
    fi
  fi

  # Fallback: escape + line breaks (no node)
  html="$md"
  html="${html//\&/\&amp;}"
  html="${html//</\&lt;}"
  html="${html//>/\&gt;}"
  html=$(printf '%s' "$html" | sed 's/$/<br\/>/' | tr -d '\n')
<<<<<<< HEAD
  echo "<div style=\"line-height:1.5;\">$html</div>"
}

# Split story markdown into title, description, acceptance criteria
_parse_story_file() {
  local file="$1"
  local title="" desc="" criteria=""
=======
  echo "<div style=\"font-family:Segoe UI,sans-serif;\">$html</div>"
}

# Split story markdown into title, description, acceptance criteria
# Extracts both HTML sections separately for ADO System.Description and Microsoft.VSTS.Common.AcceptanceCriteria
_parse_story_file() {
  local file="$1"
  local title="" desc="" criteria="" desc_html="" ac_html=""
>>>>>>> 5a6d807 (Final commit of AI-SDLC Platform)

  if [[ ! -f "$file" ]]; then
    return 1
  fi

  # Extract title (first # heading)
  title=$(grep -m1 '^#' "$file" | sed 's/^#\s*//' | sed 's/#\s*$//')

<<<<<<< HEAD
  # Extract description (between title and "## … Acceptance Criteria" — keep blank lines for readable HTML)
  desc=$(sed -n '/^#[^#]/,/^## .*Acceptance Criteria/p' "$file" | sed '1d;$d')

  # Extract acceptance criteria (section after "## … Acceptance Criteria")
  criteria=$(sed -n '/^## .*Acceptance Criteria/,$p' "$file" | sed '1d')

  echo "$title"
  [[ -n "$desc" ]] && echo "---DESC---"
  echo "$desc"
  [[ -n "$criteria" ]] && echo "---CRITERIA---"
  echo "$criteria"
=======
  # Check for new format: ## HTML Formatting for ADO with separate Description and AC sections
  if grep -q "### Description (System.Description field)" "$file"; then
    # Extract Description HTML (between ### Description and ### Acceptance Criteria or ---)
    desc_html=$(sed -n '/### Description (System.Description field)/,/### Acceptance Criteria/p' "$file" | \
                sed '1d;$d' | \
                sed '/^---$/d' | \
                sed '/^$/N;/^\n$/d')
    
    # Extract Acceptance Criteria HTML (between ### Acceptance Criteria and end of file or next ---)
    ac_html=$(sed -n '/### Acceptance Criteria (Microsoft.VSTS.Common.AcceptanceCriteria field)/,/^---$/p' "$file" | \
              sed '1d;$d' | \
              sed '/^---$/d' | \
              sed '/^$/N;/^\n$/d')
  
  # Check for old format: ## HTML Formatting for ADO Description (single section)
  elif grep -q "## HTML Formatting for ADO Description" "$file"; then
    # Extract HTML section (from <div> to </div>)
    desc_html=$(sed -n '/## HTML Formatting for ADO Description/,/^---$/p' "$file" | \
                   grep -v "^## HTML Formatting" | \
                   grep -v "^---$" | \
                   sed '/^$/N;/^\n$/d' | \
                   sed '1{/^$/d}')
    
    # Also extract markdown acceptance criteria for AC field
    ac_html=$(sed -n '/^## .*Acceptance Criteria/,/^## /p' "$file" | sed '1d;$d')
  fi

  # If no HTML sections found, fall back to markdown extraction
  if [[ -z "$desc_html" ]]; then
    desc=$(sed -n '/^#[^#]/,/^## .*Acceptance Criteria/p' "$file" | sed '1d;$d')
    ac_html=$(sed -n '/^## .*Acceptance Criteria/,/^## /p' "$file" | sed '1d;$d')
  fi

  echo "$title"
  if [[ -n "$desc_html" ]]; then
    echo "---DESC_HTML---"
    echo "$desc_html"
  elif [[ -n "$desc" ]]; then
    echo "---DESC---"
    echo "$desc"
  fi
  
  if [[ -n "$ac_html" ]]; then
    echo "---AC_HTML---"
    echo "$ac_html"
  fi
>>>>>>> 5a6d807 (Final commit of AI-SDLC Platform)
}

# ============================================================================
# ADO FIELD REGISTRY & COLLECTION
# ============================================================================

# Load field registry from template file
_ado_load_field_registry() {
  local registry_file="${PLATFORM_DIR}/templates/ado-field-registry.sh"
  if [[ -f "$registry_file" ]]; then
    source "$registry_file"
  fi
}

# Check if running in TTY (interactive terminal)
_is_tty() {
  [[ -t 0 ]] && return 0
  return 1
}

# Prompt user for a field value (TTY or structured output for non-TTY)
_ado_prompt_field() {
  local field_name="$1"
  local display_name="$2"
  local allowed_values="$3"  # semicolon-separated
  local default_value="${4:-}"

  if _is_tty; then
    # Interactive TTY mode
    if [[ -n "$allowed_values" ]]; then
      log_info "Missing mandatory field: $display_name"
      log_info "Allowed values:"
      local i=1
      local IFS=';'
      for val in $allowed_values; do
        printf '  %d) %s\n' "$i" "$val" >&2
        ((i++))
      done
      read -rp "Enter choice (1-$((i-1))): " choice
      local j=1
      for val in $allowed_values; do
        if [[ "$j" == "$choice" ]]; then
          echo "$val"
          return 0
        fi
        ((j++))
      done
      return 1
    else
      read -rp "Enter value for $display_name [default: $default_value]: " value
      echo "${value:-$default_value}"
      return 0
    fi
  else
    # Non-TTY: structured prompt for IDE/agent
    if [[ -n "$allowed_values" ]]; then
      log_info "[SDLC_ASK_USER] Missing mandatory ADO field: $field_name"
      log_info "[SDLC_ASK_USER] Display name: $display_name"
      log_info "[SDLC_ASK_USER] Allowed values: $allowed_values"
    else
      log_info "[SDLC_ASK_USER] Missing mandatory ADO field: $field_name"
      log_info "[SDLC_ASK_USER] Display name: $display_name"
      if [[ -n "$default_value" ]]; then
        log_info "[SDLC_ASK_USER] Default: $default_value"
      fi
    fi
    log_info "[SDLC_ASK_USER] Please provide value (as environment variable or re-run with appropriate --flag):"
    return 1
  fi
}

# Collect mandatory fields for a work item type
_ado_collect_fields() {
  local wi_type="$1"
  local collected_fields_var="${2:-_ADO_COLLECTED}"

  _ado_load_field_registry

  declare -gA "$collected_fields_var"

  case "$wi_type" in
    Feature)
      # Feature mandatory fields
      _ado_collect_field_value "$collected_fields_var" "Custom.AnalyticsFunnel" \
        "Analytics Funnel" "Yes;No" "$ADO_FEATURE_ANALYTICS_FUNNEL" || return 1
      _ado_collect_field_value "$collected_fields_var" "Custom.FirebaseConfigRequired" \
        "Firebase Config Required" "Yes;No" "$ADO_FEATURE_FIREBASE_CONFIG_REQUIRED" || return 1
      _ado_collect_field_value "$collected_fields_var" "Custom.SuccessCriteria" \
        "Success Criteria" "" "$ADO_FEATURE_SUCCESS_CRITERIA" || return 1
      _ado_collect_field_value "$collected_fields_var" "System.AreaPath" \
        "Area Path" "" "${ADO_WI_AREA_PATH:-YourAzureProject\\POD 1}" || return 1
      _ado_collect_field_value "$collected_fields_var" "System.IterationPath" \
        "Iteration Path" "" "${ADO_WI_ITERATION_PATH:-YourAzureProject\\Sprint 1}" || return 1
      ;;
    "User Story")
<<<<<<< HEAD
      # User Story mandatory fields (see templates/ado-field-registry.sh)
      _ado_collect_field_value "$collected_fields_var" "System.AreaPath" \
        "Area Path" "" "${ADO_WI_AREA_PATH:-YourAzureProject\\POD 1}" || return 1
      _ado_collect_field_value "$collected_fields_var" "System.IterationPath" \
        "Iteration Path" "" "${ADO_WI_ITERATION_PATH:-YourAzureProject\\Sprint 1}" || return 1
      _ado_collect_field_value "$collected_fields_var" "System.AssignedTo" \
        "Assigned To" "" "$(_ado_assignee_patch_value "${ADO_USER_EMAIL:-}")" || return 1
      _ado_collect_field_value "$collected_fields_var" "Custom.Dependency" \
        "Dependency" "Android;Server;Web" "${ADO_WI_DEPENDENCY:-Android}" || return 1
      _ado_collect_field_value "$collected_fields_var" "Custom.UserstorySource" \
        "Userstory Source" "" "${ADO_WI_USERSTORY_SOURCE:-Product Backlog}" || return 1
      _ado_collect_field_value "$collected_fields_var" "Custom.ApplicationPlatform" \
        "Application platform" "Android;Database;Devops;Server;Web" "${ADO_WI_PLATFORM:-Android}" || return 1
=======
      # User Story mandatory fields - ALWAYS prompt user for input
      log_section "User Story Field Input"
      log_info "Please provide values for the following required fields:"
      echo ""

      _ado_collect_field_value "$collected_fields_var" "System.AreaPath" \
        "Area Path" "" "${ADO_WI_AREA_PATH:-YourProject}" || return 1
      _ado_collect_field_value "$collected_fields_var" "System.IterationPath" \
        "Iteration Path" "" "${ADO_WI_ITERATION_PATH:-YourProject}" || return 1
      _ado_collect_field_value "$collected_fields_var" "System.AssignedTo" \
        "Assigned To" "" "$(_ado_assignee_patch_value "${ADO_USER_EMAIL:-}")" || return 1

      # Project-specific required fields - User must explicitly select values
      echo ""
      log_info "Project Custom Fields:"
      echo ""

      # Dependency - Single select
      _ado_collect_field_value "$collected_fields_var" "Dependency" \
        "Dependency" "Android;Server;Web" "${ADO_WI_DEPENDENCY:-}" || return 1

      # Userstory Source - Free text with default
      _ado_collect_field_value "$collected_fields_var" "Userstory Source" \
        "Userstory Source" "" "${ADO_WI_USERSTORY_SOURCE:-Product Backlog}" || return 1

      # Platform - Single select (can be extended to multi-select if needed)
      _ado_collect_field_value "$collected_fields_var" "Platform" \
        "Platform" "Android;Database;Devops;Server;Web" "${ADO_WI_PLATFORM:-}" || return 1
>>>>>>> 5a6d807 (Final commit of AI-SDLC Platform)
      ;;
    Task)
      # Task mandatory fields (process may require Assigned To + Platform — see ado-field-registry.sh)
      _ado_collect_field_value "$collected_fields_var" "System.AreaPath" \
        "Area Path" "" "${ADO_WI_AREA_PATH:-YourAzureProject\\POD 1}" || return 1
      _ado_collect_field_value "$collected_fields_var" "System.IterationPath" \
        "Iteration Path" "" "${ADO_WI_ITERATION_PATH:-YourAzureProject\\Sprint 1}" || return 1
      _ado_collect_field_value "$collected_fields_var" "System.AssignedTo" \
        "Assigned To" "" "$(_ado_assignee_patch_value "${ADO_USER_EMAIL:-}")" || return 1
      _ado_collect_field_value "$collected_fields_var" "Custom.ApplicationPlatform" \
        "Application platform" "Android;Database;Devops;Server;Web" "${ADO_WI_PLATFORM:-Android}" || return 1
      ;;
    Bug)
      # Bug mandatory fields
      _ado_collect_field_value "$collected_fields_var" "System.AreaPath" \
        "Area Path" "" "${ADO_WI_AREA_PATH:-YourAzureProject\\POD 1}" || return 1
      _ado_collect_field_value "$collected_fields_var" "System.IterationPath" \
        "Iteration Path" "" "${ADO_WI_ITERATION_PATH:-YourAzureProject\\Sprint 1}" || return 1
      ;;
  esac

  return 0
}

<<<<<<< HEAD
# Collect a single field value, prompting if necessary
=======
# Collect a single field value, ALWAYS prompting user for input in interactive mode
# This ensures user explicitly selects values rather than using env defaults
>>>>>>> 5a6d807 (Final commit of AI-SDLC Platform)
_ado_collect_field_value() {
  local arr_var="$1"
  local field_id="$2"
  local display_name="$3"
  local allowed_values="$4"
<<<<<<< HEAD
  local env_value="${5:-}"

  if [[ -n "$env_value" ]]; then
    eval "${arr_var}[$field_id]='$env_value'"
    return 0
  fi

  # Field not in env, prompt user
  local user_value
  user_value=$(_ado_prompt_field "$field_id" "$display_name" "$allowed_values" "$env_value") || {
    if ! _is_tty; then
      # Non-TTY and user can't respond; set to empty and continue
      return 0
    fi
    return 1
  }

  eval "${arr_var}[$field_id]='$user_value'"
=======
  local default_value="${5:-}"

  # Always prompt user when in interactive mode (TTY)
  if _is_tty; then
    local user_value
    user_value=$(_ado_prompt_field_interactive "$field_id" "$display_name" "$allowed_values" "$default_value") || {
      log_error "Failed to collect value for $display_name"
      return 1
    }
    eval "${arr_var}[$field_id]='$user_value'"
    return 0
  else
    # Non-TTY: use default value if provided
    if [[ -n "$default_value" ]]; then
      eval "${arr_var}[$field_id]='$default_value'"
      return 0
    fi
    # Cannot prompt and no default - fail
    log_error "Cannot prompt for $display_name in non-interactive mode"
    return 1
  fi
}

# Interactive prompt for single-select fields with numbered choices
_ado_prompt_field_interactive() {
  local field_name="$1"
  local display_name="$2"
  local allowed_values="$3"  # semicolon-separated
  local default_value="${4:-}"

  log_section "Input Required: $display_name"

  if [[ -n "$allowed_values" ]]; then
    # Single-select from predefined options
    log_info "Please select a value for: $display_name"
    echo ""

    local i=1
    local IFS=';'
    local options=()

    for val in $allowed_values; do
      options+=("$val")
      if [[ "$val" == "$default_value" ]]; then
        printf '  [%d] %s (default)\n' "$i" "$val" >&2
      else
        printf '  [%d] %s\n' "$i" "$val" >&2
      fi
      ((i++))
    done

    echo ""
    read -rp "Enter choice number [1-$((i-1))]: " choice

    # Validate choice
    if [[ -z "$choice" ]] && [[ -n "$default_value" ]]; then
      echo "$default_value"
      return 0
    fi

    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [[ "$choice" -lt 1 ]] || [[ "$choice" -ge "$i" ]]; then
      log_error "Invalid choice: $choice"
      return 1
    fi

    echo "${options[$((choice-1))]}"
    return 0
  else
    # Free text input
    if [[ -n "$default_value" ]]; then
      read -rp "Enter value for $display_name [default: $default_value]: " value
      echo "${value:-$default_value}"
    else
      read -rp "Enter value for $display_name: " value
      if [[ -z "$value" ]]; then
        log_error "Value cannot be empty"
        return 1
      fi
      echo "$value"
    fi
    return 0
  fi
}

# Collect multiple values for fields that support multi-select
# Usage: _ado_collect_multi_select_field arr_var "field_id" "Display Name" "opt1;opt2;opt3" "default1;default2"
_ado_collect_multi_select_field() {
  local arr_var="$1"
  local field_id="$2"
  local display_name="$3"
  local allowed_values="$4"
  local default_values="${5:-}"

  if ! _is_tty; then
    # Non-TTY: use defaults
    if [[ -n "$default_values" ]]; then
      eval "${arr_var}[$field_id]='$default_values'"
      return 0
    fi
    log_error "Cannot multi-select in non-interactive mode without defaults"
    return 1
  fi

  log_section "Multi-Select Input: $display_name"
  log_info "Select one or more options (comma-separated numbers, e.g., 1,3,5)"
  echo ""

  local i=1
  local IFS=';'
  local options=()

  for val in $allowed_values; do
    options+=("$val")
    printf '  [%d] %s\n' "$i" "$val" >&2
    ((i++))
  done

  echo ""
  read -rp "Enter choices [1-$((i-1))]: " choices

  if [[ -z "$choices" ]]; then
    log_error "At least one selection required"
    return 1
  fi

  # Parse comma-separated choices
  local selected_values=""
  local IFS=','
  for choice in $choices; do
    choice=$(echo "$choice" | tr -d ' ')  # trim whitespace
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [[ "$choice" -lt 1 ]] || [[ "$choice" -ge "$i" ]]; then
      log_error "Invalid choice: $choice"
      return 1
    fi
    if [[ -n "$selected_values" ]]; then
      selected_values="${selected_values};"
    fi
    selected_values="${selected_values}${options[$((choice-1))]}"
  done

  eval "${arr_var}[$field_id]='$selected_values'"
  log_success "Selected: $selected_values"
>>>>>>> 5a6d807 (Final commit of AI-SDLC Platform)
  return 0
}

# ============================================================================
# ADO PREVIEW & CONFIRMATION
# ============================================================================

# Non-interactive ADO creates require explicit opt-in: --yes on the command or SDLC_ADO_CONFIRM=yes.
_ado_preview_and_confirm() {
  local wi_type="$1"
  local title="$2"
  local parent_id="${3:-}"
  local description="${4:-}"
  declare -n fields_ref="$5"
  local assume_yes="${6:-0}"

  if _is_tty; then
    # Interactive TTY confirmation
    log_section "Preview Work Item"
    log_info "Type: $wi_type"
    log_info "Title: $title"
    if [[ -n "$parent_id" ]]; then
      log_info "Parent: $parent_id"
    fi
    for field in "${!fields_ref[@]}"; do
      log_info "$field: ${fields_ref[$field]}"
    done
    if [[ -n "$description" ]]; then
      local desc_len=${#description}
      log_info "Description: [$desc_len chars]"
    fi

    read -rp "Create this work item? [y/n/edit]: " confirm
    case "$confirm" in
      y|Y|yes|YES) return 0 ;;
      n|N|no|NO) return 1 ;;
      edit|e|E)
        log_info "Edit functionality not yet implemented. Aborting."
        return 1
        ;;
      *) log_error "Invalid response"; return 1 ;;
    esac
  else
    # Non-TTY: refuse to POST unless user explicitly opted in (automation/CI safety)
    log_info "[SDLC_CONFIRM] About to create ADO work item:"
    log_info "[SDLC_CONFIRM] Type: $wi_type"
    log_info "[SDLC_CONFIRM] Title: $title"
    if [[ -n "$parent_id" ]]; then
      log_info "[SDLC_CONFIRM] Parent: $parent_id"
    fi
    for field in "${!fields_ref[@]}"; do
      local val="${fields_ref[$field]}"
      if [[ ${#val} -gt 60 ]]; then
        val="${val:0:57}..."
      fi
      log_info "[SDLC_CONFIRM] $field: $val"
    done
    if [[ -n "$description" ]]; then
      local desc_len=${#description}
      log_info "[SDLC_CONFIRM] Description: [$desc_len chars]"
    fi
    if [[ "$assume_yes" == "1" ]] || [[ "${SDLC_ADO_CONFIRM:-}" == "yes" ]]; then
      log_info "[SDLC_CONFIRM] Non-interactive create allowed (--yes or SDLC_ADO_CONFIRM=yes)."
      return 0
    fi
    log_error "[SDLC_CONFIRM] Refusing to create ADO work item in non-interactive mode without explicit confirmation."
    log_info "  Pass --yes to sdlc ado create or sdlc ado push-story, or set: export SDLC_ADO_CONFIRM=yes"
    return 1
  fi
}

# ============================================================================
# ADO FAILURE HANDLING
# ============================================================================

_ado_handle_failure() {
  local http_code="$1"
  local response="$2"
  local field_name="${3:-unknown}"

  if _is_tty; then
    log_error "ADO creation failed: HTTP $http_code"
    if [[ -n "$response" ]]; then
      local msg=$(echo "$response" | grep -o '"message":"[^"]*"' | head -1 | cut -d'"' -f4)
      if [[ -n "$msg" ]]; then
        log_error "Message: $msg"
      fi
    fi

    log_info "Options:"
    log_info "  1) Retry with modified fields"
    log_info "  2) Save to file and abort"
    log_info "  3) Abort"
    read -rp "Choose option (1-3): " opt

    case "$opt" in
      1) return 0 ;;  # Caller will retry
      2) return 2 ;;  # Save to file
      3) return 1 ;;  # Abort
      *) log_error "Invalid choice"; return 1 ;;
    esac
  else
    log_error "[SDLC_ASK_USER] ADO creation failed: HTTP $http_code"
    if [[ -n "$response" ]]; then
      local msg=$(echo "$response" | grep -o '"message":"[^"]*"' | head -1 | cut -d'"' -f4)
      if [[ -n "$msg" ]]; then
        log_error "[SDLC_ASK_USER] Message: $msg"
      fi
    fi
    log_error "[SDLC_ASK_USER] Options: 1) retry, 2) save and abort, 3) abort"
    return 1
  fi
}

# ============================================================================
# ADO COMMANDS
# ============================================================================

# Search ADO work items using WIQL
_ado_search() {
  local query="${1:-}"
  local top="${2:-20}"

  if [[ -z "$query" ]]; then
    log_info "Usage: sdlc ado search <query|filter> [--top N]"
    log_info ""
    log_info "Examples:"
    log_info "  sdlc ado search \"Family Hub\"              # Text search in title"
    log_info "  sdlc ado search \"state=Active\"            # State filter"
    log_info "  sdlc ado search \"type=Feature\"            # Type filter"
    log_info "  sdlc ado search \"assignedTo=me\"           # My work items"
    log_info "  sdlc ado search \"Family Hub\" --top 5     # Limit results"
    return 0
  fi

  # Parse options
  local search_text=""
  local work_item_type=""
  local state=""
  local assigned_to=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --top)
        top="$2"
        shift 2
        ;;
      *)
        if [[ -z "$search_text" ]]; then
          # Parse filter syntax
          if [[ "$1" =~ ^state=(.+)$ ]]; then
            state="${BASH_REMATCH[1]}"
          elif [[ "$1" =~ ^type=(.+)$ ]]; then
            work_item_type="${BASH_REMATCH[1]}"
          elif [[ "$1" =~ ^assignedTo=(.+)$ ]]; then
            assigned_to="${BASH_REMATCH[1]}"
          else
            search_text="$1"
          fi
        fi
        shift
        ;;
    esac
  done

  # Build WIQL query
  local fields="System.Id,System.Title,System.WorkItemType,System.State,System.AssignedTo,System.ChangedDate"
  local conditions=()

  # Project filter
  conditions+=("[System.TeamProject] = '$ADO_PROJECT'")

  # Text search
  if [[ -n "$search_text" ]]; then
    local escaped_text="${search_text//\'/\'\'}"
    conditions+=("[System.Title] EVER CONTAINS '$escaped_text'")
  fi

  # Type filter
  if [[ -n "$work_item_type" ]]; then
    conditions+=("[System.WorkItemType] = '$work_item_type'")
  fi

  # State filter
  if [[ -n "$state" ]]; then
    conditions+=("[System.State] = '$state'")
  fi

  # Assigned to filter
  if [[ -n "$assigned_to" ]]; then
    if [[ "$assigned_to" == "me" ]]; then
      conditions+=("[System.AssignedTo] = @Me")
    else
      conditions+=("[System.AssignedTo] CONTAINS '$assigned_to'")
    fi
  fi

  # Combine conditions
  local where_clause=""
  for condition in "${conditions[@]}"; do
    if [[ -z "$where_clause" ]]; then
      where_clause="$condition"
    else
      where_clause="$where_clause AND $condition"
    fi
  done

  local wiql="SELECT [$fields] FROM workitems WHERE $where_clause ORDER BY [System.ChangedDate] DESC"

  log_info "Searching: $wiql"

  # Execute WIQL query
  local api_url="https://dev.azure.com/${ADO_ORG}/${ADO_PROJECT}/_apis/wit/wiql?api-version=7.0"
  local auth="$(echo -n ":$ADO_PAT" | base64 -w 0 2>/dev/null || echo -n ":$ADO_PAT" | base64)"
  local query_body="{\"query\": \"$wiql\"}"

  local response
  response=$(curl -sS -X POST \
    -H "Content-Type: application/json" \
    -H "Authorization: Basic $auth" \
    -d "$query_body" \
    "$api_url" 2>&1) || {
    log_error "Query failed: $response"
    return 1
  }

  # Check for errors
  if echo "$response" | grep -q '"message"' 2>/dev/null; then
    local error_msg=$(echo "$response" | _ado_json_field "." "message" 2>/dev/null || echo "Unknown error")
    log_error "ADO API error: $error_msg"
    return 1
  fi

  # Extract work item IDs
  local work_item_ids
  work_item_ids=$(echo "$response" | jq -r '.workItems[].id' 2>/dev/null | head -n "$top" | tr '\n' ',' | sed 's/,$//')

  if [[ -z "$work_item_ids" ]]; then
    log_warn "No work items found"
    return 0
  fi

  # Fetch full details
  local details_url="https://dev.azure.com/${ADO_ORG}/${ADO_PROJECT}/_apis/wit/workitems?ids=${work_item_ids}&fields=${fields}&api-version=7.0"
  local details_response
  details_response=$(curl -sS -H "Authorization: Basic $auth" "$details_url" 2>&1) || {
    log_error "Failed to fetch work item details"
    return 1
  }

  # Pretty print results
  log_section "ADO Search Results"
  echo "$details_response" | jq -r '.value[] |
    "\n┌─────────────────────────────────────────────────────────────┐\n" +
    "│ " + (.id|tostring) + " | " + (.fields["System.WorkItemType"] // "Unknown") +
    " | " + (.fields["System.State"] // "Unknown") + "\n" +
    "│ " + (.fields["System.Title"] // "No Title") + "\n" +
    "│ Assigned: " + ((.fields["System.AssignedTo"] // "Unassigned") | if type == "object" then .displayName else . end) + "\n" +
    "│ Updated: " + (.fields["System.ChangedDate"] // "N/A") + "\n" +
    "└─────────────────────────────────────────────────────────────┘"
  ' 2>/dev/null

  local count=$(echo "$details_response" | jq '.value | length' 2>/dev/null || echo "0")
  log_success "Found $count work item(s)"
}

# Get specific work item details (alias for show with better formatting)
_ado_get() {
  local work_item_id="${1:-}"

  if [[ -z "$work_item_id" ]]; then
    log_error "Usage: sdlc ado get <work-item-id>"
    return 1
  fi

  # Normalize ID
  work_item_id=$(_normalize_ado_wi_id "$work_item_id")

  # Fetch via existing _ado_show with better formatting
  local response
  response=$(_ado_curl -H "Authorization: Basic $(echo -n ":$ADO_PAT" | base64 -w 0 2>/dev/null || echo -n ":$ADO_PAT" | base64)" \
    "https://dev.azure.com/${ADO_ORG}/${ADO_PROJECT}/_apis/wit/workitems/${work_item_id}?api-version=7.0&\$expand=all" 2>&1)

  if [[ $? -ne 0 ]]; then
    log_error "Failed to fetch work item $work_item_id"
    return 1
  fi

  # Pretty print
  log_section "Work Item $work_item_id"

  local wi_type=$(echo "$response" | _ado_json_field "." "System.WorkItemType")
  local title=$(echo "$response" | _ado_json_field "." "System.Title")
  local state=$(echo "$response" | _ado_json_field "." "System.State")
  local assigned_to=$(echo "$response" | _ado_json_field "." "System.AssignedTo")
  local created_by=$(echo "$response" | _ado_json_field "." "System.CreatedBy")
  local created_date=$(echo "$response" | _ado_json_field "." "System.CreatedDate")
  local changed_date=$(echo "$response" | _ado_json_field "." "System.ChangedDate")

  # Handle display name extraction
  if [[ "$assigned_to" == *"displayName"* ]]; then
    assigned_to=$(echo "$assigned_to" | jq -r '.displayName' 2>/dev/null || echo "$assigned_to")
  fi
  if [[ "$created_by" == *"displayName"* ]]; then
    created_by=$(echo "$created_by" | jq -r '.displayName' 2>/dev/null || echo "$created_by")
  fi

  # Strip HTML from description
  local description=$(echo "$response" | _ado_json_field "." "System.Description" | sed 's/<[^>]*>//g' | head -c 300)

  echo ""
  echo "╔════════════════════════════════════════════════════════════════╗"
  echo "║  Type:      $wi_type"
  echo "║  State:     $state"
  echo "║  Title:     $title"
  echo "╠════════════════════════════════════════════════════════════════╣"
  echo "║  Assigned: ${assigned_to:-Unassigned}"
  echo "║  Created:  ${created_by:-Unknown}"
  echo "║  Date:     ${created_date:-N/A}"
  echo "╠════════════════════════════════════════════════════════════════╣"
  echo "║  Description:"
  echo "║  ${description:-No description}"
  if [[ ${#description} -ge 300 ]]; then
    echo "║  ... (truncated, use 'sdlc ado show $work_item_id' for full)"
  fi
  echo "╚════════════════════════════════════════════════════════════════╝"

  echo ""
  log_info "URL: https://dev.azure.com/${ADO_ORG}/${ADO_PROJECT}/_workitems/edit/${work_item_id}"
}

_ado_comment_cmd() {
  local wi_id="${1:-}"
  shift 2>/dev/null || true
  local text="$*"
  if [[ -z "$wi_id" ]] || [[ -z "$text" ]]; then
    log_error "Usage: sdlc ado comment <work-item-id> <message...>"
    return 1
  fi
  _ado_add_work_item_comment "$wi_id" "$text"
}

cmd_ado() {
  local subcmd="${1:-}"

  if [[ -z "$subcmd" ]]; then
    log_error "Usage: sdlc ado <command> [options]"
<<<<<<< HEAD
    log_info "Commands: create, list, show, update, link, link-pr, comment, description, push-story, sync, ..."
=======
    log_info "Commands: create, list, show, update, link, link-pr, comment, description, acceptance-criteria, push-story, sync, ..."
>>>>>>> 5a6d807 (Final commit of AI-SDLC Platform)
    return 1
  fi

  _context_guard false false false
  _load_env

  if [[ -z "$ADO_PAT" || -z "$ADO_ORG" || -z "$ADO_PROJECT" ]]; then
    log_error "Azure DevOps credentials not configured"
    log_info "Set ADO_PAT, ADO_ORG, ADO_PROJECT in ~/.sdlc/ado.env, ${PLATFORM_DIR}/env/.env, or app repo env/.env"
    log_hint "Copy env template, add PAT, then: sdlc doctor"
    log_recovery_footer
    return 1
  fi

  shift

  case "$subcmd" in
    create)      _ado_create "$@" ;;
    list)        _ado_list "$@" ;;
    show)        _ado_show "$@" ;;
    search)      _ado_search "$@" ;;
    get)         _ado_get "$@" ;;
    update)      _ado_update "$@" ;;
    link)        _ado_link "$@" ;;
    link-pr)     _ado_link_pr "$@" ;;
    comment)     _ado_comment_cmd "$@" ;;
    description) _ado_description_cmd "$@" ;;
    push-story)  _ado_push_story "$@" ;;
    sync)        _ado_sync "$@" ;;
    sync-from)   _ado_sync_from "$@" ;;
    sync-to)     _ado_sync_to "$@" ;;
    *)
      log_error "Unknown ADO command: $subcmd"
      log_info "Commands: create, list, show, search, get, update, link, link-pr, comment, description, push-story, sync, sync-from, sync-to"
      return 1
      ;;
  esac
}

# REWRITTEN: Single API call with all fields + parent link + description
_ado_create() {
  local type="$1"
  local title=""
  local parent=""
  local desc_file=""
  local ac_file=""
  local assume_yes=0

  if [[ -z "$type" ]]; then
    log_error "Usage: sdlc ado create <type> --title=\"...\" [--parent=ID] [--description-file=PATH] [--acceptance-criteria-file=PATH] [--template=tech-task] [--yes]"
    log_info "Types: epic, feature, story, task, bug, testcase, testplan"
    log_info "Non-interactive shells: add --yes or set SDLC_ADO_CONFIRM=yes before creating work items."
    return 1
  fi

  shift

  for arg in "$@"; do
    case "$arg" in
      --title=*) title="${arg#--title=}" ;;
      --parent=*) parent="${arg#--parent=}" ;;
      --description-file=*) desc_file="${arg#--description-file=}" ;;
      --acceptance-criteria-file=*) ac_file="${arg#--acceptance-criteria-file=}" ;;
      --template=tech-task) desc_file="${PLATFORM_DIR}/templates/tech-task-template.md" ;;
      --yes) assume_yes=1 ;;
      *) log_warn "Unknown flag: $arg" ;;
    esac
  done

  if [[ -n "$desc_file" ]] && [[ ! -f "$desc_file" ]]; then
    log_error "Description file not found: $desc_file"
    return 1
  fi

  if [[ -n "$ac_file" ]] && [[ ! -f "$ac_file" ]]; then
    log_error "Acceptance criteria file not found: $ac_file"
    return 1
  fi

  if [[ -z "$title" ]]; then
    log_error "Title is required (--title=\"...\")"
    return 1
  fi

  local wi_type=""
  case "$type" in
    epic)     wi_type="Epic" ;;
    feature)  wi_type="Feature" ;;
    story)    wi_type="User Story" ;;
    task)     wi_type="Task" ;;
    bug)      wi_type="Bug" ;;
    testcase) wi_type="Test Case" ;;
    testplan) wi_type="Test Plan" ;;
    *)
      log_error "Invalid type: $type"
      return 1
      ;;
  esac

  log_section "Creating ADO Work Item"
  log_info "Type:  $wi_type"
  log_info "Title: $title"
  if [[ -n "$parent" ]]; then log_info "Parent: $parent"; fi

  # Collect mandatory fields (interactive if needed)
  declare -A collected_fields
  if ! _ado_collect_fields "$wi_type" "collected_fields"; then
    log_error "Failed to collect mandatory fields"
    return 1
  fi

  # Build description HTML if description file provided
  local desc_html=""
  if [[ -n "$desc_file" ]]; then
    local desc_raw
    desc_raw=$(cat "$desc_file")
    desc_html=$(_markdown_to_html "$desc_raw")
  fi

  # Build acceptance criteria HTML if AC file provided
  local ac_html=""
  if [[ -n "$ac_file" ]]; then
    local ac_raw
    ac_raw=$(cat "$ac_file")
    ac_html=$(_markdown_to_html "$ac_raw")
  fi

  # Show preview and get confirmation
  _ado_preview_and_confirm "$wi_type" "$title" "$parent" "$desc_html" "collected_fields" "$assume_yes" || {
    log_info "Creation cancelled"
    return 1
  }

  # Build complete JSON patch (single API call)
  local body='['

  # Add title
  local escaped_title=$(_json_escape "$title")
  body+="{\"op\":\"add\",\"path\":\"/fields/System.Title\",\"value\":\"${escaped_title}\"}"

  # Add description if provided
  if [[ -n "$desc_html" ]]; then
    local esc_desc=$(_json_escape "$desc_html")
    body+=",{\"op\":\"add\",\"path\":\"/fields/System.Description\",\"value\":\"${esc_desc}\"}"
  fi

  # Add acceptance criteria if provided (using Microsoft.VSTS.Common.AcceptanceCriteria field)
  if [[ -n "$ac_html" ]]; then
    local esc_ac=$(_json_escape "$ac_html")
    body+=",{\"op\":\"add\",\"path\":\"/fields/Microsoft.VSTS.Common.AcceptanceCriteria\",\"value\":\"${esc_ac}\"}"
  fi

  # Add collected fields
  for field in "${!collected_fields[@]}"; do
    local val="${collected_fields[$field]}"
    local esc_val=$(_json_escape "$val")
    body+=",{\"op\":\"add\",\"path\":\"/fields/${field}\",\"value\":\"${esc_val}\"}"
  done

  # Add parent link if provided
  if [[ -n "$parent" ]]; then
    parent="$(_normalize_ado_wi_id "$parent")"
    body+=",{\"op\":\"add\",\"path\":\"/relations/-\",\"value\":{\"rel\":\"System.LinkTypes.Hierarchy-Reverse\",\"url\":\"https://dev.azure.com/${ADO_ORG}/${ADO_PROJECT}/_apis/wit/workitems/${parent}\"}}"
  fi

  body+=']'

  # Make single API call
  local wi_type_path="${wi_type// /%20}"
  local url="https://dev.azure.com/${ADO_ORG}/${ADO_PROJECT}/_apis/wit/workitems/\$${wi_type_path}?api-version=7.0"

  local body_file
  body_file="$(mktemp 2>/dev/null || echo "${TMPDIR:-/tmp}/sdlc-ado-create-$$.json")"
  printf '%s' "$body" >"$body_file"

  local response
  response=$(_ado_curl -X POST \
    -u ":${ADO_PAT}" \
    -H "Content-Type: application/json-patch+json" \
    --data-binary "@${body_file}" \
    "$url" 2>/dev/null) || true

  local wi_id=$(echo "$response" | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2)
  local http_code=$(echo "$response" | grep -o '"status":[0-9]*' | head -1 | cut -d: -f2)

  if [[ -n "$wi_id" ]]; then
    rm -f "$body_file" 2>/dev/null || true
    log_success "Work item created: $wi_id"
    echo "$wi_id"
    return 0
  else
    # Check for error response
    local error_code=""
    if echo "$response" | grep -q '"code"'; then
      error_code=$(echo "$response" | grep -o '"code":"[^"]*"' | head -1 | cut -d'"' -f4)
    fi

    log_error "Failed to create work item"
    log_info "Response: $response"

    # Call failure handler
    _ado_handle_failure "400" "$response" || {
      # Save JSON patch for later retry
      cp -f "$body_file" "${PLATFORM_DIR}/env/.last-ado-create.json" 2>/dev/null || true
      log_info "JSON patch saved to ${PLATFORM_DIR}/env/.last-ado-create.json for later retry"
    }

    rm -f "$body_file" 2>/dev/null || true
    return 1
  fi
}

_ado_list() {
  local wi_type=""
  local state=""

  for arg in "$@"; do
    case "$arg" in
      --type=*) wi_type="${arg#--type=}" ;;
      --state=*) state="${arg#--state=}" ;;
      *) log_warn "Unknown flag: $arg" ;;
    esac
  done

  local allowed_types="Epic|Feature|User Story|Task|Bug|Test Case|Test Plan|Issue|Code Review Request"
  if [[ -n "$wi_type" ]] && ! [[ "$wi_type" =~ ^($allowed_types)$ ]]; then
    log_error "Invalid work item type: $wi_type"
    log_info "Allowed types: Epic, Feature, User Story, Task, Bug, Test Case, Test Plan, Issue, Code Review Request"
    return 1
  fi

  local allowed_states="New|Active|Closed|Resolved|Removed|Done|In Progress|To Do"
  if [[ -n "$state" ]] && ! [[ "$state" =~ ^($allowed_states)$ ]]; then
    log_error "Invalid state: $state"
    log_info "Allowed states: New, Active, Closed, Resolved, Removed, Done, In Progress, To Do"
    return 1
  fi

  log_section "Listing ADO Work Items"

  local wiql="Select [System.Id], [System.Title], [System.State], [System.AssignedTo] From WorkItems"

  if [[ -n "$wi_type" ]]; then
    wiql+=" Where [System.WorkItemType] = '$wi_type'"
  fi

  if [[ -n "$state" ]]; then
    if [[ -n "$wi_type" ]]; then
      wiql+=" And [System.State] = '$state'"
    else
      wiql+=" Where [System.State] = '$state'"
    fi
  fi

  local url="https://dev.azure.com/${ADO_ORG}/${ADO_PROJECT}/_apis/wit/wiql?api-version=7.0"
  local query_json='{"query":"'"$wiql"'"}'

  local response
  response=$(_ado_curl -X POST \
    -u ":${ADO_PAT}" \
    -H "Content-Type: application/json" \
    -d "$query_json" \
    "$url" 2>/dev/null) || true

  echo "$response" | grep -o '"id":[0-9]*' | cut -d: -f2 | head -20 | while read -r id; do
    _ado_show "$id" | head -5
  done
}

_ado_show() {
  local wi_id
  wi_id="$(_normalize_ado_wi_id "${1:-}")"

  if [[ -z "$wi_id" ]] || [[ ! "$wi_id" =~ ^[0-9]+$ ]]; then
    log_error "Usage: sdlc ado show <id>"
    log_info "Examples: 851789  or  US-851789"
    return 1
  fi

  local url="https://dev.azure.com/${ADO_ORG}/${ADO_PROJECT}/_apis/wit/workitems/${wi_id}?api-version=7.0"

  printf '[sdlc] Fetching work item %s from dev.azure.com...\n' "$wi_id" >&2
  local response
  response=$(_ado_curl -u ":${ADO_PAT}" "$url") || true

  if [[ -z "$response" ]] || ! echo "$response" | grep -q '"id"'; then
    log_error "ADO returned no work item for id $wi_id (check org, project, PAT, or id)"
    if [[ -n "$response" ]]; then echo "$response" | head -c 400 >&2; fi
    return 1
  fi

  local title state type
  title=$(_ado_json_field "$response" "System.Title")
  state=$(_ado_json_field "$response" "System.State")
  type=$(_ado_json_field "$response" "System.WorkItemType")

  if [[ -z "$title" ]] && echo "$response" | grep -q '"message"'; then
    log_error "ADO API error for work item $wi_id"
    echo "$response" | sed -n 's/.*"message"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1 >&2
    return 1
  fi

  if [[ -z "$type" ]]; then type="(unknown)"; fi
  if [[ -z "$title" ]]; then title="(empty — check PAT/project or API response)"; fi
  if [[ -z "$state" ]]; then state="(unknown)"; fi

  printf '\n'
  printf 'Work item ID: %s\n' "$wi_id"
  printf 'Type:         %s\n' "$type"
  printf 'Title:        %s\n' "$title"
  printf 'State:        %s\n' "$state"
  printf '\n'
}

_ado_update() {
  local wi_id
  wi_id="$(_normalize_ado_wi_id "${1:-}")"
  local state=""
  local assigned_to=""

  if [[ -z "$wi_id" ]] || [[ ! "$wi_id" =~ ^[0-9]+$ ]]; then
    log_error "Usage: sdlc ado update <id> --state=<state> [--assigned-to=<email>]"
    return 1
  fi

  shift

  for arg in "$@"; do
    case "$arg" in
      --state=*) state="${arg#--state=}" ;;
      --assigned-to=*) assigned_to="${arg#--assigned-to=}" ;;
      *) log_warn "Unknown flag: $arg" ;;
    esac
  done

  if [[ -z "$state" && -z "$assigned_to" ]]; then
    log_error "At least one of --state=<state> or --assigned-to=<email> is required"
    return 1
  fi

  log_section "Updating ADO Work Item"
  log_info "ID:    $wi_id"
  [[ -n "$state" ]] && log_info "State: $state"
  [[ -n "$assigned_to" ]] && log_info "Assigned To: $assigned_to"

  local body='['
  local first=true
  if [[ -n "$state" ]]; then
    local escaped_state=$(_json_escape "$state")
    body+="{\"op\":\"add\",\"path\":\"/fields/System.State\",\"value\":\"${escaped_state}\"}"
    first=false
  fi
  if [[ -n "$assigned_to" ]]; then
    local at_val
    at_val=$(_ado_assignee_patch_value "$assigned_to")
    local esc_at=$(_json_escape "$at_val")
    [[ "$first" == false ]] && body+=","
    body+="{\"op\":\"add\",\"path\":\"/fields/System.AssignedTo\",\"value\":\"${esc_at}\"}"
    first=false
  fi
  body+=']'
  local url="https://dev.azure.com/${ADO_ORG}/${ADO_PROJECT}/_apis/wit/workitems/${wi_id}?api-version=7.0"

  local response
  response=$(_ado_curl -X PATCH \
    -u ":${ADO_PAT}" \
    -H "Content-Type: application/json-patch+json" \
    -d "$body" \
    "$url" 2>/dev/null) || true

  if echo "$response" | grep -q '"id"'; then
    log_success "Work item $wi_id updated"
  else
    log_error "Failed to update work item"
    log_info "Response: $response"
    return 1
  fi
}

_ado_link() {
  local wi_id
  wi_id="$(_normalize_ado_wi_id "${1:-}")"
  local parent=""

  if [[ -z "$wi_id" ]] || [[ ! "$wi_id" =~ ^[0-9]+$ ]]; then
    log_error "Usage: sdlc ado link <id> --parent=<parentId>"
    return 1
  fi

  shift

  for arg in "$@"; do
    case "$arg" in
      --parent=*) parent="${arg#--parent=}" ;;
      *) log_warn "Unknown flag: $arg" ;;
    esac
  done

  parent="$(_normalize_ado_wi_id "$parent")"

  if [[ -z "$parent" ]] || [[ ! "$parent" =~ ^[0-9]+$ ]]; then
    log_error "Parent ID is required (--parent=<parentId>)"
    return 1
  fi

  log_section "Linking ADO Work Items"
  log_info "Child:  $wi_id"
  log_info "Parent: $parent"

  local body='[{"op":"add","path":"/relations/-","value":{"rel":"System.LinkTypes.Hierarchy-Reverse","url":"https://dev.azure.com/'"${ADO_ORG}"'/'"${ADO_PROJECT}"'/_apis/wit/workitems/'"${parent}"'"}}]'
  local url="https://dev.azure.com/${ADO_ORG}/${ADO_PROJECT}/_apis/wit/workitems/${wi_id}?api-version=7.0"

  local response
  response=$(_ado_curl -X PATCH \
    -u ":${ADO_PAT}" \
    -H "Content-Type: application/json-patch+json" \
    -d "$body" \
    "$url") || true

  if echo "$response" | grep -q '"id"'; then
    log_success "Work item $wi_id linked to parent $parent"
  else
    log_warn "Link operation may have failed"
    log_info "Response: $response"
  fi
}

_ado_link_pr() {
  local pr_url="$1"
  local wi_id
  wi_id="$(_normalize_ado_wi_id "${2:-}")"

  if [[ -z "$pr_url" ]] || [[ -z "$wi_id" ]] || [[ ! "$wi_id" =~ ^[0-9]+$ ]]; then
    log_error "Usage: sdlc ado link-pr <pr-url> <work-item-id>"
    log_info "Example: sdlc ado link-pr https://github.com/org/repo/pull/123 AB#12345"
    return 1
  fi

  log_section "Linking PR to ADO Work Item"
  log_info "Work Item: $wi_id"
  log_info "PR URL:    $pr_url"

  local comment_text="PR linked: $pr_url"
  local escaped_text=$(_json_escape "$comment_text")

  # Post comment to work item
  local url="https://dev.azure.com/${ADO_ORG}/${ADO_PROJECT}/_apis/wit/workitems/${wi_id}/comments?api-version=7.0"

  local body='{"text":"'"$escaped_text"'"}'

  local response
  response=$(_ado_curl -X POST \
    -u ":${ADO_PAT}" \
    -H "Content-Type: application/json" \
    -d "$body" \
    "$url" 2>/dev/null) || true

  if echo "$response" | grep -q '"id"'; then
    log_success "PR linked to work item $wi_id"
    return 0
  else
    log_error "Failed to link PR to work item"
    log_info "Response: $response"
    return 1
  fi
}

# Post Discussion comment on work item (used by test-skip sync, automation)
_ado_add_work_item_comment() {
  local wi_id="$1"
  local text="$2"

  wi_id="$(_normalize_ado_wi_id "$wi_id")"
  if [[ -z "$wi_id" ]] || [[ ! "$wi_id" =~ ^[0-9]+$ ]]; then
    log_warn "Invalid work item id for ADO comment: $1"
    return 1
  fi

  _load_env
  if [[ -z "${ADO_PAT:-}" || -z "${ADO_ORG:-}" || -z "${ADO_PROJECT:-}" ]]; then
    log_warn "ADO not configured — skipping work item comment (set env/.env)"
    return 1
  fi

  local escaped
  escaped=$(_json_escape "$text")
  local url="https://dev.azure.com/${ADO_ORG}/${ADO_PROJECT}/_apis/wit/workitems/${wi_id}/comments?api-version=7.0"
  local body='{"text":"'"$escaped"'"}'
  local response
  response=$(_ado_curl -X POST \
    -u ":${ADO_PAT}" \
    -H "Content-Type: application/json" \
    -d "$body" \
    "$url" 2>/dev/null) || true

  if echo "$response" | grep -q '"id"'; then
    log_success "Posted comment to ADO work item #$wi_id"
    return 0
  fi
  log_warn "Could not post ADO comment on #$wi_id"
  return 1
}

# REWRITTEN: Parse story file and extract sections
_ado_push_story() {
  local story_file=""
  local parent=""
  local assume_yes=0
  local create_type="story" # story|feature|epic → User Story|Feature|Epic via _ado_create

  for arg in "$@"; do
    case "$arg" in
      --parent=*)
        parent="${arg#--parent=}"
        ;;
      --type=*)
        create_type="${arg#--type=}"
        create_type=$(printf '%s' "$create_type" | tr '[:upper:]' '[:lower:]')
        ;;
      --yes)
        assume_yes=1
        ;;
      *)
        if [[ -z "$story_file" ]]; then
          story_file="$arg"
        else
          log_warn "Ignoring unexpected argument: $arg"
        fi
        ;;
    esac
  done

  case "$create_type" in
    story|feature|epic) ;;
    *)
      log_error "Invalid --type: $create_type (use: story, feature, or epic)"
      return 1
      ;;
  esac

  if [[ -z "$story_file" ]]; then
    log_error "Usage: sdlc ado push-story <file.md> [--parent=<workItemId>] [--type=story|feature|epic] [--yes]"
    log_info "Default --type=story (User Story). Use --type=feature for master-story-template.md → ADO Feature."
    log_info "Non-interactive: add --yes or set SDLC_ADO_CONFIRM=yes (same as sdlc ado create)."
    log_info "Example: sdlc ado push-story ./stories/SS-foo.md --parent=863476"
    log_info "Example: sdlc ado push-story ./stories/MS-foo.md --type=feature --yes"
    return 1
  fi

  if [[ ! -f "$story_file" ]]; then
    log_error "File not found: $story_file"
    return 1
  fi

  log_section "Pushing markdown to ADO"
  log_info "File: $story_file"
  log_info "Work item type: $create_type (via _ado_create)"
  if [[ -n "$parent" ]]; then
    log_info "Parent: $parent (child link)"
  fi

  # Parse story file
  local parsed
  parsed=$(_parse_story_file "$story_file")

  local title=$(echo "$parsed" | head -1)
  local desc_section=""
<<<<<<< HEAD
  local criteria_section=""

  if echo "$parsed" | grep -q "^---DESC---"; then
    desc_section=$(echo "$parsed" | sed -n '/^---DESC---/,/^---CRITERIA---/p' | sed '1d;$d')
  fi

  if echo "$parsed" | grep -q "^---CRITERIA---"; then
    criteria_section=$(echo "$parsed" | sed -n '/^---CRITERIA---/,$p' | sed '1d')
=======
  local desc_html=""
  local ac_html=""

  # Check for new format: separate Description HTML and AC HTML
  if echo "$parsed" | grep -q "^---DESC_HTML---"; then
    desc_html=$(echo "$parsed" | sed -n '/^---DESC_HTML---/,/^---AC_HTML---/p' | sed '1d;$d')
    log_info "Using pre-formatted HTML for Description"
  elif echo "$parsed" | grep -q "^---DESC---"; then
    desc_section=$(echo "$parsed" | sed -n '/^---DESC---/,/^---AC_HTML---/p' | sed '1d;$d')
  fi

  # Extract Acceptance Criteria HTML
  if echo "$parsed" | grep -q "^---AC_HTML---"; then
    ac_html=$(echo "$parsed" | sed -n '/^---AC_HTML---/,$p' | sed '1d')
    log_info "Using pre-formatted HTML for Acceptance Criteria"
>>>>>>> 5a6d807 (Final commit of AI-SDLC Platform)
  fi

  if [[ -z "$title" ]]; then
    log_error "No title found in story file (expected: # Title)"
    return 1
  fi

  log_info "Title: $title"

<<<<<<< HEAD
  # Create temporary description file (description only, AC goes to separate field)
  local temp_desc
  temp_desc="$(mktemp 2>/dev/null || echo "${TMPDIR:-/tmp}/sdlc-story-desc-$$.md")"
  {
    if [[ -n "$desc_section" ]]; then
=======
  # Create temporary description file (HTML preferred, fallback to markdown)
  local temp_desc
  temp_desc="$(mktemp 2>/dev/null || echo "${TMPDIR:-/tmp}/sdlc-story-desc-$$.md")"
  {
    if [[ -n "$desc_html" ]]; then
      # Use pre-formatted HTML directly
      echo "$desc_html"
    elif [[ -n "$desc_section" ]]; then
>>>>>>> 5a6d807 (Final commit of AI-SDLC Platform)
      echo "$desc_section"
    fi
  } > "$temp_desc"

  # Create temporary acceptance criteria file
  local temp_ac=""
<<<<<<< HEAD
  if [[ -n "$criteria_section" ]]; then
    temp_ac="$(mktemp 2>/dev/null || echo "${TMPDIR:-/tmp}/sdlc-story-ac-$$.md")"
    echo "$criteria_section" > "$temp_ac"
=======
  if [[ -n "$ac_html" ]]; then
    temp_ac="$(mktemp 2>/dev/null || echo "${TMPDIR:-/tmp}/sdlc-story-ac-$$.md")"
    echo "$ac_html" > "$temp_ac"
    log_info "Acceptance Criteria HTML captured"
>>>>>>> 5a6d807 (Final commit of AI-SDLC Platform)
  fi

  # Create work item with description and acceptance criteria
  local wi_id
  local create_args=("$create_type" "--title=$title" "--description-file=$temp_desc")
  if [[ -n "$temp_ac" ]]; then
    create_args+=("--acceptance-criteria-file=$temp_ac")
  fi
  if [[ -n "$parent" ]]; then
    create_args+=("--parent=$parent")
  fi
  if [[ "$assume_yes" -eq 1 ]]; then
    create_args+=("--yes")
  fi
  wi_id=$(_ado_create "${create_args[@]}") || {
    rm -f "$temp_desc" "$temp_ac" 2>/dev/null || true
    return 1
  }

  rm -f "$temp_desc" "$temp_ac" 2>/dev/null || true

  log_success "Work item created in ADO: $wi_id"
  echo "$wi_id"
}

# DEPRECATED: Use _ado_create with --description-file instead
_ado_set_description() {
  local wi_id="$1"
  local file="$2"
  wi_id="$(_normalize_ado_wi_id "$wi_id")"
  if [[ -z "$wi_id" ]] || [[ ! "$wi_id" =~ ^[0-9]+$ ]]; then
    log_error "Usage: sdlc ado description <id> --file=</path/to/file.md>"
    return 1
  fi
  if [[ -z "$file" ]] || [[ ! -f "$file" ]]; then
    log_error "Readable file required for System.Description"
    return 1
  fi

  log_section "Updating work item description"
  log_info "ID: $wi_id"
  log_info "File: $file"

  if ! command -v node &>/dev/null; then
    log_error "Node.js is required for ado description (markdown → HTML → JSON patch)"
    return 1
  fi

  local patch_js="${PLATFORM_DIR}/cli/lib/build-description-patch.js"
  if [[ ! -f "$patch_js" ]]; then
    log_error "Missing ${patch_js}"
    return 1
  fi

  local tmp
  tmp=$(mktemp 2>/dev/null || echo "${TMPDIR:-/tmp}/sdlc-ado-desc-$$.json")

  local url="https://dev.azure.com/${ADO_ORG}/${ADO_PROJECT}/_apis/wit/workitems/${wi_id}?api-version=7.0"

  _ado_patch_desc_to_file() {
    local op="${1:-replace}"
    rm -f "$tmp"
<<<<<<< HEAD
    SDL_DESC_PATCH_OP="$op" cat "$file" | node "$patch_js" >"$tmp" || return 1
=======
    
    # Extract just the description content from story file
    local desc_content=""
    
    # Check for new format: separate Description HTML section
    if grep -q "### Description (System.Description field)" "$file"; then
      desc_content=$(sed -n '/### Description (System.Description field)/,/### Acceptance Criteria/p' "$file" | \
                     sed '1d;$d' | \
                     sed '/^---$/d' | \
                     sed '/^$/N;/^\n$/d')
      log_info "Extracted Description HTML section"
    # Check for old format: single HTML section
    elif grep -q "## HTML Formatting for ADO Description" "$file"; then
      desc_content=$(sed -n '/## HTML Formatting for ADO Description/,/^---$/p' "$file" | \
                     grep -v "^## HTML Formatting" | \
                     grep -v "^---$" | \
                     sed '/^$/N;/^\n$/d' | \
                     sed '1{/^$/d}')
      log_info "Extracted HTML section for description"
    else
      # Fallback: extract content between title and ## Acceptance Criteria
      desc_content=$(sed -n '/^#[^#]/,/^## .*Acceptance Criteria/p' "$file" | sed '1d;$d')
      log_info "Extracted markdown section for description"
    fi
    
    if [[ -z "$desc_content" ]]; then
      log_error "No description content found in file"
      return 1
    fi
    
    SDL_DESC_PATCH_OP="$op" echo "$desc_content" | node "$patch_js" >"$tmp" || return 1
>>>>>>> 5a6d807 (Final commit of AI-SDLC Platform)
    [[ -s "$tmp" ]] || return 1
    return 0
  }

  local response
  if _ado_patch_desc_to_file "replace"; then
    response=$(_ado_curl -X PATCH \
      -u ":${ADO_PAT}" \
      -H "Content-Type: application/json-patch+json; charset=utf-8" \
      --data-binary @"$tmp" \
      "$url" 2>/dev/null) || true

    if echo "$response" | grep -q '"id"'; then
      rm -f "$tmp"
      log_success "Description updated for work item $wi_id"
      return 0
    fi
  fi

  if _ado_patch_desc_to_file "add"; then
    response=$(_ado_curl -X PATCH \
      -u ":${ADO_PAT}" \
      -H "Content-Type: application/json-patch+json; charset=utf-8" \
      --data-binary @"$tmp" \
      "$url" 2>/dev/null) || true

    if echo "$response" | grep -q '"id"'; then
      rm -f "$tmp"
      log_success "Description updated for work item $wi_id"
      return 0
    fi
  fi

  rm -f "$tmp"
  log_error "Failed to update description"
  [[ -n "${response:-}" ]] && echo "$response" | head -c 1200 >&2
  return 1
}

_ado_description_cmd() {
  local wi_id="" file=""
  for arg in "$@"; do
    case "$arg" in
      --file=*) file="${arg#--file=}" ;;
      *) wi_id="$arg" ;;
    esac
  done
  _ado_set_description "$wi_id" "$file"
}

# ============================================================================
# ADO SYNC (Two-way)
# ============================================================================

_ado_sync_from() {
  local wi_id
  wi_id="$(_normalize_ado_wi_id "${1:-}")"

  if [[ -z "$wi_id" ]] || [[ ! "$wi_id" =~ ^[0-9]+$ ]]; then
    log_error "Usage: sdlc ado sync-from <id>"
    log_info "Examples: 851789  or  US-851789"
    return 1
  fi

  log_section "Fetching Work Item State from ADO (→ local)"
  log_info "Work Item ID: $wi_id"

  local url="https://dev.azure.com/${ADO_ORG}/${ADO_PROJECT}/_apis/wit/workitems/${wi_id}?api-version=7.0"
  local response
  response=$(_ado_curl -u ":${ADO_PAT}" "$url") || true

  if ! echo "$response" | grep -q '"id"'; then
    log_error "Could not fetch work item $wi_id"
    return 1
  fi

  # Extract state for local sync
  local state
  state=$(_ado_json_field "$response" "System.State")

  log_success "Synced: State is now '$state'"
}

_ado_sync_to() {
  local wi_id
  wi_id="$(_normalize_ado_wi_id "${1:-}")"

  if [[ -z "$wi_id" ]] || [[ ! "$wi_id" =~ ^[0-9]+$ ]]; then
    log_error "Usage: sdlc ado sync-to <id>"
    return 1
  fi

  log_section "Pushing Work Item State to ADO (local → remote)"
  log_info "Work Item ID: $wi_id"

  _load_env

  # Collect local state from .sdlc/memory
  local state_dir=".sdlc/memory"
  local body='['
  local has_patch=0

  # Push local stage as a tag
  if [[ -f ".sdlc/stage" ]]; then
    local local_stage
    local_stage="$(tr -d '\r\n' < .sdlc/stage)"
    if [[ -n "$local_stage" ]]; then
      [[ $has_patch -eq 1 ]] && body+=','
      body+="{\"op\":\"add\",\"path\":\"/fields/System.Tags\",\"value\":\"sdlc-stage:${local_stage}\"}"
      has_patch=1
      log_info "Pushing tag: sdlc-stage:${local_stage}"
    fi
  fi

  # Push role context as a tag
  if [[ -f ".sdlc/role" ]]; then
    local local_role
    local_role="$(tr -d '\r\n' < .sdlc/role)"
    if [[ -n "$local_role" ]]; then
      [[ $has_patch -eq 1 ]] && body+=','
      body+="{\"op\":\"add\",\"path\":\"/fields/System.Tags\",\"value\":\"sdlc-role:${local_role}\"}"
      has_patch=1
      log_info "Pushing tag: sdlc-role:${local_role}"
    fi
  fi

  # Push completion notes if present
  local stage_name=""
  [[ -f ".sdlc/stage" ]] && stage_name="$(tr -d '\r\n' < .sdlc/stage | tr ' ' '-' | tr '[:upper:]' '[:lower:]')"
  local completion_file="${state_dir}/${stage_name}-completion.md"
  if [[ -f "$completion_file" ]]; then
    local note
    note="$(head -20 "$completion_file")"
    local esc_note
    esc_note=$(_json_escape "$note")
    [[ $has_patch -eq 1 ]] && body+=','
    body+="{\"op\":\"add\",\"path\":\"/fields/System.History\",\"value\":\"[SDLC sync-to] Stage completion notes:\\n${esc_note}\"}"
    has_patch=1
    log_info "Pushing stage completion notes as discussion comment"
  fi

  body+=']'

  if [[ $has_patch -eq 0 ]]; then
    log_warn "No local state to push (missing .sdlc/stage, .sdlc/role, or completion file)"
    return 0
  fi

  local url="https://dev.azure.com/${ADO_ORG}/${ADO_PROJECT}/_apis/wit/workitems/${wi_id}?api-version=7.0"
  local response
  response=$(_ado_curl -X PATCH \
    -u ":${ADO_PAT}" \
    -H "Content-Type: application/json-patch+json" \
    -d "$body" \
    "$url") || true

  if echo "$response" | grep -q '"id"'; then
    log_success "Local state pushed to ADO work item $wi_id"
  else
    log_error "Sync-to may have failed"
    log_info "Response: $response"
    return 1
  fi
}

_ado_sync() {
  local wi_id
  wi_id="$(_normalize_ado_wi_id "${1:-}")"

  if [[ -z "$wi_id" ]] || [[ ! "$wi_id" =~ ^[0-9]+$ ]]; then
    log_error "Usage: sdlc ado sync <id>"
    return 1
  fi

  log_section "Bi-directional Sync (ADO ↔ local)"
  _ado_sync_from "$wi_id"
  _ado_sync_to "$wi_id"
}
