# Rule: ADO HTML Formatting for Work Items

## Purpose

Ensure work items pushed to Azure DevOps have properly formatted HTML descriptions that render correctly in the ADO UI and stay within field limits.

---

## Rule: Description Length Limit

**ADO System.Description field limit: 32,000 characters**

### Options for Large Stories:

1. **Condensed Version + Attachment (Recommended)**
   - Create condensed version with critical sections only
   - Keep full story in local workspace
   - Attach full `.md` file to ADO work item
   - Condensed should include:
     - Outcome
     - Core Capabilities
     - PRD-sourced specifics (notifications, errors, limits) - all verbatim
     - Acceptance Criteria
     - Dependencies
     - Key Risks

2. **Split Into Multiple Work Items**
   - Feature: Core content
   - Tasks: Additional sections (Risks, Dependencies, Non-Goals)

### What Must Stay in ADO Description:

Per AUTHORING_STANDARDS.md Section 1:
- ✅ PRD-sourced specifics (notifications, errors, field labels, limits) - verbatim
- ✅ Acceptance Criteria (testable Given/When/Then)
- ✅ Core Capabilities
- ✅ Dependencies (blockers)

### What Can Be Attached:

- Related Stories
- Detailed Notes
- Complete Risk analysis
- Validation Plan details
- Full PRD Traceability table

---

## Rule: HTML Formatting Requirements

### Required HTML Structure:

```html
<div style="font-family:Segoe UI,sans-serif;font-size:14px;line-height:1.6;">
  <!-- Content here -->
</div>
```

### Required Elements:

| Element | Required | Format |
|---------|----------|--------|
| **Headers** | Yes | `<h1>`, `<h2>` with styling |
| **Tables** | For structured data | `<table>` with border-collapse, padding |
| **Lists** | Yes | `<ul>`, `<ol>` with `<li>` items |
| **Bold text** | Yes | `<strong>` for labels |
| **Code** | If needed | `<code>` for field names, IDs |
| **Horizontal rules** | Optional | `<hr>` between sections |

### Forbidden:

- ❌ Raw markdown in ADO description
- ❌ Emojis (use text only)
- ❌ Unescaped `<`, `>`, `&` characters
- ❌ `<pre>` blocks for entire content

---

## Rule: Emoji Usage

**DO NOT use emojis in ADO work items.**

### Why:

1. ADO HTML fields may not render emojis consistently
2. Some emojis convert to HTML entities (e.g., `&#129504;`) which are unreadable
3. Cross-platform compatibility issues
4. Professional appearance

### Replacement:

| Instead of | Use |
|------------|-----|
| 🧠 Master Story | Master Story |
| 🎯 Outcome | Outcome |
| 🔍 Problem | Problem Definition |
| ⚡ JTBD | Job To Be Done |
| 💡 Solution | Solution Hypothesis |
| 🧩 Capabilities | Capabilities |
| 🎨 UI & Design | UI & Design |
| ✅ Included | Included |
| ❌ Excluded | Excluded |
| ⚠️ Risks | Risks & Unknowns |
| 📝 Notes | Notes |
| 📋 Metadata | Story Metadata |
| 🚫 Non-Goals | Explicit Non-Goals |
| 🏆 Related | Related Stories |
| 📊 Measurement | Measurement & Signals |
| 🧪 Validation | Validation Plan |
| 🔗 Dependencies | Dependencies |

---

## Rule: Content Organization

### ADO-Ready Structure (Condensed Version):

```markdown
# [Story Title]

> PRD Source: [filename]
> Full Details: See attached [filename.md]

---

## Outcome
- User Outcome: [text]
- Business Impact: [text]
- Success Metric: [text]

## Core Capabilities
1. [Capability 1]
2. [Capability 2]
...

## PRD-Sourced Specifics

### Notifications
| ID | Message | Channel | Trigger |
|----|---------|---------|---------|
| N1 | "..." | SMS | Immediate |
...

### Errors
| ID | Message | When Shown |
|----|-----------|------------|
| E1 | "..." | [condition] |
...

### Config Limits
| Field | Value |
|-------|-------|
| ... | ... |

## Acceptance Criteria

### Flow 1: [Name]
1. **Given** [context], **When** [action], **Then** [result]
2. ...

### Flow 2: [Name]
...

## Dependencies
| Dependency | Team | Status |
|------------|------|--------|
| ... | ... | ... |

## Key Risks
- **Risk:** [description]
...

---

**Full story attached: [filename.md]**
```

---

## Rule: Organization-Specific Data

**Never commit work items with actual ADO IDs to general platform repository.**

### What is Organization-Specific:

- Actual ADO work item IDs (e.g., 865620, 865621)
- Organization emails (e.g., mehul.dedhia@ril.com)
- Custom field references (e.g., Jio.Common.AnalyticsFunnel)
- Team/POD names specific to organization
- Project-specific URLs

### Where to Store:

| Type | Location |
|------|----------|
| Templates with `USER_INPUT_REQUIRED` | AI-SDLC Platform repo (public) |
| Actual work items with ADO IDs | Local workspace only OR org-specific private repo |
| Push scripts with credentials | Local workspace only (never commit) |

### .gitignore Protection:

```gitignore
# Organization-specific work items
stories/

# Environment files with credentials
env/.env
plugins/ide-plugin/env/.env
```

---

## Validation

Before pushing to ADO:

1. ✅ Check character count: `wc -m story.md` (must be < 32,000 for ADO)
2. ✅ Convert to HTML and verify rendering
3. ✅ Check for emojis: `grep -P '[\x{1F300}-\x{1F9FF}]' story.md`
4. ✅ Verify all tables are proper markdown
5. ✅ Ensure PRD-sourced specifics are verbatim

---

## Related

- [AUTHORING_STANDARDS.md](../templates/AUTHORING_STANDARDS.md)
- [Story Template Registry](../templates/story-templates/STORY_TEMPLATE_REGISTRY.md)
- [ADO MCP Integration](../User_Manual/ADO_MCP_Integration.md)
