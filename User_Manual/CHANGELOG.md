# User Manual Changelog

All notable changes to the AI-SDLC User Manual are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Versioning Policy

- **MAJOR** (X.0.0): Breaking changes to pipelines, stages, commands, roles, or fundamental architecture
  - Example: Stage renamed, command signature changed, workflow restructured
  - User action required: Review changes, may need adaptation
  - Release frequency: Quarterly or as needed

- **MINOR** (0.X.0): New features without breaking compatibility
  - Example: New agent, new skill, new command, new integration
  - User action: Optional, new features available
  - Release frequency: Weekly or per sprint

- **PATCH** (0.0.X): Bug fixes, clarifications, documentation improvements
  - Example: Typo fixes, clarified instructions, improved examples
  - User action: None required
  - Release frequency: As needed

---

## [2.1.4] - 2026-04-22

### Added — Acceptance Criteria Field Support

- **Dedicated AC field population** — Stories now populate `Microsoft.VSTS.Common.AcceptanceCriteria` instead of embedding AC in description
  - CLI extracts AC from `## Acceptance Criteria` section in markdown
  - AC converted to HTML and sent to dedicated ADO field
  - Description field contains only narrative content (before AC section)
  - Updated: `cli/lib/ado.sh` — `_ado_push_story()` and `_ado_create()` functions

### Changed — Master Story Guidance

- **Master stories default to User Story** (not Feature)
  - Updated help text: `sdlc story push` now recommends `--type=story` for master stories
  - Rationale: Master stories contain AC for complete user journeys; Feature type only needed for portfolio roll-up
  - `--type=feature` still available for cross-cutting initiatives

### Updated — Family Hub Work Items

- Populated acceptance criteria field for existing work items:
  - 865620 (Master Story - Family Hub Phase 1) — AC extracted and updated
  - 865621 (Sprint 3 - Hub Creation & Invite) — AC extracted and updated
  - 865622 (Sprint 4 - Member Management) — AC extracted and updated

### Documentation

- `User_Manual/ADO_MCP_Integration.md` — Added AC field section and work item type guidance
- `cli/commands/story.sh` — Updated help text for master story recommendations

---

## [2.1.3] - 2026-04-22

### Added — ADO Search Commands (CLI)

- **`sdlc ado search <query>`** — Search Azure DevOps work items via CLI without MCP
  - Text search: `sdlc ado search "Family Hub"`
  - State filter: `sdlc ado search state=Active`
  - Type filter: `sdlc ado search type=Feature`
  - Assignee filter: `sdlc ado search assignedTo=me`
  - Combined filters: `sdlc ado search "Family Hub" state=Proposed type=Feature`
  - Result limiting: `--top N` flag
  - Implementation: WIQL-based query via ADO REST API v7.0

- **`sdlc ado get <id>`** — Quick formatted summary of work item
  - Box-style formatted output (ID, Type, State, Title, Assigned, Description)
  - Direct link to ADO work item
  - Faster than `show` for quick lookups

### Changed — Documentation

- `User_Manual/Commands.md` — Added ADO search command reference with filter table
- `User_Manual/ADO_MCP_Integration.md` — Added quick reference table (CLI vs MCP search)
- `cli/sdlc.sh` — Updated help text with new `search` and `get` commands
- `cli/lib/ado.sh` — Added `_ado_search()` and `_ado_get()` functions

### Why This Matters

**Offline/No-MCP Access:** Teams can now search ADO work items without MCP setup or when MCP is unavailable. CLI-only environments (CI, restricted workstations) get full search capability.

**Token Efficiency:** CLI search uses ~200 tokens vs ~800 tokens for MCP roundtrip.

**Pattern Established:** Organization-specific stories stay local (not in repo), ADO references in `memory/team/product/` provide discoverability, CLI search bridges the gap.

---

## [2.1.2] - 2026-04-20

### Added — Token-optimization v2: env knobs + stage re-run guard

- **`SDL_TOKEN_BUDGET_MULTIPLIER`** — scales all role + stage budgets. Default `1.0`;
  set `0.8` to tighten team discipline by 20%. Wired in `scripts/token-blocker.sh::check_token_limit()`.
- **`SDL_MODULE_CACHE_TTL`** — module smart-load cache TTL (seconds). Default `3600`;
  set `86400` for single-day focused sprints. Wired in `scripts/module-load.sh::check_cache()`.
- **`SDL_FORCE_RERUN`** — suppress the new "stage already completed" warning.
  Default `0`.
- **Stage re-run guard** in `cli/lib/executor.sh::cmd_run()` — warns when
  `.sdlc/memory/<stage>-completion.md` exists, offers three paths (load prior output,
  `sdlc recall`, or force re-run). Prevents the re-run-of-completed-stage waste pattern.
- **Ready-to-use config template** at `env/.env.tokens-optimized.template` with
  documented defaults for all three knobs + `SDL_MODEL` + `SDL_SKIP_MODULE_INIT`.

### Changed — tightened guidance

- `rules/token-optimization.md` — new **"Further Reductions (v2.1.2) — 10 Levers"**
  section with ranked, measurable levers (L1-L10) and the env-knob reference table.
- `rules/rpi-workflow.md` (+ IDE mirror) — strict RPI threshold: NEW_FEATURE requires
  >3 files **AND** >1 module contract touched. Explicit skip triggers added for
  additive-API, test-only, docs-only changes. Token rationale called out.
- `rules/token-enforcement.md` IDE mirror — version bumped to 2.1.2, env-knob table
  inlined, cross-link to canonical optimization playbook.
- `User_Manual/Token_Efficiency_and_Context_Loading.md` — "Further Reductions"
  section mirrors the canonical rule and links back.

### Follow-ups

- Measure baseline spend (`sdlc tokens`) per-team before rolling out `SDL_TOKEN_BUDGET_MULTIPLIER=0.8`.
- Add a platform-ci check that fails if a story's actual spend >120% of recommended lane.
- Extend `sdlc cost` to show per-lever contribution (future minor version).

---

## [2.1.1] - 2026-04-20

### Added — Atomic design, CI enforcement, ADO observer idempotency

**Atomic skills (3 new, registry bumped to 8 total)**
- `skills/shared/update-documentation/` — align README, wiki, ADRs, User_Manual when behavior/contracts change
- `skills/shared/sync-to-ado/` — outbound ADO CRUD; wires to `cli/`, `orchestrator/ado-observer/`, agent refs
- `skills/shared/generate-or-validate-unit-tests/` — **blocking** pre-dev-complete test gate; bypass requires ADO work-item comment
- `skills/registry.json` bumped `2.1.0 → 2.1.1`, `total_skills 0 → 8`

**IDE slash commands — thin router pattern (Option C)**
- 16 `project-*.md` files rewritten as 7-line routers delegating to base commands with `--project` flag
- New routing design doc: `.claude/commands/COMMAND_ROUTING.md`
- Eliminates prior twin-command duplication; base commands remain single source of truth

**CI enforcement on `main` / `master` / `develop`**
- `.github/workflows/sdlc-ci.yml` gains three blocking jobs:
  - `pr-traceability` — regex-asserts `PRD-REF-*-SEC*` and `AB#*` on PR body
  - `claude-mirror-drift` — fails if `.claude/{agents,skills,templates}` drift from canonical
  - `platform-ci` — full `scripts/ci-sdlc-platform.sh` lint gate
- New: `.github/pull_request_template.md` with Traceability section

**Cross-platform `.claude` SSOT (Mac + Windows)**
- `scripts/sync-claude-mirrors.sh` — regenerates `.claude/{agents,skills,templates}` as byte-identical copies
- `scripts/verify-claude-ssot-ci.sh` — accepts both symlink and generated-copy modes; `diff -rq` for drift detection
- Removes symlink incompatibility with Windows

**ADO observer (`orchestrator/ado-observer/observer.py`)**
- `EVENT_STAGE_MAP` — state-transition → stage-id table (stub with TODO entries; no-op when empty)
- `resolve_stage_for_transition(from, to)` — exact → `from:*` → `*:to` fallback chain
- Idempotency cache with 1 h TTL on `work_item + rev + event_type` and ADO `eventId`
- Hooked into both `_process_work_item` (polling) and `handle_webhook` (webhook) paths

**Rules**
- `generate-or-validate-unit-tests` skill is mandatory/blocking; all other rules remain advisory
- Gate bypass must be recorded as an ADO work-item comment (enforced via observer)
- `rules/` self-duplication removed

**Docs**
- New: [`REPO_LAYOUT.md`](../REPO_LAYOUT.md), [`User_Manual/Enforcement_Contract.md`](Enforcement_Contract.md), [`User_Manual/Traceability_and_Governance.md`](Traceability_and_Governance.md), [`agents/REGISTRY_AND_ATOMIC_DESIGN.md`](../agents/REGISTRY_AND_ATOMIC_DESIGN.md)
- Updated: Architecture, Agents_Skills_Rules, Commands, ADO_MCP_Integration, PR_Merge_Process
- `User_Manual/VERSION` → `2.1.1`

### Follow-ups

- Populate `EVENT_STAGE_MAP` with definitive ADO state transitions (operational rollout)
- Regenerate `AI_SDLC_Platform/` public mirror from updated canonical tree
- Run `bash scripts/sync-claude-mirrors.sh` once to baseline `.claude/` mirror copies

---

## [Unreleased]

### Changed (tooling & governance)

- **`cli/lib/ado.sh`:** Non-interactive `sdlc ado create` / `push-story` no longer POSTs to ADO without **`--yes`** or **`SDLC_ADO_CONFIRM=yes`** (TTY unchanged: prompt before create).
- **`sdlc skip-tests`:** **`--reason=`** is **required** with at least **10 characters** (audit trail for bypassing test enforcement).
- **`scripts/verify-platform-registry.sh`:** Verifies every `path` in `agents/agent-registry.json` exists and fails on **duplicate agent IDs** across tiers.
- **Docs:** [Enforcement_Contract](Enforcement_Contract.md), [Traceability_and_Governance](Traceability_and_Governance.md); [agents/REGISTRY_AND_ATOMIC_DESIGN.md](../agents/REGISTRY_AND_ATOMIC_DESIGN.md); [gate-informant](../agents/shared/gate-informant.md) table wording (soft vs hard enforcement); mirror [README](../scripts/mirror-public/README.md) (edit Azure first).

---

## [2.0.0] - 2026-04-17

### Platform v2.1.0 Architecture Update

This release introduces the **atomic skills architecture** and **2-way ADO synchronization** while maintaining 100% backward compatibility.

#### Added

**Skill Registry & Routing**
- `skills/registry.json` — Central capability registry with routing, caching, and validation
- `cli/lib/skill-router.sh` — Tiered skill routing (composed → generic → legacy)
- Schema validation for skill inputs/outputs
- Per-skill token budgets and model selection
- Cache configuration with TTL and invalidation triggers

**Atomic Skills**
- `skills/atomic/ado-fetch.md` — Fetch ADO work items (50 tokens)
- `skills/atomic/codebase-search.md` — Search repository (100 tokens)
- `skills/atomic/file-extract.md` — Read file excerpts (50 tokens)
- `skills/atomic/wiki-lookup.md` — Search WikiJS (50 tokens)
- `skills/atomic/risk-identify.md` — Analyze risks (200 tokens)

**Composed Skills**
- `skills/composed/rpi-research.yaml` — 5-step research workflow
- `skills/composed/rpi-plan.yaml` — 4-step planning workflow
- YAML-based declarative skill composition
- Dependency management between steps
- Per-step caching and error handling

**ADO Observer System (2-Way Sync)**
- `orchestrator/ado-observer/observer.py` — Event-driven ADO sync
- Webhook mode (real-time) and polling mode (fallback)
- Trigger handlers for: risk acceptance, gate approval, state changes
- Pattern matching for ADO comments
- Cooldown mechanism to prevent duplicate triggers

**Stage Composition DSL**
- `stages/08-implementation/composition.yaml` — Declarative stage definition
- RPI workflow integration (Research → Plan → Implement)
- Gate checkpoints with ADO comment channels
- ADO actions on phase completion/approval/rejection

**Skill Discovery & Management**
- `cli/lib/skill-discovery.sh` — Interactive skill discovery UI
- `sdlc skills discover` — Filter by role/stage/category
- `sdlc skills register` — 5-minute skill registration
- `sdlc skills cache clear` — Cache management
- `sdlc skills invoke-composed` — Execute YAML workflows

**Composition Engine**
- `cli/lib/composition-engine.py` — Python-based YAML executor
- Variable interpolation (`$var`, `${expression}`)
- Dependency graph resolution
- Parallel step execution where safe
- Result caching per step

**Migration Support**
- `scripts/migrate-v2.1.sh` — Safe migration with `--check`, `--apply`, `--rollback`
- 100% backward compatibility verification
- Legacy fallback chain for all skills
- Documentation: `Migrating_From_V2_to_V2.1.md`

#### Changed

**Documentation**
- `Architecture.md` — Added skill architecture section, ADO observer, compatibility guarantees
- `Commands.md` — Added skill discovery commands, cache management
- `Agents_Skills_Rules.md` — Added atomic vs composed skills, skill registry explanation
- `ADO_MCP_Integration.md` — Added 2-way sync, ADO observer setup, trigger examples

#### Backward Compatibility

- All existing skills (`skills/*.md`) continue to work unchanged
- All existing stages (`stages/*/STAGE.md`) continue to work
- All existing commands work identically
- Router automatically falls back to legacy implementations
- Opt-in only: new features don't affect existing workflows

#### Migration Path

1. Run `bash scripts/migrate-v2.1.sh --check`
2. Verify no breaking changes
3. Optionally explore `sdlc skills discover`
4. Gradually adopt new features as needed

Full migration guide: `Migrating_From_V2_to_V2.1.md`

---

## [1.0.16] - 2026-04-17

### Changed

- **[System_Overview.md](System_Overview.md)** — Added **§2a** (where it runs: platform vs app repo, terminal vs IDE, split of module KB / memory / ADO) and **§2b** (how this page links to SDLC_Flows, Features, Commands, Happy path). Softened absolute claims on memory/ADO; **§7** inventory now points to live repo counts + `sdlc doctor`.
- **[SDLC_Flows.md](SDLC_Flows.md)** — Added **per-stage tables (01–08, 09–15)** with what / typical inputs / outputs & where / `sdlc run` / slash commands; expanded **stage execution** with **What / How / Where** and path table to `stages/`, `.sdlc/`, ADO.
- **[INDEX.md](INDEX.md)** — Manual-order rows for **System_Overview** and **SDLC_Flows** note new §§ (§2a/§2b; per-stage I/O + execution depth).

## [1.0.15] - 2026-04-17

### Changed

- **[build-manual-html.mjs](build-manual-html.mjs)** — **`ORDER`** resequenced for a **linear learning path**: overview → prerequisites → getting started → repo/IDE layout → happy path → flows → roles → **features deep dive** → commands → recovery → memory → ADO/MCP → agents → architecture → PR → extension → doc rules → V1 migration → FAQ → changelog.
- **[FEATURES_REFERENCE.md](FEATURES_REFERENCE.md)** — Rewritten as **“Features — how they work”**: per-area **what it is**, **how it works** (numbered steps), **read more** links (setup, stages, flows, roles, module, memory, stories, ADO layers, agents/rules, tokens, hooks, docs, extension/CI).
- **[INDEX.md](INDEX.md)** — **Manual order** table (#1–#23) matches sidebar; alphabetical list moved to **lookup** section; goal table points at numbered flow.
- **[README.md](README.md)** — Short navigation table **numbered** to match sidebar; intro points to top-to-bottom reading.

## [1.0.14] - 2026-04-17

### Added

- **[INDEX.md](INDEX.md)** — Layman **reading guide**, full page list, glossary, `manual.html` search tips, Cursor agent note.
- **[FEATURES_REFERENCE.md](FEATURES_REFERENCE.md)** — **Features A–Z** (setup, stages, stories, ADO, memory, module KB, agents, CI, docs).

### Changed

- **[README.md](README.md)** — Rewritten as a friendly **home** page with full short navigation and search behavior.
- **[FAQ.md](FAQ.md)** — Table of contents; **Cursor / non-interactive setup**; multi-word search Q&A; index pointer (plus existing Module KB troubleshooting).
- **[Persistent_Memory.md](Persistent_Memory.md)** — **Plain words** table: semantic memory vs module KB before technical sections.
- **[Happy_Path_End_to_End.md](Happy_Path_End_to_End.md)** — Cursor / `SDL_SETUP_*` setup note.
- **[manual-client.js](manual-client.js)** — Search matches **all words** (AND); per-token highlights; skip nested marks.
- **[build-manual-html.mjs](build-manual-html.mjs)** — Order: **INDEX** after Home, **FEATURES_REFERENCE** before PR merge; sidebar titles for new pages.
- **`scripts/module-init.sh`** — **Stack detection:** when `pom.xml` / `build.gradle` / `build.gradle.kts` are not at the git repo root (monorepos), scan nested paths up to depth 8 so Java/Maven/Gradle projects are classified as **`java`** instead of **`unknown`**. **API contracts:** for **`java`** / **`java-android`**, scan **RestExpress / JAX-RS**-style **`@Path("…")`** in addition to Spring **`@GetMapping`** / **`@RequestMapping`**. Extracted paths are per-annotation segments (combine with controller base paths for full URLs).
- **[Commands.md](Commands.md)** — Module system: monorepo stack detection and `@Path` scanning notes.

## [1.0.13] - 2026-04-15

### Changed

- **[FAQ.md](FAQ.md)** — Clarified why **`sdlc doctor`** / **Rule Files Validation** can feel slow (OneDrive, `find`, full `agents/` + `skills/` scan).
- **`scripts/validate-rules.sh`** — Faster bypass detection (one combined `grep` per file when no match); shallow `find` for rule count; extended-regex for action-verb check.

## [1.0.12] - 2026-04-16

### Changed

- **[V2_Improvements_Over_V1.md](V2_Improvements_Over_V1.md)** — Expanded V2 vs V1 comparison: **NL + CLI** (§2), **semantic JSONL + auto-sync** (§5), **`USER_INPUT_REQUIRED`** story governance (§6), **registry generation** + **`.claude/commands`** bootstrap (§9), slash+NL IDE (§10); summary table rows for NL/CLI and story quality. Agent/skill counts refreshed (~35 skills, 4 orchestrators).

## [1.0.11] - 2026-04-16

### Added

- **[Commands.md](Commands.md)** — **Natural language (NL) and CLI together**: table mapping stages, `sdlc route`, `sdlc module load`, `sdlc memory semantic-query`, and delegation pattern; links to [Happy_Path_End_to_End](Happy_Path_End_to_End.md) and [Persistent_Memory](Persistent_Memory.md).

### Changed

- **Story templates** — [STORY_TEMPLATE_REGISTRY.md](../templates/story-templates/STORY_TEMPLATE_REGISTRY.md): *Missing source material* policy and `USER_INPUT_REQUIRED` pattern; Master/Sprint/Tech/Task templates and **story-generator** / **sprint-story-generator** / **tech-task-generator** / **story-validator** skills aligned (no invented prose when PRD/parent is missing).
- **Registries** — `scripts/regenerate-registries.sh`: ensure `.claude/commands` exists before writing `COMMANDS_REGISTRY.md` (fresh clones without that directory).

## [1.0.10] - 2026-04-16

### Changed

- **Canonical clone URL** — User Manual now documents the **Azure DevOps** repo  
  `https://github.com/YOUR_GITHUB_USER/ai_sdlc_platform.git` (project **YourAzureProject**) in [README](README.md), [Getting_Started](Getting_Started.md), [CANONICAL_REPO_AND_INTERFACES](CANONICAL_REPO_AND_INTERFACES.md), [Happy_Path_End_to_End](Happy_Path_End_to_End.md), [Commands](Commands.md), and [Prerequisites](Prerequisites.md).

## [1.0.9] - 2026-04-15

### Added

- **`sdlc story push` / `sdlc ado push-story`** — Optional **`--type=story|feature|epic`** (default `story` → User Story). Use **`--type=feature`** to create an Azure DevOps **Feature** from a filled master story file; documented in [Commands](Commands.md), [FAQ](FAQ.md), [SDLC_Flows](SDLC_Flows.md), and [master-story-template.md](../templates/story-templates/master-story-template.md). Native helpers: **`scripts/ado-mac.sh`** (`--type=…`), **`scripts/ado.ps1`** (`-pushType`).

## [1.0.8] - 2026-04-16

### Added

- **[Platform_Extension_Onboarding.md](Platform_Extension_Onboarding.md)** — Checklist for adding agents, rules, skills, roles/stacks, stages and SDLC flows; CI and manual regeneration notes.

### Fixed

- **`cli/lib/config.sh`** — `STACK_VARIANT_MAP[jmeter]` now points to variant file basename `jmeter-perf` (matches `stages/*/variants/jmeter-perf.md`).

---

## [1.0.7] - 2026-04-16

### Documentation

- **Getting_Started.md** — Full-tree symlinks for `agents/`, `skills/`, `templates/`; `repair-claude-mirrors.sh`; CI notes for registry + stage checks.
- **SDLC_Flows.md** — Stack variants and shared RPI baseline (`stages/_includes/`, stage 08).
- **FAQ.md** — Nested `.claude/` paths; registry drift; `validate-stage-variants` failures.

---

## [1.0.6] - 2026-04-14

### Added

- **[Happy_Path_End_to_End.md](Happy_Path_End_to_End.md)** — Full **happy path** from PRD / design through stories, implementation, unit tests, local merge, and Azure DevOps Git; tables for **pre/post** steps, **CLI**, **slash commands**, and **NL**; links to detail docs only (single narrative).

### Documentation

- **README.md** — Navigation entry; **Getting_Started.md** — pointer; **Documentation_Rules.md** — auto-update trigger; **build-manual-html.mjs** — include in offline manual order.

---

## [1.0.5] - 2026-04-15

### Added (tooling)

- **`cli/lib/logging.sh`**: `log_recovery_footer`, `log_hint`, `log_error_recovery` — standard **“── Next steps ──”** block after recoverable errors.
- **`.cursor/rules/guided-recovery.mdc`**: Always-on assistant rule — on CLI/setup errors, output **numbered** recovery steps and **copy-paste** `sdlc` syntax.
- **`scripts/verify-platform-registry.sh`**: Validates **stages** ↔ `cli/lib/config.sh`, **`agents/agent-registry.json`** (jq), **`rules/*.md`** count.

### Changed (CLI polish)

- **`guards.sh`**: ASK-in-chat paths append recovery footer.
- **`executor.sh`**: Recovery on invalid role/stack/stage, **run** without role, token block, **flow** (workflow + role), **sync/publish**, **gate-check**, **template**, **agent/skills** usage, **skip-tests** / **clear-test-skips**.
- **`ado.sh`**: Missing ADO credentials → hint + recovery footer.
- **`sdlc.sh`**: Unknown command + **module** missing script → recovery footer.

### Tests

- **`cli/tests/smoke.sh`**: Asserts **“Next steps”** in output for invalid command / role / stage; runs **`verify-platform-registry.sh`** when present.

### Documentation automation

- **`User_Manual/manual.html`**: Regenerated automatically on **pre-commit** when staged files include `User_Manual/*.md`, `VERSION`, or the HTML generator/client (`hooks/pre-commit.sh` Step 2c). **`build-manual-html.mjs --check`** in **`scripts/ci-sdlc-platform.sh`** fails CI if the offline manual drifts from sources.
- **`Documentation_Rules.md`**, **`rules/user-manual-sync.md`**: Describe the above.

### Documentation

- **Commands.md**, **Guided_Execution_and_Recovery.md**, **Agents_Skills_Rules.md** — updated for recovery UX and registry script.

---

## [1.0.4] - 2026-04-14

### Documentation

- **Getting_Started.md** — Setup steps aligned with `setup.sh` (git hooks list, CI `--quick` step 9).
- **Persistent_Memory.md** — Team sync table (SQLite vs JSONL vs module KB); cross-reference to [Commands](Commands.md) only.
- **Documentation_Rules.md** — Auto-update triggers for CI / auto-sync; doctor note for CI files.
- **Prerequisites.md** — Doc verification table: CI script + pipelines row.
- **README.md** — Commands row clarifies auto-sync + CI.

---

## [1.0.3] - 2026-04-15

### Added

- **Guided_Execution_and_Recovery.md** — How guided execution works across **CLI, bash, Cursor, Claude Code, NL**: TTY vs non-TTY, **ASK in chat** messages, step-by-step recovery, assistant behavior (show exact `sdlc` syntax), `sdlc doctor`, common failure → next command table.

### Documentation

- **README.md** — Navigation entry; **FAQ.md** — link for “ASK in chat” / next steps.

---

## [1.0.2] - 2026-04-15

### Added

- **Role_and_Stage_Playbook.md** — Playbook for all **8 roles** and **15 stages**: primary ownership, typical chain of command, handoffs, per-stage summary with pointers to `roles/*.md` and `stages/*/STAGE.md`. Clarifies that guidance is **not** automated execution.

### Documentation

- **README.md** — Quick navigation entry for the playbook.
- **SDLC_Flows.md** — Cross-link to the playbook after the role/stage table.

---

## [1.0.1] - 2026-04-15

### Added

- **Migrating_From_V1_to_V2.md** — Step-by-step migration from `ai-claude-platform` (V1) to `ai-sdlc-platform` (V2): team→role mapping, setup, memory, ADO, rollback.
- **V2_Improvements_Over_V1.md** — Feature and architecture comparison across CLI, stages/workflows, agents/skills/rules, memo