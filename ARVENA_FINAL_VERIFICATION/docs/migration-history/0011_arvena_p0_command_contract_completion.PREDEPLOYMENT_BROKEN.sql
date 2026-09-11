-- ARVENA P0 command contract completion. Historical migrations 0001-0010 remain immutable.
create or replace function app.command_hash(p_payload jsonb) returns text language sql immutable set search_path=public,app as $$ select encode(digest(coalesce(p_payload,'null'::jsonb)::text,'sha256'),'hex') $$;
create or replace function app.command_lock(p_org uuid,p_scope text,p_key text) returns void language plpgsql security definer set search_path=public,app as $$ begin if coalesce(trim(p_key),'')='' then raise exception 'ARV-CONFLICT-1001 idempotency key required'; end if; perform pg_advisory_xact_lock(hashtextextended(p_org::text||':'||p_scope||':'||p_key,17)); end $$;
revoke all on function app.command_lock(uuid,text,text) from public,anon,authenticated;
revoke all on function app.command_hash(jsonb) from public,anon; grant execute on function app.command_hash(jsonb) to authenticated,service_role;

-- confirm_job: add serialized same-key/same-hash replay contract around the preserved implementation.
alter function app.confirm_job(uuid,uuid,int,text) rename to confirm_job_v1_unhardened;
revoke all on function app.confirm_job_v1_unhardened(uuid,uuid,int,text) from public,anon,authenticated;
create or replace function app.confirm_job(p_org uuid,p_job uuid,p_expected_version int,p_key text) returns jsonb
language plpgsql security definer set search_path=public,app as $$
declare actor uuid; h text; result jsonb; replay jsonb; begin
  actor:=app.require_permission(p_org,'job.confirm'); h:=app.command_hash(jsonb_build_array(p_org,p_job,p_expected_version)); perform app.command_lock(p_org,'job.confirm',p_key);
  replay:=app.idempotency_existing(p_org,actor,'job.confirm',p_key,h);
  if replay is not null then return replay; end if;
  result:=app.confirm_job_v1_unhardened(p_org,p_job,p_expected_version,p_key);
  perform app.audit(p_org,actor,'job.confirm','JOB',p_job,null,case when pg_typeof(result)::text='jsonb' then result else jsonb_build_object('result_id',result) end);
  perform app.emit_event(p_org,actor,'job.confirm','JOB',p_job,case when pg_typeof(result)::text='jsonb' then result else jsonb_build_object('result_id',result) end,p_key||':contract');
  perform app.idempotency_commit(p_org,actor,'job.confirm',p_key,h,result); return result; end $$;
grant execute on function app.confirm_job(uuid,uuid,int,text) to authenticated;

-- schedule_visit: add serialized same-key/same-hash replay contract around the preserved implementation.
alter function app.schedule_visit(uuid,uuid,uuid,timestamptz,timestamptz,text,jsonb,uuid[],boolean,text,int,text) rename to schedule_visit_v1_unhardened;
revoke all on function app.schedule_visit_v1_unhardened(uuid,uuid,uuid,timestamptz,timestamptz,text,jsonb,uuid[],boolean,text,int,text) from public,anon,authenticated;
create or replace function app.schedule_visit(p_org uuid,p_job uuid,p_visit uuid,p_start timestamptz,p_end timestamptz,p_timezone text,p_address jsonb,p_assign_members uuid[],p_override boolean,p_reason text,p_expected_version int,p_key text) returns uuid
language plpgsql security definer set search_path=public,app as $$
declare actor uuid; h text; result uuid; replay jsonb; begin
  actor:=app.require_permission(p_org,case when p_visit is null then 'visit.schedule' else 'visit.reschedule' end); h:=app.command_hash(jsonb_build_array(p_org,p_job,p_visit,p_start,p_end,p_timezone,p_address,p_assign_members,p_override,p_reason,p_expected_version)); perform app.command_lock(p_org,'visit.schedule',p_key);
  replay:=app.idempotency_existing(p_org,actor,'visit.schedule',p_key,h);
  if replay is not null then return (replay->>'result_id')::uuid; end if;
  result:=app.schedule_visit_v1_unhardened(p_org,p_job,p_visit,p_start,p_end,p_timezone,p_address,p_assign_members,p_override,p_reason,p_expected_version,p_key);
  perform app.audit(p_org,actor,'visit.schedule','VISIT',coalesce(p_visit,p_job),null,case when pg_typeof(result)::text='jsonb' then result else jsonb_build_object('result_id',result) end);
  perform app.emit_event(p_org,actor,'visit.schedule','VISIT',coalesce(p_visit,p_job),case when pg_typeof(result)::text='jsonb' then result else jsonb_build_object('result_id',result) end,p_key||':contract');
  perform app.idempotency_commit(p_org,actor,'visit.schedule',p_key,h,jsonb_build_object('result_id',result)); return result; end $$;
grant execute on function app.schedule_visit(uuid,uuid,uuid,timestamptz,timestamptz,text,jsonb,uuid[],boolean,text,int,text) to authenticated;

-- visit_action: add serialized same-key/same-hash replay contract around the preserved implementation.
alter function app.visit_action(uuid,uuid,text,int,text,text) rename to visit_action_v1_unhardened;
revoke all on function app.visit_action_v1_unhardened(uuid,uuid,text,int,text,text) from public,anon,authenticated;
create or replace function app.visit_action(p_org uuid,p_visit uuid,p_action text,p_expected_version int,p_reason text,p_key text) returns jsonb
language plpgsql security definer set search_path=public,app as $$
declare actor uuid; h text; result jsonb; replay jsonb; begin
  actor:=app.require_permission(p_org,case p_action when 'DEPART' then 'visit.depart_assigned' when 'ARRIVE' then 'visit.arrive_assigned' when 'START' then 'visit.start_assigned' when 'FINISH' then 'visit.finish_assigned' when 'CANCEL' then 'visit.cancel' when 'NO_SHOW' then 'visit.no_show' else 'visit.view' end); h:=app.command_hash(jsonb_build_array(p_org,p_visit,p_action,p_expected_version,p_reason)); perform app.command_lock(p_org,'visit.action',p_key);
  replay:=app.idempotency_existing(p_org,actor,'visit.action',p_key,h);
  if replay is not null then return replay; end if;
  result:=app.visit_action_v1_unhardened(p_org,p_visit,p_action,p_expected_version,p_reason,p_key);
  perform app.audit(p_org,actor,'visit.action','VISIT',p_visit,null,case when pg_typeof(result)::text='jsonb' then result else jsonb_build_object('result_id',result) end);
  perform app.emit_event(p_org,actor,'visit.action','VISIT',p_visit,case when pg_typeof(result)::text='jsonb' then result else jsonb_build_object('result_id',result) end,p_key||':contract');
  perform app.idempotency_commit(p_org,actor,'visit.action',p_key,h,result); return result; end $$;
grant execute on function app.visit_action(uuid,uuid,text,int,text,text) to authenticated;

-- complete_job: add serialized same-key/same-hash replay contract around the preserved implementation.
alter function app.complete_job(uuid,uuid,int,text) rename to complete_job_v1_unhardened;
revoke all on function app.complete_job_v1_unhardened(uuid,uuid,int,text) from public,anon,authenticated;
create or replace function app.complete_job(p_org uuid,p_job uuid,p_expected_version int,p_key text) returns jsonb
language plpgsql security definer set search_path=public,app as $$
declare actor uuid; h text; result jsonb; replay jsonb; begin
  actor:=app.require_permission(p_org,'job.complete'); h:=app.command_hash(jsonb_build_array(p_org,p_job,p_expected_version)); perform app.command_lock(p_org,'job.complete',p_key);
  replay:=app.idempotency_existing(p_org,actor,'job.complete',p_key,h);
  if replay is not null then return replay; end if;
  result:=app.complete_job_v1_unhardened(p_org,p_job,p_expected_version,p_key);
  perform app.audit(p_org,actor,'job.complete','JOB',p_job,null,case when pg_typeof(result)::text='jsonb' then result else jsonb_build_object('result_id',result) end);
  perform app.emit_event(p_org,actor,'job.complete','JOB',p_job,case when pg_typeof(result)::text='jsonb' then result else jsonb_build_object('result_id',result) end,p_key||':contract');
  perform app.idempotency_commit(p_org,actor,'job.complete',p_key,h,result); return result; end $$;
grant execute on function app.complete_job(uuid,uuid,int,text) to authenticated;

-- reverse_payment: add serialized same-key/same-hash replay contract around the preserved implementation.
alter function app.reverse_payment(uuid,uuid,text,text) rename to reverse_payment_v1_unhardened;
revoke all on function app.reverse_payment_v1_unhardened(uuid,uuid,text,text) from public,anon,authenticated;
create or replace function app.reverse_payment(p_org uuid,p_payment uuid,p_reason text,p_key text) returns jsonb
language plpgsql security definer set search_path=public,app as $$
declare actor uuid; h text; result jsonb; replay jsonb; begin
  actor:=app.require_permission(p_org,'payment.reverse'); h:=app.command_hash(jsonb_build_array(p_org,p_payment,p_reason)); perform app.command_lock(p_org,'payment.reverse',p_key);
  replay:=app.idempotency_existing(p_org,actor,'payment.reverse',p_key,h);
  if replay is not null then return replay; end if;
  result:=app.reverse_payment_v1_unhardened(p_org,p_payment,p_reason,p_key);
  perform app.idempotency_commit(p_org,actor,'payment.reverse',p_key,h,result); return result; end $$;
grant execute on function app.reverse_payment(uuid,uuid,text,text) to authenticated;

-- void_invoice: add serialized same-key/same-hash replay contract around the preserved implementation.
alter function app.void_invoice(uuid,uuid,text,int,text) rename to void_invoice_v1_unhardened;
revoke all on function app.void_invoice_v1_unhardened(uuid,uuid,text,int,text) from public,anon,authenticated;
create or replace function app.void_invoice(p_org uuid,p_invoice uuid,p_reason text,p_expected_version int,p_key text) returns jsonb
language plpgsql security definer set search_path=public,app as $$
declare actor uuid; h text; result jsonb; replay jsonb; begin
  actor:=app.require_permission(p_org,'invoice.void'); h:=app.command_hash(jsonb_build_array(p_org,p_invoice,p_reason,p_expected_version)); perform app.command_lock(p_org,'invoice.void',p_key);
  replay:=app.idempotency_existing(p_org,actor,'invoice.void',p_key,h);
  if replay is not null then return replay; end if;
  result:=app.void_invoice_v1_unhardened(p_org,p_invoice,p_reason,p_expected_version,p_key);
  perform app.activity(p_org,actor,'INVOICE',p_invoice,'invoice.void','Command applied',jsonb_build_object('command','invoice.void'));
  perform app.idempotency_commit(p_org,actor,'invoice.void',p_key,h,result); return result; end $$;
grant execute on function app.void_invoice(uuid,uuid,text,int,text) to authenticated;

-- followup_action: add serialized same-key/same-hash replay contract around the preserved implementation.
alter function app.followup_action(uuid,uuid,text,timestamptz,text,int,text) rename to followup_action_v1_unhardened;
revoke all on function app.followup_action_v1_unhardened(uuid,uuid,text,timestamptz,text,int,text) from public,anon,authenticated;
create or replace function app.followup_action(p_org uuid,p_followup uuid,p_action text,p_due timestamptz,p_reason text,p_expected_version int,p_key text) returns jsonb
language plpgsql security definer set search_path=public,app as $$
declare actor uuid; h text; result jsonb; replay jsonb; begin
  actor:=app.require_permission(p_org,case p_action when 'DONE' then 'followup.complete' when 'CANCEL' then 'followup.cancel' when 'SNOOZE' then 'followup.update' else 'followup.update' end); h:=app.command_hash(jsonb_build_array(p_org,p_followup,p_action,p_due,p_reason,p_expected_version)); perform app.command_lock(p_org,'followup.action',p_key);
  replay:=app.idempotency_existing(p_org,actor,'followup.action',p_key,h);
  if replay is not null then return replay; end if;
  result:=app.followup_action_v1_unhardened(p_org,p_followup,p_action,p_due,p_reason,p_expected_version,p_key);
  perform app.audit(p_org,actor,'followup.action','FOLLOW_UP',p_followup,null,case when pg_typeof(result)::text='jsonb' then result else jsonb_build_object('result_id',result) end);
  perform app.emit_event(p_org,actor,'followup.action','FOLLOW_UP',p_followup,case when pg_typeof(result)::text='jsonb' then result else jsonb_build_object('result_id',result) end,p_key||':contract');
  perform app.idempotency_commit(p_org,actor,'followup.action',p_key,h,result); return result; end $$;
grant execute on function app.followup_action(uuid,uuid,text,timestamptz,text,int,text) to authenticated;

-- update_recurring_rule: add serialized same-key/same-hash replay contract around the preserved implementation.
alter function app.update_recurring_rule(uuid,uuid,int,text,int,time,text,date,date,jsonb,text) rename to update_recurring_rule_v1_unhardened;
revoke all on function app.update_recurring_rule_v1_unhardened(uuid,uuid,int,text,int,time,text,date,date,jsonb,text) from public,anon,authenticated;
create or replace function app.update_recurring_rule(p_org uuid,p_rule uuid,p_expected_version int,p_type text,p_interval int,p_local_time time,p_timezone text,p_starts date,p_ends date,p_template jsonb,p_key text) returns jsonb
language plpgsql security definer set search_path=public,app as $$
declare actor uuid; h text; result jsonb; replay jsonb; begin
  actor:=app.require_permission(p_org,'recurring.manage'); h:=app.command_hash(jsonb_build_array(p_org,p_rule,p_expected_version,p_type,p_interval,p_local_time,p_timezone,p_starts,p_ends,p_template)); perform app.command_lock(p_org,'recurring.update',p_key);
  replay:=app.idempotency_existing(p_org,actor,'recurring.update',p_key,h);
  if replay is not null then return replay; end if;
  result:=app.update_recurring_rule_v1_unhardened(p_org,p_rule,p_expected_version,p_type,p_interval,p_local_time,p_timezone,p_starts,p_ends,p_template,p_key);
  perform app.activity(p_org,actor,'RECURRING_RULE',p_rule,'recurring.update','Command applied',jsonb_build_object('command','recurring.update'));
  perform app.emit_event(p_org,actor,'recurring.update','RECURRING_RULE',p_rule,case when pg_typeof(result)::text='jsonb' then result else jsonb_build_object('result_id',result) end,p_key||':contract');
  perform app.idempotency_commit(p_org,actor,'recurring.update',p_key,h,result); return result; end $$;
grant execute on function app.update_recurring_rule(uuid,uuid,int,text,int,time,text,date,date,jsonb,text) to authenticated;

-- skip_recurring_occurrence: add serialized same-key/same-hash replay contract around the preserved implementation.
alter function app.skip_recurring_occurrence(uuid,uuid,text,text) rename to skip_recurring_occurrence_v1_unhardened;
revoke all on function app.skip_recurring_occurrence_v1_unhardened(uuid,uuid,text,text) from public,anon,authenticated;
create or replace function app.skip_recurring_occurrence(p_org uuid,p_occ uuid,p_reason text,p_key text) returns jsonb
language plpgsql security definer set search_path=public,app as $$
declare actor uuid; h text; result jsonb; replay jsonb; begin
  actor:=app.require_permission(p_org,'recurring.manage'); h:=app.command_hash(jsonb_build_array(p_org,p_occ,p_reason)); perform app.command_lock(p_org,'recurring.skip',p_key);
  replay:=app.idempotency_existing(p_org,actor,'recurring.skip',p_key,h);
  if replay is not null then return replay; end if;
  result:=app.skip_recurring_occurrence_v1_unhardened(p_org,p_occ,p_reason,p_key);
  perform app.activity(p_org,actor,'RECURRING_OCCURRENCE',p_occ,'recurring.skip','Command applied',jsonb_build_object('command','recurring.skip'));
  perform app.audit(p_org,actor,'recurring.skip','RECURRING_OCCURRENCE',p_occ,null,case when pg_typeof(result)::text='jsonb' then result else jsonb_build_object('result_id',result) end);
  perform app.idempotency_commit(p_org,actor,'recurring.skip',p_key,h,result); return result; end $$;
grant execute on function app.skip_recurring_occurrence(uuid,uuid,text,text) to authenticated;

-- deactivate_recurring_rule: add serialized same-key/same-hash replay contract around the preserved implementation.
alter function app.deactivate_recurring_rule(uuid,uuid,text,text) rename to deactivate_recurring_rule_v1_unhardened;
revoke all on function app.deactivate_recurring_rule_v1_unhardened(uuid,uuid,text,text) from public,anon,authenticated;
create or replace function app.deactivate_recurring_rule(p_org uuid,p_rule uuid,p_reason text,p_key text) returns jsonb
language plpgsql security definer set search_path=public,app as $$
declare actor uuid; h text; result jsonb; replay jsonb; begin
  actor:=app.require_permission(p_org,'recurring.manage'); h:=app.command_hash(jsonb_build_array(p_org,p_rule,p_reason)); perform app.command_lock(p_org,'recurring.deactivate',p_key);
  replay:=app.idempotency_existing(p_org,actor,'recurring.deactivate',p_key,h);
  if replay is not null then return replay; end if;
  result:=app.deactivate_recurring_rule_v1_unhardened(p_org,p_rule,p_reason,p_key);
  perform app.audit(p_org,actor,'recurring.deactivate','RECURRING_RULE',p_rule,null,case when pg_typeof(result)::text='jsonb' then result else jsonb_build_object('result_id',result) end);
  perform app.emit_event(p_org,actor,'recurring.deactivate','RECURRING_RULE',p_rule,case when pg_typeof(result)::text='jsonb' then result else jsonb_build_object('result_id',result) end,p_key||':contract');
  perform app.idempotency_commit(p_org,actor,'recurring.deactivate',p_key,h,result); return result; end $$;
grant execute on function app.deactivate_recurring_rule(uuid,uuid,text,text) to authenticated;

-- invite_member: add serialized same-key/same-hash replay contract around the preserved implementation.
alter function app.invite_member(uuid,text,uuid,text) rename to invite_member_v1_unhardened;
revoke all on function app.invite_member_v1_unhardened(uuid,text,uuid,text) from public,anon,authenticated;
create or replace function app.invite_member(p_org uuid,p_email text,p_role uuid,p_key text) returns uuid
language plpgsql security definer set search_path=public,app as $$
declare actor uuid; h text; result uuid; replay jsonb; begin
  actor:=app.require_permission(p_org,'member.invite'); h:=app.command_hash(jsonb_build_array(p_org,p_email,p_role)); perform app.command_lock(p_org,'member.invite',p_key);
  replay:=app.idempotency_existing(p_org,actor,'member.invite',p_key,h);
  if replay is not null then return (replay->>'result_id')::uuid; end if;
  result:=app.invite_member_v1_unhardened(p_org,p_email,p_role,p_key);
  perform app.activity(p_org,actor,'MEMBER',p_org,'member.invite','Command applied',jsonb_build_object('command','member.invite'));
  perform app.emit_event(p_org,actor,'member.invite','MEMBER',p_org,case when pg_typeof(result)::text='jsonb' then result else jsonb_build_object('result_id',result) end,p_key||':contract');
  perform app.idempotency_commit(p_org,actor,'member.invite',p_key,h,jsonb_build_object('result_id',result)); return result; end $$;
grant execute on function app.invite_member(uuid,text,uuid,text) to authenticated;

-- update_member: add serialized same-key/same-hash replay contract around the preserved implementation.
alter function app.update_member(uuid,uuid,uuid,text,text) rename to update_member_v1_unhardened;
revoke all on function app.update_member_v1_unhardened(uuid,uuid,uuid,text,text) from public,anon,authenticated;
create or replace function app.update_member(p_org uuid,p_member uuid,p_role uuid,p_status text,p_key text) returns jsonb
language plpgsql security definer set search_path=public,app as $$
declare actor uuid; h text; result jsonb; replay jsonb; begin
  actor:=app.require_permission(p_org,'member.update'); h:=app.command_hash(jsonb_build_array(p_org,p_member,p_role,p_status)); perform app.command_lock(p_org,'member.update',p_key);
  replay:=app.idempotency_existing(p_org,actor,'member.update',p_key,h);
  if replay is not null then return replay; end if;
  result:=app.update_member_v1_unhardened(p_org,p_member,p_role,p_status,p_key);
  perform app.activity(p_org,actor,'MEMBER',p_member,'member.update','Command applied',jsonb_build_object('command','member.update'));
  perform app.emit_event(p_org,actor,'member.update','MEMBER',p_member,case when pg_typeof(result)::text='jsonb' then result else jsonb_build_object('result_id',result) end,p_key||':contract');
  perform app.idempotency_commit(p_org,actor,'member.update',p_key,h,result); return result; end $$;
grant execute on function app.update_member(uuid,uuid,uuid,text,text) to authenticated;

-- update_quote_draft: add serialized same-key/same-hash replay contract around the preserved implementation.
alter function app.update_quote_draft(uuid,uuid,int,timestamptz,text,bigint,jsonb,text) rename to update_quote_draft_v1_unhardened;
revoke all on function app.update_quote_draft_v1_unhardened(uuid,uuid,int,timestamptz,text,bigint,jsonb,text) from public,anon,authenticated;
create or replace function app.update_quote_draft(p_org uuid,p_quote uuid,p_expected_version int,p_expires timestamptz,p_terms text,p_document_discount bigint,p_items jsonb,p_key text) returns jsonb
language plpgsql security definer set search_path=public,app as $$
declare actor uuid; h text; result jsonb; replay jsonb; begin
  actor:=app.require_permission(p_org,'quote.update_draft'); h:=app.command_hash(jsonb_build_array(p_org,p_quote,p_expected_version,p_expires,p_terms,p_document_discount,p_items)); perform app.command_lock(p_org,'quote.update_draft',p_key);
  replay:=app.idempotency_existing(p_org,actor,'quote.update_draft',p_key,h);
  if replay is not null then return replay; end if;
  result:=app.update_quote_draft_v1_unhardened(p_org,p_quote,p_expected_version,p_expires,p_terms,p_document_discount,p_items,p_key);
  perform app.activity(p_org,actor,'QUOTE',p_quote,'quote.update_draft','Command applied',jsonb_build_object('command','quote.update_draft'));
  perform app.audit(p_org,actor,'quote.update_draft','QUOTE',p_quote,null,case when pg_typeof(result)::text='jsonb' then result else jsonb_build_object('result_id',result) end);
  perform app.emit_event(p_org,actor,'quote.update_draft','QUOTE',p_quote,case when pg_typeof(result)::text='jsonb' then result else jsonb_build_object('result_id',result) end,p_key||':contract');
  perform app.idempotency_commit(p_org,actor,'quote.update_draft',p_key,h,result); return result; end $$;
grant execute on function app.update_quote_draft(uuid,uuid,int,timestamptz,text,bigint,jsonb,text) to authenticated;

-- update_invoice_draft: add serialized same-key/same-hash replay contract around the preserved implementation.
alter function app.update_invoice_draft(uuid,uuid,int,timestamptz,text,bigint,jsonb,text) rename to update_invoice_draft_v1_unhardened;
revoke all on function app.update_invoice_draft_v1_unhardened(uuid,uuid,int,timestamptz,text,bigint,jsonb,text) from public,anon,authenticated;
create or replace function app.update_invoice_draft(p_org uuid,p_invoice uuid,p_expected_version int,p_due timestamptz,p_terms text,p_document_discount bigint,p_items jsonb,p_key text) returns jsonb
language plpgsql security definer set search_path=public,app as $$
declare actor uuid; h text; result jsonb; replay jsonb; begin
  actor:=app.require_permission(p_org,'invoice.update_draft'); h:=app.command_hash(jsonb_build_array(p_org,p_invoice,p_expected_version,p_due,p_terms,p_document_discount,p_items)); perform app.command_lock(p_org,'invoice.update_draft',p_key);
  replay:=app.idempotency_existing(p_org,actor,'invoice.update_draft',p_key,h);
  if replay is not null then return replay; end if;
  result:=app.update_invoice_draft_v1_unhardened(p_org,p_invoice,p_expected_version,p_due,p_terms,p_document_discount,p_items,p_key);
  perform app.activity(p_org,actor,'INVOICE',p_invoice,'invoice.update_draft','Command applied',jsonb_build_object('command','invoice.update_draft'));
  perform app.audit(p_org,actor,'invoice.update_draft','INVOICE',p_invoice,null,case when pg_typeof(result)::text='jsonb' then result else jsonb_build_object('result_id',result) end);
  perform app.emit_event(p_org,actor,'invoice.update_draft','INVOICE',p_invoice,case when pg_typeof(result)::text='jsonb' then result else jsonb_build_object('result_id',result) end,p_key||':contract');
  perform app.idempotency_commit(p_org,actor,'invoice.update_draft',p_key,h,result); return result; end $$;
grant execute on function app.update_invoice_draft(uuid,uuid,int,timestamptz,text,bigint,jsonb,text) to authenticated;

-- job_action: add serialized same-key/same-hash replay contract around the preserved implementation.
alter function app.job_action(uuid,uuid,text,text,int,text) rename to job_action_v1_unhardened;
revoke all on function app.job_action_v1_unhardened(uuid,uuid,text,text,int,text) from public,anon,authenticated;
create or replace function app.job_action(p_org uuid,p_job uuid,p_action text,p_reason text,p_expected_version int,p_key text) returns jsonb
language plpgsql security definer set search_path=public,app as $$
declare actor uuid; h text; result jsonb; replay jsonb; begin
  actor:=app.require_permission(p_org,case p_action when 'HOLD' then 'job.update' when 'RESUME' then 'job.update' when 'CANCEL' then 'job.cancel' when 'CANCEL_PRIVILEGED' then 'job.cancel_privileged' else 'job.update' end); h:=app.command_hash(jsonb_build_array(p_org,p_job,p_action,p_reason,p_expected_version)); perform app.command_lock(p_org,'job.action',p_key);
  replay:=app.idempotency_existing(p_org,actor,'job.action',p_key,h);
  if replay is not null then return replay; end if;
  result:=app.job_action_v1_unhardened(p_org,p_job,p_action,p_reason,p_expected_version,p_key);
  perform app.audit(p_org,actor,'job.action','JOB',p_job,null,case when pg_typeof(result)::text='jsonb' then result else jsonb_build_object('result_id',result) end);
  perform app.idempotency_commit(p_org,actor,'job.action',p_key,h,result); return result; end $$;
grant execute on function app.job_action(uuid,uuid,text,text,int,text) to authenticated;

-- fail_media: add serialized same-key/same-hash replay contract around the preserved implementation.
alter function app.fail_media(uuid,uuid,text,text) rename to fail_media_v1_unhardened;
revoke all on function app.fail_media_v1_unhardened(uuid,uuid,text,text) from public,anon,authenticated;
create or replace function app.fail_media(p_org uuid,p_media uuid,p_error text,p_key text) returns jsonb
language plpgsql security definer set search_path=public,app as $$
declare actor uuid; h text; result jsonb; replay jsonb; begin
  actor:=app.require_permission(p_org,'media.create'); h:=app.command_hash(jsonb_build_array(p_org,p_media,p_error)); perform app.command_lock(p_org,'media.fail',p_key);
  replay:=app.idempotency_existing(p_org,actor,'media.fail',p_key,h);
  if replay is not null then return replay; end if;
  result:=app.fail_media_v1_unhardened(p_org,p_media,p_error,p_key);
  perform app.audit(p_org,actor,'media.fail','MEDIA',p_media,null,case when pg_typeof(result)::text='jsonb' then result else jsonb_build_object('result_id',result) end);
  perform app.emit_event(p_org,actor,'media.fail','MEDIA',p_media,case when pg_typeof(result)::text='jsonb' then result else jsonb_build_object('result_id',result) end,p_key||':contract');
  perform app.idempotency_commit(p_org,actor,'media.fail',p_key,h,result); return result; end $$;
grant execute on function app.fail_media(uuid,uuid,text,text) to authenticated;

-- retry_media: add serialized same-key/same-hash replay contract around the preserved implementation.
alter function app.retry_media(uuid,uuid,text,bigint,text,text) rename to retry_media_v1_unhardened;
revoke all on function app.retry_media_v1_unhardened(uuid,uuid,text,bigint,text,text) from public,anon,authenticated;
create or replace function app.retry_media(p_org uuid,p_media uuid,p_expected_checksum text,p_size bigint,p_mime text,p_key text) returns jsonb
language plpgsql security definer set search_path=public,app as $$
declare actor uuid; h text; result jsonb; replay jsonb; begin
  actor:=app.require_permission(p_org,'media.retry'); h:=app.command_hash(jsonb_build_array(p_org,p_media,p_expected_checksum,p_size,p_mime)); perform app.command_lock(p_org,'media.retry',p_key);
  replay:=app.idempotency_existing(p_org,actor,'media.retry',p_key,h);
  if replay is not null then return replay; end if;
  result:=app.retry_media_v1_unhardened(p_org,p_media,p_expected_checksum,p_size,p_mime,p_key);
  perform app.activity(p_org,actor,'MEDIA',p_media,'media.retry','Command applied',jsonb_build_object('command','media.retry'));
  perform app.audit(p_org,actor,'media.retry','MEDIA',p_media,null,case when pg_typeof(result)::text='jsonb' then result else jsonb_build_object('result_id',result) end);
  perform app.emit_event(p_org,actor,'media.retry','MEDIA',p_media,case when pg_typeof(result)::text='jsonb' then result else jsonb_build_object('result_id',result) end,p_key||':contract');
  perform app.idempotency_commit(p_org,actor,'media.retry',p_key,h,result); return result; end $$;
grant execute on function app.retry_media(uuid,uuid,text,bigint,text,text) to authenticated;

-- update_organization_business: add serialized same-key/same-hash replay contract around the preserved implementation.
alter function app.update_organization_business(uuid,text,jsonb,text) rename to update_organization_business_v1_unhardened;
revoke all on function app.update_organization_business_v1_unhardened(uuid,text,jsonb,text) from public,anon,authenticated;
create or replace function app.update_organization_business(p_org uuid,p_name text,p_business_address jsonb,p_key text) returns jsonb
language plpgsql security definer set search_path=public,app as $$
declare actor uuid; h text; result jsonb; replay jsonb; begin
  actor:=app.require_permission(p_org,'organization.manage'); h:=app.command_hash(jsonb_build_array(p_org,p_name,p_business_address)); perform app.command_lock(p_org,'organization.business',p_key);
  replay:=app.idempotency_existing(p_org,actor,'organization.business',p_key,h);
  if replay is not null then return replay; end if;
  result:=app.update_organization_business_v1_unhardened(p_org,p_name,p_business_address,p_key);
  perform app.activity(p_org,actor,'ORGANIZATION',p_org,'organization.business','Command applied',jsonb_build_object('command','organization.business'));
  perform app.emit_event(p_org,actor,'organization.business','ORGANIZATION',p_org,case when pg_typeof(result)::text='jsonb' then result else jsonb_build_object('result_id',result) end,p_key||':contract');
  perform app.idempotency_commit(p_org,actor,'organization.business',p_key,h,result); return result; end $$;
grant execute on function app.update_organization_business(uuid,text,jsonb,text) to authenticated;

-- update_localization: add serialized same-key/same-hash replay contract around the preserved implementation.
alter function app.update_localization(uuid,text,text,text,text,text) rename to update_localization_v1_unhardened;
revoke all on function app.update_localization_v1_unhardened(uuid,text,text,text,text,text) from public,anon,authenticated;
create or replace function app.update_localization(p_org uuid,p_country text,p_currency text,p_timezone text,p_locale text,p_key text) returns jsonb
language plpgsql security definer set search_path=public,app as $$
declare actor uuid; h text; result jsonb; replay jsonb; begin
  actor:=app.require_permission(p_org,'settings.localization'); h:=app.command_hash(jsonb_build_array(p_org,p_country,p_currency,p_timezone,p_locale)); perform app.command_lock(p_org,'settings.localization',p_key);
  replay:=app.idempotency_existing(p_org,actor,'settings.localization',p_key,h);
  if replay is not null then return replay; end if;
  result:=app.update_localization_v1_unhardened(p_org,p_country,p_currency,p_timezone,p_locale,p_key);
  perform app.activity(p_org,actor,'ORGANIZATION',p_org,'settings.localization','Command applied',jsonb_build_object('command','settings.localization'));
  perform app.emit_event(p_org,actor,'settings.localization','ORGANIZATION',p_org,case when pg_typeof(result)::text='jsonb' then result else jsonb_build_object('result_id',result) end,p_key||':contract');
  perform app.idempotency_commit(p_org,actor,'settings.localization',p_key,h,result); return result; end $$;
grant execute on function app.update_localization(uuid,text,text,text,text,text) to authenticated;

-- update_workflow_settings: add serialized same-key/same-hash replay contract around the preserved implementation.
alter function app.update_workflow_settings(uuid,jsonb,text) rename to update_workflow_settings_v1_unhardened;
revoke all on function app.update_workflow_settings_v1_unhardened(uuid,jsonb,text) from public,anon,authenticated;
create or replace function app.update_workflow_settings(p_org uuid,p_workflow jsonb,p_key text) returns jsonb
language plpgsql security definer set search_path=public,app as $$
declare actor uuid; h text; result jsonb; replay jsonb; begin
  actor:=app.require_permission(p_org,'settings.workflow'); h:=app.command_hash(jsonb_build_array(p_org,p_workflow)); perform app.command_lock(p_org,'settings.workflow',p_key);
  replay:=app.idempotency_existing(p_org,actor,'settings.workflow',p_key,h);
  if replay is not null then return replay; end if;
  result:=app.update_workflow_settings_v1_unhardened(p_org,p_workflow,p_key);
  perform app.activity(p_org,actor,'ORGANIZATION',p_org,'settings.workflow','Command applied',jsonb_build_object('command','settings.workflow'));
  perform app.emit_event(p_org,actor,'settings.workflow','ORGANIZATION',p_org,case when pg_typeof(result)::text='jsonb' then result else jsonb_build_object('result_id',result) end,p_key||':contract');
  perform app.idempotency_commit(p_org,actor,'settings.workflow',p_key,h,result); return result; end $$;
grant execute on function app.update_workflow_settings(uuid,jsonb,text) to authenticated;

-- update_tax_profile: add serialized same-key/same-hash replay contract around the preserved implementation.
alter function app.update_tax_profile(uuid,text,int,text,text) rename to update_tax_profile_v1_unhardened;
revoke all on function app.update_tax_profile_v1_unhardened(uuid,text,int,text,text) from public,anon,authenticated;
create or replace function app.update_tax_profile(p_org uuid,p_name text,p_rate_ppm int,p_behavior text,p_key text) returns uuid
language plpgsql security definer set search_path=public,app as $$
declare actor uuid; h text; result uuid; replay jsonb; begin
  actor:=app.require_permission(p_org,'settings.tax'); h:=app.command_hash(jsonb_build_array(p_org,p_name,p_rate_ppm,p_behavior)); perform app.command_lock(p_org,'settings.tax',p_key);
  replay:=app.idempotency_existing(p_org,actor,'settings.tax',p_key,h);
  if replay is not null then return (replay->>'result_id')::uuid; end if;
  result:=app.update_tax_profile_v1_unhardened(p_org,p_name,p_rate_ppm,p_behavior,p_key);
  perform app.activity(p_org,actor,'ORGANIZATION',p_org,'settings.tax','Command applied',jsonb_build_object('command','settings.tax'));
  perform app.emit_event(p_org,actor,'settings.tax','ORGANIZATION',p_org,case when pg_typeof(result)::text='jsonb' then result else jsonb_build_object('result_id',result) end,p_key||':contract');
  perform app.idempotency_commit(p_org,actor,'settings.tax',p_key,h,jsonb_build_object('result_id',result)); return result; end $$;
grant execute on function app.update_tax_profile(uuid,text,int,text,text) to authenticated;

-- set_role_permission: add serialized same-key/same-hash replay contract around the preserved implementation.
alter function app.set_role_permission(uuid,uuid,text,boolean,text) rename to set_role_permission_v1_unhardened;
revoke all on function app.set_role_permission_v1_unhardened(uuid,uuid,text,boolean,text) from public,anon,authenticated;
create or replace function app.set_role_permission(p_org uuid,p_role uuid,p_permission text,p_allowed boolean,p_key text) returns jsonb
language plpgsql security definer set search_path=public,app as $$
declare actor uuid; h text; result jsonb; replay jsonb; begin
  actor:=app.require_permission(p_org,'role.assign'); h:=app.command_hash(jsonb_build_array(p_org,p_role,p_permission,p_allowed)); perform app.command_lock(p_org,'role.permission',p_key);
  replay:=app.idempotency_existing(p_org,actor,'role.permission',p_key,h);
  if replay is not null then return replay; end if;
  result:=app.set_role_permission_v1_unhardened(p_org,p_role,p_permission,p_allowed,p_key);
  perform app.activity(p_org,actor,'ROLE',p_role,'role.permission','Command applied',jsonb_build_object('command','role.permission'));
  perform app.emit_event(p_org,actor,'role.permission','ROLE',p_role,case when pg_typeof(result)::text='jsonb' then result else jsonb_build_object('result_id',result) end,p_key||':contract');
  perform app.idempotency_commit(p_org,actor,'role.permission',p_key,h,result); return result; end $$;
grant execute on function app.set_role_permission(uuid,uuid,text,boolean,text) to authenticated;

-- create_note: add serialized same-key/same-hash replay contract around the preserved implementation.
alter function app.create_note(uuid,text,uuid,text,text,text) rename to create_note_v1_unhardened;
revoke all on function app.create_note_v1_unhardened(uuid,text,uuid,text,text,text) from public,anon,authenticated;
create or replace function app.create_note(p_org uuid,p_entity_type text,p_entity_id uuid,p_body text,p_visibility text,p_key text) returns uuid
language plpgsql security definer set search_path=public,app as $$
declare actor uuid; h text; result uuid; replay jsonb; begin
  actor:=app.require_permission(p_org,'note.create'); h:=app.command_hash(jsonb_build_array(p_org,p_entity_type,p_entity_id,p_body,p_visibility)); perform app.command_lock(p_org,'note.create',p_key);
  replay:=app.idempotency_existing(p_org,actor,'note.create',p_key,h);
  if replay is not null then return (replay->>'result_id')::uuid; end if;
  result:=app.create_note_v1_unhardened(p_org,p_entity_type,p_entity_id,p_body,p_visibility,p_key);
  perform app.audit(p_org,actor,'note.create','NOTE',p_entity_id,null,case when pg_typeof(result)::text='jsonb' then result else jsonb_build_object('result_id',result) end);
  perform app.emit_event(p_org,actor,'note.create','NOTE',p_entity_id,case when pg_typeof(result)::text='jsonb' then result else jsonb_build_object('result_id',result) end,p_key||':contract');
  perform app.idempotency_commit(p_org,actor,'note.create',p_key,h,jsonb_build_object('result_id',result)); return result; end $$;
grant execute on function app.create_note(uuid,text,uuid,text,text,text) to authenticated;

-- respond_checklist: add serialized same-key/same-hash replay contract around the preserved implementation.
alter function app.respond_checklist(uuid,uuid,text,jsonb,text) rename to respond_checklist_v1_unhardened;
revoke all on function app.respond_checklist_v1_unhardened(uuid,uuid,text,jsonb,text) from public,anon,authenticated;
create or replace function app.respond_checklist(p_org uuid,p_checklist uuid,p_item_key text,p_value jsonb,p_key text) returns jsonb
language plpgsql security definer set search_path=public,app as $$
declare actor uuid; h text; result jsonb; replay jsonb; begin
  actor:=app.require_permission(p_org,'checklist.respond_assigned'); h:=app.command_hash(jsonb_build_array(p_org,p_checklist,p_item_key,p_value)); perform app.command_lock(p_org,'checklist.respond',p_key);
  replay:=app.idempotency_existing(p_org,actor,'checklist.respond',p_key,h);
  if replay is not null then return replay; end if;
  result:=app.respond_checklist_v1_unhardened(p_org,p_checklist,p_item_key,p_value,p_key);
  perform app.audit(p_org,actor,'checklist.respond','CHECKLIST',p_checklist,null,case when pg_typeof(result)::text='jsonb' then result else jsonb_build_object('result_id',result) end);
  perform app.emit_event(p_org,actor,'checklist.respond','CHECKLIST',p_checklist,case when pg_typeof(result)::text='jsonb' then result else jsonb_build_object('result_id',result) end,p_key||':contract');
  perform app.idempotency_commit(p_org,actor,'checklist.respond',p_key,h,result); return result; end $$;
grant execute on function app.respond_checklist(uuid,uuid,text,jsonb,text) to authenticated;

-- set_industry_template: add serialized same-key/same-hash replay contract around the preserved implementation.
alter function app.set_industry_template(uuid,uuid,text) rename to set_industry_template_v1_unhardened;
revoke all on function app.set_industry_template_v1_unhardened(uuid,uuid,text) from public,anon,authenticated;
create or replace function app.set_industry_template(p_org uuid,p_template_version uuid,p_key text) returns jsonb
language plpgsql security definer set search_path=public,app as $$
declare actor uuid; h text; result jsonb; replay jsonb; begin
  actor:=app.require_permission(p_org,'organization.manage'); h:=app.command_hash(jsonb_build_array(p_org,p_template_version)); perform app.command_lock(p_org,'organization.template',p_key);
  replay:=app.idempotency_existing(p_org,actor,'organization.template',p_key,h);
  if replay is not null then return replay; end if;
  result:=app.set_industry_template_v1_unhardened(p_org,p_template_version,p_key);
  perform app.activity(p_org,actor,'ORGANIZATION',p_org,'organization.template','Command applied',jsonb_build_object('command','organization.template'));
  perform app.emit_event(p_org,actor,'organization.template','ORGANIZATION',p_org,case when pg_typeof(result)::text='jsonb' then result else jsonb_build_object('result_id',result) end,p_key||':contract');
  perform app.idempotency_commit(p_org,actor,'organization.template',p_key,h,result); return result; end $$;
grant execute on function app.set_industry_template(uuid,uuid,text) to authenticated;

-- create_media: add serialized same-key/same-hash replay contract around the preserved implementation.
alter function app.create_media(uuid,text,uuid,text,text,text,text,bigint,text) rename to create_media_v1_unhardened;
revoke all on function app.create_media_v1_unhardened(uuid,text,uuid,text,text,text,text,bigint,text) from public,anon,authenticated;
create or replace function app.create_media(p_org uuid,p_parent_type text,p_parent_id uuid,p_category text,p_storage_key text,p_mime text,p_checksum text,p_size bigint,p_key text) returns uuid
language plpgsql security definer set search_path=public,app as $$
declare actor uuid; h text; result uuid; replay jsonb; begin
  actor:=app.require_permission(p_org,'media.create'); h:=app.command_hash(jsonb_build_array(p_org,p_parent_type,p_parent_id,p_category,p_storage_key,p_mime,p_checksum,p_size)); perform app.command_lock(p_org,'media.create',p_key);
  replay:=app.idempotency_existing(p_org,actor,'media.create',p_key,h);
  if replay is not null then return (replay->>'result_id')::uuid; end if;
  result:=app.create_media_v1_unhardened(p_org,p_parent_type,p_parent_id,p_category,p_storage_key,p_mime,p_checksum,p_size,p_key);
  perform app.activity(p_org,actor,'MEDIA',p_parent_id,'media.create','Command applied',jsonb_build_object('command','media.create'));
  perform app.audit(p_org,actor,'media.create','MEDIA',p_parent_id,null,case when pg_typeof(result)::text='jsonb' then result else jsonb_build_object('result_id',result) end);
  perform app.emit_event(p_org,actor,'media.create','MEDIA',p_parent_id,case when pg_typeof(result)::text='jsonb' then result else jsonb_build_object('result_id',result) end,p_key||':contract');
  perform app.idempotency_commit(p_org,actor,'media.create',p_key,h,jsonb_build_object('result_id',result)); return result; end $$;
grant execute on function app.create_media(uuid,text,uuid,text,text,text,text,bigint,text) to authenticated;

-- finalize_media: add serialized same-key/same-hash replay contract around the preserved implementation.
alter function app.finalize_media(uuid,uuid,text) rename to finalize_media_v1_unhardened;
revoke all on function app.finalize_media_v1_unhardened(uuid,uuid,text) from public,anon,authenticated;
create or replace function app.finalize_media(p_org uuid,p_media uuid,p_key text) returns jsonb
language plpgsql security definer set search_path=public,app as $$
declare actor uuid; h text; result jsonb; replay jsonb; begin
  actor:=app.require_permission(p_org,'media.finalize'); h:=app.command_hash(jsonb_build_array(p_org,p_media)); perform app.command_lock(p_org,'media.finalize',p_key);
  replay:=app.idempotency_existing(p_org,actor,'media.finalize',p_key,h);
  if replay is not null then return replay; end if;
  result:=app.finalize_media_v1_unhardened(p_org,p_media,p_key);
  perform app.audit(p_org,actor,'media.finalize','MEDIA',p_media,null,case when pg_typeof(result)::text='jsonb' then result else jsonb_build_object('result_id',result) end);
  perform app.idempotency_commit(p_org,actor,'media.finalize',p_key,h,result); return result; end $$;
grant execute on function app.finalize_media(uuid,uuid,text) to authenticated;
