-- CC-16 Test 059 — Cross-buyer isolation + invalid status transitions:
--   * buyer B cannot create invoice from buyer A's executed contract (42501)
--   * buyer B cannot get buyer A's invoice (42501)
--   * cannot send from draft (must issue first) (P0001)
--   * cannot record payment on draft invoice (P0001)
--   * cannot record payment with paid_amount <= 0 (22023)
--   * buyer_create_draft_invoice requires contract OR shipment (22023)
--   * cancelling a paid invoice rejected (P0001)

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  app_storage, finance, tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '1c000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '059-buyerA@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '1c000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', '059-buyerB@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '1c000000-0000-0000-0000-000000000003', 'authenticated', 'authenticated', '059-sup@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('1c000000-0000-0000-0000-00000000000a', 'tenant-059a', 'الف', 'A'),
  ('1c000000-0000-0000-0000-00000000000b', 'tenant-059b', 'ب', 'B');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('1c000000-0000-0000-0000-00000000001a', '1c000000-0000-0000-0000-00000000000a',
   'buyer-059a', 'خریدار الف', 'Buyer A', 'buyer', 'active'),
  ('1c000000-0000-0000-0000-00000000001b', '1c000000-0000-0000-0000-00000000000b',
   'buyer-059b', 'خریدار ب', 'Buyer B', 'buyer', 'active'),
  ('1c000000-0000-0000-0000-00000000002a', '1c000000-0000-0000-0000-00000000000a',
   'sup-059', 'تأمین', 'Supplier', 'supplier', 'active');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('1c000000-0000-0000-0000-000000000001', '1c000000-0000-0000-0000-00000000000a',
   '1c000000-0000-0000-0000-00000000001a', 'BuyerA', 'fa', 'active'),
  ('1c000000-0000-0000-0000-000000000002', '1c000000-0000-0000-0000-00000000000b',
   '1c000000-0000-0000-0000-00000000001b', 'BuyerB', 'fa', 'active'),
  ('1c000000-0000-0000-0000-000000000003', '1c000000-0000-0000-0000-00000000000a',
   '1c000000-0000-0000-0000-00000000002a', 'Supplier', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '1c000000-0000-0000-0000-00000000000a', '1c000000-0000-0000-0000-00000000001a',
       '1c000000-0000-0000-0000-000000000001', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '1c000000-0000-0000-0000-00000000000b', '1c000000-0000-0000-0000-00000000001b',
       '1c000000-0000-0000-0000-000000000002', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '1c000000-0000-0000-0000-00000000000a', '1c000000-0000-0000-0000-00000000002a',
       '1c000000-0000-0000-0000-000000000003', r.id, 'active', now()
  from identity.roles r where r.code = 'supplier_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '1c000000-0000-0000-0000-000000000001', r.id, 'organization', '1c000000-0000-0000-0000-00000000001a'
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '1c000000-0000-0000-0000-000000000002', r.id, 'organization', '1c000000-0000-0000-0000-00000000001b'
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '1c000000-0000-0000-0000-000000000003', r.id, 'organization', '1c000000-0000-0000-0000-00000000002a'
  from identity.roles r where r.code = 'supplier_admin';

-- Build A's executed contract + create a draft invoice on it.
do $$
declare
  v_sup uuid; v_prod uuid; v_rfq uuid; v_item uuid; v_off uuid; v_dec uuid;
  v_prep uuid; v_contract uuid; v_p_b uuid; v_p_s uuid; v_sr_b uuid; v_sr_s uuid;
  v_inv uuid;
begin
  select id into v_sup  from supplier.suppliers where organization_id = '1c000000-0000-0000-0000-00000000002a';
  select id into v_prod from commodity.products where code = 'methanol';

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','1c000000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','1c000000-0000-0000-0000-00000000000a',
                       'organization_id','1c000000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '1c000000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_rfq := rfq.buyer_create_rfq(p_title => 'R for scope');
  v_item := rfq.buyer_upsert_rfq_item(p_request_id => v_rfq, p_product_id => v_prod,
                                       p_quantity => 100, p_quantity_unit => 'ton');
  perform rfq.buyer_submit_rfq(v_rfq);
  perform rfq.buyer_invite_suppliers(v_rfq, array[v_sup]);
  reset role;

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','1c000000-0000-0000-0000-000000000003','role','authenticated',
                       'tenant_id','1c000000-0000-0000-0000-00000000000a',
                       'organization_id','1c000000-0000-0000-0000-00000000002a')::text, true);
  perform set_config('request.jwt.claim.sub', '1c000000-0000-0000-0000-000000000003', true);
  set local role authenticated;
  v_off := offer.supplier_create_draft_offer(p_request_id => v_rfq);
  perform offer.supplier_upsert_offer_item(p_offer_id => v_off, p_request_item_id => v_item,
    p_offered_quantity => 100, p_quantity_unit => 'ton', p_unit_price => 100, p_currency => 'USD');
  perform offer.supplier_submit_my_offer(v_off);
  reset role;

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','1c000000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','1c000000-0000-0000-0000-00000000000a',
                       'organization_id','1c000000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '1c000000-0000-0000-0000-000000000001', true);
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
    jsonb_build_object('sub','1c000000-0000-0000-0000-000000000003','role','authenticated',
                       'tenant_id','1c000000-0000-0000-0000-00000000000a',
                       'organization_id','1c000000-0000-0000-0000-00000000002a')::text, true);
  perform set_config('request.jwt.claim.sub', '1c000000-0000-0000-0000-000000000003', true);
  set local role authenticated;
  perform contract.supplier_sign_signature_request(v_sr_s);
  reset role;

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','1c000000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','1c000000-0000-0000-0000-00000000000a',
                       'organization_id','1c000000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '1c000000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_inv := finance.buyer_create_draft_invoice(
    p_executed_contract_id => v_contract, p_currency => 'USD', p_due_date => current_date + 30
  );
  perform finance.buyer_upsert_invoice_item(
    p_invoice_id => v_inv, p_description => 'Item 1',
    p_quantity => 1, p_unit_price => 100, p_tax_rate => 0
  );
  reset role;

  perform set_config('test.contract', v_contract::text, false);
  perform set_config('test.invoice',  v_inv::text,      false);
end;
$$;

select plan(7);

-- 1. Buyer B cannot create invoice from buyer A's executed contract.
select tests.authenticate_as(
  '1c000000-0000-0000-0000-000000000002',
  '1c000000-0000-0000-0000-00000000000b',
  '1c000000-0000-0000-0000-00000000001b'
);
set local role authenticated;
select throws_ok(
  format($$ select finance.buyer_create_draft_invoice(p_executed_contract_id => %L::uuid) $$,
         current_setting('test.contract')),
  '42501', null,
  'buyer B cannot create invoice from buyer A''s executed contract (42501)'
);

-- 2. Buyer B cannot get buyer A's invoice.
select throws_ok(
  format($$ select finance.buyer_get_invoice(%L::uuid) $$, current_setting('test.invoice')),
  '42501', null,
  'buyer B cannot get buyer A''s invoice (42501)'
);
reset role;

-- 3. Cannot send from draft (must issue first).
select tests.authenticate_as(
  '1c000000-0000-0000-0000-000000000001',
  '1c000000-0000-0000-0000-00000000000a',
  '1c000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select throws_ok(
  format($$ select finance.buyer_send_invoice(%L::uuid) $$, current_setting('test.invoice')),
  'P0001', null,
  'cannot send from draft (must issue first) (P0001)'
);

-- 4. Cannot record payment on a draft invoice.
select throws_ok(
  format($$ select finance.buyer_record_payment(%L::uuid, 100) $$, current_setting('test.invoice')),
  'P0001', null,
  'cannot record payment on a draft invoice (P0001)'
);

-- 5. Cannot record payment with paid_amount = 0.
do $$
begin
  perform finance.buyer_issue_invoice(current_setting('test.invoice')::uuid);
end;
$$;

select throws_ok(
  format($$ select finance.buyer_record_payment(%L::uuid, 0) $$, current_setting('test.invoice')),
  '22023', null,
  'cannot record payment with paid_amount <= 0 (22023)'
);

-- 6. buyer_create_draft_invoice requires contract OR shipment.
select throws_ok(
  $$ select finance.buyer_create_draft_invoice() $$,
  '22023', null,
  'buyer_create_draft_invoice requires contract OR shipment (22023)'
);

-- 7. Pay invoice fully, then cancellation is rejected.
do $$
begin
  perform finance.buyer_record_payment(current_setting('test.invoice')::uuid, 100);
end;
$$;
select throws_ok(
  format($$ select finance.buyer_cancel_invoice(%L::uuid) $$, current_setting('test.invoice')),
  'P0001', null,
  'cancelling a paid invoice rejected (P0001)'
);
reset role;

select * from finish();
rollback;
