# Tech Task (v1.0)

A Tech Task is a granular, implementable unit of work that enables a Sprint User Story. Tech Tasks can be Backend, Frontend, Data, DevOps, or QA focused. One Sprint Story often spawns 3-5 Tech Tasks that can be worked on in parallel.

**For detailed examples and guardrails, see `templates/examples/tech-task-examples.md`**

---

## §1 Task Metadata

```yaml
Task ID: [SPRINT_STORY_ID]-[BE|FE|DATA|DEVOPS|QA]-[SEQ]
# e.g., US-1234-01-FE-01 (Frontend task 1 for sprint story US-1234-01)
Title: [Concise, implementation-focused title]
Parent Sprint Story: US-[XXXX]-[SEQ]
Type: Backend | Frontend | Data | DevOps | QA
Platform: [Web | iOS | Android | Backend]
Priority: P0 | P1 | P2 | P3
Story Points: [1-5 typical for tech task]
Sprint: [Sprint Name]
Assignee: [Engineer Name]
Status: New | Ready | In Progress | In Review | Done
Created: [YYYY-MM-DD]
Last Updated: [YYYY-MM-DD]
```

---

## §2 Objective

### Enables
What Sprint Story capability does this task unlock?

**Story Capability**: [e.g., "User Can: View personalized recommendations on homepage"]  
**Why It Matters**: [e.g., "Without this carousel, users cannot see recommendations. This is the UI that makes the feature visible."]

### Delivers
What specific code/artifact is produced?

**Deliverable**: [e.g., "React Carousel.tsx component that fetches and displays 10 recommendations from ML API. Fully responsive, accessible, tested."]  
**Success Definition**: [e.g., "Component renders without errors, fetches recommendations in <500ms, passes accessibility audit."]

---

## §3 Technical Scope

### In Scope
What will this task deliver (checklist format):

**Type: Frontend** or **Type: Backend** or **Type: Data** etc.  
Specify concrete deliverables as a checkbox list.

### Out of Scope
What's NOT included:

List items that could be mistaken as part of this task but are separate work.

---

## §4 API Contract (Backend Only)

If this is a Backend task, define the API contract:

### Endpoint
```
Method: [GET|POST|PUT|DELETE]
Path: [/api/v1/resource]
Host: [api.example.com]
Base URL: [https://api.example.com/api/v1]
```

### Request
**Query Parameters / Body Fields**: Define interface or schema  
**Headers**: Authorization, content-type, etc.

### Response
**Success (2xx)**: JSON structure  
**Error (4xx/5xx)**: Error format with error codes

### Error Codes
| Status | Code | Message | Cause | Client Action |
|--------|------|---------|-------|---------------|
| ... | ... | ... | ... | ... |

---

## §5 Screen / Component Spec (Frontend Only)

If this is a Frontend task, define the UI component:

### Component Tree
Hierarchical structure of components/elements

### Props / Interface
TypeScript interface defining props, state, events

### Responsive Breakpoints
| Device | Width | Behavior | Spacing |
|--------|-------|----------|---------|
| Mobile | ... | ... | ... |
| Desktop | ... | ... | ... |

---

## §6 Data Model (Backend Only)

If this task involves database changes:

### Schema
SQL table definitions or NoSQL schema

### Migrations
DDL migration scripts

### Data Access Layer
Code patterns for fetching/storing data

---

## §7 Dependencies

### Upstream
What must be done before starting this task:

| Dependency | Type | Status | Owner | Critical? |
|-----------|------|--------|-------|-----------|
| [Describe] | [Design/Technical/Other] | [Done/In Progress/Not Started] | [Owner] | [YES/NO] |

**Blocking Issues**: List any blockers or "None"

### Downstream
What tasks depend on this one:

| Task | Depends On | Impact | Mitigation |
|------|-----------|--------|-----------|
| [Describe] | [This task] | [Impact] | [Mitigation] |

**Parallelization Strategy**: What can run in parallel with this task?

---

## §8 Localization (Frontend Only)

If this task has user-facing copy:

### Strings to Localize
| Key | English | [Language] | Notes |
|-----|---------|----------|-------|
| key_1 | "Text" | "Translation" | Context |

### Implementation
Code pattern for loading localized strings (i18next, etc.)

### Notes
- Translators to review — Mark for review once component shipped
- Regional variations needed?
- RTL language support?

---

## §9 Accessibility (Frontend Only)

If this task creates UI, it must be accessible:

### WCAG 2.1 AA Compliance
- Color contrast requirements (4.5:1 normal, 3:1 large)
- Keyboard navigation (Tab, Arrow keys, Enter, Escape)
- Screen reader support (ARIA roles, labels)
- Focus indicators
- Dark mode support

### Implementation Checklist
- [ ] Focus indicators visible and logical
- [ ] Color not only means of communication
- [ ] Images have alt text
- [ ] Keyboard-only navigation works
- [ ] Dark mode contrast verified
- [ ] Reduced motion respected
- [ ] Axe DevTools audit ≥90 score
- [ ] Lighthouse accessibility ≥90 score

---

## §10 Technical Acceptance Criteria (Gherkin)

Test scenarios that verify implementation (BDD format):

```gherkin
Feature: [Feature Name]

  Scenario: [Scenario description]
    Given [precondition]
    When [action]
    Then [expected result]
```

Provide 5-10 key scenarios covering happy path, edge cases, and error handling.

---

## §11 Testing Requirements

### Unit Tests
- Describe test framework and patterns
- Specify minimum coverage (≥70% typical)
- Example test cases

### Integration Tests
- End-to-end test scenarios
- External service mocking strategy

### Performance Tests
- Load/stress test approach
- Performance targets (latency, throughput)

### UI / Snapshot Tests
- Visual regression testing approach

---

## §12 Observability

### Logging
- Structured logging format
- Log levels and examples
- Error tracking integration (Sentry, etc.)

### Metrics
Key metrics to track:
- Counter metrics (requests, errors)
- Histogram metrics (latency, duration)
- Gauge metrics (active connections, queue size)

### Alerts
Alert thresholds and escalation procedures for critical failures

---

## §13 Analytics Integration (Frontend Only)

If this task includes user-facing features, log analytics events:

Track events:
- User interactions (clicks, views, submissions)
- Error conditions
- Performance milestones

Include user_id, timestamp, relevant context in each event.

---

## §14 Implementation Notes

### Architecture Decisions
Document major technology/pattern choices and rationale

### Code Patterns (Guardrails)
- Language/framework conventions
- Error handling patterns
- Testing requirements
- Code review criteria

### Performance Optimization
- Caching strategy
- Database query optimization
- Network request batching
- Code splitting / lazy loading

### Testing Strategy
- Unit test approach
- Integration test approach
- Manual QA focus areas

### Potential Pitfalls
Document known gotchas and solutions

---

## §15 Definition of Done

Before this tech task can be marked complete:

### Code Quality
- [ ] Code merged to main/develop branch
- [ ] All review feedback addressed (≥2 approvals)
- [ ] Linting passed
- [ ] Type checking passed (TypeScript / strict mode)
- [ ] No console warnings/errors on build
- [ ] No temporary debugging code left

### Testing
- [ ] Unit tests written (≥70% code coverage)
- [ ] Tests passing locally + in CI/CD
- [ ] Acceptance criteria tested manually
- [ ] Edge cases tested
- [ ] Cross-browser/platform tested
- [ ] Accessibility tested

### Documentation
- [ ] Code comments for complex logic
- [ ] API contract documented (if backend)
- [ ] Component props documented (if frontend)
- [ ] Known limitations noted
- [ ] Runbook written: "How to debug [feature]"

### Performance
- [ ] Lighthouse score ≥85 (mobile) or ≥90 (desktop)
- [ ] API response time <200ms P95
- [ ] Component render time <100ms
- [ ] Bundle size impact <50KB gzipped

### Deployment
- [ ] Merged to release branch
- [ ] Deployed to staging environment
- [ ] Smoke tested in staging
- [ ] Feature flag configured
- [ ] Ready for code freeze

### QA Sign-off
- [ ] QA tested and approved
- [ ] Manual test cases documented
- [ ] No open bugs
- [ ] Ready for production

---

## Comments & Collaboration

[Task updates, blockers, code review feedback logged here]

---

**Created**: [YYYY-MM-DD]  
**Last Updated**: [YYYY-MM-DD]  
**Status**: [New | Ready | In Progress | In Review | Done]  
**Assignee**: [Engineer Name]  
**Reviewer**: [Reviewer Name(s)]  

---

**Last Updated**: 2026-04-11  
**Governed By**: AI-SDLC Platform
