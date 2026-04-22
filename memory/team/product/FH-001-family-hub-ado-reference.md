# Family Hub (FH-001) - ADO Work Item Reference

**Primary Repository**: `https://dev.azure.com/JPL-Limited/JioAIphotos/_git/AI-sdlc-platform`

**Local Path**: `c:\JioCloudCursor\AISDLC\stories\`

> This document serves as a **reference pointer** linking the platform's distributed memory to Azure DevOps work items. The actual story files remain local (not in the platform repo) as they are organization-specific.

---

## ADO Work Items

| Work Item | Type | Title | State | Local Reference |
|-----------|------|-------|-------|-----------------|
| [865620](https://dev.azure.com/JPL-Limited/JioAIPhotos/_workitems/edit/865620) | Feature | Family Hub Phase 1 - Master Story | Proposed | `FH-001-master-family-hub-phase1.md` |
| [865621](https://dev.azure.com/JPL-Limited/JioAIPhotos/_workitems/edit/865621) | User Story | Sprint 3: Hub Creation and Invite Flow | New | `FH-001-S01-sprint-hub-creation-invite.md` |
| [865622](https://dev.azure.com/JPL-Limited/JioAIPhotos/_workitems/edit/865622) | User Story | Sprint 4: Member Management and Storage Alerts | New | `FH-001-S02-sprint-member-management.md` |

---

## Hierarchy

```
Feature 865620: Family Hub Phase 1 (Master Story)
├── User Story 865621: Sprint 3 - Hub Creation & Invite Flow
└── User Story 865622: Sprint 4 - Member Management & Storage Alerts
```

---

## Cross-Team Impact Log

When Family Hub decisions affect other teams, log them here:

| Date | Decision | Impact | ADO Ref |
|------|----------|--------|---------|
| | | | |

---

## Notes

- Story files are maintained **locally** at `c:\JioCloudCursor\AISDLC\stories\`
- This reference file lives in the **platform repo** (`memory/team/product/`) for discoverability
- Updates to story files should be pushed to ADO work items via `push_to_ado.py`
- Cross-team decisions should be logged in `../shared/cross-team-log.md`

---

**Last Updated**: 2026-04-22
