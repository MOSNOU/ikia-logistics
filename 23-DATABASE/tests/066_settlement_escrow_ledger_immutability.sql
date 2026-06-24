-- CC-17 Test 066 — Escrow ledger + event immutability:
--   * cancel during 'holding' writes a 'reverse' entry and balances drop to 0
--   * direct UPDATE/DELETE on escrow_entries blocked (no grant)
--   * direct UPDATE/DELETE on escrow_status_events blocked
--   * direct UPDATE/DELETE on settlement_events blocked
--   * admin_close_escrow_account rejects when balances are non-zero (P0001)

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  app_storage, finance, settlement, tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '23000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '066-buyer@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '23000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', '066-sup@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('23000000-0000-0000-0000-00000000000a', 'tenant-066', 'تست', 'Test');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('23000000-0000-0000-0000-00000000001a', '23000000-0000-0000-0000-00000000000a',
   'buyer-066', 'خریدار', 'Buyer 066', 'buyer', 'active'),
  ('23000000-0000-0000-0000-00000000002a', '23000000-0000-0000-0000-00000000000a',
   'sup-066', 'تأمین', 'Supplier 066', 'supplier', 'active');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('23000000-0000-0000-0000-000000000001', '23000000-0000-0000-0000-00000000000a',
   '23000000-0000-0000-0000-00000000001a', 'Buyer', 'fa', 'active'),
  ('23000000-0000-0000-0000-000000000002', '23000000-0000-0000-0000-00000000000a',
   '23000000-0000-0000-0000-00000000002a', 'Supplier', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '23000000-0000-0000-0000-00000000000a', '23000000-0000-0000-0000-00000000001a',
       '23000000-0000-0000-0000-000000000001', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '23000000-0000-0000-0000-00000000000a', '23000000-0000-0000-0000-00000000002a',
       '23000000-0000-0000-0000-000000000002', r.id, 'active', now()
  from identity.roles r where r.code = 'supplier_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '23000000-0000-0000-0000-000000000001', r.id, 'organization', '23000000-0000-0000-0000-00000000001a'
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '23000000-0000-0000-0000-000000000002', r.id, 'organization', '23000000-0000-0000-0000-00000000002a'
  from identity.roles r where r.code = 'supplier_admin';

-- Build chain + create + hold + cancel a settlement to exercise reverse entry.
do $$
declare
  v_sup uuid; v_prod uuid; v_rfq uuid; v_item uuid; v_off uuid; v_dec uuid;
  v_prep uuid; v_contract uuid; v_p_b uuid; v_p_s uuid; v_sr_b uuid; v_sr_s uuid;
  v_esc uuid; v_set uuid; v_set_holding uuid;
begin
  select id into v_sup  from supplier.suppliers where organization_id = '23000000-0000-0000-0000-00000000002a';
  select id into v_prod from commodity.products where code = 'methanol';

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','23000000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','23000000-0000-0000-0000-00000000000a',
                       'organization_id','23000000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '23000000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_rfq := rfq.buyer_create_rfq(p_title => 'R for ledger immutability');
  v_item := rfq.buyer_upsert_rfq_item(p_request_id => v_rfq, p_product_id => v_prod,
                                       p_quantity => 100, p_quantity_unit => 'ton');
  perform rfq.buyer_submit_rfq(v_rfq);
  perform rfq.buyer_invite_suppliers(v_rfq, array[v_sup]);
  reset role;

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','23000000-0000-0000-0000-000000000002','role','authenticated',
                       'tenant_id','23000000-0000-0000-0000-00000000000a',
                       'organization_id','23000000-0000-0000-0000-00000000002a')::text, true);
  perform set_config('request.jwt.claim.sub', '23000000-0000-0000-0000-000000000002', true);
  set local role authenticated;
  v_off := offer.supplier_create_draft_offer(p_request_id => v_rfq);
  perform offer.supplier_upsert_offer_item(p_offer_id => v_off, p_request_item_id => v_item,
    p_offered_quantity => 100, p_quantity_unit => 'ton', p_unit_price => 10, p_currency => 'USD');
  perform offer.supplier_submit_my_offer(v_off);
  reset role;

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','23000000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','23000000-0000-0000-0000-00000000000a',
                       'organization_id','23000000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '23000000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_dec := evaluation.buyer_select_for_contract(p_offer_id => v_off);
  v_prep := contract.buyer_create_preparation(p_decision_id => v_dec, p_title => 'ledger prep');
  perform contract.buyer_mark_ready_for_contract(v_prep);
  v_contract := contract.buyer_create_executed_contract(p_preparation_id => v_prep);
  select id into v_p_b from contract.contract_parties where contract_id = v_contract and party_type='buyer' and deleted_at is null limit 1;
  select id into v_p_s from contract.contract_parties where contract_id = v_contract and party_type='supplier' and deleted_at is null limit 1;
  v_sr_b := contract.buyer_create_signature_request(p_contract_id => v_contract, p_party_id => v_p_b);
  v_sr_s := contract.buyer_create_signature_request(p_contract_id => v_contract, p_party_id => v_p_s);
  perform contract.buyer_mark_pending_signatures(v_contract);
  perform contract.buyer_sign_signature_request(v_sr_b);
  reset role;

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','23000000-0000-0000-0000-000000000002','role','authenticated',
                       'tenant_id','23000000-0000-0000-0000-00000000000a',
                       'organization_id','23000000-0000-0000-0000-00000000002a')::text, true);
  perform set_config('request.jwt.claim.sub', '23000000-0000-0000-0000-000000000002', true);
  set local role authenticated;
  perform contract.supplier_sign_signature_request(v_sr_s);
  reset role;

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','23000000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','23000000-0000-0000-0000-00000000000a',
                       'organization_id','23000000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '23000000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_esc := settlement.buyer_open_escrow_account(p_supplier_id => v_sup, p_currency => 'USD');
  v_set_holding := settlement.buyer_create_draft_settlement(
    p_executed_contract_id => v_contract, p_escrow_account_id => v_esc, p_currency => 'USD'
  );
  perform settlement.buyer_upsert_settlement_item(
    p_settlement_id => v_set_holding, p_description => 'Hold payment', p_amount => 700
  );
  perform settlement.buyer_mark_settlement_ready(v_set_holding);
  perform settlement.buyer_hold_settlement(v_set_holding);
  perform settlement.buyer_cancel_settlement(v_set_holding, p_reason => 'order cancelled');
  reset role;

  perform set_config('test.escrow', v_esc::text, false);
  perform set_config('test.settlement', v_set_holding::text, false);
end;
$$;

select plan(7);

-- 1. Cancel-from-holding wrote a 'reverse' ledger entry.
select is(
  (select count(*)::int from settlement.escrow_entries
    where settlement_id = current_setting('test.settlement')::uuid
      and entry_type = 'reverse'),
  1,
  'cancel-from-holding writes one reverse entry'
);

-- 2. Escrow balances dropped back to 0.
select is(
  (select total_held::text || '/' || available_balance::text from settlement.escrow_accounts
    where id = current_setting('test.escrow')::uuid),
  '0/0',
  'cancel-from-holding restores escrow balances to total_held=0, available=0'
);

-- 3. Direct UPDATE on escrow_entries blocked.
select tests.authenticate_as(
  '23000000-0000-0000-0000-000000000001',
  '23000000-0000-0000-0000-00000000000a',
  '23000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select throws_ok(
  format($$ update settlement.escrow_entries set notes = 'tamper'
            where escrow_account_id = %L::uuid $$, current_setting('test.escrow')),
  '42501', null,
  'direct UPDATE on escrow_entries is blocked (no grant)'
);

-- 4. Direct DELETE on escrow_entries blocked.
select throws_ok(
  format($$ delete from settlement.escrow_entries
            where escrow_account_id = %L::uuid $$, current_setting('test.escrow')),
  '42501', null,
  'direct DELETE on escrow_entries is blocked (no grant)'
);

-- 5. Direct UPDATE on escrow_status_events blocked.
select throws_ok(
  format($$ update settlement.escrow_status_events set reason = 'tamper'
            where escrow_account_id = %L::uuid $$, current_setting('test.escrow')),
  '42501', null,
  'direct UPDATE on escrow_status_events is blocked (no grant)'
);

-- 6. Direct DELETE on settlement_events blocked.
select throws_ok(
  format($$ delete from settlement.settlement_events
            where settlement_id = %L::uuid $$, current_setting('test.settlement')),
  '42501', null,
  'direct DELETE on settlement_events is blocked (no grant)'
);
reset role;

-- 7. admin_close_escrow_account rejects non-zero balances:
--    create a fresh settlement that stays held, then try to close.
select tests.authenticate_as(
  '23000000-0000-0000-0000-000000000001',
  '23000000-0000-0000-0000-00000000000a',
  '23000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
do $$
declare v_set_h uuid;
begin
  v_set_h := settlement.buyer_create_draft_settlement(
    p_executed_contract_id => (select executed_contract_id from settlement.settlements
                                where id = current_setting('test.settlement')::uuid),
    p_escrow_account_id => current_setting('test.escrow')::uuid,
    p_currency => 'USD'
  );
  perform settlement.buyer_upsert_settlement_item(
    p_settlement_id => v_set_h, p_description => 'Hold for close test', p_amount => 250
  );
  perform settlement.buyer_mark_settlement_ready(v_set_h);
  perform settlement.buyer_hold_settlement(v_set_h);
end;
$$;
reset role;

-- Add a platform_admin user, then authenticate as that user.
insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '23000000-0000-0000-0000-000000000099', 'authenticated', 'authenticated', '066-admin@example.com');
insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('23000000-0000-0000-0000-000000000099', '23000000-0000-0000-0000-00000000000a',
   '23000000-0000-0000-0000-00000000001a', 'Admin', 'fa', 'active');
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '23000000-0000-0000-0000-000000000099', r.id, 'platform', null
  from identity.roles r where r.code = 'platform_admin';

select tests.authenticate_as(
  '23000000-0000-0000-0000-000000000099',
  '23000000-0000-0000-0000-00000000000a',
  '23000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select throws_ok(
  format($$ select settlement.admin_close_escrow_account(%L::uuid) $$, current_setting('test.escrow')),
  'P0001', null,
  'admin_close_escrow_account rejects when balances are non-zero (P0001)'
);
reset role;

select * from finish();
rollback;
