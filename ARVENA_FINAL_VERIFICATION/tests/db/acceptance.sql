\set ON_ERROR_STOP on
-- Structural and invariant acceptance that is independent of UI.
do $$ begin
  if (select minor_unit_exponent from currency_definitions where currency_code='IDR') <> 0 then raise exception 'IDR exponent'; end if;
  if (select minor_unit_exponent from currency_definitions where currency_code='USD') <> 2 then raise exception 'USD exponent'; end if;
  if exists(select 1 from quotes where status='SENT') then raise exception 'SENT must not be canonical backend state'; end if;
  if exists(select 1 from payments where amount_minor<=0) then raise exception 'payment amount invariant'; end if;
end $$;
-- Composite tenant FK must reject Org A child referencing Org B parent.
do $$ begin
  begin
    insert into customer_addresses(organization_id,customer_id,label,line1,country_code)
    values('aaaaaaaa-0000-0000-0000-000000000001','b2000001-0000-0000-0000-000000000001','bad','bad','ID');
    raise exception 'cross-tenant FK unexpectedly accepted';
  exception when foreign_key_violation then null; end;
end $$;
