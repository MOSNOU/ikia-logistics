-- CC-16 Test 058 — Buyer invoice lifecycle:
--   create draft from executed contract → add item → issue → send → record full payment
--   → invoice auto-promotes to 'paid'.
--
-- Assertions (11):
--   1. buyer_create_draft_invoice creates invoice with status='draft'
--   2. buyer_upsert_invoice_item adds an item; total computed = qty*price*(1+tax)
--   3. invoice total_amount recomputed after item add (= 11500)
--   4. buyer_issue_invoice moves draft → issued, sets invoice_date
--   5. buyer_send_invoice moves issued → sent
--   6. buyer_record_payment with completed status creates a payment
--   7. paid_amount on the invoice is updated
--   8. invoice auto-promotes to 'paid' (full payment covers total)
--   9. paid_at is set
--  10. invoice_status_events has the 'paid' transition row
--  11. payment_status_events has a 'completed' row

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  app_storage, finance, tests;
begin;

-- Fixtures: full chain to executed contract.
insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '1b000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '058-buyer@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '1b000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', '058-sup@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('1b000000-0000-0000-0000-00000000000a', 'tenant-058', 'تست', 'Test');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('1b000000-0000-0000-0000-00000000001a', '1b000000-0000-0000-0000-00000000000a',
   'buyer-058', 'خریدار', 'Buyer 058', 'buyer', 'active'),
  ('1b000000-0000-0000-0000-00000000002a', '1b000000-0000-0000-0000-00000000000a',
   'sup-058', 'تأمین', 'Supplier 058', 'supplier', 'active');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('1b000000-0000-0000-0000-000000000001', '1b000000-0000-0000-0000-00000000000a',
   '1b000000-0000-0000-0000-00000000001a', 'Buyer', 'fa', 'active'),
  ('1b000000-0000-0000-0000-000000000002', '1b000000-0000-0000-0000-00000000000a',
   '1b000000-0000-0000-0000-00000000002a', 'Supplier', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '1b000000-0000-0000-0000-00000000000a', '1b000000-0000-0000-0000-00000000001a',
       '1b000000-0000-0000-0000-000000000001', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '1b000000-0000-0000-0000-00000000000a', '1b000000-0000-0000-0000-00000000002a',
       '1b000000-0000-0000-0000-000000000002', r.id, 'active', now()
  from identity.roles r where r.code = 'supplier_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '1b000000-0000-0000-0000-000000000001', r.id, 'organization', '1b000000-0000-0000-0000-00000000001a'
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '1b000000-0000-0000-0000-000000000002', r.id, 'organization', '1b000000-0000-0000-0000-00000000002a'
  from identity.roles r where r.code = 'supplier_admin';

do $$
declare
  v_sup uuid; v_prod uuid; v_rfq uuid; v_item uuid; v_off uuid; v_dec uuid;
  v_prep uuid; v_contract uuid; v_p_b uuid; v_p_s uuid; v_sr_b uuid; v_sr_s uuid;
begin
  select id into v_sup  from supplier.suppliers where organization_id = '1b000000-0000-0000-0000-00000000002a';
  select id into v_prod from commodity.products where code = 'methanol';

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','1b000000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','1b000000-0000-0000-0000-00000000000a',
                       'organization_id','1b000000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '1b000000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_rfq := rfq.buyer_create_rfq(p_title => 'R for finance lifecycle');
  v_item := rfq.buyer_upsert_rfq_item(p_request_id => v_rfq, p_product_id => v_prod,
                                       p_quantity => 100, p_quantity_unit => 'ton');
  perform rfq.buyer_submit_rfq(v_rfq);
  perform rfq.buyer_invite_suppliers(v_rfq, array[v_sup]);
  reset role;

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','1b000000-0000-0000-0000-000000000002','role','authenticated',
                       'tenant_id','1b000000-0000-0000-0000-00000000000a',
                       'organization_id','1b000000-0000-0000-0000-00000000002a')::text, true);
  perform set_config('request.jwt.claim.sub', '1b000000-0000-0000-0000-000000000002', true);
  set local role authenticated;
  v_off := offer.supplier_create_draft_offer(p_request_id => v_rfq);
  perform offer.supplier_upsert_offer_item(p_offer_id => v_off, p_request_item_id => v_item,
    p_offered_quantity => 100, p_quantity_unit => 'ton', p_unit_price => 100, p_currency => 'USD');
  perform offer.supplier_submit_my_offer(v_off);
  reset role;

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','1b000000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','1b000000-0000-0000-0000-00000000000a',
                       'organization_id','1b000000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '1b000000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_dec := evaluation.buyer_select_for_contract(p_offer_id => v_off);
  v_prep := contract.buyer_create_preparation(p_decision_id => v_dec, p_title => 'fin prep');
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
    jsonb_build_object('sub','1b000000-0000-0000-0000-000000000002','role','authenticated',
                       'tenant_id','1b000000-0000-0000-0000-00000000000a',
                       'organization_id','1b000000-0000-0000-0000-00000000002a')::text, true);
  perform set_config('request.jwt.claim.sub', '1b000000-0000-0000-0000-000000000002', true);
  set local role authenticated;
  perform contract.supplier_sign_signature_request(v_sr_s);
  reset role;

  perform set_config('test.contract', v_contract::text, false);
end;
$$;

select plan(11);

-- 1. Create draft invoice from executed contract.
select tests.authenticate_as(
  '1b000000-0000-0000-0000-000000000001',
  '1b000000-0000-0000-0000-00000000000a',
  '1b000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
do $$
declare v_inv uuid;
begin
  v_inv := finance.buyer_create_draft_invoice(
    p_executed_contract_id => current_setting('test.contract')::uuid,
    p_currency => 'USD',
    p_due_date => current_date + 30
  );
  perform set_config('test.invoice', v_inv::text, false);
end;
$$;
reset role;

select is(
  (select status::text from finance.invoices where id = current_setting('test.invoice')::uuid),
  'draft',
  'buyer_create_draft_invoice creates invoice with status=draft'
);

-- 2. Add an item. qty=100, unit_price=100, tax_rate=0.15 → total = 11500.
select tests.authenticate_as(
  '1b000000-0000-0000-0000-000000000001',
  '1b000000-0000-0000-0000-00000000000a',
  '1b000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
do $$
declare v_it uuid;
begin
  v_it := finance.buyer_upsert_invoice_item(
    p_invoice_id => current_setting('test.invoice')::uuid,
    p_description => 'Methanol 100 tons',
    p_quantity => 100, p_quantity_unit => 'ton',
    p_unit_price => 100, p_tax_rate => 0.15
  );
end;
$$;
reset role;

select is(
  (select total from finance.invoice_items
    where invoice_id = current_setting('test.invoice')::uuid and deleted_at is null
   limit 1),
  numeric '11500',
  'invoice item total computed = qty * price * (1+tax) = 11500'
);

-- 3. Invoice total_amount recomputed.
select is(
  (select total_amount from finance.invoices where id = current_setting('test.invoice')::uuid),
  numeric '11500',
  'invoice total_amount = 11500 after item recompute'
);

-- 4. Issue.
select tests.authenticate_as(
  '1b000000-0000-0000-0000-000000000001',
  '1b000000-0000-0000-0000-00000000000a',
  '1b000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select finance.buyer_issue_invoice(current_setting('test.invoice')::uuid);
reset role;

select is(
  (select status::text from finance.invoices where id = current_setting('test.invoice')::uuid),
  'issued',
  'buyer_issue_invoice moves draft → issued'
);

-- 5. Send.
select tests.authenticate_as(
  '1b000000-0000-0000-0000-000000000001',
  '1b000000-0000-0000-0000-00000000000a',
  '1b000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select finance.buyer_send_invoice(current_setting('test.invoice')::uuid);
reset role;

select is(
  (select status::text from finance.invoices where id = current_setting('test.invoice')::uuid),
  'sent',
  'buyer_send_invoice moves issued → sent'
);

-- 6. Record full payment.
select tests.authenticate_as(
  '1b000000-0000-0000-0000-000000000001',
  '1b000000-0000-0000-0000-00000000000a',
  '1b000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
do $$
declare v_pay uuid;
begin
  v_pay := finance.buyer_record_payment(
    p_invoice_id => current_setting('test.invoice')::uuid,
    p_paid_amount => 11500,
    p_payment_date => current_date,
    p_transaction_reference => 'TX-001'
  );
  perform set_config('test.payment', v_pay::text, false);
end;
$$;
reset role;

select is(
  (select status::text from finance.payments where id = current_setting('test.payment')::uuid),
  'completed',
  'buyer_record_payment creates payment with status=completed'
);

-- 7. paid_amount updated on invoice.
select is(
  (select paid_amount from finance.invoices where id = current_setting('test.invoice')::uuid),
  numeric '11500',
  'invoice paid_amount updated to 11500 after recording payment'
);

-- 8. Invoice auto-promotes to 'paid'.
select is(
  (select status::text from finance.invoices where id = current_setting('test.invoice')::uuid),
  'paid',
  'invoice auto-promotes to paid (full payment covers total)'
);

-- 9. paid_at populated.
select isnt(
  (select paid_at from finance.invoices where id = current_setting('test.invoice')::uuid),
  null,
  'paid_at is populated when invoice reaches paid'
);

-- 10. invoice_status_events has the 'paid' transition row.
select is(
  (select count(*)::int from finance.invoice_status_events
    where invoice_id = current_setting('test.invoice')::uuid
      and to_status = 'paid'),
  1,
  'invoice_status_events has the paid transition row'
);

-- 11. payment_status_events has a 'completed' row.
select is(
  (select count(*)::int from finance.payment_status_events
    where payment_id = current_setting('test.payment')::uuid
      and to_status = 'completed'),
  1,
  'payment_status_events has a completed row'
);

select * from finish();
rollback;
