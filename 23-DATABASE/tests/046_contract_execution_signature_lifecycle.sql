-- CC-13 Test 046 — Signature lifecycle → contract promoted to executed:
--   * buyer creates contract, marks pending_signatures with two required signers
--   * supplier views + signs own request (contract moves to partially_signed)
--   * supplier cannot sign buyer party's request (42501)
--   * buyer signs buyer party's request (contract moves to executed)
--   * executed contract is locked from buyer_update_executed_contract (P0001)
--   * decline writes signature event but does not execute (separate scenario)
--   * direct UPDATE/DELETE on signature_events row blocked (immutability)

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '12000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '046-buyer@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '12000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', '046-sup@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('12000000-0000-0000-0000-00000000000a', 'tenant-046', 'تست', 'Test');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('12000000-0000-0000-0000-00000000001a', '12000000-0000-0000-0000-00000000000a',
   'buyer-046', 'خریدار', 'Buyer 046', 'buyer', 'active'),
  ('12000000-0000-0000-0000-00000000002a', '12000000-0000-0000-0000-00000000000a',
   'sup-046', 'تأمین', 'Supplier 046', 'supplier', 'active');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('12000000-0000-0000-0000-000000000001', '12000000-0000-0000-0000-00000000000a',
   '12000000-0000-0000-0000-00000000001a', 'Buyer', 'fa', 'active'),
  ('12000000-0000-0000-0000-000000000002', '12000000-0000-0000-0000-00000000000a',
   '12000000-0000-0000-0000-00000000002a', 'Supplier', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '12000000-0000-0000-0000-00000000000a', '12000000-0000-0000-0000-00000000001a',
       '12000000-0000-0000-0000-000000000001', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '12000000-0000-0000-0000-00000000000a', '12000000-0000-0000-0000-00000000002a',
       '12000000-0000-0000-0000-000000000002', r.id, 'active', now()
  from identity.roles r where r.code = 'supplier_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '12000000-0000-0000-0000-000000000001', r.id, 'organization', '12000000-0000-0000-0000-00000000001a'
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '12000000-0000-0000-0000-000000000002', r.id, 'organization', '12000000-0000-0000-0000-00000000002a'
  from identity.roles r where r.code = 'supplier_admin';

-- Build chain → ready_for_contract → executed contract draft + 2 signature requests.
do $$
declare
  v_sup uuid; v_prod uuid; v_rfq uuid; v_item uuid; v_off uuid; v_dec uuid; v_prep uuid;
  v_contract uuid; v_party_buyer uuid; v_party_supplier uuid;
  v_sr_buyer uuid; v_sr_supplier uuid;
begin
  select id into v_sup  from supplier.suppliers where organization_id = '12000000-0000-0000-0000-00000000002a';
  select id into v_prod from commodity.products where code = 'methanol';

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','12000000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','12000000-0000-0000-0000-00000000000a',
                       'organization_id','12000000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '12000000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_rfq := rfq.buyer_create_rfq(p_title => 'R for signature lifecycle');
  v_item := rfq.buyer_upsert_rfq_item(p_request_id => v_rfq, p_product_id => v_prod,
                                       p_quantity => 1000, p_quantity_unit => 'ton');
  perform rfq.buyer_submit_rfq(v_rfq);
  perform rfq.buyer_invite_suppliers(v_rfq, array[v_sup]);
  reset role;

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','12000000-0000-0000-0000-000000000002','role','authenticated',
                       'tenant_id','12000000-0000-0000-0000-00000000000a',
                       'organization_id','12000000-0000-0000-0000-00000000002a')::text, true);
  perform set_config('request.jwt.claim.sub', '12000000-0000-0000-0000-000000000002', true);
  set local role authenticated;
  v_off := offer.supplier_create_draft_offer(p_request_id => v_rfq);
  perform offer.supplier_upsert_offer_item(p_offer_id => v_off, p_request_item_id => v_item,
    p_offered_quantity => 1000, p_quantity_unit => 'ton', p_unit_price => 380, p_currency => 'USD');
  perform offer.supplier_submit_my_offer(v_off);
  reset role;

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','12000000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','12000000-0000-0000-0000-00000000000a',
                       'organization_id','12000000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '12000000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_dec := evaluation.buyer_select_for_contract(p_offer_id => v_off);
  v_prep := contract.buyer_create_preparation(p_decision_id => v_dec, p_title => 'sig prep');
  perform contract.buyer_mark_ready_for_contract(v_prep);
  v_contract := contract.buyer_create_executed_contract(
    p_preparation_id => v_prep, p_title => 'sig contract'
  );

  select id into v_party_buyer    from contract.contract_parties
   where contract_id = v_contract and party_type = 'buyer' and deleted_at is null limit 1;
  select id into v_party_supplier from contract.contract_parties
   where contract_id = v_contract and party_type = 'supplier' and deleted_at is null limit 1;

  v_sr_buyer    := contract.buyer_create_signature_request(p_contract_id => v_contract, p_party_id => v_party_buyer);
  v_sr_supplier := contract.buyer_create_signature_request(p_contract_id => v_contract, p_party_id => v_party_supplier);

  perform contract.buyer_mark_pending_signatures(v_contract);
  reset role;

  perform set_config('test.contract',     v_contract::text,     false);
  perform set_config('test.sr_buyer',     v_sr_buyer::text,     false);
  perform set_config('test.sr_supplier',  v_sr_supplier::text,  false);
end;
$$;

select plan(8);

-- 1. Supplier views own signature request.
select tests.authenticate_as(
  '12000000-0000-0000-0000-000000000002',
  '12000000-0000-0000-0000-00000000000a',
  '12000000-0000-0000-0000-00000000002a'
);
set local role authenticated;
select contract.supplier_view_signature_request(current_setting('test.sr_supplier')::uuid);
reset role;

select is(
  (select status::text from contract.contract_signature_requests
    where id = current_setting('test.sr_supplier')::uuid),
  'viewed',
  'supplier_view_signature_request transitions pending → viewed'
);

-- 2. Supplier cannot sign buyer party's signature request (42501).
select tests.authenticate_as(
  '12000000-0000-0000-0000-000000000002',
  '12000000-0000-0000-0000-00000000000a',
  '12000000-0000-0000-0000-00000000002a'
);
set local role authenticated;
select throws_ok(
  format($$ select contract.supplier_sign_signature_request(%L::uuid) $$, current_setting('test.sr_buyer')),
  '42501', null,
  'supplier cannot sign buyer party signature request (42501)'
);

-- 3. Supplier signs own signature request → contract becomes partially_signed.
select contract.supplier_sign_signature_request(current_setting('test.sr_supplier')::uuid);
reset role;

select is(
  (select status::text from contract.executed_contracts
    where id = current_setting('test.contract')::uuid),
  'partially_signed',
  'supplier signing 1 of 2 required moves contract to partially_signed'
);

-- 4. Buyer signs buyer party's request → all required signed → contract moves to executed.
select tests.authenticate_as(
  '12000000-0000-0000-0000-000000000001',
  '12000000-0000-0000-0000-00000000000a',
  '12000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select contract.buyer_sign_signature_request(current_setting('test.sr_buyer')::uuid);
reset role;

select is(
  (select status::text from contract.executed_contracts
    where id = current_setting('test.contract')::uuid),
  'executed',
  'all required signed promotes contract to executed'
);

-- 5. executed_at is populated when contract reaches executed.
select isnt(
  (select executed_at from contract.executed_contracts
    where id = current_setting('test.contract')::uuid),
  null,
  'executed_at is populated when contract reaches executed'
);

-- 6. Executed contract locks normal buyer_update_executed_contract.
select tests.authenticate_as(
  '12000000-0000-0000-0000-000000000001',
  '12000000-0000-0000-0000-00000000000a',
  '12000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select throws_ok(
  format($$ select contract.buyer_update_executed_contract(%L::uuid, p_incoterm => 'CIF') $$,
         current_setting('test.contract')),
  'P0001', null,
  'executed contract is locked from buyer_update_executed_contract (P0001)'
);
reset role;

-- 7. Direct UPDATE on signature_events row blocked (immutability).
select tests.authenticate_as(
  '12000000-0000-0000-0000-000000000001',
  '12000000-0000-0000-0000-00000000000a',
  '12000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select throws_ok(
  format($$ update contract.contract_signature_events set reason = 'tamper'
            where contract_id = %L::uuid $$, current_setting('test.contract')),
  '42501', null,
  'direct UPDATE on signature_events row is blocked (no grant)'
);

-- 8. Direct DELETE on executed_contract_events row blocked.
select throws_ok(
  format($$ delete from contract.executed_contract_events
            where contract_id = %L::uuid $$, current_setting('test.contract')),
  '42501', null,
  'direct DELETE on executed_contract_events row is blocked (no grant)'
);
reset role;

select * from finish();
rollback;
