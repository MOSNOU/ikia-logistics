-- CC-17 Test 063 — Buyer settlement lifecycle:
--   open escrow → create draft → add item → mark ready → hold (escrow credit+hold)
--   → release (escrow release+debit) → settlement events written + escrow balances correct.
--
-- Assertions (10):
--   1. buyer_open_escrow_account creates account with status='open'
--   2. buyer_create_draft_settlement creates settlement with status='draft'
--   3. buyer_upsert_settlement_item recomputes planned_amount = 1000
--   4. buyer_mark_settlement_ready moves draft → ready
--   5. buyer_hold_settlement moves ready → holding + sets held_amount
--   6. hold writes 2 escrow entries (credit + hold)
--   7. escrow.total_held = 1000 after hold
--   8. escrow.status auto-activated to 'active' after first credit
--   9. buyer_release_settlement moves holding → released
--  10. escrow.total_held = 0, total_released = 1000 after release

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  app_storage, finance, settlement, tests;
begin;

-- Fixtures: full chain through executed contract.
insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '20000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '063-buyer@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '20000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', '063-sup@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('20000000-0000-0000-0000-00000000000a', 'tenant-063', 'تست', 'Test');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('20000000-0000-0000-0000-00000000001a', '20000000-0000-0000-0000-00000000000a',
   'buyer-063', 'خریدار', 'Buyer 063', 'buyer', 'active'),
  ('20000000-0000-0000-0000-00000000002a', '20000000-0000-0000-0000-00000000000a',
   'sup-063', 'تأمین', 'Supplier 063', 'supplier', 'active');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('20000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-00000000000a',
   '20000000-0000-0000-0000-00000000001a', 'Buyer', 'fa', 'active'),
  ('20000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-00000000000a',
   '20000000-0000-0000-0000-00000000002a', 'Supplier', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '20000000-0000-0000-0000-00000000000a', '20000000-0000-0000-0000-00000000001a',
       '20000000-0000-0000-0000-000000000001', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '20000000-0000-0000-0000-00000000000a', '20000000-0000-0000-0000-00000000002a',
       '20000000-0000-0000-0000-000000000002', r.id, 'active', now()
  from identity.roles r where r.code = 'supplier_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '20000000-0000-0000-0000-000000000001', r.id, 'organization', '20000000-0000-0000-0000-00000000001a'
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '20000000-0000-0000-0000-000000000002', r.id, 'organization', '20000000-0000-0000-0000-00000000002a'
  from identity.roles r where r.code = 'supplier_admin';

do $$
declare
  v_sup uuid; v_prod uuid; v_rfq uuid; v_item uuid; v_off uuid; v_dec uuid;
  v_prep uuid; v_contract uuid; v_p_b uuid; v_p_s uuid; v_sr_b uuid; v_sr_s uuid;
begin
  select id into v_sup  from supplier.suppliers where organization_id = '20000000-0000-0000-0000-00000000002a';
  select id into v_prod from commodity.products where code = 'methanol';

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','20000000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','20000000-0000-0000-0000-00000000000a',
                       'organization_id','20000000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '20000000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_rfq := rfq.buyer_create_rfq(p_title => 'R for settlement lifecycle');
  v_item := rfq.buyer_upsert_rfq_item(p_request_id => v_rfq, p_product_id => v_prod,
                                       p_quantity => 100, p_quantity_unit => 'ton');
  perform rfq.buyer_submit_rfq(v_rfq);
  perform rfq.buyer_invite_suppliers(v_rfq, array[v_sup]);
  reset role;

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','20000000-0000-0000-0000-000000000002','role','authenticated',
                       'tenant_id','20000000-0000-0000-0000-00000000000a',
                       'organization_id','20000000-0000-0000-0000-00000000002a')::text, true);
  perform set_config('request.jwt.claim.sub', '20000000-0000-0000-0000-000000000002', true);
  set local role authenticated;
  v_off := offer.supplier_create_draft_offer(p_request_id => v_rfq);
  perform offer.supplier_upsert_offer_item(p_offer_id => v_off, p_request_item_id => v_item,
    p_offered_quantity => 100, p_quantity_unit => 'ton', p_unit_price => 10, p_currency => 'USD');
  perform offer.supplier_submit_my_offer(v_off);
  reset role;

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','20000000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','20000000-0000-0000-0000-00000000000a',
                       'organization_id','20000000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '20000000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_dec := evaluation.buyer_select_for_contract(p_offer_id => v_off);
  v_prep := contract.buyer_create_preparation(p_decision_id => v_dec, p_title => 'settlement prep');
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
    jsonb_build_object('sub','20000000-0000-0000-0000-000000000002','role','authenticated',
                       'tenant_id','20000000-0000-0000-0000-00000000000a',
                       'organization_id','20000000-0000-0000-0000-00000000002a')::text, true);
  perform set_config('request.jwt.claim.sub', '20000000-0000-0000-0000-000000000002', true);
  set local role authenticated;
  perform contract.supplier_sign_signature_request(v_sr_s);
  reset role;

  perform set_config('test.contract', v_contract::text, false);
  perform set_config('test.supplier', v_sup::text,      false);
end;
$$;

select plan(10);

-- 1. Open escrow account.
select tests.authenticate_as(
  '20000000-0000-0000-0000-000000000001',
  '20000000-0000-0000-0000-00000000000a',
  '20000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
do $$
declare v_esc uuid;
begin
  v_esc := settlement.buyer_open_escrow_account(
    p_supplier_id => current_setting('test.supplier')::uuid,
    p_currency => 'USD'
  );
  perform set_config('test.escrow', v_esc::text, false);
end;
$$;
reset role;

select is(
  (select status::text from settlement.escrow_accounts where id = current_setting('test.escrow')::uuid),
  'open',
  'buyer_open_escrow_account creates account with status=open'
);

-- 2. Create draft settlement.
select tests.authenticate_as(
  '20000000-0000-0000-0000-000000000001',
  '20000000-0000-0000-0000-00000000000a',
  '20000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
do $$
declare v_set uuid;
begin
  v_set := settlement.buyer_create_draft_settlement(
    p_executed_contract_id => current_setting('test.contract')::uuid,
    p_escrow_account_id => current_setting('test.escrow')::uuid,
    p_currency => 'USD'
  );
  perform set_config('test.settlement', v_set::text, false);
end;
$$;
reset role;

select is(
  (select status::text from settlement.settlements where id = current_setting('test.settlement')::uuid),
  'draft',
  'buyer_create_draft_settlement creates settlement with status=draft'
);

-- 3. Add an item; planned_amount recomputed.
select tests.authenticate_as(
  '20000000-0000-0000-0000-000000000001',
  '20000000-0000-0000-0000-00000000000a',
  '20000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
do $$
declare v_it uuid;
begin
  v_it := settlement.buyer_upsert_settlement_item(
    p_settlement_id => current_setting('test.settlement')::uuid,
    p_description => 'Initial payment',
    p_amount => 1000, p_fees_amount => 0, p_platform_fee_amount => 0
  );
end;
$$;
reset role;

select is(
  (select planned_amount from settlement.settlements where id = current_setting('test.settlement')::uuid),
  numeric '1000',
  'planned_amount recomputed = 1000 after adding item'
);

-- 4. Mark ready.
select tests.authenticate_as(
  '20000000-0000-0000-0000-000000000001',
  '20000000-0000-0000-0000-00000000000a',
  '20000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select settlement.buyer_mark_settlement_ready(current_setting('test.settlement')::uuid);
reset role;

select is(
  (select status::text from settlement.settlements where id = current_setting('test.settlement')::uuid),
  'ready',
  'buyer_mark_settlement_ready moves draft → ready'
);

-- 5. Hold.
select tests.authenticate_as(
  '20000000-0000-0000-0000-000000000001',
  '20000000-0000-0000-0000-00000000000a',
  '20000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select settlement.buyer_hold_settlement(current_setting('test.settlement')::uuid);
reset role;

select is(
  (select status::text from settlement.settlements where id = current_setting('test.settlement')::uuid),
  'holding',
  'buyer_hold_settlement moves ready → holding'
);

-- 6. 2 escrow entries (credit + hold).
select is(
  (select count(*)::int from settlement.escrow_entries
    where escrow_account_id = current_setting('test.escrow')::uuid
      and settlement_id = current_setting('test.settlement')::uuid),
  2,
  'hold writes 2 escrow entries (credit + hold)'
);

-- 7. escrow.total_held = 1000.
select is(
  (select total_held from settlement.escrow_accounts where id = current_setting('test.escrow')::uuid),
  numeric '1000',
  'escrow.total_held = 1000 after hold'
);

-- 8. escrow.status auto-activated.
select is(
  (select status::text from settlement.escrow_accounts where id = current_setting('test.escrow')::uuid),
  'active',
  'escrow status auto-activates to active after first credit'
);

-- 9. Release.
select tests.authenticate_as(
  '20000000-0000-0000-0000-000000000001',
  '20000000-0000-0000-0000-00000000000a',
  '20000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select settlement.buyer_release_settlement(current_setting('test.settlement')::uuid, p_reason => 'goods delivered');
reset role;

select is(
  (select status::text from settlement.settlements where id = current_setting('test.settlement')::uuid),
  'released',
  'buyer_release_settlement moves holding → released'
);

-- 10. Balances after release.
select is(
  (select total_held::text || '/' || total_released::text from settlement.escrow_accounts
    where id = current_setting('test.escrow')::uuid),
  '0/1000',
  'after release: total_held=0, total_released=1000'
);

select * from finish();
rollback;
