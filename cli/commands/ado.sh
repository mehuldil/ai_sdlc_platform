#!/usr/bin/env bash
# ============================================================================
# AI SDLC Azure DevOps Search & Query Commands
# Version: 1.0.0
# ============================================================================

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLATFORM_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source ADO library
source "$PLATFORM_DIR/cli/lib/ado.sh" 2>/dev/null || {
  echo "Error: Could not load ado.sh library"
  exit 1
}

# Source config for env vars
source "$PLATFORM_DIR/cli/lib/config.sh" 2>/dev/null || true

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log_success() { echo -e "${GREEN}✓${NC} $@"; }
log_error() { echo -e "${RED}✗${NC} $@" >&2; }
log_warn() { echo -e "${YELLOW}⚠${NC} $@" >&2; }
log_info() { echo -e "${BLUE}ℹ${NC} $@"; }
log_section() { echo ""; echo "=== $@ ==="; echo ""; }

# ============================================================================
# ADO SEARCH COMMANDS
# ============================================================================

# Search work items using WIQL (Work Item Query Language)
cmd_ado_search() {
  local query="${1:-}"
  local top="${2:-20}"
  local fields="System.Id,System.Title,System.WorkItemType,System.State,System.AssignedTo,System.CreatedDate"
  local wiql=""

  # If no query provided, show usage
  if [[ -z "$query" ]]; then
    echo "Usage: sdlc ado search <query> [options]"
    echo ""
    echo "Search Azure DevOps work items using text or WIQL"
    echo ""
    echo "Examples:"
    echo "  sdlc ado search \"Family Hub\"                    # Text search"
    echo "  sdlc ado search --wiql \"SELECT [Id] FROM workitems WHERE [Work Item Type] = 'User Story'\""
    echo "  sdlc ado search \"state=Active\" --top 10          # State filter"
    echo "  sdlc ado search \"assignedTo=me\"                # My work items"
    echo ""
    echo "Options:"
    echo "  --top N              Return N results (default: 20)"
    echo "  --wiql \"QUERY\"       Use raw WIQL query"
    echo "  --type TYPE          Filter by work item type (Feature, 'User Story', Bug, Task)"
    echo "  --state STATE        Filter by state (New, Active, Resolved, Closed)"
    echo "  --assigned-to USER   Filter by assignee"
    echo "  --json               Output as JSON"
    echo "  --fields FIELDS      Comma-separated fields (default: basic info)"
    return 0
  fi

  # Parse arguments
  local search_text=""
  local use_wiql=false
  local work_item_type=""
  local state=""
  local assigned_to=""
  local output_json=false
  local custom_fields=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --wiql)
        use_wiql=true
        wiql="$2"
        shift 2
        ;;
      --top)
        top="$2"
        shift 2
        ;;
      --type)
        work_item_type="$2"
        shift 2
        ;;
      --state)
        state="$2"
        shift 2
        ;;
      --assigned-to)
        assigned_to="$2"
        shift 2
        ;;
      --json)
        output_json=true
        shift
        ;;
      --fields)
        custom_fields="$2"
        shift 2
        ;;
      *)
        if [[ -z "$search_text" && "$use_wiql" == false ]]; then
          search_text="$1"
        fi
        shift
        ;;
    esac
  done

  # Load env vars
  local ado_org="${ADO_ORG:-}"
  local ado_project="${ADO_PROJECT:-}"
  local ado_pat="${ADO_PAT:-}"

  # Try loading from env/.env
  if [[ -f "$PLATFORM_DIR/env/.env" ]]; then
    while IFS='=' read -r key value; do
      [[ "$key" =~ ^#.*$ || -z "$key" ]] && continue
      case "$key" in
        ADO_ORG) ado_org="${ado_org:-$value}" ;;
        ADO_PROJECT) ado_project="${ado_project:-$value}" ;;
        ADO_PAT) ado_pat="${ado_pat:-$value}" ;;
      esac
    done < "$PLATFORM_DIR/env/.env"
  fi

  if [[ -z "$ado_org" || -z "$ado_project" || -z "$ado_pat" ]]; then
    log_error "ADO credentials not configured. Please set ADO_ORG, ADO_PROJECT, and ADO_PAT in env/.env"
    return 1
  fi

  # Build WIQL query if not provided
  if [[ "$use_wiql" == false ]]; then
    # Parse simple query syntax
    if [[ "$search_text" =~ ^state=(.+)$ ]]; then
      state="${BASH_REMATCH[1]}"
      search_text=""
    elif [[ "$search_text" =~ ^assignedTo=(.+)$ ]]; then
      assigned_to="${BASH_REMATCH[1]}"
      search_text=""
    fi

    # Build WIQL
    local conditions=()

    # Project filter
    conditions+=("[System.TeamProject] = '$ado_project'")

    # Text search
    if [[ -n "$search_text" ]]; then
      # Escape single quotes
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

    # Select fields
    if [[ -n "$custom_fields" ]]; then
      fields="$custom_fields"
    fi

    # Build final WIQL
    wiql="SELECT [$fields] FROM workitems WHERE $where_clause ORDER BY [System.ChangedDate] DESC"
  fi

  log_info "Searching ADO with query: $wiql"

  # Execute WIQL query
  local api_url="https://dev.azure.com/${ado_org}/${ado_project}/_apis/wit/wiql?api-version=7.0"
  local auth_header="Authorization: Basic $(echo -n ":$ado_pat" | base64 -w 0 2>/dev/null || echo -n ":$ado_pat" | base64)"

  local query_body="{\"query\": \"$wiql\"}"

  local response
  response=$(curl -sS -X POST \
    -H "Content-Type: application/json" \
    -H "$auth_header" \
    -d "$query_body" \
    "$api_url" 2>&1) || {
    log_error "Failed to execute query: $response"
    return 1
  }

  # Check for errors
  if echo "$response" | grep -q '"message"'; then
    local error_msg=$(echo "$response" | jq -r '.message // "Unknown error"' 2>/dev/null || echo "Unknown error")
    log_error "ADO API error: $error_msg"
    return 1
  fi

  # Extract work item IDs
  local work_item_ids
  work_item_ids=$(echo "$response" | jq -r '.workItems[].id' 2>/dev/null | head -n "$top" | tr '\n' ',' | sed 's/,$//')

  if [[ -z "$work_item_ids" ]]; then
    log_warn "No work items found matching your query"
    return 0
  fi

  # Fetch full details
  local details_url="https://dev.azure.com/${ado_org}/${ado_project}/_apis/wit/workitems?ids=${work_item_ids}&fields=${fields}&api-version=7.0"

  local details_response
  details_response=$(curl -sS \
    -H "$auth_header" \
    "$details_url" 2>&1) || {
    log_error "Failed to fetch work item details"
    return 1
  }

  # Output
  if [[ "$output_json" == true ]]; then
    echo "$details_response" | jq '.' 2>/dev/null || echo "$details_response"
  else
    # Pretty print
    log_section "Search Results"
    echo "$details_response" | jq -r '.value[] | "\n┌─────────────────────────────────────────────────────────────┐\n│ \(.id) | \(.fields["System.WorkItemType"]) | \(.fields["System.State"])\n│ \(.fields["System.Title"])\n│ Assigned: \(.fields["System.AssignedTo"] // "Unassigned")\n│ Updated: \(.fields["System.ChangedDate"] // "N/A")\n└─────────────────────────────────────────────────────────────┘"' 2>/dev/null || {
      log_error "Failed to parse results"
      echo "$details_response"
    }

    local count=$(echo "$details_response" | jq '.value | length' 2>/dev/null || echo "0")
    echo ""
    log_success "Found $count work item(s)"
  fi
}

# Get specific work item details
cmd_ado_get() {
  local work_item_id="${1:-}"

  if [[ -z "$work_item_id" ]]; then
    echo "Usage: sdlc ado get <work-item-id>"
    echo ""
    echo "Get detailed information about a specific ADO work item"
    echo ""
    echo "Examples:"
    echo "  sdlc ado get 865620"
    echo "  sdlc ado get US-865620"
    echo "  sdlc ado get #865620 --expand relations"
    return 0
  fi

  # Normalize ID
  work_item_id=$(_normalize_ado_wi_id "$work_item_id")

  # Load env vars
  local ado_org="${ADO_ORG:-}"
  local ado_project="${ADO_PROJECT:-}"
  local ado_pat="${ADO_PAT:-}"

  if [[ -f "$PLATFORM_DIR/env/.env" ]]; then
    while IFS='=' read -r key value; do
      [[ "$key" =~ ^#.*$ || -z "$key" ]] && continue
      case "$key" in
        ADO_ORG) ado_org="${ado_org:-$value}" ;;
        ADO_PROJECT) ado_project="${ado_project:-$value}" ;;
        ADO_PAT) ado_pat="${ado_pat:-$value}" ;;
      esac
    done < "$PLATFORM_DIR/env/.env"
  fi

  if [[ -z "$ado_org" || -z "$ado_project" || -z "$ado_pat" ]]; then
    log_error "ADO credentials not configured"
    return 1
  fi

  local api_url="https://dev.azure.com/${ado_org}/${ado_project}/_apis/wit/workitems/${work_item_id}?api-version=7.0&\$expand=all"
  local auth_header="Authorization: Basic $(echo -n ":$ado_pat" | base64 -w 0 2>/dev/null || echo -n ":$ado_pat" | base64)"

  log_info "Fetching work item $work_item_id..."

  local response
  response=$(curl -sS \
    -H "$auth_header" \
    "$api_url" 2>&1) || {
    log_error "Failed to fetch work item"
    return 1
  }

  # Check for errors
  if echo "$response" | grep -q '"message"'; then
    local error_msg=$(echo "$response" | jq -r '.message // "Unknown error"' 2>/dev/null || echo "Unknown error")
    log_error "ADO API error: $error_msg"
    return 1
  fi

  # Pretty print
  log_section "Work Item Details"

  local wi_type=$(echo "$response" | jq -r '.fields["System.WorkItemType"] // "Unknown"')
  local title=$(echo "$response" | jq -r '.fields["System.Title"] // "No Title"')
  local state=$(echo "$response" | jq -r '.fields["System.State"] // "Unknown"')
  local assigned_to=$(echo "$response" | jq -r '.fields["System.AssignedTo"].displayName // .fields["System.AssignedTo"] // "Unassigned"')
  local created_by=$(echo "$response" | jq -r '.fields["System.CreatedBy"].displayName // .fields["System.CreatedBy"] // "Unknown"')
  local created_date=$(echo "$response" | jq -r '.fields["System.CreatedDate"] // "N/A"')
  local changed_date=$(echo "$response" | jq -r '.fields["System.ChangedDate"] // "N/A"')
  local description=$(echo "$response" | jq -r '.fields["System.Description"] // "No description"' | sed 's/<[^>]*>//g' | head -c 500)

  echo ""
  echo "╔════════════════════════════════════════════════════════════════╗"
  echo "║  ID:        $work_item_id"
  echo "║  Type:      $wi_type"
  echo "║  State:     $state"
  echo "║  Title:     $title"
  echo "╠════════════════════════════════════════════════════════════════╣"
  echo "║  Assigned: $assigned_to"
  echo "║  Created:  $created_by on $created_date"
  echo "║  Updated:  $changed_date"
  echo "╠════════════════════════════════════════════════════════════════╣"
  echo "║  Description:"
  echo "║  $description"
  if [[ ${#description} -ge 500 ]]; then
    echo "║  ... (truncated)"
  fi
  echo "╚════════════════════════════════════════════════════════════════╝"

  # Show URL
  echo ""
  log_info "View in browser: https://dev.azure.com/${ado_org}/${ado_project}/_workitems/edit/${work_item_id}"
}

# Main command dispatcher
cmd_ado() {
  local subcommand="${1:-}"
  shift || true

  case "$subcommand" in
    search)
      cmd_ado_search "$@"
      ;;
    get)
      cmd_ado_get "$@"
      ;;
    *)
      echo "Azure DevOps CLI Commands"
      echo ""
      echo "Usage: sdlc ado <command> [options]"
      echo ""
      echo "Commands:"
      echo "  search <query>       Search work items using WIQL or text"
      echo "  get <id>             Get detailed work item information"
      echo ""
      echo "Examples:"
      echo "  sdlc ado search \"Family Hub\""
      echo "  sdlc ado search --type Feature --state Active"
      echo "  sdlc ado search assignedTo=me --top 10"
      echo "  sdlc ado get 865620"
      echo ""
      echo "Credentials: Set ADO_ORG, ADO_PROJECT, ADO_PAT in env/.env"
      return 0
      ;;
  esac
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  cmd_ado "$@"
fi
