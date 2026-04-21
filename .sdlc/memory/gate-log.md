# Gate Validation Log

**Purpose:** Track all gate checks, results, and user decisions for audit trail and compliance.

**Policy:** All gates are ADVISORY (non-blocking). This log documents what was checked, findings, and whether user accepted or mitigated risks.

---

## Gate Validation Results

| Date | Gate | Story ID | Result | Criteria Met | Issues Found | User Decision | Actor | Notes |
|------|------|----------|--------|-------------|--------------|---------------|-------|-------|
| 2026-04-13 | G4 | AB#2001 | ADVISORY | ADR ✓, API ~, DB ✓, NFR ✓ | API spec not committed | Proceed (merge will validate) | mehul.dedhia@ril.com | ADR in Draft, user accepted risk |
| | | | | | | | | |

---

## Gate Definitions

### G1 — PRD Review
- **Checked By:** Product Lead
- **Criteria:** PRD sections complete, open questions resolved, clarity on scope
- **Async:** Check PRD-{story}.md for: Objectives, Requirements, Success Criteria, Acceptance Criteria
- **Action:** ADVISORY — document findings, user decides to proceed/fix/skip

### G2 — Pre-grooming
- **Checked By:** Engineering Lead
- **Criteria:** Pre-grooming checklist items ready
- **Action:** ADVISORY — user can skip pre-grooming or address later

### G3 — Grooming
- **Checked By:** Grooming Lead
- **Criteria:** Acceptance Criteria present, scope clear, estimate exists
- **Action:** ADVISORY — document gaps, user proceeds at own risk

### G4 — Tech Design
- **Checked By:** Architect / Tech Lead
- **Criteria:**
  - ADR exists and is Accepted
  - API contracts (OpenAPI/GraphQL/Protobuf) committed
  - Database migrations linked (if applicable)
  - NFRs quantified (numeric targets, not adjectives)
- **Action:** ADVISORY — log to ADO comment, user can proceed with draft ADR

### G5 — Sprint Ready
- **Checked By:** Product Owner
- **Criteria:** Dependencies identified, blockers flagged
- **Action:** ADVISORY — document blockers, user proceeds with awareness

### G6 — Dev Complete
- **Checked By:** Dev Lead / Author
- **Criteria:** Code merged, test coverage >= 70%, PR reviewed
- **Action:** ADVISORY — log test coverage, user can merge with gaps

### G7 — SIT (System Integration Testing)
- **Checked By:** QA Lead
- **Criteria:** SIT execution status, defect count, pass/fail rate
- **Action:** ADVISORY — document defect status, user can proceed to PP

### G8 — Pre-Prod (PP)
- **Checked By:** DevOps Lead
- **Criteria:** PP deployment successful, performance baseline established
- **Action:** ADVISORY — document baseline, user can promote to Prod

### G9 — Performance
- **Checked By:** Performance Team
- **Criteria:** Perf test results vs targets (p95, error rate, throughput)
- **Action:** ADVISORY — log results, user can accept or optimize

### G10 — Release
- **Checked By:** Release Manager
- **Criteria:** Compliance scans passed, changelog complete, rollback plan documented
- **Action:** ADVISORY — document compliance status, user can release

---

## Decision Codes

| Code | Meaning | Example |
|------|---------|---------|
| `PASS` | Gate criteria fully met | ADR Accepted, API committed, all OK |
| `WARN` | Gate criteria partially met or at risk | ADR in Draft but ADR exists; API pending |
| `SKIP` | User chose to skip gate (noted for audit) | User proceeded without pre-grooming |
| `PROCEED` | User proceeded with known gaps | "Merge with draft ADR, will finalize in PR review" |
| `FIXED` | User addressed gaps and re-ran gate | ADR now Accepted after tech review |
| `ESCALATED` | Gate escalated to stakeholder for decision | Release gate blocked, escalated to Release Manager |

---

## User Actions (Always Available)

At any gate, user has these options:

1. **Proceed** — Accept current state and continue (noted in log)
2. **Fix** — Address gaps and re-run gate check
3. **Skip** — Bypass gate, continue with risk noted
4. **Pause** — Stop and work on gate items before proceeding

**Example Log Entry:**
```
| 2026-04-13 | G4 | AB#2001 | ADVISORY | ADR ✓, API ~, DB ✓ | API not committed | Proceed (will add in PR) | user@ril.com | ADR Draft acceptable |
```

---

## Automated vs Manual Gates

### Automated Gates (checked by sdlc)
- G4 (ADR, API, DB, NFR checks)
- G6 (test coverage scan)

### Manual Gates (checked by team in chat/IDE)
- G1 (PRD review — requires human judgment)
- G2 (pre-grooming — human assessment)
- G3 (grooming — team discussion)
- G5 (sprint readiness — depends on planning)
- G7 (SIT results — QA judgment)
- G8 (PP deployment — DevOps assessment)
- G9 (performance — performance team review)
- G10 (release readiness — release manager decision)

---

## Audit Trail

Every gate check is logged here to ensure:
- ✅ Full visibility into what was checked
- ✅ User decisions are documented
- ✅ Risks are explicitly accepted
- ✅ No silent failures or skips
- ✅ Compliance records for release

See: `rules/gate-enforcement.md`, `ENFORCEMENT-POLICY.md`
