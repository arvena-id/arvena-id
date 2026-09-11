\set ON_ERROR_STOP on
-- Canonical occurrence identity must be unique per rule/local occurrence.
do $$ begin
  if not exists(select 1 from recurring_rules where timezone='Asia/Jakarta') then raise exception 'Jakarta fixture missing'; end if;
  if not exists(select 1 from recurring_rules where timezone='America/New_York') then raise exception 'New York fixture missing'; end if;
end $$;
