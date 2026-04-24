# AI-SDLC Platform

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-GPLv3-blue.svg" alt="License: GPL v3"/></a>
  <a href="User_Manual/README.md"><img src="https://img.shields.io/badge/docs-User_Manual-2ea44f" alt="Docs"/></a>
  <img src="https://img.shields.io/badge/stages-15-orange" alt="15 stages"/>
  <img src="https://img.shields.io/badge/roles-8-blueviolet" alt="8 roles"/>
  <img src="https://img.shields.io/badge/stacks-6-yellow" alt="6 stacks"/>
</p>

<p align="center">
  <strong>The open-source AI-native SDLC platform.<br/>Ship software faster with AI — without losing control, traceability, or engineering discipline.</strong>
</p>

<p align="center">
  15 stages &nbsp;·&nbsp; 8 roles &nbsp;·&nbsp; 6 stacks &nbsp;·&nbsp; Agents · Skills · Rules &nbsp;·&nbsp; One <code>sdlc</code> CLI<br/>
  Works in <strong>Terminal</strong> · <strong>Cursor</strong> · <strong>Claude Code</strong>
</p>

<p align="center">
  <a href="#the-problem">Problem</a> ·
  <a href="#why-ai-sdlc-platform">Why</a> ·
  <a href="#quick-start">Quick Start</a> ·
  <a href="#features">Features</a> ·
  <a href="#architecture">Architecture</a> ·
  <a href="#who-its-for">Who It's For</a> ·
  <a href="#documentation">Docs</a> ·
  <a href="#contributing">Contributing</a>
</p>

---

## The problem

Every engineering team using AI today runs into the same wall:

- **Fragmented prompts** — every engineer has their own AI workflow, nothing is shared
- **Zero traceability** — a PR ships and nobody can trace it back to a requirement
- **"Release readiness" is tribal knowledge** — it lives in 2 people's heads
- **Governance is either absent or a bottleneck** — AI acts without human approval, or gates are so heavy nobody uses them
- **New engineers take weeks to onboard** — because "how we work here" isn't written down

**AI moves fast. Process doesn't keep up. Quality suffers.**

---

## Why AI-SDLC Platform

> **One CLI. Every team. Every IDE. Full traceability. Humans stay in control.**

| Without AI-SDLC | With AI-SDLC |
|-----------------|--------------|
| Every team invents their own AI workflow | Shared stages, agents, skills, and rules — one playbook |
| Traceability is manual and often missing | PRD → Master Story → Sprint → Task → Branch → PR → ADO — automatic chain |
| Onboarding a new engineer takes weeks | `sdlc doctor` + offline User Manual — productive from day 1 |
| Quality gates are informal | Pre-commit hooks, rules, and template DoD enforce quality at the right moments |
| AI makes changes without asking | **Ask-first protocol** — AI proposes, human approves every gate and destructive action |
| Token costs are unpredictable | Budget per role, visible via `sdlc tokens`, module slices cut waste |

---

## Quick start

```bash
git clone https://github.com/YOUR_GITHUB_USER/ai_sdlc_platform.git
cd ai_sdlc_platform

./setup.sh /path/to/your/project   # or just ./setup.sh for in-repo use
sdlc doctor                        # verify hooks and health

sdlc use backend --stack=java  # pick your role and stack
sdlc context                       # confirm current state
sdlc run 05-system-design          # jump into any stage
```

**IDE integration — zero extra config after setup:**

| Interface | How |
|-----------|-----|
| **Cursor** | Use `/project:*` slash commands; rules auto-load from `.cursor/rules/` |
| **Claude Code** | Skills and rules available via `.claude/` symlinks |
| **Terminal** | Full `sdlc` CLI — same commands everywhere |

Full install walkthrough: [`SETUP_GUIDE.md`](SETUP_GUIDE.md)  
Offline searchable manual: [`User_Manual/manual.html`](User_Manual/manual.html) — open in any browser after clone

---

## Features

### 15-stage pipeline with smart routing

A numbered, named stage for every phase — intake through post-release close. Smart routing skips unnecessary stages based on change type, so a config change doesn't run the full 15-stage gauntlet.

| Route | Stages | Use case |
|-------|--------|----------|
| `NEW_FEATURE` | All 15 | New capability end-to-end |
| `BUG_FIX` | ~10 | Fix with full test cycle |
| `HOTFIX` | ~4 | Critical fix, fast path |
| `CONFIG_CHANGE` | ~5 | Env vars, feature flags |
| `REFACTOR` | ~10 | Quality work, behavior unchanged |

### 4-tier story pipeline with full traceability

```
PRD → Master Story → Sprint Story → Tech Task → Branch → PR → ADO Work Item
```

```bash
sdlc story create sprint   # scaffold a sprint story from template
sdlc story validate        # check AC format, traceability
sdlc story push            # push to Azure DevOps as linked work item
```

### Ask-first protocol

**AI never acts without asking.** Every destructive action, state change, and gate transition requires explicit human approval. Not as a block — as a habit.

```
AI: "I plan to modify 3 files for US-1234:
     1. UserService.java — add validation
     2. UserController.java — new endpoint  
     3. api.yaml — update contract schema
     Proceed?  (1) Yes  (2) Edit plan  (3) Cancel"
```

### RPI workflow (Research → Plan → Implement → Verify)

For changes touching multiple files, the platform enforces a serialized workflow with human approval at each phase — no silent rewrites.

```bash
sdlc run 08-implementation   # triggers RPI loop for the current task
```

### Repo-grounded design

Design and implementation stay **anchored to real artifacts**, not abstract bullets:

- Design template **§0** captures existing paths, contracts, and backward-compatibility risks before any code is written
- Module knowledge (`.sdlc/module/`) refreshed with `sdlc module update .`; loaded efficiently with `sdlc module load api` (not the whole tree)
- Rules enforce **regression-aware** testing at implementation complete (`rules/repo-grounded-change.md`)

### Module system (token-efficient context)

```bash
sdlc module init .                    # generate module knowledge for your app repo
sdlc module show                      # compact overview
sdlc module load api|data|events|logic # load only the slice you need
sdlc module validate                  # check for breaking changes before merge
```

### Git hooks (quality at commit-time)

22 hooks covering: secrets detection, commit message format, documentation sync, token budget checks, module contract validation, **semantic memory sync**, and **pre-merge test enforcement**. Issues caught at commit — not at PR review.

**Semantic Memory Hooks:**
- `semantic-memory-pre-commit.sh` — Exports active semantic memory to JSONL for team sync
- `semantic-memory-post-merge.sh` — Imports team semantic memory after pull/merge

**Pre-merge Test Enforcement:**
- `pre-merge-test-enforcement.md` — Policy requiring tests to pass before merge (with structured bypass via `sdlc skip-tests`)
- `test-bypass-escalation.sh` — Escalation workflow for test bypass approval

### Advisory gates (inform, don't block)

10 quality gates. All advisory. AI validates evidence and surfaces findings. Humans decide to proceed, fix, skip, or pause. No bottlenecks; full audit trail.

---

## Architecture

```
Roles → Agents → Skills → Stages
```

```
├── agents/          # AI personas — compose skills, no duplicated logic
├── skills/          # Atomic, single-responsibility capabilities
├── rules/           # Governance: ask-first, gates, traceability, quality, tokens
├── stages/          # 01-requirement-intake → 15-summary-close
├── stacks/          # Stack conventions: Java, Kotlin/Android, Swift/iOS, React Native, JMeter, Figma
├── roles/           # 8 role definitions with token budgets
├── cli/             # sdlc CLI (Bash + completions) + utilities (ado-html-to-validator-md.js)
├── hooks/           # 22 git hooks + semantic memory sync
├── templates/       # PRD, 4-tier stories, design, ADR, test plans
├── workflows/       # Workflow YAML (full-sdlc, quick-fix, perf-cycle, …)
├── orchestrator/    # Smart routing, gate enforcement, ADO observer (2-way sync)
├── memory/          # Semantic memory system (SQLite + JSONL team sync)
└── User_Manual/     # Markdown manual + searchable manual.html (see build-manual-html.mjs ORDER)
```

> **Context loading is tiered:** Tier 1 (always) → Tier 2 (if space) → Tier 3 (on demand). Stage files specify exactly what to load. See [`User_Manual/Architecture.md`](User_Manual/Architecture.md).

---

## Who it's for

| Role | What you get |
|------|-------------|
| **CTO / Engineering Director** | Org-wide governance, audit trail, token cost visibility, extensible without rewrites |
| **Engineering Lead** | Architecture enforcement, cross-pod contract validation, quality gates |
| **Developer** | One CLI, atomic skills, guided error recovery, RPI workflow |
| **Product Manager** | Story pipeline, PRD-to-ADO traceability, grooming flows |
| **QA Engineer** | Test design stage, regression scope in templates, pre-merge enforcement |
| **TPM** | Sprint visibility, gate status, cross-team dependency tracking |

---

## Design principles

1. **Atomic skills, thin agents** — skills have single responsibility; agents compose them, never duplicate logic
2. **Ask-first** — AI proposes, humans decide; no silent production actions ever
3. **Gates inform, don't block** — advisory checkpoints with justifiable skip; not bottlenecks
4. **Repo-grounded** — work anchors to real files, contracts, and tests; not abstract descriptions
5. **Token-aware** — smart context loading per stage; sliced module access; budget per role
6. **Single source of truth** — one `User_Manual/`, one CLI, one registry per asset type

---

## Documentation

**Everything lives in [`User_Manual/`](User_Manual/README.md)** — one hub, one source of truth.

| Need | Read |
|------|------|
| **Browse offline (searchable HTML)** | **[`User_Manual/manual.html`](User_Manual/manual.html)** — open in browser after clone |
| What is this? | [System Overview](User_Manual/System_Overview.md) |
| First run | [Getting Started](User_Manual/Getting_Started.md) |
| Commands reference | [Commands](User_Manual/Commands.md) |
| End-to-end happy path | [Happy Path End to End](User_Manual/Happy_Path_End_to_End.md) |
| Agents, skills, rules inventory | [Agents Skills Rules](User_Manual/Agents_Skills_Rules.md) |
| ADO / MCP integration | [ADO MCP Integration](User_Manual/ADO_MCP_Integration.md) |
| Semantic Memory System | [Persistent Memory](User_Manual/Persistent_Memory.md) |
| Pre-merge Test Enforcement | [Pre-Merge Test Enforcement](rules/pre-merge-test-enforcement.md) |
| Cursor / Claude / CLI | [CANONICAL_REPO_AND_INTERFACES](User_Manual/CANONICAL_REPO_AND_INTERFACES.md) |
| Architecture deep-dive | [Architecture](User_Manual/Architecture.md) |
| Troubleshooting | [FAQ](User_Manual/FAQ.md) |

#### Automatic Documentation Updates

The platform includes **git hooks** that automatically regenerate `User_Manual/manual.html` whenever documentation files change. No manual intervention needed.

**Setup hooks (one-time):**
```bash
# Linux/Mac:
bash hooks/setup-hooks.sh

# Windows:
setup-hooks.cmd
```

**How it works:**
- **Pre-commit hook** — Detects changes to `User_Manual/*.md`, `docs/*.md`, `rules/*.md`, `skills/*.md`, `agents/*.md`, `stages/*.md`, or `templates/*.md` and auto-regenerates `manual.html` before every commit
- **Pre-push hook** — Verifies `manual.html` is current before allowing push to remote (blocks push if outdated)

**Manual regeneration** (if needed):
```bash
node User_Manual/build-manual-html.mjs
```

---

## Extensibility

No platform rewrites. Add capabilities by following existing patterns:

| Add | What to create | Also update |
|-----|---------------|-------------|
| New role | `roles/` + `agents/` folder | `agent-registry.json`, relevant stages |
| New skill | `skills/<role>/<skill>/SKILL.md` | `skills/SKILL.md` registry |
| New stack | `stacks/<stack>/` conventions | `cli/lib/config.sh` |
| New stage | `stages/<n>-name/STAGE.md` | Routing + adjacent stages |
| New rule | `rules/<rule>.md` | `rules/README.md` index |

---

## Contributing

1. Fork and create a feature branch
2. For changes touching multiple files, follow the **RPI workflow** and **repo-grounded rules**
3. Run `sdlc doctor` before submitting
4. Open a PR — commit messages and traceability matter (see `rules/commit-conventions.md`)

All contributions pass pre-commit hooks: secrets detection, commit format, documentation sync.

---

## License

[GNU General Public License v3.0](LICENSE) — open source, share alike.

---

## Previous documentation

94+ files from earlier versions remain available in **git history**.

---

<p align="center">
  <strong>AI-SDLC Platform</strong> — Calm, precise, traceable delivery with AI.<br/><br/>
  If this helps your team, ⭐ the repo — it helps others find it.
</p>
