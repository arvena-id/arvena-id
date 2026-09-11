# ARVENA app RPC Surface — Physical Migration Inventory

Generated directly by replaying CREATE/DROP/GRANT/REVOKE statements in the physical canonical executable migrations after final hardening. Runtime `pg_proc`/ACL verification remains authoritative when PostgreSQL is available.

## Physical migration fingerprints

| Migration | SHA-256 | Bytes |
|---|---|---:|
| `0001_arvena_canonical_baseline.sql` | `2cddd0ca16d2f10c2252354d5d7d0bca86ac3b96a33b1fc9294747a5505ce6f8` | 319087 |
| `0002_arvena_p1.sql` | `9f83fc842f6045d24b387d28a8950a11cde74029fec3bd69158a2546bf812b6a` | 62073 |
| `0003_arvena_p2.sql` | `6ffad6f0147fcd20f217341832c5361a9df28dd40414001efc934f563fb2073c` | 62549 |

## Effective classification summary

- Client-callable authenticated RPC: **99**
- Service-role/internal worker RPC: **21**
- Private helper/no effective client execute privilege: **39**
- Final `app` function signatures: **159**
- Effective PUBLIC executable functions: **0**
- Effective anon/PUBLIC executable functions: **0**

## Final function surface

| Function signature | Classification | Effective execute roles | SECURITY DEFINER | Controlled search_path | Last physical definition |
|---|---|---|---:|---:|---|
| `app.accept_invitation(uuid)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.active_organization_id()` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.activity(uuid,uuid,text,uuid,text,text,jsonb)` | private helper | `none` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.apply_import_validation_batch(uuid,uuid,jsonb)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.apply_usage(uuid,text,bigint,text,text,text)` | private helper | `none` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.approval_payload_valid(text,jsonb)` | private helper | `none` | yes | yes | `0003_arvena_p2.sql` |
| `app.archive_customer(uuid,uuid,int,text,text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.attach_import_source(uuid,uuid,text,text,text,bigint,text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.audit(uuid,uuid,text,text,uuid,jsonb,jsonb)` | private helper | `none` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.authorize_api_token(text,text)` | service-role/internal worker RPC | `service_role` | yes | yes | `0003_arvena_p2.sql` |
| `app.automation_trigger_still_valid(uuid)` | service-role/internal worker RPC | `service_role` | yes | yes | `0002_arvena_p1.sql` |
| `app.branch_allowed(uuid,uuid)` | private helper | `none` | yes | yes | `0003_arvena_p2.sql` |
| `app.bump_version()` | private helper | `none` | no | n/a | `0001_arvena_canonical_baseline.sql` |
| `app.can_access_entity(uuid,text,uuid)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.can_view_asset(uuid,uuid)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.can_view_customer(uuid,uuid)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.can_view_followup(uuid,uuid)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.can_view_invoice(uuid,uuid)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0003_arvena_p2.sql` |
| `app.can_view_job(uuid,uuid)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0003_arvena_p2.sql` |
| `app.can_view_lead(uuid,uuid)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.can_view_quote(uuid,uuid)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.can_view_visit(uuid,uuid)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0003_arvena_p2.sql` |
| `app.claim_automation_runs(text,int)` | service-role/internal worker RPC | `service_role` | yes | yes | `0002_arvena_p1.sql` |
| `app.claim_queue(text,text,int)` | service-role/internal worker RPC | `service_role` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.command_hash(jsonb)` | private helper | `none` | no | yes | `0001_arvena_canonical_baseline.sql` |
| `app.command_lock(uuid,text,text)` | private helper | `none` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.commit_import_job(uuid,uuid,text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.complete_job(uuid,uuid,int,text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.confirm_job(uuid,uuid,int,text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.consume_job_limit(uuid,text,text)` | private helper | `none` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.convert_quote_to_job(uuid,uuid,text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.create_api_token(uuid,text,text[],timestamptz,text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0003_arvena_p2.sql` |
| `app.create_asset(uuid,uuid,text,text,text,text,text,date,date,text,text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.create_automation_rule(uuid,text,text,jsonb,jsonb,text,text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0002_arvena_p1.sql` |
| `app.create_branch(uuid,text,text,text,jsonb,text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0003_arvena_p2.sql` |
| `app.create_custom_field_definition(uuid,text,text,text,text,jsonb,boolean,text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0002_arvena_p1.sql` |
| `app.create_custom_role(uuid,text,text[],text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0003_arvena_p2.sql` |
| `app.create_customer(uuid,text,text,text,text,text,text,text,text,uuid,uuid,text,text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.create_customer_with_address(uuid,text,text,text,text,text,text,text,text,uuid,uuid,text,text,text,text,text,text,text,text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.create_export_job(uuid,text,jsonb,text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.create_followup(uuid,uuid,text,timestamptz,text,uuid,uuid,uuid,uuid,uuid,text,text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.create_import_job(uuid,text,text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.create_invoice(uuid,uuid,uuid,uuid,text,timestamptz,text,bigint,jsonb,text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.create_job(uuid,uuid,uuid,text,text,text,uuid,text,bigint,jsonb,text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.create_lead(uuid,uuid,text,text,text,text,uuid,bigint,text,timestamptz,text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.create_media(uuid,text,uuid,text,text,text,text,bigint,text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.create_note(uuid,text,uuid,text,text,text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.create_organization(text,text,text,text,text,text,uuid)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.create_outbound_webhook(uuid,text,text,text,text[],text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0003_arvena_p2.sql` |
| `app.create_quote(uuid,uuid,uuid,text,timestamptz,text,bigint,jsonb,text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.create_recurring_rule(uuid,uuid,uuid,text,int,time,text,date,date,jsonb,text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.create_service_catalog_item(uuid,text,text,text,text,bigint,text,text,text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0002_arvena_p1.sql` |
| `app.create_sla_contract(uuid,uuid,text,int,int,jsonb,text,date,date,jsonb,text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0003_arvena_p2.sql` |
| `app.create_ticket(uuid,uuid,uuid,uuid,text,text,text,text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0003_arvena_p2.sql` |
| `app.current_member_id(uuid)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.current_role_key(uuid)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.current_usage(uuid,text)` | private helper | `none` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.custom_field_target_exists(uuid,text,uuid)` | private helper | `none` | yes | yes | `0002_arvena_p1.sql` |
| `app.deactivate_recurring_rule(uuid,uuid,text,text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.decide_approval(uuid,uuid,text,text,text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0003_arvena_p2.sql` |
| `app.disconnect_integration(uuid,uuid,text,text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0002_arvena_p1.sql` |
| `app.effective_entitlement(uuid,text)` | private helper | `none` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.emit_event(uuid,uuid,text,text,uuid,jsonb,text)` | private helper | `none` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.enqueue_automation_for_event(uuid)` | service-role/internal worker RPC | `service_role` | yes | yes | `0002_arvena_p1.sql` |
| `app.enqueue_outbound_webhooks(uuid)` | service-role/internal worker RPC | `service_role` | yes | yes | `0003_arvena_p2.sql` |
| `app.entity_belongs_to_org(uuid,text,uuid)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.execute_approved_action(uuid)` | service-role/internal worker RPC | `service_role` | yes | yes | `0003_arvena_p2.sql` |
| `app.execute_automation_run(uuid)` | service-role/internal worker RPC | `service_role` | yes | yes | `0002_arvena_p1.sql` |
| `app.expire_exports(uuid)` | service-role/internal worker RPC | `service_role` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.fail_export_job(uuid,uuid,text,text)` | service-role/internal worker RPC | `service_role` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.fail_import_job(uuid,uuid,text,text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.fail_media(uuid,uuid,text,text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.feature_enabled(uuid,text)` | private helper | `none` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.finalize_media(uuid,uuid,text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.find_customer_duplicate_for_import(uuid,text)` | service-role/internal worker RPC | `service_role` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.followup_action(uuid,uuid,text,timestamptz,text,int,text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.generate_recurring_occurrence(uuid,uuid,date,timestamptz,text)` | service-role/internal worker RPC | `service_role` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.guard_direct_state_change()` | private helper | `none` | no | n/a | `0001_arvena_canonical_baseline.sql` |
| `app.guard_final_owner()` | private helper | `none` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.guard_invoice_immutability()` | private helper | `none` | no | n/a | `0001_arvena_canonical_baseline.sql` |
| `app.guard_invoice_item_mutation()` | private helper | `none` | no | n/a | `0001_arvena_canonical_baseline.sql` |
| `app.guard_job_schedule_cache()` | private helper | `none` | no | n/a | `0001_arvena_canonical_baseline.sql` |
| `app.guard_payment_immutability()` | private helper | `none` | no | n/a | `0001_arvena_canonical_baseline.sql` |
| `app.guard_quote_immutability()` | private helper | `none` | no | n/a | `0001_arvena_canonical_baseline.sql` |
| `app.guard_quote_item_mutation()` | private helper | `none` | no | n/a | `0001_arvena_canonical_baseline.sql` |
| `app.has_permission(uuid,text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.idempotency_commit(uuid,uuid,text,text,text,jsonb)` | private helper | `none` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.idempotency_existing(uuid,uuid,text,text,text)` | private helper | `none` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.invite_member(uuid,text,uuid,text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.is_privileged_db_actor()` | private helper | `none` | no | n/a | `0001_arvena_canonical_baseline.sql` |
| `app.issue_invoice(uuid,uuid,int,text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.issue_quote(uuid,uuid,int,text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.job_action(uuid,uuid,text,text,int,text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.limit_value(uuid,text)` | private helper | `none` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.list_my_organizations()` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.navigation_context(uuid)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.next_document_number(uuid,text)` | private helper | `none` | yes | yes | `0003_arvena_p2.sql` |
| `app.process_client_actions(uuid,text,jsonb)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.process_whatsapp_inbound(uuid,text,text,text,boolean)` | service-role/internal worker RPC | `service_role` | yes | yes | `0002_arvena_p1.sql` |
| `app.receive_external_event(uuid,text,text,text,boolean,jsonb)` | service-role/internal worker RPC | `service_role` | yes | yes | `0002_arvena_p1.sql` |
| `app.recompute_invoice(uuid,uuid)` | private helper | `none` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.recompute_quote(uuid,uuid)` | private helper | `none` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.record_payment(uuid,uuid,bigint,text,text,text,timestamptz,text,int,text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.recurring_date_matches_rule(uuid,uuid,date)` | service-role/internal worker RPC | `service_role` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.refresh_export_expiry(uuid,uuid)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.register_export_result(uuid,uuid,text,bigint,text,text)` | service-role/internal worker RPC | `service_role` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.request_approval(uuid,text,uuid,text,jsonb,int,timestamptz,text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0003_arvena_p2.sql` |
| `app.require_member(uuid)` | private helper | `none` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.require_permission(uuid,text)` | private helper | `none` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.resolve_customer_for_asset_import(uuid,uuid,text)` | service-role/internal worker RPC | `service_role` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.resolve_recurring_local_time(text,date,time)` | service-role/internal worker RPC | `service_role` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.respond_checklist(uuid,uuid,text,jsonb,text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.retry_media(uuid,uuid,text,bigint,text,text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.reverse_payment(uuid,uuid,text,text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.revoke_api_token(uuid,uuid,text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0003_arvena_p2.sql` |
| `app.schedule_visit(uuid,uuid,uuid,timestamptz,timestamptz,text,jsonb,uuid[],boolean,text,int,text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.seed_phase_permissions(uuid)` | private helper | `none` | yes | yes | `0002_arvena_p1.sql` |
| `app.seed_ultra_permissions(uuid)` | private helper | `none` | yes | yes | `0003_arvena_p2.sql` |
| `app.set_active_organization(uuid)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.set_custom_field_value(uuid,uuid,uuid,jsonb,text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0002_arvena_p1.sql` |
| `app.set_import_duplicate_decision(uuid,uuid,uuid,text,text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.set_import_status(uuid,uuid,text)` | service-role/internal worker RPC | `service_role` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.set_industry_template(uuid,uuid,text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.set_role_permission(uuid,uuid,text,boolean,text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.set_updated_at()` | private helper | `none` | no | n/a | `0001_arvena_canonical_baseline.sql` |
| `app.skip_recurring_occurrence(uuid,uuid,text,text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.stage_import_row(uuid,uuid,int,jsonb,jsonb,uuid,text)` | service-role/internal worker RPC | `service_role` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.stage_import_rows(uuid,uuid,jsonb)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.sync_member_profile()` | private helper | `none` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.ticket_action(uuid,uuid,text,int,text,text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0003_arvena_p2.sql` |
| `app.transition_lead(uuid,uuid,text,text,int,text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.update_asset_fields(uuid,uuid,int,text,text,text,text,text,date,date,text,text,text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.update_automation_rule(uuid,uuid,int,text,jsonb,jsonb,boolean,text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0002_arvena_p1.sql` |
| `app.update_branded_documents(uuid,uuid,text,text,text,text,text,text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0002_arvena_p1.sql` |
| `app.update_customer(uuid,uuid,int,text,text,text,text,text,text,text,text,uuid,uuid,text,text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.update_import_mapping(uuid,uuid,jsonb,text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.update_import_row_validation(uuid,uuid,int,jsonb,jsonb,uuid)` | service-role/internal worker RPC | `service_role` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.update_invoice_draft(uuid,uuid,int,timestamptz,text,bigint,jsonb,text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.update_job_fields(uuid,uuid,int,text,text,text,bigint,text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.update_lead_fields(uuid,uuid,int,text,text,text,text,uuid,bigint,timestamptz,text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.update_localization(uuid,text,text,text,text,text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.update_member(uuid,uuid,uuid,text,text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.update_member_profile(uuid,uuid,uuid,text,jsonb,text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.update_organization_business(uuid,text,jsonb,text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.update_quote_draft(uuid,uuid,int,timestamptz,text,bigint,jsonb,text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.update_quote_status(uuid,uuid,text,text,int,text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.update_recurring_rule(uuid,uuid,int,text,int,time,text,date,date,jsonb,text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.update_service_catalog_item(uuid,uuid,int,text,text,text,bigint,text,text,boolean,text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0002_arvena_p1.sql` |
| `app.update_tax_profile(uuid,text,int,text,text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.update_workflow_settings(uuid,jsonb,text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.upsert_integration(uuid,text,text,text,text,jsonb,text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0002_arvena_p1.sql` |
| `app.upsert_notification_preference(uuid,text,text,boolean,text,time,time,text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.validate_approval_target()` | private helper | `none` | no | n/a | `0003_arvena_p2.sql` |
| `app.validate_media_parent()` | private helper | `none` | no | n/a | `0001_arvena_canonical_baseline.sql` |
| `app.validate_polymorphic_target()` | private helper | `none` | no | n/a | `0001_arvena_canonical_baseline.sql` |
| `app.visit_action(uuid,uuid,text,int,text,text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.void_invoice(uuid,uuid,text,int,text)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |
| `app.webhook_endpoint_is_obviously_safe(text)` | private helper | `none` | yes | yes | `0003_arvena_p2.sql` |
| `app.worker_visit_context(uuid,uuid)` | client-callable authenticated RPC | `authenticated` | yes | yes | `0001_arvena_canonical_baseline.sql` |

## Physical hardening assertions

- No broad authenticated function grant exists in the canonical migration source.
- Effective PUBLIC/anon execution is zero after replaying the physical ACL statements.
- The caller-resolved legacy recurring generator signature and three-argument `fail_media` definition are absent.
- The retained recurring generator resolves timezone/DST server-side and enforces the rolling 60-day horizon.
- Offline processing contains server-owned sequence progression, immutable sequence slots, payload-hash validation and dependency gates.
- P1 integration binding globally serializes provider/account ownership and rejects foreign-tenant ownership.
- P2 approval action catalog, API scope catalog and webhook destination guard are present in executable SQL.
