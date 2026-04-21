# Module Intelligence System (MIS) — Contract Summary

## Module: ai-sdlc-platform
**Generated:** 2026-04-13T07:04:21Z
**Commit:** unknown
**Stack:** unknown

## Contracts Created

1. **api-contract.yaml** — API endpoint contract
   - Define all REST endpoints
   - Document request/response schemas
   - List API consumers
   - Track deprecations

2. **data-contract.yaml** — Database schema contract
   - Document table structures
   - Track migrations
   - Mark immutable columns
   - Document breaking changes

3. **event-contract.yaml** — Event schema contract
   - Define Kafka topics
   - Document event schemas
   - List producers/consumers
   - Track breaking changes

4. **dependencies.yaml** — External dependency contract
   - List external services
   - Document internal modules
   - Track critical libraries
   - Define SLAs

5. **breaking-changes.md** — Breaking change policy
   - Define what breaks
   - Approval workflow
   - Migration guides
   - History tracking

## Next Steps

### 1. Review and Complete Contracts
- [ ] Fill in api-contract.yaml with your endpoints
- [ ] Document all request/response schemas
- [ ] Fill in data-contract.yaml with table definitions
- [ ] Complete event-contract.yaml with Kafka topics
- [ ] List all dependencies in dependencies.yaml
- [ ] Update breaking-changes.md with policy

### 2. Validate Contracts
Run validation to check contract syntax:
```bash
sdlc mis validate
```

### 3. Analyze Changes
When making changes, analyze impact:
```bash
sdlc mis analyze-change <branch-name>
```

### 4. Pre-Merge Validation
Before merging, validate against contracts:
```bash
sdlc mis validate-merge
```

## Scanning Tips

### Find API Endpoints
```bash
grep -r "@RequestMapping\|@PostMapping\|@GetMapping" src/main/java
```

### Find Migrations
```bash
find . -path "*/db/migrations/*.sql" -o -path "*/migration/*.sql"
```

### Find Kafka Topics
```bash
grep -r "KafkaTemplate\|@KafkaListener\|topics\|\.topic" src/
```

### Find External Services
```bash
grep -r "@FeignClient\|RestTemplate\|WebClient" src/
```

## Commands

```bash
# Initialize MIS (this script)
sdlc mis init [repo-path]

# Show contracts
sdlc mis show api
sdlc mis show data
sdlc mis show events

# Analyze changes on branch
sdlc mis analyze-change [branch-name]

# Validate contracts before merge
sdlc mis validate-merge

# Generate impact report
sdlc mis impact-report
```

## Resources

- Module Knowledgebase: 
- Contracts: 
- Change Analysis: 
- Impact Reports: 

---

**Platform:** AI SDLC Platform v2.0
**Module Intelligence System Version:** 1.0
