-- CC-17 Test 064 — Scope, transitions, and constraints:
--   * buyer B cannot create settlement from buyer A's executed contract (42501)
--   * draft cannot release (P0001)
--   * settlement requires at least one anchor (22023)
--   * duplicate active escrow for (org, supplier, currency) rejected (23505)
--   * escrow currency mismatch on hold (P0001)
--   * mark_ready with planned=0 rejected (P0001)

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  app_storage, finance, settlement, tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '21000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '064-buyerA@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '21000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', '064-buyerB@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '21000000-0000-0000-0000-000000000003', 'authenticated', 'authenticated', '064-sup@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('21000000-0000-0000-0000-00000000000a', 'tenant-064a', 'الف', 'A'),
  ('21000000-0000-0000-0000-00000000000b', 'tenant-064b', 'ب', 'B');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('21000000-0000-0000-0000-00000000001a', '21000000-0000-0000-0000-00000000000a',
   'buyer-064a', 'خریدار الف', 'Buyer A', 'buyer', 'active'),
  ('21000000-0000-0000-0000-00000000001b', '21000000-0000-0000-0000-00000000000b',
   'buyer-064b', 'خریدار ب', 'Buyer B', 'buyer', 'active'),
  ('21000000-0000-0000-0000-00000000002a', '21000000-0000-0000-0000-00000000000a',
   'sup-064', 'تأمین', 'Supplier', 'supplier', 'active');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('21000000-0000-0000-0000-000000000001', '21000000-0000-0000-0000-00000000000a',
   '21000000-0000-0000-0000-00000000001a', 'BuyerA', 'fa', 'active'),
  ('21000000-0000-0000-0000-000000000002', '21000000-0000-0000-0000-00000000000b',
   '21000000-0000-0000-0000-00000000001b', 'BuyerB', 'fa', 'active'),
  ('21000000-0000-0000-0000-000000000003', '21000000-0000-0000-0000-00000000000a',
   '21000000-0000-0000-0000-00000000002a', 'Supplier', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '21000000-0000-0000-0000-00000000000a', '21000000-0000-0000-0000-00000000001a',
       '21000000-0000-0000-0000-000000000001', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '21000000-0000-0000-0000-00000000000b', '21000000-0000-0000-0000-00000000001b',
       '21000000-0000-0000-0000-000000000002', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '21000000-0000-0000-0000-00000000000a', '21000000-0000-0000-0000-00000000002a',
       '21000000-0000-0000-0000-000000000003', r.id, 'active', now()
  from identity.roles r where r.code = 'supplier_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '21000000-0000-0000-0000-000000000001', r.id, 'organization', '21000000-0000-0000-0000-00000000001a'
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '21000000-0000-0000-0000-000000000002', r.id, 'organization', '21000000-0000-0000-0000-00000000001b'
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '21000000-0000-0000-0000-000000000003', r.id, 'organization', '21000000-0000-0000-0000-00000000002a'
  from identity.roles r where r.code = 'supplier_admin';

-- Build A's contract + draft settlement + USD escrow.
do $$
declare
  v_sup uuid; v_prod uuid; v_rfq uuid; v_item uuid; v_off uuid; v_dec uuid;
  v_prep uuid; v_contract uuid; v_p_b uuid; v_p_s uuid; v_sr_b uuid; v_sr_s uuid;
  v_set uuid; v_esc uuid;
begin
  select id into v_sup  from supplier.suppliers where organization_id = '21000000-0000-0000-0000-00000000002a';
  select id into v_prod from commodity.products where code = 'methanol';

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','21000000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','21000000-0000-0000-0000-00000000000a',
                       'organization_id','21000000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '21000000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_rfq := rfq.buyer_create_rfq(p_title => 'R for scope');
  v_item := rfq.buyer_upsert_rfq_item(p_request_id => v_rfq, p_product_id => v_prod,
                                       p_quantity => 100, p_quantity_unit => 'ton');
  perform rfq.buyer_submit_rfq(v_rfq);
  perform rfq.buyer_invite_suppliers(v_rfq, array[v_sup]);
  reset role;

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','21000000-0000-0000-0000-000000000003','role','authenticated',
                       'tenant_id','21000000-0000-0000-0000-00000000000a',
                       'organization_id','21000000-0000-0000-0000-00000000002a')::text, true);
  perform set_config('request.jwt.claim.sub', '21000000-0000-0000-0000-000000000003', true);
  set local role authenticated;
  v_off := offer.supplier_create_draft_offer(p_request_id => v_rfq);
  perform offer.supplier_upsert_offer_item(p_offer_id => v_off, p_request_item_id => v_item,
    p_offered_quantity => 100, p_quantity_unit => 'ton', p_unit_price => 10, p_currency => 'USD');
  perform offer.supplier_submit_my_offer(v_off);
  reset role;

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','21000000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','21000000-0000-0000-0000-00000000000a',
                       'organization_id','21000000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '21000000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_dec := evaluation.buyer_select_for_contract(p_offer_id => v_off);
  v_prep := contract.buyer_create_preparation(p_decision_id => v_dec, p_title => 'scope prep');
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
    jsonb_build_object('sub','21000000-0000-0000-0000-000000000003','role','authenticated',
                       'tenant_id','21000000-0000-0000-0000-00000000000a',
                       'organization_id','21000000-0000-0000-0000-00000000002a')::text, true);
  perform set_config('request.jwt.claim.sub', '21000000-0000-0000-0000-000000000003', true);
  set local role authenticated;
  perform contract.supplier_sign_signature_request(v_sr_s);
  reset role;

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','21000000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','21000000-0000-0000-0000-00000000000a',
                       'organization_id','21000000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '21000000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_esc := settlement.buyer_open_escrow_account(p_supplier_id => v_sup, p_currency => 'USD');
  v_set := settlement.buyer_create_draft_settlement(
    p_executed_contract_id => v_contract,
    p_escrow_account_id => v_esc,
    p_currency => 'USD'
  );
  reset role;

  perform set_config('test.contract', v_contract::text, false);
  perform set_config('test.supplier', v_sup::text,      false);
  perform set_config('test.escrow',   v_esc::text,      false);
  perform set_config('test.settlement', v_set::text,    false);
end;
$$;

select plan(6);

-- 1. Buyer B cannot create settlement from buyer A's contract.
select tests.authenticate_as(
  '21000000-0000-0000-0000-000000000002',
  '21000000-0000-0000-0000-00000000000b',
  '21000000-0000-0000-0000-00000000001b'
);
set local role authenticated;
select throws_ok(
  format($$ select settlement.buyer_create_draft_settlement(p_executed_contract_id => %L::uuid) $$,
         current_setting('test.contract')),
  '42501', null,
  'buyer B cannot create settlement from buyer A''s contract (42501)'
);
reset role;

-- 2. Draft cannot be released.
select tests.authenticate_as(
  '21000000-0000-0000-0000-000000000001',
  '21000000-0000-0000-0000-00000000000a',
  '21000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select throws_ok(
  format($$ select settlement.buyer_release_settlement(%L::uuid) $$, current_setting('test.settlement')),
  'P0001', null,
  'draft settlement cannot be released (P0001)'
);

-- 3. Settlement requires at least one anchor.
select throws_ok(
  $$ select settlement.buyer_create_draft_settlement() $$,
  '22023', null,
  'settlement requires at least one anchor (executed_contract_id or shipment_id) (22023)'
);

-- 4. Duplicate active escrow for (org, supplier, USD) rejected.
select throws_ok(
  format($$ select settlement.buyer_open_escrow_account(p_supplier_id => %L::uuid, p_currency => 'USD') $$,
         current_setting('test.supplier')),
  '23505', null,
  'duplicate active escrow for (org, supplier, currency) rejected (23505)'
);

-- 5. Escrow currency mismatch on hold:
--   open a EUR escrow, then attempt to use it on a USD settlement.
do $$
declare v_esc_eur uuid; v_set_eur uuid;
begin
  v_esc_eur := settlement.buyer_open_escrow_account(
    p_supplier_id => current_setting('test.supplier')::uuid, p_currency => 'EUR'
  );
  perform set_config('test.escrow_eur', v_esc_eur::text, false);
end;
$$;

-- Build a settlement with EUR currency + USD escrow attempt → currency mismatch raised.
select throws_ok(
  format($$ select settlement.buyer_create_draft_settlement(
              p_executed_contract_id => %L::uuid,
              p_escrow_account_id => %L::uuid,
              p_currency => 'USD'
            ) $$, current_setting('test.contract'), current_setting('test.escrow_eur')),
  'P0001', null,
  'currency mismatch with escrow account rejected (P0001)'
);

-- 6. mark_ready with planned=0 (no items) rejected.
do $$
declare v_set2 uuid;
begin
  v_set2 := settlement.buyer_create_draft_settlement(
    p_executed_contract_id => current_setting('test.contract')::uuid,
    p_currency => 'USD'
  );
  perform set_config('test.set2', v_set2::text, false);
end;
$$;
select throws_ok(
  format($$ select settlement.buyer_mark_settlement_ready(%L::uuid) $$, current_setting('test.set2')),
  'P0001', null,
  'mark_ready with planned_amount=0 rejected (P0001)'
);
reset role;

select * from finish();
rollback;
