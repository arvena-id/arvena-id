# ADR-001 — Unlimited Jobs Across All ARVENA Plans

**Status:** Accepted  
**Date:** 2026-09-11  
**Decision authority:** Explicit Owner approval in project conversation  
**Scope:** Commercial entitlement only; no change to core architecture, state machines, tenancy, security, or workflow behavior.

## Context

The prior v1 entitlement contract capped Job creation at 30/month on FREE, 500/month on PRO, and 2,000/month on ULTRA. During pricing review, the Owner approved changing Job records to unlimited on every tier because Job count is not a reliable proxy for business size or ability to pay. A solo field-service operator may create many low-value Jobs while still not needing Pro team, automation, or integration capabilities.

ARVENA should monetize scale and variable-cost/management capabilities rather than stopping the core Job workflow solely because a monthly record count was reached.

## Decision

`FREE`, `PRO`, and `ULTRA` all have **unlimited Job creation**.

The centralized entitlement key `limit.jobs_created_per_period` remains present for compatibility but its value is JSON `null`, which means **unlimited**.

`app.consume_job_limit(...)` is retained as a compatibility helper because existing Job creation flows call it, but it no longer blocks Job creation. It records `jobs_created` usage only for analytics, observability, and future business intelligence.

The following limits remain unchanged and continue to be enforced according to the existing contracts:

- team seats;
- storage;
- branches;
- WhatsApp/API/provider usage where applicable;
- automation/messaging and other variable-cost resources;
- feature entitlements such as WhatsApp connection, automation, service catalog, custom fields, advanced audit, custom roles, approvals, API/webhooks, and related tier boundaries.

Existing data access, completion, invoicing, payment, and export rules are unchanged.

## Upgrade philosophy

The intended upgrade triggers are now primarily:

- additional team seats;
- WhatsApp API/inbound automation;
- automation workflows;
- Service Catalog/custom fields;
- advanced recurring/reporting/performance;
- multi-branch, approval, audit, API/webhooks and other Ultra capabilities;
- storage and other cost-bearing resources.

ARVENA MUST NOT reintroduce a plan-based monthly Job creation cap without a new explicit product decision and versioned change record.

## Migration change control

The previously accepted pre-change physical P0 migration was preserved at:

`docs/migration-history/job-unlimited-prechange/0001_arvena_canonical_baseline.sql.accepted-before-job-unlimited`

Accepted pre-change SHA-256:

`93bd5e6a8948558b69666ac1e958490b2086819d83169ac18307aa05d4e96d21`

This ADR intentionally changes the canonical clean-install `0001_arvena_canonical_baseline.sql`. P1 and P2 migrations are not modified by this decision.

## Consequences

Positive:

- Free users can keep ARVENA as their operational system as Job volume grows.
- Upgrade pressure aligns with genuine operational complexity instead of arbitrary record count.
- High-volume, low-ticket service businesses are not penalized simply for having many Jobs.
- Job usage can still be measured without becoming a gate.

Trade-off:

- ARVENA must control variable cost through storage, messaging, automation, API/webhook use, seats and other governed resources rather than Job count itself.
