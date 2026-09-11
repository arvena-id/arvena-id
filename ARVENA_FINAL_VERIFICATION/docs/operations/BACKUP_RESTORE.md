# ARVENA P0 Backup and Restore

Status: **Restore procedure documented but not execution-tested in this environment.**

## Scope
Back up PostgreSQL tenant/business data, Supabase Auth metadata according to provider procedures, private object storage bytes, and deployment configuration/secrets through the platform secret manager. Database backup alone is not sufficient for ARVENA media because object bytes live outside PostgreSQL.

## PostgreSQL backup
Use the production provider's scheduled backups and retain an independent logical dump according to the recovery policy. Example for an authorized maintenance host:

```bash
pg_dump --format=custom --no-owner --no-acl "$DATABASE_URL" > arvena-db-$(date -u +%Y%m%dT%H%M%SZ).dump
```

Protect backup files as sensitive data. Never place dumps in the application repository.

## Private object storage backup
Export/copy the private ARVENA media/export buckets to a separate protected storage destination, preserving object keys, checksums, content type and creation metadata where the provider supports it. Do not make a bucket public to simplify backup.

## Configuration and secrets
Record non-secret deployment configuration separately. Restore secrets from the authorized secret manager; never source real secrets from `.env.example` or repository history. Rotate credentials if compromise is suspected.

## Restore order
1. Provision an isolated recovery environment.
2. Restore PostgreSQL/Auth data using provider-supported procedures.
3. Restore private object-storage bytes using the same logical object keys.
4. Restore application configuration and secrets.
5. Deploy the exact application/migration version corresponding to the backup.
6. Reconcile media rows against storage objects and checksums.
7. Rebuild only derived caches/materialized data; never rewrite immutable issued Quote/Invoice history.
8. Re-enable background workers after core database integrity checks pass.

## Post-restore verification
- Migration/schema version matches the release manifest.
- Organization A cannot access Organization B records.
- Composite tenant FKs reject cross-tenant parents.
- Final Owner safety invariant holds.
- Issued Quote/Invoice snapshots are unchanged.
- Payment ledger totals reconcile with invoice paid/outstanding projections.
- Private media requires entity-level authorization and signed access.
- Recurring occurrence unique identities remain intact.
- Outbox/idempotency receipts do not produce duplicate business outcomes on worker restart.
- Sample Customers, Jobs, Visits, Invoices and Payments are readable only by allowed roles.

## Recovery evidence
For production readiness, record date, backup identifier, restore target, operator, duration, RPO/RTO observed, row/object reconciliation counts, security acceptance results and any discrepancies. A documented procedure alone is not evidence of a successful restore drill.
