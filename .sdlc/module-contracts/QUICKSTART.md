# Module Intelligence System (MIS) — Quick Start

## 30-Second Overview

MIS is a contract-based system that:
- Defines what your module exposes (APIs, databases, events)
- Detects breaking changes automatically
- Prevents merge of changes without approval
- Generates impact reports for cross-service coordination

## Get Started Now

### 1. Initialize Your Repository (2 minutes)

```bash
sdlc mis init .
```

This creates:
- `.sdlc/module-contracts/api-contract.yaml`
- `.sdlc/module-contracts/data-contract.yaml`
- `.sdlc/module-contracts/event-contract.yaml`
- `.sdlc/module-contracts/dependencies.yaml`
- `.sdlc/module-contracts/breaking-changes.md`

### 2. Fill In Your Contracts (15 minutes)

Edit the YAML files:

```bash
# Edit your API endpoints
vi .sdlc/module-contracts/api-contract.yaml

# Edit your database schema
vi .sdlc/module-contracts/data-contract.yaml

# Edit your Kafka topics
vi .sdlc/module-contracts/event-contract.yaml

# Edit your external dependencies
vi .sdlc/module-contracts/dependencies.yaml

# Edit your breaking change policy
vi .sdlc/module-contracts/breaking-changes.md
```

Use the `.template` files as examples:
- `api-contract.yaml.template` — Shows API endpoint format
- `data-contract.yaml.template` — Shows database schema format

### 3. Analyze Changes (1 minute)

When developing a new feature:

```bash
# On your feature branch
sdlc mis analyze-change .
```

This detects:
- Breaking API changes
- Database schema incompatibilities
- Event schema breaking changes
- Affected services
- Risk score (LOW/MEDIUM/HIGH/CRITICAL)

### 4. Validate Before Merge (1 minute)

```bash
sdlc mis validate .
```

Checks:
- Contract syntax
- Git state
- Test coverage
- ADO issue linkage
- Migration rollback capability

### 5. Generate Impact Report (1 minute)

```bash
sdlc mis report .
```

Creates detailed report showing:
- What changed
- Who is affected
- Rollback procedures
- Testing checklist
- Deployment plan

## Quick Reference

### Commands

```bash
# Initialize MIS
sdlc mis init .

# Analyze changes on current branch
sdlc mis analyze-change .

# Validate before merge
sdlc mis validate .

# Generate impact report
sdlc mis report .

# View summary
sdlc mis show . summary

# View specific contract
sdlc mis show . api      # API contract
sdlc mis show . data     # Database contract
sdlc mis show . events   # Event/Kafka contract
sdlc mis show . deps     # Dependencies
sdlc mis show . breaking # Breaking change policy

# View analysis results
sdlc mis show . analysis
sdlc mis show . validation
```

## Files

### Contracts You Edit

- **`api-contract.yaml`** — REST endpoints and schemas
- **`data-contract.yaml`** — Database tables and migrations
- **`event-contract.yaml`** — Kafka topics and event schemas
- **`dependencies.yaml`** — External services and libraries
- **`breaking-changes.md`** — Breaking change policy

### Files Generated (Auto)

- **`last-change-analysis.json`** — Last analysis results
- **`validation-report.json`** — Last validation results
- **`impact-reports/`** — Generated impact reports

### Documentation

- **`README.md`** — Complete documentation (800+ lines)
- **`SUMMARY.md`** — Getting started guide

## Examples

### Example 1: Add New API Endpoint

**What you do:**
1. Create branch: `git checkout -b feature/user-verification`
2. Add endpoint to code
3. Run: `sdlc mis analyze-change .`
4. Update `api-contract.yaml` with new endpoint
5. Run: `sdlc mis validate .`
6. Push for review

**What MIS does:**
- Detects new endpoint ✓ (not breaking)
- Validates contract syntax ✓
- Checks tests exist ✓
- Reports: Ready to merge

### Example 2: Make Required Field

**What you do:**
1. Create branch: `git checkout -b feature/require-email`
2. Change email from optional → required
3. Run: `sdlc mis analyze-change .`

**What MIS detects:**
```
API CHANGES
  ✗ POST /users — BREAKING: email now required
  
BREAKING CHANGES DETECTED: 1
RISK SCORE: HIGH

RECOMMENDATIONS
  [ ] Get approval from API owners
  [ ] Notify mobile-app, web-app teams
  [ ] Create migration guide
  [ ] Set removal date (6 months)
```

**What you do:**
4. Update `breaking-changes.md` with breaking change info
5. Create ADO issue: "Breaking: POST /users email required"
6. Add to commit: `git commit -m "Require email in POST /users AB#12345"`
7. Run: `sdlc mis validate .`
8. Notify affected teams
9. Push for review

### Example 3: Rename Database Column

**What MIS detects:**
```
DATA CHANGES
  ✗ email_verified renamed to verified (BREAKING)

BREAKING CHANGES DETECTED: 1
RISK SCORE: HIGH
```

**Required actions:**
- Update `breaking-changes.md`
- Create ADO issue with migration guide
- Test rollback: `./mvnw liquibase:rollback`
- Notify affected services
- Get approval before merge

## Breaking Changes

### Not Breaking (Safe)
- Adding optional API field
- Adding optional parameter
- Adding optional database column
- Adding new event topic (old topic stays)
- Adding new endpoint
- Adding new event
- Additional status codes
- New optional fields in response

### Breaking (Requires Approval)
- Removing API endpoint
- Making optional field required
- Removing required response field
- Removing database column
- Removing unique constraint
- Changing column type
- Removing event topic
- Removing required event field

## Workflow

### For Developers
```
1. Create branch
2. Code changes
3. Run: sdlc mis analyze-change .
4. If breaking:
   - Update breaking-changes.md
   - Create ADO issue (AB#XXXXX)
   - Add to commits
5. Run: sdlc mis validate .
6. Push for review
```

### For Code Reviewers
```
1. Run: sdlc mis analyze-change .
2. Run: sdlc mis validate .
3. Run: sdlc mis report .
4. Review breaking changes
5. Verify affected services notified
6. Approve if all checks pass
```

### For Release Managers
```
1. Run: sdlc mis show . summary
2. Review impact reports
3. Coordinate with affected services
4. Verify rollback tested
5. Deploy
```

## Common Tasks

### Find What Changed

```bash
sdlc mis analyze-change . feature/my-branch
```

### Check If Safe to Merge

```bash
sdlc mis validate .
cat .sdlc/module-contracts/validation-report.json
```

### See Who Is Affected

```bash
sdlc mis report .
cat .sdlc/module-contracts/impact-reports/*.md
```

### View Your Contracts

```bash
sdlc mis show . api
sdlc mis show . data
sdlc mis show . events
```

### Update Contracts

```bash
vi .sdlc/module-contracts/api-contract.yaml
vi .sdlc/module-contracts/data-contract.yaml
vi .sdlc/module-contracts/event-contract.yaml
vi .sdlc/module-contracts/dependencies.yaml
vi .sdlc/module-contracts/breaking-changes.md
```

## Troubleshooting

### "No module contracts found"
```bash
sdlc mis init .
```

### "Validation failed"
```bash
sdlc mis validate .
cat .sdlc/module-contracts/validation-report.json
```

### "Breaking changes not detected"
- Check contract is complete (not using defaults)
- Run analysis from repository root
- Verify changed code matches contract

### "Can't understand YAML"
- Use templates as examples: `.template` files
- Simple key: value format
- Check indentation (YAML is whitespace-sensitive)

## Next Steps

1. **Initialize**: `sdlc mis init .`
2. **Complete contracts** — Fill in your APIs, database, events
3. **Test analysis** — Run on a feature branch
4. **Enable in CI/CD** — Add validation to pipeline
5. **Document** — Share workflow with team
6. **Coordinate** — Notify teams of breaking changes

## Help & Documentation

- **Full docs**: `cat .sdlc/module-contracts/README.md`
- **Command help**: `sdlc mis help`
- **Examples**: `.sdlc/module-contracts/*.template`
- **Integration**: `cat MIS-INTEGRATION.md`

## Key Points

- **Breaking changes detected automatically** ✓
- **Windows compatible** (Git Bash) ✓
- **No external dependencies** (pure bash) ✓
- **Version controlled** (contracts in .git) ✓
- **Non-blocking warnings** (see issues without blocking) ✓
- **Clear recommendations** (actionable guidance) ✓

## Questions?

1. Read `.sdlc/module-contracts/README.md` (800+ lines)
2. Check template examples
3. Run `sdlc mis help`
4. Review impact reports
5. Ask team lead

---

**Ready to start?** Run: `sdlc mis init .`

**Version:** 1.0 | **Date:** April 13, 2025 | **Platform:** AI SDLC v2.0
