# Index & reading guide

This page is the **map of the manual**. The **order below matches the sidebar** in `manual.html` (see `User_Manual/build-manual-html.mjs` → `ORDER`): read **top to bottom** for a linear path from “what is this?” to “how do I extend or troubleshoot?”

## How to use the offline manual (`manual.html`)

1. Open **`User_Manual/manual.html`** in Chrome or Edge (double-click the file, or drag it into the browser).
2. **Search** — type in the search box (top) or press **Ctrl+K** / **Cmd+K** for the spotlight search.  
   - Search looks at **every page** embedded in that file.  
   - You can type **several words**; only pages that contain **all** of those words (in any order) are shown.
3. **Jump** — use the **sidebar** top-to-bottom as the **recommended sequence**, or the dropdown / hash links.
4. **Links** that point to another `Something.md` page jump inside the same manual when you click them.

Search does **not** query your project, Azure DevOps, or local SQLite — only the manual text. For live data use **`sdlc`** in a terminal (see [FAQ](FAQ.md)).

---

## Manual order (same as sidebar — read down this list)

| # | Page | What you get |
|---|------|----------------|
| 1 | [Home](README.md) | Welcome, shortest links |
| 2 | **Index** (this page) | Map, glossary, goals |
| 3 | [System_Overview](System_Overview.md) | Product story + **where it runs** (§2a) + **manual map** (§2b) |
| 4 | [Prerequisites](Prerequisites.md) | Software, optional skips |
| 5 | [Getting_Started](Getting_Started.md) | `./setup.sh`, env, first commands |
| 6 | [CANONICAL_REPO_AND_INTERFACES](CANONICAL_REPO_AND_INTERFACES.md) | Clone layout, Cursor vs Claude vs CLI |
| 7 | [Happy_Path_End_to_End](Happy_Path_End_to_End.md) | One narrative: PRD → merge |
| 8 | [SDLC_Flows](SDLC_Flows.md) | **Per-stage I/O table**, gates, flows, story pipeline, execution **what/how/where** |
| 9 | [Role_and_Stage_Playbook](Role_and_Stage_Playbook.md) | Roles, handoffs, chains of work |
| 10 | [Features — how they work](FEATURES_REFERENCE.md) | **Deep dive**: what each area *is* and *how it runs* |
| 11 | [Commands](Commands.md) | Full CLI / slash / CI reference (incl. ADO search) |
| 12 | [Guided_Execution_and_Recovery](Guided_Execution_and_Recovery.md) | When things fail; ASK in chat |
| 13 | [Persistent_Memory](Persistent_Memory.md) | Memory vs module KB; SQLite, JSONL, hooks |
| 14 | [ADO_MCP_Integration](ADO_MCP_Integration.md) | PAT, MCP, sync, CLI search |
| 15 | [Agents_Skills_Rules](Agents_Skills_Rules.md) | Steering the model |
| 16 | [Architecture](Architecture.md) | Components, folders, extension points |
| 17 | [PR_Merge_Process](PR_Merge_Process.md) | PRs, AB#, policies |
| 18 | [Platform_Extension_Onboarding](Platform_Extension_Onboarding.md) | Adding agents, skills, stages |
| 19 | [Documentation_Rules](Documentation_Rules.md) | When to update docs; `manual.html` |
| 20 | [Migrating_From_V1_to_V2](Migrating_From_V1_to_V2.md) | Legacy V1 repo |
| 21 | [V2_Improvements_Over_V1](V2_Improvements_Over_V1.md) | Why V2 |
| 22 | [FAQ](FAQ.md) | Troubleshooting Q&A |
| 23 | [CHANGELOG](CHANGELOG.md) | Manual / tooling history |

---

## Start here (by goal — still jump in anywhere)

| I want to… | Open first | Then follow sidebar from that page |
|------------|--------------|--------------------------------------|
| **Linear learn** | Row **#3** in the table above | Continue **#4, #5, …** in order |
| **Install only** | [Prerequisites](Prerequisites.md) → [Getting_Started](Getting_Started.md) | [Happy_Path](Happy_Path_End_to_End.md) |
| **Understand mechanics** | [Features — how they work](FEATURES_REFERENCE.md) | [Commands](Commands.md) |
| **Fix an error** | [Guided_Execution_and_Recovery](Guided_Execution_and_Recovery.md) | [FAQ](FAQ.md) |
| **Memory vs KB** | [Persistent_Memory](Persistent_Memory.md) | [Features — how they work](FEATURES_REFERENCE.md) §5–6 |
| **Full-path dry run (CLI, no ADO)** | [Happy_Path_End_to_End](Happy_Path_End_to_End.md) — section *Full-path dry run* | [Commands](Commands.md) |
| **Extend platform** | [Platform_Extension_Onboarding](Platform_Extension_Onboarding.md) | [Documentation_Rules](Documentation_Rules.md) |

---

## Lookup: all pages by title (A–Z)

| File | Topic |
|------|--------|
| [ADO_MCP_Integration](ADO_MCP_Integration.md) | Azure DevOps + MCP |
| [Agents_Skills_Rules](Agents_Skills_Rules.md) | Agents, skills, rules |
| [Architecture](Architecture.md) | System structure |
| [CANONICAL_REPO_AND_INTERFACES](CANONICAL_REPO_AND_INTERFACES.md) | Repos & IDEs |
| [CHANGELOG](CHANGELOG.md) | Manual changelog |
| [Commands](Commands.md) | CLI & automation |
| [Documentation_Rules](Documentation_Rules.md) | Doc governance |
| [FAQ](FAQ.md) | Q&A |
| [FEATURES_REFERENCE](FEATURES_REFERENCE.md) | Features — how they work |
| [Getting_Started](Getting_Started.md) | Setup |
| [Guided_Execution_and_Recovery](Guided_Execution_and_Recovery.md) | Recovery |
| [Happy_Path_End_to_End](Happy_Path_End_to_End.md) | E2E path |
| [INDEX](INDEX.md) | This index |
| [Migrating_From_V1_to_V2](Migrating_From_V1_to_V2.md) | V1 migration |
| [Persistent_Memory](Persistent_Memory.md) | Semantic memory |
| [Platform_Extension_Onboarding](Platform_Extension_Onboarding.md) | Extensions |
| [PR_Merge_Process](PR_Merge_Process.md) | PRs & traceability |
| [Prerequisites](Prerequisites.md) | Requirements |
| [README](README.md) | Home |
| [Role_and_Stage_Playbook](Role_and_Stage_Playbook.md) | Roles & stages |
| [SDLC_Flows](SDLC_Flows.md) | Flows |
| [System_Overview](System_Overview.md) | Overview |
| [V2_Improvements_Over_V1](V2_Improvements_Over_V1.md) | V2 vs V1 |

---

## Glossary (short)

| Term | Plain meaning |
|------|----------------|
| **Stage** | A lifecycle step (01–15). Run with `sdlc run` and a stage id, or a `/project:…` slash command. |
| **Role** | Persona for the AI (`sdlc use`). Changes which rules and playbooks apply. |
| **Stack** | Tech lane (e.g. java). Refines implementation guidance. |
| **Workflow / flow** | Named bundle of stages (`sdlc flow list`). |
| **Module / KB** | Code-derived facts under `.sdlc/module/` (`sdlc module init`). |
| **Semantic memory** | Decision-derived facts; SQLite locally; team JSONL in git. |
| **MCP** | IDE tools exposed to the model (ADO, wiki, …). |
| **ASK** | CLI cannot prompt → confirm next step in chat with your assistant. |

---

## Cursor agent note (setup without a TTY)

When the assistant runs **`sdlc-setup.sh`** or **`./setup.sh`**, there is often **no keyboard** on stdin. Use **AskQuestion**, then pass **`SDL_SETUP_*`** and **`ADO_*`** as documented in **`cli/sdlc-setup.sh --help`** and [Getting_Started](Getting_Started.md).
