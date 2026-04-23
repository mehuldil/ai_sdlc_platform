# Documentation Rules

## Single Source of Truth

- `/User_Manual/` is the ONLY active documentation
- All previous docs (94 files) available in git history
- Each concept defined **once** — other docs cross-reference

## Documentation Style

- Concise, bullet-first
- No long paragraphs
- No duplication across files
- Tables over prose where possible
- Add "ask for details" prompts instead of over-explaining

## Atomic Documentation Principle

| Rule | Meaning |
|------|---------|
| Single definition | Each concept exists in exactly one file |
| Cross-reference | Other files link to the source, never copy |
| Minimal verbosity | State the fact, not the explanation |
| Ask-first model | "For details, ask: [question]" instead of 5 paragraphs |

## Cursor / Agent rule (enforced in-IDE)

- **File:** `ai-sdlc-platform/.cursor/rules/user-manual-sync.mdc` — applies when editing files under `skills/`, `agents/`, `rules/`, or `cli/` (see globs in that file).
- **Canonical text:** `ai-sdlc-platform/rules/user-manual-sync.md`
- **Claude Code:** `ai-sdlc-platform/.claude/rules/user-manual-sync.md`

## Offline manual (`manual.html`)

- **Generated** from `User_Manual/*.md` + `VERSION` via `node User_Manual/build-manual-html.mjs`.
- **Pre-commit:** if you stage any `User_Manual/*.md`, `VERSION`, or the generator/client scripts, **`hooks/pre-commit.sh` regenerates and stages `User_Manual/manual.html` automatically** (requires Node on PATH).
- **CI:** `node User_Manual/build-manual-html.mjs --check` fails if `manual.html` drifts from sources.

## Auto-Update Triggers

Any change to these components **MUST** trigger a documentation update:

> **Auto-Documentation-Guardian:** The `auto-documentation-guardian` agent (Tier 1 Universal) automatically monitors these triggers and ensures User Manual stays current, simple, non-duplicative, and minimal. See [`Agents_Skills_Rules.md`](Agents_Skills_Rules.md) for agent details.

| Changed | Update In |
|---------|-----------|
| New/modified skill | [Agents_Skills_Rules](Agents_Skills_Rules.md) |
| New/modified agent | [Agents_Skills_Rules](Agents_Skills_Rules.md) |
| New/modified rule | [Agents_Skills_Rules](Agents_Skills_Rules.md) |
| New/modified command | [Commands](Commands.md) |
| New/modified stage | [SDLC_Flows](SDLC_Flows.md) |
| New/modified workflow | [SDLC_Flows](SDLC_Flows.md) |
| New/modified default E2E narrative (stages, merge, interfaces) | [Happy_Path_End_to_End](Happy_Path_End_to_End.md) |
| New/modified integration | [ADO_MCP_Integration](ADO_MCP_Integration.md) |
| Architecture change | [Architecture](Architecture.md) |
| New PR template | [PR_Merge_Process](PR_Merge_Process.md) |
| Component count change | [System_Overview](System_Overview.md) |
| CI script / `ci-sdlc-platform.sh` / GitHub or Azure YAML | [Commands](Commands.md) (CI section) + [Prerequisites](Prerequisites.md) (verify table) |
| Module KB / semantic auto-sync / `sdlc-auto-sync.sh` | [Commands](Commands.md) (Auto-sync) + [Persistent_Memory](Persistent_Memory.md) (table + link only) |

## Verifying documentation is complete

Run **`sdlc doctor`** (includes documentation drift, command consistency, generated-registry checks, and **CI definition files**). For a manual checklist and exact commands, see [Prerequisites](Prerequisites.md) — section *Confirm all documentation is up to date*. Full pipeline parity: `bash scripts/ci-sdlc-platform.sh` (see [Commands](Commands.md), section *CI*).

## Pre-Merge Documentation Check

Enforced by `hooks/doc-change-check.sh`:

1. Detects if changed files are in: skills/, agents/, rules/, stages/, workflows/, cli/
2. Checks if any file in User_Manual/ was also modified
3. If system files changed but User_Manual/ NOT updated → **WARN** (logged to `.sdlc/logs/doc-drift.log`)

## Change Validation Hooks

| Hook | What It Catches | Guardian Integration |
|------|----------------|---------------------|
| `doc-change-check.sh` | System files changed without doc update | Triggers auto-documentation-guardian analysis |
| `pre-merge-duplication-check.sh` | New skills/agents duplicating existing ones | Guardian runs duplication validation |
| `commit-msg.sh` | Commit format violations | — |
| `branch-name-check.sh` | Invalid branch naming | — |

## Traceability Map

```
Commands → reference → Agents → invoke → Skills
   ↓                      ↓                ↓
 Stages ←── Gates ←── Rules ←── Stacks
```

Every command traces to an agent, which traces to skills, which map to SDLC stages.

## Adding Documentation

1. Identify which `/User_Manual/` file owns the topic
2. Add content to that file ONLY
3. If new topic doesn't fit existing files → discuss before creating new file
4. Never create standalone `.md` files outside `/User_Manual/`

> For doc governance details, ask: "Explain the documentation validation pipeline"
