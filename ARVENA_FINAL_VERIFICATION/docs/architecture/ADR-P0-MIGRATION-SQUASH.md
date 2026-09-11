# ADR-P0-MIGRATION-SQUASH

Status: Accepted  
Date: 2026-09-11

## Context

The pre-squash physical migration history contained `0001-0006` and `0009-0012`. The authoritative historical files `0007_arvena_p0_application_hardening.sql` and `0008_arvena_p0_evidence_security.sql` are not available byte-for-byte. Historical `0011_arvena_p0_command_contract_completion.sql` therefore contains rename assumptions that cannot execute against the physically preserved predecessor chain. Reconstructing `0007`/`0008` and presenting them as authoritative history would falsify provenance.

## Decision

The historical chain is preserved verbatim under `supabase/migrations_history/p0_pre_squash/` and is **not** the clean-install path. New deployments start from `supabase/migrations/0001_arvena_canonical_baseline.sql`. The canonical baseline incorporates the executable P0 schema/functions/RLS/views from the preserved repository, active-organization/Worker security hardening, and direct command-contract definitions without pretending the missing historical migrations existed.

P1 and P2 remain additive clean migrations after the canonical P0 baseline.

## Consequences

- Historical provenance is retained for audit/reference.
- Clean installs do not execute the known-broken historical chain.
- No fake `0007`/`0008` files are created.
- Future production migrations are append-only and must not edit the archived history.
