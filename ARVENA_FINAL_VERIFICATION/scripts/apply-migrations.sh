#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
: "${ARVENA_TEST_DATABASE_URL:?Set ARVENA_TEST_DATABASE_URL to a disposable PostgreSQL/Supabase-compatible database}"
command -v psql >/dev/null 2>&1 || { echo 'ENVIRONMENT BLOCKER: psql is not installed' >&2; exit 78; }
for migration in "$ROOT"/supabase/migrations/*.sql; do
  echo "==> applying $(basename "$migration")"
  psql "$ARVENA_TEST_DATABASE_URL" -v ON_ERROR_STOP=1 -f "$migration"
done
