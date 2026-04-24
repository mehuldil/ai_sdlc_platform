# FAQ & Troubleshooting

Quick jump:

- [Setup issues](#setup-issues)
- [Cursor & non-interactive setup](#cursor--non-interactive-setup)
- [Role & context](#role--context)
- [Stage execution](#stage-execution)
- [Azure DevOps](#azure-devops)
- [Memory & token budget](#memory--token-budget)
- [Module KB](#module-kb-sdlc-module-init)
- [Diagnostics](#diagnostics)
- [Extending the platform](#extending-the-platform)
- [User Manual (HTML reader)](#user-manual-html-reader)
- [Stories, tasks & templates](#stories-tasks--templates)
- [Workflows & modes](#workflows--modes)
- [IDE (Cursor / Claude Code)](#ide-cursor--claude-code)
- [Windows & Git Bash](#windows--git-bash)
- [Semantic memory & module system](#semantic-memory--module-system)
- [Azure DevOps & MCP](#azure-devops-mcp)
- [Tokens & cost](#tokens--cost)
- [PR, merge & traceability](#pr-merge--traceability)
- [Documentation & drift](#documentation--drift)
- [QA orchestrator](#qa-orchestrator)
- [System integrity & validation](#system-integrity--validation)

**New for V2+:**
- [**Layman's Guide by Role**](#laymans-guide-by-role) — Answers for your specific job
- [**Layman's Guide by Stage**](#laymans-guide-by-stage) — What each stage means in plain English

---

## Setup Issues

**Q: Setup fails with "Node.js not found"**
Install Node.js 18+: `nvm install 18 && nvm use 18`

**Q: MCP servers not connecting after setup**
1. Check **`~/.sdlc/ado.env`** or this repo's **`env/.env`** for valid `ADO_*` values (and restart the IDE)
2. Run `sdlc doctor` to diagnose

**Q: Symlinks broken after moving project**
Re-run: `./setup.sh /path/to/project`

**Q: Nested folders under `.claude/skills` or `.claude/agents` (e.g. `skills/skills/`)**
Re-run setup, or from the platform repo run `bash scripts/repair-claude-mirrors.sh`. Canonical content always lives under top-level `agents/`, `skills/`, and `templates/`.

**Q: "Permission denied" on setup.sh**
`chmod +x setup.sh cli/sdlc.sh cli/sdlc-setup.sh`

**Q: I have many microservice repos — do I run setup in each one?**
Yes. Each app repo needs its own `.sdlc/` and hooks. Use **`./scripts/setup-repos-from-manifest.sh`** with a manifest file (one path per line), or a shell loop — see **[Getting_Started — Many microservice repositories](Getting_Started.md#many-microservice-repositories)**. For CI, loop over repos and use **`sdlc setup --from-env`** where non-interactive. A **monorepo** needs only one setup at the root.

---

## Cursor & non-interactive setup

**Q: Setup ran in Cursor but never asked my role / ADO — is that normal?**  
Yes when there is **no TTY**. The script cannot open terminal prompts. Your assistant should use **AskQuestion** in chat, then run setup again with **`SDL_SETUP_ROLE`**, **`SDL_SETUP_STACK`**, **`SDL_SETUP_ADO`**, and **`ADO_*`** variables set. See **`cli/sdlc-setup.sh --help`** and [INDEX](INDEX.md).

**Q: I want to skip all questions in CI**  
Set **`SDL_SETUP_SKIP_QUESTIONS=1`** before running `sdlc-setup.sh` (see `--help`).

**Q: Where is the full list of features explained in simple language?**  
[FEATURES_REFERENCE](FEATURES_REFERENCE.md) (**what each area is** and **how it runs**) and the **[Index](INDEX.md)** numbered sidebar order.

---

## Layman's Guide by Role

### **I'm a Backend Developer — What's This For Me?**

**Q: In plain English, what does this platform do for me?**
Think of it as a **smart assistant that knows your codebase**. Instead of explaining your microservice architecture every time, it remembers your APIs, database schemas, and coding patterns. It helps you write code faster while following your team's standards.

**Q: What's my typical day using this?**
```
Morning:
1. Open your feature branch
2. Run: sdlc use backend --stack=java
3. Work on your story (AB#12345)

During development:
- Ask AI: "Implement the payment endpoint using our existing patterns"
- AI loads your module KB (APIs, schemas) automatically
- Writes code following your team's conventions
- You review and approve

End of day:
- Commit with: git commit -m "feat: payment API AB#12345"
- Push and create PR
```

**Q: What are the 3 stages I use most?**
| Stage | When You Use It | What It Does |
|-------|-----------------|--------------|
| **08-implementation** | Writing code | AI helps write service/controller code with your patterns |
| **09-code-review** | Before PR | AI reviews your code for security, bugs, style issues |
| **11-test-execution** | After coding | Helps write and run unit tests |

**Q: What if AI suggests wrong code?**
You always approve changes. The AI **proposes**, you **decide**. Think of it as a junior developer suggesting code — you review and say yes/no.

---

### **I'm a Frontend Developer — What's This For Me?**

**Q: In simple terms, how does this help me?**
It's like having a **senior frontend engineer** who knows your design system, component library, and API contracts. It helps you build screens faster while keeping UI consistent.

**Q: What's my daily workflow?**
```
1. Get design from Figma
2. Run: sdlc use frontend --stack=react-native
3. Create feature branch
4. Ask AI: "Build the payment screen from this Figma link"
5. AI suggests components using your design system
6. You refine and approve
7. Test on simulator
8. Commit and push
```

**Q: Key stages for frontend work?**
| Stage | When | What Happens |
|-------|------|--------------|
| **05-system-design** | Before coding | Plan screen structure, API calls, state management |
| **08-implementation** | Coding | Build components, wire up APIs |
| **09-code-review** | Before PR | Check accessibility, responsive design, code quality |

**Q: Does it know my component library?**
Yes — run `sdlc module init` once, and it learns your components. Then it suggests using `<Button>`, `<Card>`, etc. from your library, not generic code.

---

### **I'm a QA Engineer — How Does This Help?**

**Q: What does this platform do for QA?**
It's a **test planning assistant**. It reads your requirements and suggests test cases — happy paths, edge cases, error scenarios. It tracks what's tested and what isn't.

**Q: My typical workflow?**
```
1. Get user story from Product
2. Run: sdlc use qa
3. Execute stage 10: sdlc run 10-test-design
4. AI suggests test scenarios
5. You review and add more
6. AI helps write test code (JUnit, XCTest, etc.)
7. Run tests: sdlc run 11-test-execution
8. Report defects in ADO
```

**Q: Key QA stages?**
| Stage | Purpose | What You Get |
|-------|---------|--------------|
| **10-test-design** | Plan testing | Test scenarios, data requirements, coverage plan |
| **11-test-execution** | Run tests | Execute and report results |
| **09-code-review** | Review dev code | Spot issues before they reach QA |

**Q: Does it replace my testing expertise?**
No — it **accelerates** your work. You still decide what's important to test. The AI is a tool, not a replacement.

---

### **I'm a Product Manager — What's In It For Me?**

**Q: Simple explanation of what this does?**
It's a **PRD-to-execution pipeline**. You write requirements in markdown, and the platform helps turn them into stories, tasks, and tracked work items in ADO.

**Q: My workflow?**
```
1. Write PRD in markdown
2. Run: sdlc use product
3. Execute: sdlc run 01-requirement-intake
4. AI helps review PRD for gaps
5. Create stories: sdlc story create master --output=./stories/
6. Edit story files
7. Push to ADO: sdlc story push ./stories/MS-*.md
8. Track in Azure Boards
```

**Q: Key PM stages?**
| Stage | What It Does | Your Output |
|-------|--------------|-------------|
| **01-requirement-intake** | Load PRD into process | PRD captured, linked to feature branch |
| **02-prd-review** | Check for gaps, risks | Review notes, updated PRD |
| **04-grooming** | Sprint planning | Groomed backlog, sized stories |
| **07-task-breakdown** | Split stories to tasks | Task assignments in ADO |

**Q: Do I need technical knowledge?**
No — the platform guides you through each step. You write in plain English, it handles the technical details.

---

### **I'm a Tech Lead — How Do I Manage My Team?**

**Q: What's my role in this platform?**
You're the **gatekeeper and coordinator**. You set up the platform for your team, monitor quality, and approve designs.

**Q: My responsibilities?**
```
1. Run initial setup for team repos
2. Configure token budgets per developer
3. Set team conventions in .sdlc/config
4. Review system designs (Stage 05 → 06)
5. Monitor team velocity via sdlc reports
6. Approve test bypasses when needed
7. Ensure ADO integration works
```

**Q: Key stages I focus on?**
| Stage | Why It Matters | Your Action |
|-------|----------------|-------------|
| **05-system-design** | Architecture decisions | Review and approve design docs |
| **06-design-review** | Quality gate | Sign off before implementation |
| **14-release-signoff** | Release approval | Final check before production |

**Q: How do I monitor team usage?**
```bash
sdlc budget report --team    # Token spend by person
sdlc doctor --team           # Health check all repos
sdlc ado list --sprint=45    # What's in flight
```

---

## Layman's Guide by Stage

### **What Are These 15 Stages (In Plain English)?**

Think of stages as **checkpoints in a road trip** from "idea" to "released software." Each stage has an **input** (what you need), **process** (what happens), and **output** (what you get).

| Stage # | Stage Name | Simple Meaning | What You Bring | What You Get |
|---------|------------|----------------|----------------|--------------|
| **01** | Requirement Intake | "Let's start a new feature" | PRD, idea, or Jira ticket | Feature branch, captured requirements |
| **02** | PRD Review | "Is this PRD ready to build?" | Draft PRD | Reviewed PRD with gaps identified |
| **03** | Pre-Grooming | "Prep for sprint planning" | PRD + design mockups | Grooming agenda, sized stories |
| **04** | Grooming | "Plan the sprint" | Team availability | Committed sprint backlog |
| **05** | System Design | "How do we build this?" | Requirements | Technical design document |
| **06** | Design Review | "Is the design good?" | Design doc | Approved or revised design |
| **07** | Task Breakdown | "Who does what?" | Sprint stories | Assigned tasks in ADO |
| **08** | Implementation | "Write the code" | Design + tasks | Working code in branch |
| **09** | Code Review | "Is the code good?" | Code changes | Reviewed, approved code |
| **10** | Test Design | "How do we test this?" | Requirements + code | Test plan, scenarios |
| **11** | Test Execution | "Run the tests" | Test plan | Test results, defects |
| **12** | Commit & Push | "Save and share" | Tested code | Code in remote repo |
| **13** | Documentation | "Write the docs" | Completed feature | Updated README, runbooks |
| **14** | Release Signoff | "Ready to ship?" | Tested, documented code | Release approval |
| **15** | Summary Close | "We're done!" | Released feature | Retrospective, lessons learned |

### **Which Stages Do I Actually Use?**

**For a small bug fix:**
```
01 → 08 → 09 → 11 → 12 → 15
(Intake → Code → Review → Test → Push → Close)
```

**For a new feature:**
```
01 → 02 → 03 → 04 → 05 → 06 → 07 → 08 → 09 → 10 → 11 → 12 → 13 → 14 → 15
(Full process)
```

**For a spike/research:**
```
01 → 05 → 15
(Intake → Explore → Close)
```

### **Stage-Specific Questions**

**Q: Stage 05 (System Design) — What if I already know the design?**
Run it anyway quickly — it captures your decisions for the team. Takes 5 minutes, saves hours of "why did we do this?" later.

**Q: Stage 08 (Implementation) — Can I write code myself without AI?**
Absolutely! The stage helps when you want it. Skip it or use it partially.

**Q: Stage 09 (Code Review) — Does this replace peer review?**
No — it's a **first pass**. You still want human review, but AI catches obvious issues first.

**Q: Stage 11 (Test Execution) — Does it run my actual tests?**
The stage **prepares** test execution. You still run `mvn test`, `npm test`, etc. yourself (or in CI).

---

## Role & Context

**Q: How do I switch roles?**
`sdlc use <role>` — switch anytime. Verify: `sdlc context`

**Q: Can I run stages outside my role?**
Yes. Roles are advisory. Any role can run any stage. Gates inform, don't block.

**Q: Role not recognized?**
Check supported roles: product, backend, frontend, qa, ui, tpm, performance, boss

---

## Stage Execution

**Q: Stage fails with "context missing"**
Set role first: `sdlc use backend --stack=java`

**Q: Command failed with "ASK in chat" or I don't know what to run next**
See **[Guided_Execution_and_Recovery](Guided_Execution_and_Recovery.md)** — use the printed `sdlc` lines, run `sdlc context`, then `sdlc doctor`. In IDE chat, ask the assistant to read the error and give the **exact** next commands (non-interactive terminals cannot prompt).

**Q: How do I skip a gate?**
Gates are informational. When prompted, choose "Skip" or "Proceed anyway."

**Q: How do I re-run a stage?**
Just run it again: `sdlc run <stage>`. Previous outputs are preserved in memory.

---

## Azure DevOps

**Q: Can I use one Azure DevOps PAT for every service repo?**  
Yes. Create **`~/.sdlc/ado.env`** (see **`env/ado.env.template`** in the platform checkout). The CLI merges it before each repo's **`env/.env`**, so you do not need to copy secrets into every repository. Optional: set **`SDL_AZURE_DEVOPS_ENV_FILE`** to another path.

**Q: ADO commands return "authentication failed"**
1. Check `ADO_PAT` in `~/.sdlc/ado.env` or this repo's `env/.env`
2. Verify PAT hasn't expired
3. Verify scopes include "Work Items (Read & Write)"

**Q: Work items not syncing**
Run `sdlc ado sync` manually. Check `sdlc doctor` for connection status.

**Q: How do I create stories and get an ADO work item id?**
1. `sdlc story create master|sprint|tech|task --output=./stories/` (or use the IDE / story-generator skill from a PRD).
2. Fill the markdown files.
3. `sdlc story push ./stories/MS-....md --type=feature` for an ADO **Feature** (master story), or `sdlc story push ./stories/SS-....md` for a **User Story** (default). Same as `sdlc ado push-story`; prints the numeric id on success.

**Q: How do I search ADO work items without MCP? (v2.1.3+)**
Use CLI search commands (no MCP required):
```bash
# Text search
sdlc ado search "Family Hub"

# Filter by state
sdlc ado search state=Active

# Filter by type
sdlc ado search type=Feature

# My work items
sdlc ado search assignedTo=me

# Combined filters
sdlc ado search "Family Hub" state=Proposed type=Feature --top 5
```

**Q: What's the difference between `sdlc ado show` and `sdlc ado get`?**
- `show` — Full work item details (JSON-like output, all fields)
- `get` — Formatted summary (box-style, quick reference, truncated description)

Use `get` for quick lookups, `show` for detailed analysis.

**Q: Can I search ADO when offline?**
No — both CLI and MCP require network connectivity to Azure DevOps. However, CLI search uses fewer tokens (~200 vs ~800) and has no MCP dependency, making it more reliable in restricted environments.

**Q: Setup said hooks could not be verified**
Setup no longer aborts for this. Run `sdlc doctor` or re-run `./setup.sh`. Hooks are retried automatically during setup.

**Q: How do I get an ADO PAT?**
`https://dev.azure.com/{ORG}/_usersSettings/tokens` → New Token → Scopes: Work Items

---

## Memory & Token Budget

**Q: Token budget exceeded**
Options: wait until tomorrow (daily reset), split work across days, request TPM exception.

**Q: Memory not syncing across teams**
Check: git hooks executable (`ls -la .git/hooks/`), memory initialized (`sdlc memory status`)

**Q: How to check token usage?**
`sdlc tokens` or `/project:tokens` in IDE

---

## Module KB (`sdlc module init`)

**Q: Stack in `meta.json` / contracts is `unknown`, or `api.yaml` has no endpoints**

1. **Monorepo layout** — If **`build.gradle`**, **`build.gradle.kts`**, or **`pom.xml`** is only under a subfolder (not the repo root), use a platform version whose **`scripts/module-init.sh`** includes **nested** Gradle/Maven detection (scan depth ≤8). Then re-run **`sdlc module init .`** from the **git root** of the app repo.
2. **Java frameworks** — **`api.yaml`** is populated from **Spring** (`@GetMapping`, `@RequestMapping`, …) and from **`@Path("…")`** (RestExpress, JAX-RS-style). If you use another style, edit **`contracts/api.yaml`** manually or extend the scanner in **`scripts/module-init.sh`**.
3. **Path segments** — Listed **`path`** values are **per `@Path` annotation**. For nested routes (class-level base + method-level path), **compose** them when documenting full URLs.

---

## Diagnostics

**Q: Something isn't working — where to start?**
```bash
sdlc doctor               # Full diagnostic
bash scripts/verify.sh    # Cross-reference check
bash cli/tests/smoke.sh   # CLI smoke tests
```

**Q: How do I validate the entire system after changes?**
```bash
bash -n cli/sdlc.sh          # Syntax check
bash cli/tests/smoke.sh      # Smoke tests
bash scripts/doctor.sh .     # Diagnostics
bash scripts/verify.sh .     # Cross-references
./setup.sh --self            # Full end-to-end
```

**Q: Tests failing but I need to merge (hotfix)?**
Test bypass requires TPM/Boss approval:
```bash
sdlc approve-test-skip --approver=<name> --role=tpm --reason="<reason>"
```
Self-service bypass is NOT allowed. Logged to `.sdlc/logs/test-bypass.log`.

**Q: Commit rejected with "invalid format"?**
Use conventional commits: `feat(auth): implement OAuth AB#12345`
Types: feat, fix, refactor, test, docs, chore, perf, ci. Use `[no-ref]` for infra-only commits.

**Q: Branch name rejected?**
Use: `feature/AB#<id>-desc`, `bugfix/AB#<id>-desc`, `hotfix/AB#<id>-desc`, `release/<version>`

---

## Extending the Platform

**Q: How do I add a new role/agent/skill/stage?**
Copy template from `extension-templates/`, follow pattern in [Architecture](Architecture.md).

**Q: Where are old docs?**
94 files available in git history. Use `git log --all --diff-filter=D -- "*.md"` to find them.

**Q: Where is the role-specific guide for my role?**
In git history under `guides/` (product, backend, frontend, qa, ui, tpm, performance, boss).

---

## User Manual (HTML reader)

**Q: How do I read the manual offline with search?**
Open `User_Manual/manual.html` in a browser (double-click or drag into Chrome/Edge). Use the sidebar links and the search box. Regenerate after doc edits: `node User_Manual/build-manual-html.mjs`.

**Q: How does search work (multiple words)?**  
The reader matches **every** word you type (order-free). Example: `memory semantic` shows only pages that contain both "memory" and "semantic". It still searches **manual text only**, not your repo.

**Q: Where is the table of contents for the whole manual?**  
Start at **[INDEX](INDEX.md)** inside the manual (or in the repo). **Home** ([README](README.md)) lists all pages in one table.

**Q: Do I need a web server for manual.html?**
No. It is a single file with embedded content; open as `file://` or host it statically if you prefer.

**Q: Can manual.html search my local memory, KB, or Azure DevOps?**
No. That page only searches the **embedded User_Manual text**. Browsers do not allow a static local HTML file to read `.sdlc/`, SQLite, git state, or call ADO APIs (security / sandbox). Use the CLI from a real checkout instead, for example `sdlc memory semantic-query --text="…"`, `sdlc memory status`, `sdlc ado list`, `sdlc ado show <id>`. A small local server + backend could be added later to proxy those calls; the manual sidebar explains the limitation.

---

## Stories, tasks & templates

**Q: What are the four story tiers?**
Master → Sprint → Tech → Task. Create files with `sdlc story create master|sprint|tech|task --output=./stories/`. See [SDLC_Flows](SDLC_Flows.md) and templates under `templates/story-templates/`.

**Q: How do I validate a story file before push?**
`sdlc story validate <file.md>`

**Q: Can I attach a PRD section to a story?**
Yes — use the traceability fields in the story templates (PRD section / refs). See templates and [Persistent_Memory](Persistent_Memory.md) for how context is retained.

---

## Workflows & modes

**Q: What workflows exist besides full SDLC?**
`sdlc flow list` — includes quick-fix, perf-cycle, plan-design-implement, boss-report, etc. See [SDLC_Flows](SDLC_Flows.md).

**Q: What is plan-design-implement?**
An explicit serialization mode: plan → design → implement. Run via `sdlc flow plan-design-implement` (see Commands and workflows).

**Q: What is RPI (research / plan / implement / verify)?**
A gated workflow for complex work: `sdlc rpi research|plan|implement|verify|status <story-id>`. See [Commands](Commands.md).

---

## IDE (Cursor / Claude Code)

**Q: Slash commands do nothing**
Confirm setup completed, `.claude/commands` is linked, and the IDE reloaded. Compare with [CANONICAL_REPO_AND_INTERFACES](CANONICAL_REPO_AND_INTERFACES.md).

**Q: How do I run a stage from the IDE?**
Use `/project:<stage-name>` (e.g. `/project:implementation`) or ask in chat to run the matching stage — see [Commands](Commands.md) for the full list.

---

## Windows & Git Bash

**Q: `bash` is not recognized in PowerShell**
Use **Git Bash** from [Git for Windows](https://git-scm.com/download/win), or run: `"C:\Program Files\Git\bin\bash.exe" -lc "./setup.sh"`.

**Q: Python not found for semantic memory**
Install Python 3, or on Windows use `py -3` if the launcher is installed. See [Prerequisites](Prerequisites.md). Without Python, `sdlc memory semantic-*` commands are unavailable; other CLI features still work.

**Q: Why is `sdlc doctor` slow on my PC?**
Doctor runs multiple validators (`validate-rules`, `validate-commands`, doc drift, registries, hooks, etc.). On network drives or OneDrive, **`find`** and repeated file reads are slower. The **Rule Files Validation** line is only a quick rule count; most time in `validate-rules` is scanning **all** `agents/**/*.md` and `skills/**/*.md` with greps. Use `sdlc doctor --verbose` to see which step runs long; cloning the repo outside synced folders helps.

**Q: CI failed on "registry drift" or `regenerate-registries.sh --check`**
Someone changed `agents/`, `skills/`, or commands without refreshing the generated registries. From the repo root run: `bash scripts/regenerate-registries.sh --update`, then commit the updated `agents/CAPABILITY_MATRIX.md`, `skills/SKILL.md`, and `.claude/commands/COMMANDS_REGISTRY.md` as needed.

**Q: CI failed on `validate-stage-variants.sh`**
Usually stage **08-implementation** stack variants are missing YAML `stack:` or a link to `rpi-serialization-baseline.md` / `rules/rpi-workflow.md`. Fix the files under `stages/08-implementation/variants/` (see `stages/_includes/README.md`).

---

## Semantic memory & module system

**Q: Where is semantic memory stored?**
Local SQLite and metadata under `.sdlc/` / scripts as described in [Persistent_Memory](Persistent_Memory.md). Use `sdlc memory semantic-status`.

**Q: What is `sdlc module` (formerly kb/mis)?**
Unified module / contract context: `sdlc module load`, `validate`, `report`. See help: `sdlc module` (no args) and [Architecture](Architecture.md).

---

## Azure DevOps & MCP

**Q: Difference between CLI ADO and MCP in the IDE?**
CLI uses REST with `ADO_PAT` from the merged env chain (`~/.sdlc/ado.env`, platform `env/.env`, repo `env/.env`). MCP uses the same values via `env/mcp-start.sh` (and the standalone MCP server also reads `~/.sdlc/ado.env`). Both should point at the same org/project. See [ADO_MCP_Integration](ADO_MCP_Integration.md).

**Q: What does `sdlc ado sync` do?**
Pulls work item state from ADO and pushes local tags/notes (stage, role, completion snippets) — two-way. Requires valid credentials.

---

## Tokens & cost

**Q: What is `sdlc cost`?**
Shows per-stage token budgets (and optional spend from `.sdlc/state.json` if present). See [Commands](Commands.md).

**Q: How do token budgets relate to stages?**
Budgets are defined in `scripts/token-blocker.sh` (`STAGE_BUDGET`). `sdlc run` consults them when token blocking is enabled.

---

## PR, merge & traceability

**Q: Why do commits need `AB#` or `[no-ref]`?**
Traceability to Azure Boards work items; infrastructure-only commits may use `[no-ref]`. See [PR_Merge_Process](PR_Merge_Process.md) and hook `pre-merge-trace`.

**Q: How do I generate a traceability report?**
`bash scripts/trace-e2e-report.sh .` (from platform root). `sdlc doctor` can include this check.

---

## Documentation & drift

**Q: How do I know User_Manual is up to date with the CLI?**
Run `bash scripts/detect-doc-drift.sh .` and `sdlc doctor`. See [Documentation_Rules](Documentation_Rules.md) and [Prerequisites](Prerequisites.md).

**Q: Pre-commit blocked my commit for doc reasons**
Hooks enforce doc updates when certain platform paths change. Update the relevant `User_Manual` page or follow the hook message.

---

## QA orchestrator

**Q: What is `sdlc qa`?**
HTTP client for the QA orchestrator API (start/status/approve/kb/health). Default URL `http://localhost:8000` unless `QA_ORCHESTRATOR_URL` is set. See [Commands](Commands.md).

**Q: Do I need Docker for QA?**
Only if you run the orchestrator stack locally per `orchestrator/qa/docker-compose.yml`. Optional for general CLI use.

---

## System integrity & validation

**Q: What does `scripts/validate-system-integrity.sh` check?**
Agent/skill duplication signals, workflow vs stage alignment, symlink health, `STAGE_BUDGET` consistency — see script header. Run: `bash scripts/validate-system-integrity.sh .`

**Q: Where is smoke / CI gate tests?**
`bash cli/tests/smoke.sh` — basic CLI checks. See also `cli/tests/ci-gate.sh` if present in your branch.

> For deeper troubleshooting, ask: "Debug [specific issue]"
