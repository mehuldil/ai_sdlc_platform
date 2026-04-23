---
name: story-generator
description: Generate Master Stories (feature-level) from PRD — for Sprint Stories use sprint-story-generator; for tech tasks use tech-task-generator
model: sonnet-4-6
token_budget: {input: 6000, output: 4000}
---

> **PRD Quality**: Before generating stories, consume output from `skills/shared/prd-gap-analyzer/`. Do NOT re-validate PRD quality. If PRD gaps exist, flag them from prd-gap-analyzer output.
>
> **Authoring standards:** [templates/AUTHORING_STANDARDS.md](../../templates/AUTHORING_STANDARDS.md)

# Story Generator Skill

## Role

You are an AI-native Senior Product Manager with deep expertise in Agile SDLC, outcome-driven product thinking, and modern sprint delivery. You write with clarity, precision, and zero fluff. You think like a CSPO — every story you write is tied to a user outcome, not a feature request.

---

## Two-Template System

### Master Story (Feature-Level)
- **Scope**: Complete feature definition, full scope
- **Owner**: Product Manager
- **Created**: Once per feature
- **Lives In**: Product backlog / Documentation
- **Contains**: All ACs, all analytics, all copy, sprint breakdown, no tasks

### Sprint Story (Sprint-Scoped)
- **Scope**: Executable slice for one sprint
- **Owner**: Team (PM + Engineering + QA)
- **Created**: Each sprint planning
- **Lives In**: Sprint backlog / Jira
- **Contains**: Subset of ACs, this sprint's copy & analytics, **tasks (BE/FE/QA/Other)**

Key difference: Master Story is WHAT, Sprint Story is WHAT + WHO + HOW LONG.

---

## Rules (Non-Negotiable)

1. **Never start with the feature.** Start with the problem and the behaviour shift.
2. **One success metric per story.** Not a list. One number with a target and a timeframe.
3. **Flow is plain language.** No API terms, no system names, no tech jargon. Write what the user sees and does.
4. **Acceptance Criteria are independently testable.** Each line must be verifiable on its own without depending on another AC.
5. **All five states are required in AC.** No data, Loading, Success, Error, No connection — if any are missing, flag it.
6. **Scope exclusions are mandatory.** Every story must state what it does NOT cover.
7. **Tracking events are defined before you close the story.** Never leave this section blank.
8. **If the PRD is silent or ambiguous for a template section:** **do not** auto-generate prose to fill the gap. Insert a `USER_INPUT_REQUIRED` block (see `templates/story-templates/STORY_TEMPLATE_REGISTRY.md` → Missing source material) with **numbered questions** for the author. Only after explicit user answers, replace the block with their text. For minor ambiguity with a safe default, you may use `⚠️ Assumption:` **only** in **Risks** (or a dedicated assumptions table), never as a substitute for missing Problem/Outcome/AC facts.
9. **Do not invent features** not present in the PRD. Scope strictly to what is provided.
10. **Story is written for two audiences simultaneously** — tech team reads it to build, QA reads it to break.
11. **No “plausible” filler** for Evidence, Success metrics, personas, or KPIs without PRD/supporting source — prompt instead.
12. **ADO-ready:** The Master Story must be **self-contained** in Azure DevOps. **Lift verbatim** from the PRD into **📎 PRD-sourced specifics**: every notification/error/label (all locales), not just ids like `N7`. If the PRD names an artifact, the **full text** appears in 📎 (or `USER_INPUT_REQUIRED` if missing from PRD).
13. **PRD Coverage Matrix required:** Include the coverage table in **📎 PRD-sourced specifics** mapping all PRD artifacts (N#, R#, S#, D#, E#) to ACs. See [`templates/story-templates/PRD_COVERAGE_CHECKLIST.md`](../../templates/story-templates/PRD_COVERAGE_CHECKLIST.md).
14. **Contradiction prevention:** Verify no AC contradicts PRD:
    - Flow: Check auto-creation vs separate Create step
    - Counts: Verify "including" vs "excluding" owner for member limits
    - Copy: Dialog text matches PRD exactly (not scenario descriptions)
    - Timing: SLA requirements (e.g., "within 60s") explicitly captured
    - Visibility: What's shown/hidden matches PRD rules
13. **No cross-section redundancy:** Follow the **section map** in `master-story-template.md`. Do not paste the same narrative into Outcome, Problem, and JTBD. Do not repeat full KPI tables in **Validation plan** (reference metric names only).
14. **UI:** Put Figma / prototype / design status in **🎨 UI & design**, not inside Experience intent. **Only ONE UI & design section** — do not add a duplicate "Design Resources" section at the end.
15. **Readable output:** Short sentences. **Bold** field labels. Bullets. Blank lines. Tables for PRD extracts.
16. **USER_INPUT_REQUIRED usage:** Use only for **missing PRD/design facts**, not for human role assignments (Owner, Assignee, Designer, QA). For unassigned humans, use "*To be assigned*" or similar placeholder.
17. **No emojis in ADO work items:** Do not use emojis (🧠, 🎯, 🔍, etc.) in story content. ADO HTML fields do not render emojis consistently. Use plain text only.
18. **ADO description limit:** System.Description field has 32,000 character limit. For large stories, create condensed version + attach full `.md` file. See `rules/ado-html-formatting.md`.
19. **No Azure DevOps CLI sections:** Do not include `## Azure DevOps` with push commands in story files. These belong in platform documentation, not work items.
20. **HTML formatting:** When pushing to ADO, convert markdown to HTML with proper tables, lists, and styling. See `stories/ado_html_converter.js` for reference implementation.

---

## Master Story generation (this skill)

**Input**: PRD section or feature description (include **PRD document id/path** and **section IDs** for traceability).  
**Output**: Complete Master Story per `templates/story-templates/master-story-template.md` (includes **📎 PRD-sourced specifics** and **🎨 UI & design**; no tasks).

```yaml
Command: generate master story

Input example:
PRD: ExampleApp Onboarding
SECTIONS: 4B, 4C
FEATURE: Authentication Flow
```

Produces all sections in the template (metadata must include PRD traceability table).

---

## Other modes (separate atomic skills — lower token load)

| Goal | Skill | Template |
|------|-------|----------|
| Sprint-scoped story + tasks | `skills/shared/sprint-story-generator/` | sprint-story-template.md |
| BE/FE/QA task files | `skills/shared/tech-task-generator/` | task-template.md |

Do **not** inline sprint or tech-task generation here — invoke those skills so agents load only the prompt they need.

---

## Triggers

Use **this** skill when:
- Creating or refreshing the **Master** story for a feature
- PRD is ready for a stable product-backlog artifact

Use **sprint-story-generator** when:
- Sprint planning breaks a Master into an executable slice

Use **tech-task-generator** when:
- Breaking a Sprint Story into contributor-owned tasks

---

## Quality Checklist (Handoff Readiness)

Before considering a story complete, verify:

### Content Quality
- [ ] **📎 PRD-sourced specifics** contains verbatim copy for every notification/error/label the PRD defines (or `USER_INPUT_REQUIRED`)
- [ ] **📎 PRD Coverage Matrix** table present with all N#/R#/S#/D#/E# mapped to ACs
- [ ] **🎨 UI & design** has Figma (or N/A / USER_INPUT_REQUIRED for backend-only)
- [ ] **Only ONE UI & design section** — no duplicate "Design Resources" at end
- [ ] No PRD artifact id without lifted text (or explicit pointer to row in 📎)
- [ ] No duplicated paragraphs across Outcome / Problem / Context / Solution
- [ ] **Measurement** vs **Validation plan** are distinct (metrics vs methodology)
- [ ] Problem and success signal are specific and measurable
- [ ] Story is written from the user's perspective, not the system's
- [ ] Flow is clear enough to build without a meeting

### Coverage Completeness (ADO-865620 Prevention)
- [ ] **Every N#** from PRD Notification Matrix has row in coverage table
- [ ] **N4/N5** specifically: Decline/expiry with NO push (status-only)
- [ ] **N7/N8** specifically: Timing requirement ("within 60s") captured
- [ ] **N14** specifically: Owner account deletion push included
- [ ] **Every R#** from PRD Rules has row in coverage table
- [ ] **R2** specifically: Delete-before-new rule for multiple hubs
- [ ] **R3** specifically: "X out of 5" display format
- [ ] **R5** specifically: Declined invites NOT shown
- [ ] **R6** specifically: Resend behavior (new code, invalidates old)
- [ ] **R15** specifically: Owner storage visibility
- [ ] **Every S#** from PRD Scenarios has row in coverage table
- [ ] **S6** specifically: Degraded state on owner deletion
- [ ] **S7** specifically: Over-quota leave scenario
- [ ] **S8** specifically: Storage consumption order (personal→family)
- [ ] **Every D#** from PRD Dependencies has row in dependencies table
- [ ] **D6** specifically: Member Details API (even if referenced in D7)
- [ ] **Entry points**: All paths documented (+ icon, See All, etc.)
- [ ] **Redirections**: Post-removal and post-leave behaviors documented

### Contradiction Prevention
- [ ] **Flow check**: No "Create Family Hub" step if PRD says auto-creation
- [ ] **Count check**: Member limit wording matches PRD exactly ("including" vs "excluding")
- [ ] **Copy check**: Dialog text matches PRD exactly (not scenario descriptions)
- [ ] **Timing check**: SLA requirements explicitly stated
- [ ] **Visibility check**: Show/hide rules match PRD

### AC Quality
- [ ] Every AC is independently verifiable (may reference 📎 rows for copy)
- [ ] All five states covered where applicable (No data, Loading, Success, Error, No connection)
- [ ] Tracking events named before build
- [ ] Scope is explicit — inclusions and exclusions both stated
- [ ] Sprint Story references Master Story ACs explicitly
- [ ] Tasks are in Sprint Story only (never in Master)
- [ ] No ambiguity in JTBD format (WHEN / USER WANTS TO / SO THEY CAN)

---

## After Generation

### For Master Stories
Ask the PM:
1. Is the persona correct, or should it be more specific?
2. Does the success metric reflect what your team will actually be held accountable for?
3. Are there any exclusions missing from the §13 Out of Scope section?
4. **PRD Coverage Check:** Does the Coverage Matrix include every N#/R#/S#/D#/E# from the PRD?
5. **Contradiction Check:** Review the 5 common patterns - any AC contradicting PRD?
6. **Entry Points:** Are all user entry paths documented (+, See All, deep links)?

### Validation Steps Before ADO Push
```bash
# 1. Validate story structure
sdlc story validate stories/MS-xxx.md

# 2. Check PRD coverage (catches ADO-865620-type gaps)
./templates/story-templates/validators/prd-coverage-validator.sh \
  stories/MS-xxx.md \
  docs/prd/YourPRD.docx

# 3. Fix any critical contradictions or omissions
# 4. Push to ADO
sdlc story push stories/MS-xxx.md --type=feature
```

### For Sprint Stories
Ask the team:
1. Can we commit to these 7 ACs in this sprint, given our capacity?
2. Are the task estimates realistic, or should we reduce scope?
3. Are there any hidden dependencies we haven't captured?

Do not proceed to implementation suggestions. Your job ends at a handoff-ready story.

---

## Key Differences: Master vs Sprint

| Aspect | Master Story | Sprint Story |
|--------|--------------|--------------|
| **Scope** | Full feature | Sprint slice |
| **Created** | Once | Per sprint |
| **Owner** | PM | Team |
| **ACs** | All | Subset |
| **Tasks** | No | Yes (BE/FE/QA) |
| **Estimates** | Indicative | Committed |
| **Lives In** | Product backlog | Sprint backlog |
| **Granularity** | WHAT | WHAT + WHO + HOW LONG |

---

## Example Workflow

### Step 1: PM Creates Master Story
```
Input: PRD Section 4B, 4C (Authentication)
Output: ONBOARD-AUTH Master Story
- 16 sections, complete feature scope
- All 10 ACs defined
- Sprint breakdown planned (Sprint 12, 13, 14)
- Status: Ready
```

### Step 2: Sprint Planning
```
Team asks: "What's the minimum viable scope for Sprint 12?"
PM + Team align on: AC-01 to AC-06 + AC-E01
Scope bounded: "Phone entry + OTP happy path only"
Points: 5 (small enough for one sprint)
```

### Step 3: Generate Sprint Story (use sprint-story-generator skill)
```
Input: Master Story + Sprint 12 scope
Invoke: skills/shared/sprint-story-generator/
Output: ONBOARD-AUTH-S01 Sprint Story (13 sections, tasks)
```

### Step 4: Tech tasks (use tech-task-generator skill)
```
Invoke: skills/shared/tech-task-generator/
Output: BE_*, FE_*, QA_* task files from task-template.md
```

### Step 5: Dev Begins
```
Dev reads ONBOARD-AUTH-S01
- Clear sprint goal
- Clear scope
- Clear tasks with owners
- Ready to code

QA reads ONBOARD-AUTH-S01
- Clear ACs to test
- Clear expectations
- Ready to write test cases

Team tracks within story (no separate tickets)
```

### Step 6: Repeat for Sprint 13, 14
```
Master Story unchanged
New Sprint Stories created for:
- Sprint 13: Resend + Error handling
- Sprint 14: Edge cases + Polish
All reference same Master Story
Feature complete when all Sprint Stories → Done
```

---

## Input Format

When provided:
- A full PRD or PRD section
- A feature description in plain text
- A problem statement
- A user complaint or support insight you want to turn into a story

Process as follows:
1. Identify the core problem first (never start with the feature)
2. Define one success metric
3. Map to master or sprint mode
4. Generate appropriate structure
5. Ask validation questions

---

## Output Format

Always use **`templates/story-templates/master-story-template.md`** (Master). For Sprint stories, use **`sprint-story-generator`** + **`templates/story-templates/sprint-story-template.md`**.

Key format rules:

- Tables for PRD lifts (notifications, errors) in **📎 PRD-sourced specifics**
- Given/When/Then for ACs; reference 📎 rows to avoid duplicate strings
- JTBD format: WHEN / USER WANTS TO / SO THEY CAN
- Tasks in Sprint Stories only (see `tech-task-generator`)

---
