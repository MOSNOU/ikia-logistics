-- CC-16 Test 061 — Supplier visibility + event immutability:
--   * supplier X sees own invoice via supplier_list_my_invoices
--   * supplier X gets own invoice detail
--   * unrelated supplier Y sees 0 invoices
--   * unrelated supplier cannot get invoice (42501)
--   * supplier_record_payment_receipt creates a 'completed' payment with party=supplier
--   * direct UPDATE on invoice_status_events blocked
--   * direct DELETE on payment_status_events blocked

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  app_storage, finance, tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '1e000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '061-buyer@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '1e000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', '061-supX@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '1e000000-0000-0000-0000-000000000003', 'authenticated', 'authenticated', '061-supY@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('1e000000-0000-0000-0000-00000000000a', 'tenant-061', 'تست', 'Test');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('1e000000-0000-0000-0000-00000000001a', '1e000000-0000-0000-0000-00000000000a',
   'buyer-061', 'خریدار', 'Buyer 061', 'buyer', 'active'),
  ('1e000000-0000-0000-0000-00000000002a', '1e000000-0000-0000-0000-00000000000a',
   'sup-061-X', 'ایکس', 'SupX', 'supplier', 'active'),
  ('1e000000-0000-0000-0000-00000000002b', '1e000000-0000-0000-0000-00000000000a',
   'sup-061-Y', 'وای', 'SupY', 'supplier', 'active');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('1e000000-0000-0000-0000-000000000001', '1e000000-0000-0000-0000-00000000000a',
   '1e000000-0000-0000-0000-00000000001a', 'Buyer', 'fa', 'active'),
  ('1e000000-0000-0000-0000-000000000002', '1e000000-0000-0000-0000-00000000000a',
   '1e000000-0000-0000-0000-00000000002a', 'SupX', 'fa', 'active'),
  ('1e000000-0000-0000-0000-000000000003', '1e000000-0000-0000-0000-00000000000a',
   '1e000000-0000-0000-0000-00000000002b', 'SupY', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '1e000000-0000-0000-0000-00000000000a', '1e000000-0000-0000-0000-00000000001a',
       '1e000000-0000-0000-0000-000000000001', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '1e000000-0000-0000-0000-00000000000a', '1e000000-0000-0000-0000-00000000002a',
       '1e000000-0000-0000-0000-000000000002', r.id, 'active', now()
  from identity.roles r where r.code = 'supplier_admin';
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '1e000000-0000-0000-0000-00000000000a', '1e000000-0000-0000-0000-00000000002b',
       '1e000000-0000-0000-0000-000000000003', r.id, 'active', now()
  from identity.roles r where r.code = 'supplier_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '1e000000-0000-0000-0000-000000000001', r.id, 'organization', '1e000000-0000-0000-0000-00000000001a'
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '1e000000-0000-0000-0000-000000000002', r.id, 'organization', '1e000000-0000-0000-0000-00000000002a'
  from identity.roles r where r.code = 'supplier_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '1e000000-0000-0000-0000-000000000003', r.id, 'organization', '1e000000-0000-0000-0000-00000000002b'
  from identity.roles r where r.code = 'supplier_admin';

-- Build contract on supplier X, issue invoice (status=sent), then test.
do $$
declare
  v_supX uuid; v_prod uuid; v_rfq uuid; v_item uuid; v_off uuid; v_dec uuid;
  v_prep uuid; v_contract uuid; v_p_b uuid; v_p_s uuid; v_sr_b uuid; v_sr_s uuid;
  v_inv uuid;
begin
  select id into v_supX from supplier.suppliers where organization_id = '1e000000-0000-0000-0000-00000000002a';
  select id into v_prod from commodity.products where code = 'methanol';

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','1e000000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','1e000000-0000-0000-0000-00000000000a',
                       'organization_id','1e000000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '1e000000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_rfq := rfq.buyer_create_rfq(p_title => 'R for supplier visibility');
  v_item := rfq.buyer_upsert_rfq_item(p_request_id => v_rfq, p_product_id => v_prod,
                                       p_quantity => 100, p_quantity_unit => 'ton');
  perform rfq.buyer_submit_rfq(v_rfq);
  perform rfq.buyer_invite_suppliers(v_rfq, array[v_supX]);
  reset role;

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','1e000000-0000-0000-0000-000000000002','role','authenticated',
                       'tenant_id','1e000000-0000-0000-0000-00000000000a',
                       'organization_id','1e000000-0000-0000-0000-00000000002a')::text, true);
  perform set_config('request.jwt.claim.sub', '1e000000-0000-0000-0000-000000000002', true);
  set local role authenticated;
  v_off := offer.supplier_create_draft_offer(p_request_id => v_rfq);
  perform offer.supplier_upsert_offer_item(p_offer_id => v_off, p_request_item_id => v_item,
    p_offered_quantity => 100, p_quantity_unit => 'ton', p_unit_price => 10, p_currency => 'USD');
  perform offer.supplier_submit_my_offer(v_off);
  reset role;

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','1e000000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','1e000000-0000-0000-0000-00000000000a',
                       'organization_id','1e000000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '1e000000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_dec := evaluation.buyer_select_for_contract(p_offer_id => v_off);
  v_prep := contract.buyer_create_preparation(p_decision_id => v_dec, p_title => 'sup vis prep');
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
    jsonb_build_object('sub','1e000000-0000-0000-0000-000000000002','role','authenticated',
                       'tenant_id','1e000000-0000-0000-0000-00000000000a',
                       'organization_id','1e000000-0000-0000-0000-00000000002a')::text, true);
  perform set_config('request.jwt.claim.sub', '1e000000-0000-0000-0000-000000000002', true);
  set local role authenticated;
  perform contract.supplier_sign_signature_request(v_sr_s);
  reset role;

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','1e000000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','1e000000-0000-0000-0000-00000000000a',
                       'organization_id','1e000000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '1e000000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_inv := finance.buyer_create_draft_invoice(
    p_executed_contract_id => v_contract, p_currency => 'USD'
  );
  perform finance.buyer_upsert_invoice_item(
    p_invoice_id => v_inv, p_description => 'Item',
    p_quantity => 10, p_unit_price => 100, p_tax_rate => 0
  );
  perform finance.buyer_issue_invoice(v_inv);
  perform finance.buyer_send_invoice(v_inv);
  reset role;

  perform set_config('test.invoice', v_inv::text, false);
end;
$$;

select plan(7);

-- 1. Supplier X sees own invoice.
select tests.authenticate_as(
  '1e000000-0000-0000-0000-000000000002',
  '1e000000-0000-0000-0000-00000000000a',
  '1e000000-0000-0000-0000-00000000002a'
);
set local role authenticated;
select is(
  (select count(*)::int from finance.supplier_list_my_invoices(null, 100, 0)),
  1,
  'supplier X sees own invoice via supplier_list_my_invoices'
);

-- 2. Supplier X gets own detail.
select is(
  (finance.supplier_get_my_invoice(current_setting('test.invoice')::uuid))->>'status',
  'sent',
  'supplier_get_my_invoice returns status=sent'
);

-- 3. Supplier X records payment receipt.
do $$
declare v_p uuid;
begin
  v_p := finance.supplier_record_payment_receipt(
    p_invoice_id => current_setting('test.invoice')::uuid,
    p_paid_amount => 1000,
    p_payment_date => current_date,
    p_transaction_reference => 'SUP-RX-1'
  );
  perform set_config('test.payment', v_p::text, false);
end;
$$;
reset role;

select is(
  (select recorded_by_party from finance.payments where id = current_setting('test.payment')::uuid),
  'supplier',
  'supplier_record_payment_receipt creates payment with recorded_by_party=supplier'
);

-- 4. Unrelated supplier Y sees 0 invoices.
select tests.authenticate_as(
  '1e000000-0000-0000-0000-000000000003',
  '1e000000-0000-0000-0000-00000000000a',
  '1e000000-0000-0000-0000-00000000002b'
);
set local role authenticated;
select is(
  (select count(*)::int from finance.supplier_list_my_invoices(null, 100, 0)),
  0,
  'unrelated supplier Y sees 0 invoices'
);

-- 5. Unrelated supplier cannot get invoice (42501).
select throws_ok(
  format($$ select finance.supplier_get_my_invoice(%L::uuid) $$, current_setting('test.invoice')),
  '42501', null,
  'unrelated supplier cannot get invoice (42501)'
);
reset role;

-- 6. Direct UPDATE on invoice_status_events blocked.
select tests.authenticate_as(
  '1e000000-0000-0000-0000-000000000001',
  '1e000000-0000-0000-0000-00000000000a',
  '1e000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select throws_ok(
  format($$ update finance.invoice_status_events set reason = 'tamper'
            where invoice_id = %L::uuid $$, current_setting('test.invoice')),
  '42501', null,
  'direct UPDATE on invoice_status_events is blocked (no grant)'
);

-- 7. Direct DELETE on payment_status_events blocked.
select throws_ok(
  format($$ delete from finance.payment_status_events
            where invoice_id = %L::uuid $$, current_setting('test.invoice')),
  '42501', null,
  'direct DELETE on payment_status_events is blocked (no grant)'
);
reset role;

select * from finish();
rollback;
