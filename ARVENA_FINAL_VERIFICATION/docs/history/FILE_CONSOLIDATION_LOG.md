# ARVENA File Consolidation Log

Purpose: consolidate the latest ARVENA P0 source that physically exists in the current Work filesystem into one canonical repository without changing application source, business logic, or historical migrations.

## Canonical source selection

- Canonical implementation source selected: `/mnt/data/arvena-p0`
- Canonical consolidated destination: `/mnt/data/ARVENA_CURRENT/arvena-p0`
- Selection reason: `/mnt/data/arvena-p0` contains the broadest and newest physical implementation tree found in Work (`app`, `components`, `lib`, `public`, `supabase`, `scripts`, `tests`, configs, and current migration-history documentation).
- Generated cache `tsconfig.tsbuildinfo` was intentionally excluded from the canonical repository.
- No `node_modules`, `.next`, `.git`, real `.env`, or secrets were copied.

## Work locations inspected

The consolidation scan inspected ARVENA-related material in:

- `/mnt/data/arvena-p0`
- `/mnt/data/ARVENA/05_CURRENT_REPOSITORY/arvena-p0`
- `/mnt/data/ARVENA/00_PROJECT_INDEX`
- `/mnt/data/ARVENA/04_IMPLEMENTATION_BASELINES`
- `/mnt/data/ARVENA_P0_BASELINE_AFTER_INITIAL_BUILD.tar.gz`
- `/mnt/data/ARVENA_P0_BASELINE_AFTER_INITIAL_BUILD_v2.tar.gz`
- ARVENA source-of-truth files at `/mnt/data`
- `/tmp/arvena-quality` and `/tmp/arvena_static_audit.txt` were inspected as runtime verification output, not application source.
- `/home/oai/share` contained no additional ARVENA source candidates.

## Duplicate/conflict decisions

### `package.json`

Two historical baseline archives contain an older `package.json`:

- Historical SHA-256: `e9cc62f8720462f49226f5ccf82d8436ad7b5bde6d132f7cdad710ee61ff07e0`
- Historical size: 1,494 bytes
- Current implementation SHA-256: `7d1f970d8e64431fc0147305c8f8f85c2b42178c58b4abdc5a632a7f086960f0`
- Current size: 1,617 bytes

Decision: the current implementation copy from `/mnt/data/arvena-p0/package.json` is canonical. Historical copies remain preserved inside the two existing baseline archives and were not overwritten.

### Migrations `0001` through `0006`

The copies inside both historical baseline archives are byte-identical to the current implementation copies. No conflict exists. The current implementation paths are canonical.

### `0011_arvena_p0_command_contract_completion.sql`

Two intentionally different versions physically exist:

- Historical broken pre-deployment copy: `docs/migration-history/0011_arvena_p0_command_contract_completion.PREDEPLOYMENT_BROKEN.sql`
  - SHA-256: `5b67e459c665e7532c626a104566affd520d350c92f265a60cb2831f2a616cc6`
  - Size: 44,450 bytes
- Current migration: `supabase/migrations/0011_arvena_p0_command_contract_completion.sql`
  - SHA-256: `aa5b6603ed37990b904fbe568055d4bd423df4d5301ccbbe84f63e79fcd99bc5`
  - Size: 43,946 bytes

Decision: the current file in `supabase/migrations/` is canonical. The broken pre-deployment version remains preserved under `docs/migration-history/`; it was not deleted or overwritten.

### `FINAL_VERIFICATION_RESULTS.md`

A duplicate exists at `/mnt/data/ARVENA/05_CURRENT_REPOSITORY/arvena-p0/docs/audit/FINAL_VERIFICATION_RESULTS.md`. It is byte-identical to the copy in `/mnt/data/arvena-p0/docs/audit/FINAL_VERIFICATION_RESULTS.md`.

SHA-256 for both: `d82d6550232f5d5e0a2df7bcbe8b07dafd63d5f2281b8cfbbb27d7738256f263`.

Decision: keep one canonical copy in `docs/audit/`.

### Official ARVENA logo

`/mnt/data/arvena logo.png` and `/mnt/data/arvena-p0/public/brand/arvena-logo.png` are byte-identical.

SHA-256: `72726e073950541f31383b2f1c64e0ac502748f0bc9769202e898512b3d235a2`.

Decision: the application path `public/brand/arvena-logo.png` is canonical. No duplicate logo file was added elsewhere in the repository.

### Source-of-truth documents

The six source-of-truth documents physically present at `/mnt/data` are byte-identical to the copies contained in the historical v2 baseline archive. They were consolidated once into `docs/source-of-truth/` with their content unchanged.

## Missing historical migrations

No authoritative physical file named either of the following was found in the inspected Work filesystem or either historical baseline archive:

- `0007_arvena_p0_application_hardening.sql`
- `0008_arvena_p0_evidence_security.sql`

They were **not reconstructed, inferred, or fabricated**. The migration sequence therefore contains a physical numbering gap between `0006` and `0009`.

## Files intentionally not treated as source

The following remain outside the canonical repository because they are runtime output, historical packaged snapshots, generated cache, or conversation/request artifacts rather than current application source:

- `/tmp/arvena-quality/*`
- `/tmp/arvena_static_audit.txt`
- `/mnt/data/ARVENA_P0_BASELINE_AFTER_INITIAL_BUILD.tar.gz`
- `/mnt/data/ARVENA_P0_BASELINE_AFTER_INITIAL_BUILD_v2.tar.gz`
- `/mnt/data/Pasted markdown*.md`
- `/mnt/data/arvena-p0/tsconfig.tsbuildinfo`

The two baseline archives remain physically present in Work and therefore historical source has not been deleted.

## Additional historical project documents consolidated

Existing project-index/status documents were copied unchanged under `docs/history/project-index/`, and the existing implementation status report was copied unchanged under `docs/history/status-reports/`. These are historical/context documents and are not treated as application source-of-truth.
