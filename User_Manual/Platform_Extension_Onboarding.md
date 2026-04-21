# Platform extension onboarding — agents, rules, skills, roles, stacks, stages

Use this checklist when you **add or change** platform behavior so CLI, IDE, NL, and CI stay aligned. Repository layout: [`CANONICAL_REPO_AND_INTERFACES`](CANONICAL_REPO_AND_INTERFACES.md).

## Quick reference

| You add… | Primary locations | Must update / run |
|----------|-------------------|-------------------|
| **Agent** | `agents/<domain>/*.md`, [`agents/agent-registry.json`](../agents/agent-registry.json) | Registries; optional: [`agents/CAPABILITY_MATRIX.md`](../agents/CAPABILITY_MATRIX.md) via script |
| **Rule** | [`rules/<name>.md`](../rules/) | Cursor: re-run project `setup` / `sdlc-setup` so `.cursor/rules/rule-*` symlinks exist; Claude Code: update condensed copies under [`.claude/rules/`](../.claude/rules/) if you maintain IDE-specific shortenings |
| **Skill** | `skills/<area>/<skill-name>/SKILL.md` | [`skills/SKILL.md`](../skills/SKILL.md) via regen script; reference from agents/commands as needed |
| **Role (“team”)** | [`cli/lib/config.sh`](../cli/lib/config.sh) (`ROLES`), [`cli/sdlc-setup.sh`](../cli/sdlc-setup.sh) interactive lists | [`roles/`](../roles/) markdown if role docs exist; User Manual tables ([`Role_and_Stage_Playbook`](Role_and_Stage_Playbook.md)) |
| **Tech stack** | `config.sh` (`STACKS`, `STACK_VARIANT_MAP`) | For **each** stage that uses variants: `stages/<stage>/variants/<mapped-name>.md` (see below) |
| **Stage / SDLC flow** | `stages/<NN-name>/STAGE.md`, [`cli/lib/config.sh`](../cli/lib/config.sh) (`STAGES`) | [`workflows/*.yml`](../workflows/) that include the stage; slash commands under [`.claude/commands/`](../.claude/commands/); [`User_Manual/SDLC_Flows`](SDLC_Flows.md) |

After edits, run from the repository root:

```bash
bash scripts/regenerate-registries.sh --update
bash scripts/validate-system-change.sh .
bash scripts/ci-sdlc-platform.sh --quick    # or full CI without --quick
node User_Manual/build-manual-html.mjs      # if User_Manual changed
```

---

## 1. Add an agent

1. **Create** `agents/<shared|backend|frontend|qa|performance|product|boss>/<agent-name>.md` (YAML frontmatter: `name`, `description`, `model`, `token_budget` as used elsewhere).
2. **Register** in [`agents/agent-registry.json`](../agents/agent-registry.json) (tier, path, tags, `accepts_roles`, env).
3. **Governance:** Link [`rules/ask-first-protocol.md`](../rules/ask-first-protocol.md) (or equivalent ASK-first language) so `validate-rules.sh` and reviews stay consistent.
4. **Wire invocation:** From stages, roles, or `cli/` only if the CLI exposes `sdlc agent invoke` for this id — follow existing patterns in [`cli/lib/executor.sh`](../cli/lib/executor.sh) and docs.
5. **Regenerate** [`agents/CAPABILITY_MATRIX.md`](../agents/CAPABILITY_MATRIX.md): `bash scripts/regenerate-registries.sh --update`.

**Thin agent pattern:** Prefer delegating heavy work to **skills** (see [Agents_Skills_Rules](Agents_Skills_Rules.md)).

---

## 2. Add a rule

1. **Create** [`rules/<rule-name>.md`](../rules/) (single responsibility; add a row to [`rules/README.md`](../rules/README.md) index if useful).
2. **Cursor:** Project setup symlinks `rules/*.md` → `.cursor/rules/rule-*.md` — contributors should **re-run** [`setup.sh`](../setup.sh) or `sdlc-setup` for the **app repo** after pulling (not always needed if symlink target updated in place).
3. **Claude Code:** If you keep condensed rule files under [`.claude/rules/`](../.claude/rules/), add or sync the short form there and keep naming aligned with [`validate-rules.sh`](../scripts/validate-rules.sh) / `_rule_file_exists` behavior.
4. **Validate:** `bash scripts/validate-rules.sh .`

---

## 3. Add a skill

1. **Create** directory `skills/<domain>/<skill-id>/SKILL.md` (frontmatter `name`, `description`, `model`, `token_budget`).
2. **Reference** from agents (orchestration) and optionally stages — same patterns as existing skills.
3. **Regenerate** [`skills/SKILL.md`](../skills/SKILL.md): `bash scripts/regenerate-registries.sh --update`.
4. **Dedup:** Run merge-time duplication checks as documented in [Agents_Skills_Rules](Agents_Skills_Rules.md) (`hooks/pre-merge-duplication-check.sh` where applicable).

---

## 4. Add a role (“team”) — e.g. a new lane beside Product / QA / UI

**Note:** `ui` already exists in [`cli/lib/config.sh`](../cli/lib/config.sh) (`ROLES`). For a **new** role id:

1. **Append** the role id to the `ROLES=(...)` array in [`cli/lib/config.sh`](../cli/lib/config.sh) (and keep ordering consistent for UX).
2. **Interactive setup:** Update [`cli/sdlc-setup.sh`](../cli/sdlc-setup.sh) arrays `ROLES` and `ROLE_DESC` so `sdlc setup` prompts list the new role with a one-line description.
3. **Docs:** Update [`Role_and_Stage_Playbook`](Role_and_Stage_Playbook.md), [FAQ](FAQ.md) role lists if you mention supported roles, and token tables in [Agents_Skills_Rules](Agents_Skills_Rules.md) if the role gets a budget.
4. **Optional:** Add [`roles/<role>.md`](../roles/) if your repo uses per-role markdown.

`validate_role` in `config.sh` is the **single gate** for `sdlc use <role>`.

---

## 5. Add a tech stack (e.g. new mobile or backend flavor)

1. **Add** stack id to `STACKS=(...)` in [`cli/lib/config.sh`](../cli/lib/config.sh).
2. **Map** stack → variant filename: `STACK_VARIANT_MAP` must point to the **basename** of variant files (without `.md`).

   Resolver (see [`cli/lib/executor.sh`](../cli/lib/executor.sh)):  
   `stages/<stage>/variants/${STACK_VARIANT_MAP[$STACK]:-$STACK}.md`

3. **For each stage** that should differ by stack, add  
   `stages/<stage-id>/variants/<mapped-name>.md`  
   At minimum, maintain **08-implementation** variants; link [`stages/_includes/rpi-serialization-baseline.md`](../stages/_includes/rpi-serialization-baseline.md) per [stage variant validation](../scripts/validate-stage-variants.sh).
4. **Stacks config / doctor:** If [`scripts/verify-platform-registry.sh`](../scripts/verify-platform-registry.sh) or `sdlc doctor` references stack lists, update those scripts or docs.

---

## 6. Add or rename a stage / SDLC flow

Stages are **numbered directories** under [`stages/`](../stages/): `NN-short-name` with [`STAGE.md`](../stages/01-requirement-intake/STAGE.md) inside.

1. **Add folder** `stages/NN-<name>/STAGE.md` (follow existing YAML + structure).
2. **Register** stage id in `STAGES=(...)` in [`cli/lib/config.sh`](../cli/lib/config.sh) (exact directory name).
3. **Workflows:** Add or edit entries in [`workflows/*.yml`](../workflows/) (stage **names** in YAML are short names; the CLI maps them to `NN-name` directories — see comments in [`workflows/full-sdlc.yml`](../workflows/full-sdlc.yml)).
4. **Slash commands:** Add or update `.claude/commands` markdown if you expose a new `/project:*` (and rerun setup in consuming projects).
5. **User Manual:** [SDLC_Flows](SDLC_Flows.md), [Role_and_Stage_Playbook](Role_and_Stage_Playbook.md), [Happy_Path_End_to_End](Happy_Path_End_to_End.md) as appropriate.
6. **Hooks / memory / ADO:** Search for hardcoded stage lists (`workflow-state.md`, hooks, `ado.sh`) and extend if your automation references stage ids.

Renaming a stage is **high impact**: search the repo for the old folder name and old short name.

---

## 7. CI and manual

- **Registry drift:** `validate-system-change.sh` runs `regenerate-registries.sh --check`.
- **Stage 08 variants:** `validate-stage-variants.sh` enforces RPI links for `stages/08-implementation/variants/*.md`.
- **Offline manual:** After any `User_Manual/*.md` change, run `node User_Manual/build-manual-html.mjs` and commit [`manual.html`](manual.html).

---

## 8. Publishing a public distribution snapshot

When you maintain a **full** checkout and need a **separate** public tree (neutral clone URLs and curated overlays), use the scripts under [`scripts/mirror-public/`](../scripts/mirror-public/). See **[`scripts/mirror-public/README.md`](../scripts/mirror-public/README.md)** for the full publish workflow, dry-run, and environment variables.

**Overlay** files for public-facing wording live under **`scripts/mirror-public/overlays/`** in the **full** repository — edit those when the public tree should differ.

---

## 9. Full Example: Onboarding the Analytics Team

This walkthrough demonstrates onboarding a new **Analytics** team that requires:
- New role (`analytics`)
- New agent (`analytics-engineer`)
- Specialized skills for data validation and metrics tracking
- Rules that impact multiple stages (tracking, privacy, data quality gates)
- Integration points with existing Backend and Product teams

### Step 1: Define the Analytics Role

**File:** `roles/analytics.md`
```markdown
---
name: analytics
description: Data analysts and analytics engineers responsible for metrics tracking, data pipelines, and reporting infrastructure. Works across requirements, implementation, and release stages.
token_budget:
  daily: 5000
  sprint: 50000
---

# Analytics Role

## Responsibilities
- Define tracking requirements during PRD review
- Design and implement analytics events in Stage 08
- Validate data pipeline quality in Stage 10
- Ensure privacy compliance (GDPR, CCPA) across all stages
- Generate release metrics in Stage 14

## Constraints
- Cannot modify production data without QA approval
- Must include privacy review for any new data collection
- All tracking changes require product sign-off

## Cross-Team Impact
- **Product**: Defines tracking requirements; receives analytics reports
- **Backend**: Implements server-side tracking events
- **Frontend**: Implements client-side tracking events
- **QA**: Validates tracking correctness
```

**Update:** `cli/lib/config.sh`
```bash
# Add to ROLES array
ROLES=(product backend frontend qa performance ui tpm boss analytics)

# Add to ROLE_DESC in cli/sdlc-setup.sh
ROLE_DESC=(
  "Product management and requirements"
  "Backend development and APIs"
  "Frontend development and UI"
  "Quality assurance and testing"
  "Performance optimization"
  "UI/UX design"
  "Technical program management"
  "Executive oversight and approvals"
  "Analytics and data tracking"  # <-- NEW
)
```

---

### Step 2: Create the Analytics Agent

**File:** `agents/analytics/analytics-engineer.md`
```markdown
---
name: analytics-engineer
description: Analytics engineer specializing in event tracking, data pipelines, and metrics validation. Works closely with Product for requirements and Backend/Frontend for implementation.
model: composer-2-fast
token_budget: 5000
accepts_roles:
  - analytics
  - product  # Can assist product with tracking requirements
tags:
  - data-tracking
  - privacy
  - metrics
---

# Analytics Engineer Agent

## Core Skills
- `tracking-requirement-analyzer` — Extract tracking needs from PRDs
- `privacy-compliance-checker` — Validate GDPR/CCPA compliance
- `event-schema-validator` — Validate analytics event schemas
- `metrics-report-generator` — Generate sprint/release metrics

## Ask-First Protocol
This agent MUST ask before:
- Adding new data collection points
- Modifying existing event schemas
- Accessing user behavior data
- Deploying tracking changes to production

## Stage Integration
| Stage | Responsibility |
|-------|---------------|
| 02-prd-review | Identify tracking requirements in PRD |
| 05-system-design | Design data pipeline architecture |
| 08-implementation | Implement tracking events |
| 10-test-design | Validate tracking data quality |
| 14-release-signoff | Generate release metrics report |
```

**Update:** `agents/agent-registry.json`
```json
{
  "tier_2_domain": {
    "analytics": {
      "analytics-engineer": {
        "description": "Analytics engineer for tracking, data pipelines, and privacy compliance",
        "path": "agents/analytics/analytics-engineer.md",
        "skills": [
          "tracking-requirement-analyzer",
          "privacy-compliance-checker",
          "event-schema-validator",
          "metrics-report-generator"
        ],
        "stages": ["02-prd-review", "05-system-design", "08-implementation", "10-test-design", "14-release-signoff"]
      }
    }
  }
}
```

---

### Step 3: Create Analytics Skills

**Skill 1:** `skills/analytics/tracking-requirement-analyzer/SKILL.md`
```markdown
---
name: tracking-requirement-analyzer
description: Extract analytics tracking requirements from PRDs and user stories. Identifies what user actions need to be tracked, what properties to capture, and privacy implications.
model: composer-2-fast
token_budget: 3000
---

# Tracking Requirement Analyzer

## Purpose
Analyze PRDs and stories to identify:
1. User actions that need tracking
2. Event properties (who, what, when, where)
3. Privacy classification (PII, anonymous)
4. Backend vs Frontend tracking responsibility

## Output Template
```markdown
## Tracking Requirements for [Story ID]

### Events to Track
| Event Name | Trigger | Properties | Owner | Privacy Level |
|------------|---------|------------|-------|---------------|
| [event_name] | [when it fires] | [properties] | BE/FE | PII/Anonymous |

### Privacy Checklist
- [ ] No PII captured without explicit approval
- [ ] GDPR right-to-deletion considered
- [ ] Data retention period defined
- [ ] Opt-out mechanism documented

### Cross-Team Dependencies
- Backend: [server-side events]
- Frontend: [client-side events]
- QA: [validation strategy]
```

## Ask-First Triggers
- PRD contains user-facing features
- Story mentions "metrics", "tracking", "analytics"
- New data collection is proposed
```

**Skill 2:** `skills/analytics/privacy-compliance-checker/SKILL.md`
```markdown
---
name: privacy-compliance-checker
description: Validate GDPR, CCPA, and privacy compliance for data collection changes. Required before any tracking implementation.
model: composer-2-fast
token_budget: 2000
---

# Privacy Compliance Checker

## Purpose
Ensure all data collection follows privacy regulations.

## Compliance Checklist
### GDPR (EU)
- [ ] Lawful basis for processing documented
- [ ] Purpose limitation defined
- [ ] Data minimization (only necessary data)
- [ ] Retention period specified
- [ ] Right to deletion process exists
- [ ] Consent mechanism (if required)

### CCPA (California)
- [ ] Disclosure of what data is collected
- [ ] Opt-out mechanism available
- [ ] No sale of personal information

## Gate Behavior
- **BLOCK**: PII collection without privacy review
- **WARN**: New data types (requires documentation)
- **PASS**: Anonymous, existing patterns

## Output
Privacy report appended to `.sdlc/memory/privacy-reviews.md`
```

**Skill 3:** `skills/analytics/event-schema-validator/SKILL.md`
```markdown
---
name: event-schema-validator
description: Validate analytics event schemas against team conventions and platform requirements. Ensures consistency across all tracking events.
model: composer-2-fast
token_budget: 2000
---

# Event Schema Validator

## Schema Requirements
All events MUST include:
```json
{
  "event_name": "snake_case_string",
  "timestamp": "ISO8601",
  "user_id": "string (hashed)",
  "session_id": "string",
  "properties": {
    "feature": "string",
    "action": "string"
  },
  "context": {
    "app_version": "string",
    "platform": "string"
  }
}
```

## Validation Rules
- Event names: `snake_case`, max 40 chars
- Properties: camelCase, max 50 per event
- No raw PII in event names or property keys
- Sensitive data must be hashed

## Integration
- Runs in Stage 10 (Test Design)
- Validates against `memory/team/analytics/event-schemas.md`
- Reports issues to `.sdlc/memory/tracking-validation.md`
```

---

### Step 4: Create Cross-Cutting Rules

Analytics requires rules that impact **multiple stages**:

**Rule 1:** `rules/privacy-by-design.md` (impacts Stages 02, 05, 08)
```markdown
---
category: governance
severity: mandatory
stages: [02-prd-review, 05-system-design, 08-implementation]
---

# Privacy by Design

## Rule
All new data collection MUST pass privacy review **before** implementation.

## Stage-Specific Checks

### Stage 02: PRD Review
- Identify any new data collection in PRD
- Flag PII for privacy review
- Document data retention requirements

### Stage 05: System Design
- Design data pipeline with anonymization
- Plan consent/opt-out mechanisms
- Document data flow diagrams

### Stage 08: Implementation
- Implement hashing/encryption
- Add consent checks in code
- Log privacy decisions in `.sdlc/memory/privacy-log.md`

## Violation Handling
- **Pre-implementation**: Block until privacy review complete
- **Post-implementation**: Create tech debt ticket; schedule remediation
```

**Rule 2:** `rules/tracking-completeness.md` (impacts Stages 02, 08, 10)
```markdown
---
category: quality
severity: advisory
stages: [02-prd-review, 08-implementation, 10-test-design]
---

# Tracking Completeness

## Rule
All user-facing features MUST have tracking defined and validated.

## Checks
1. **Stage 02**: PRD includes "Analytics" section with tracking requirements
2. **Stage 08**: Implementation includes event firing code
3. **Stage 10**: Tests validate events are fired correctly

## Skip Conditions
- Backend-only API changes (no user action)
- Bug fixes without user flow changes
- Infrastructure changes (no behavioral impact)

## Gate Output
- List of features with/without tracking
- Coverage percentage
- Recommendations for missing tracking
```

**Rule 3:** `rules/data-quality-gates.md` (impacts Stages 10, 11)
```markdown
---
category: quality
severity: advisory
stages: [10-test-design, 11-test-execution]
---

# Data Quality Gates

## Rule
Analytics data quality must meet minimum thresholds before release.

## Quality Metrics
| Metric | Minimum | Target |
|--------|---------|--------|
| Event validation pass rate | 95% | 99% |
| Schema compliance | 100% | 100% |
| Privacy review completion | 100% | 100% |
| Test coverage (tracking) | 80% | 90% |

## Gate Behavior
- **FAIL**: Metrics below minimum → Block release
- **WARN**: Metrics below target → Advisory, document rationale
- **PASS**: All metrics at/above target → Proceed

## Auto-Remediation
- Invalid events: Log to `.sdlc/memory/data-quality-issues.md`
- Missing tests: Generate test stubs
- Schema drift: Suggest migration plan
```

**Update rules index:** Add to `rules/README.md`
```markdown
## Analytics Rules
- [privacy-by-design](privacy-by-design.md) — Mandatory privacy review across stages 02, 05, 08
- [tracking-completeness](tracking-completeness.md) — Ensure tracking defined for all features
- [data-quality-gates](data-quality-gates.md) — Quality thresholds for analytics data
```

---

### Step 5: Stage Integration Points

Analytics team needs to hook into existing stages. Here's how:

**Stage 02: PRD Review** (`stages/02-prd-review/STAGE.md`)
Add to the Stage file:
```markdown
## Analytics Integration
Before completing PRD review:
- [ ] Analytics section added to PRD (if user-facing)
- [ ] Tracking requirements documented
- [ ] Privacy implications reviewed
- [ ] Load `agents/analytics/analytics-engineer.md` if tracking required
```

**Stage 08: Implementation** (`stages/08-implementation/STAGE.md`)
```markdown
## Analytics Implementation
For features with tracking requirements:
- [ ] Implement client-side events (Frontend)
- [ ] Implement server-side events (Backend)
- [ ] Run `sdlc skills invoke privacy-compliance-checker`
- [ ] Run `sdlc skills invoke event-schema-validator`
- [ ] Log events to staging analytics platform
```

**Stage 10: Test Design** (`stages/10-test-design/STAGE.md`)
```markdown
## Analytics Testing
- [ ] Unit tests for event firing logic
- [ ] Integration tests for data pipeline
- [ ] Schema validation tests
- [ ] Privacy compliance tests (consent, opt-out)
- [ ] Run `sdlc skills invoke event-schema-validator`
```

**Create Stage Variants** (for analytics-heavy features):
```bash
# Create variant for analytics-intensive implementations
stages/08-implementation/variants/analytics-heavy.md
```

---

### Step 6: Team Memory Setup

Create team-specific memory for analytics knowledge:

```bash
# Create directory structure
mkdir -p memory/team/analytics/
touch memory/team/analytics/event-schemas.md
touch memory/team/analytics/privacy-decisions.md
touch memory/team/analytics/tracking-patterns.md
touch memory/team/analytics/metrics-baselines.md
```

**File:** `memory/team/analytics/README.md`
```markdown
# Analytics Team Memory

## Event Schema Registry
See [event-schemas.md](event-schemas.md) — canonical event definitions

## Privacy Decisions Log
See [privacy-decisions.md](privacy-decisions.md) — ADR-style privacy decisions

## Tracking Patterns
See [tracking-patterns.md](tracking-patterns.md) — Reusable tracking patterns

## Metrics Baselines
See [metrics-baselines.md](metrics-baselines.md) — Historical performance baselines

## Team Integration
- **Product**: Define requirements together in Stage 02
- **Backend**: Coordinate server-side events in Stage 08
- **Frontend**: Coordinate client-side events in Stage 08
- **QA**: Joint validation in Stage 10-11
```

---

### Step 7: Cross-Team Workflow Example

Here's how Analytics integrates with the full SDLC:

**Scenario**: New "Family Hub" feature needs click tracking

```
Stage 02: PRD Review
├── Product creates PRD with user stories
├── Analytics Agent analyzes PRD → extracts tracking requirements
├── Output: analytics-requirements-FH-001.md
└── Gate: Privacy review flagged for new data collection

Stage 05: System Design
├── Backend designs API contract
├── Frontend designs UI components
├── Analytics designs data pipeline (where events flow)
├── Privacy review (privacy-by-design rule)
└── Output: system-design-FH-001.md with analytics section

Stage 08: Implementation
├── Frontend implements UI + tracking events
├── Backend implements API + server-side events
├── Analytics validates events with schema-validator skill
├── Privacy compliance checker runs automatically
└── Memory: .sdlc/memory/tracking-validation.md

Stage 10: Test Design
├── QA designs functional tests
├── Analytics designs tracking validation tests
├── event-schema-validator validates all events
└── Gate: data-quality-gates rule checks metrics

Stage 14: Release Signoff
├── Analytics generates release metrics report
├── Compare against metrics-baselines.md
└── Memory: .sdlc/memory/release-metrics-FH-001.md
```

---

### Step 8: Validation & Testing

After implementing analytics onboarding:

```bash
# 1. Regenerate all registries
bash scripts/regenerate-registries.sh --update

# 2. Validate the changes
bash scripts/validate-system-change.sh .

# 3. Test the new role works
sdlc use analytics
sdlc context  # Should show: Role: analytics

# 4. Test new skills
sdlc skills show tracking-requirement-analyzer

# 5. Validate rules
bash scripts/validate-rules.sh .

# 6. Run CI check
bash scripts/ci-sdlc-platform.sh --quick

# 7. Update offline manual
node User_Manual/build-manual-html.mjs
```

---

### Step 9: Documentation Updates

Update these files to include Analytics:

| File | Update |
|------|--------|
| `README.md` | Add analytics to role badges (8 roles → 9 roles) |
| `User_Manual/Role_and_Stage_Playbook.md` | Add analytics row to role table |
| `User_Manual/Agents_Skills_Rules.md` | List analytics agent and skills |
| `User_Manual/FAQ.md` | Add "How do I onboard a new team?" |
| `rules/README.md` | Add analytics rules to index |
| `skills/SKILL.md` | Regenerated via script |
| `agents/CAPABILITY_MATRIX.md` | Regenerated via script |

---

### Summary: Analytics Onboarding Checklist

| Step | Task | File/Location | Status |
|------|------|---------------|--------|
| 1 | Define role | `roles/analytics.md` | ☐ |
| 2 | Add to config | `cli/lib/config.sh` | ☐ |
| 3 | Create agent | `agents/analytics/analytics-engineer.md` | ☐ |
| 4 | Register agent | `agents/agent-registry.json` | ☐ |
| 5 | Create skills | `skills/analytics/*/` | ☐ |
| 6 | Create rules | `rules/privacy-by-design.md`, etc. | ☐ |
| 7 | Update stages | `stages/*/STAGE.md` | ☐ |
| 8 | Create variants | `stages/*/variants/` (if needed) | ☐ |
| 9 | Setup memory | `memory/team/analytics/` | ☐ |
| 10 | Regenerate | `bash scripts/regenerate-registries.sh --update` | ☐ |
| 11 | Validate | `bash scripts/validate-system-change.sh .` | ☐ |
| 12 | Update docs | User Manual files | ☐ |
| 13 | Build manual | `node User_Manual/build-manual-html.mjs` | ☐ |

---

## See also

- [Architecture](Architecture.md) — components and extension points  
- [Agents_Skills_Rules](Agents_Skills_Rules.md) — deeper hierarchy  
- [Documentation_Rules](Documentation_Rules.md) — when to refresh which doc  
- [Commands](Commands.md) — CI parity commands  
- [extension-templates/NEW-ROLE.md](../extension-templates/NEW-ROLE.md) — role template  
