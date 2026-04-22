# Commands Reference

## CLI Commands (`sdlc`)

### Context Management
```bash
sdlc use <role>                    # Switch role
sdlc use backend --stack=java-tej  # Role + stack
sdlc context                       # Show current role/stack/stage
sdlc init                          # Initialize context
```

### Document Ingestion (non-Markdown input)
```bash
sdlc doc convert <file|dir>              # docx/xlsx/pptx/html/pdf → .sdlc/import/*.extracted.md
sdlc doc convert <file> --output-dir ./  # Custom output directory
sdlc doc list                            # Show already-extracted files
sdlc doc deps                            # Print pip install command for all format libraries
```
Use before `story create` or `prd-review` when the user provides Office/PDF files instead of Markdown.
Skill: `skills/shared/doc-normalizer/SKILL.md` | Script: `scripts/doc-to-md.py`

### Story files (4-tier) + ADO
```bash
sdlc story create master --output=./stories/   # Template: MS-*.md
sdlc story create sprint --output=./stories/    # SS-*.md
sdlc story create tech --output=./stories/      # TS-*.md
sdlc story create task --output=./stories/      # T-*.md
sdlc story validate <file.md>
sdlc story push <file.md> [--type=story|feature|epic] [--parent=<id>]  # Same as sdlc ado push-story; prints ADO id
```
Default **`--type=story`** (ADO **User Story**). For a filled **master story** file, use **`--type=feature`** to create an ADO **Feature** (then copy the id into the PRD Traceability table). After content is filled (in chat or locally), **`sdlc story push`** creates the work item and returns the number.

### Stage Execution
```bash
sdlc run <stage>                   # Run specific stage (01-15)
sdlc flow full-sdlc               # Complete workflow
sdlc flow quick-fix               # Hotfix workflow
sdlc flow perf-cycle              # Performance testing cycle
sdlc flow plan-design-implement   # Explicit mode serialization
sdlc route <natural-language>     # AI routes to correct stage
sdlc gate-check                   # Validate current gate status
```

### ADO — Windows (no admin, no bash)
```powershell
# scripts\ado.ps1 — needs only PowerShell 5.1+ and curl.exe (built into Windows 10+)
powershell -File scripts\ado.ps1 description <id> --file=<story.md>
powershell -File scripts\ado.ps1 show        <id>
powershell -File scripts\ado.ps1 comment     <id> "text"
powershell -File scripts\ado.ps1 update      <id> --state=Active
powershell -File scripts\ado.ps1 push-story  <story.md> [--parent=<id>]
powershell -File scripts\ado.ps1 list        --type="User Story"
powershell -File scripts\ado.ps1 help
```

### ADO — macOS / Linux (no full setup)
```bash
# scripts/ado-mac.sh — needs only bash + curl (both built into macOS)
bash scripts/ado-mac.sh description <id> --file=<story.md>
bash scripts/ado-mac.sh show        <id>
bash scripts/ado-mac.sh comment     <id> "text"
bash scripts/ado-mac.sh update      <id> --state=Active
bash scripts/ado-mac.sh push-story  <story.md> [--parent=<id>] [--type=feature]
```
Both scripts auto-load `env/.env`. See [Prerequisites](Prerequisites.md) for details.

### Azure DevOps (full sdlc CLI — bash/Git Bash required)
```bash
# Work Item Creation & Management
sdlc ado create story --title="..." [--yes]   # Create work item (non-TTY: --yes or SDLC_ADO_CONFIRM=yes)
sdlc ado list --type=story          # List stories
sdlc ado show <id>                  # View work item (full details)
sdlc ado update <id> --state=Done   # Update status
sdlc ado push-story <file.md> [--type=story|feature|epic] [--yes]  # Push markdown to ADO (default: User Story)
sdlc ado link <id1> <id2>           # Link work items
sdlc ado comment <id> "message"      # Discussion comment on work item
sdlc ado sync                       # Sync local ↔ ADO

# ADO Search (v2.1.3+) — No MCP required
sdlc ado search "Family Hub"                    # Text search in titles
sdlc ado search "Family Hub" --top 5           # Limit results
sdlc ado search state=Active                    # Filter by state
sdlc ado search type=Feature                    # Filter by type
sdlc ado search assignedTo=me                    # My work items
sdlc ado search "Family Hub" state=Proposed    # Combined filters
sdlc ado get 865620                             # Quick formatted summary
```

**Search Filter Reference:**
| Filter | Syntax | Example |
|--------|--------|---------|
| Text | `"search text"` | `sdlc ado search "Family Hub"` |
| State | `state=<state>` | `sdlc ado search state=Active` |
| Type | `type=<type>` | `sdlc ado search type=Feature` |
| Assignee | `assignedTo=me\|<name>` | `sdlc ado search assignedTo=me` |
| Top N | `--top N` | `sdlc ado search "query" --top 10` |

### Module System
```bash
sdlc module init                  # Initialize module KB
sdlc module load [api|data|events|logic|all]  # Smart context load
sdlc module validate              # Pre-merge contract check
sdlc module report                # Impact analysis
sdlc module budget                # Token budget status
sdlc module link-issues           # Find related ADO issues
sdlc module update                # Refresh KB after commit
```

**Pre-design / pre-implementation hygiene:** Before system design or large implementation plans in an application repo, ensure module knowledge is current (`sdlc module init .` or `sdlc module update .` from that repo’s root). Use **`sdlc module show`** for a concise view or **`sdlc module load [api|data|events|logic|all]`** to pull contract slices into context without guessing paths. This aligns with **repo-grounded** design (`rules/repo-grounded-change.md`, design doc §0).

**Monorepos and API extraction:** Run **`sdlc module init`** from the **application git root**. If **`build.gradle`** / **`pom.xml`** lives only under a subfolder (e.g. `services/api/`), the scanner now detects nested Gradle/Maven files (depth ≤8) so **`stack`** in contracts is not **`unknown`**. For Java, **`api.yaml`** lists Spring MVC mappings and **`@Path("…")`** segments (RestExpress, JAX-RS). Segments are per annotation; combine with class-level base paths when documenting full routes.

### Auto-sync (module KB + semantic memory)

With hooks from **`setup.sh`** / **`sdlc setup``, you normally **do not** run manual `module update` / memory export:

| When | What runs |
|------|-----------|
| **pre-commit** | `sdlc module update` (if `.sdlc/module` exists) + export **`.sdlc/memory/semantic-memory-team.jsonl`** + `git add` those paths so they ship with the commit |
| **post-merge** | Same module refresh + **import** JSONL into local **SQLite** (so `git pull` + merge updates your DB) |
| **post-checkout** | Same as post-merge when you **switch branches** (so local state tracks the branch) |
| **post-commit** | Async backup export (e.g. if **`--no-verify`** skipped pre-commit) |

**Semantic Memory Hooks:**
- `hooks/semantic-memory-pre-commit.sh` — Exports semantic memory to JSONL before commit
- `hooks/semantic-memory-post-merge.sh` — Imports team JSONL after pull/merge

These hooks ensure team memory stays synchronized automatically via git.

- **Git-tracked bus for the team:** `.sdlc/module/**` and `semantic-memory-team.jsonl` (SQLite stays machine-local and gitignored).
- **Disable:** `SDL_AUTO_SYNC=0`, or `SDL_AUTO_SYNC_MODULE=0` / `SDL_AUTO_SYNC_SEMANTIC=0`.
- **Existing repos:** setup **removes a blanket `.sdlc/` line** from `.gitignore` when present and adds **granular** ignores so shared artifacts can be committed.

Manual equivalents: `sdlc memory semantic-export` / `sdlc memory semantic-import` (run from repo root).

### Memory & Budget
```bash
sdlc memory init                  # Initialize memory system
sdlc memory sync                  # Sync memory across branches
sdlc memory status                # Show memory state
sdlc memory semantic-status       # Unified semantic memory stats
sdlc memory semantic-query --text="..."   # Ranked retrieval
sdlc memory semantic-lifecycle    # Apply archive/trim governance
sdlc memory semantic-export       # Write team JSONL (also automatic on pre-commit)
sdlc memory semantic-import       # Merge team JSONL into local SQLite (also after pull)
sdlc tokens                       # Show token usage
sdlc cost                         # Show token cost model (all stages)
sdlc cost 08-implementation       # Show cost/spend for a specific stage
```

### RPI Workflow
```bash
sdlc rpi research US-1234         # Phase 1: Scope isolation
sdlc rpi plan US-1234             # Phase 2: Plan (requires approved research)
sdlc rpi implement US-1234        # Phase 3: Execute plan (requires approved plan)
sdlc rpi verify US-1234           # Phase 4: Verify implementation vs plan
sdlc rpi status US-1234           # Show RPI workflow status
```

### QA Orchestrator
```bash
sdlc qa start US-12345 --priority=high --tags=regression,critical
sdlc qa status <run-id>
sdlc qa approve <run-id> requirements APPROVED --reason="verified"
sdlc qa kb <run-id> --format=summary
sdlc qa archive <run-id>
sdlc qa health
```

### Test-skip markers (unit-test bypass)
```bash
# Create a per-branch skip marker (auditable; writes to .sdlc/skip-tests-<branch>)
sdlc skip-tests --reason="..." [--work-item=AB#12345] [--master-story=MS-...]

# View audit history (append-only log at .sdlc/memory/test-skips.log)
sdlc show-test-skips

# Remove markers once tests are back in scope (Ask-First: prompts unless --force)
sdlc clear-test-skips                      # Clear marker for current branch
sdlc clear-test-skips --all                # Clear markers for every branch
sdlc clear-test-skips [--all] --force      # Skip the confirmation prompt
```

- `skip-tests` requires `--reason` (min 10 chars) and a work-item trace (`--work-item`, `.sdlc/story-id`, `AB#<id>` in branch name, or `AB#<id>` in latest commit).
- `clear-test-skips` only deletes marker files; the audit trail in `.sdlc/memory/test-skips.log` is preserved and a `cleared=...` entry is appended.
- Policy and ADO discussion requirements: `rules/pre-merge-test-enforcement.md`.

### Skill Registry & Discovery (v2.1.1)
```bash
# Discover skills by role/stage
sdlc skills discover                          # List all skills
sdlc skills discover --for-role=backend      # Filter by role
sdlc skills discover --for-stage=08-implementation  # Filter by stage
sdlc skills discover --category=security     # Filter by category

# Show skill details
sdlc skills show rpi-research                # Show skill definition
sdlc skills show security-scan               # Show schemas, implementations

# Register new skills
sdlc skills register skills/qa/my-new-skill.md     # Add skill to registry
sdlc agent register agents/qa/my-new-agent.md      # Add agent to registry
sdlc stage register stages/16-new-stage/          # Add stage to registry

# Execute composed skills
sdlc skills invoke-composed skills/composed/rpi-research.yaml --input='{"story_id":"US-123"}'

# Cache management
sdlc skills cache clear                      # Clear all skill caches
sdlc skills cache clear rpi-research         # Clear specific skill cache
```

**Skill Discovery Interactive Mode**:
```bash
$ sdlc skills discover --for-role=backend

┌─────────────────────────────────────────────────────────────────┐
│ Available Skills                                                │
├─────────────────────────────────────────────────────────────────┤
│ rpi-research         │  600 tokens │ universal │ cached    │
│   Analyze story + codebase                                       │
├─────────────────────────────────────────────────────────────────┤
│ rpi-plan             │  800 tokens │ universal │ no-cache  │
│   Create implementation plan                                     │
├─────────────────────────────────────────────────────────────────┤
│ security-scan        │  400 tokens │ universal │ cached    │
│   Check for vulnerabilities                                      │
└─────────────────────────────────────────────────────────────────┘

Compose workflow (enter numbers, e.g., "1,2"): 1,2
Workflow name: my-backend-workflow
Created: .sdlc/user-composed-skills/my-backend-workflow.yaml
```

### Catalog & Diagnostics
```bash
sdlc agent list                   # List all agents
sdlc agent list --tier=1          # Filter by tier (universal)
sdlc agent list --role=backend    # Filter by role
sdlc skills list                  # List all skills
sdlc skills list --category=rpi   # Filter by category
sdlc skills list --universal      # Show universal skills only
sdlc flow list                    # List workflows
sdlc template list                # List templates
sdlc doctor                       # Full diagnostic: tools, config, rules, commands, docs+registries, memory, hooks, ADO
sdlc doctor --verbose             # Same, with validator stdout (validate-rules, validate-commands, detect-doc-drift, etc.)
sdlc doctor --check-registry      # Validate skill registry consistency
sdlc version                      # Platform version
sdlc version --full               # Show version + registry versions
sdlc help                         # All commands
sdlc help skills                  # Skill-specific help
```

### Error recovery (CLI)

When a command fails with a recoverable problem (wrong role, bad stage id, missing ADO env, unknown subcommand, etc.), stderr often ends with:

- **`── Next steps ──`** → run **`sdlc context`**, then **`sdlc doctor`**, or follow the **hint** line (`→`) above it.

**Registry consistency** (optional): `bash scripts/verify-platform-registry.sh` from `ai-sdlc-platform/` root — checks **stages** ↔ `config.sh`, **agent-registry.json**, **rules** count.

### First-time setup (clone)
```bash
git clone https://github.com/YOUR_GITHUB_USER/ai_sdlc_platform.git
cd AI-sdlc-platform
./setup.sh                        # Platform repo: hooks, env, IDE plugin, doc automation, CI --quick validation
sdlc setup --ide=both             # App repo: .sdlc/, env/.env, symlinks, git hooks
```

### CI (pipelines — no extra local commands)

After clone, **`./setup.sh` already runs** the same lint gate as CI: `bash scripts/ci-sdlc-platform.sh --quick`.

| Where | What runs |
|-------|-----------|
| **GitHub** | `.github/workflows/sdlc-ci.yml` on push/PR to `main` / `master` / `develop` — runs 3 jobs (see below) |
| **Azure DevOps** | `azure-pipelines.yml` (create a pipeline targeting this file) |
| **Full local** | `bash scripts/ci-sdlc-platform.sh` (includes `validate-system-change.sh` → rules, commands, hooks, **registry drift**, **stage-08 variants**, `cli/tests/smoke.sh`, `manual.html --check`) |

**GitHub CI jobs (v2.1.1):**

| Job | Purpose | Blocks merge on failure |
|-----|---------|-------------------------|
| `pr-traceability` | Regex-asserts **`PRD-REF-*-SEC*`** and **`AB#*`** in PR body | YES |
| `claude-mirror-drift` | Runs `scripts/verify-claude-ssot-ci.sh` — fails if `.claude/{agents,skills,templates}` drift from canonical `agents/`, `skills/`, `templates/` | YES |
| `platform-ci` | Runs `scripts/ci-sdlc-platform.sh` (full lint gate) | YES |

A PR template at `.github/pull_request_template.md` carries the required Traceability section. See [Traceability_and_Governance](Traceability_and_Governance.md).

**Optional** before merging large platform-only PRs: `bash scripts/validate-system-change.sh .` (same meta-checks as the first part of full CI: rules, commands, hooks, `regenerate-registries.sh --check`, `validate-stage-variants.sh`).

## IDE slash commands — router pattern (v2.1.1)

Slash commands come in two prefixes — logic lives in exactly one place per pair.

| Pattern | Role | Content |
|---------|------|---------|
| **`X.md`** (base) | Canonical workflow | Full steps, prompts, gate checks, skill invocations |
| **`project-X.md`** (`/project:<name>`) | Thin router | 7-line delegate that reads and follows `X.md` with `--project` scope. No logic. |

16 routers exist: `project-architecture-review`, `project-code-review`, `project-deployment`, `project-grooming`, `project-implementation`, `project-incident-response`, `project-monitoring`, `project-performance-testing`, `project-prd-review`, `project-release-prep`, `project-requirement-intake`, `project-setup`, `project-sprint-planning`, `project-staging-validation`, `project-system-design`, `project-test-design`.

Design doc: `.claude/commands/COMMAND_ROUTING.md`. Do **not** copy gate logic into routers — edit the base file only.

## Cross-platform .claude mirror sync (v2.1.1)

Team runs on Mac, some users on Windows — symlinks don't work cross-platform. Instead, `.claude/{agents,skills,templates}` are byte-identical **generated copies** of canonical `agents/`, `skills/`, `templates/`.

```bash
bash scripts/sync-claude-mirrors.sh          # Regenerate mirrors
bash scripts/sync-claude-mirrors.sh --check  # Diff-only (exit 1 on drift)
```

CI enforces mirror parity via the `claude-mirror-drift` job (above).

**Same capabilities** in Cursor chat, Claude Code, or natural l