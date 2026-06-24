-- CC-16 Test 060 — Payment lifecycle: partial + refund + re-promotion:
--   * partial payment promotes invoice to 'partial'
--   * second partial payment completes coverage → invoice 'paid'
--   * refund flips payment status → invoice drops back from 'paid' to 'partial'
--   * only completed payments are refundable (refunding non-completed → P0001)

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  app_storage, finance, tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '1d000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '060-buyer@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '1d000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', '060-sup@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('1d000000-0000-0000-0000-00000000000a', 'tenant-060', 'تست', 'Test');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('1d000000-0000-0000-0000-00000000001a', '1d000000-0000-0000-0000-00000000000a',
   'buyer-060', 'خریدار', 'Buyer 060', 'buyer', 'active'),
  ('1d000000-0000-0000-0000-00000000002a', '1d000000-0000-0000-0000-00000000000a',
   'sup-060', 'تأمین', 'Supplier 060', 'supplier', 'active');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('1d000000-0000-0000-0000-000000000001', '1d000000-0000-0000-0000-00000000000a',
   '1d000000-0000-0000-0000-00000000001a', 'Buyer', 'fa', 'active'),
  ('1d000000-0000-0000-0000-000000000002', '1d000000-0000-0000-0000-00000000000a',
   '1d000000-0000-0000-0000-00000000002a', 'Supplier', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '1d000000-0000-0000-0000-00000000000a', '1d000000-0000-0000-0000-00000000001a',
       '1d000000-0000-0000-0000-000000000001', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '1d000000-0000-0000-0000-00000000000a', '1d000000-0000-0000-0000-00000000002a',
       '1d000000-0000-0000-0000-000000000002', r.id, 'active', now()
  from identity.roles r where r.code = 'supplier_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '1d000000-0000-0000-0000-000000000001', r.id, 'organization', '1d000000-0000-0000-0000-00000000001a'
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '1d000000-0000-0000-0000-000000000002', r.id, 'organization', '1d000000-0000-0000-0000-00000000002a'
  from identity.roles r where r.code = 'supplier_admin';

-- Build contract → issued invoice with total 1000.
do $$
declare
  v_sup uuid; v_prod uuid; v_rfq uuid; v_item uuid; v_off uuid; v_dec uuid;
  v_prep uuid; v_contract uuid; v_p_b uuid; v_p_s uuid; v_sr_b uuid; v_sr_s uuid;
  v_inv uuid;
begin
  select id into v_sup  from supplier.suppliers where organization_id = '1d000000-0000-0000-0000-00000000002a';
  select id into v_prod from commodity.products where code = 'methanol';

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','1d000000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','1d000000-0000-0000-0000-00000000000a',
                       'organization_id','1d000000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '1d000000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_rfq := rfq.buyer_create_rfq(p_title => 'R for payment lifecycle');
  v_item := rfq.buyer_upsert_rfq_item(p_request_id => v_rfq, p_product_id => v_prod,
                                       p_quantity => 100, p_quantity_unit => 'ton');
  perform rfq.buyer_submit_rfq(v_rfq);
  perform rfq.buyer_invite_suppliers(v_rfq, array[v_sup]);
  reset role;

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','1d000000-0000-0000-0000-000000000002','role','authenticated',
                       'tenant_id','1d000000-0000-0000-0000-00000000000a',
                       'organization_id','1d000000-0000-0000-0000-00000000002a')::text, true);
  perform set_config('request.jwt.claim.sub', '1d000000-0000-0000-0000-000000000002', true);
  set local role authenticated;
  v_off := offer.supplier_create_draft_offer(p_request_id => v_rfq);
  perform offer.supplier_upsert_offer_item(p_offer_id => v_off, p_request_item_id => v_item,
    p_offered_quantity => 100, p_quantity_unit => 'ton', p_unit_price => 10, p_currency => 'USD');
  perform offer.supplier_submit_my_offer(v_off);
  reset role;

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','1d000000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','1d000000-0000-0000-0000-00000000000a',
                       'organization_id','1d000000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '1d000000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_dec := evaluation.buyer_select_for_contract(p_offer_id => v_off);
  v_prep := contract.buyer_create_preparation(p_decision_id => v_dec, p_title => 'pay lifecycle prep');
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
    jsonb_build_object('sub','1d000000-0000-0000-0000-000000000002','role','authenticated',
                       'tenant_id','1d000000-0000-0000-0000-00000000000a',
                       'organization_id','1d000000-0000-0000-0000-00000000002a')::text, true);
  perform set_config('request.jwt.claim.sub', '1d000000-0000-0000-0000-000000000002', true);
  set local role authenticated;
  perform contract.supplier_sign_signature_request(v_sr_s);
  reset role;

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','1d000000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','1d000000-0000-0000-0000-00000000000a',
                       'organization_id','1d000000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '1d000000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_inv := finance.buyer_create_draft_invoice(
    p_executed_contract_id => v_contract, p_currency => 'USD', p_due_date => current_date + 30
  );
  perform finance.buyer_upsert_invoice_item(
    p_invoice_id => v_inv, p_description => 'Methanol invoice',
    p_quantity => 100, p_unit_price => 10, p_tax_rate => 0  -- total = 1000
  );
  perform finance.buyer_issue_invoice(v_inv);
  reset role;

  perform set_config('test.invoice', v_inv::text, false);
end;
$$;

select plan(5);

-- 1. First partial payment of 600 → invoice 'partial'.
select tests.authenticate_as(
  '1d000000-0000-0000-0000-000000000001',
  '1d000000-0000-0000-0000-00000000000a',
  '1d000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
do $$
declare v_p1 uuid;
begin
  v_p1 := finance.buyer_record_payment(
    p_invoice_id => current_setting('test.invoice')::uuid,
    p_paid_amount => 600
  );
  perform set_config('test.payment1', v_p1::text, false);
end;
$$;
reset role;

select is(
  (select status::text from finance.invoices where id = current_setting('test.invoice')::uuid),
  'partial',
  'partial payment promotes invoice to partial'
);

-- 2. Second partial payment of 400 → invoice 'paid'.
select tests.authenticate_as(
  '1d000000-0000-0000-0000-000000000001',
  '1d000000-0000-0000-0000-00000000000a',
  '1d000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
do $$
declare v_p2 uuid;
begin
  v_p2 := finance.buyer_record_payment(
    p_invoice_id => current_setting('test.invoice')::uuid,
    p_paid_amount => 400
  );
  perform set_config('test.payment2', v_p2::text, false);
end;
$$;
reset role;

select is(
  (select status::text from finance.invoices where id = current_setting('test.invoice')::uuid),
  'paid',
  'second partial payment completing coverage promotes invoice to paid'
);

-- 3. Refund the first payment → invoice drops back to 'partial'.
select tests.authenticate_as(
  '1d000000-0000-0000-0000-000000000001',
  '1d000000-0000-0000-0000-00000000000a',
  '1d000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select finance.buyer_refund_payment(current_setting('test.payment1')::uuid, p_reason => 'duplicate');
reset role;

select is(
  (select status::text from finance.payments where id = current_setting('test.payment1')::uuid),
  'refunded',
  'buyer_refund_payment flips payment status to refunded'
);

-- 4. Invoice goes back to 'partial' (paid amount drops from 1000 → 400).
select is(
  (select status::text from finance.invoices where id = current_setting('test.invoice')::uuid),
  'partial',
  'refund drops invoice back to partial'
);

-- 5. Refunding an already-refunded payment → P0001.
select tests.authenticate_as(
  '1d000000-0000-0000-0000-000000000001',
  '1d000000-0000-0000-0000-00000000000a',
  '1d000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select throws_ok(
  format($$ select finance.buyer_refund_payment(%L::uuid) $$, current_setting('test.payment1')),
  'P0001', null,
  'refunding a non-completed payment is rejected (P0001)'
);
reset role;

select * from finish();
rollback;
