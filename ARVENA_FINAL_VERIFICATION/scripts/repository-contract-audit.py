#!/usr/bin/env python3
from pathlib import Path
import sys
root=Path(__file__).resolve().parents[1]
required_files=[
 'package.json','tsconfig.json','next.config.ts','eslint.config.mjs','vitest.config.ts','playwright.config.ts','.env.example',
 'scripts/apply-migrations.sh','scripts/test-db.sh','scripts/static-sql-audit.py',
 'tests/db/fixtures.sql','tests/rls/acceptance.sql','tests/integration/application-surface.test.ts','tests/e2e/p0-surface.spec.ts',
 'tests/concurrency/run-concurrency.sh','tests/offline/offline-contract.test.ts','tests/recurring/recurrence-source.test.ts','tests/finance/money-source.test.ts','tests/import-export/import-export-source.test.ts'
]
missing=[p for p in required_files if not (root/p).exists()]
routes=sorted(str(p.relative_to(root)) for p in (root/'app').rglob('*') if p.is_file() and p.name in {'page.tsx','route.ts'}) if (root/'app').exists() else []
migrations=sorted((root/'supabase/migrations').glob('*.sql'))
nums=[int(p.name[:4]) for p in migrations if p.name[:4].isdigit()]
gaps=[n for n in range(min(nums),max(nums)+1) if n not in nums] if nums else []
print(f'required_file_missing={len(missing)}')
for p in missing: print('MISSING',p)
print(f'route_count={len(routes)}')
for r in routes: print('ROUTE',r)
print(f'migration_count={len(migrations)}')
print('migration_gaps='+','.join(f'{n:04d}' for n in gaps))
# A P0 release repository must have actual route source and a gap-free migration chain.
if missing or not routes or gaps: sys.exit(1)
