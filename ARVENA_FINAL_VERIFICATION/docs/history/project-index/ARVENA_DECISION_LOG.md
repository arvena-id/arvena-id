# ARVENA Decision Log

This file records project-level canonical/current decisions and references. It does not replace the source-of-truth documents.

## D-ORG-001 — Product source authority

Canonical product/architecture documents are stored under `01_PRODUCT_SOURCE_OF_TRUTH/`, `02_ARCHITECTURE_AUDIT/`, and `03_ARCHITECTURE_CORRECTIONS/`.

For ambiguity/correction, Architecture Correction Pack v1.0.1 is binding.

## D-ORG-002 — Current repository

The canonical current repository is `05_CURRENT_REPOSITORY/arvena-p0/`.

Historical baseline archives are non-current and are stored under `04_IMPLEMENTATION_BASELINES/archive/`.

## D-ORG-003 — Migration history

Migration contents were not modified during project reorganization. The physically present current chain is `0001`-`0006`, `0009`-`0011`. Missing `0007` and `0008` were not recreated.

## D-ORG-004 — Verification authority

`FINAL_VERIFICATION_RESULTS.md` is the current verification record. `08_VERIFICATION/ARVENA_P0_FINAL_VERIFICATION_REPORT.md` is a symlink alias to that record.

## D-ORG-005 — Release status

No P0 final release archive is canonical or valid at this time. Current release classification remains **P0 INCOMPLETE — PRODUCTION NO-GO**.

## D-ORG-006 — Organizational views

`06_DATABASE/`, `07_TESTING_ACCEPTANCE/`, `08_VERIFICATION/`, and `09_OPERATIONS/` use symlinks where appropriate so the current repository remains the canonical source of migrations, tests, verification documents, and operations documentation without duplicating or rewriting file contents.
