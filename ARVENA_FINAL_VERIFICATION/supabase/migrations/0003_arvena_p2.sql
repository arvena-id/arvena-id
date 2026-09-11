-- ARVENA P2 / Ultra additive migration
set search_path=public,app;

create table if not exists public.branches(
  id uuid primary key default gen_random_uuid(), organization_id uuid not null, name text not null, country_code text not null,
  timezone text not null, address_json jsonb not null default '{}'::jsonb, active boolean not null default true,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(), version int not null default 1,
  unique(organization_id,id), unique(organization_id,name), foreign key(organization_id) references public.organizations(id) on delete restrict
);
create trigger trg_branches_updated before update on public.branches for each row execute function app.set_updated_at();
create trigger trg_branches_version before update on public.branches for each row execute function app.bump_version();
alter table public.organization_members add column if not exists branch_id uuid;
alter table public.jobs add column if not exists branch_id uuid;
alter table public.invoices add column if not exists branch_id uuid;
do $$ begin
 if not exists(select 1 from pg_constraint where conname='organization_members_branch_fk') then alter table public.organization_members add constraint organization_members_branch_fk foreign key(organization_id,branch_id) references public.branches(organization_id,id); end if;
 if not exists(select 1 from pg_constraint where conname='jobs_branch_fk') then alter table public.jobs add constraint jobs_branch_fk foreign key(organization_id,branch_id) references public.branches(organization_id,id); end if;
 if not exists(select 1 from pg_constraint where conname='invoices_branch_fk') then alter table public.invoices add constraint invoices_branch_fk foreign key(organization_id,branch_id) references public.branches(organization_id,id); end if;
end $$;
create index if not exists jobs_branch_status_idx on public.jobs(organization_id,branch_id,status,updated_at desc);
create index if not exists invoices_branch_status_idx on public.invoices(organization_id,branch_id,status,due_at);

create table if not exists public.approval_requests(
  id uuid primary key default gen_random_uuid(), organization_id uuid not null, entity_type text not null, entity_id uuid not null,
  action_type text not null, requested_by uuid not null, requested_payload jsonb not null default '{}'::jsonb,
  status text not null default 'PENDING' check(status in('PENDING','APPROVED','REJECTED','CANCELLED','EXPIRED')),
  required_approvals int not null default 1 check(required_approvals>0), idempotency_key text not null,
  created_at timestamptz not null default now(), expires_at timestamptz, decided_at timestamptz,
  unique(organization_id,id), unique(organization_id,idempotency_key), foreign key(organization_id,requested_by) references public.organization_members(organization_id,id)
);
create index if not exists approval_pending_idx on public.approval_requests(organization_id,status,created_at);
create table if not exists public.approval_decisions(
  id uuid primary key default gen_random_uuid(), organization_id uuid not null, approval_request_id uuid not null, approver_member_id uuid not null,
  decision text not null check(decision in('APPROVE','REJECT')), reason text, created_at timestamptz not null default now(),
  unique(organization_id,id), unique(organization_id,approval_request_id,approver_member_id),
  foreign key(organization_id,approval_request_id) references public.approval_requests(organization_id,id) on delete restrict,
  foreign key(organization_id,approver_member_id) references public.organization_members(organization_id,id)
);

create table if not exists public.sla_contracts(
  id uuid primary key default gen_random_uuid(), organization_id uuid not null, customer_id uuid not null, name text not null,
  response_minutes int, resolution_minutes int, business_hours jsonb not null default '{}'::jsonb, timezone text not null,
  starts_on date not null, ends_on date, active boolean not null default true, terms jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(), version int not null default 1,
  unique(organization_id,id), foreign key(organization_id,customer_id) references public.customers(organization_id,id)
);
create trigger trg_sla_contracts_updated before update on public.sla_contracts for each row execute function app.set_updated_at();
create trigger trg_sla_contracts_version before update on public.sla_contracts for each row execute function app.bump_version();
create table if not exists public.tickets(
  id uuid primary key default gen_random_uuid(), organization_id uuid not null, customer_id uuid not null, sla_contract_id uuid, job_id uuid,
  ticket_number text not null, title text not null, description text, priority text not null default 'NORMAL',
  status text not null default 'OPEN' check(status in('OPEN','ACKNOWLEDGED','IN_PROGRESS','WAITING','RESOLVED','CLOSED','CANCELLED')),
  opened_at timestamptz not null default now(), acknowledged_at timestamptz, resolved_at timestamptz, response_due_at timestamptz, resolution_due_at timestamptz,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(), version int not null default 1,
  unique(organization_id,id), unique(organization_id,ticket_number), foreign key(organization_id,customer_id) references public.customers(organization_id,id),
  foreign key(organization_id,sla_contract_id) references public.sla_contracts(organization_id,id), foreign key(organization_id,job_id) references public.jobs(organization_id,id)
);
create trigger trg_tickets_updated before update on public.tickets for each row execute function app.set_updated_at();
create trigger trg_tickets_version before update on public.tickets for each row execute function app.bump_version();
create index if not exists tickets_sla_due_idx on public.tickets(organization_id,status,response_due_at,resolution_due_at);

create table if not exists public.recurring_contracts(
  id uuid primary key default gen_random_uuid(), organization_id uuid not null, customer_id uuid not null, recurring_rule_id uuid not null,
  name text not null, starts_on date not null, ends_on date, billing_terms jsonb not null default '{}'::jsonb, sla_contract_id uuid,
  status text not null default 'ACTIVE' check(status in('DRAFT','ACTIVE','PAUSED','ENDED','CANCELLED')),
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(), version int not null default 1,
  unique(organization_id,id), unique(organization_id,recurring_rule_id), foreign key(organization_id,customer_id) references public.customers(organization_id,id),
  foreign key(organization_id,recurring_rule_id) references public.recurring_rules(organization_id,id), foreign key(organization_id,sla_contract_id) references public.sla_contracts(organization_id,id)
);
create trigger trg_recurring_contracts_updated before update on public.recurring_contracts for each row execute function app.set_updated_at();
create trigger trg_recurring_contracts_version before update on public.recurring_contracts for each row execute function app.bump_version();

create table if not exists public.asset_contracts(
  id uuid primary key default gen_random_uuid(), organization_id uuid not null, asset_id uuid not null, contract_type text not null,
  provider text, reference text, starts_on date, ends_on date, coverage jsonb not null default '{}'::jsonb, status text not null default 'ACTIVE',
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(), version int not null default 1,
  unique(organization_id,id), foreign key(organization_id,asset_id) references public.assets(organization_id,id)
);
create trigger trg_asset_contracts_updated before update on public.asset_contracts for each row execute function app.set_updated_at();
create trigger trg_asset_contracts_version before update on public.asset_contracts for each row execute function app.bump_version();

create table if not exists public.api_tokens(
  id uuid primary key default gen_random_uuid(), organization_id uuid not null, name text not null, token_prefix text not null, token_hash text not null,
  scopes text[] not null default '{}', created_by uuid not null, expires_at timestamptz, last_used_at timestamptz, revoked_at timestamptz,
  created_at timestamptz not null default now(), unique(organization_id,id), unique(token_hash), foreign key(organization_id,created_by) references public.organization_members(organization_id,id)
);
create index if not exists api_tokens_prefix_idx on public.api_tokens(token_prefix) where revoked_at is null;
create table if not exists public.api_rate_limits(
  id uuid primary key default gen_random_uuid(), organization_id uuid not null, token_id uuid not null, window_start timestamptz not null,
  request_count int not null default 0, unique(organization_id,token_id,window_start), foreign key(organization_id,token_id) references public.api_tokens(organization_id,id) on delete cascade
);

create table if not exists public.outbound_webhooks(
  id uuid primary key default gen_random_uuid(), organization_id uuid not null, name text not null, endpoint_url text not null,
  signing_secret_reference text not null, subscribed_events text[] not null default '{}', active boolean not null default true,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(), version int not null default 1,
  unique(organization_id,id), foreign key(organization_id) references public.organizations(id)
);
create trigger trg_outbound_webhooks_updated before update on public.outbound_webhooks for each row execute function app.set_updated_at();
create trigger trg_outbound_webhooks_version before update on public.outbound_webhooks for each row execute function app.bump_version();
create table if not exists public.webhook_deliveries(
  id uuid primary key default gen_random_uuid(), organization_id uuid not null, webhook_id uuid not null, event_id uuid not null,
  status text not null default 'PENDING' check(status in('PENDING','CLAIMED','SUCCEEDED','FAILED_RETRYABLE','FAILED_FINAL','CANCELLED')),
  attempts int not null default 0, next_attempt_at timestamptz not null default now(), response_code int, response_hash text, last_error text,
  lease_owner text, lease_expires_at timestamptz, created_at timestamptz not null default now(), completed_at timestamptz,
  unique(organization_id,id), unique(organization_id,webhook_id,event_id), foreign key(organization_id,webhook_id) references public.outbound_webhooks(organization_id,id),
  foreign key(event_id) references public.event_outbox(event_id)
);
create index if not exists webhook_delivery_due_idx on public.webhook_deliveries(status,next_attempt_at);

with pv as (select id,plan_key from plan_versions where version=1)
insert into plan_entitlements(plan_version_id,feature_key,value_json)
select pv.id,x.key,x.value::jsonb from pv cross join lateral(values
 ('feature.multi_branch',case when pv.plan_key='ULTRA' then 'true' else 'false' end),
 ('feature.approvals',case when pv.plan_key='ULTRA' then 'true' else 'false' end),
 ('feature.sla_ticket',case when pv.plan_key='ULTRA' then 'true' else 'false' end),
 ('feature.recurring_contracts',case when pv.plan_key='ULTRA' then 'true' else 'false' end),
 ('feature.public_api',case when pv.plan_key='ULTRA' then 'true' else 'false' end),
 ('feature.outbound_webhooks',case when pv.plan_key='ULTRA' then 'true' else 'false' end),
 ('feature.advanced_assets',case when pv.plan_key='ULTRA' then 'true' else 'false' end),
 ('feature.advanced_analytics',case when pv.plan_key='ULTRA' then 'true' else 'false' end),
 ('feature.advanced_automation',case when pv.plan_key='ULTRA' then 'true' else 'false' end)
) x(key,value) on conflict(plan_version_id,feature_key) do update set value_json=excluded.value_json;

create or replace function app.seed_ultra_permissions(p_org uuid) returns void language plpgsql security definer set search_path=public,app as $$
begin
 insert into role_permissions(organization_id,role_id,permission_key,allowed)
 select p_org,r.id,p.key,true from roles r cross join lateral(values
 ('branch.view'),('branch.manage'),('role.custom_manage'),('approval.view'),('approval.decide'),('audit.full_view'),('sla.view'),('sla.manage'),('api.manage'),('webhook.manage'),('analytics.advanced')) p(key)
 where r.organization_id=p_org and r.system_key='OWNER'
 on conflict(organization_id,role_id,permission_key) do update set allowed=true;
 insert into role_permissions(organization_id,role_id,permission_key,allowed)
 select p_org,r.id,p.key,true from roles r cross join lateral(values('branch.view'),('approval.view'),('approval.decide'),('sla.view'),('analytics.advanced')) p(key)
 where r.organization_id=p_org and r.system_key='ADMIN'
 on conflict(organization_id,role_id,permission_key) do update set allowed=true;
end $$;
do $$ declare o uuid; begin for o in select id from organizations loop perform app.seed_ultra_permissions(o); end loop; end $$;

create or replace function app.branch_allowed(p_org uuid,p_branch uuid) returns boolean language plpgsql stable security definer set search_path=public,app as $$
declare me uuid:=app.current_member_id(p_org); rk text:=app.current_role_key(p_org); mb uuid;
begin if me is null then return false; end if; if p_branch is null then return true; end if; if rk='OWNER' then return true; end if; select branch_id into mb from organization_members where organization_id=p_org and id=me; if mb=p_branch then return true; end if; if rk='SUPERVISOR' then return exists(select 1 from member_team_scope s join organization_members m on m.organization_id=s.organization_id and m.id=s.member_id where s.organization_id=p_org and s.supervisor_member_id=me and m.branch_id=p_branch and m.status='ACTIVE'); end if; return false; end $$;

create or replace function app.create_branch(p_org uuid,p_name text,p_country text,p_timezone text,p_address jsonb,p_key text) returns uuid
language plpgsql security definer set search_path=public,app as $$
declare actor uuid:=app.require_permission(p_org,'branch.manage'); bid uuid:=gen_random_uuid(); lim bigint; cnt int; h text; replay jsonb;
begin if not app.feature_enabled(p_org,'feature.multi_branch') then raise exception 'ARV-USAGE-6001 multi-branch not entitled'; end if; h:=app.command_hash(jsonb_build_array(p_name,p_country,p_timezone,p_address)); perform app.command_lock(p_org,'branch.create',p_key); replay:=app.idempotency_existing(p_org,actor,'branch.create',p_key,h); if replay is not null then return (replay->>'branch_id')::uuid; end if;
 perform pg_advisory_xact_lock(hashtextextended(p_org::text||':branches',23)); lim:=app.limit_value(p_org,'limit.branches_active'); select count(*) into cnt from branches where organization_id=p_org and active; if cnt>=lim then raise exception 'ARV-USAGE-6001 branch limit reached'; end if;
 insert into branches(id,organization_id,name,country_code,timezone,address_json) values(bid,p_org,p_name,upper(p_country),p_timezone,coalesce(p_address,'{}')); perform app.idempotency_commit(p_org,actor,'branch.create',p_key,h,jsonb_build_object('branch_id',bid)); return bid; end $$;

create or replace function app.create_custom_role(p_org uuid,p_name text,p_permissions text[],p_key text) returns uuid
language plpgsql security definer set search_path=public,app as $$
declare actor uuid:=app.require_permission(p_org,'role.custom_manage'); rid uuid:=gen_random_uuid(); perm text; h text; replay jsonb;
begin if not app.feature_enabled(p_org,'feature.custom_roles') then raise exception 'ARV-USAGE-6001 custom roles not entitled'; end if; h:=app.command_hash(jsonb_build_array(p_name,to_jsonb(p_permissions))); perform app.command_lock(p_org,'role.custom',p_key); replay:=app.idempotency_existing(p_org,actor,'role.custom',p_key,h); if replay is not null then return (replay->>'role_id')::uuid; end if;
 insert into roles(id,organization_id,name,system_key,is_system_role) values(rid,p_org,p_name,null,false); foreach perm in array coalesce(p_permissions,'{}'::text[]) loop if perm in('billing.manage','integration.manage','role.custom_manage','api.manage','webhook.manage') and app.current_role_key(p_org)<>'OWNER' then raise exception 'ARV-PERM-1001 privileged permission cannot be delegated by actor'; end if; insert into role_permissions(organization_id,role_id,permission_key,allowed) values(p_org,rid,perm,true); end loop; perform app.idempotency_commit(p_org,actor,'role.custom',p_key,h,jsonb_build_object('role_id',rid)); return rid; end $$;

create or replace function app.request_approval(p_org uuid,p_entity_type text,p_entity_id uuid,p_action text,p_payload jsonb,p_required int,p_expires timestamptz,p_key text) returns uuid
language plpgsql security definer set search_path=public,app as $$
declare actor uuid:=app.require_member(p_org); aid uuid; h text; replay jsonb;
begin if not app.feature_enabled(p_org,'feature.approvals') then raise exception 'ARV-USAGE-6001 approvals not entitled'; end if; if not app.can_access_entity(p_org,p_entity_type,p_entity_id) then raise exception 'ARV-PERM-1001 entity scope denied'; end if; h:=app.command_hash(jsonb_build_array(p_entity_type,p_entity_id,p_action,p_payload,p_required,p_expires)); perform app.command_lock(p_org,'approval.request',p_key); replay:=app.idempotency_existing(p_org,actor,'approval.request',p_key,h); if replay is not null then return (replay->>'approval_id')::uuid; end if;
 insert into approval_requests(organization_id,entity_type,entity_id,action_type,requested_by,requested_payload,required_approvals,idempotency_key,expires_at) values(p_org,upper(p_entity_type),p_entity_id,p_action,actor,coalesce(p_payload,'{}'),greatest(1,p_required),p_key,p_expires) returning id into aid; perform app.idempotency_commit(p_org,actor,'approval.request',p_key,h,jsonb_build_object('approval_id',aid)); return aid; end $$;

create or replace function app.decide_approval(p_org uuid,p_approval uuid,p_decision text,p_reason text,p_key text) returns jsonb
language plpgsql security definer set search_path=public,app as $$
declare actor uuid:=app.require_permission(p_org,'approval.decide'); a approval_requests%rowtype; approved int; rejected int; final text; h text; replay jsonb;
begin h:=app.command_hash(jsonb_build_array(p_approval,p_decision,p_reason)); perform app.command_lock(p_org,'approval.decide:'||p_approval,p_key); replay:=app.idempotency_existing(p_org,actor,'approval.decide',p_key,h); if replay is not null then return replay; end if;
 select * into a from approval_requests where organization_id=p_org and id=p_approval for update; if not found or a.status<>'PENDING' then raise exception 'ARV-CONFLICT-1001 approval already terminal'; end if; if a.expires_at is not null and a.expires_at<=now() then update approval_requests set status='EXPIRED',decided_at=now() where id=a.id; raise exception 'ARV-STATE-1001 approval expired'; end if;
 insert into approval_decisions(organization_id,approval_request_id,approver_member_id,decision,reason) values(p_org,p_approval,actor,upper(p_decision),p_reason) on conflict(organization_id,approval_request_id,approver_member_id) do nothing;
 select count(*) filter(where decision='APPROVE'),count(*) filter(where decision='REJECT') into approved,rejected from approval_decisions where organization_id=p_org and approval_request_id=p_approval;
 final:=case when rejected>0 then 'REJECTED' when approved>=a.required_approvals then 'APPROVED' else 'PENDING' end; if final<>'PENDING' then update approval_requests set status=final,decided_at=now() where id=p_approval and status='PENDING'; perform app.emit_event(p_org,actor,'approval.'||lower(final),'ORGANIZATION',p_org,jsonb_build_object('approval_id',p_approval,'entity_type',a.entity_type,'entity_id',a.entity_id,'action_type',a.action_type),p_key); end if;
 perform app.idempotency_commit(p_org,actor,'approval.decide',p_key,h,jsonb_build_object('approval_id',p_approval,'status',final,'approvals',approved,'rejections',rejected)); return jsonb_build_object('approval_id',p_approval,'status',final,'approvals',approved,'rejections',rejected); end $$;

create or replace function app.authorize_api_token(p_token_hash text,p_scope text) returns uuid
language plpgsql security definer set search_path=public,app as $$
declare t api_tokens%rowtype; minute_window timestamptz:=date_trunc('minute',now()); cnt int;
begin select * into t from api_tokens where token_hash=p_token_hash and revoked_at is null and (expires_at is null or expires_at>now()) for update; if not found or not(p_scope=any(t.scopes) or '*'=any(t.scopes)) then raise exception 'ARV-API-8001 token unauthorized'; end if; insert into api_rate_limits(organization_id,token_id,window_start,request_count) values(t.organization_id,t.id,minute_window,1) on conflict(organization_id,token_id,window_start) do update set request_count=api_rate_limits.request_count+1 returning request_count into cnt; if cnt>120 then raise exception 'ARV-API-8002 rate limit exceeded'; end if; update api_tokens set last_used_at=now() where id=t.id; return t.organization_id; end $$;

-- Durable outbound webhook fanout and claim.
create or replace function app.enqueue_outbound_webhooks(p_event_id uuid) returns int language plpgsql security definer set search_path=public,app as $$
declare ev event_outbox%rowtype; w outbound_webhooks%rowtype; n int:=0; begin select * into ev from event_outbox where event_id=p_event_id; if not found then return 0; end if; for w in select * from outbound_webhooks where organization_id=ev.organization_id and active and (cardinality(subscribed_events)=0 or ev.event_type=any(subscribed_events)) loop insert into webhook_deliveries(organization_id,webhook_id,event_id) values(ev.organization_id,w.id,p_event_id) on conflict do nothing; if found then n:=n+1; end if; end loop; return n; end $$;

-- Branch-aware helper views. Customer remains organization-wide; Jobs and Invoice snapshots may be branch scoped.
create or replace view public.branch_list_v with(security_invoker=true) as select organization_id,id,name,country_code,timezone,active,updated_at from branches;
create or replace view public.approval_list_v with(security_invoker=true) as select organization_id,id,entity_type,entity_id,action_type,status,required_approvals,created_at,expires_at,decided_at from approval_requests;
create or replace view public.ticket_list_v with(security_invoker=true) as select t.organization_id,t.id,t.ticket_number,c.name customer,t.title,t.priority,t.status,t.response_due_at,t.resolution_due_at,t.updated_at from tickets t join customers c on c.organization_id=t.organization_id and c.id=t.customer_id;
create or replace view public.audit_full_v with(security_invoker=true) as select organization_id,id,actor_id,action,entity_type,entity_id,before_json,after_json,occurred_at from audit_logs;

-- RLS.
do $$ declare t text; begin foreach t in array array['branches','approval_requests','approval_decisions','sla_contracts','tickets','recurring_contracts','asset_contracts','api_tokens','api_rate_limits','outbound_webhooks','webhook_deliveries'] loop execute format('alter table public.%I enable row level security',t); execute format('alter table public.%I force row level security',t); end loop; end $$;
create policy branches_select on branches for select using(app.has_permission(organization_id,'branch.view'));
create policy branches_manage on branches for all using(app.has_permission(organization_id,'branch.manage') and app.feature_enabled(organization_id,'feature.multi_branch')) with check(app.has_permission(organization_id,'branch.manage') and app.feature_enabled(organization_id,'feature.multi_branch'));
create policy approvals_select on approval_requests for select using(app.has_permission(organization_id,'approval.view') or requested_by=app.current_member_id(organization_id));
create policy approval_decisions_select on approval_decisions for select using(app.has_permission(organization_id,'approval.view'));
create policy sla_select on sla_contracts for select using(app.has_permission(organization_id,'sla.view'));
create policy sla_manage on sla_contracts for all using(app.has_permission(organization_id,'sla.manage') and app.feature_enabled(organization_id,'feature.sla_ticket')) with check(app.has_permission(organization_id,'sla.manage') and app.feature_enabled(organization_id,'feature.sla_ticket'));
create policy tickets_select on tickets for select using(app.has_permission(organization_id,'sla.view') and app.can_view_customer(organization_id,customer_id));
create policy tickets_manage on tickets for all using(app.has_permission(organization_id,'sla.manage') and app.can_view_customer(organization_id,customer_id)) with check(app.has_permission(organization_id,'sla.manage'));
create policy recurring_contracts_select on recurring_contracts for select using(app.has_permission(organization_id,'recurring.view') and app.can_view_customer(organization_id,customer_id));
create policy recurring_contracts_manage on recurring_contracts for all using(app.has_permission(organization_id,'recurring.manage') and app.feature_enabled(organization_id,'feature.recurring_contracts')) with check(app.has_permission(organization_id,'recurring.manage') and app.feature_enabled(organization_id,'feature.recurring_contracts'));
create policy asset_contracts_select on asset_contracts for select using(exists(select 1 from assets a where a.organization_id=asset_contracts.organization_id and a.id=asset_id and app.can_view_asset(a.organization_id,a.id)));
create policy asset_contracts_manage on asset_contracts for all using(app.has_permission(organization_id,'asset.manage') and app.feature_enabled(organization_id,'feature.advanced_assets')) with check(app.has_permission(organization_id,'asset.manage') and app.feature_enabled(organization_id,'feature.advanced_assets'));
create policy api_tokens_select on api_tokens for select using(app.has_permission(organization_id,'api.manage'));
create policy outbound_webhooks_select on outbound_webhooks for select using(app.has_permission(organization_id,'webhook.manage'));
create policy outbound_webhooks_manage on outbound_webhooks for all using(app.has_permission(organization_id,'webhook.manage') and app.feature_enabled(organization_id,'feature.outbound_webhooks')) with check(app.has_permission(organization_id,'webhook.manage') and app.feature_enabled(organization_id,'feature.outbound_webhooks'));
create policy webhook_deliveries_select on webhook_deliveries for select using(app.has_permission(organization_id,'webhook.manage'));
-- api_rate_limits has no client policy.

-- Full audit is Ultra only even though critical events are always retained.
drop policy if exists audit_select on audit_logs;
create policy audit_select on audit_logs for select using(app.has_permission(organization_id,'audit.critical_view') or (app.has_permission(organization_id,'audit.full_view') and app.feature_enabled(organization_id,'feature.full_audit')));

grant execute on function app.create_branch(uuid,text,text,text,jsonb,text),app.create_custom_role(uuid,text,text[],text),app.request_approval(uuid,text,uuid,text,jsonb,int,timestamptz,text),app.decide_approval(uuid,uuid,text,text,text) to authenticated;
revoke all on function app.authorize_api_token(text,text),app.enqueue_outbound_webhooks(uuid) from public,anon,authenticated;
grant execute on function app.authorize_api_token(text,text),app.enqueue_outbound_webhooks(uuid) to service_role;

-- explicit RLS declarations for static verification
alter table public.branches enable row level security;
alter table public.approval_requests enable row level security;
alter table public.approval_decisions enable row level security;
alter table public.sla_contracts enable row level security;
alter table public.tickets enable row level security;
alter table public.recurring_contracts enable row level security;
alter table public.asset_contracts enable row level security;
alter table public.api_tokens enable row level security;
alter table public.api_rate_limits enable row level security;
alter table public.outbound_webhooks enable row level security;
alter table public.webhook_deliveries enable row level security;

-- Final P2 branch-scope enforcement on operational reads. Customers remain organization-wide by contract.
create or replace function app.can_view_job(p_org uuid,p_id uuid) returns boolean language plpgsql stable security definer set search_path=public,app as $$
declare rk text:=app.current_role_key(p_org); mid uuid:=app.current_member_id(p_org); j jobs%rowtype;
begin
 if mid is null or not app.has_permission(p_org,'job.view') then return false; end if;
 select * into j from jobs where organization_id=p_org and id=p_id; if not found then return false; end if;
 if rk='OWNER' then return true; end if;
 if rk='ADMIN' then return app.branch_allowed(p_org,j.branch_id); end if;
 if rk='SALES' then return app.branch_allowed(p_org,j.branch_id) and (app.can_view_customer(p_org,j.customer_id) or (j.lead_id is not null and app.can_view_lead(p_org,j.lead_id))); end if;
 if rk='WORKER' then return exists(select 1 from visits v join visit_assignments a on a.organization_id=v.organization_id and a.visit_id=v.id and a.removed_at is null where v.organization_id=p_org and v.job_id=p_id and a.member_id=mid); end if;
 if rk='SUPERVISOR' then return app.branch_allowed(p_org,j.branch_id) and exists(select 1 from visits v join visit_assignments a on a.organization_id=v.organization_id and a.visit_id=v.id and a.removed_at is null where v.organization_id=p_org and v.job_id=p_id and (a.member_id=mid or exists(select 1 from member_team_scope s where s.organization_id=p_org and s.supervisor_member_id=mid and s.member_id=a.member_id))); end if;
 return false;
end $$;

create or replace function app.can_view_visit(p_org uuid,p_id uuid) returns boolean language plpgsql stable security definer set search_path=public,app as $$
declare rk text:=app.current_role_key(p_org); mid uuid:=app.current_member_id(p_org); jid uuid;
begin
 if mid is null or not app.has_permission(p_org,'visit.view') then return false; end if;
 if rk='WORKER' then return exists(select 1 from visit_assignments where organization_id=p_org and visit_id=p_id and member_id=mid and removed_at is null); end if;
 if rk='SUPERVISOR' then return exists(select 1 from visits v join jobs j on j.organization_id=v.organization_id and j.id=v.job_id where v.organization_id=p_org and v.id=p_id and app.branch_allowed(p_org,j.branch_id) and exists(select 1 from visit_assignments a where a.organization_id=p_org and a.visit_id=v.id and a.removed_at is null and (a.member_id=mid or exists(select 1 from member_team_scope s where s.organization_id=p_org and s.supervisor_member_id=mid and s.member_id=a.member_id)))); end if;
 select job_id into jid from visits where organization_id=p_org and id=p_id; return jid is not null and app.can_view_job(p_org,jid);
end $$;

create or replace function app.can_view_invoice(p_org uuid,p_id uuid) returns boolean language plpgsql stable security definer set search_path=public,app as $$
declare rk text:=app.current_role_key(p_org); mid uuid:=app.current_member_id(p_org); i invoices%rowtype;
begin
 if mid is null or not app.has_permission(p_org,'invoice.view') then return false; end if;
 select * into i from invoices where organization_id=p_org and id=p_id; if not found then return false; end if;
 if rk='OWNER' then return true; end if;
 if rk in('ADMIN','FINANCE') then return app.branch_allowed(p_org,i.branch_id); end if;
 if rk='SALES' then return app.branch_allowed(p_org,i.branch_id) and app.can_view_customer(p_org,i.customer_id); end if;
 return false;
end $$;

-- ===== final P2 operational hardening =====
-- Keep role templates current for organizations created after the Ultra migration.
update system_role_templates s set permissions=(
 select coalesce(jsonb_agg(v order by v),'[]'::jsonb) from (
  select distinct v from jsonb_array_elements_text(s.permissions || case s.system_key
   when 'OWNER' then '["branch.view","branch.manage","role.custom_manage","approval.view","approval.decide","audit.full_view","sla.view","sla.manage","api.manage","webhook.manage","analytics.advanced"]'::jsonb
   when 'ADMIN' then '["branch.view","approval.view","approval.decide","sla.view","analytics.advanced"]'::jsonb
   else '[]'::jsonb end) v
 ) q
) where s.version=1;

-- Tickets receive the same tenant-scoped transactional numbering discipline as core documents.
alter table public.document_sequences drop constraint if exists document_sequences_document_type_check;
alter table public.document_sequences add constraint document_sequences_document_type_check check(document_type in('JOB','QUOTE','INVOICE','TICKET'));
create or replace function app.next_document_number(p_org uuid,p_type text) returns text language plpgsql security definer set search_path=public,app as $$
declare tz text; year_key text; v bigint; prefix text;
begin
 select timezone into tz from organizations where id=p_org; if tz is null then raise exception 'ARV-TENANT-1002 organization unavailable'; end if;
 year_key:=to_char(now() at time zone tz,'YYYY'); prefix:=case p_type when 'JOB' then 'JOB' when 'QUOTE' then 'QTE' when 'INVOICE' then 'INV' when 'TICKET' then 'TKT' else 'DOC' end;
 insert into document_sequences(organization_id,document_type,period_key,next_value) values(p_org,p_type,year_key,2)
 on conflict(organization_id,document_type,period_key) do update set next_value=document_sequences.next_value+1
 returning next_value-1 into v;
 return prefix||'-'||year_key||'-'||lpad(v::text,6,'0');
end $$;

create or replace function app.validate_approval_target() returns trigger language plpgsql as $$
begin if not app.entity_belongs_to_org(new.organization_id,new.entity_type,new.entity_id) then raise exception 'ARV-TENANT-1003 invalid approval target'; end if; return new; end $$;
drop trigger if exists trg_approval_target on approval_requests;
create trigger trg_approval_target before insert or update of organization_id,entity_type,entity_id on approval_requests for each row execute function app.validate_approval_target();

create or replace function app.create_sla_contract(p_org uuid,p_customer uuid,p_name text,p_response int,p_resolution int,p_business_hours jsonb,p_timezone text,p_starts date,p_ends date,p_terms jsonb,p_key text) returns uuid
language plpgsql security definer set search_path=public,app as $$
declare actor uuid:=app.require_permission(p_org,'sla.manage'); sid uuid:=gen_random_uuid(); h text; replay jsonb;
begin
 if not app.feature_enabled(p_org,'feature.sla_ticket') then raise exception 'ARV-USAGE-6001 SLA not entitled'; end if; if not app.can_view_customer(p_org,p_customer) then raise exception 'ARV-PERM-1001 customer scope denied'; end if;
 if coalesce(p_response,0)<=0 or coalesce(p_resolution,0)<=0 or p_resolution<p_response or (p_ends is not null and p_ends<p_starts) then raise exception 'ARV-VALIDATION-1001 invalid SLA'; end if;
 h:=app.command_hash(jsonb_build_array(p_customer,p_name,p_response,p_resolution,p_business_hours,p_timezone,p_starts,p_ends,p_terms)); perform app.command_lock(p_org,'sla.create',p_key); replay:=app.idempotency_existing(p_org,actor,'sla.create',p_key,h); if replay is not null then return (replay->>'sla_id')::uuid; end if;
 insert into sla_contracts(id,organization_id,customer_id,name,response_minutes,resolution_minutes,business_hours,timezone,starts_on,ends_on,terms) values(sid,p_org,p_customer,trim(p_name),p_response,p_resolution,coalesce(p_business_hours,'{}'),p_timezone,p_starts,p_ends,coalesce(p_terms,'{}'));
 perform app.idempotency_commit(p_org,actor,'sla.create',p_key,h,jsonb_build_object('sla_id',sid)); return sid;
end $$;

create or replace function app.create_ticket(p_org uuid,p_customer uuid,p_sla uuid,p_job uuid,p_title text,p_description text,p_priority text,p_key text) returns uuid
language plpgsql security definer set search_path=public,app as $$
declare actor uuid:=app.require_permission(p_org,'sla.manage'); tid uuid:=gen_random_uuid(); num text; s sla_contracts%rowtype; h text; replay jsonb;
begin
 if not app.feature_enabled(p_org,'feature.sla_ticket') then raise exception 'ARV-USAGE-6001 Ticket/SLA not entitled'; end if; if not app.can_view_customer(p_org,p_customer) then raise exception 'ARV-PERM-1001 customer scope denied'; end if;
 if p_sla is not null then select * into s from sla_contracts where organization_id=p_org and id=p_sla and customer_id=p_customer and active; if not found then raise exception 'ARV-TENANT-1003 SLA/customer mismatch'; end if; end if;
 if p_job is not null and not exists(select 1 from jobs where organization_id=p_org and id=p_job and customer_id=p_customer) then raise exception 'ARV-TENANT-1003 Job/customer mismatch'; end if;
 h:=app.command_hash(jsonb_build_array(p_customer,p_sla,p_job,p_title,p_description,p_priority)); perform app.command_lock(p_org,'ticket.create',p_key); replay:=app.idempotency_existing(p_org,actor,'ticket.create',p_key,h); if replay is not null then return (replay->>'ticket_id')::uuid; end if;
 num:=app.next_document_number(p_org,'TICKET');
 insert into tickets(id,organization_id,customer_id,sla_contract_id,job_id,ticket_number,title,description,priority,response_due_at,resolution_due_at) values(tid,p_org,p_customer,p_sla,p_job,num,trim(p_title),p_description,upper(coalesce(p_priority,'NORMAL')),case when p_sla is null then null else now()+make_interval(mins=>s.response_minutes) end,case when p_sla is null then null else now()+make_interval(mins=>s.resolution_minutes) end);
 perform app.activity(p_org,actor,'CUSTOMER',p_customer,'ticket.created','SLA ticket created',jsonb_build_object('ticket_id',tid,'ticket_number',num)); perform app.idempotency_commit(p_org,actor,'ticket.create',p_key,h,jsonb_build_object('ticket_id',tid,'ticket_number',num)); return tid;
end $$;

create or replace function app.ticket_action(p_org uuid,p_ticket uuid,p_action text,p_expected_version int,p_reason text,p_key text) returns jsonb
language plpgsql security definer set search_path=public,app as $$
declare actor uuid:=app.require_permission(p_org,'sla.manage'); t tickets%rowtype; target text; h text; replay jsonb; result jsonb;
begin
 h:=app.command_hash(jsonb_build_array(p_ticket,upper(p_action),p_expected_version,p_reason)); perform app.command_lock(p_org,'ticket.action:'||p_ticket::text,p_key); replay:=app.idempotency_existing(p_org,actor,'ticket.action',p_key,h); if replay is not null then return replay; end if;
 select * into t from tickets where organization_id=p_org and id=p_ticket for update; if not found or t.version<>p_expected_version then raise exception 'ARV-CONFLICT-1001 stale Ticket'; end if;
 target:=case upper(p_action) when 'ACKNOWLEDGE' then 'ACKNOWLEDGED' when 'START' then 'IN_PROGRESS' when 'WAIT' then 'WAITING' when 'RESOLVE' then 'RESOLVED' when 'CLOSE' then 'CLOSED' when 'CANCEL' then 'CANCELLED' else null end; if target is null then raise exception 'ARV-STATE-1001 invalid ticket action'; end if;
 if t.status in('CLOSED','CANCELLED') then raise exception 'ARV-STATE-1001 terminal Ticket'; end if; if upper(p_action)='CANCEL' and coalesce(trim(p_reason),'')='' then raise exception 'ARV-VALIDATION-1001 cancel reason required'; end if;
 update tickets set status=target,acknowledged_at=case when target='ACKNOWLEDGED' then coalesce(acknowledged_at,now()) else acknowledged_at end,resolved_at=case when target='RESOLVED' then coalesce(resolved_at,now()) else resolved_at end where id=t.id;
 result:=jsonb_build_object('ticket_id',t.id,'status',target,'version',p_expected_version+1); perform app.activity(p_org,actor,'CUSTOMER',t.customer_id,'ticket.'||lower(target),'Ticket '||lower(target),jsonb_build_object('ticket_id',t.id,'reason',p_reason)); perform app.idempotency_commit(p_org,actor,'ticket.action',p_key,h,result); return result;
end $$;

-- API tokens are returned once in plaintext; only the SHA-256 hash is persisted.
create or replace function app.create_api_token(p_org uuid,p_name text,p_scopes text[],p_expires timestamptz,p_key text) returns jsonb
language plpgsql security definer set search_path=public,app as $$
declare actor uuid:=app.require_permission(p_org,'api.manage'); raw text; full_token text; hid text; prefix text; idv uuid:=gen_random_uuid(); h text; replay jsonb;
begin
 if not app.feature_enabled(p_org,'feature.public_api') then raise exception 'ARV-USAGE-6001 public API not entitled'; end if; if cardinality(coalesce(p_scopes,'{}'::text[]))=0 then raise exception 'ARV-VALIDATION-1001 at least one API scope required'; end if;
 h:=app.command_hash(jsonb_build_array(p_name,to_jsonb(p_scopes),p_expires)); perform app.command_lock(p_org,'api_token.create',p_key); replay:=app.idempotency_existing(p_org,actor,'api_token.create',p_key,h); if replay is not null then return jsonb_build_object('token_id',replay->>'token_id','token',null,'replayed',true); end if;
 raw:=encode(extensions.gen_random_bytes(32),'hex'); full_token:='arv_live_'||raw; hid:=encode(extensions.digest(full_token,'sha256'),'hex'); prefix:=left(full_token,17);
 insert into api_tokens(id,organization_id,name,token_prefix,token_hash,scopes,created_by,expires_at) values(idv,p_org,trim(p_name),prefix,hid,p_scopes,actor,p_expires);
 perform app.idempotency_commit(p_org,actor,'api_token.create',p_key,h,jsonb_build_object('token_id',idv)); return jsonb_build_object('token_id',idv,'token',full_token,'replayed',false);
end $$;

create or replace function app.revoke_api_token(p_org uuid,p_token uuid,p_key text) returns jsonb language plpgsql security definer set search_path=public,app as $$
declare actor uuid:=app.require_permission(p_org,'api.manage'); h text; replay jsonb; result jsonb;
begin h:=app.command_hash(jsonb_build_array(p_token)); perform app.command_lock(p_org,'api_token.revoke:'||p_token::text,p_key); replay:=app.idempotency_existing(p_org,actor,'api_token.revoke',p_key,h); if replay is not null then return replay; end if; update api_tokens set revoked_at=coalesce(revoked_at,now()) where organization_id=p_org and id=p_token; if not found then raise exception 'ARV-API-8001 token unavailable'; end if; result:=jsonb_build_object('token_id',p_token,'revoked',true); perform app.idempotency_commit(p_org,actor,'api_token.revoke',p_key,h,result); return result; end $$;

create or replace function app.create_outbound_webhook(p_org uuid,p_name text,p_endpoint text,p_secret_reference text,p_events text[],p_key text) returns uuid
language plpgsql security definer set search_path=public,app as $$
declare actor uuid:=app.require_permission(p_org,'webhook.manage'); idv uuid:=gen_random_uuid(); h text; replay jsonb;
begin
 if not app.feature_enabled(p_org,'feature.outbound_webhooks') then raise exception 'ARV-USAGE-6001 webhooks not entitled'; end if; if p_endpoint!~'^https://' then raise exception 'ARV-VALIDATION-1001 webhook endpoint must use HTTPS'; end if; if trim(coalesce(p_secret_reference,''))='' then raise exception 'ARV-VALIDATION-1001 signing secret reference required'; end if;
 h:=app.command_hash(jsonb_build_array(p_name,p_endpoint,p_secret_reference,to_jsonb(coalesce(p_events,'{}'::text[])))); perform app.command_lock(p_org,'webhook.create',p_key); replay:=app.idempotency_existing(p_org,actor,'webhook.create',p_key,h); if replay is not null then return (replay->>'webhook_id')::uuid; end if;
 insert into outbound_webhooks(id,organization_id,name,endpoint_url,signing_secret_reference,subscribed_events) values(idv,p_org,trim(p_name),p_endpoint,p_secret_reference,coalesce(p_events,'{}'::text[])); perform app.idempotency_commit(p_org,actor,'webhook.create',p_key,h,jsonb_build_object('webhook_id',idv)); return idv;
end $$;

-- API/Webhook secret-bearing base tables are not directly readable by authenticated clients.
revoke all on public.api_tokens from authenticated;
revoke all on public.outbound_webhooks from authenticated;
create or replace view public.api_token_list_v as select organization_id,id,name,token_prefix,scopes,expires_at,last_used_at,revoked_at,created_at from api_tokens where app.has_permission(organization_id,'api.manage');
create or replace view public.outbound_webhook_list_v as select organization_id,id,name,endpoint_url,subscribed_events,active,updated_at from outbound_webhooks where app.has_permission(organization_id,'webhook.manage');
grant select on public.api_token_list_v,public.outbound_webhook_list_v to authenticated;

grant execute on function app.create_sla_contract(uuid,uuid,text,int,int,jsonb,text,date,date,jsonb,text),app.create_ticket(uuid,uuid,uuid,uuid,text,text,text,text),app.ticket_action(uuid,uuid,text,int,text,text),app.create_api_token(uuid,text,text[],timestamptz,text),app.revoke_api_token(uuid,uuid,text),app.create_outbound_webhook(uuid,text,text,text,text[],text) to authenticated;


-- ===== FINAL P2 SECURITY/CORRECTNESS HARDENING =====
-- Explicit catalogs prevent approvals and API tokens from turning arbitrary strings into authority.
create table if not exists public.approval_action_catalog(
  action_type text primary key, entity_type text not null, required_permission text not null, payload_contract text not null, executable boolean not null default true
);
insert into public.approval_action_catalog(action_type,entity_type,required_permission,payload_contract,executable) values
 ('JOB.CANCEL_PRIVILEGED','JOB','job.cancel_privileged','expected_version:int,reason:nonempty',true),
 ('INVOICE.VOID','INVOICE','invoice.void','expected_version:int,reason:nonempty',true)
on conflict(action_type) do update set entity_type=excluded.entity_type,required_permission=excluded.required_permission,payload_contract=excluded.payload_contract,executable=excluded.executable;

create table if not exists public.api_scope_catalog(
  scope_key text primary key, required_permission text not null, active boolean not null default true
);
insert into public.api_scope_catalog(scope_key,required_permission) values
 ('customers.read','customer.view'),('customers.write','customer.update'),('leads.read','lead.view'),('leads.write','lead.update'),
 ('jobs.read','job.view'),('jobs.write','job.update'),('visits.read','visit.view'),('visits.write','visit.schedule'),
 ('invoices.read','invoice.view'),('invoices.write','invoice.create'),('payments.read','payment.view'),('payments.write','payment.record'),('reports.read','report.basic')
on conflict(scope_key) do update set required_permission=excluded.required_permission,active=true;
alter table public.approval_action_catalog enable row level security;
alter table public.approval_action_catalog force row level security;
alter table public.api_scope_catalog enable row level security;
alter table public.api_scope_catalog force row level security;
revoke all on public.approval_action_catalog,public.api_scope_catalog from public,anon,authenticated;
grant select on public.approval_action_catalog,public.api_scope_catalog to service_role;

alter table public.approval_requests add column if not exists required_permission text;
alter table public.approval_requests add column if not exists execution_status text not null default 'NOT_READY' check(execution_status in('NOT_READY','READY','RUNNING','SUCCEEDED','FAILED_RETRYABLE','FAILED_FINAL'));
alter table public.approval_requests add column if not exists executed_at timestamptz;
alter table public.approval_requests add column if not exists execution_result jsonb;
alter table public.approval_requests add column if not exists execution_error text;

create or replace function app.approval_payload_valid(p_action text,p_payload jsonb) returns boolean
language sql immutable security definer set search_path=public,app as $$
 select case upper(p_action)
  when 'JOB.CANCEL_PRIVILEGED' then jsonb_typeof(coalesce(p_payload,'{}'::jsonb))='object' and (p_payload ? 'expected_version') and (p_payload->>'expected_version') ~ '^[0-9]+$' and coalesce(trim(p_payload->>'reason'),'')<>''
  when 'INVOICE.VOID' then jsonb_typeof(coalesce(p_payload,'{}'::jsonb))='object' and (p_payload ? 'expected_version') and (p_payload->>'expected_version') ~ '^[0-9]+$' and coalesce(trim(p_payload->>'reason'),'')<>''
  else false end
$$;

create or replace function app.request_approval(p_org uuid,p_entity_type text,p_entity_id uuid,p_action text,p_payload jsonb,p_required int,p_expires timestamptz,p_key text) returns uuid
language plpgsql security definer set search_path=public,app as $$
declare actor uuid:=app.require_member(p_org); aid uuid; h text; replay jsonb; cat public.approval_action_catalog%rowtype; action_norm text:=upper(trim(p_action)); entity_norm text:=upper(trim(p_entity_type));
begin
 if not app.feature_enabled(p_org,'feature.approvals') then raise exception 'ARV-USAGE-6001 approvals not entitled'; end if;
 select * into cat from public.approval_action_catalog where action_type=action_norm and executable;
 if not found or cat.entity_type<>entity_norm then raise exception 'ARV-APPROVAL-8101 unsupported approval action'; end if;
 if not app.can_access_entity(p_org,entity_norm,p_entity_id) or not app.has_permission(p_org,cat.required_permission) then raise exception 'ARV-PERM-1001 approval request scope denied'; end if;
 if not app.approval_payload_valid(action_norm,coalesce(p_payload,'{}')) then raise exception 'ARV-APPROVAL-8102 approval payload invalid'; end if;
 h:=app.command_hash(jsonb_build_array(entity_norm,p_entity_id,action_norm,p_payload,p_required,p_expires)); perform app.command_lock(p_org,'approval.request',p_key); replay:=app.idempotency_existing(p_org,actor,'approval.request',p_key,h); if replay is not null then return (replay->>'approval_id')::uuid; end if;
 insert into public.approval_requests(organization_id,entity_type,entity_id,action_type,requested_by,requested_payload,required_permission,required_approvals,idempotency_key,expires_at)
 values(p_org,entity_norm,p_entity_id,action_norm,actor,coalesce(p_payload,'{}'),cat.required_permission,greatest(1,p_required),p_key,p_expires) returning id into aid;
 perform app.idempotency_commit(p_org,actor,'approval.request',p_key,h,jsonb_build_object('approval_id',aid)); return aid;
end $$;

create or replace function app.decide_approval(p_org uuid,p_approval uuid,p_decision text,p_reason text,p_key text) returns jsonb
language plpgsql security definer set search_path=public,app as $$
declare actor uuid:=app.require_permission(p_org,'approval.decide'); a public.approval_requests%rowtype; approved int; rejected int; final text; h text; replay jsonb; decision_norm text:=upper(trim(p_decision));
begin
 if decision_norm not in('APPROVE','REJECT') then raise exception 'ARV-APPROVAL-8103 invalid approval decision'; end if;
 h:=app.command_hash(jsonb_build_array(p_approval,decision_norm,p_reason)); perform app.command_lock(p_org,'approval.decide:'||p_approval::text,p_key); replay:=app.idempotency_existing(p_org,actor,'approval.decide',p_key,h); if replay is not null then return replay; end if;
 select * into a from public.approval_requests where organization_id=p_org and id=p_approval for update; if not found or a.status<>'PENDING' then raise exception 'ARV-CONFLICT-1001 approval already terminal'; end if;
 if a.expires_at is not null and a.expires_at<=now() then update public.approval_requests set status='EXPIRED',decided_at=now() where id=a.id; raise exception 'ARV-STATE-1001 approval expired'; end if;
 insert into public.approval_decisions(organization_id,approval_request_id,approver_member_id,decision,reason) values(p_org,p_approval,actor,decision_norm,p_reason) on conflict(organization_id,approval_request_id,approver_member_id) do nothing;
 select count(*) filter(where decision='APPROVE'),count(*) filter(where decision='REJECT') into approved,rejected from public.approval_decisions where organization_id=p_org and approval_request_id=p_approval;
 final:=case when rejected>0 then 'REJECTED' when approved>=a.required_approvals then 'APPROVED' else 'PENDING' end;
 if final<>'PENDING' then
   update public.approval_requests set status=final,decided_at=now(),execution_status=case when final='APPROVED' then 'READY' else 'NOT_READY' end where id=p_approval and status='PENDING';
   perform app.emit_event(p_org,actor,'approval.'||lower(final),'ORGANIZATION',p_org,jsonb_build_object('approval_id',p_approval,'entity_type',a.entity_type,'entity_id',a.entity_id,'action_type',a.action_type),p_key);
 end if;
 replay:=jsonb_build_object('approval_id',p_approval,'status',final,'approvals',approved,'rejections',rejected); perform app.idempotency_commit(p_org,actor,'approval.decide',p_key,h,replay); return replay;
end $$;

-- Trusted approval executor. It revalidates current requester's membership and action permission by impersonating the requester only inside this transaction.
create or replace function app.execute_approved_action(p_approval uuid) returns jsonb
language plpgsql security definer set search_path=public,app as $$
declare a public.approval_requests%rowtype; cat public.approval_action_catalog%rowtype; requester_user uuid; result jsonb; old_sub text; exec_key text;
begin
 select * into a from public.approval_requests where id=p_approval for update;
 if not found or a.status<>'APPROVED' then raise exception 'ARV-APPROVAL-8104 approval not executable'; end if;
 if a.execution_status='SUCCEEDED' then return coalesce(a.execution_result,'{}'::jsonb)||jsonb_build_object('replayed',true); end if;
 if a.execution_status='RUNNING' then raise exception 'ARV-CONFLICT-1001 approval execution already running'; end if;
 select * into cat from public.approval_action_catalog where action_type=a.action_type and entity_type=a.entity_type and executable;
 if not found or cat.required_permission<>a.required_permission or not app.approval_payload_valid(a.action_type,a.requested_payload) then raise exception 'ARV-APPROVAL-8105 approval contract no longer valid'; end if;
 select user_id into requester_user from public.organization_members where organization_id=a.organization_id and id=a.requested_by and status='ACTIVE';
 if requester_user is null then raise exception 'ARV-TENANT-1002 requester membership inactive'; end if;
 update public.approval_requests set execution_status='RUNNING',execution_error=null where id=a.id;
 old_sub:=current_setting('request.jwt.claim.sub',true); perform set_config('request.jwt.claim.sub',requester_user::text,true); exec_key:='approval:'||a.id::text||':execute';
 begin
   if a.action_type='JOB.CANCEL_PRIVILEGED' then
     result:=app.job_action(a.organization_id,a.entity_id,'CANCEL_PRIVILEGED',a.requested_payload->>'reason',(a.requested_payload->>'expected_version')::int,exec_key);
   elsif a.action_type='INVOICE.VOID' then
     result:=app.void_invoice(a.organization_id,a.entity_id,a.requested_payload->>'reason',(a.requested_payload->>'expected_version')::int,exec_key);
   else raise exception 'ARV-APPROVAL-8101 unsupported approval action'; end if;
   update public.approval_requests set execution_status='SUCCEEDED',executed_at=now(),execution_result=result,execution_error=null where id=a.id;
 exception when serialization_failure or deadlock_detected then
   update public.approval_requests set execution_status='FAILED_RETRYABLE',execution_error=left(sqlerrm,500) where id=a.id; result:=jsonb_build_object('approval_id',a.id,'execution_status','FAILED_RETRYABLE','error',sqlerrm);
 when others then
   update public.approval_requests set execution_status='FAILED_FINAL',execution_error=left(sqlerrm,500) where id=a.id; result:=jsonb_build_object('approval_id',a.id,'execution_status','FAILED_FINAL','error',sqlerrm);
 end;
 if old_sub is not null then perform set_config('request.jwt.claim.sub',old_sub,true); else perform set_config('request.jwt.claim.sub','',true); end if;
 return result;
end $$;

create or replace function app.create_api_token(p_org uuid,p_name text,p_scopes text[],p_expires timestamptz,p_key text) returns jsonb
language plpgsql security definer set search_path=public,app as $$
declare actor uuid:=app.require_permission(p_org,'api.manage'); raw text; full_token text; hid text; prefix text; idv uuid:=gen_random_uuid(); h text; replay jsonb; scope text;
begin
 if not app.feature_enabled(p_org,'feature.public_api') then raise exception 'ARV-USAGE-6001 public API not entitled'; end if;
 if cardinality(coalesce(p_scopes,'{}'::text[]))=0 then raise exception 'ARV-VALIDATION-1001 at least one API scope required'; end if;
 foreach scope in array p_scopes loop
   if not exists(select 1 from public.api_scope_catalog c where c.scope_key=scope and c.active) then raise exception 'ARV-API-8003 unknown API scope'; end if;
   if not exists(select 1 from public.api_scope_catalog c where c.scope_key=scope and c.active and app.has_permission(p_org,c.required_permission)) then raise exception 'ARV-PERM-1001 API scope exceeds actor authority'; end if;
 end loop;
 h:=app.command_hash(jsonb_build_array(p_name,to_jsonb((select array_agg(distinct x order by x) from unnest(p_scopes) x)),p_expires)); perform app.command_lock(p_org,'api_token.create',p_key); replay:=app.idempotency_existing(p_org,actor,'api_token.create',p_key,h); if replay is not null then return jsonb_build_object('token_id',replay->>'token_id','token',null,'replayed',true); end if;
 raw:=encode(extensions.gen_random_bytes(32),'hex'); full_token:='arv_live_'||raw; hid:=encode(extensions.digest(full_token,'sha256'),'hex'); prefix:=left(full_token,17);
 insert into public.api_tokens(id,organization_id,name,token_prefix,token_hash,scopes,created_by,expires_at) values(idv,p_org,trim(p_name),prefix,hid,(select array_agg(distinct x order by x) from unnest(p_scopes) x),actor,p_expires);
 perform app.idempotency_commit(p_org,actor,'api_token.create',p_key,h,jsonb_build_object('token_id',idv)); return jsonb_build_object('token_id',idv,'token',full_token,'replayed',false);
end $$;

create or replace function app.authorize_api_token(p_token_hash text,p_scope text) returns uuid
language plpgsql security definer set search_path=public,app as $$
declare t public.api_tokens%rowtype; minute_window timestamptz:=date_trunc('minute',now()); cnt int;
begin
 if not exists(select 1 from public.api_scope_catalog where scope_key=p_scope and active) then raise exception 'ARV-API-8001 token unauthorized'; end if;
 select * into t from public.api_tokens where token_hash=p_token_hash and revoked_at is null and (expires_at is null or expires_at>now()) for update;
 if not found or not(p_scope=any(t.scopes)) then raise exception 'ARV-API-8001 token unauthorized'; end if;
 insert into public.api_rate_limits(organization_id,token_id,window_start,request_count) values(t.organization_id,t.id,minute_window,1) on conflict(organization_id,token_id,window_start) do update set request_count=api_rate_limits.request_count+1 returning request_count into cnt;
 if cnt>120 then raise exception 'ARV-API-8002 rate limit exceeded'; end if; update public.api_tokens set last_used_at=now() where id=t.id; return t.organization_id;
end $$;

-- Database-side first-pass SSRF guard. Delivery code must resolve DNS and revalidate every returned IP immediately before network I/O.
create or replace function app.webhook_endpoint_is_obviously_safe(p_endpoint text) returns boolean
language plpgsql immutable security definer set search_path=public,app as $$
declare host text; h text;
begin
 if p_endpoint is null or p_endpoint !~* '^https://[^/]+(/|$)' then return false; end if;
 host:=substring(p_endpoint from '^https://(\\[[^]]+\\]|[^/:?#]+)'); if host is null then return false; end if; h:=lower(trim(both '[]' from host));
 if h in('localhost','localhost.localdomain','0.0.0.0','::','::1') or h like '%.localhost' or h like '%.local' then return false; end if;
 if h ~ '^127\\.' or h ~ '^10\\.' or h ~ '^192\\.168\\.' or h ~ '^169\\.254\\.' or h ~ '^100\\.(6[4-9]|[7-9][0-9]|1[01][0-9]|12[0-7])\\.' or h ~ '^172\\.(1[6-9]|2[0-9]|3[01])\\.' then return false; end if;
 if h ~ '^(fc|fd|fe8|fe9|fea|feb)[0-9a-f]*:' then return false; end if;
 return true;
end $$;

create or replace function app.create_outbound_webhook(p_org uuid,p_name text,p_endpoint text,p_secret_reference text,p_events text[],p_key text) returns uuid
language plpgsql security definer set search_path=public,app as $$
declare actor uuid:=app.require_permission(p_org,'webhook.manage'); idv uuid:=gen_random_uuid(); h text; replay jsonb;
begin
 if not app.feature_enabled(p_org,'feature.outbound_webhooks') then raise exception 'ARV-USAGE-6001 webhooks not entitled'; end if;
 if not app.webhook_endpoint_is_obviously_safe(trim(p_endpoint)) then raise exception 'ARV-VALIDATION-1001 unsafe webhook endpoint'; end if;
 if trim(coalesce(p_secret_reference,''))='' or p_secret_reference ~* '(secret|token|key)=[^/ ]+' then raise exception 'ARV-VALIDATION-1001 signing secret reference required'; end if;
 h:=app.command_hash(jsonb_build_array(p_name,trim(p_endpoint),p_secret_reference,to_jsonb(coalesce(p_events,'{}'::text[])))); perform app.command_lock(p_org,'webhook.create',p_key); replay:=app.idempotency_existing(p_org,actor,'webhook.create',p_key,h); if replay is not null then return (replay->>'webhook_id')::uuid; end if;
 insert into public.outbound_webhooks(id,organization_id,name,endpoint_url,signing_secret_reference,subscribed_events) values(idv,p_org,trim(p_name),trim(p_endpoint),p_secret_reference,coalesce(p_events,'{}'::text[])); perform app.idempotency_commit(p_org,actor,'webhook.create',p_key,h,jsonb_build_object('webhook_id',idv)); return idv;
end $$;

-- P2 least-privilege surface.
revoke execute on function app.seed_ultra_permissions(uuid),app.branch_allowed(uuid,uuid),app.approval_payload_valid(text,jsonb),app.webhook_endpoint_is_obviously_safe(text),app.execute_approved_action(uuid),app.authorize_api_token(text,text),app.enqueue_outbound_webhooks(uuid) from public,anon,authenticated;
grant execute on function app.execute_approved_action(uuid),app.authorize_api_token(text,text),app.enqueue_outbound_webhooks(uuid) to service_role;
grant execute on function app.create_branch(uuid,text,text,text,jsonb,text),app.create_custom_role(uuid,text,text[],text),app.request_approval(uuid,text,uuid,text,jsonb,int,timestamptz,text),app.decide_approval(uuid,uuid,text,text,text),app.create_sla_contract(uuid,uuid,text,int,int,jsonb,text,date,date,jsonb,text),app.create_ticket(uuid,uuid,uuid,uuid,text,text,text,text),app.ticket_action(uuid,uuid,text,int,text,text),app.create_api_token(uuid,text,text[],timestamptz,text),app.revoke_api_token(uuid,uuid,text),app.create_outbound_webhook(uuid,text,text,text,text[],text) to authenticated;
