---
name: sprint-story-generator
description: Generate Sprint Stories from Master Story + sprint scope — ADO-ready PRD lift, UI/Figma, non-redundant sections
model: sonnet-4-6
token_budget: {input: 6000, output: 4000}
---

> **Context:** Use **parent Master Story** + PRD section ids. Prefer `prd-gap-analyzer` if PRD quality is in question.
>
> **Authoring standards:** [templates/AUTHORING_STANDARDS.md](../../templates/AUTHORING_STANDARDS.md)

# Sprint Story Generator

## Role

Senior CSPO + Tech Lead: one sprint, one shippable slice. The **Sprint Story work item must stand alone** in Azure DevOps.

## Input

- Master Story (or link + id)
- Sprint id, capacity, scope boundaries
- Which Master ACs / capabilities are **in** vs **out** this sprint

## Non-negotiables

1. **📎 PRD / Master lift:** Include **full** user-visible strings for everything touched this sprint (notifications, errors, labels). If copy already lives on the Master work item, add one line pointing to Master + row id—**do not** rely on “see PRD” alone.
2. **No invention:** Missing PRD/design facts → `USER_INPUT_REQUIRED` per `STORY_TEMPLATE_REGISTRY.md`. **Do NOT** use `USER_INPUT_REQUIRED` for human role assignments (Assignee, QA, Designer) — use "*To be assigned*" or similar placeholder.
3. **No redundancy:** **Context** = why this sprint. **What we're building** = deliverable summary—**not** the same user journey twice. **How we'll measure** = sprint target vs Master metric—**not** the full Master analytics tables.
4. **🎨 UI & design:** Figma URL(s) for frames built this sprint, or **N/A** with one line (e.g. backend-only). **Only ONE UI & design section** — do not duplicate at the end.
5. **Product vs Technical:** Sprint Stories are **product-focused** (WHAT). **No Technical Approach section** — architecture/tech choices belong in a **Tech Story** (`tech-story-template.md`).
6. **Traceability:** Scope table must explicitly map to **Master Story AC numbers** (e.g., "Master AC #1, #3"), not just PRD sections.
7. **Readable:** Short sentences, **bold** labels, bullets, tables for copy.
8. **No emojis:** Do not use emojis in story content. ADO HTML fields do not render them consistently. Use plain text only.
9. **ADO limit:** System.Description has 32,000 character limit. Create condensed version + attach full `.md` file for large stories. See `rules/ado-html-formatting.md`.
10. **No CLI sections:** Do not include `## Azure DevOps` with push commands in story files.
11. **HTML formatting:** When pushing to ADO, convert markdown to HTML with proper styling.
12. **PRD Coverage Inheritance:** Cross-check that all PRD artifacts (N#/R#/S#/D#/E#) in this sprint's scope are covered. Verify against Master Story's PRD Coverage Matrix.

## Quality Checklist for Sprint Stories

Before handoff, verify:
- [ ] Scope table maps to specific Master Story AC numbers
- [ ] All notifications/errors for this sprint's scope have full text in PRD/Master lift
- [ ] If Master has N4/N5 decline/expiry behavior, Sprint inherits it if in scope
- [ ] If Master has timing requirements (e.g., N7+N8 within 60s), Sprint includes them
- [ ] If Master has entry points (+ and See All), Sprint covers both if in scope
- [ ] Traceability: Parent Master + specific AC numbers + PRD sections

## Output

Fill **`templates/story-templates/sprint-story-template.md`** completely. Key sections:

- Scope (IN/OUT) with explicit Master Story AC mapping
- **📎 PRD / Master lift (this sprint)**
- Acceptance criteria (checkboxes) — testable, atomic
- **🎨 UI & design**
- Dependencies, risks, DoD
- Traceability (parent Master + PRD ids + specific AC numbers)

**⚠️ DO NOT include:** Technical Approach section — that belongs in a **Tech Story** per AUTHORING_STANDARDS.md rule #3 (Product vs Technical separation).

## Command example

```yaml
Command: generate sprint story

MASTER_STORY: ONBOARD-AUTH
SPRINT: 12
SCOPE: "Phone entry + OTP happy path"
INCLUDE_ACS: AC-01, AC-02, AC-03
```

## See also

- **Master story:** `skills/shared/story-generator/`
- **Tasks:** `skills/shared/tech-task-generator/`
- **Validate:** `skills/shared/story-validator/`
<<<<<<< HEAD
=======

---

## MANDATORY: PRD Coverage Validation for Sprint Stories

**REQUIRED BEFORE PUSH TO ADO**

Sprint Stories inherit PRD coverage from Master Stories. Before pushing:

### Validation Checklist

| Check | Validation | Status |
|-------|------------|--------|
| **Parent Coverage** | Master Story has valid PRD Coverage Matrix | ⬜ |
| **N# Inherited** | All notifications in Sprint scope covered | ⬜ |
| **R# Inherited** | All rules in Sprint scope enforced | ⬜ |
| **No New Artifacts** | Sprint does NOT introduce new N/R/S/D/E | ⬜ |
| **Traceability** | Each AC references Master Story AC # | ⬜ |

### Validation Command (MANDATORY)

```bash
# Validate Sprint Story inherits PRD coverage correctly
python AI_SDLC_Platform/scripts/validate-before-create.py \
  stories/FH-001-S01-sprint.md \
  Sprint

# Only proceed if validation passes
# Then push with parent reference
sdlc story push stories/FH-001-S01-sprint.md --parent=<Feature-ID>
```

**FAILURE TO VALIDATE → ADO-865620-TYPE GAPS → REWORK REQUIRED**
>>>>>>> 5a6d807 (Final commit of AI-SDLC Platform)
