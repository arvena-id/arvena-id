-- ARVENA P1 / Pro additive migration
set search_path=public,app;

-- Integration account boundary: every external event resolves one organization through one active integration.
create table if not exists public.integrations(
  id uuid primary key default gen_random_uuid(), organization_id uuid not null, provider text not null,
  status text not null default 'DISCONNECTED' check(status in('CONNECTED','DEGRADED','DISCONNECTED')),
  external_account_id text not null, display_name text, secret_reference text, webhook_key_id text,
  last_success_at timestamptz, last_error_at timestamptz, last_error_code text, metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(), version int not null default 1,
  unique(organization_id,id), unique(provider,external_account_id), foreign key(organization_id) references public.organizations(id) on delete restrict
);
create index if not exists integrations_org_provider_idx on public.integrations(organization_id,provider,status);
create trigger trg_integrations_updated before update on public.integrations for each row execute function app.set_updated_at();
create trigger trg_integrations_version before update on public.integrations for each row execute function app.bump_version();

create table if not exists public.external_events(
  id uuid primary key default gen_random_uuid(), organization_id uuid not null, integration_id uuid not null,
  provider text not null, external_event_id text not null, event_type text not null, payload_hash text not null,
  signature_verified boolean not null default false, payload_envelope jsonb not null default '{}'::jsonb,
  processing_status text not null default 'RECEIVED' check(processing_status in('RECEIVED','QUEUED','PROCESSING','PROCESSED','FAILED_RETRYABLE','FAILED_FINAL','IGNORED')),
  received_at timestamptz not null default now(), processed_at timestamptz, error_code text, retry_count int not null default 0,
  created_customer_id uuid, created_lead_id uuid,
  unique(organization_id,id), unique(organization_id,integration_id,external_event_id),
  foreign key(organization_id,integration_id) references public.integrations(organization_id,id) on delete restrict,
  foreign key(organization_id,created_customer_id) references public.customers(organization_id,id),
  foreign key(organization_id,created_lead_id) references public.leads(organization_id,id)
);
create index if not exists external_events_processing_idx on public.external_events(processing_status,received_at);

create table if not exists public.automation_rules(
  id uuid primary key default gen_random_uuid(), organization_id uuid not null, name text not null, trigger_type text not null,
  conditions jsonb not null default '[]'::jsonb, actions jsonb not null default '[]'::jsonb, active boolean not null default true,
  template_key text, advanced boolean not null default false, created_by uuid not null,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(), version int not null default 1,
  unique(organization_id,id), foreign key(organization_id,created_by) references public.organization_members(organization_id,id),
  foreign key(organization_id) references public.organizations(id) on delete restrict
);
create trigger trg_automation_rules_updated before update on public.automation_rules for each row execute function app.set_updated_at();
create trigger trg_automation_rules_version before update on public.automation_rules for each row execute function app.bump_version();

create table if not exists public.automation_runs(
  id uuid primary key default gen_random_uuid(), organization_id uuid not null, automation_rule_id uuid not null,
  trigger_event_id uuid not null, action_key text not null default 'main',
  status text not null default 'PENDING' check(status in('PENDING','SCHEDULED','RUNNING','SUCCEEDED','FAILED_RETRYABLE','FAILED_FINAL','CANCELLED')),
  scheduled_for timestamptz, started_at timestamptz, finished_at timestamptz, retry_count int not null default 0,
  lease_owner text, lease_expires_at timestamptz, next_attempt_at timestamptz, last_error text, result jsonb,
  idempotency_key text not null, created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  unique(organization_id,id), unique(organization_id,automation_rule_id,trigger_event_id,action_key), unique(organization_id,idempotency_key),
  foreign key(organization_id,automation_rule_id) references public.automation_rules(organization_id,id) on delete restrict,
  foreign key(trigger_event_id) references public.event_outbox(event_id) on delete restrict
);
create index if not exists automation_runs_due_idx on public.automation_runs(status,coalesce(next_attempt_at,scheduled_for,created_at));
create trigger trg_automation_runs_updated before update on public.automation_runs for each row execute function app.set_updated_at();

create table if not exists public.custom_field_definitions(
  id uuid primary key default gen_random_uuid(), organization_id uuid not null, entity_type text not null check(entity_type in('CUSTOMER','LEAD','JOB','ASSET')),
  field_key text not null, label text not null, field_type text not null check(field_type in('TEXT','NUMBER','BOOLEAN','DATE','SELECT','MULTISELECT')),
  config jsonb not null default '{}'::jsonb, required boolean not null default false, active boolean not null default true,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(), version int not null default 1,
  unique(organization_id,id), unique(organization_id,entity_type,field_key), foreign key(organization_id) references public.organizations(id)
);
create trigger trg_custom_field_defs_updated before update on public.custom_field_definitions for each row execute function app.set_updated_at();
create trigger trg_custom_field_defs_version before update on public.custom_field_definitions for each row execute function app.bump_version();

create table if not exists public.custom_field_values(
  id uuid primary key default gen_random_uuid(), organization_id uuid not null, definition_id uuid not null, entity_id uuid not null, value jsonb not null,
  updated_by uuid not null, created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  unique(organization_id,id), unique(organization_id,definition_id,entity_id),
  foreign key(organization_id,definition_id) references public.custom_field_definitions(organization_id,id) on delete cascade,
  foreign key(organization_id,updated_by) references public.organization_members(organization_id,id)
);
create trigger trg_custom_field_values_updated before update on public.custom_field_values for each row execute function app.set_updated_at();

create table if not exists public.branded_document_settings(
  id uuid primary key default gen_random_uuid(), organization_id uuid not null, logo_media_id uuid, accent_hex text,
  quote_footer text, invoice_footer text, legal_name text, registration_number text,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(), version int not null default 1,
  unique(organization_id), unique(organization_id,id), foreign key(organization_id) references public.organizations(id)
);
create trigger trg_branded_doc_updated before update on public.branded_document_settings for each row execute function app.set_updated_at();
create trigger trg_branded_doc_version before update on public.branded_document_settings for each row execute function app.bump_version();

alter table public.recurring_rules add column if not exists advanced_config jsonb not null default '{}'::jsonb;
alter table public.recurring_rules add column if not exists automation_enabled boolean not null default false;

-- Pro capability keys.
with pv as (select id,plan_key from plan_versions where version=1)
insert into plan_entitlements(plan_version_id,feature_key,value_json)
select pv.id,x.key,x.value::jsonb from pv cross join lateral(values
 ('feature.integration_health',case when pv.plan_key='FREE' then 'false' else 'true' end),
 ('feature.recurring_advanced',case when pv.plan_key='FREE' then 'false' else 'true' end),
 ('feature.branded_documents',case when pv.plan_key='FREE' then 'false' else 'true' end),
 ('feature.team_performance',case when pv.plan_key='FREE' then 'false' else 'true' end),
 ('feature.reports_advanced',case when pv.plan_key='FREE' then 'false' else 'true' end),
 ('limit.messaging_credits',case when pv.plan_key='FREE' then '0' when pv.plan_key='PRO' then '1000' else '5000' end)
) x(key,value) on conflict(plan_version_id,feature_key) do update set value_json=excluded.value_json;

-- Add Pro permission keys to organization role profiles already created by onboarding.
create or replace function app.seed_phase_permissions(p_org uuid) returns void language plpgsql security definer set search_path=public,app as $$
begin
  insert into role_permissions(organization_id,role_id,permission_key,allowed)
  select p_org,r.id,p.key,true from roles r cross join lateral(values
    ('catalog.view'),('catalog.manage'),('custom_field.view'),('custom_field.manage'),('automation.view'),('automation.manage'),
    ('performance.view'),('report.advanced'),('document.branding.manage')) p(key)
  where r.organization_id=p_org and r.system_key in('OWNER','ADMIN')
  on conflict(organization_id,role_id,permission_key) do update set allowed=true;
  insert into role_permissions(organization_id,role_id,permission_key,allowed)
  select p_org,r.id,p.key,true from roles r cross join lateral(values('catalog.view'),('custom_field.view')) p(key)
  where r.organization_id=p_org and r.system_key in('SALES','SUPERVISOR','FINANCE')
  on conflict(organization_id,role_id,permission_key) do update set allowed=true;
end $$;

-- Re-seed when org roles already exist. New organization creation calls role template copy and then may call this helper from onboarding API.
do $$ declare o uuid; begin for o in select id from organizations loop perform app.seed_phase_permissions(o); end loop; end $$;

create or replace function app.upsert_integration(p_org uuid,p_provider text,p_external_account text,p_display text,p_secret_reference text,p_metadata jsonb,p_key text) returns uuid
language plpgsql security definer set search_path=public,app as $$
declare actor uuid:=app.require_permission(p_org,'integration.manage'); iid uuid; h text; replay jsonb;
begin
 if not app.feature_enabled(p_org,'feature.whatsapp_connection') then raise exception 'ARV-USAGE-6001 integration not entitled'; end if;
 h:=app.command_hash(jsonb_build_array(p_provider,p_external_account,p_display,p_metadata)); perform app.command_lock(p_org,'integration.upsert',p_key);
 replay:=app.idempotency_existing(p_org,actor,'integration.upsert',p_key,h); if replay is not null then return (replay->>'integration_id')::uuid; end if;
 insert into integrations(organization_id,provider,status,external_account_id,display_name,secret_reference,metadata)
 values(p_org,upper(p_provider),'CONNECTED',p_external_account,p_display,p_secret_reference,coalesce(p_metadata,'{}'))
 on conflict(provider,external_account_id) do update set display_name=excluded.display_name,secret_reference=excluded.secret_reference,metadata=excluded.metadata,status='CONNECTED',updated_at=now()
 returning id into iid;
 perform app.activity(p_org,actor,'ORGANIZATION',p_org,'integration.connected','Integration connected',jsonb_build_object('integration_id',iid,'provider',upper(p_provider)));
 perform app.emit_event(p_org,actor,'integration.connected','ORGANIZATION',p_org,jsonb_build_object('integration_id',iid,'provider',upper(p_provider)),p_key);
 perform app.idempotency_commit(p_org,actor,'integration.upsert',p_key,h,jsonb_build_object('integration_id',iid)); return iid;
end $$;

create or replace function app.receive_external_event(p_integration uuid,p_external_event_id text,p_event_type text,p_payload_hash text,p_signature_verified boolean,p_envelope jsonb) returns jsonb
language plpgsql security definer set search_path=public,app as $$
declare i integrations%rowtype; eid uuid; qid uuid;
begin
 select * into i from integrations where id=p_integration and status in('CONNECTED','DEGRADED') for update;
 if not found then raise exception 'ARV-WA-2001 integration not active'; end if;
 if not p_signature_verified then raise exception 'ARV-WA-2002 invalid webhook signature'; end if;
 insert into external_events(organization_id,integration_id,provider,external_event_id,event_type,payload_hash,signature_verified,payload_envelope,processing_status)
 values(i.organization_id,i.id,i.provider,p_external_event_id,p_event_type,p_payload_hash,true,coalesce(p_envelope,'{}'),'QUEUED')
 on conflict(organization_id,integration_id,external_event_id) do nothing returning id into eid;
 if eid is null then select id into eid from external_events where organization_id=i.organization_id and integration_id=i.id and external_event_id=p_external_event_id; return jsonb_build_object('external_event_id',eid,'duplicate',true); end if;
 insert into queue_jobs(organization_id,topic,task_reference,payload,task_dedupe_key) values(i.organization_id,'external_event',eid::text,jsonb_build_object('external_event_id',eid),'external_event:'||eid) returning id into qid;
 return jsonb_build_object('external_event_id',eid,'queue_job_id',qid,'duplicate',false);
end $$;

create or replace function app.process_whatsapp_inbound(p_external_event uuid,p_normalized_phone text,p_display_name text,p_summary text,p_create_lead boolean default true) returns jsonb
language plpgsql security definer set search_path=public,app as $$
declare e external_events%rowtype; c uuid; l uuid; nowid uuid:=gen_random_uuid();
begin
 select * into e from external_events where id=p_external_event for update; if not found or e.provider<>'WHATSAPP' then raise exception 'ARV-WA-2003 event not found'; end if;
 if e.processing_status='PROCESSED' then return jsonb_build_object('customer_id',e.created_customer_id,'lead_id',e.created_lead_id,'duplicate',true); end if;
 if not e.signature_verified then raise exception 'ARV-WA-2002 signature not verified'; end if;
 update external_events set processing_status='PROCESSING' where id=e.id;
 select id into c from customers where organization_id=e.organization_id and normalized_phone=p_normalized_phone and archived_at is null order by created_at limit 1;
 if c is null then
   c:=gen_random_uuid(); insert into customers(id,organization_id,type,name,raw_phone,normalized_phone,whatsapp_phone,source,status) values(c,e.organization_id,'PERSON',coalesce(nullif(p_display_name,''),p_normalized_phone),p_normalized_phone,p_normalized_phone,p_normalized_phone,'WHATSAPP','ACTIVE');
 end if;
 if p_create_lead then
   l:=gen_random_uuid(); insert into leads(id,organization_id,customer_id,title,description,status,temperature,source,currency_code) select l,e.organization_id,c,'WhatsApp request',p_summary,'NEW','WARM','WHATSAPP',o.currency_code from organizations o where o.id=e.organization_id;
 end if;
 insert into activities(organization_id,entity_type,entity_id,actor_id,event_type,summary,metadata) values(e.organization_id,'CUSTOMER',c,null,'whatsapp.inbound',coalesce(p_summary,'Inbound WhatsApp'),jsonb_build_object('external_event_id',e.id,'lead_id',l));
 update external_events set processing_status='PROCESSED',processed_at=now(),created_customer_id=c,created_lead_id=l where id=e.id;
 update integrations set last_success_at=now(),last_error_at=null,last_error_code=null,status='CONNECTED' where id=e.integration_id;
 return jsonb_build_object('customer_id',c,'lead_id',l,'duplicate',false);
exception when others then
 update external_events set processing_status='FAILED_RETRYABLE',error_code='ARV-WA-2099',retry_count=retry_count+1 where id=p_external_event;
 raise;
end $$;

create or replace function app.create_automation_rule(p_org uuid,p_name text,p_trigger text,p_conditions jsonb,p_actions jsonb,p_template_key text,p_key text) returns uuid
language plpgsql security definer set search_path=public,app as $$
declare actor uuid:=app.require_permission(p_org,'automation.manage'); rid uuid:=gen_random_uuid(); h text; replay jsonb;
begin if not app.feature_enabled(p_org,'feature.automation_templates') then raise exception 'ARV-USAGE-6001 automation not entitled'; end if;
 h:=app.command_hash(jsonb_build_array(p_name,p_trigger,p_conditions,p_actions,p_template_key)); perform app.command_lock(p_org,'automation.create',p_key); replay:=app.idempotency_existing(p_org,actor,'automation.create',p_key,h); if replay is not null then return (replay->>'rule_id')::uuid; end if;
 insert into automation_rules(id,organization_id,name,trigger_type,conditions,actions,template_key,created_by) values(rid,p_org,p_name,p_trigger,coalesce(p_conditions,'[]'),coalesce(p_actions,'[]'),p_template_key,actor);
 perform app.idempotency_commit(p_org,actor,'automation.create',p_key,h,jsonb_build_object('rule_id',rid)); return rid; end $$;

create or replace function app.enqueue_automation_for_event(p_event_id uuid) returns int
language plpgsql security definer set search_path=public,app as $$
declare ev event_outbox%rowtype; r automation_rules%rowtype; created int:=0; runid uuid;
begin
 select * into ev from event_outbox where event_id=p_event_id; if not found then return 0; end if;
 for r in select * from automation_rules where organization_id=ev.organization_id and active and trigger_type=ev.event_type loop
   insert into automation_runs(organization_id,automation_rule_id,trigger_event_id,status,scheduled_for,idempotency_key)
   values(ev.organization_id,r.id,p_event_id,case when exists(select 1 from jsonb_array_elements(r.actions) a where coalesce((a->>'delay_seconds')::int,0)>0) then 'SCHEDULED' else 'PENDING' end,
          case when exists(select 1 from jsonb_array_elements(r.actions) a where coalesce((a->>'delay_seconds')::int,0)>0) then now()+make_interval(secs=coalesce((r.actions->0->>'delay_seconds')::int,0)) else now() end,
          'automation:'||r.id||':'||p_event_id)
   on conflict(organization_id,automation_rule_id,trigger_event_id,action_key) do nothing returning id into runid;
   if runid is not null then created:=created+1; insert into queue_jobs(organization_id,topic,task_reference,payload,task_dedupe_key,next_attempt_at) values(ev.organization_id,'automation',runid::text,jsonb_build_object('automation_run_id',runid),'automation:'||runid,coalesce((select scheduled_for from automation_runs where id=runid),now())) on conflict do nothing; end if;
 end loop; return created;
end $$;

create or replace function app.claim_automation_runs(p_worker text,p_limit int default 10) returns setof automation_runs
language plpgsql security definer set search_path=public,app as $$ begin
 return query with c as (select id from automation_runs where status in('PENDING','SCHEDULED','FAILED_RETRYABLE') and coalesce(next_attempt_at,scheduled_for,created_at)<=now() and (lease_expires_at is null or lease_expires_at<now()) order by coalesce(next_attempt_at,scheduled_for,created_at) for update skip locked limit greatest(1,least(p_limit,100)))
 update automation_runs a set status='RUNNING',started_at=coalesce(started_at,now()),lease_owner=p_worker,lease_expires_at=now()+interval '60 seconds',retry_count=case when a.status='FAILED_RETRYABLE' then retry_count+1 else retry_count end from c where a.id=c.id returning a.*;
end $$;

-- Custom field target validation, without arbitrary schema mutation.
create or replace function app.custom_field_target_exists(p_org uuid,p_type text,p_id uuid) returns boolean language sql stable security definer set search_path=public,app as $$ select app.entity_belongs_to_org(p_org,p_type,p_id) $$;
create or replace function app.set_custom_field_value(p_org uuid,p_definition uuid,p_entity uuid,p_value jsonb,p_key text) returns jsonb
language plpgsql security definer set search_path=public,app as $$
declare actor uuid:=app.require_permission(p_org,'custom_field.manage'); d custom_field_definitions%rowtype; h text; replay jsonb;
begin if not app.feature_enabled(p_org,'feature.custom_fields') then raise exception 'ARV-USAGE-6001 custom fields not entitled'; end if; select * into d from custom_field_definitions where organization_id=p_org and id=p_definition and active; if not found then raise exception 'ARV-VALIDATION-1001 field definition missing'; end if; if not app.custom_field_target_exists(p_org,d.entity_type,p_entity) then raise exception 'ARV-TENANT-1003 field target mismatch'; end if;
 h:=app.command_hash(jsonb_build_array(p_definition,p_entity,p_value)); perform app.command_lock(p_org,'custom_field.set',p_key); replay:=app.idempotency_existing(p_org,actor,'custom_field.set',p_key,h); if replay is not null then return replay; end if;
 insert into custom_field_values(organization_id,definition_id,entity_id,value,updated_by) values(p_org,p_definition,p_entity,p_value,actor) on conflict(organization_id,definition_id,entity_id) do update set value=excluded.value,updated_by=excluded.updated_by,updated_at=now();
 perform app.idempotency_commit(p_org,actor,'custom_field.set',p_key,h,jsonb_build_object('definition_id',p_definition,'entity_id',p_entity)); return jsonb_build_object('definition_id',p_definition,'entity_id',p_entity); end $$;

-- RLS / safe views.
do $$ declare t text; begin foreach t in array array['integrations','external_events','automation_rules','automation_runs','custom_field_definitions','custom_field_values','branded_document_settings'] loop execute format('alter table public.%I enable row level security',t); execute format('alter table public.%I force row level security',t); end loop; end $$;
create policy integrations_select on integrations for select using(app.has_permission(organization_id,'integration.manage'));
create policy automation_rules_select on automation_rules for select using(app.has_permission(organization_id,'automation.view'));
create policy automation_rules_manage on automation_rules for all using(app.has_permission(organization_id,'automation.manage')) with check(app.has_permission(organization_id,'automation.manage'));
create policy automation_runs_select on automation_runs for select using(app.has_permission(organization_id,'automation.view'));
create policy custom_field_defs_select on custom_field_definitions for select using(app.has_permission(organization_id,'custom_field.view'));
create policy custom_field_defs_manage on custom_field_definitions for all using(app.has_permission(organization_id,'custom_field.manage')) with check(app.has_permission(organization_id,'custom_field.manage'));
create policy custom_field_values_select on custom_field_values for select using(exists(select 1 from custom_field_definitions d where d.organization_id=custom_field_values.organization_id and d.id=definition_id and app.has_permission(d.organization_id,'custom_field.view') and app.can_access_entity(d.organization_id,d.entity_type,entity_id)));
create policy custom_field_values_manage on custom_field_values for all using(app.has_permission(organization_id,'custom_field.manage')) with check(app.has_permission(organization_id,'custom_field.manage'));
create policy branded_doc_select on branded_document_settings for select using(app.current_member_id(organization_id) is not null);
create policy branded_doc_manage on branded_document_settings for all using(app.has_permission(organization_id,'document.branding.manage')) with check(app.has_permission(organization_id,'document.branding.manage'));
-- external_events has no client write/read policy by design; health is exposed through integration health only.

create policy service_catalog_manage_p1 on service_catalog for all using(app.has_permission(organization_id,'catalog.manage') and app.feature_enabled(organization_id,'feature.service_catalog_manage')) with check(app.has_permission(organization_id,'catalog.manage') and app.feature_enabled(organization_id,'feature.service_catalog_manage'));

create or replace view public.integration_health_v with(security_invoker=true) as
select organization_id,id,provider,status,external_account_id,display_name,last_success_at,last_error_at,last_error_code,updated_at from integrations;
create or replace view public.automation_list_v with(security_invoker=true) as
select r.organization_id,r.id,r.name,r.trigger_type,r.active,r.template_key,r.updated_at,count(a.id) runs,count(a.id) filter(where a.status='FAILED_FINAL') failures from automation_rules r left join automation_runs a on a.organization_id=r.organization_id and a.automation_rule_id=r.id group by r.organization_id,r.id;
create or replace view public.team_performance_v with(security_invoker=true) as
select m.organization_id,m.id member_id,coalesce(up.display_name,au.email) display_name,r.system_key role,
 count(distinct va.visit_id) assigned_visits,count(distinct va.visit_id) filter(where v.status='COMPLETED') completed_visits,
 count(distinct f.id) filter(where f.status='DONE') completed_followups
from organization_members m join auth.users au on au.id=m.user_id left join user_profiles up on up.user_id=m.user_id join roles r on r.organization_id=m.organization_id and r.id=m.role_id
left join visit_assignments va on va.organization_id=m.organization_id and va.member_id=m.id and va.removed_at is null left join visits v on v.organization_id=va.organization_id and v.id=va.visit_id left join follow_ups f on f.organization_id=m.organization_id and f.assigned_to=m.id
group by m.organization_id,m.id,up.display_name,au.email,r.system_key;

revoke all on function app.receive_external_event(uuid,text,text,text,boolean,jsonb),app.process_whatsapp_inbound(uuid,text,text,text,boolean),app.enqueue_automation_for_event(uuid),app.claim_automation_runs(text,int) from public,anon,authenticated;
grant execute on function app.receive_external_event(uuid,text,text,text,boolean,jsonb),app.process_whatsapp_inbound(uuid,text,text,text,boolean),app.enqueue_automation_for_event(uuid),app.claim_automation_runs(text,int) to service_role;
grant execute on function app.upsert_integration(uuid,text,text,text,text,jsonb,text),app.create_automation_rule(uuid,text,text,jsonb,jsonb,text,text),app.set_custom_field_value(uuid,uuid,uuid,jsonb,text) to authenticated;

-- explicit RLS declarations for static verification
alter table public.integrations enable row level security;
alter table public.external_events enable row level security;
alter table public.automation_rules enable row level security;
alter table public.automation_runs enable row level security;
alter table public.custom_field_definitions enable row level security;
alter table public.custom_field_values enable row level security;
alter table public.branded_document_settings enable row level security;

-- ===== final P1 command/security hardening =====
-- Keep role templates current so organizations created after this migration receive P1 permissions too.
update system_role_templates s set permissions=(
  select coalesce(jsonb_agg(v order by v),'[]'::jsonb) from (
    select distinct v from jsonb_array_elements_text(s.permissions || case s.system_key
      when 'OWNER' then '["catalog.view","catalog.manage","custom_field.view","custom_field.manage","automation.view","automation.manage","performance.view","report.advanced","document.branding.manage"]'::jsonb
      when 'ADMIN' then '["catalog.view","catalog.manage","custom_field.view","custom_field.manage","automation.view","automation.manage","performance.view","report.advanced","document.branding.manage"]'::jsonb
      when 'SALES' then '["catalog.view","custom_field.view"]'::jsonb
      when 'SUPERVISOR' then '["catalog.view","custom_field.view"]'::jsonb
      when 'FINANCE' then '["catalog.view","custom_field.view"]'::jsonb
      else '[]'::jsonb end) v
  ) q
) where s.version=1;

-- Provider account identity is globally unique and cannot be reassigned by another tenant through UPSERT.
create or replace function app.upsert_integration(p_org uuid,p_provider text,p_external_account text,p_display text,p_secret_reference text,p_metadata jsonb,p_key text) returns uuid
language plpgsql security definer set search_path=public,app as $$
declare actor uuid:=app.require_permission(p_org,'integration.manage'); iid uuid; existing integrations%rowtype; h text; replay jsonb;
begin
 if not app.feature_enabled(p_org,'feature.whatsapp_connection') then raise exception 'ARV-USAGE-6001 integration not entitled'; end if;
 if upper(p_provider)<>'WHATSAPP' then raise exception 'ARV-INTEGRATION-2001 unsupported provider'; end if;
 h:=app.command_hash(jsonb_build_array(upper(p_provider),p_external_account,p_display,p_secret_reference,coalesce(p_metadata,'{}'::jsonb))); perform app.command_lock(p_org,'integration.upsert:'||upper(p_provider)||':'||p_external_account,p_key);
 replay:=app.idempotency_existing(p_org,actor,'integration.upsert',p_key,h); if replay is not null then return (replay->>'integration_id')::uuid; end if;
 select * into existing from integrations where provider=upper(p_provider) and external_account_id=p_external_account for update;
 if found and existing.organization_id<>p_org then raise exception 'ARV-TENANT-1003 provider account belongs to another organization'; end if;
 if found then update integrations set display_name=p_display,secret_reference=p_secret_reference,metadata=coalesce(p_metadata,'{}'),status='CONNECTED',last_error_at=null,last_error_code=null where id=existing.id returning id into iid;
 else insert into integrations(organization_id,provider,status,external_account_id,display_name,secret_reference,metadata) values(p_org,upper(p_provider),'CONNECTED',p_external_account,p_display,p_secret_reference,coalesce(p_metadata,'{}')) returning id into iid; end if;
 perform app.activity(p_org,actor,'ORGANIZATION',p_org,'integration.connected','Integration connected',jsonb_build_object('integration_id',iid,'provider',upper(p_provider)));
 perform app.emit_event(p_org,actor,'integration.connected','ORGANIZATION',p_org,jsonb_build_object('integration_id',iid,'provider',upper(p_provider)),p_key);
 perform app.idempotency_commit(p_org,actor,'integration.upsert',p_key,h,jsonb_build_object('integration_id',iid)); return iid;
end $$;

create or replace function app.disconnect_integration(p_org uuid,p_integration uuid,p_reason text,p_key text) returns jsonb
language plpgsql security definer set search_path=public,app as $$
declare actor uuid:=app.require_permission(p_org,'integration.manage'); i integrations%rowtype; h text; replay jsonb; result jsonb;
begin
 h:=app.command_hash(jsonb_build_array(p_integration,p_reason)); perform app.command_lock(p_org,'integration.disconnect:'||p_integration::text,p_key); replay:=app.idempotency_existing(p_org,actor,'integration.disconnect',p_key,h); if replay is not null then return replay; end if;
 select * into i from integrations where organization_id=p_org and id=p_integration for update; if not found then raise exception 'ARV-INTEGRATION-2002 integration unavailable'; end if;
 update integrations set status='DISCONNECTED',last_error_at=now(),last_error_code='MANUAL_DISCONNECT' where id=i.id;
 result:=jsonb_build_object('integration_id',i.id,'status','DISCONNECTED'); perform app.activity(p_org,actor,'ORGANIZATION',p_org,'integration.disconnected','Integration disconnected',jsonb_build_object('integration_id',i.id,'reason',p_reason)); perform app.idempotency_commit(p_org,actor,'integration.disconnect',p_key,h,result); return result;
end $$;

create or replace function app.create_service_catalog_item(p_org uuid,p_type text,p_name text,p_description text,p_unit text,p_price bigint,p_currency text,p_tax_behavior text,p_key text) returns uuid
language plpgsql security definer set search_path=public,app as $$
declare actor uuid:=app.require_permission(p_org,'catalog.manage'); idv uuid:=gen_random_uuid(); h text; replay jsonb;
begin
 if not app.feature_enabled(p_org,'feature.service_catalog_manage') then raise exception 'ARV-USAGE-6001 Service Catalog not entitled'; end if;
 if trim(coalesce(p_name,''))='' or coalesce(p_price,0)<0 then raise exception 'ARV-VALIDATION-1001 invalid catalog item'; end if;
 h:=app.command_hash(jsonb_build_array(p_type,p_name,p_description,p_unit,p_price,p_currency,p_tax_behavior)); perform app.command_lock(p_org,'catalog.create',p_key); replay:=app.idempotency_existing(p_org,actor,'catalog.create',p_key,h); if replay is not null then return (replay->>'catalog_id')::uuid; end if;
 insert into service_catalog(id,organization_id,item_type,name,description,unit,unit_price_minor,currency_code,tax_behavior,active) values(idv,p_org,upper(coalesce(p_type,'SERVICE')),trim(p_name),p_description,p_unit,p_price,upper(p_currency),upper(coalesce(p_tax_behavior,'EXEMPT')),true);
 perform app.activity(p_org,actor,'ORGANIZATION',p_org,'catalog.created','Service Catalog item created',jsonb_build_object('catalog_id',idv)); perform app.idempotency_commit(p_org,actor,'catalog.create',p_key,h,jsonb_build_object('catalog_id',idv)); return idv;
end $$;

create or replace function app.update_service_catalog_item(p_org uuid,p_item uuid,p_expected_version int,p_name text,p_description text,p_unit text,p_price bigint,p_currency text,p_tax_behavior text,p_active boolean,p_key text) returns jsonb
language plpgsql security definer set search_path=public,app as $$
declare actor uuid:=app.require_permission(p_org,'catalog.manage'); s service_catalog%rowtype; h text; replay jsonb; result jsonb;
begin
 if not app.feature_enabled(p_org,'feature.service_catalog_manage') then raise exception 'ARV-USAGE-6001 Service Catalog not entitled'; end if;
 h:=app.command_hash(jsonb_build_array(p_item,p_expected_version,p_name,p_description,p_unit,p_price,p_currency,p_tax_behavior,p_active)); perform app.command_lock(p_org,'catalog.update:'||p_item::text,p_key); replay:=app.idempotency_existing(p_org,actor,'catalog.update',p_key,h); if replay is not null then return replay; end if;
 select * into s from service_catalog where organization_id=p_org and id=p_item for update; if not found or s.version<>p_expected_version then raise exception 'ARV-CONFLICT-1001 stale catalog item'; end if;
 update service_catalog set name=trim(p_name),description=p_description,unit=p_unit,unit_price_minor=p_price,currency_code=upper(p_currency),tax_behavior=upper(p_tax_behavior),active=p_active,archived_at=case when p_active then null else coalesce(archived_at,now()) end where organization_id=p_org and id=p_item;
 result:=jsonb_build_object('catalog_id',p_item,'version',p_expected_version+1,'active',p_active); perform app.idempotency_commit(p_org,actor,'catalog.update',p_key,h,result); return result;
end $$;

create or replace function app.create_custom_field_definition(p_org uuid,p_entity_type text,p_field_key text,p_label text,p_field_type text,p_config jsonb,p_required boolean,p_key text) returns uuid
language plpgsql security definer set search_path=public,app as $$
declare actor uuid:=app.require_permission(p_org,'custom_field.manage'); idv uuid:=gen_random_uuid(); h text; replay jsonb;
begin
 if not app.feature_enabled(p_org,'feature.custom_fields') then raise exception 'ARV-USAGE-6001 custom fields not entitled'; end if;
 if upper(p_entity_type) not in('CUSTOMER','LEAD','JOB','ASSET') or upper(p_field_type) not in('TEXT','NUMBER','BOOLEAN','DATE','SELECT','MULTISELECT') or p_field_key!~'^[a-z][a-z0-9_]{1,62}$' then raise exception 'ARV-VALIDATION-1001 invalid custom field definition'; end if;
 h:=app.command_hash(jsonb_build_array(upper(p_entity_type),p_field_key,p_label,upper(p_field_type),coalesce(p_config,'{}'),p_required)); perform app.command_lock(p_org,'custom_field.definition.create',p_key); replay:=app.idempotency_existing(p_org,actor,'custom_field.definition.create',p_key,h); if replay is not null then return (replay->>'definition_id')::uuid; end if;
 insert into custom_field_definitions(id,organization_id,entity_type,field_key,label,field_type,config,required) values(idv,p_org,upper(p_entity_type),p_field_key,p_label,upper(p_field_type),coalesce(p_config,'{}'),coalesce(p_required,false)); perform app.idempotency_commit(p_org,actor,'custom_field.definition.create',p_key,h,jsonb_build_object('definition_id',idv)); return idv;
end $$;

create or replace function app.update_automation_rule(p_org uuid,p_rule uuid,p_expected_version int,p_name text,p_conditions jsonb,p_actions jsonb,p_active boolean,p_key text) returns jsonb
language plpgsql security definer set search_path=public,app as $$
declare actor uuid:=app.require_permission(p_org,'automation.manage'); r automation_rules%rowtype; h text; replay jsonb; result jsonb;
begin
 h:=app.command_hash(jsonb_build_array(p_rule,p_expected_version,p_name,p_conditions,p_actions,p_active)); perform app.command_lock(p_org,'automation.update:'||p_rule::text,p_key); replay:=app.idempotency_existing(p_org,actor,'automation.update',p_key,h); if replay is not null then return replay; end if;
 select * into r from automation_rules where organization_id=p_org and id=p_rule for update; if not found or r.version<>p_expected_version then raise exception 'ARV-CONFLICT-1001 stale automation rule'; end if;
 update automation_rules set name=trim(p_name),conditions=coalesce(p_conditions,'[]'),actions=coalesce(p_actions,'[]'),active=p_active where id=p_rule;
 if not p_active then update automation_runs set status='CANCELLED',finished_at=now(),last_error='Rule disabled' where organization_id=p_org and automation_rule_id=p_rule and status in('PENDING','SCHEDULED','FAILED_RETRYABLE'); end if;
 result:=jsonb_build_object('rule_id',p_rule,'version',p_expected_version+1,'active',p_active); perform app.idempotency_commit(p_org,actor,'automation.update',p_key,h,result); return result;
end $$;

create or replace function app.automation_trigger_still_valid(p_event uuid) returns boolean language plpgsql stable security definer set search_path=public,app as $$
declare ev event_outbox%rowtype;
begin
 select * into ev from event_outbox where event_id=p_event; if not found then return false; end if;
 case ev.event_type
  when 'visit.scheduled' then return exists(select 1 from visits where organization_id=ev.organization_id and id=ev.entity_id and status='SCHEDULED');
  when 'visit.completed' then return exists(select 1 from visits where organization_id=ev.organization_id and id=ev.entity_id and status='COMPLETED');
  when 'job.completed' then return exists(select 1 from jobs where organization_id=ev.organization_id and id=ev.entity_id and status='COMPLETED');
  when 'quote.accepted' then return exists(select 1 from quotes where organization_id=ev.organization_id and id=ev.entity_id and status='ACCEPTED');
  when 'invoice.issued' then return exists(select 1 from invoices where organization_id=ev.organization_id and id=ev.entity_id and status in('ISSUED','PARTIALLY_PAID','OVERDUE'));
  when 'invoice.overdue' then return exists(select 1 from invoices where organization_id=ev.organization_id and id=ev.entity_id and status in('OVERDUE','PARTIALLY_PAID') and outstanding_minor>0 and due_at<now());
  else return true;
 end case;
end $$;

-- A durable service-role executor for template actions. Every action uses a deterministic receipt key.
create or replace function app.execute_automation_run(p_run uuid) returns jsonb language plpgsql security definer set search_path=public,app as $$
declare run automation_runs%rowtype; rule automation_rules%rowtype; ev event_outbox%rowtype; a jsonb; idx int:=0; action_key text; receipt idempotency_receipts%rowtype; target_customer uuid; assignee uuid; follow_id uuid; notification_id uuid;
begin
 select * into run from automation_runs where id=p_run for update; if not found then raise exception 'ARV-AUTOMATION-5001 run unavailable'; end if;
 if run.status='SUCCEEDED' then return coalesce(run.result,jsonb_build_object('run_id',run.id,'status','SUCCEEDED')); end if;
 if run.status not in('RUNNING','PENDING','SCHEDULED','FAILED_RETRYABLE') then return jsonb_build_object('run_id',run.id,'status',run.status); end if;
 select * into rule from automation_rules where organization_id=run.organization_id and id=run.automation_rule_id; select * into ev from event_outbox where event_id=run.trigger_event_id;
 if not found or not rule.active or not app.feature_enabled(run.organization_id,'feature.automation_templates') or not app.automation_trigger_still_valid(run.trigger_event_id) then update automation_runs set status='CANCELLED',finished_at=now(),last_error='Rule/entitlement/business state no longer valid',lease_owner=null,lease_expires_at=null where id=run.id; return jsonb_build_object('run_id',run.id,'status','CANCELLED'); end if;
 update automation_runs set status='RUNNING',started_at=coalesce(started_at,now()) where id=run.id;
 if ev.entity_type='CUSTOMER' then target_customer:=ev.entity_id;
 elsif ev.entity_type='LEAD' then select customer_id into target_customer from leads where organization_id=ev.organization_id and id=ev.entity_id;
 elsif ev.entity_type='QUOTE' then select customer_id into target_customer from quotes where organization_id=ev.organization_id and id=ev.entity_id;
 elsif ev.entity_type='JOB' then select customer_id into target_customer from jobs where organization_id=ev.organization_id and id=ev.entity_id;
 elsif ev.entity_type='VISIT' then select j.customer_id into target_customer from visits v join jobs j on j.organization_id=v.organization_id and j.id=v.job_id where v.organization_id=ev.organization_id and v.id=ev.entity_id;
 elsif ev.entity_type='INVOICE' then select customer_id into target_customer from invoices where organization_id=ev.organization_id and id=ev.entity_id; end if;
 for a in select * from jsonb_array_elements(rule.actions) loop
  idx:=idx+1; action_key:='automation:'||run.id||':'||idx;
  select * into receipt from idempotency_receipts where organization_id=run.organization_id and producer='automation' and scope='action' and idempotency_key=action_key;
  if found then continue; end if;
  if upper(coalesce(a->>'type',''))='CREATE_FOLLOWUP' then
    if target_customer is null then raise exception 'ARV-AUTOMATION-5002 follow-up target customer unavailable'; end if;
    assignee:=nullif(a->>'assigned_to','')::uuid; if assignee is null then select assigned_sales_id into assignee from customers where organization_id=run.organization_id and id=target_customer; end if; if assignee is null then select m.id into assignee from organization_members m join roles r on r.organization_id=m.organization_id and r.id=m.role_id where m.organization_id=run.organization_id and m.status='ACTIVE' and r.system_key='OWNER' order by m.joined_at nulls last limit 1; end if;
    follow_id:=gen_random_uuid(); insert into follow_ups(id,organization_id,customer_id,assigned_to,reason,due_at,timezone,status,notes) select follow_id,run.organization_id,target_customer,assignee,coalesce(a->>'reason','Automation follow-up'),now()+make_interval(days=>coalesce((a->>'due_days')::int,0)),o.timezone,'PENDING','Created by automation '||rule.name from organizations o where o.id=run.organization_id;
    insert into activities(organization_id,entity_type,entity_id,actor_id,event_type,summary,metadata) values(run.organization_id,'CUSTOMER',target_customer,null,'followup.created','Follow-up created by automation',jsonb_build_object('automation_run_id',run.id,'follow_up_id',follow_id));
  elsif upper(coalesce(a->>'type',''))='CREATE_NOTIFICATION' then
    assignee:=nullif(a->>'recipient_member_id','')::uuid; if assignee is null then select m.id into assignee from organization_members m join roles r on r.organization_id=m.organization_id and r.id=m.role_id where m.organization_id=run.organization_id and m.status='ACTIVE' and r.system_key='OWNER' order by m.joined_at nulls last limit 1; end if;
    notification_id:=gen_random_uuid(); insert into notifications(id,organization_id,recipient_member_id,type,title,body,entity_type,entity_id) values(notification_id,run.organization_id,assignee,'AUTOMATION',coalesce(a->>'title',rule.name),coalesce(a->>'body','Automation action ready'),ev.entity_type,ev.entity_id);
  elsif upper(coalesce(a->>'type',''))='QUEUE_WHATSAPP' then
    if target_customer is null or not exists(select 1 from customer_contact_preferences where organization_id=run.organization_id and customer_id=target_customer and channel='WHATSAPP' and status='OPTED_IN') then raise exception 'ARV-WA-2010 outbound WhatsApp consent missing'; end if;
    insert into queue_jobs(organization_id,topic,task_reference,payload,task_dedupe_key) values(run.organization_id,'whatsapp_outbound',run.id::text,jsonb_build_object('automation_run_id',run.id,'customer_id',target_customer,'template',a->>'template'),action_key) on conflict do nothing;
  else raise exception 'ARV-AUTOMATION-5003 unsupported action type'; end if;
  insert into idempotency_receipts(organization_id,producer,scope,idempotency_key,request_hash,result_reference) values(run.organization_id,'automation','action',action_key,app.command_hash(a),jsonb_build_object('ok',true)) on conflict do nothing;
 end loop;
 update automation_runs set status='SUCCEEDED',finished_at=now(),lease_owner=null,lease_expires_at=null,result=jsonb_build_object('actions',idx) where id=run.id;
 return jsonb_build_object('run_id',run.id,'status','SUCCEEDED','actions',idx);
exception when others then
 update automation_runs set status=case when retry_count>=4 then 'FAILED_FINAL' else 'FAILED_RETRYABLE' end,next_attempt_at=case when retry_count>=4 then null else now()+make_interval(secs=>least(3600,power(2,greatest(retry_count,0))::int*30)) end,last_error=left(sqlerrm,1000),lease_owner=null,lease_expires_at=null where id=p_run;
 raise;
end $$;

create or replace function app.update_branded_documents(p_org uuid,p_logo uuid,p_accent text,p_quote_footer text,p_invoice_footer text,p_legal_name text,p_registration text,p_key text) returns jsonb
language plpgsql security definer set search_path=public,app as $$
declare actor uuid:=app.require_permission(p_org,'document.branding.manage'); h text; replay jsonb; result jsonb;
begin
 if not app.feature_enabled(p_org,'feature.branded_documents') then raise exception 'ARV-USAGE-6001 branded documents not entitled'; end if;
 if p_accent is not null and p_accent!~'^#[0-9A-Fa-f]{6}$' then raise exception 'ARV-VALIDATION-1001 invalid accent color'; end if;
 h:=app.command_hash(jsonb_build_array(p_logo,p_accent,p_quote_footer,p_invoice_footer,p_legal_name,p_registration)); perform app.command_lock(p_org,'documents.branding',p_key); replay:=app.idempotency_existing(p_org,actor,'documents.branding',p_key,h); if replay is not null then return replay; end if;
 insert into branded_document_settings(organization_id,logo_media_id,accent_hex,quote_footer,invoice_footer,legal_name,registration_number) values(p_org,p_logo,p_accent,p_quote_footer,p_invoice_footer,p_legal_name,p_registration) on conflict(organization_id) do update set logo_media_id=excluded.logo_media_id,accent_hex=excluded.accent_hex,quote_footer=excluded.quote_footer,invoice_footer=excluded.invoice_footer,legal_name=excluded.legal_name,registration_number=excluded.registration_number;
 result:=jsonb_build_object('organization_id',p_org,'updated',true); perform app.idempotency_commit(p_org,actor,'documents.branding',p_key,h,result); return result;
end $$;

-- Sensitive connector secrets are never client-readable; the safe health projection is permission-filtered.
drop view if exists public.integration_health_v;
create view public.integration_health_v as select organization_id,id,provider,status,external_account_id,display_name,last_success_at,last_error_at,last_error_code,updated_at from integrations where app.has_permission(organization_id,'integration.manage');
revoke all on public.integrations from authenticated;
grant select on public.integration_health_v to authenticated;

-- Avoid requiring client access to auth.users for operational performance reports.
drop view if exists public.team_performance_v;
create view public.team_performance_v with(security_invoker=true) as
select m.organization_id,m.id member_id,coalesce(up.display_name,'Team member') display_name,r.system_key role,
 count(distinct va.visit_id) assigned_visits,count(distinct va.visit_id) filter(where v.status='COMPLETED') completed_visits,
 count(distinct f.id) filter(where f.status='DONE') completed_followups
from organization_members m left join user_profiles up on up.user_id=m.user_id join roles r on r.organization_id=m.organization_id and r.id=m.role_id
left join visit_assignments va on va.organization_id=m.organization_id and va.member_id=m.id and va.removed_at is null left join visits v on v.organization_id=va.organization_id and v.id=va.visit_id left join follow_ups f on f.organization_id=m.organization_id and f.assigned_to=m.id
where app.has_permission(m.organization_id,'performance.view')
group by m.organization_id,m.id,up.display_name,r.system_key;

grant execute on function app.disconnect_integration(uuid,uuid,text,text),app.create_service_catalog_item(uuid,text,text,text,text,bigint,text,text,text),app.update_service_catalog_item(uuid,uuid,int,text,text,text,bigint,text,text,boolean,text),app.create_custom_field_definition(uuid,text,text,text,text,jsonb,boolean,text),app.update_automation_rule(uuid,uuid,int,text,jsonb,jsonb,boolean,text),app.update_branded_documents(uuid,uuid,text,text,text,text,text,text) to authenticated;
revoke all on function app.execute_automation_run(uuid),app.automation_trigger_still_valid(uuid) from public,anon,authenticated;
grant execute on function app.execute_automation_run(uuid),app.automation_trigger_still_valid(uuid) to service_role;

-- v1.0.1 durability correction: automation failures must be committed as state,
-- not re-raised so the entire worker statement rolls the failure record back.
create or replace function app.execute_automation_run(p_run uuid) returns jsonb
language plpgsql security definer set search_path=public,app as $$
declare run automation_runs%rowtype; rule automation_rules%rowtype; ev event_outbox%rowtype; a jsonb; idx int:=0; action_key text; receipt idempotency_receipts%rowtype; target_customer uuid; assignee uuid; follow_id uuid; notification_id uuid; err text;
begin
 select * into run from automation_runs where id=p_run for update;
 if not found then return jsonb_build_object('run_id',p_run,'status','FAILED_FINAL','error','run unavailable'); end if;
 if run.status='SUCCEEDED' then return coalesce(run.result,jsonb_build_object('run_id',run.id,'status','SUCCEEDED')); end if;
 if run.status not in('RUNNING','PENDING','SCHEDULED','FAILED_RETRYABLE') then return jsonb_build_object('run_id',run.id,'status',run.status); end if;
 select * into rule from automation_rules where organization_id=run.organization_id and id=run.automation_rule_id;
 select * into ev from event_outbox where event_id=run.trigger_event_id;
 if rule.id is null or ev.id is null or not rule.active or not app.feature_enabled(run.organization_id,'feature.automation_templates') or not app.automation_trigger_still_valid(run.trigger_event_id) then
   update automation_runs set status='CANCELLED',finished_at=now(),last_error='Rule/entitlement/business state no longer valid',lease_owner=null,lease_expires_at=null where id=run.id;
   return jsonb_build_object('run_id',run.id,'status','CANCELLED');
 end if;
 update automation_runs set status='RUNNING',started_at=coalesce(started_at,now()) where id=run.id;
 begin
  if ev.entity_type='CUSTOMER' then target_customer:=ev.entity_id;
  elsif ev.entity_type='LEAD' then select customer_id into target_customer from leads where organization_id=ev.organization_id and id=ev.entity_id;
  elsif ev.entity_type='QUOTE' then select customer_id into target_customer from quotes where organization_id=ev.organization_id and id=ev.entity_id;
  elsif ev.entity_type='JOB' then select customer_id into target_customer from jobs where organization_id=ev.organization_id and id=ev.entity_id;
  elsif ev.entity_type='VISIT' then select j.customer_id into target_customer from visits v join jobs j on j.organization_id=v.organization_id and j.id=v.job_id where v.organization_id=ev.organization_id and v.id=ev.entity_id;
  elsif ev.entity_type='INVOICE' then select customer_id into target_customer from invoices where organization_id=ev.organization_id and id=ev.entity_id; end if;
  for a in select * from jsonb_array_elements(rule.actions) loop
   idx:=idx+1; action_key:='automation:'||run.id||':'||idx;
   select * into receipt from idempotency_receipts where organization_id=run.organization_id and producer='automation' and scope='action' and idempotency_key=action_key;
   if found then continue; end if;
   if upper(coalesce(a->>'type',''))='CREATE_FOLLOWUP' then
     if target_customer is null then raise exception 'ARV-AUTOMATION-5002 follow-up target customer unavailable'; end if;
     assignee:=nullif(a->>'assigned_to','')::uuid;
     if assignee is null then select assigned_sales_id into assignee from customers where organization_id=run.organization_id and id=target_customer; end if;
     if assignee is null then select m.id into assignee from organization_members m join roles r on r.organization_id=m.organization_id and r.id=m.role_id where m.organization_id=run.organization_id and m.status='ACTIVE' and r.system_key='OWNER' order by m.joined_at nulls last limit 1; end if;
     follow_id:=gen_random_uuid();
     insert into follow_ups(id,organization_id,customer_id,assigned_to,reason,due_at,timezone,status,notes)
     select follow_id,run.organization_id,target_customer,assignee,coalesce(a->>'reason','Automation follow-up'),now()+make_interval(days=>coalesce((a->>'due_days')::int,0)),o.timezone,'PENDING','Created by automation '||rule.name from organizations o where o.id=run.organization_id;
     insert into activities(organization_id,entity_type,entity_id,actor_id,event_type,summary,metadata) values(run.organization_id,'CUSTOMER',target_customer,null,'followup.created','Follow-up created by automation',jsonb_build_object('automation_run_id',run.id,'follow_up_id',follow_id));
   elsif upper(coalesce(a->>'type',''))='CREATE_NOTIFICATION' then
     assignee:=nullif(a->>'recipient_member_id','')::uuid;
     if assignee is null then select m.id into assignee from organization_members m join roles r on r.organization_id=m.organization_id and r.id=m.role_id where m.organization_id=run.organization_id and m.status='ACTIVE' and r.system_key='OWNER' order by m.joined_at nulls last limit 1; end if;
     notification_id:=gen_random_uuid();
     insert into notifications(id,organization_id,recipient_member_id,type,title,body,entity_type,entity_id) values(notification_id,run.organization_id,assignee,'AUTOMATION',coalesce(a->>'title',rule.name),coalesce(a->>'body','Automation action ready'),ev.entity_type,ev.entity_id);
   elsif upper(coalesce(a->>'type',''))='QUEUE_WHATSAPP' then
     if target_customer is null or not exists(select 1 from customer_contact_preferences where organization_id=run.organization_id and customer_id=target_customer and channel='WHATSAPP' and status='OPTED_IN') then raise exception 'ARV-WA-2010 outbound WhatsApp consent missing'; end if;
     insert into queue_jobs(organization_id,topic,task_reference,payload,task_dedupe_key) values(run.organization_id,'whatsapp_outbound',run.id::text,jsonb_build_object('automation_run_id',run.id,'customer_id',target_customer,'template',a->>'template'),action_key) on conflict do nothing;
   else raise exception 'ARV-AUTOMATION-5003 unsupported action type'; end if;
   insert into idempotency_receipts(organization_id,producer,scope,idempotency_key,request_hash,result_reference) values(run.organization_id,'automation','action',action_key,app.command_hash(a),jsonb_build_object('ok',true)) on conflict do nothing;
  end loop;
  update automation_runs set status='SUCCEEDED',finished_at=now(),lease_owner=null,lease_expires_at=null,result=jsonb_build_object('actions',idx),last_error=null where id=run.id;
  return jsonb_build_object('run_id',run.id,'status','SUCCEEDED','actions',idx);
 exception when others then
  err:=left(sqlerrm,1000);
  update automation_runs set retry_count=retry_count+1,status=case when retry_count+1>=5 then 'FAILED_FINAL' else 'FAILED_RETRYABLE' end,next_attempt_at=case when retry_count+1>=5 then null else now()+make_interval(secs=>least(3600,power(2,greatest(retry_count,0))::int*30)) end,last_error=err,lease_owner=null,lease_expires_at=null,finished_at=case when retry_count+1>=5 then now() else null end where id=run.id;
  return jsonb_build_object('run_id',run.id,'status',case when run.retry_count+1>=5 then 'FAILED_FINAL' else 'FAILED_RETRYABLE' end,'error',err);
 end;
end $$;

-- Team display names are denormalized on membership so performance queries do
-- not depend on broad access to auth or profile tables.
drop view if exists public.team_performance_v;
create view public.team_performance_v with(security_invoker=true) as
select m.organization_id,m.id member_id,coalesce(m.display_name,m.email,'Team member') display_name,r.system_key role,
 count(distinct va.visit_id) assigned_visits,count(distinct va.visit_id) filter(where v.status='COMPLETED') completed_visits,
 count(distinct f.id) filter(where f.status='DONE') completed_followups
from organization_members m join roles r on r.organization_id=m.organization_id and r.id=m.role_id
left join visit_assignments va on va.organization_id=m.organization_id and va.member_id=m.id and va.removed_at is null
left join visits v on v.organization_id=va.organization_id and v.id=va.visit_id
left join follow_ups f on f.organization_id=m.organization_id and f.assigned_to=m.id
where app.has_permission(m.organization_id,'performance.view')
group by m.organization_id,m.id,m.display_name,m.email,r.system_key;
grant select on public.team_performance_v to authenticated;


-- ===== FINAL P1 SECURITY/CORRECTNESS HARDENING =====
-- Provider/account binding is globally serialized so two tenants cannot race to claim one external account.
create or replace function app.upsert_integration(p_org uuid,p_provider text,p_external_account text,p_display text,p_secret_reference text,p_metadata jsonb,p_key text) returns uuid
language plpgsql security definer set search_path=public,app as $$
declare actor uuid:=app.require_permission(p_org,'integration.manage'); iid uuid; existing public.integrations%rowtype; h text; replay jsonb; provider_norm text:=upper(trim(p_provider)); account_norm text:=trim(p_external_account);
begin
 if not app.feature_enabled(p_org,'feature.whatsapp_connection') then raise exception 'ARV-USAGE-6001 integration not entitled'; end if;
 if provider_norm<>'WHATSAPP' or account_norm='' then raise exception 'ARV-INTEGRATION-2001 unsupported or invalid provider account'; end if;
 h:=app.command_hash(jsonb_build_array(provider_norm,account_norm,p_display,p_secret_reference,coalesce(p_metadata,'{}'::jsonb)));
 perform app.command_lock(p_org,'integration.upsert:'||provider_norm||':'||account_norm,p_key);
 replay:=app.idempotency_existing(p_org,actor,'integration.upsert',p_key,h); if replay is not null then return (replay->>'integration_id')::uuid; end if;
 perform pg_advisory_xact_lock(hashtextextended('integration-bind:'||provider_norm||':'||account_norm,2101));
 select * into existing from public.integrations where provider=provider_norm and external_account_id=account_norm for update;
 if found and existing.organization_id<>p_org then raise exception 'ARV-TENANT-2101 external account already bound to another organization'; end if;
 if found then
   update public.integrations set display_name=p_display,secret_reference=p_secret_reference,metadata=coalesce(p_metadata,'{}'),status='CONNECTED',last_error_at=null,last_error_code=null,updated_at=now()
    where organization_id=p_org and id=existing.id returning id into iid;
 else
   insert into public.integrations(organization_id,provider,status,external_account_id,display_name,secret_reference,metadata)
    values(p_org,provider_norm,'CONNECTED',account_norm,p_display,p_secret_reference,coalesce(p_metadata,'{}')) returning id into iid;
 end if;
 perform app.activity(p_org,actor,'ORGANIZATION',p_org,'integration.connected','Integration connected',jsonb_build_object('integration_id',iid,'provider',provider_norm));
 perform app.emit_event(p_org,actor,'integration.connected','ORGANIZATION',p_org,jsonb_build_object('integration_id',iid,'provider',provider_norm),p_key);
 perform app.idempotency_commit(p_org,actor,'integration.upsert',p_key,h,jsonb_build_object('integration_id',iid)); return iid;
end $$;

-- P1 least-privilege RPC grants. Default PUBLIC function execution was revoked by the canonical P0 baseline.
revoke execute on function app.seed_phase_permissions(uuid),app.custom_field_target_exists(uuid,text,uuid),app.automation_trigger_still_valid(uuid) from public,anon,authenticated;
revoke execute on function app.receive_external_event(uuid,text,text,text,boolean,jsonb),app.process_whatsapp_inbound(uuid,text,text,text,boolean),app.enqueue_automation_for_event(uuid),app.claim_automation_runs(text,int),app.execute_automation_run(uuid) from public,anon,authenticated;
grant execute on function app.receive_external_event(uuid,text,text,text,boolean,jsonb),app.process_whatsapp_inbound(uuid,text,text,text,boolean),app.enqueue_automation_for_event(uuid),app.claim_automation_runs(text,int),app.execute_automation_run(uuid) to service_role;
grant execute on function app.upsert_integration(uuid,text,text,text,text,jsonb,text),app.disconnect_integration(uuid,uuid,text,text),app.create_service_catalog_item(uuid,text,text,text,text,bigint,text,text,text),app.update_service_catalog_item(uuid,uuid,int,text,text,text,bigint,text,text,boolean,text),app.create_custom_field_definition(uuid,text,text,text,text,jsonb,boolean,text),app.set_custom_field_value(uuid,uuid,uuid,jsonb,text),app.create_automation_rule(uuid,text,text,jsonb,jsonb,text,text),app.update_automation_rule(uuid,uuid,int,text,jsonb,jsonb,boolean,text),app.update_branded_documents(uuid,uuid,text,text,text,text,text,text) to authenticated;
