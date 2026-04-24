# Agent Capability Matrix

**Last Generated**: 2026-04-24T11:22:17Z
**Total Agents**: 55

**Authoritative manifest:** [agent-registry.json](agent-registry.json) — tiers, tags, token budgets, and tool wiring.

## SDLC authoring (all agents)

Outputs that touch **PRD, system design, Master/Sprint/Tech/Task stories, or ADO** must follow **[AUTHORING_STANDARDS.md](../templates/AUTHORING_STANDARDS.md)** — ADO-ready PRD lift (copy/notifications), traceability chain, no invented scope, non-redundancy, and **Tech Story** non-regression when applicable.

Individual agent files include a short **SDLC authoring** line pointing to this standard (search for AUTHORING_STANDARDS under the agents/ tree).

## By Tier

| Tier | Domain | Count | Purpose |
|------|--------|-------|---------|
| **Tier 1** | Shared (Universal) | 19 | Core system agents used by all roles |
| **Tier 2** | Backend | 4 | Backend-specific agents |
| **Tier 2** | Frontend | 16 | Mobile/web/design/dev agents |
| **Tier 2** | QA | 10 | Requirements through test execution |
| **Tier 2** | Performance | 4 | Performance analysis and reporting |
| **Tier 2** | Product | 1 | Product management |
| **Tier 3** | Reports / Executive | 1 | Cross-cutting reports and release |

**Total Agents**: 55

---

## Agent Inventory (from filesystem)

### Tier 1: `agents/shared/`

- `ado-integration`
- `architect-agent`
- `auto-documentation-guardian`
- `compliance-auditor`
- `context-guard`
- `em-agent`
- `gate-informant`
- `gate-matrix`
- `master-code-reviewer`
- `pipeline-coordinator-agent`
- `pipeline-flow`
- `pm-agent`
- `qa-agent`
- `release-manager-agent`
- `rpi-coordinator`
- `smart-routing`
- `state-reconciler-agent`
- `tech-lead-agent`
- `tpm-agent`

### Tier 2: `agents/backend/`

- `be-developer-agent`
- `be-sdlc-pipeline-agent`
- `elasticsearch-logs-agent`
- `wikijs-mcp-agent`

### Tier 2: `agents/frontend/`

- `android-dev`
- `architecture-guardian`
- `context-memory-manager`
- `crash-monitor`
- `cto`
- `dependency-watchdog`
- `designer`
- `developer`
- `ios-dev`
- `memory-budget-controller`
- `peer-reviewer`
- `perf-optimizer`
- `platform-qa`
- `rn-dev`
- `scaffolding-agent`
- `security-agent`

### Tier 2: `agents/qa/`

- `analysis-agent`
- `defect-agent`
- `qa-engineer`
- `qa-ops-agent`
- `release-signoff-agent`
- `requirement-analysis-agent`
- `risk-analysis-agent`
- `test-builder-agent`
- `test-environment-agent`
- `test-runner-agent`

### Tier 2: `agents/performance/`

- `perf-analyst`
- `perf-architect`
- `perf-engineer`
- `perf-reporter`

### Tier 2: `agents/product/`

- `product-manager`

### Tier 3: `agents/boss/` (and `agents/reports/` if present)

- `report-agent`


---

## Agent Discovery

```bash
ls agents/{shared,backend,frontend,qa,performance,product,boss}/
grep -r "description" agents/ --include="*.md"
```

---

**Generated**: 2026-04-24T11:22:17Z
**Command**: regenerate-registries.sh --update
