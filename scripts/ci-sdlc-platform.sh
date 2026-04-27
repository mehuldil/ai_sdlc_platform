#!/usr/bin/env bash
# ci-sdlc-platform.sh — Single CI entry (GitHub Actions + Azure Pipelines)
# Also run locally: bash scripts/ci-sdlc-platform.sh
#   --quick  Fast checks only (used by ./setup.sh after install; no smoke test)
#
# Requires: bash, git checkout; full mode also: node 18+, npm, python3, jq, curl

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

QUICK=0
for a in "$@"; do
  [[ "$a" == "--quick" ]] && QUICK=1
done

# Do not set CI=1 here — local ./setup.sh must still verify git hooks. CI env is set by GitHub/Azure agents.

_lint_shell_and_python() {
  echo "=== bash -n (critical scripts) ==="
  bash -n scripts/sdlc-auto-sync.sh
  bash -n scripts/bootstrap-sdlc-features.sh
  bash -n scripts/repair-claude-mirrors.sh
  bash -n scripts/verify-claude-ssot-ci.sh
  bash -n scripts/validate-stage-variants.sh
  bash -n hooks/pre-commit.sh
  bash -n cli/sdlc.sh
  bash -n cli/lib/ado.sh
  bash scripts/sdlc-auto-sync.sh ci-verify
  if command -v python3 &>/dev/null && python3 -V &>/dev/null; then
    echo "=== python3 -m py_compile (semantic memory) ==="
    python3 -m py_compile orchestrator/shared/semantic_memory.py scripts/semantic-memory.py
    rm -rf orchestrator/shared/__pycache__ scripts/__pycache__ 2>/dev/null || true
  else
    echo "=== skip py_compile (python3 not on PATH) ==="
  fi
  if command -v node &>/dev/null && node -v &>/dev/null; then
    echo "=== User_Manual/manual.html --check ==="
    cd User_Manual
    if ! npm ci --prefer-offline --no-audit 2>/dev/null; then
      npm install --legacy-peer-deps 2>/dev/null || true
    fi
    node build-manual-html.mjs --check
    cd "$ROOT"
  else
    echo "=== skip manual.html --check (node not on PATH) ==="
  fi
}

run_quick() {
  echo "=== ci-sdlc-platform (--quick) ==="
  bash scripts/validate-system-change.sh "$ROOT"
  _lint_shell_and_python
  echo "=== ci-sdlc-platform --quick OK ==="
}

if [[ "$QUICK" -eq 1 ]]; then
  run_quick
  exit 0
fi

echo "=== ci-sdlc-platform (full) ==="
bash scripts/validate-system-change.sh "$ROOT"
_lint_shell_and_python

echo "=== semantic-memory status ==="
if command -v python3 &>/dev/null && python3 -V &>/dev/null; then
  python3 scripts/semantic-memory.py status || true
else
  echo "skip: python3"
fi

echo "=== CLI smoke (cli/tests/smoke.sh) ==="
bash cli/tests/smoke.sh

if command -v node &>/dev/null; then
  echo "=== User_Manual/manual.html --check (full) ==="
  cd User_Manual
  if ! npm ci --prefer-offline --no-audit 2>/dev/null; then
    npm install --legacy-peer-deps 2>/dev/null || true
  fi
  node build-manual-html.mjs --check
  cd "$ROOT"
fi

echo "=== ci-sdlc-platform (full) OK ==="
