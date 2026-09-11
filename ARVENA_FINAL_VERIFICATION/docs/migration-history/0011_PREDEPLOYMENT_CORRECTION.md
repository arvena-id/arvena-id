# 0011 controlled pre-deployment correction

Status: pre-deployment migration correction. This is verification/change-control evidence, not a product/architecture change.

Evidence available in the repository shows the migration chain has never been successfully executed in a real PostgreSQL/Supabase-compatible database in this Work. The prior verification report records DB execution as NOT EXECUTED and `0011` as statically invalid. Therefore the current task's explicit pre-deployment correction rule applies.

The original broken `0011_arvena_p0_command_contract_completion.sql` is preserved byte-for-byte as `0011_arvena_p0_command_contract_completion.PREDEPLOYMENT_BROKEN.sql` with a SHA-256 manifest.

The active `0011` changes only the five known UUID-return wrapper expressions for:

- `schedule_visit`
- `invite_member`
- `update_tax_profile`
- `create_note`
- `create_media`

Each now serializes its UUID result explicitly as `jsonb_build_object('result_id', result)` for audit/event payloads instead of attempting a UUID/JSONB CASE expression.

This correction does **not** claim the migration chain is complete. Authoritative original migrations `0007` and `0008` are still missing from the accessible filesystem/File Library, so predecessor signatures required by later `0011` wrappers remain unverifiable until those original files are recovered.
