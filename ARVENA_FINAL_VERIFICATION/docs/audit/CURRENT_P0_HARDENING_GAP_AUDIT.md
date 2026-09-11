# ARVENA P0 Current Hardening Gap Audit

Audit date: 2026-09-09
Baseline: current repository at `/mnt/data/arvena-p0`
Binding correction contract: ARVENA Architecture Correction Pack v1.0.1.

## Verified current state

The repository is now a real Next.js/TypeScript application with 144 files before this hardening run, including auth, onboarding, protected routes, Supabase SSR helpers, domain actions, worker/offline/media routes, migrations `0001`-`0008`, reports/settings pages, and responsive shell components.

## Release-blocking gaps found before changes

1. **P0 Import/Export application layer missing.** The persistence/RPC primitives exist in migration `0007`, but the four required `/data/import*` and `/data/export*` routes and application actions are absent.
2. **Quality scripts reference missing files.** `test:db` points to `scripts/test-db.sh`, but `scripts/` is empty. `test:integration` points to `tests/integration`, but only `tests/setup.ts` exists. Playwright config exists but there are no E2E tests.
3. **Acceptance/security suite absent.** No deterministic Organization A/B database fixture, RLS deny/allow suite, state-machine SQL acceptance, finance concurrency, owner-safety concurrency, recurring concurrency/DST, or import/export isolation tests exist yet.
4. **Unit coverage is absent.** Domain utilities for money, phone normalization, recurrence and offline queues have no unit tests.
5. **Database execution path is unverified.** Static SQL exists through migration `0008`, but there is no reproducible local/remote database verification harness and no evidence in the repository that migrations/RLS were executed successfully.
6. **Dashboard/report semantics need reconciliation.** Existing pages query real rows but require explicit shared definitions for overdue/late/unassigned/cancelled exclusions and drill-through consistency.
7. **Transactional command surface is inconsistent.** Several state-changing server actions call RPCs, but some mutable fields still use direct table updates. Those must be reviewed against RLS, version and activity/outbox requirements; no permission may rely on hidden UI.
8. **Import/export RPCs are incomplete for end-to-end P0.** Baseline functions create/stage jobs, but safe idempotent commit, export data materialization, expiry/download authorization and retry-safe result behavior are not complete application workflows.
9. **Final placeholder/dead-code scan is not cleanly documented.** No PlaceholderPage exists, but the final repository needs an explicit scan result and intentional P1/P2 non-active code review.
10. **Backup/restore operations doc missing.** Required `docs/operations/BACKUP_RESTORE.md` does not exist.
11. **Final release archive must not be produced yet.** P0 remains implementation-incomplete until missing P0 workflows/tests are added and all executable gates are rerun after final changes.

## Non-gaps / locked behavior already preserved

- Job and Visit are separate; Visit remains scheduling source of truth.
- Quote backend state uses `ISSUED`, not `SENT`.
- Job reopen remains disabled in P0.
- Money uses minor-unit primitives and issued document snapshots are intended immutable.
- Payment correction uses append-only reversal and P0 rejects overpayment.
- Worker routes are separate from Owner navigation and use assignment-scoped RPCs.
- Active organization is resolved server-side from authenticated membership rather than trusted client ownership.
- Historical migrations `0001`-`0008` are preserved; future fixes must be additive.
