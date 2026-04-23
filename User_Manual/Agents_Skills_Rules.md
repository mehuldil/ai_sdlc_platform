# Agents, Skills & Rules

## Agents (53 Total)

### What Is an Agent?
An AI persona that embodies a role at specific stages. Loads role context + stage context + gates. Invokes skills to perform work. Uses **THIN orchestrator pattern** — delegates to atomic skills, contains no inline logic.

### Agent Tiers

| Tier | Count | Purpose | Examples |
|------|-------|---------|---------|
| Tier 1 (Universal) | 6 | Cross-role infrastructure | context-guard, smart-routing, auto-documentation-guardian, etc. |
| Tier 2 (Domain) | 40 | Role-specific execution | Backend, frontend, QA, performance, product agents |
| Tier 3 (Reports / Executive) | 8 | Cross-cutting reports and release | release-manager, compliance-auditor, etc. |

### Agent Registry
All agents defined in `agents/agent-registry.json` with: path, tier, role, description, tags, token budget, required env vars, and **accepts_roles** (which roles can invoke this agent). Governance for the registry (dedup, skills-first): [`agents/REGISTRY_AND_ATOMIC_DESIGN.md`](../agents/REGISTRY_AND_ATOMIC_DESIGN.md).

### THIN Orchestrator Pattern (Canonical)
Agents delegate to skills. Example: `security-agent.md` orchestrates `security-scan` + `security-remediation` skills.
Full (non-orchestrator) versions archived as `{name}-FULL.md` for reference.

### Documentation Governance Agents

| Agent | Tier | Purpose | Triggers |
|-------|------|---------|----------|
| **auto-documentation-guardian** | 1 (Universal) | Keep User Manual current, simple, non-duplicative, minimal | Any change to skills/, agents/, rules/, commands/, stages/ |

**What it does:**
1. Detects documentation impact from platform changes
2. Checks for duplication before adding content
3. Updates docs following strict 5-part format
4. Validates UX (scannable, understandable)
5. Cross-references instead of duplicating

**Status output:**
- 📄 Updated files
- ✂️ Duplication removed
- 🔗 Cross-links added
- 📉 Token optimization notes
- 🚦 Status: SAFE / NEEDS_IMPROVEMENT / BLOCKED

**Invoke:** `sdlc agent invoke auto-documentation-guardian` or automatic via `hooks/doc-change-check.sh`

See full definition: [`agents/shared/auto-documentation-guardian.md`](../agents/shared/auto-documentation-guardian.md)

## Skills (v2.1.1 Architecture)

**v2.1.1 (Apr 2026):** Registry bumped to **8 total skills** with **3 new atomic skills** added: `update-documentation`, `sync-to-ado`, `generate-or-validate-unit-tests` (mandatory/blocking — bypass must be documented in the ADO work item per `rules/gate-enforcement-ide.md`).

### Skill Evolution

The platform now uses a **three-tier skill architecture**:

```
┌─────────────────────────────────────────────────────────────┐
│  Tier 3: Composed Skills (YAML Workflows)                   │
│  - Declarative combinations of atomic skills                  │
│  - Example: rpi-research.yaml combines 5 atomic skills        │
├─────────────────────────────────────────────────────────────┤
│  Tier 2: Monolithic Skills (Legacy .md)                     │
│  - Full implementation in single file                         │
│  - Example: rpi-research.md (~200 lines)                    │
│  - Still supported via fallback chain                         │
├─────────────────────────────────────────────────────────────┤
│  Tier 1: Atomic Skills (~10 building blocks)                │
│  - Single-responsibility operations                           │
│  - ~50 lines each                                             │
│  - Composable like LEGO bricks                                │
└─────────────────────────────────────────────────────────────┘
```

### What Is an Atomic Skill?

An **atomic skill** is a single-responsibility AI capability:

| Skill | Responsibility | Input | Output |
|-------|---------------|-------|--------|
| `ado-fetch` | Fetch ADO work item | story_id | Work item fields |
| `codebase-search` | Find relevant files | keywords | File paths + scores |
| `file-extract` | Read file excerpts | paths, limits | File contents |
| `wiki-lookup` | Search documentation | terms | Wiki results |
| `risk-identify` | Analyze risks | work item, files | Risk list |

**Benefits**:
- **Reusability**: atomic skills → many composed skills (current registry: 8 total; target: 100+ composed over time)
- **Testability**: Each skill independently testable
- **Caching**: Granular cache invalidation
- **Token Efficiency**: Only load what's needed

### What Is a Composed Skill?

A **composed skill** is a declarative workflow combining atomic skills:

```yaml
# skills/composed/rpi-research.yaml
name: rpi-research
composition:
  - id: step-1
    skill: ado-fetch
    output: work_item
    
  - id: step-2
    skill: codebase-search
    input:
      keywords: "$work_item.title"
    output: relevant_files
    depends_on: [step-1]
    
  - id: step-3
    skill: file-extract
    input:
      files: "$relevant_files.files"
    output: file_contents
    depends_on: [step-2]
    
  - id: step-4
    skill: wiki-lookup
    input:
      terms: "$work_item.tags"
    output: wiki_results
    
  - id: step-5
    skill: risk-identify
    input:
      work_item: "$work_item"
      files: "$relevant_files"
    output: risk_analysis
    depends_on: [step-1, step-2]

gate:
  id: research-gate
  description: Review research findings
  channels: [cli, ado_comment]
```

### Skill Registry (v2.1.0)

**Two indexes:** `skills/SKILL.md` counts every markdown skill file under `skills/`. `skills/registry.json` is the **smaller machine-routed set** (CLI skill-router: schemas, composed vs monolithic, caching). Not every `SKILL.md` has a JSON entry—see [`skills/README.md`](../skills/README.md).

Central registry at `skills/registry.json`:

```json
{
  "skills": {
    "rpi-research": {
      "id": "rpi-research",
      "universal": true,
      "accepts_roles": ["*"],
      "model": "sonnet-4-6",
      "token_budget": {"input": 6000, "output": 4000},
      "implementations": {
        "composed": {
          "path": "skills/composed/rpi-research.yaml",
          "cost": 400
        },
        "generic": {
          "path": "skills/rpi-research.md",
          "cost": 600
        }
      },
      "input_schema": {...},
      "output_schema": {...},
      "cacheable": true,
      "cache_ttl_seconds": 3600
    }
  }
}
```

**Routing Logic**:
1. Try `composed` implementation (YAML workflow)
2. Fallback to `generic` (monolithic .md)
3. Route to atomic skills

### Skill Caching (v2.1.0)

Skills can be cached based on:
- Input parameters
- Git HEAD (auto-invalidation on commit)
- TTL (time-based expiration)

```bash
# Cache location
.sdlc/cache/skills/{hash}.json

# Clear cache
sdlc skills cache clear          # All
sdlc skills cache clear rpi-research  # Specific skill
```

### Orchestrators (Moved to orchestrator/)

Frontend, QA, and Boss orchestration logic moved from `skills/` to `orchestrator/` — they coordinate agents, not perform atomic work.

| Orchestrator | Location | Coordinates |
|-------------|----------|-------------|
| Frontend | `orchestrator/frontend/` | ios-dev, android-dev, rn-dev agents |
| QA | `orchestrator/qa/` | 6 QA agents (analysis, test-builder, test-runner, defect, qa-ops) |
| Reporting | `orchestrator/reporting/` | Sprint health, release readiness, risk dashboard |
| Performance | `orchestrator/perf/` | 8-phase PTLC pipeline (load, soak, stress, spike) |
| **ADO Observer** (v2.1.0) | `orchestrator/ado-observer/` | 2-way ADO sync, event triggers |

### Key Atomic Skills (v2.1.0)

| Skill | Purpose | Location | Cost |
|-------|---------|----------|------|
| **ado-fetch** | Fetch work item from ADO | `skills/atomic/` | 50 tokens |
| **codebase-search** | Search repository for relevant files | `skills/atomic/` | 100 tokens |
| **file-extract** | Read file excerpts with limits | `skills/atomic/` | 50 tokens |
| **wiki-lookup** | Search WikiJS documentation | `skills/atomic/` | 50 tokens |
| **risk-identify** | Analyze implementation risks | `skills/atomic/` | 200 tokens |
| **update-documentation** (v2.1.1) | Align README, wiki, ADRs, User_Manual when behavior/contracts change | `skills/shared/update-documentation/` | 4K in / 2K out |
| **sync-to-ado** (v2.1.1) | Outbound ADO CRUD; wires to `cli/`, `orchestrator/ado-observer/`, and agent refs | `skills/shared/sync-to-ado/` | small |
| **generate-or-validate-unit-tests** (v2.1.1) | **Blocking** — generate or validate unit tests pre-dev-complete. Bypass requires an ADO work item comment (`ado_comment_required: true`) | `skills/shared/generate-or-validate-unit-tests/` | varies |
| story-ge