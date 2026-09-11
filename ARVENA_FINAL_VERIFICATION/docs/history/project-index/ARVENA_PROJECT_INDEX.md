# ARVENA Project Index

Last organized: 2026-09-10

## Canonical source of truth

The canonical product/architecture source set is located under `01_PRODUCT_SOURCE_OF_TRUTH/`, `02_ARCHITECTURE_AUDIT/`, and `03_ARCHITECTURE_CORRECTIONS/`.

Canonical documents:

1. `01_PRODUCT_SOURCE_OF_TRUTH/ARVENA_Master_Product_Requirements.pdf`
2. `01_PRODUCT_SOURCE_OF_TRUTH/ARVENA_UI_UX_Blueprint.pdf`
3. `01_PRODUCT_SOURCE_OF_TRUTH/ARVENA_Technical_Architecture_Data_Blueprint.pdf`
4. `01_PRODUCT_SOURCE_OF_TRUTH/ARVENA_Control_State_Entitlement_Acceptance.pdf`
5. `02_ARCHITECTURE_AUDIT/ARVENA_Pre_Build_Architecture_Audit_v1.0.md`
6. `03_ARCHITECTURE_CORRECTIONS/ARVENA_Architecture_Correction_Pack_v1.0.1.docx`
7. `01_PRODUCT_SOURCE_OF_TRUTH/brand/arvena-logo.png`

For ambiguity/correction, `ARVENA_Architecture_Correction_Pack_v1.0.1.docx` is the binding correction contract.

## Current repository

Canonical current source repository:

`05_CURRENT_REPOSITORY/arvena-p0/`

Compatibility pointer retained at:

`/mnt/data/arvena-p0 -> /mnt/data/ARVENA/05_CURRENT_REPOSITORY/arvena-p0`

The current repository is preserved without changing source-code or migration contents during this reorganization.

## Database

Canonical migration files remain inside:

`05_CURRENT_REPOSITORY/arvena-p0/supabase/migrations/`

`06_DATABASE/migrations/` is an organizational symlink view of those canonical migration files.

Latest migration physically present: `0011_arvena_p0_command_contract_completion.sql`.

Important current-chain fact: `0007` and `0008` are not physically present in the current repository. They were not reconstructed during reorganization. Final verification records this as a release blocker.

## Verification

Canonical latest verification result:

`05_CURRENT_REPOSITORY/arvena-p0/docs/audit/FINAL_VERIFICATION_RESULTS.md`

Convenience pointer:

`08_VERIFICATION/ARVENA_P0_FINAL_VERIFICATION_REPORT.md`

Current verified classification:

**P0 INCOMPLETE — PRODUCTION NO-GO**

Key verified blockers include missing application route source, incomplete migration chain, static SQL errors in `0011`, unavailable real DB execution, and failed/unexecuted quality gates.

## Releases

No valid `ARVENA_P0_FINAL_RELEASE.tar.gz` exists. It was intentionally not created because the release preconditions were not met.

Historical implementation baselines are archived in:

`04_IMPLEMENTATION_BASELINES/archive/`

## Historical work requests

Prior Work request/prompt artifacts are preserved unchanged under:

`00_PROJECT_INDEX/archive/work_requests/`

They are historical context only and are not canonical source code or product contracts.
