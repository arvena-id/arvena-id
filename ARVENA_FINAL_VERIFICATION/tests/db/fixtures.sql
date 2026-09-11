\set ON_ERROR_STOP on
-- Deterministic ARVENA P0 acceptance fixtures.
insert into auth.users(id,email) values
('10000000-0000-0000-0000-000000000001','owner-a@example.test'),
('10000000-0000-0000-0000-000000000002','admin-fin-a@example.test'),
('10000000-0000-0000-0000-000000000003','admin-a@example.test'),
('10000000-0000-0000-0000-000000000004','sales1-a@example.test'),
('10000000-0000-0000-0000-000000000005','sales2-a@example.test'),
('10000000-0000-0000-0000-000000000006','worker1-a@example.test'),
('10000000-0000-0000-0000-000000000007','worker2-a@example.test'),
('10000000-0000-0000-0000-000000000008','supervisor-a@example.test'),
('10000000-0000-0000-0000-000000000009','finance-a@example.test'),
('10000000-0000-0000-0000-000000000010','disabled-a@example.test'),
('10000000-0000-0000-0000-000000000011','invited-a@example.test'),
('20000000-0000-0000-0000-000000000001','owner-b@example.test'),
('20000000-0000-0000-0000-000000000002','admin-fin-b@example.test'),
('20000000-0000-0000-0000-000000000003','admin-b@example.test'),
('20000000-0000-0000-0000-000000000004','sales1-b@example.test'),
('20000000-0000-0000-0000-000000000005','sales2-b@example.test'),
('20000000-0000-0000-0000-000000000006','worker1-b@example.test'),
('20000000-0000-0000-0000-000000000007','worker2-b@example.test'),
('20000000-0000-0000-0000-000000000008','supervisor-b@example.test'),
('20000000-0000-0000-0000-000000000009','finance-b@example.test'),
('20000000-0000-0000-0000-000000000010','disabled-b@example.test'),
('20000000-0000-0000-0000-000000000011','invited-b@example.test'),
('30000000-0000-0000-0000-000000000001','multi-org@example.test')
on conflict do nothing;

insert into organizations(id,name,slug,country_code,currency_code,timezone,locale,status) values
('aaaaaaaa-0000-0000-0000-000000000001','Org A','org-a','ID','IDR','Asia/Jakarta','id-ID','ACTIVE'),
('bbbbbbbb-0000-0000-0000-000000000001','Org B','org-b','US','USD','America/New_York','en-US','ACTIVE')
on conflict do nothing;

insert into organization_settings(id,organization_id,localization) values
('a0000000-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000001','{"timezone":"Asia/Jakarta","currency":"IDR"}'),
('b0000000-0000-0000-0000-000000000001','bbbbbbbb-0000-0000-0000-000000000001','{"timezone":"America/New_York","currency":"USD"}')
on conflict(organization_id) do nothing;

insert into roles(id,organization_id,name,system_key,is_system_role) values
('a0000001-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000001','Owner','OWNER',true),
('a0000002-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000001','Admin','ADMIN',true),
('a0000003-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000001','Sales','SALES',true),
('a0000004-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000001','Worker','WORKER',true),
('a0000005-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000001','Supervisor','SUPERVISOR',true),
('a0000006-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000001','Finance','FINANCE',true),
('b0000001-0000-0000-0000-000000000001','bbbbbbbb-0000-0000-0000-000000000001','Owner','OWNER',true),
('b0000002-0000-0000-0000-000000000001','bbbbbbbb-0000-0000-0000-000000000001','Admin','ADMIN',true),
('b0000003-0000-0000-0000-000000000001','bbbbbbbb-0000-0000-0000-000000000001','Sales','SALES',true),
('b0000004-0000-0000-0000-000000000001','bbbbbbbb-0000-0000-0000-000000000001','Worker','WORKER',true),
('b0000005-0000-0000-0000-000000000001','bbbbbbbb-0000-0000-0000-000000000001','Supervisor','SUPERVISOR',true),
('b0000006-0000-0000-0000-000000000001','bbbbbbbb-0000-0000-0000-000000000001','Finance','FINANCE',true)
on conflict do nothing;

insert into role_permissions(organization_id,role_id,permission_key,allowed)
select r.organization_id,r.id,p,true from roles r cross join unnest(array[
'organization.manage','member.view','member.invite','member.update','role.view','role.manage','customer.view','customer.create','customer.update',
'lead.view','lead.create','lead.update','lead.reopen','lead.convert','quote.view','quote.create','quote.update_draft','quote.issue','quote.accept','job.view','job.create','job.update','job.confirm','job.complete','job.cancel','job.hold','visit.view','visit.schedule','visit.reschedule','visit.assign','visit.depart_assigned','visit.arrive_assigned','visit.start_assigned','visit.finish_assigned','checklist.respond_assigned','media.view','media.create','media.finalize','media.retry','note.view','note.create','note.update_own','invoice.view','invoice.create','invoice.update_draft','invoice.issue','invoice.void','payment.view','payment.record','payment.reverse','asset.manage','recurring.view','recurring.manage','followup.create','followup.update','import.customer','import.asset_basic','export.basic','settings.tax','settings.localization','settings.workflow','billing.manage','notification.preference_manage','audit.critical_view'
]) p where r.system_key='OWNER'
on conflict(organization_id,role_id,permission_key) do update set allowed=excluded.allowed;

insert into role_permissions(organization_id,role_id,permission_key,allowed)
select r.organization_id,r.id,p,true from roles r join lateral unnest(
case r.system_key
 when 'ADMIN' then array['member.view','customer.view','customer.create','customer.update','lead.view','lead.create','lead.update','quote.view','quote.create','quote.update_draft','job.view','job.create','job.update','visit.view','visit.schedule','visit.reschedule','visit.assign','asset.manage','followup.create','followup.update']
 when 'SALES' then array['customer.view','customer.create','customer.update','lead.view','lead.create','lead.update','quote.view','quote.create','quote.update_draft','followup.create','followup.update']
 when 'WORKER' then array['job.view','visit.view','visit.depart_assigned','visit.arrive_assigned','visit.start_assigned','visit.finish_assigned','checklist.respond_assigned','media.view','media.create','media.finalize','media.retry','note.view','note.create']
 when 'SUPERVISOR' then array['member.view','customer.view','job.view','visit.view','visit.schedule','visit.reschedule','visit.assign']
 when 'FINANCE' then array['customer.view','invoice.view','invoice.create','invoice.update_draft','invoice.issue','invoice.void','payment.view','payment.record','payment.reverse','export.basic']
 else array[]::text[] end
) p on true where r.system_key<>'OWNER'
on conflict(organization_id,role_id,permission_key) do update set allowed=excluded.allowed;

insert into organization_members(id,organization_id,user_id,role_id,status,joined_at) values
('a1000001-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001','a0000001-0000-0000-0000-000000000001','ACTIVE',now()),
('a1000002-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000002','a0000002-0000-0000-0000-000000000001','ACTIVE',now()),
('a1000003-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000003','a0000002-0000-0000-0000-000000000001','ACTIVE',now()),
('a1000004-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000004','a0000003-0000-0000-0000-000000000001','ACTIVE',now()),
('a1000005-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000005','a0000003-0000-0000-0000-000000000001','ACTIVE',now()),
('a1000006-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000006','a0000004-0000-0000-0000-000000000001','ACTIVE',now()),
('a1000007-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000007','a0000004-0000-0000-0000-000000000001','ACTIVE',now()),
('a1000008-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000008','a0000005-0000-0000-0000-000000000001','ACTIVE',now()),
('a1000009-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000009','a0000006-0000-0000-0000-000000000001','ACTIVE',now()),
('a1000010-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000010','a0000003-0000-0000-0000-000000000001','DISABLED',now()),
('a1000011-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000011','a0000003-0000-0000-0000-000000000001','INVITED',null),
('a1000012-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000001','a0000003-0000-0000-0000-000000000001','ACTIVE',now()),
('b1000001-0000-0000-0000-000000000001','bbbbbbbb-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000001','b0000001-0000-0000-0000-000000000001','ACTIVE',now()),
('b1000002-0000-0000-0000-000000000001','bbbbbbbb-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000002','b0000002-0000-0000-0000-000000000001','ACTIVE',now()),
('b1000003-0000-0000-0000-000000000001','bbbbbbbb-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000003','b0000002-0000-0000-0000-000000000001','ACTIVE',now()),
('b1000004-0000-0000-0000-000000000001','bbbbbbbb-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000004','b0000003-0000-0000-0000-000000000001','ACTIVE',now()),
('b1000005-0000-0000-0000-000000000001','bbbbbbbb-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000005','b0000003-0000-0000-0000-000000000001','ACTIVE',now()),
('b1000006-0000-0000-0000-000000000001','bbbbbbbb-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000006','b0000004-0000-0000-0000-000000000001','ACTIVE',now()),
('b1000007-0000-0000-0000-000000000001','bbbbbbbb-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000007','b0000004-0000-0000-0000-000000000001','ACTIVE',now()),
('b1000008-0000-0000-0000-000000000001','bbbbbbbb-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000008','b0000005-0000-0000-0000-000000000001','ACTIVE',now()),
('b1000009-0000-0000-0000-000000000001','bbbbbbbb-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000009','b0000006-0000-0000-0000-000000000001','ACTIVE',now()),
('b1000010-0000-0000-0000-000000000001','bbbbbbbb-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000010','b0000003-0000-0000-0000-000000000001','DISABLED',now()),
('b1000011-0000-0000-0000-000000000001','bbbbbbbb-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000011','b0000003-0000-0000-0000-000000000001','INVITED',null),
('b1000012-0000-0000-0000-000000000001','bbbbbbbb-0000-0000-0000-000000000001','30000000-0000-0000-0000-000000000001','b0000003-0000-0000-0000-000000000001','ACTIVE',now())
on conflict do nothing;

insert into member_permission_overrides(id,organization_id,member_id,permission_key,effect,reason,actor_member_id) values
('a1100001-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000001','a1000002-0000-0000-0000-000000000001','invoice.issue','ALLOW','fixture','a1000001-0000-0000-0000-000000000001'),
('a1100002-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000001','a1000002-0000-0000-0000-000000000001','payment.record','ALLOW','fixture','a1000001-0000-0000-0000-000000000001'),
('b1100001-0000-0000-0000-000000000001','bbbbbbbb-0000-0000-0000-000000000001','b1000002-0000-0000-0000-000000000001','invoice.issue','ALLOW','fixture','b1000001-0000-0000-0000-000000000001'),
('b1100002-0000-0000-0000-000000000001','bbbbbbbb-0000-0000-0000-000000000001','b1000002-0000-0000-0000-000000000001','payment.record','ALLOW','fixture','b1000001-0000-0000-0000-000000000001')
on conflict do nothing;

insert into member_team_scope(organization_id,supervisor_member_id,member_id) values
('aaaaaaaa-0000-0000-0000-000000000001','a1000008-0000-0000-0000-000000000001','a1000006-0000-0000-0000-000000000001'),
('bbbbbbbb-0000-0000-0000-000000000001','b1000008-0000-0000-0000-000000000001','b1000006-0000-0000-0000-000000000001') on conflict do nothing;

insert into customers(id,organization_id,type,name,raw_phone,normalized_phone,source,assigned_sales_id,status) values
('a2000001-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000001','PERSON','Customer A1','081200000001','+6281200000001','MANUAL','a1000004-0000-0000-0000-000000000001','ACTIVE'),
('a2000002-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000001','COMPANY','Customer A2','081200000002','+6281200000002','MANUAL','a1000005-0000-0000-0000-000000000001','ACTIVE'),
('b2000001-0000-0000-0000-000000000001','bbbbbbbb-0000-0000-0000-000000000001','PERSON','Customer B1','2125550001','+12125550001','MANUAL','b1000004-0000-0000-0000-000000000001','ACTIVE') on conflict do nothing;

insert into customer_addresses(id,organization_id,customer_id,label,line1,city,country_code,is_primary) values
('a2100001-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000001','a2000001-0000-0000-0000-000000000001','Home','Jl. Fixture 1','Jakarta','ID',true),
('b2100001-0000-0000-0000-000000000001','bbbbbbbb-0000-0000-0000-000000000001','b2000001-0000-0000-0000-000000000001','Office','1 Fixture Ave','New York','US',true) on conflict do nothing;

insert into leads(id,organization_id,customer_id,title,status,temperature,source,assigned_sales_id,currency_code) values
('a3000001-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000001','a2000001-0000-0000-0000-000000000001','Lead A1','NEW','WARM','MANUAL','a1000004-0000-0000-0000-000000000001','IDR'),
('a3000002-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000001','a2000002-0000-0000-0000-000000000001','Lead A2','NEW','COLD','MANUAL','a1000005-0000-0000-0000-000000000001','IDR'),
('b3000001-0000-0000-0000-000000000001','bbbbbbbb-0000-0000-0000-000000000001','b2000001-0000-0000-0000-000000000001','Lead B1','NEW','WARM','MANUAL','b1000004-0000-0000-0000-000000000001','USD') on conflict do nothing;

insert into quotes(id,organization_id,quote_number,customer_id,lead_id,owner_member_id,status,currency_code,currency_exponent,subtotal_minor,discount_minor,tax_minor,total_minor,expires_at,issued_at,customer_snapshot,organization_snapshot,calculator_version) values
('a4000001-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000001','QTE-A-1','a2000001-0000-0000-0000-000000000001','a3000001-0000-0000-0000-000000000001','a1000004-0000-0000-0000-000000000001','DRAFT','IDR',0,100000,0,0,100000,now()+interval '14 days',null,'{}','{}','v1'),
('b4000001-0000-0000-0000-000000000001','bbbbbbbb-0000-0000-0000-000000000001','QTE-B-1','b2000001-0000-0000-0000-000000000001','b3000001-0000-0000-0000-000000000001','b1000004-0000-0000-0000-000000000001','DRAFT','USD',2,10000,0,0,10000,now()+interval '14 days',null,'{}','{}','v1') on conflict do nothing;
insert into quote_items(id,organization_id,quote_id,name_snapshot,quantity,unit_price_minor,gross_minor,net_minor,total_minor,sort_order) values
('a4100001-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000001','a4000001-0000-0000-0000-000000000001','Service A',1,100000,100000,100000,100000,1),
('b4100001-0000-0000-0000-000000000001','bbbbbbbb-0000-0000-0000-000000000001','b4000001-0000-0000-0000-000000000001','Service B',1,10000,10000,10000,10000,1) on conflict do nothing;
update quotes set status='ISSUED', issued_at=now() where id in ('a4000001-0000-0000-0000-000000000001','b4000001-0000-0000-0000-000000000001');

insert into jobs(id,organization_id,job_number,customer_id,lead_id,title,status,priority,primary_address_id,currency_code,version) values
('a5000001-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000001','JOB-A-1','a2000001-0000-0000-0000-000000000001','a3000001-0000-0000-0000-000000000001','Job A1','CONFIRMED','NORMAL','a2100001-0000-0000-0000-000000000001','IDR',1),
('b5000001-0000-0000-0000-000000000001','bbbbbbbb-0000-0000-0000-000000000001','JOB-B-1','b2000001-0000-0000-0000-000000000001','b3000001-0000-0000-0000-000000000001','Job B1','CONFIRMED','NORMAL','b2100001-0000-0000-0000-000000000001','USD',1) on conflict do nothing;

insert into visits(id,organization_id,job_id,status,scheduled_start,scheduled_end,scheduled_local_start,scheduled_local_end,timezone,version,address_snapshot) values
('a6000001-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000001','a5000001-0000-0000-0000-000000000001','SCHEDULED','2026-09-10T02:00:00Z','2026-09-10T03:00:00Z','2026-09-10 09:00','2026-09-10 10:00','Asia/Jakarta',1,'{}'),
('a6000002-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000001','a5000001-0000-0000-0000-000000000001','SCHEDULED','2026-09-11T02:00:00Z','2026-09-11T03:00:00Z','2026-09-11 09:00','2026-09-11 10:00','Asia/Jakarta',1,'{}'),
('b6000001-0000-0000-0000-000000000001','bbbbbbbb-0000-0000-0000-000000000001','b5000001-0000-0000-0000-000000000001','SCHEDULED','2026-09-10T13:00:00Z','2026-09-10T14:00:00Z','2026-09-10 09:00','2026-09-10 10:00','America/New_York',1,'{}') on conflict do nothing;
insert into visit_assignments(id,organization_id,visit_id,member_id,assignment_role) values
('a6100001-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000001','a6000001-0000-0000-0000-000000000001','a1000006-0000-0000-0000-000000000001','WORKER'),
('b6100001-0000-0000-0000-000000000001','bbbbbbbb-0000-0000-0000-000000000001','b6000001-0000-0000-0000-000000000001','b1000006-0000-0000-0000-000000000001','WORKER') on conflict do nothing;

insert into follow_ups(id,organization_id,customer_id,lead_id,assigned_to,reason,due_at,timezone,status) values
('a7000001-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000001','a2000001-0000-0000-0000-000000000001','a3000001-0000-0000-0000-000000000001','a1000004-0000-0000-0000-000000000001','LEAD',now()-interval '1 day','Asia/Jakarta','PENDING'),
('b7000001-0000-0000-0000-000000000001','bbbbbbbb-0000-0000-0000-000000000001','b2000001-0000-0000-0000-000000000001','b3000001-0000-0000-0000-000000000001','b1000004-0000-0000-0000-000000000001','LEAD',now()+interval '1 day','America/New_York','PENDING') on conflict do nothing;

insert into job_checklists(id,organization_id,job_id,visit_id,template_snapshot,status,required) values
('a8000001-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000001','a5000001-0000-0000-0000-000000000001','a6000001-0000-0000-0000-000000000001','{"items":[{"key":"done","required":true}]}','IN_PROGRESS',true),
('b8000001-0000-0000-0000-000000000001','bbbbbbbb-0000-0000-0000-000000000001','b5000001-0000-0000-0000-000000000001','b6000001-0000-0000-0000-000000000001','{"items":[{"key":"done","required":true}]}','IN_PROGRESS',true) on conflict do nothing;
insert into checklist_responses(id,organization_id,job_checklist_id,template_item_key,value,completed_by) values
('a8100001-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000001','a8000001-0000-0000-0000-000000000001','done','true','a1000006-0000-0000-0000-000000000001'),
('b8100001-0000-0000-0000-000000000001','bbbbbbbb-0000-0000-0000-000000000001','b8000001-0000-0000-0000-000000000001','done','true','b1000006-0000-0000-0000-000000000001') on conflict do nothing;

insert into assets(id,organization_id,customer_id,asset_type,name,status,notes) values
('a9000001-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000001','a2000001-0000-0000-0000-000000000001','AC','AC A1','ACTIVE','fixture'),
('b9000001-0000-0000-0000-000000000001','bbbbbbbb-0000-0000-0000-000000000001','b2000001-0000-0000-0000-000000000001','ROUTER','Router B1','ACTIVE','fixture') on conflict do nothing;

insert into media(id,organization_id,parent_type,parent_id,category,storage_key,mime_type,checksum,size_bytes,upload_status,quota_reserved_bytes,attempts,uploaded_by) values
('aa000001-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000001','VISIT','a6000001-0000-0000-0000-000000000001','AFTER','aaaaaaaa/visits/a.jpg','image/jpeg','aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',100,'UPLOADED',0,1,'a1000006-0000-0000-0000-000000000001'),
('ba000001-0000-0000-0000-000000000001','bbbbbbbb-0000-0000-0000-000000000001','VISIT','b6000001-0000-0000-0000-000000000001','AFTER','bbbbbbbb/visits/b.jpg','image/jpeg','bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',100,'UPLOADED',0,1,'b1000006-0000-0000-0000-000000000001') on conflict do nothing;

insert into invoices(id,organization_id,invoice_number,customer_id,job_id,status,currency_code,currency_exponent,subtotal_minor,discount_minor,tax_minor,total_minor,paid_minor,outstanding_minor,issued_at,customer_snapshot,organization_snapshot,calculator_version,version) values
('ab000001-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000001','INV-A-1','a2000001-0000-0000-0000-000000000001','a5000001-0000-0000-0000-000000000001','PARTIALLY_PAID','IDR',0,100000,0,0,100000,40000,60000,now(),'{}','{}','v1',1),
('bb000001-0000-0000-0000-000000000001','bbbbbbbb-0000-0000-0000-000000000001','INV-B-1','b2000001-0000-0000-0000-000000000001','b5000001-0000-0000-0000-000000000001','ISSUED','USD',2,10000,0,0,10000,0,10000,now(),'{}','{}','v1',1) on conflict do nothing;
insert into payments(id,organization_id,invoice_id,amount_minor,currency_code,method,paid_at,received_by,status,idempotency_key) values
('ac000001-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000001','ab000001-0000-0000-0000-000000000001',40000,'IDR','BANK_TRANSFER',now(),'a1000001-0000-0000-0000-000000000001','SETTLED','fixture-partial-a') on conflict do nothing;

insert into recurring_rules(id,organization_id,customer_id,asset_id,recurrence_type,interval_value,local_time,timezone,starts_on,next_occurrence_at,active,version,template_data) values
('ad000001-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000001','a2000001-0000-0000-0000-000000000001','a9000001-0000-0000-0000-000000000001','MONTHLY',1,'09:00','Asia/Jakarta','2026-09-01','2026-10-01T02:00:00Z',true,1,'{}'),
('bd000001-0000-0000-0000-000000000001','bbbbbbbb-0000-0000-0000-000000000001','b2000001-0000-0000-0000-000000000001','b9000001-0000-0000-0000-000000000001','MONTHLY',1,'02:30','America/New_York','2026-01-01','2026-11-01T06:30:00Z',true,1,'{}') on conflict do nothing;
insert into recurring_occurrences(id,organization_id,recurring_rule_id,intended_local_date,intended_local_time,timezone,resolved_occurrence_at,resolved_offset_minutes,dst_resolution,rule_version,rule_snapshot,status) values
('ae000001-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000001','ad000001-0000-0000-0000-000000000001','2026-10-01','09:00','Asia/Jakarta','2026-10-01T02:00:00Z',420,'EXACT',1,'{}','PENDING'),
('be000001-0000-0000-0000-000000000001','bbbbbbbb-0000-0000-0000-000000000001','bd000001-0000-0000-0000-000000000001','2026-11-01','02:30','America/New_York','2026-11-01T06:30:00Z',-240,'DST_OVERLAP_EARLIER_OFFSET',1,'{}','PENDING') on conflict do nothing;

-- Free subscriptions and usage boundary fixtures.
insert into subscriptions(id,organization_id,plan_version_id,status,period_start,period_end)
select 'af000001-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000001',id,'ACTIVE','2026-09-01T00:00:00Z','2026-10-01T00:00:00Z' from plan_versions where plan_key='FREE' and version=1
on conflict do nothing;
insert into subscriptions(id,organization_id,plan_version_id,status,period_start,period_end)
select 'bf000001-0000-0000-0000-000000000001','bbbbbbbb-0000-0000-0000-000000000001',id,'ACTIVE','2026-09-01T00:00:00Z','2026-10-01T00:00:00Z' from plan_versions where plan_key='FREE' and version=1
on conflict do nothing;
insert into usage_counters(id,organization_id,period_start,period_end,metric_key,value,reserved) values
('a1200001-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000001','2026-09-01T00:00:00Z','2026-10-01T00:00:00Z','jobs_created',24,0),
('b1200001-0000-0000-0000-000000000001','bbbbbbbb-0000-0000-0000-000000000001','2026-09-01T00:00:00Z','2026-10-01T00:00:00Z','jobs_created',30,0) on conflict do nothing;

insert into import_jobs(id,organization_id,actor_member_id,kind,mapping,status,valid_count,duplicate_count,error_count,committed_count,command_key) values
('a1300001-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000001','a1000001-0000-0000-0000-000000000001','CUSTOMERS','{}','VALIDATED',1,1,1,0,'fixture-import-a') on conflict do nothing;
insert into import_rows(id,organization_id,import_job_id,source_row,normalized_payload,validation_errors,duplicate_customer_id,duplicate_decision,commit_state) values
('a1310001-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000001','a1300001-0000-0000-0000-000000000001',1,'{"name":"New Customer"}','[]',null,null,'PENDING'),
('a1310002-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000001','a1300001-0000-0000-0000-000000000001',2,'{"name":"Duplicate"}','[]','a2000001-0000-0000-0000-000000000001','USE_EXISTING','PENDING'),
('a1310003-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000001','a1300001-0000-0000-0000-000000000001',3,'{}','["name required"]',null,'SKIP','PENDING') on conflict do nothing;
insert into export_jobs(id,organization_id,actor_member_id,dataset,filter,state,expires_at,command_key) values
('a1400001-0000-0000-0000-000000000001','aaaaaaaa-0000-0000-0000-000000000001','a1000001-0000-0000-0000-000000000001','CUSTOMERS','{}','PENDING',now()+interval '24 hours','fixture-export-a') on conflict do nothing;
