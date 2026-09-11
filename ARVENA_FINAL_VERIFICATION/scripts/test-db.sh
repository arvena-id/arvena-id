#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RLS_ONLY=0
[[ "${1:-}" == "--rls-only" ]] && RLS_ONLY=1
python3 "$ROOT/scripts/static-sql-audit.py"
: "${ARVENA_TEST_DATABASE_URL:?Set ARVENA_TEST_DATABASE_URL to a disposable PostgreSQL/Supabase-compatible test database}"
command -v psql >/dev/null 2>&1 || { echo 'ENVIRONMENT BLOCKER: psql is not installed' >&2; exit 78; }
"$ROOT/scripts/apply-migrations.sh"
psql "$ARVENA_TEST_DATABASE_URL" -v ON_ERROR_STOP=1 -f "$ROOT/tests/db/fixtures.sql"
if [[ "$RLS_ONLY" == "1" ]]; then
  psql "$ARVENA_TEST_DATABASE_URL" -v ON_ERROR_STOP=1 -f "$ROOT/tests/rls/acceptance.sql"
else
  psql "$ARVENA_TEST_DATABASE_URL" -v ON_ERROR_STOP=1 -f "$ROOT/tests/db/acceptance.sql"
  psql "$ARVENA_TEST_DATABASE_URL" -v ON_ERROR_STOP=1 -f "$ROOT/tests/rls/acceptance.sql"
fi
