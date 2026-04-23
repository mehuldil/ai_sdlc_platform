# PRD Coverage Checklist for Master Stories

**Purpose:** Ensure every PRD requirement (Notifications, Rules, Scenarios, Dependencies, Errors) is explicitly mapped to Acceptance Criteria in the Master Story.

**When to use:** After drafting the Master Story, before ADO push. Validate that all PRD artifacts are covered.

---

## Coverage Matrix Template

Copy this table into your Master Story's **📎 PRD-sourced specifics** section and fill it out:

### Notification Matrix Coverage (N1-N20)

| ID | PRD Text | Surface | Trigger | AC Reference | Status |
|----|----------|---------|---------|----------------|--------|
| N1 | | | | AC #X | ⬜ |
| N2 | | | | AC #X | ⬜ |
| N3 | | | | AC #X | ⬜ |
| N4 | | | | AC #X | ⬜ |
| N5 | | | | AC #X | ⬜ |
| ... | | | | | ⬜ |

### Rules Coverage (R1-R20)

| ID | Rule Description | AC Reference | UI/UX Impact | Status |
|----|-------------------|--------------|----------------|--------|
| R1 | | AC #X | | ⬜ |
| R2 | | AC #X | | ⬜ |
| R3 | | AC #X | | ⬜ |
| ... | | | | ⬜ |

### Scenarios Coverage (S1-S10)

| ID | Scenario | Flow/State | AC Reference | Status |
|----|----------|------------|--------------|--------|
| S1 | | | AC #X | ⬜ |
| S2 | | | AC #X | ⬜ |
| S3 | | | AC #X | ⬜ |
| ... | | | | ⬜ |

### Dependencies Coverage (D1-D10)

| ID | API/Dependency | Team/Owner | AC Reference | Status |
|----|----------------|------------|--------------|--------|
| D1 | | | AC #X | ⬜ |
| D2 | | | AC #X | ⬜ |
| ... | | | | ⬜ |

### Error Scenarios Coverage (E1-E20)

| ID | Error Message | When Shown | AC Reference | Status |
|----|---------------|------------|--------------|--------|
| E1 | | | AC #X | ⬜ |
| E2 | | | AC #X | ⬜ |
| ... | | | | ⬜ |

---

## Common Coverage Gaps to Check

### Notifications (Often Missed)
- [ ] **N4/N5**: Decline/Expiry behavior (no push, status-only)
- [ ] **N7/N8**: Removal notifications (check timing requirement - "within 60s")
- [ ] **N14**: Owner account deletion push to all members
- [ ] **Owner-specific toasts**: Not just member notifications

### Rules (Often Missed)
- [ ] **R2**: Delete existing hub before creating new one
- [ ] **R3**: Member count display format ("X out of 5")
- [ ] **R5**: Declined invites NOT shown in family detail
- [ ] **R6**: Resend behavior (new code, invalidates old, same slot)
- [ ] **R15**: Owner sees individual member storage usage
- [ ] **R16+**: Any member count limits (check "including" vs "excluding" owner)

### Scenarios (Often Missed)
- [ ] **S6**: Degraded state when owner deletes account
- [ ] **S7**: Member leaves after exceeding quota (read-only scenario)
- [ ] **S8**: Storage consumption order (personal → family pool)
- [ ] **S9+**: Redirection behaviors after removal/leave

### Dependencies (Often Missed)
- [ ] **D6**: Member Details API (referenced in D7 but needs its own AC)
- [ ] **D7**: Delete/Leave Hub API

### Entry Points (Often Missed)
- [ ] **Multiple paths**: "See All" AND "+" icon
- [ ] **Auto-creation**: Hub created on first invite vs separate Create step

---

## Contradiction Checks

Before finalizing, verify these common contradiction patterns:

### 1. Flow Contradictions
```
❌ "User taps Create Family Hub, confirms creation"
✅ "Hub created automatically when first invite sent" (per Sprint 3 decision)
```

### 2. Count Contradictions
```
❌ "Max 5 members including owner" (5 total)
✅ "Max 5 members excluding owner" (6 total) — verify PRD wording exactly
```

### 3. Copy Contradictions
```
❌ "Leave Family Hub? Your personal library is unaffected."
✅ "Leave Family Hub?" only (extra text may be scenario description, not dialog copy)
```

### 4. Timing Contradictions
```
❌ "N7 + N8 sent on removal"
✅ "N7 + N8 sent within 60 seconds of removal" (timing requirement from PRD)
```

### 5. Visibility Contradictions
```
❌ "All invite statuses shown in member list"
✅ "Declined invites not shown in family detail" (R5)
```

---

## Pre-Push Validation Checklist

Before running `sdlc story push`, confirm:

- [ ] Every N# from PRD Notification Matrix has a row in coverage table
- [ ] Every R# from PRD Rules section has a row in coverage table
- [ ] Every S# from PRD Scenarios has a row in coverage table
- [ ] Every D# from PRD Dependencies has a row in dependencies table
- [ ] Every E# from PRD Error Scenarios has a row in error table
- [ ] Every row in coverage tables has an AC Reference filled in
- [ ] No AC contradicts PRD requirements
- [ ] All user-visible text is lifted verbatim from PRD
- [ ] Timing/SLA requirements are explicitly captured
- [ ] Entry points (all paths) are documented
- [ ] Redirection behaviors are documented

---

## Automated Validation

Run these validators before ADO push:

```bash
# 1. Validate story structure
sdlc story validate stories/FH-001-master.md

# 2. Check PRD coverage (new check)
./templates/story-templates/validators/prd-coverage-validator.sh \
  stories/FH-001-master.md \
  docs/prd/FamilyHub_Phase1.docx

# 3. Push to ADO
sdlc story push stories/FH-001-master.md --type=feature
```

---

## ADO-865620 Feedback Reference

The issues found in ADO-865620 that this checklist prevents:

| Issue Type | PRD Reference | What Was Wrong | Checklist Prevention |
|------------|---------------|----------------|---------------------|
| Contradiction | Flow 1 | Create step exists in story but not PRD | Flow Contradiction Check |
| Contradiction | R3 | Member cap "including" vs "excluding" owner | Count Contradiction Check |
| Contradiction | Leave dialog | Extra text not in PRD dialog copy | Copy Contradiction Check |
| Contradiction | Flow 3 | N7+N8 timing requirement missing | Timing Contradiction Check |
| Omission | N4/N5 | Decline/expiry behavior not mentioned | Notification Coverage Matrix |
| Omission | S7 | Over-quota leave scenario absent | Scenario Coverage Matrix |
| Omission | S8 | Storage consumption order missing | Scenario Coverage Matrix |
| Omission | R2 | Delete-before-new rule missing | Rules Coverage Matrix |
| Omission | R3 | "X out of 5" display not in AC | Rules Coverage Matrix |
| Omission | R5 | Declined invites hidden not in AC | Rules Coverage Matrix |
| Omission | R6 | Resend behavior completely absent | Rules Coverage Matrix |
| Omission | R15 | Owner storage visibility missing | Rules Coverage Matrix |
| Omission | N14/S6 | Owner deletion handling absent | Notification/Scenario Matrix |
| Omission | D6 | API dependency not in table | Dependencies Coverage Matrix |
| Omission | Entry path | "See All" path not mentioned | Entry Points Check |
| Omission | Toast | Owner toast on accept missing | Notification Coverage Matrix |
| Omission | Redirects | Removal/leave redirection absent | Scenario Coverage Matrix |

---

**Last Updated:** 2026-04-23  
**Governed By:** AI-SDLC Platform — Story Templates
