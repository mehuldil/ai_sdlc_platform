# ✅ Task — [Short Task Name]

> **Authoring:** [../AUTHORING_STANDARDS.md](../AUTHORING_STANDARDS.md) — ADO-ready facts live in **PRD** and **parent stories**; do not invent scope. If the **Sprint Story** or **Tech Story** does not support a section, use `USER_INPUT_REQUIRED` — see [STORY_TEMPLATE_REGISTRY.md](STORY_TEMPLATE_REGISTRY.md) (Missing source material).
>
> **Non-regression:** This task must **not** break existing behavior named in the Tech Story **🛡️ Non-regression** section or Sprint scope—cite tests/suites you will run or extend.

---

## 🎯 What's the Task?
**<Specific, actionable work>**

- **Do this:** [Specific action, e.g., "Implement handler for …"]
- **Why:** [Link to Sprint Story AC or Tech Story delta—**not** a duplicate of the full sprint goal]
- **Definition of Done:** [Exactly when is this task complete?] **Include:** repo anchors filled; unit tests **and** targeted regression (see below).

---

## 📍 Repo anchors (mirror design §0 / Tech Story)

Short list of **files, packages, or services** this task touches—same spirit as system design **§0** and **Tech Story** repo tables.

| Path or package | Role (read / extend / replace) |
|-----------------|--------------------------------|
| `…` | … |

---

## 📋 Acceptance Criteria
**<I'm done when...>**

Use **numbered** checklist items (`1. [ ]`, `2. [ ]`, …). **One criterion per block;** use a **blank line between** items.

1. [ ] [Specific testable outcome tied to parent AC or Tech Story]

2. [ ] [Tests: unit/integration as appropriate]

3. [ ] [Code review if required by team] *(optional)*

### Repo anchors & regression *(should-have for engineering tasks)*

1. [ ] **Unit / component tests** cover this change (stack-appropriate: JUnit, pytest, Jest, etc.).

2. [ ] **Regression:** Run or extend tests for **at-risk existing behavior** (name suite or command—e.g. `mvn test -pl …`, `pytest path/`, `npm test -- --testPathPattern=…`). If truly N/A, state **why** (one line).

---

## 🏗️ Implementation Notes
**<How to approach this technically>**

- **Approach:** [Patterns, constraints from Tech Story / design] *(optional)*
- **Files to modify:** [List] *(optional)*
- **Dependencies:** [Packages, APIs—**versions** if contract-sensitive] *(optional)*
- **Estimated time:** [2h–2d range typical] *(optional)*

---

## 🔗 Related Tasks
**<Connections to other work>**

- **Blocks:** […] *(optional)*
- **Blocked by:** […] *(optional)*
- **Related:** […] *(optional)*

---

## 📎 Parent Story PRD Coverage *(required)*

**Purpose:** Trace this Task to specific PRD artifacts (N#/R#/S#/D#/E#) from parent Master/Sprint stories. Tasks must NOT introduce new PRD artifacts.

### PRD Traceability

| Parent Story | AC Reference | PRD Artifacts Implemented | Verification |
|--------------|--------------|---------------------------|--------------|
| **Master Story** | AC #X | N#, R#, S#, D#, E# covered | ⬜ |
| **Sprint Story** | AC #Y | N#, R#, S#, D#, E# covered | ⬜ |
| **Tech Story** (if applicable) | Section | Technical requirements | ⬜ |

### Coverage Checklist

- [ ] **No new PRD artifacts:** This Task does NOT introduce new N#/R#/S#/D#/E# not in parent stories
- [ ] **Specific AC identified:** Task implements specific numbered AC from parent story
- [ ] **Notifications (N#):** Any notifications this task touches are listed
- [ ] **Rules (R#):** Any rules this task enforces are listed
- [ ] **Errors (E#):** Any errors this task handles are listed
- [ ] **Timing compliance:** Any timing requirements from parent are achievable in this task's scope

### ADO-865620 Prevention for Tasks

| Check | Question | Status |
|-------|----------|--------|
| **AC alignment** | Does this task implement the exact AC from parent story? | ⬜ |
| **No scope creep** | Does this task add requirements not in parent AC? | ⬜ |
| **Text verbatim** | Does this task use parent's exact user-visible text? | ⬜ |
| **Count correct** | Do technical limits match parent's count rules? | ⬜ |

---

## 📊 How We Know It Works
**<Validation—avoid duplicating full Sprint test plan>**

- **Manual:** [Quick check] *(optional)*
- **Automated:** [What runs in CI] *(optional)*
- **Feature flag:** [Name, default] *(optional)*

---

## ⚠️ Risks
**<Task-level risks only>**

- **Risk:** […] *(optional)*
- **Mitigation:** […] *(optional)*

---

## 📝 Notes
[Any context, spikes, links to PRs]

---

## 📋 Task Metadata

**Status:** [ ] To Do  [ ] In Progress  [ ] In Review  [ ] Done  
**Assignee:** [Name] *(optional)*  
**Created:** [Date]  
**Last Updated:** [Date]

---

## 🔗 Traceability *(required)*

| Artifact | Id / link |
|----------|-----------|
| **Sprint Story** | |
| **Master Story** | |
| **Tech Story** *(if applicable)* | |
| **PRD section IDs** | e.g. 4B, 4C |
| **ADO Task** | AB#[id] when synced |

*User-visible copy for this task’s scope should already appear on **Sprint/Master 📎 sections** or **PRD**—do not re-invent strings here unless this task introduces **new** copy (then align with PM).*

---

## ℹ️ Template Info
**Purpose:** Atomic work unit (2h–2d). **Audience:** Engineers, QA.  
**Hierarchy:** PRD → Master → Sprint → Tech (optional) → **Task**.
