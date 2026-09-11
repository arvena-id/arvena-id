\set ON_ERROR_STOP on
do $$ begin
 if not exists(select 1 from import_jobs where id='a1300001-0000-0000-0000-000000000001' and organization_id='aaaaaaaa-0000-0000-0000-000000000001') then raise exception 'import fixture missing'; end if;
 if not exists(select 1 from export_jobs where id='a1400001-0000-0000-0000-000000000001' and dataset='CUSTOMERS') then raise exception 'export fixture missing'; end if;
end $$;
