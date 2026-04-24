# 🎯 Sprint Story Template

> **Purpose**: Executable slice for one sprint. Derived from Master Story. Team-owned. Contains tasks.

---

## §1 Metadata

| Field | Value |
|-------|-------|
| **Story ID** | [MASTER-ID]-S[XX] |
| **Title** | [Action + Scope + Sprint Context] |
| **Parent Feature** | [MASTER-ID]: [Master Story Title] |
| **Sprint** | Sprint [X] |
| **Points** | [Fibonacci: 1/2/3/5/8] |
| **Status** | [To Do / In Progress / In Review / Done] |

### Team
| Role | Assignee |
|------|----------|
| **Dev Lead** | |
| **Backend** | |
| **Frontend** | |
| **QA** | |

---

## §2 Sprint Goal

> **One sentence: What's the user-visible outcome at sprint end?**

[By end of this sprint, user can...]

---

## §3 Scope

### ✅ Included (This Sprint)

| # | Capability | From Master AC |
|---|------------|----------------|
| 1 | [What's being delivered] | AC-01, AC-02 |
| 2 | [What's being delivered] | AC-03 |
| 3 | [What's being delivered] | AC-E01 |

### 🚫 Excluded (Future Sprints)

| Capability | Reason | Target Sprint |
|------------|--------|---------------|
| [Deferred item] | [Why not now] | Sprint Y |
| [Deferred item] | [Dependency] | Sprint Z |

### ⚠️ Assumptions

- [Assumption that must be true for this scope]
- [Dependency that's expected to be ready]

---

## §4 JTBD (Scoped)

```
WHEN [situation/trigger — specific to this sprint]
USER WANTS TO [motivation]
SO THEY CAN [outcome/progress]
```

---

## §5 Acceptance Criteria (This Sprint Only)

> **Subset of Master ACs. Only what's being delivered this sprint.**

```gherkin
AC-01: [From Master]
GIVEN [context]
WHEN [action]
THEN [outcome]
```

```gherkin
AC-02: [From Master]
GIVEN [context]
WHEN [action]
THEN [outcome]
```

```gherkin
AC-E01: [Edge Case — if in scope]
GIVEN [context]
WHEN [action]
THEN [outcome]
```

---

## §6 Copy (This Sprint Only)

| Element | English | Hindi |
|---------|---------|-------|
| [Only elements needed this sprint] | | |

---

## §7 Tasks

> **Checklist format. Track within this story, not as separate tickets.**

### Backend
- [ ] **[BE-1]** [Task description] — Est: [X]h — @[Owner]
- [ ] **[BE-2]** [Task description] — Est: [X]h — @[Owner]

### Frontend
- [ ] **[FE-1]** [Task description] — Est: [X]h — @[Owner]
- [ ] **[FE-2]** [Task description] — Est: [X]h — @[Owner]
- [ ] **[FE-3]** [Task description] — Est: [X]h — @[Owner]

### QA
- [ ] **[QA-1]** [Test scenario/area] — Est: [X]h — @[Owner]
- [ ] **[QA-2]** [Test scenario/area] — Est: [X]h — @[Owner]

### Other
- [ ] **[OTH-1]** [Analytics instrumentation] — @[Owner]
- [ ] **[OTH-2]** [Documentation update] — @[Owner]

---

## §8 Analytics (This Sprint)

| Event | Status |
|-------|--------|
| `event_from_master` | [ ] Instrumented [ ] Verified |

---

## §9 Dependencies

| Dependency | Status | Blocker? |
|------------|--------|----------|
| [What this needs] | [Ready/Pending] | [Yes/No] |

---

## §10 Risks

| Risk | Mitigation |
|------|------------|
| [Risk 1] | [Plan] |

---

## §11 Definition of Done

- [ ] All ACs in scope pass
- [ ] Code reviewed and merged
- [ ] Unit tests passing
- [ ] Design review passed
- [ ] Analytics events verified
- [ ] Works on target devices
- [ ] QA sign-off
- [ ] PO demo accepted
- [ ] No critical bugs open

---

## §12 Links

| Asset | Link |
|-------|------|
| Parent Master Story | [Link] |
| Design (this scope) | [Link] |
| PR/Branch | [Link] |

---

## §13 Sprint Notes

> **Updates during sprint (blockers, scope changes, decisions)**

| Date | Note |
|------|------|
| [Date] | [Note] |

---
