# Breaking Change Policy for MODULE_NAME_HERE

## What is a Breaking Change?

A breaking change is any modification that requires consumers to update their code:

### API Breaking Changes
- Endpoint removed or renamed
- Required request field added
- Required response field removed or renamed
- Response field type changed
- Status code behavior changed

### Data Breaking Changes
- Column removed from database
- Column type changed (e.g., int → varchar)
- Unique constraint added to column with duplicates
- Foreign key added (integrity constraint)
- Column made required (null → not null)

### Event Breaking Changes
- Event topic removed or renamed
- Required field removed from schema
- Required field type changed
- Required field added (old producers fail)

## What is NOT a Breaking Change?

- Optional field added to request (old clients work)
- Optional field added to response (old clients ignore)
- New optional query parameter
- New event topic (if old topic stays)
- Column added to database (nullable)
- Additional status codes in API response
- New optional event field (backward compatible)

## Approval Workflow

1. **Identify the change** — Determine if it's breaking
2. **Document it** — Add to this file with details
3. **Create ADO issue** — Link with `AB#XXXXX` in commit
4. **Notify consumers** — Contact all consuming services
5. **Set deadline** — Usually 6 months from change date
6. **Merge after approval** — Get stakeholder sign-off
7. **Enforce deadline** — Remove deprecated code at deadline

## Current Breaking Changes

**None** (as of TIMESTAMP_HERE)

## Planned Breaking Changes

Add planned changes here with deprecation dates.

## Past Breaking Changes (History)

Include history of removed breaking changes:
- What changed
- When it was deprecated
- When it was removed
- How consumers were impacted

## Migration Guides

Create subdirectories for each breaking change:
- `migration/v2.0-api-changes.md` — Guide for API consumers
- `migration/v2.0-schema-changes.md` — Guide for DB migrations
- `migration/v2.0-event-changes.md` — Guide for event consumers

## Contact

For breaking change questions, contact:
- Service Owner: [NAME_HERE]
- Architecture: [TEAM_HERE]
