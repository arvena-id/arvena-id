#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
roots=()
for d in app components lib scripts tests supabase; do [[ -e "$d" ]] && roots+=("$d"); done
PATTERN='PlaceholderPage|TODO|FIXME|HACK|\bmock\b|\bdummy\b|console\.log|service_role|hardcoded organization|unsafe any'
set +e
out=$(grep -RInE --exclude-dir=node_modules --exclude-dir=.next --exclude='*.md' --exclude='final-source-scan.sh' "$PATTERN" "${roots[@]}" 2>/dev/null)
rc=$?
set -e
if [[ $rc -eq 2 ]]; then printf '%s\n' "$out"; exit 2; fi
if [[ -n "$out" ]]; then printf '%s\n' "$out"; fi
# Known non-blocking SQL-only service_role occurrences are expected for privileged DB actor checks / grants.
blocking=$(printf '%s\n' "$out" | grep -Ev '^supabase/migrations/[0-9]{4}_.+\.sql:.*service_role' || true)
if [[ -n "$blocking" ]]; then
  echo 'P0-BLOCKING SOURCE-SCAN HITS:' >&2
  printf '%s\n' "$blocking" >&2
  exit 1
fi
exit 0
