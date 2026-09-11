# ARVENA P0 Final Verification Gap Audit

Date: 2026-09-10
Binding contract: ARVENA Architecture Correction Pack v1.0.1.

## Current-source findings

1. **Application source is absent.** The current repository does not contain the previously reported auth, onboarding, app shell, resource pages, route handlers, Supabase client/server helpers, worker UI/offline client, import/export UI, dashboard/report UI, or application actions.
2. **No P0 route exists.** `app/globals.css` is the only application file.
3. **Historical migration chain is incomplete.** `0007` and `0008` are missing while later migrations are present.
4. **`0011` cannot be accepted as executable against the present migration chain.** Static signature analysis finds multiple `ALTER FUNCTION ... RENAME` targets that have no prior matching function in `0001`-`0010` as physically present. These missing functions correspond to areas previously reported as coming from hardening migrations that are now absent.
5. **`0011` also has UUID/JSONB wrapper type hazards.** Several UUID-returning wrappers use a generic `CASE` expression whose branches are UUID and JSONB; this is not a safe PostgreSQL expression contract.
6. **No executable DB/RLS acceptance suite existed.** A reproducible harness is being added in this run, but the current environment has no `psql`, PostgreSQL, Supabase CLI, Docker or Podman, so real DB execution cannot be claimed.
7. **No frontend/unit/integration/E2E source existed.** Verification tests cannot exercise a missing application layer without implementing product features, which is outside this verification-only scope.
8. **Package scripts are not backed by repository files.** `npm run typecheck`, `test`, `test:integration`, and `test:e2e` reference tools/config/test source that did not exist locally at baseline. Dependency installation also requires network access.
9. **Backup/restore documentation was absent.** A P0 operations document is added in this verification run and explicitly states that restore execution has not been tested.
10. **Active-organization request context is not enforced by the physically present authorization helpers.** `app.current_member_id(p_org)` and `app.has_permission(p_org, ...)` accept any organization UUID for which the authenticated user has an ACTIVE membership. A dual-org user can therefore resolve both memberships without a binding active-organization claim. The Correction Pack requires one active organization per request.
11. **Worker full-row Customer minimization is not satisfied by the present RLS shape.** `customers_select` delegates to `app.can_view_customer`, which explicitly returns true for a Worker whose assigned Visit belongs to a Job for that Customer. Because the policy is on the base `customers` table, the Worker receives the whole Customer row rather than a minimized execution-only projection. No `worker_execution_context` view exists in the repository. Acceptance tests were added to make both defects fail closed once DB execution is available.

## Release consequence

The repository cannot truthfully be classified as P0 implementation-complete. The missing application layer is not a test gap; it is missing implementation. Reconstructing it during a final-verification-only run would violate the instruction not to add product features to mask missing source.

The only valid release class unless the missing application source is restored from the authoritative baseline is:

**P0 INCOMPLETE — PRODUCTION NO-GO**
