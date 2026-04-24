# 🧠 Feature Story Template (Master)

> **Purpose**: Complete feature definition. Source of truth. Created once. PM-owned. NO TASKS — tasks belong in Sprint Stories.

---

## §1 Metadata

| Field | Value |
|-------|-------|
| **Feature ID** | [EPIC]-[FEATURE]-[SEQ] |
| **Title** | [Verb + Object + Outcome] |
| **Epic** | |
| **PRD Reference** | Section [X.X] |
| **Owner** | [PM Name] |
| **Created** | [Date] |
| **Status** | [Draft / Refined / Ready / In Progress / Done] |
| **Target Release** | [Release/Version] |
| **Total Estimate** | [Points] (indicative, refined per sprint) |

---

## §2 Outcome

| Dimension | Definition |
|-----------|------------|
| **User Outcome** | [What user can do/feel after this ships] |
| **Business Outcome** | [KPI impact] |
| **Success Metric** | [Quantified target] |
| **Guardrail** | [Threshold that triggers escalation] |
| **Measurement Point** | [Day X post-launch] |

---

## §3 Problem

| Element | Description |
|---------|-------------|
| **Current State** | [What happens today / pain point] |
| **Evidence** | [Data or [H] for hypothesis] |
| **Why Now** | [Why this feature, this release] |

---

## §4 User Context

| Attribute | Description |
|-----------|-------------|
| **Persona** | [Target user with relevant traits] |
| **Trigger** | [When/where problem occurs] |
| **Environment** | [Device, network, language, journey stage] |

---

## §5 Job To Be Done

```
WHEN [situation/trigger]
USER WANTS TO [motivation]
SO THEY CAN [outcome/progress]
```

---

## §6 Solution

| Element | Description |
|---------|-------------|
| **Core Idea** | [One-line solution] |
| **Hypothesis** | [Why we believe this works] |
| **Confidence** | [High / Medium / Low] |

---

## §7 Capabilities (Full Scope)

> **All capabilities this feature delivers when fully complete.**

### Must Have (P0)
| # | Capability | Sprint Target |
|---|------------|---------------|
| 1 | [User can...] | Sprint X |
| 2 | [System enables...] | Sprint X |
| 3 | [System ensures...] | Sprint Y |

### Should Have (P1)
| # | Capability | Sprint Target |
|---|------------|---------------|
| 4 | [Capability] | Sprint Y |
| 5 | [Capability] | Sprint Z |

### Nice to Have (P2)
| # | Capability | Sprint Target |
|---|------------|---------------|
| 6 | [Capability] | Backlog |

---

## §8 Experience Intent

| Dimension | Intent |
|-----------|--------|
| **Should Feel** | [e.g., Instant, effortless, trustworthy] |
| **Speed** | [e.g., < 2 seconds] |
| **Cognitive Load** | [e.g., Zero decisions required] |
| **Error Recovery** | [e.g., Self-healing, never stuck] |

---

## §9 Acceptance Criteria (Complete)

> **All ACs for the full feature. Sprint stories will reference subsets.**

### Happy Path

```gherkin
AC-01: [Name]
GIVEN [context]
WHEN [action]
THEN [outcome]
```

```gherkin
AC-02: [Name]
GIVEN [context]
WHEN [action]
THEN [outcome]
```

### Edge Cases

```gherkin
AC-E01: [Name]
GIVEN [edge condition]
WHEN [action]
THEN [graceful handling]
```

```gherkin
AC-E02: [Name]
GIVEN [edge condition]
WHEN [action]
THEN [graceful handling]
```

### Error States

```gherkin
AC-ERR01: [Name]
GIVEN [error condition]
WHEN [action]
THEN [error handling + recovery]
```

### Anti-Patterns

```gherkin
AC-NOT01: [Name]
GIVEN [any state]
THEN [this must NOT happen]
```

---

## §10 Content & Copy

| Element | English | Hindi |
|---------|---------|-------|
| [Element 1] | | |
| [Element 2] | | |
| [Error 1] | | |

---

## §11 Analytics (All Events)

| Event | Trigger | Parameters | KPI |
|-------|---------|------------|-----|
| `event_1` | [When] | [Params] | [KPI] |
| `event_2` | [When] | [Params] | [KPI] |

---

## §12 Dependencies

| Dependency | Owner | Status |
|------------|-------|--------|
| [Dependency 1] | [Team] | [Status] |
| [Dependency 2] | [Team] | [Status] |

---

## §13 Out of Scope

- [Explicitly excluded 1]
- [Explicitly excluded 2]

---

## §14 Design Reference

| Asset | Link | Status |
|-------|------|--------|
| Full Feature Design | [URL] | |

---

## §15 Sprint Breakdown (Planned)

| Sprint | Scope | Points | Status |
|--------|-------|--------|--------|
| Sprint X | [Capabilities 1-2] | Est | [Planned/Done] |
| Sprint Y | [Capabilities 3-4] | Est | [Planned] |
| Sprint Z | [Capabilities 5-6] | Est | [Backlog] |

---

## §16 Linked Sprint Stories

| Sprint Story ID | Sprint | Scope | Status |
|-----------------|--------|-------|--------|
| [ID]-S01 | Sprint X | [Brief scope] | [Status] |
| [ID]-S02 | Sprint Y | [Brief scope] | [Status] |

---
