\set ON_ERROR_STOP on
-- Utility to impersonate a JWT user in the compatibility harness.
-- The setting must persist across autocommit statements; transaction-local=true
-- would clear the subject immediately after the helper SELECT completes.
create or replace function pg_temp.as_user(p uuid) returns void language plpgsql as $$ begin perform set_config('request.jwt.claim.sub',p::text,false); end $$;

-- Unauthenticated tenant SELECT must return no rows.
select set_config('request.jwt.claim.sub','',false);
do $$ begin if (select count(*) from customers) <> 0 then raise exception 'unauthenticated tenant leak'; end if; end $$;

-- Org A owner: bind active organization, then own Customer visible and Org B invisible.
select pg_temp.as_user('10000000-0000-0000-0000-000000000001');
select app.set_active_organization('aaaaaaaa-0000-0000-0000-000000000001');
do $$ begin
 if not exists(select 1 from customers where id='a2000001-0000-0000-0000-000000000001') then raise exception 'owner allow failed'; end if;
 if exists(select 1 from customers where id='b2000001-0000-0000-0000-000000000001') then raise exception 'cross-tenant customer leak'; end if;
 if exists(select 1 from invoices where organization_id='bbbbbbbb-0000-0000-0000-000000000001') then raise exception 'cross-tenant invoice leak'; end if;
end $$;

-- Disabled and invited members must have no tenant access and cannot establish active context.
select pg_temp.as_user('10000000-0000-0000-0000-000000000010');
do $$ begin if exists(select 1 from customers) then raise exception 'disabled member leak'; end if; end $$;
select pg_temp.as_user('10000000-0000-0000-0000-000000000011');
do $$ begin if exists(select 1 from customers) then raise exception 'invited member leak'; end if; end $$;

-- Sales scope: Sales 1 sees assigned A1 but not Sales 2 A2.
select pg_temp.as_user('10000000-0000-0000-0000-000000000004');
select app.set_active_organization('aaaaaaaa-0000-0000-0000-000000000001');
do $$ begin
 if not exists(select 1 from leads where id='a3000001-0000-0000-0000-000000000001') then raise exception 'assigned sales allow failed'; end if;
 if exists(select 1 from leads where id='a3000002-0000-0000-0000-000000000001') then raise exception 'sales unassigned lead leak'; end if;
end $$;

-- Worker must not see billing or base Customer rows and must not see unrelated Visit.
select pg_temp.as_user('10000000-0000-0000-0000-000000000006');
select app.set_active_organization('aaaaaaaa-0000-0000-0000-000000000001');
do $$ begin
 if not exists(select 1 from visits where id='a6000001-0000-0000-0000-000000000001') then raise exception 'assigned worker visit allow failed'; end if;
 if exists(select 1 from visits where id='a6000002-0000-0000-0000-000000000001') then raise exception 'worker unrelated visit leak'; end if;
 if exists(select 1 from invoices) then raise exception 'worker invoice leak'; end if;
 if exists(select 1 from payments) then raise exception 'worker payment leak'; end if;
 -- Binding contract requires minimized execution context; direct full Customer base row is a release blocker.
 if exists(select 1 from customers where id='a2000001-0000-0000-0000-000000000001') then raise exception 'worker receives full customer base row instead of minimized execution context'; end if;
end $$;

-- Admin without finance cannot issue invoice; explicit finance-granted Admin can.
select pg_temp.as_user('10000000-0000-0000-0000-000000000003');
select app.set_active_organization('aaaaaaaa-0000-0000-0000-000000000001');
do $$ begin if app.has_permission('aaaaaaaa-0000-0000-0000-000000000001','invoice.issue') then raise exception 'admin without finance unexpectedly allowed'; end if; end $$;
select pg_temp.as_user('10000000-0000-0000-0000-000000000002');
select app.set_active_organization('aaaaaaaa-0000-0000-0000-000000000001');
do $$ begin if not app.has_permission('aaaaaaaa-0000-0000-0000-000000000001','invoice.issue') then raise exception 'admin explicit finance grant missing'; end if; end $$;

-- Multi-org user must resolve exactly one active organization in request context.
select pg_temp.as_user('30000000-0000-0000-0000-000000000001');
select app.set_active_organization('aaaaaaaa-0000-0000-0000-000000000001');
do $$ begin
 if app.current_member_id('aaaaaaaa-0000-0000-0000-000000000001') is null then
   raise exception 'active organization member missing';
 end if;
 if app.current_member_id('bbbbbbbb-0000-0000-0000-000000000001') is not null then
   raise exception 'active organization is not bound to one request context';
 end if;
end $$;