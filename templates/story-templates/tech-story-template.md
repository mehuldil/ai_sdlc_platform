# 🏗️ Tech Story — [Component / Service / Flow Name]

> **Single source of truth (implementation):** This document is the **authoritative technical spec for build and review**. It must be **grounded in fact**—repository structure, existing APIs, approved **system design**, **Master Story**, and **Sprint Story**—not speculative architecture.
>
> **No guesses:** If a fact is unknown, use `USER_INPUT_REQUIRED` (see [STORY_TEMPLATE_REGISTRY.md](STORY_TEMPLATE_REGISTRY.md)). Do **not** invent endpoints, schemas, SLAs, or dependencies.
>
> **Non-regression:** New behavior must be **explicitly safe** for existing users, APIs, jobs, and data. Call out **what must not change** and how you **prove** it (tests, flags, contracts).

---

## 📚 Inputs & source of truth *(required)*

**Every technical claim should trace** to one of: **system design** (section/figure), **Master/Sprint story**, **existing code/module**, or **observed runtime**—or be marked `USER_INPUT_REQUIRED`.

| Source | Link / ADO id / repo path | Revision (commit, date, or doc version) | Sections / ACs used |
|--------|---------------------------|------------------------------------------|---------------------|
| **System design** (primary) | | | e.g. §3.2, Fig. 4 |
| **Master Story** | | | Outcome / capabilities / 📎 PRD lift |
| **Sprint Story** | | | Scope, ACs, 📎 sprint lift |
| **Repo / module map** | e.g. `.sdlc/module/` or `docs/architecture` | | |

---

## 🧱 Baseline: existing system *(required — evidence-based)*

**Purpose:** Describe **today’s** behavior so the team knows **what must keep working**. Prefer **code anchors** and **facts** over narrative.

- **Services / modules involved:** [Names; link packages or top-level dirs]
- **Current behavior (as-is):** [What users/systems experience today—in **short** bullets]
- **Existing contracts:** [REST/queue events/schemas consumers rely on—cite file or OpenAPI path]
- **Known constraints:** [DB, rate limits, idempotency, ordering—**from design or code**]
- **Repo anchors** (extend table as needed):

| Path, package, or service | Role today (read / extend / must not break) |
|---------------------------|-----------------------------------------------|
| | |

---

## 🎯 Technical goal & delta *(required)*

**What changes** relative to the baseline—**one paragraph max**, then bullets.

- **Delta:** [New capability or change—tied to Sprint/Master scope]
- **Out of scope (technical):** [What this tech story explicitly does **not** change]
- **Performance / reliability targets:** [Only if stated in design or Sprint/Master—else `USER_INPUT_REQUIRED`]

---

## 📐 Alignment with system design *(required)*

- **Design sections / diagrams:** [List § and fig refs this work implements]
- **Consistency:** [How this matches the design—same components, same boundaries]
- **Deviation:** [If implementation differs from design] → **ADR link** or decision record + approver *(no silent drift)*

---

## 🔀 Change impact & blast radius *(required)*

**Purpose:** Who and what is affected—**functional** and **technical**.

| Area | Impact | Owner / note |
|------|--------|----------------|
| APIs / events | [New/changed/deprecated] | |
| Data stores | [Migration, backfill, new indexes] | |
| Jobs / async | [New consumers, topic changes] | |
| Clients (apps, BFFs) | [Contract changes] | |
| Observability | [New metrics/logs] | |

- **Dependencies:** [Upstream/downstream systems; **blocking** items]
- **Rollback data risk:** [None / low / high + mitigation]

---

## 🛡️ Non-regression, compatibility & “do not break” *(required)*

**Purpose:** Implementation must **not** break existing functionality unless an **explicit** deprecation path is approved.

- **Must remain true (invariants):** [Bullets—e.g. “Existing GET `/x` response shape unchanged for v1 clients”]
- **Backward compatibility:** [API versioning, feature flags, dual-write period, default-off behavior]
- **Contract / regression checks:** [What stays green—e.g. “existing integration test suite `…`”, “consumer contract tests for …”]
- **Feature flags / kill switches:** [If used—name, default, rollout tie-in]

---

## 🏛️ Architecture & implementation approach

### Design *(grounded)*

- **Approach:** [Queue + worker, new service, extension point—**aligned with design doc**]
- **Components:** [New vs modified—name them]
- **Data flow:** [Request/event → processing → persistence → response]
- **Failure modes:** [Degrade paths; idempotency]

### Technology & integration *(optional but cite sources)*

- **Persistence / messaging / cache:** [Only if in scope—match design or repo standards]
- **Integration points:** [Upstream/downstream; **versioning**]

### Repo anchors *(update before merge)*

| Path or package | Change (add / modify / replace) |
|-----------------|--------------------------------|
| | |

---

## 📈 Performance & scalability

*(Fill from design or measured need; avoid invented numbers.)*

- **Load / latency / throughput:** [As in design or Sprint NFRs]
- **Capacity:** [If applicable]

---

## 🔒 Reliability & resilience

- **Failure scenarios:** [Relevant to this change]
- **Recovery / timeouts / circuit breakers:** [As per design or patterns in repo]

---

## 🔐 Security & compliance

*(If applicable—PII, authz, audit.)*

---

## 📊 Observability

- **Logs / metrics / traces:** [What is new or changed; **no PII** in log fields per policy]

---

## 🧪 Testing strategy *(required)*

**Purpose:** Prove **new** behavior **and** **no unintended breakage**.

- **Unit / component:** [Scope]
- **Integration / contract:** [APIs, events, DB—**including existing consumers**]
- **Regression:** [Explicit: suites, paths, or smoke list for **old** behavior]
- **Load / chaos:** [If required by design or risk]
- **Pre-prod / canary:** [If applicable]

---

## 🧾 Acceptance criteria

Use **numbered** checklist items (`1. [ ]`, `2. [ ]`, …). **Blank line between** items.

### Core

1. [ ] Implementation matches **system design** sections cited above (or approved deviation documented).
2. [ ] **Master / Sprint** acceptance and scope satisfied at technical level (link AC ids).
3. [ ] **Non-regression:** Invariants in **🛡️ Non-regression** verified (tests or checks named).
4. [ ] **Repo anchors** table updated; code review confirms no unintended surfaces changed.
5. [ ] **Observability** in place for new paths; alerts/dashboards if required by design.

### Optional / NFR

1. [ ] [Performance target from design] measured in [environment].
2. [ ] Rollback path validated (see Rollout).

---

## 🔄 Rollout & rollback plan

- **Strategy:** [Canary / flag / blue-green—**per org standards**]
- **Rollback trigger:** [Measurable—e.g. error rate, SLO breach]
- **Data migration:** [If any—forward/backward steps]

---

## 📚 Documentation & artifacts

- **Design / ADR / diagram links:** [Updated]
- **API contract:** [OpenAPI / schema PR]
- **Runbook / troubleshooting:** [If operability changes]

---

## ⚠️ Technical risks & unknowns

- **Risk:** [e.g. integration uncertainty] | **Mitigation:** […]
- **Unknown:** […] | **Resolution path:** [spike / USER_INPUT_REQUIRED]

---

## 📝 Notes

[Decisions, open questions, review feedback]

---

## 📋 Story metadata

**Status:** [ ] Draft  [ ] Review  [ ] Approved  [ ] In implementation  [ ] Done  
**Owner:** [Tech lead / engineer]  
**Created:** [Date]  
**Last updated:** [Date]

---

## 🔗 Traceability *(required)*

| Artifact | Id / link |
|----------|-----------|
| **System design** | |
| **Master Story** | |
| **Sprint Story** | |
| **ADO Feature / Story** (if applicable) | |
| **PRD section IDs** (from Master/Sprint) | |

---

## 📎 PRD Inheritance & Coverage Verification *(required)*

**Purpose:** Verify all PRD artifacts (N#/R#/S#/D#/E#) from parent Master/Sprint stories are understood and properly implemented. Tech Stories must NOT introduce new PRD artifacts not covered by parent stories.

### Inherited from Parent Stories

| PRD Artifact | ID | Parent Story Location | Implementation Approach | Verified |
|--------------|-----|----------------------|------------------------|----------|
| **Notifications** | N# | Master/Sprint section | How this tech story implements it | ⬜ |
| **Rules** | R# | Master/Sprint section | How this tech story enforces it | ⬜ |
| **Scenarios** | S# | Master/Sprint section | How this tech story handles it | ⬜ |
| **Dependencies** | D# | Master/Sprint section | API/Service implementation status | ⬜ |
| **Errors** | E# | Master/Sprint section | Error handling implementation | ⬜ |

### Coverage Verification Checklist

- [ ] **No new PRD artifacts:** This Tech Story does NOT introduce new N#/R#/S#/D#/E# not in parent stories
- [ ] **All inherited N# covered:** Every notification from parent has implementation approach
- [ ] **All inherited R# enforced:** Every rule from parent has technical enforcement mechanism
- [ ] **All inherited D# available:** Every dependency API is available or has workaround
- [ ] **All inherited E# handled:** Every error scenario has technical handling strategy
- [ ] **Timing requirements captured:** SLA/timing requirements (e.g., "within 60s") have technical implementation
- [ ] **Count limits enforced:** Member/data limits have technical enforcement (db constraints, validation)

### ADO-865620 Prevention for Tech Stories

| Pattern | Check | Status |
|---------|-------|--------|
| **Flow contradiction** | Implementation matches parent's flow | ⬜ |
| **Count contradiction** | Technical enforcement matches parent's count rules | ⬜ |
| **Copy contradiction** | Technical implementation uses parent's verbatim text | ⬜ |
| **Timing contradiction** | Technical implementation meets parent's timing requirements | ⬜ |
| **Visibility contradiction** | Technical implementation matches parent's show/hide rules | ⬜ |

---

## ℹ️ Template info

**Purpose:** Implementation-grade technical spec—grounded in design and stories, with explicit **non-regression**.  
**Audience:** Engineers, architects, QA (technical review)  
**Created by:** Tech lead / senior engineer (with architect as needed)  
**Lifecycle:** Tied to sprint; updated when design or scope shifts
