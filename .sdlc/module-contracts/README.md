# Module Intelligence System (MIS)

The Module Intelligence System is a contract-based change analysis engine that:
- Defines what each module exposes (APIs, databases, events, dependencies)
- Validates changes against those contracts
- Detects breaking changes before merge
- Generates impact reports for cross-service coordination
- Tracks deprecation policies and migration paths

## Quick Start

### 1. Initialize MIS for Your Repository

```bash
sdlc mis init [repo-path]
```

This scans your repository and creates:
- `.sdlc/module-contracts/api-contract.yaml` — API endpoint contract
- `.sdlc/module-contracts/data-contract.yaml` — Database schema contract
- `.sdlc/module-contracts/event-contract.yaml` — Event/Kafka topics
- `.sdlc/module-contracts/dependencies.yaml` — External dependencies
- `.sdlc/module-contracts/breaking-changes.md` — Breaking change policy

### 2. Review and Complete Contracts

Edit each contract YAML file to document your module's interface:

```bash
# View the API contract template
cat api-contract.yaml.template

# Edit your actual contract
vi api-contract.yaml
```

### 3. Analyze Changes on Your Branch

```bash
# Analyze changes from main → HEAD
sdlc mis analyze-change .

# Analyze a specific commit/branch
sdlc mis analyze-change . feature/new-api
sdlc mis analyze-change . HEAD~1
```

Output: Breaking change detection, risk score, recommendations

### 4. Validate Before Merge

```bash
sdlc mis validate
```

Checks:
- Contract syntax and content validity
- Git repository state
- Test coverage
- ADO issue linkage
- Migration rollback capability

### 5. Generate Impact Report

```bash
sdlc mis report
```

Comprehensive markdown report showing:
- What changed (APIs, database, events)
- Who is affected (consuming services)
- Risk assessment and mitigation
- Rollback plan
- Testing and deployment checklists
- Sign-off requirements

### 6. View Contracts

```bash
# Show summary
sdlc mis show . summary

# Show specific contract
sdlc mis show . api
sdlc mis show . data
sdlc mis show . events
sdlc mis show . dependencies

# Show analysis results
sdlc mis show . analysis
sdlc mis show . validation
```

## Contracts Explained

### API Contract (`api-contract.yaml`)

Defines all REST API endpoints your module exposes:

```yaml
version: "1.0"
module: user-service
base_path: /api/v1

endpoints:
  - path: /users
    method: POST
    summary: Create user
    request_schema: CreateUserRequest
    response_schema: UserResponse
    status_codes: [201, 400, 409]
    consumers: [mobile-app, web-app]

schemas:
  CreateUserRequest:
    fields:
      email: {type: string, required: true}
      name: {type: string, required: true}
```

**Key fields:**
- `path` — API endpoint path
- `method` — HTTP method (GET, POST, PUT, DELETE)
- `request_schema` / `response_schema` — Data structures
- `status_codes` — Possible HTTP status codes
- `consumers` — Services that use this endpoint
- `breaking_change_notes` — Deprecation info

**Breaking changes in APIs:**
- Endpoint removed or renamed
- Required request field added
- Required response field removed or renamed
- Response field type changed
- Status code behavior changed

### Data Contract (`data-contract.yaml`)

Defines database schema and migration constraints:

```yaml
version: "1.0"
database: postgresql

tables:
  users:
    columns:
      id: {type: bigserial, primary_key: true, immutable: true}
      email: {type: varchar(255), unique: true, required: true}
      created_at: {type: timestamp, immutable: true}
      updated_at: {type: timestamp}
    indexes:
      - name: idx_users_email
        columns: [email]
        unique: true
    foreign_keys:
      - column: organization_id
        references: organizations.id

migrations:
  - version: "001"
    description: "Create users table"
    file: "db/migrations/001_create_users.sql"
    tested: true
    rolled_back: true
```

**Key fields:**
- `columns` — All table columns with types and constraints
- `indexes` — Database indexes
- `foreign_keys` — Relationships to other tables
- `migrations` — History of schema changes
- `readonly_columns` — Immutable columns (id, created_at, etc.)
- `mutable_columns` — Columns that can be updated

**Breaking changes in schemas:**
- Column removed from database
- Column type changed
- Unique constraint added to column with duplicates
- Foreign key added (integrity constraint)
- Column made required (null → not null)

### Event Contract (`event-contract.yaml`)

Defines Kafka topics and event schemas:

```yaml
version: "1.0"
broker: kafka
namespace: jio.services.users

events_produced:
  - name: user.created
    topic: user.created.v1
    version: "1"
    schema:
      user_id: {type: string, format: uuid}
      email: {type: string}
    produced_by: [CreateUserController]
    consumed_by: [notification-service, analytics-service]

events_consumed:
  - name: organization.deleted
    topic: org.deleted.v1
    consumed_by: [DeleteUsersByOrgController]
```

**Key fields:**
- `events_produced` — Events this service publishes
- `events_consumed` — Events this service subscribes to
- `schema` — Event payload structure
- `produced_by` / `consumed_by` — Which classes handle the event
- `retention` — How long events are kept

**Breaking changes in events:**
- Event topic removed or renamed
- Required field removed from schema
- Required field type changed
- Required field added (old producers fail)

### Dependencies Contract (`dependencies.yaml`)

Declares external services and libraries:

```yaml
version: "1.0"
module: user-service

external_services:
  - service: auth-service
    endpoints: [/auth/validate]
    purpose: "Validate OAuth tokens"
    failure_mode: "Return 401 Unauthorized"
    sla: "99.9%"

internal_modules:
  - module: user-repository
    use: "Database access layer"
    breaking_changes_tracked: true

libraries:
  - name: spring-security
    version: "6.1.0"
    purpose: "OAuth2 provider"
    security_constraint: true
```

### Breaking Changes Policy (`breaking-changes.md`)

Documents your breaking change approval workflow:

```markdown
## What is a Breaking Change?

A breaking change requires consumers to update their code:
- API endpoint removed or renamed
- Required field added to request
- Required field removed from response
- Database column removed

## What is NOT a Breaking Change?

- Optional field added (backward compatible)
- New optional parameter
- Additional status codes
- New column in database (if nullable)

## Approval Workflow

1. Identify the change is breaking
2. Document in breaking-changes.md
3. Create ADO issue (AB#XXXXX)
4. Notify all consumers
5. Set migration deadline (6+ months)
6. Get stakeholder approval
7. Merge after approval
```

## Change Analysis

The `analyze-change` command detects breaking changes:

```bash
sdlc mis analyze-change . feature/new-api
```

**Output includes:**

```
ANALYSIS REPORT: user-service feature/new-api

API CHANGES
  ✓ GET /users/{id} — implementation changed (safe)
  ✗ POST /users — BREAKING: email now required (was optional)
  + POST /users/{id}/verify-email — new endpoint

DATA CHANGES
  ✓ phone_number added (optional column, safe)
  ✗ email_verified renamed to verified (BREAKING)

EVENT CHANGES
  + user.email_verified event — new event
  ✗ user.created — schema changed (BREAKING)

BREAKING CHANGES DETECTED: 2
RISK SCORE: HIGH

RECOMMENDATIONS
  [ ] Get approval from API owners
  [ ] Notify notification-service and analytics-service
  [ ] Update docs/migration guides
  [ ] Add deprecation date to breaking-changes.md
```

**Analysis detects:**
- New/removed/renamed endpoints
- Required field additions
- Schema changes in requests/responses
- Migration changes
- Event schema modifications
- ADO issue linkage (AB#XXXXX in commits)
- Test coverage

## Validation

Pre-merge validation checklist:

```bash
sdlc mis validate
```

**Checks:**
1. Contract syntax valid (YAML parsing)
2. Module metadata defined
3. Contract content complete
4. Breaking changes documented
5. Git repository clean
6. Change analysis passing
7. ADO issues linked
8. Test coverage sufficient
9. Documentation updated
10. Migration rollback tested

## Impact Reports

Generate comprehensive impact reports:

```bash
sdlc mis report
```

**Report includes:**
- File change summary
- API impact analysis
- Database impact analysis
- Event/Kafka impact
- Dependency impact
- Cross-service impact (who needs to update)
- Rollback plan
- Testing checklist
- Deployment checklist
- Risk assessment
- Sign-off requirements

## Workflow

### For Developers

1. Create feature branch
2. Make changes to code, migrations, events, etc.
3. Run: `sdlc mis analyze-change`
4. If breaking changes:
   - Update `breaking-changes.md`
   - Create ADO issue (AB#XXXXX)
   - Link in commits
   - Add migration guides
5. Run: `sdlc mis validate`
6. Push for code review
7. Reviewer runs: `sdlc mis validate` and `sdlc mis report`
8. Get approvals from affected service owners
9. Merge after approval

### For Code Reviewers

1. Run: `sdlc mis analyze-change`
2. Review breaking changes
3. Check notifications to affected services
4. Run: `sdlc mis validate`
5. Run: `sdlc mis report` for impact
6. Verify test coverage
7. Approve if all checks pass

### For Release Managers

1. Run: `sdlc mis show . summary`
2. Review impact reports
3. Coordinate with affected services
4. Verify SLA/downtime requirements
5. Plan deployment order
6. Test rollback procedures
7. Deploy with confidence

## Files and Directories

```
.sdlc/module-contracts/
├── README.md                           This file
├── api-contract.yaml                   API endpoint definitions
├── data-contract.yaml                  Database schema contract
├── event-contract.yaml                 Kafka event schemas
├── dependencies.yaml                   External dependencies
├── breaking-changes.md                 Breaking change policy
├── SUMMARY.md                          Getting started guide
├── api-contract.yaml.template          Example API contract
├── data-contract.yaml.template         Example data contract
├── last-change-analysis.json           Last analysis results
├── validation-report.json              Last validation results
└── impact-reports/
    └── YYYYMMDD-HHMMSS-impact-report.md   Generated impact reports
```

## Integration with CI/CD

### Pre-Commit Hook

```bash
#!/bin/bash
sdlc mis validate || exit 1
```

### Pre-Merge Check (ADO/GitHub)

```bash
#!/bin/bash
sdlc mis validate
sdlc mis analyze-change
# Fail if breaking changes without approval
```

### Release Pipeline

```bash
#!/bin/bash
sdlc mis show . summary
sdlc mis report
# Generate deployment checklist
```

## Best Practices

### 1. Keep Contracts Updated

Update contracts when:
- Adding new endpoints
- Changing database schema
- Adding events
- Changing dependencies

### 2. Test Migrations

Always test database migrations:
```bash
# Test forward migration
./mvnw liquibase:update

# Test rollback
./mvnw liquibase:rollback -Dliquibase.rollback.count=1
```

### 3. Link ADO Issues

Always link work items in commits:
```bash
git commit -m "Implement user verification AB#12345"
```

### 4. Document Breaking Changes

Breaking changes require:
- ADO issue tracking
- Migration guide
- Deprecation deadline
- Consumer notifications

### 5. Notify Affected Services

Before deploying breaking changes:
- Create epic with all impacted services
- Set same deadline for all consumers
- Coordinate testing
- Plan deployment order

### 6. Version Your APIs

Use API versioning to avoid breaking changes:
- `POST /api/v1/users` (current)
- `POST /api/v2/users` (new version)
- Keep v1 for backward compatibility

## Troubleshooting

### "No module contracts found"

Initialize contracts first:
```bash
sdlc mis init
```

### Breaking changes not detected

Make sure:
1. Contract is complete (not using templates)
2. Changed code matches contract definitions
3. Run analysis from correct repo directory

### Validation fails

Run validation with details:
```bash
sdlc mis validate
```

Check each validation result:
- Contract syntax (use `sdlc mis show . api`)
- Test coverage
- Git state
- ADO linkage

## Examples

### Example 1: Add Optional API Field

**Change:** Add `phone` field to `/users` POST request (optional)

**Analysis:** ✓ NOT BREAKING (backward compatible)
- Old clients don't send phone → works fine
- New clients can send phone → works fine
- No action required

### Example 2: Make Field Required

**Change:** Change `email` from optional to required in `POST /users`

**Analysis:** ✗ BREAKING CHANGE
- Old clients don't send email → API returns 400
- Must create migration path:
  1. Create v2 endpoint accepting required email
  2. Deprecate v1 endpoint
  3. Notify all consumers (mobile-app, web-app)
  4. Set 6-month migration deadline

**Action:**
1. Add to `breaking-changes.md`:
   ```
   - API: POST /users email field now required
   - Deprecated: 2025-04-13
   - Removal: 2025-10-13
   - Migrate: Use POST /api/v2/users instead
   ```
2. Create ADO issue: "Breaking: POST /users email required - AB#12345"
3. Notify mobile-app, web-app teams
4. Update migration guide

### Example 3: Remove Database Column

**Change:** Drop `legacy_id` column from `users` table

**Analysis:** ✗ BREAKING CHANGE
- Any query using `legacy_id` will fail
- Other services might use this column
- Database migration needed

**Action:**
1. Check which services use `legacy_id`:
   ```bash
   grep -r "legacy_id" /path/to/other/services/
   ```
2. Notify those services
3. Create migration:
   ```sql
   ALTER TABLE users DROP COLUMN legacy_id;
   ```
4. Test rollback:
   ```sql
   ALTER TABLE users ADD COLUMN legacy_id VARCHAR(255);
   ```
5. Document in `breaking-changes.md`
6. Set migration deadline (usually 6 months)

## Support

For questions or issues with MIS:
1. Review examples above
2. Check contract templates (`.template` files)
3. Look at analysis output in `last-change-analysis.json`
4. Run `sdlc mis show . validation` for recent checks
5. Contact architecture team for guidance

## Version History

- **v1.0** (2025-04-13) — Initial release
  - Contract definitions for API, data, events
  - Change analysis engine
  - Validation and impact reporting
  - Breaking change tracking

---

**Last Updated:** 2025-04-13
**Module Intelligence System v1.0**
**AI SDLC Platform v2.0**
