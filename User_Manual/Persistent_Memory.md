# Persistent Memory

## In plain words: memory vs knowledge base

People often mix these up. In AI-SDLC they are **two different things**:

| | **Semantic memory** (“persistence”) | **Module / knowledge base** (“KB”) |
|---|-------------------------------------|-------------------------------------|
| **Stores** | Decisions, rationales, QA notes, long-lived facts you **write** or tools **upsert**. | Facts **extracted from your repository**: APIs, contracts, dependencies, layout. |
| **Lives in** | `.sdlc/memory/` — **SQLite** on your machine (ignored by git) + **JSONL** file for the **team** (committed). | `.sdlc/module/` — YAML/JSON and contracts generated from code (committed). |
| **Good question** | “What did we decide about OAuth timeouts?” | “What endpoints does this service expose?” |
| **Main commands** | `sdlc memory semantic-query`, `semantic-upsert`, `semantic-status` | `sdlc module init`, `sdlc module load`, `sdlc module validate` |
| **Synced how** | Git hooks **export** your local writes to JSONL on commit and **import** teammates’ JSONL after pull/merge. | Hooks run **`sdlc module update`** so the KB stays close to the code you committed. |

Use **[Features — how they work](FEATURES_REFERENCE.md)** for mechanics and **[Commands](Commands.md)** for auto-sync details.

---

## Unified Semantic Long-Term Memory

AI-SDLC now includes a shared semantic memory index at:

- `.sdlc/memory/semantic-memory.sqlite3`

It is intended for all orchestrators (QA first, then frontend/perf/reporting) and provides:

1. **Retrieval ranking**
   - Token + character-trigram vectorization
   - Cosine similarity ranking
   - Small freshness weighting for recency-aware results

2. **Conflict resolution**
   - `reject` (default)
   - `last_write_wins`
   - `merge_append`

3. **Lifecycle governance**
   - Entry states: `active`, `superseded`, `archived`
   - Version retention policy per key
   - Archival and hard-delete windows
   - Full audit events in `memory_audit`

## CLI

```bash
sdlc memory semantic-status
sdlc memory semantic-upsert --orchestrator=qa --namespace=requirements --key=US-123 --content-file=notes.md
sdlc memory semantic-query --text="oauth timeout edge case" --orchestrator=qa --limit=5
sdlc memory semantic-lifecycle
```

## Orchestrator Integration

- **QA orchestrator** mirrors KB/context writes into semantic memory through `orchestrator/qa/context_store.py`.
- Other orchestrators should call `orchestrator/shared/semantic_memory.py` directly for write/query/lifecycle.

## Team sync (git) — one source of truth

| Artifact | Role |
|----------|------|
| **SQLite** (`.sdlc/memory/semantic-memory.sqlite3`) | Local machine only; gitignored |
| **JSONL** (`.sdlc/memory/semantic-memory-team.jsonl`) | Team bus — **committed**; hooks export/import around commit/pull |
| **Module KB** (`.sdlc/module/**`) | Code-derived; **committed** after `module update` |

**Details (hooks, env toggles, pipeline files):** see [Commands](Commands.md) — sections *Auto-sync* and *CI* — do not duplicate here.

## Namespacing at scale (many engineers)

To limit merge contention and conflicting keys in **team JSONL** / semantic memory:

- Prefer **`--namespace=`** (and/or feature/sprint prefixes in **keys**) so unrelated work does not share one flat key space.
- Choose **conflict policy** per namespace: e.g. `reject` for canonical facts, `merge_append` for narrative notes (see `semantic-upsert` / lifecycle docs).
- Treat **SQLite** as a **local index**; **git-tracked JSONL + module KB** remain the shared bus for reconciliation.

See also [Traceability_and_Governance](Traceability_and_Governance.md) §6.

## Governance Recommendations

- Run `sdlc memory semantic-lifecycle` in CI nightly (or on a schedule).
- Keep `retain_versions` conservative (default 5) to avoid unbounded growth.
- Rely on **JSONL + module KB in git** for portability; SQLite is regenerated locally after pull.

---

## Platform Team Memory: Cross-Team Sync

### Architecture Overview

The AI-SDLC Platform uses a **dual-layer memory system** for cross-team collaboration:

```
┌─────────────────────────────────────────────────────────────────┐
│                    PLATFORM REPO (Shared)                        │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────────────┐  │
│  │ memory/team/ │    │ memory/     │    │ .sdlc/memory/       │  │
│  │  backend/    │◄──►│  shared/    │◄──►│ semantic-memory-    │  │
│  │  frontend/   │    │             │    │ team.jsonl          │  │
│  │  qa/         │    │ cross-team  │    │ (Git-tracked)       │  │
│  │  product/    │    │ -log.md     │    └─────────────────────┘  │
│  │  ...         │    │             │                             │
│  └─────────────┘    └─────────────┘                             │
└─────────────────────────────────────────────────────────────────┘
         ▲                           ▲
         │                           │
    git pull/push              git hooks export/import
         │                           │
┌────────┴──────────────────────────┴──────────────────────────┐
│                         LOCAL MACHINE                         │
│  ┌─────────────────────┐    ┌──────────────────────────────┐  │
│  │ Local Stories       │    │ .sdlc/memory/                │  │
│  │ (Not in git)        │    │ semantic-memory.sqlite3      │  │
│  │ c:\...\stories\     │    │ (Gitignored, rebuilt)        │  │
│  └─────────────────────┘    └──────────────────────────────┘  │
└───────────────────────────────────────────────────────────────┘
```

### How Teams Sync Memory

| Action | What Happens | Direction |
|--------|--------------|-----------|
| `git commit` | Local SQLite → `semantic-memory-team.jsonl` | Export |
| `git push` | JSONL uploaded to Azure DevOps origin | Upload |
| `git pull` | Remote JSONL merged → Local SQLite | Import |
| `git merge` | Same as pull — import teammates' entries | Import |

### Organization-Specific Content Pattern

**Problem**: Platform repo is shared across all teams, but organization-specific stories should not be in the platform repo.

**Solution**: Keep stories local, store ADO reference pointers in platform memory.

```
Local (not in git):
  c:\JioCloudCursor\AISDLC\stories\
  ├── FH-001-master-family-hub-phase1.md
  ├── FH-001-S01-sprint-hub-creation-invite.md
  └── FH-001-S02-sprint-member-management.md

Platform repo (git-tracked):
  AI_SDLC_Platform/memory/team/product/
  └── FH-001-family-hub-ado-reference.md  ← ADO links only
```

**Example Reference File**:

```markdown
# Family Hub (FH-001) - ADO Work Item Reference

| Work Item | Type | Title | State |
|-----------|------|-------|-------|
| [865620](https://dev.azure.com/...) | Feature | Family Hub Phase 1 | Proposed |
| [865621](https://dev.azure.com/...) | User Story | Sprint 3: Hub Creation | New |
| [865622](https://dev.azure.com/...) | User Story | Sprint 4: Member Management | New |
```

**Benefits**:
- Platform repo stays clean (no org-specific content)
- ADO work items are discoverable via platform memory
- Cross-team impact logged in shared memory
- Stories remain local for organization privacy

### For New Teams Joining the Platform

1. **Clone the platform repo**:
   ```bash
   git clone https://dev.azure.com/JPL-Limited/JioAIphotos/_git/AI-sdlc-platform
   ```

2. **Initialize memory**:
   ```bash
   cd ai-sdlc-platform
   sdlc memory init
   ```

3. **Create team folder** (if doesn't exist):
   ```bash
   mkdir -p memory/team/{your-team-name}
   ```

4. **Add ADO references** for your work items in `memory/team/product/`

5. **Commit and push**:
   ```bash
   git add memory/
   git commit -m "Add team memory and ADO references"
   git push origin main
   ```

### Cross-Team Discovery

Any team can discover another team's ADO work items:

```bash
# Search all team memory for ADO links
grep -r "dev.azure.com" memory/team/

# Or query via semantic memory
sdlc memory semantic-query --text="Family Hub ADO work item"
```

