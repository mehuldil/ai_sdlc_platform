# ADO & MCP Integration

## Azure DevOps Integration

### Three Modes

| Mode | Interface | How It Works | Best For |
|------|-----------|-------------|----------|
| **MCP Mode** | IDE (Cursor, Claude Code) | `mcp.json` → `@azure-devops/mcp` → ADO API | Interactive queries, rich context |
| **CLI Mode** | Terminal | `sdlc ado` → `curl` → ADO REST API v7.0 | Scripts, offline workflows, automation |
| **Observer Mode** (v2.1.1) | Background | ADO → Webhook/Polling → Platform triggers | Real-time sync, event-driven |

### Acceptance Criteria Field (v2.1.4+)

When pushing stories to ADO via `sdlc story push` or `sdlc ado push-story`, the platform now populates the **dedicated acceptance criteria field** (`Microsoft.VSTS.Common.AcceptanceCriteria`) instead of embedding AC within the description.

**Benefits:**
- AC appears in ADO's dedicated Acceptance Criteria section (visible in work item form)
- Better separation of narrative description from testable criteria
- Standard ADO field enables better reporting and queries

**How it works:**
1. Story files must have `## Acceptance Criteria` section (standard template format)
2. CLI extracts AC content and converts to HTML
3. AC is sent to `Microsoft.VSTS.Common.AcceptanceCriteria` field via JSON Patch
4. Description field contains only narrative content (before AC section)

**Example story structure:**
```markdown
# Story Title

Description content here...

## Acceptance Criteria

### Scenario 1
1. **Given** context
   **When** action
   **Then** result
```

### Quick Reference: Search ADO Work Items

| Method | Command | When to Use |
|--------|---------|-------------|
| **CLI (Offline-safe)** | `sdlc ado search "Family Hub"` | Fast text search, no MCP setup needed |
| **CLI (Filtered)** | `sdlc ado search state=Active --top 10` | Filtered queries, programmatic use |
| **CLI (My Items)** | `sdlc ado search assignedTo=me` | Quick personal work item lookup |
| **MCP (Rich)** | `@mcp azure-devops search "Family Hub"` | Full ADO search with all fields |
| **CLI (Get Details)** | `sdlc ado get 865620` | Formatted summary of specific work item |

**CLI Search Examples:**
```bash
# Text search in titles
sdlc ado search "Family Hub"

# State filter
sdlc ado search state=Active

# Type filter
sdlc ado search type=Feature

# Combined filters
sdlc ado search "Family Hub" state=Proposed type=Feature --top 5

# My work items
sdlc ado search assignedTo=me

# Get formatted summary
sdlc ado get 865620
```

Both use the same credentials from `env/.env`.

### Setup

```bash
# In env/.env
ADO_ORG=your-organization
ADO_PROJECT=your-project
ADO_PAT=your-personal-access-token
```

**Get ADO PAT:** `https://dev.azure.com/{ORG}/_usersSettings/tokens`
- Scopes: "Work Items (Read & Write)"

### Work Item Types: Story vs Feature vs Epic

**Recommendation: Use User Story as default for all stories** (v2.1.4+)

| Type | When to Use | CLI Flag |
|------|-------------|----------|
| **User Story** (default) | Functional requirements with acceptance criteria. Use for both master stories and sprint stories. | `--type=story` or omit |
| **Feature** | Large cross-cutting initiatives requiring portfolio tracking. Rarely needed for single-team work. | `--type=feature` |
| **Epic** | Strategic initiatives spanning multiple releases or quarters. | `--type=epic` |

**Master stories are User Stories**, not Features. A master story contains detailed acceptance criteria for a complete user journey (e.g., "Family Hub Phase 1"). Only use Feature type when you need ADO's portfolio roll-up capabilities for cross-team initiatives.

**Example:**
```bash
# Master story → User Story (recommended)
sdlc story push ./stories/MS-family-hub.md

# Sprint story → User Story (default)
sdlc story push ./stories/SS-sprint-3.md --parent=865620
```

### ADO Work Item Tagging

| Tag Type | Examples |
|----------|---------|
| Status | `prd:reviewed`, `techdesign:reviewed`, `release:reviewed` |
| Blocking | `blocked:prd-review`, `blocked:design` |
| Type | `story:product`, `story:backend`, `story:frontend` |
| Quality | `analytics:required`, `adr:required` |
| AI | `claude:generated` |
| **RPI (v2.1.1)** | `rpi:research-complete`, `rpi:research-approved`, `rpi:plan-complete` |

### ADO State Machine

```
New → Approved → Committed → In Progress → Done
                    ↓
                 Blocked → Closed (Done or Won't Do)
```

### Auto-Linking on Merge

When branches merge, auto-posts to ADO work item:
- Branch merged + timestamp
- All ADR decisions combined
- Engineers involved across branches
- Links to git decision logs

**Non-blocking:** Merge succeeds even if ADO is unreachable.

### Offline / connectivity (acceptable behavior)

**Preferred posture:** Work continues locally; ADO sync is **best-effort** and **eventually consistent**.

| Situation | Behavior |
|-----------|----------|
| ADO API unreachable | Commits and merges still succeed; queue ADO updates for when online |
| MCP disconnected | Use **`sdlc ado`** (CLI + REST) when the network returns |
| Drift risk | Reconcile with **`sdlc ado`** queries + work item comments; optional scheduled job in your org |
| **Observer offline** (v2.1.1) | Workflow gates wait for CLI approval; queue comment-based triggers |

**Not guaranteed in offline mode:** real-time two-way sync, immediate parent/child link visibility, or zero drift until reconciliation runs.

## ADO Observer System (v2.1.1)

### What Is the ADO Observer?

The ADO Observer enables **2-way synchronization** between Azure DevOps and the AI-SDLC Platform:

- **Reactive** (existing): Platform pushes to ADO via CLI or MCP
- **Observable** (new): ADO changes trigger platform actions via webhook or polling

Implementation: [`orchestrator/ado-observer/observer.py`](../orchestrator/ado-observer/observer.py).

### How It Works

Two entry paths feed the same handler:

| Path | Trigger | Used for |
|------|---------|----------|
| **Webhook** | ADO posts an event (work item updated, comment added, state changed) | Real-time, preferred |
| **Polling** | Observer polls ADO REST at interval | Fallback when webhook is unreachable |

Both paths flow through `_process_work_item` which applies the same dedup + stage-mapping logic.

### Event → stage mapping

`EVENT_STAGE_MAP` in `observer.py` maps state transitions to SDLC stage ids. Wildcard `*` supported on either side.

```python
# example entries (fill in after ADO schema finalized)
EVENT_STAGE_MAP = {
    "new:active":       "02-pre-grooming",
    "active:resolved":  "09-code-review",
    "*:done":           "15-close",
}
```

Helper: `resolve_stage_for_transition(from_state, to_state)` tries exact match first, then `from:*`, then `*:to`.

**Status (v2.1.1):** shipped as a stub with `TODO(mehul)` entries. Fill real transitions during operational rollout; observer runs without error on empty map (no-op).

### Idempotency (v2.1.1)

Both paths are idempotent via an in-memory cache:

| Cache key | Source | TTL |
|-----------|--------|-----|
| `work_item_id + rev + event_type` | Polling & webhook fallback | 1 hour |
| ADO `eventId` | Webhook (when present) | 1 hour |

Duplicate events within the TTL are dropped with a log line — no downstream handlers fire twice. The cache self-prunes expired keys on each call (`_is_duplicate_event`).

This closes the "observer re-fires on polling after webhook already delivered" hole seen in pre-v2.1.1 deployments.

### Run modes

```bash
# Webhook mode (default)
python3 orchestrator/ado-observer/observer.py --mode=webhook --port=8080

# Polling mode (fallback)
python3 orchestrator/ado-observer/observer.py --mode=polling --interval=60

# Both (recommended for production)
python3 orchestrator/ado-observer/observer.py --mode=both --port=8080 --interval=300
```

### Gate bypass and ADO comments

Per [Enforcement_Contract](Enforcement_Contract.md) and `rules/gate-enforcement-ide.md`, any bypass of a hard gate (e.g., unit-test enforcement, mirror drift) must be recorded as a **comment on the ADO work item**. The observer treats gate-bypass comments as first-class events and records them for audit.
