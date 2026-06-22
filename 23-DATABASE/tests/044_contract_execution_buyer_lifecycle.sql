-- CC-13 Test 044 — Buyer executed contract lifecycle:
--   create from ready_for_contract preparation → items + clauses + parties + initial snapshot derived
--   → update draft → add party → create signature request → mark pending_signatures
--   → create executed snapshot → executed contract locks normal edits when in pending state.
--
-- Assertions (11):
--   1. buyer_create_executed_contract creates contract with status='draft_execution'
--   2. items derived from preparation items
--   3. clauses derived from preparation clauses
--   4. parties auto-created: buyer + supplier (count = 2)
--   5. initial_from_preparation snapshot auto-created
--   6. buyer_update_executed_contract patches incoterm
--   7. buyer_add_party adds a witness party
--   8. buyer_create_signature_request creates pending signature
--   9. buyer_mark_pending_signatures transitions draft_execution → pending_signatures
--  10. buyer_create_executed_snapshot persists a pending_signature_snapshot
--  11. pending_signatures contract is locked from buyer_update (P0001)

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, tests;
begin;

-- Fixtures: 1 buyer + 1 supplier, full chain through ready_for_contract preparation.
insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '10000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '044-buyer@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '10000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', '044-sup@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('10000000-0000-0000-0000-00000000000a', 'tenant-044', 'تست', 'Test');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('10000000-0000-0000-0000-00000000001a', '10000000-0000-0000-0000-00000000000a',
   'buyer-044', 'خریدار', 'Buyer 044', 'buyer', 'active'),
  ('10000000-0000-0000-0000-00000000002a', '10000000-0000-0000-0000-00000000000a',
   'sup-044', 'تأمین', 'Supplier 044', 'supplier', 'active');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('10000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-00000000000a',
   '10000000-0000-0000-0000-00000000001a', 'Buyer', 'fa', 'active'),
  ('10000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-00000000000a',
   '10000000-0000-0000-0000-00000000002a', 'Supplier', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '10000000-0000-0000-0000-00000000000a', '10000000-0000-0000-0000-00000000001a',
       '10000000-0000-0000-0000-000000000001', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '10000000-0000-0000-0000-00000000000a', '10000000-0000-0000-0000-00000000002a',
       '10000000-0000-0000-0000-000000000002', r.id, 'active', now()
  from identity.roles r where r.code = 'supplier_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '10000000-0000-0000-0000-000000000001', r.id, 'organization', '10000000-0000-0000-0000-00000000001a'
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '10000000-0000-0000-0000-000000000002', r.id, 'organization', '10000000-0000-0000-0000-00000000002a'
  from identity.roles r where r.code = 'supplier_admin';

-- Build through preparation in ready_for_contract.
do $$
declare
  v_sup uuid; v_prod uuid; v_rfq uuid; v_item uuid; v_off uuid; v_dec uuid; v_prep uuid;
begin
  select id into v_sup  from supplier.suppliers where organization_id = '10000000-0000-0000-0000-00000000002a';
  select id into v_prod from commodity.products where code = 'methanol';

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','10000000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','10000000-0000-0000-0000-00000000000a',
                       'organization_id','10000000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '10000000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_rfq := rfq.buyer_create_rfq(p_title => 'R for executed contract lifecycle');
  v_item := rfq.buyer_upsert_rfq_item(p_request_id => v_rfq, p_product_id => v_prod,
                                       p_quantity => 1000, p_quantity_unit => 'ton');
  perform rfq.buyer_submit_rfq(v_rfq);
  perform rfq.buyer_invite_suppliers(v_rfq, array[v_sup]);
  reset role;

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','10000000-0000-0000-0000-000000000002','role','authenticated',
                       'tenant_id','10000000-0000-0000-0000-00000000000a',
                       'organization_id','10000000-0000-0000-0000-00000000002a')::text, true);
  perform set_config('request.jwt.claim.sub', '10000000-0000-0000-0000-000000000002', true);
  set local role authenticated;
  v_off := offer.supplier_create_draft_offer(p_request_id => v_rfq);
  perform offer.supplier_upsert_offer_item(p_offer_id => v_off, p_request_item_id => v_item,
    p_offered_quantity => 1000, p_quantity_unit => 'ton', p_unit_price => 380, p_currency => 'USD');
  perform offer.supplier_submit_my_offer(v_off);
  reset role;

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','10000000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','10000000-0000-0000-0000-00000000000a',
                       'organization_id','10000000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '10000000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_dec := evaluation.buyer_select_for_contract(p_offer_id => v_off);
  v_prep := contract.buyer_create_preparation(p_decision_id => v_dec, p_title => 'lifecycle prep');
  perform contract.buyer_upsert_clause(
    p_preparation_id => v_prep,
    p_clause_type => 'payment'::contract.preparation_clause_type,
    p_clause_key => 'std', p_title_en => 'Payment', p_body_en => 'Net 30'
  );
  perform contract.buyer_mark_ready_for_contract(v_prep);
  reset role;

  perform set_config('test.prep', v_prep::text, false);
end;
$$;

select plan(11);

-- 1. Create executed contract.
select tests.authenticate_as(
  '10000000-0000-0000-0000-000000000001',
  '10000000-0000-0000-0000-00000000000a',
  '10000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
do $$
declare v_c uuid;
begin
  v_c := contract.buyer_create_executed_contract(
    p_preparation_id => current_setting('test.prep')::uuid,
    p_title => 'Executed methanol contract'
  );
  perform set_config('test.contract', v_c::text, false);
end;
$$;
reset role;

select is(
  (select status::text from contract.executed_contracts
    where id = current_setting('test.contract')::uuid),
  'draft_execution',
  'buyer_create_executed_contract creates contract with status=draft_execution'
);

-- 2. Items derived from preparation items.
select is(
  (select count(*)::int from contract.executed_contract_items
    where contract_id = current_setting('test.contract')::uuid and deleted_at is null),
  1,
  'items derived from preparation items (count=1)'
);

-- 3. Clauses derived from preparation clauses.
select is(
  (select count(*)::int from contract.executed_contract_clauses
    where contract_id = current_setting('test.contract')::uuid and deleted_at is null),
  1,
  'clauses derived from preparation clauses (count=1)'
);

-- 4. Parties auto-created: buyer + supplier = 2.
select is(
  (select count(*)::int from contract.contract_parties
    where contract_id = current_setting('test.contract')::uuid and deleted_at is null),
  2,
  'parties auto-created: buyer + supplier (count=2)'
);

-- 5. initial_from_preparation snapshot auto-created.
select is(
  (select count(*)::int from contract.executed_contract_snapshots
    where contract_id = current_setting('test.contract')::uuid
      and snapshot_type = 'initial_from_preparation'),
  1,
  'initial_from_preparation snapshot is auto-created on contract create'
);

-- 6. Update.
select tests.authenticate_as(
  '10000000-0000-0000-0000-000000000001',
  '10000000-0000-0000-0000-00000000000a',
  '10000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select contract.buyer_update_executed_contract(
  p_contract_id => current_setting('test.contract')::uuid,
  p_incoterm => 'FOB'
);
reset role;

select is(
  (select incoterm from contract.executed_contracts
    where id = current_setting('test.contract')::uuid),
  'FOB',
  'buyer_update_executed_contract patches incoterm'
);

-- 7. Add witness party.
select tests.authenticate_as(
  '10000000-0000-0000-0000-000000000001',
  '10000000-0000-0000-0000-00000000000a',
  '10000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
do $$
declare v_p uuid;
begin
  v_p := contract.buyer_add_party(
    p_contract_id        => current_setting('test.contract')::uuid,
    p_party_type         => 'witness'::contract.party_type,
    p_display_name       => 'Notary Co.',
    p_signing_order      => 3,
    p_is_required_signer => false
  );
  perform set_config('test.party_witness', v_p::text, false);
end;
$$;
reset role;

select is(
  (select count(*)::int from contract.contract_parties
    where contract_id = current_setting('test.contract')::uuid
      and deleted_at is null and party_type = 'witness'),
  1,
  'buyer_add_party adds a witness party'
);

-- 8. Create a signature request for the supplier party.
select tests.authenticate_as(
  '10000000-0000-0000-0000-000000000001',
  '10000000-0000-0000-0000-00000000000a',
  '10000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
do $$
declare v_sup_party uuid; v_sr uuid;
begin
  select id into v_sup_party from contract.contract_parties
   where contract_id = current_setting('test.contract')::uuid
     and party_type = 'supplier' and deleted_at is null limit 1;
  v_sr := contract.buyer_create_signature_request(
    p_contract_id => current_setting('test.contract')::uuid,
    p_party_id    => v_sup_party
  );
  perform set_config('test.sr_supplier', v_sr::text, false);
end;
$$;
reset role;

select is(
  (select status::text from contract.contract_signature_requests
    where id = current_setting('test.sr_supplier')::uuid),
  'pending',
  'buyer_create_signature_request creates pending signature request'
);

-- 9. Mark pending_signatures.
select tests.authenticate_as(
  '10000000-0000-0000-0000-000000000001',
  '10000000-0000-0000-0000-00000000000a',
  '10000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select contract.buyer_mark_pending_signatures(current_setting('test.contract')::uuid);
reset role;

select is(
  (select status::text from contract.executed_contracts
    where id = current_setting('test.contract')::uuid),
  'pending_signatures',
  'buyer_mark_pending_signatures transitions draft_execution → pending_signatures'
);

-- 10. Pending-signature snapshot.
select tests.authenticate_as(
  '10000000-0000-0000-0000-000000000001',
  '10000000-0000-0000-0000-00000000000a',
  '10000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select contract.buyer_create_executed_snapshot(
  p_contract_id   => current_setting('test.contract')::uuid,
  p_snapshot_type => 'pending_signature_snapshot'::contract.executed_snapshot_type,
  p_title         => 'snapshot at pending_signatures'
);
reset role;

select is(
  (select count(*)::int from contract.executed_contract_snapshots
    where contract_id = current_setting('test.contract')::uuid
      and snapshot_type = 'pending_signature_snapshot'),
  1,
  'buyer_create_executed_snapshot persists a pending_signature_snapshot'
);

-- 11. pending_signatures contract is locked from buyer_update_executed_contract.
select tests.authenticate_as(
  '10000000-0000-0000-0000-000000000001',
  '10000000-0000-0000-0000-00000000000a',
  '10000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select throws_ok(
  format($$ select contract.buyer_update_executed_contract(%L::uuid, p_incoterm => 'CIF') $$,
         current_setting('test.contract')),
  'P0001', null,
  'pending_signatures contract is locked from update (P0001)'
);
reset role;

select * from finish();
rollback;
