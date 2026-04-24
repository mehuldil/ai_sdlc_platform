# Authoring standards (all SDLC templates & skills)

**Applies to:** PRD, system design, Master / Sprint / Tech stories, tasks, test plans, ADRs, and agent-generated content that fills these templates.

---

## 1. Azure DevOps / work-item readiness

- Downstream readers (engineering, QA, TPM) should **not need to open the PRD** for **user-visible** facts: notification text, errors, labels, limits—when those facts exist in the PRD or parent story, they must be **lifted verbatim** (or referenced to a row that contains the full text on the same work item).
- **Do not** list PRD artifact ids (**Nx**, **§x.x**) **without** the corresponding text, unless a parent work item already contains that text and you add a **single** pointer line (Master/Sprint id + row).
- **UI:** Use template sections **🎨 UI & design** (stories) or **§9 Design / Figma** (PRD) for Figma links and status—not for repeating business outcomes.
- **PRD Coverage Matrix:** Master Stories must include a coverage table mapping all PRD artifacts (N#/R#/S#/D#/E#) to ACs. See `story-templates/PRD_COVERAGE_CHECKLIST.md`.

---

## 1b. Contradiction Prevention (ADO-865620 Lessons)

Before finalizing a story, verify these common contradiction patterns:

### Flow Contradictions
| ❌ Wrong | ✅ Correct | Check |
|----------|------------|-------|
| "User taps Create, confirms creation" | "Hub auto-created on first invite" | Match PRD Flow X exactly |
| "Step 1: Create, Step 2: Invite" | "No separate Create step" | Check for Sprint decisions |

### Count/Limit Contradictions
| ❌ Wrong | ✅ Correct | Check |
|----------|------------|-------|
| "Max 5 including owner" (5 total) | "Max 5 excluding owner" (6 total) | Verify "including" vs "excluding" |
| "Unlimited invites" | "5 pending max" | Check R# rules |

### Copy Contradictions
| ❌ Wrong | ✅ Correct | Check |
|----------|------------|-------|
| "Leave Hub? Your library is unaffected." | "Leave Hub?" | Dialog ≠ Scenario description |
| Toast has extra context | Toast matches PRD verbatim | Copy must be verbatim |

### Timing/SLA Contradictions
| ❌ Wrong | ✅ Correct | Check |
|----------|------------|-------|
| "N7 + N8 sent on removal" | "N7 + N8 sent within 60s" | Capture SLA requirements |
| "Notifications sent" | "Notifications sent within X seconds" | Check for timing specs |

### Visibility Contradictions
| ❌ Wrong | ✅ Correct | Check |
|----------|------------|-------|
| "All statuses shown" | "Declined invites NOT shown" (R5) | Match PRD visibility rules |
| "Owner sees everything" | "Owner sees X, not Y" per R# | Check R# rules |

**Validation:** Run `prd-coverage-validator.sh` before ADO push to catch these.

---

## 2. No invention; use `USER_INPUT_REQUIRED`

- If a required fact is missing from PRD, design, or parent story, **do not** fabricate prose to “complete” the template.
- Use the `USER_INPUT_REQUIRED` pattern in [story-templates/STORY_TEMPLATE_REGISTRY.md](story-templates/STORY_TEMPLATE_REGISTRY.md) (Missing source material).

---

## 3. Non-redundancy

- Each section has **one job**. Do **not** paste the same paragraph into Outcome, Problem, Context, and Solution (stories), or duplicate full KPI tables across Measurement and Validation plan.
- **Product vs technical:** Master/Sprint carry product acceptance; **Tech Story** carries implementation SSoT grounded in **system design** + stories; **Tasks** stay atomic and link upward.

---

## 4. Grounded technical work

- **System design §0** and **Tech Story** baseline describe **what exists today** and **what must not break** (invariants, regression strategy).
- Tasks cite **repo anchors** and **regression** checks aligned with Tech/Sprint story—not greenfield guesses.

---

## 5. Traceability chain

**PRD (section ids) → Master Story → Sprint Story → Tech Story (if used) → Task → AB# / PR**

Every artifact lists parent ids/links appropriate to its tier (see each template’s **Traceability** section).

---

## 6. Readability

- Short sentences. **Bold** labels. Bullets. Blank lines between items. Tables for structured content (notifications, APIs, impact).

---

## 7. Template map

| Artifact | Canonical template |
|----------|-------------------|
| PRD | `prd-template.md` |
| System design | `design-doc-template.md` |
| Master story | `story-templates/master-story-template.md` |
| Sprint story | `story-templates/sprint-story-template.md` |
| Tech story | `story-templates/tech-story-template.md` |
| Task | `story-templates/task-template.md` |
| Test plan | `test-plan-template.md` |
| ADR | `adr-template.md` |

**Deprecated (do not use for new work):** `templates/DEPRECATED/*user-story*`, old `tech-task-template.md`—use **story-templates/** tier instead.

---

## 8. Validators & CLI

- Story-tier validators: `story-templates/validators/*.sh`
- `sdlc story validate <file.md>` runs the matching validator by tier.
- **PRD Coverage Validator:** `prd-coverage-validator.sh <story.md> [prd.docx]` — Checks all N#/R#/S#/D#/E# are covered, catches ADO-865620-type gaps.

**Pre-Push Validation Sequence:**
```bash
# 1. Structure validation
sdlc story validate stories/MS-xxx.md

# 2. PRD coverage validation (prevents ADO-865620 feedback)
./templates/story-templates/validators/prd-coverage-validator.sh \
  stories/MS-xxx.md \
  docs/prd/YourPRD.docx

# 3. ADO push
sdlc story push stories/MS-xxx.md --type=feature
```
