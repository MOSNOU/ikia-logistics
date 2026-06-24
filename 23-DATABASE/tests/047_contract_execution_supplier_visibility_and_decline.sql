-- CC-13 Test 047 — Supplier visibility + decline behavior:
--   * supplier sees own executed contract via supplier_list_my_executed_contracts
--   * supplier_get_my_executed_contract returns the contract
--   * unrelated supplier sees 0 contracts
--   * unrelated supplier cannot get contract detail (42501)
--   * supplier sees own signature request via supplier_list_my_signature_requests
--   * supplier_decline_signature_request transitions to declined and writes signature event
--   * after decline, contract does NOT auto-execute (status stays in pending_signatures)

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '13000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '047-buyer@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '13000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', '047-supX@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '13000000-0000-0000-0000-000000000003', 'authenticated', 'authenticated', '047-supY@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('13000000-0000-0000-0000-00000000000a', 'tenant-047', 'تست', 'Test');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('13000000-0000-0000-0000-00000000001a', '13000000-0000-0000-0000-00000000000a',
   'buyer-047', 'خریدار', 'Buyer 047', 'buyer', 'active'),
  ('13000000-0000-0000-0000-00000000002a', '13000000-0000-0000-0000-00000000000a',
   'sup-047-X', 'ایکس', 'SupX', 'supplier', 'active'),
  ('13000000-0000-0000-0000-00000000002b', '13000000-0000-0000-0000-00000000000a',
   'sup-047-Y', 'وای',  'SupY', 'supplier', 'active');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('13000000-0000-0000-0000-000000000001', '13000000-0000-0000-0000-00000000000a',
   '13000000-0000-0000-0000-00000000001a', 'Buyer', 'fa', 'active'),
  ('13000000-0000-0000-0000-000000000002', '13000000-0000-0000-0000-00000000000a',
   '13000000-0000-0000-0000-00000000002a', 'SupX', 'fa', 'active'),
  ('13000000-0000-0000-0000-000000000003', '13000000-0000-0000-0000-00000000000a',
   '13000000-0000-0000-0000-00000000002b', 'SupY', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '13000000-0000-0000-0000-00000000000a', '13000000-0000-0000-0000-00000000001a',
       '13000000-0000-0000-0000-000000000001', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '13000000-0000-0000-0000-00000000000a', '13000000-0000-0000-0000-00000000002a',
       '13000000-0000-0000-0000-000000000002', r.id, 'active', now()
  from identity.roles r where r.code = 'supplier_admin';
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '13000000-0000-0000-0000-00000000000a', '13000000-0000-0000-0000-00000000002b',
       '13000000-0000-0000-0000-000000000003', r.id, 'active', now()
  from identity.roles r where r.code = 'supplier_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '13000000-0000-0000-0000-000000000001', r.id, 'organization', '13000000-0000-0000-0000-00000000001a'
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '13000000-0000-0000-0000-000000000002', r.id, 'organization', '13000000-0000-0000-0000-00000000002a'
  from identity.roles r where r.code = 'supplier_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '13000000-0000-0000-0000-000000000003', r.id, 'organization', '13000000-0000-0000-0000-00000000002b'
  from identity.roles r where r.code = 'supplier_admin';

do $$
declare
  v_supX uuid; v_prod uuid; v_rfq uuid; v_item uuid; v_off uuid; v_dec uuid; v_prep uuid;
  v_contract uuid; v_p_supplier uuid; v_p_buyer uuid; v_sr_supplier uuid; v_sr_buyer uuid;
begin
  select id into v_supX from supplier.suppliers where organization_id = '13000000-0000-0000-0000-00000000002a';
  select id into v_prod from commodity.products where code = 'methanol';

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','13000000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','13000000-0000-0000-0000-00000000000a',
                       'organization_id','13000000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '13000000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_rfq := rfq.buyer_create_rfq(p_title => 'R for supplier visibility/decline');
  v_item := rfq.buyer_upsert_rfq_item(p_request_id => v_rfq, p_product_id => v_prod,
                                       p_quantity => 500, p_quantity_unit => 'ton');
  perform rfq.buyer_submit_rfq(v_rfq);
  perform rfq.buyer_invite_suppliers(v_rfq, array[v_supX]);
  reset role;

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','13000000-0000-0000-0000-000000000002','role','authenticated',
                       'tenant_id','13000000-0000-0000-0000-00000000000a',
                       'organization_id','13000000-0000-0000-0000-00000000002a')::text, true);
  perform set_config('request.jwt.claim.sub', '13000000-0000-0000-0000-000000000002', true);
  set local role authenticated;
  v_off := offer.supplier_create_draft_offer(p_request_id => v_rfq);
  perform offer.supplier_upsert_offer_item(p_offer_id => v_off, p_request_item_id => v_item,
    p_offered_quantity => 500, p_quantity_unit => 'ton', p_unit_price => 380, p_currency => 'USD');
  perform offer.supplier_submit_my_offer(v_off);
  reset role;

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','13000000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','13000000-0000-0000-0000-00000000000a',
                       'organization_id','13000000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '13000000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_dec := evaluation.buyer_select_for_contract(p_offer_id => v_off);
  v_prep := contract.buyer_create_preparation(p_decision_id => v_dec, p_title => 'visibility prep');
  perform contract.buyer_mark_ready_for_contract(v_prep);
  v_contract := contract.buyer_create_executed_contract(p_preparation_id => v_prep);

  select id into v_p_supplier from contract.contract_parties
   where contract_id = v_contract and party_type = 'supplier' and deleted_at is null limit 1;
  select id into v_p_buyer from contract.contract_parties
   where contract_id = v_contract and party_type = 'buyer' and deleted_at is null limit 1;

  v_sr_supplier := contract.buyer_create_signature_request(p_contract_id => v_contract, p_party_id => v_p_supplier);
  v_sr_buyer    := contract.buyer_create_signature_request(p_contract_id => v_contract, p_party_id => v_p_buyer);

  perform contract.buyer_mark_pending_signatures(v_contract);
  reset role;

  perform set_config('test.contract',    v_contract::text,    false);
  perform set_config('test.sr_supplier', v_sr_supplier::text, false);
  perform set_config('test.sr_buyer',    v_sr_buyer::text,    false);
end;
$$;

select plan(7);

-- 1. Supplier X sees own contract.
select tests.authenticate_as(
  '13000000-0000-0000-0000-000000000002',
  '13000000-0000-0000-0000-00000000000a',
  '13000000-0000-0000-0000-00000000002a'
);
set local role authenticated;
select is(
  (select count(*)::int from contract.supplier_list_my_executed_contracts(null, 100, 0)),
  1,
  'supplier X sees own executed contract via supplier_list_my_executed_contracts'
);
reset role;

-- 2. Supplier X reads detail.
select tests.authenticate_as(
  '13000000-0000-0000-0000-000000000002',
  '13000000-0000-0000-0000-00000000000a',
  '13000000-0000-0000-0000-00000000002a'
);
set local role authenticated;
select isnt(
  (contract.supplier_get_my_executed_contract(current_setting('test.contract')::uuid))->>'id',
  null,
  'supplier_get_my_executed_contract returns contract detail for own supplier'
);
reset role;

-- 3. Supplier Y sees 0.
select tests.authenticate_as(
  '13000000-0000-0000-0000-000000000003',
  '13000000-0000-0000-0000-00000000000a',
  '13000000-0000-0000-0000-00000000002b'
);
set local role authenticated;
select is(
  (select count(*)::int from contract.supplier_list_my_executed_contracts(null, 100, 0)),
  0,
  'unrelated supplier Y sees 0 contracts'
);

-- 4. Supplier Y cannot get contract detail.
select throws_ok(
  format($$ select contract.supplier_get_my_executed_contract(%L::uuid) $$, current_setting('test.contract')),
  '42501', null,
  'unrelated supplier cannot get contract detail (42501)'
);
reset role;

-- 5. Supplier X sees own signature request via the list RPC.
select tests.authenticate_as(
  '13000000-0000-0000-0000-000000000002',
  '13000000-0000-0000-0000-00000000000a',
  '13000000-0000-0000-0000-00000000002a'
);
set local role authenticated;
select is(
  (select count(*)::int from contract.supplier_list_my_signature_requests(null, 100, 0)),
  1,
  'supplier X sees own signature request via supplier_list_my_signature_requests'
);

-- 6. Supplier declines own signature request.
select contract.supplier_decline_signature_request(
  p_signature_request_id => current_setting('test.sr_supplier')::uuid,
  p_reason => 'pricing changed'
);
reset role;

-- Verify decline wrote a signature event (declined) and contract did NOT execute.
select is(
  (select count(*)::int from contract.contract_signature_events
    where signature_request_id = current_setting('test.sr_supplier')::uuid
      and to_status = 'declined'),
  1,
  'decline writes a signature event (to_status=declined)'
);

-- 7. Contract remained at pending_signatures (no auto-execution on decline).
select is(
  (select status::text from contract.executed_contracts
    where id = current_setting('test.contract')::uuid),
  'pending_signatures',
  'after decline, contract did NOT auto-execute (status remains pending_signatures)'
);

select * from finish();
rollback;
