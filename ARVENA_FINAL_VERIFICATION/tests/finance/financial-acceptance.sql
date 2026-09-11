\set ON_ERROR_STOP on
-- Verify stored projections and financial immutability on fixture invoice.
do $$ begin
 if (select paid_minor from invoices where id='ab000001-0000-0000-0000-000000000001') <> 40000 then raise exception 'partial paid projection'; end if;
 if (select outstanding_minor from invoices where id='ab000001-0000-0000-0000-000000000001') <> 60000 then raise exception 'partial outstanding projection'; end if;
 begin update payments set amount_minor=41000 where id='ac000001-0000-0000-0000-000000000001'; raise exception 'payment mutation accepted'; exception when others then if sqlerrm='payment mutation accepted' then raise; end if; end;
 begin update invoices set total_minor=99999 where id='ab000001-0000-0000-0000-000000000001'; raise exception 'issued invoice mutation accepted'; exception when others then if sqlerrm='issued invoice mutation accepted' then raise; end if; end;
end $$;
