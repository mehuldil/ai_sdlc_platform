# Rules index (canonical `rules/`)

Single source of truth for platform governance. Cursor loads these via project setup as `.cursor/rules/rule-*.md`; Claude Code may use condensed copies under `.claude/rules/` — edit **here**, then sync condensed variants if your process requires it.

## How to use this index

- **Thematic overlap is intentional:** several files touch “quality” or “compliance” from different angles (e.g. product vs engineering vs operations). Use this table to pick the **narrowest** file for your task; cross-link in chat when multiple apply.
- **Always load first for user-facing work:** [`ask-first-protocol.md`](ask-first-protocol.md), [`rpi-workflow.md`](rpi-workflow.md), [`gate-enforcement.md`](gate-enforcement.md) (operations and ADO gates).
- **Delegation (Cursor + Claude Code):** [`subagent-delegation.md`](subagent-delegation.md) — when to use subagents / parallel context without requiring explicit user phrasing; copy global snippet from [`../extension-templates/cursor-user-rule-subagent-delegation-snippet.md`](../extension-templates/cursor-user-rule-subagent-delegation-snippet.md) into Cursor User rules if desired.

## By theme

| Theme | Rules | Notes |
|-------|--------|--------|
| **Interaction & workflow** | `ask-first-protocol`, `rpi-workflow`, `subagent-delegation`, `prompt-templates`, `model-selection`, `token-optimization` | ASK + RPI + delegation defaults + efficient prompting. |
| **Quality & engineering** | `global-standards`, `quality-standards`, `coverage-rule`, `prd-standards`, `nfr-targets`, `branch-strategy`, `mobile-code-review`, `qa-guardrails`, `repo-grounded-change` | What “good” looks like by artifact type; **coverage-rule** centralizes default coverage targets; **repo-grounded-change** ties design/implementation/tests to real paths, module KB, and regression-aware unit tests. |
| **Compliance & risk** | `compliance-standards`, `operational-reliability`, `pre-merge-test-enforcement`, `merge-and-source-of-truth` | Audit, reliability, merge policy. |
| **Gates & traceability** | `gate-enforcement`, `gate-metrics`, `traceability-pr-prd`, `cross-pipeline-triggers`, `state-reconciliation`, `cross-team-dependencies` | ADO/state alignment. |
| **Tooling & integration** | `ado-standards`, `ado-html-formatting`, `mcp-resilience`, `user-config` | Azure DevOps/MCP, HTML formatting for work items, and user configuration. |
| **Docs & repo hygiene** | `commit-conventions`, `user-manual-sync` | Commits and manual drift. |

## Merge vs keep separate

**Suggested approach (no merges required):** keep files separate for discoverability and blame history; resolve “overlap” by **this index** and short cross-references at the top of closely related rules (add one line pointing to the other) when confusion appears.
