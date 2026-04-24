#!/usr/bin/env bash
# CI guard: fail if internal-attribution strings (below) still appear in the tree.
# Intended to run on the public checkout after neutralize + overlays; regenerate User_Manual/manual.html before commit.
# (ADO integration code uses dev.azure.com with ${ADO_ORG} — not scanned as "internal org" here.)
set -euo pipefail
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "$ROOT" ]]; then
  echo "ERROR: not inside a git repository" >&2
  exit 1
fi
cd "$ROOT"

# neutralize_public_mirror.py legitimately contains old needles as replace() literals
EXC=(
  ':(exclude)scripts/mirror-public/verify-public-no-vendor.sh'
  ':(exclude)scripts/mirror-public/neutralize_public_mirror.py'
)

# Needles that must not remain after neutralize (matched case-insensitively with git grep -i).
PATS=(
  'YourOrg'
  'YourProject'
  'yourcloud'
  'YourCursor'
  'neutral mirror'
  '_git/AI-sdlc-platform'
)

failed=0
for pat in "${PATS[@]}"; do
  # -i: case-insensitive for jiocloud etc.; search tracked files in the working tree
  if git grep -n -i -F "$pat" -- . "${EXC[@]}" 2>/dev/null; then
    echo "::error::Blocked string (case-insensitive): $pat" >&2
    failed=1
  fi
done

if [[ "$failed" -ne 0 ]]; then
  echo "verify-public-no-vendor: FAILED" >&2
  exit 1
fi
echo "verify-public-no-vendor: OK"
