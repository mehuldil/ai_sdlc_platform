# 🧠 Master Story — [Feature / Product Name]

> **ADO completeness:** Whoever reads this in Azure DevOps (or any work item) should **not need to open the PRD**. Copy **verbatim** anything required to build or test: notification IDs **and** full message text, error strings, field labels, limits, enums, and tables from the PRD.
>
> **No invention:** If the PRD does not support a subsection, **do not** paraphrase or fill with generic text. Use `USER_INPUT_REQUIRED` — see [STORY_TEMPLATE_REGISTRY.md](STORY_TEMPLATE_REGISTRY.md).
>
> **No redundancy:** Each section has a **single job** (see map below). Do **not** paste the same paragraph into Outcome, Problem, and Context. Do **not** restate full notification copy inside Acceptance Criteria if it already lives under **PRD-sourced specifics**—reference the row (e.g. “Behavior matches **Notification Nx** in the table below”).
>
> **Readable:** Short sentences. **Bold** labels. Bullets. Blank lines between ideas. Tables for structured PRD content.

### Section map (what goes where — keep content unique)

| Section | Single job | Do **not** duplicate here |
|--------|------------|-----------------------------|
| **Outcome** | Measurable user + business result | Full problem narrative, Gherkin, or notification tables |
| **Problem** | Pain, evidence, why now | Solution detail, AC text, metrics targets |
| **JTBD** | Trigger → motivation → outcome (one block) | Same sentences as Problem or Outcome |
| **Capability** | What the product enables (capabilities-level) | Verbatim PRD tables (those go in **PRD-sourced specifics**) |
| **PRD-sourced specifics** | **All** verbatim PRD facts: copy, notifications, errors, limits | Re-stating in prose in other sections |
| **Experience intent** | How it should *feel* (tone, load, speed expectation) | Figma links (use **UI & design**) |
| **UI & design** | Figma / prototype / design status | Full business outcome (Outcome) or Gherkin |
| **Acceptance criteria** | Testable Given/When/Then | Full notification text when not already in **PRD-sourced specifics** |
| **Measurement** | KPIs, analytics, baselines, targets | A/B methodology (that is **Validation plan**) |
| **Validation plan** | How we validate (pilot, A/B, rollout gates) | Re-listing every KPI from Measurement |

---

## 🎯 Outcome
**<What measurable change should happen?>**

- **User Outcome:** [Single sentence - what user can do differently]
- **Business Impact:** [Revenue, retention, CAC, engagement metric] *(optional)*
- **Success Metric:** [Exact number/percentage target] *(optional)*
- **Time Horizon:** [1Q, 2Q, 3Q, or specific date] *(optional)*

---

## 🔍 Problem Definition
**<What exact problem exists today?>**

- **Current user behavior:** [How users work today] *(optional)*
- **Pain / friction:** [Specific moment of friction]
- **Evidence:** [Data point, user research, or observation] *(optional)*
- **Why this matters now:** [Market opportunity, user feedback signal, trend] *(optional)*

---

## 👤 Target User & Context
**<Who is this for? When does the problem occur?>**

- **Persona:** [User segment, role, characteristics]
- **Trigger moment:** [When problem occurs in user's workflow] *(optional)*
- **Environment:** [App/feature/journey stage where problem manifests] *(optional)*

---

## ⚡ Job To Be Done (JTBD)
**When** [user situation/context],
**User wants to** [motivation/desire],
**So they can** [expected outcome/benefit]

*(optional - if not obvious from problem)*

---

## 💡 Solution Hypothesis
**<What we believe will solve the problem>**

- **Core idea:** [One-paragraph description of solution]
- **Why it should work:** [Behavioral/user principle supporting this] *(optional)*
- **User behavior change expected:** [What will users do differently?] *(optional)*

---

## 🧩 Capability Definition
**<What can users do? What does the system enable?>**

### Core Capability
- **User can:** [e.g., "upload files in batch without manual retry"]
- **System enables:** [e.g., "automatic queue management and retry logic"] *(optional)*
- **System ensures:** [e.g., "no duplicate uploads, atomic transactions"] *(optional)*

### Guardrails *(optional)*
- **System must prevent:** [e.g., "users cannot delete live data"]
- **Constraints:** [e.g., "batch size limit 1000 items", "max file size 5GB"]

---

## 📎 PRD-sourced specifics *(required when PRD lists copy, notifications, or messages)*

**Purpose:** One place for **verbatim** PRD content so ADO is self-contained. If the PRD names “Notification N7” or “Error E3”, the **full text** (and locale variants if in PRD) goes **here**, not only the ID.

**Rules:**

- **Never** list a PRD artifact id (e.g. `Nx`, `§4.2`) alone without the lifted text (or a `USER_INPUT_REQUIRED` block if PRD is missing it).
- Prefer **tables** aligned to the PRD (notifications, errors, empty states, tooltips).
- Acceptance criteria may **reference** rows here (e.g. “Matches **Notification N7** below”) without repeating the string.

### Notifications & user-visible copy

| ID / PRD ref | User-visible text (all locales from PRD) | Surface (toast, modal, inline, …) | Trigger |
|--------------|------------------------------------------|-------------------------------------|---------|
| [PRD id] | [Full text] | | |

### Errors & edge copy *(if applicable)*

| ID / PRD ref | Message | When shown |
|--------------|---------|------------|

### Data / config limits *(if applicable)*

| Field / rule | Value | PRD § |
|--------------|-------|-------|

*If a subsection does not apply, write **N/A — not in PRD** (do not invent placeholders).*

### PRD Coverage Matrix *(required for ADO push)*

**Purpose:** Ensure every PRD requirement is mapped to an AC. See [`PRD_COVERAGE_CHECKLIST.md`](PRD_COVERAGE_CHECKLIST.md) for full guidance.

| PRD Artifact | IDs in PRD | IDs in Story | Coverage % | Status |
|--------------|------------|--------------|------------|--------|
| Notifications (N#) | | | | ⬜ |
| Rules (R#) | | | | ⬜ |
| Scenarios (S#) | | | | ⬜ |
| Dependencies (D#) | | | | ⬜ |
| Errors (E#) | | | | ⬜ |

**Contradiction Check:**
- [ ] No AC contradicts PRD requirements
- [ ] All user-visible text matches PRD verbatim
- [ ] Timing/SLA requirements explicitly captured
- [ ] Count limits verified ("including" vs "excluding")

---

## 🎯 Experience Intent
**<How should this feel? What's the user experience like?>**

- **Should feel:** [e.g., "effortless, real-time, intelligent"] *(optional)*
- **Speed expectation:** [e.g., "sub-second response", "background async"] *(optional)*
- **Cognitive load:** [e.g., "minimal: one click", "clear feedback"]
- **Default vs control:** [e.g., "smart defaults, power user overrides available"] *(optional)*

---

## 🎨 UI & design

**Purpose:** Links and design readiness—not the same as **Experience intent** (qualitative feel). Put **Figma / design files** here.

- **Figma (primary):** [URL] — File/page: [name] — **Last updated:** [date] *(or `USER_INPUT_REQUIRED` / **N/A — backend-only feature**)*
- **Prototype / Zeplin / other:** [URL] *(optional)*
- **Components / design system:** [e.g. DS v3 — Button, Modal] *(optional)*
- **Design status:** [ ] Not started  [ ] Draft  [ ] Ready for dev  [ ] N/A (no UI)

*If UI exists but no link yet, use `USER_INPUT_REQUIRED` with owner — do not invent a URL.*

---

## 🧾 Acceptance Criteria
**<Feature is done when...>**

Use **one numbered scenario per block**. Put **each scenario on its own numbered item**; use a **blank line between** items. Under each number, keep **Given / When / Then** on separate lines.

### Core Flow

1. **Given** [context/precondition]
   **When** [user action]
   **Then** [expected outcome]

2. **Given** [context/precondition]
   **When** [user action]
   **Then** [expected outcome]

*(at least 1 scenario in Core Flow)*

### Failure / Edge Case *(optional)*

1. **Given** [edge condition]
   **When** [action]
   **Then** [fallback behavior]

2. **Given** [edge condition]
   **When** [action]
   **Then** [fallback behavior]

---

## 📊 Measurement & Signals
**<KPIs, analytics, baselines, and targets — not the same as Validation plan (below).>**

### Primary Metric
- **Name:** [e.g., "Same-day completion rate"]
- **Baseline:** [Current %, number] *(optional)*
- **Target:** [e.g., "↑ from 40% to 70%"]
- **Observation window:** [1 week, 1 month, 1 quarter] *(optional)*

### Secondary Signals *(optional)*
- **Engagement:** [e.g., "daily active users, feature adoption %"]
- **Retention:** [e.g., "7-day retention, month-over-month churn"]
- **Feature usage:** [e.g., "# of batch uploads, avg batch size"]

### Event Tracking *(optional)*
- **Event name:** [e.g., "feature_batch_upload_initiated"]
- **Trigger:** [When event fires]
- **Parameters:** [What metadata to capture]

---

## 🧪 Validation Plan
**<How we prove success: pilot, A/B, rollout %, user testing — avoid repeating the full KPI table from Measurement. Reference metric names only.>**

- **Experiment type:** [A/B test / rollout / cohort / user testing / pilot]
- **Success threshold:** [Statistical significance, adoption %, completion %]
- **Observation window:** [1 week, 2 weeks, 1 month] *(optional)*

---

## ⚠️ Risks & Unknowns
**<What could go wrong? What are we unsure about?>**

- **Adoption risk:** [e.g., "Users may not discover the feature"] *(optional)*
- **Behavioral uncertainty:** [e.g., "Users may prefer manual control over automation"] *(optional)*
- **Dependency risk:** [e.g., "Requires API deprecation of old endpoint"] *(optional)*

---

## 🔗 Dependencies
**<What blocks this story? What do we need from others?>**

- **Product dependencies:** [e.g., "Analytics event structure from POD-X"] *(optional)*
- **Data readiness:** [e.g., "User segmentation model must be live"] *(optional)*
- **External systems:** [e.g., "Requires payment processor webhook integration"] *(optional)*
- **Cross-POD blockers:** [POD-X must complete Y before we start Z] *(optional)*
- **Timeline dependencies:** [Specify by quarter/month if applicable] *(optional)*

---

## 🚫 Explicit Non-Goals
**<What we are NOT solving in this story>**

- [e.g., "Not building mobile-first experience (mobile v2.0)"] *(optional)*
- [e.g., "Not supporting <100 user teams (enterprise plan)"] *(optional)*

---

## 📅 Priority & Rollout Strategy
**<When? How aggressively?>**

- **Priority:** [P0/P1/P2 - based on outcome impact]
- **Rollout plan:** [Phased % (5% → 25% → 100%) OR full launch OR beta] *(optional)*
- **Success gate:** [What metric must hit before next % rollout?] *(optional)*

---

## 🏆 Related Stories
**<Connections to other work>**

- **Depends on:** [Other master stories] *(optional)*
- **Unblocks:** [Downstream stories] *(optional)*
- **Relates to:** [Adjacent stories] *(optional)*

---

## 📝 Notes
[Any additional context, open questions, or considerations]

---

## 📋 Story Metadata

**Status:** [ ] Draft  [ ] In Review  [ ] Approved  [ ] In Progress  [ ] Done
**Owner:** [Name]
**Created:** [Date]
**Last Updated:** [Date]

---

## 🔗 PRD Traceability *(required)*

| PRD document (path or URL) | Section IDs (e.g. 4B, 4C) | ADO Feature / Epic ID |
|----------------------------|---------------------------|------------------------|
| | | |

*Maps every downstream Sprint Story, Task, commit (AB#), and PR back to explicit PRD sections.*

---

## Azure DevOps

After this file is filled and **`sdlc story validate`** passes, create the work item and link the id above.

| Goal | Command |
|------|---------|
| ADO **Feature** (typical for a master story) | `sdlc story push <this-file.md> --type=feature` — same as `sdlc ado push-story`; prints the numeric id |
| ADO **User Story** (if you prefer that type) | `sdlc story push <this-file.md>` (default `--type=story`) |
| ADO **Epic** | `sdlc story push <this-file.md> --type=epic` |

Sprint-level files usually use **`sdlc story push <SS-file.md> --parent=<FeatureWorkItemId>`** so the User Story nests under the Feature.

---

## ℹ️ Template Info
**Purpose:** Strategic, discovery-phase story. Source of truth. Created once.
**Audience:** Product, leadership, cross-pod stakeholders
**Created by:** Product Manager
**Lifecycle:** Long-term (1-3 quarters)
