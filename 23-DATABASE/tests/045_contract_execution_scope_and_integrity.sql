-- CC-13 Test 045 — Executed contract scope and integrity:
--   * buyer of org A cannot create executed contract from buyer B's preparation (42501)
--   * executed contract from a draft preparation is rejected (P0001)
--   * executed contract from an under_review preparation is rejected (P0001)
--   * executed contract from a cancelled preparation is rejected (P0001)
--   * duplicate active executed contract for same preparation is rejected (23505)
--   * no shipment/payment/settlement/escrow/invoice/accounting schemas exist

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '11000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '045-buyerA@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '11000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', '045-buyerB@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '11000000-0000-0000-0000-000000000003', 'authenticated', 'authenticated', '045-sup@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('11000000-0000-0000-0000-00000000000a', 'tenant-045a', 'الف', 'A'),
  ('11000000-0000-0000-0000-00000000000b', 'tenant-045b', 'ب',  'B');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('11000000-0000-0000-0000-00000000001a', '11000000-0000-0000-0000-00000000000a',
   'buyer-045a', 'خریدار الف', 'Buyer A', 'buyer', 'active'),
  ('11000000-0000-0000-0000-00000000001b', '11000000-0000-0000-0000-00000000000b',
   'buyer-045b', 'خریدار ب',  'Buyer B', 'buyer', 'active'),
  ('11000000-0000-0000-0000-00000000002a', '11000000-0000-0000-0000-00000000000a',
   'sup-045', 'تأمین',       'Supplier',  'supplier', 'active');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('11000000-0000-0000-0000-000000000001', '11000000-0000-0000-0000-00000000000a',
   '11000000-0000-0000-0000-00000000001a', 'BuyerA', 'fa', 'active'),
  ('11000000-0000-0000-0000-000000000002', '11000000-0000-0000-0000-00000000000b',
   '11000000-0000-0000-0000-00000000001b', 'BuyerB', 'fa', 'active'),
  ('11000000-0000-0000-0000-000000000003', '11000000-0000-0000-0000-00000000000a',
   '11000000-0000-0000-0000-00000000002a', 'Supplier', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '11000000-0000-0000-0000-00000000000a', '11000000-0000-0000-0000-00000000001a',
       '11000000-0000-0000-0000-000000000001', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '11000000-0000-0000-0000-00000000000b', '11000000-0000-0000-0000-00000000001b',
       '11000000-0000-0000-0000-000000000002', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '11000000-0000-0000-0000-00000000000a', '11000000-0000-0000-0000-00000000002a',
       '11000000-0000-0000-0000-000000000003', r.id, 'active', now()
  from identity.roles r where r.code = 'supplier_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '11000000-0000-0000-0000-000000000001', r.id, 'organization', '11000000-0000-0000-0000-00000000001a'
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '11000000-0000-0000-0000-000000000002', r.id, 'organization', '11000000-0000-0000-0000-00000000001b'
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '11000000-0000-0000-0000-000000000003', r.id, 'organization', '11000000-0000-0000-0000-00000000002a'
  from identity.roles r where r.code = 'supplier_admin';

-- Build three preparations under buyer A on three separate RFQs/offers:
--   prep_ready    — ready_for_contract  (used for cross-buyer test + duplicate test)
--   prep_draft    — draft
--   prep_review   — under_review
--   prep_cancelled — cancelled
do $$
declare
  v_sup uuid; v_prod uuid;
  v_rfq1 uuid; v_item1 uuid; v_off1 uuid; v_dec1 uuid; v_p_ready uuid;
  v_rfq2 uuid; v_item2 uuid; v_off2 uuid; v_dec2 uuid; v_p_draft uuid;
  v_rfq3 uuid; v_item3 uuid; v_off3 uuid; v_dec3 uuid; v_p_review uuid;
  v_rfq4 uuid; v_item4 uuid; v_off4 uuid; v_dec4 uuid; v_p_cancelled uuid;
begin
  select id into v_sup  from supplier.suppliers where organization_id = '11000000-0000-0000-0000-00000000002a';
  select id into v_prod from commodity.products where code = 'methanol';

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','11000000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','11000000-0000-0000-0000-00000000000a',
                       'organization_id','11000000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '11000000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  -- Four RFQs
  v_rfq1 := rfq.buyer_create_rfq(p_title => 'R045-ready');
  v_item1 := rfq.buyer_upsert_rfq_item(p_request_id => v_rfq1, p_product_id => v_prod, p_quantity => 1000, p_quantity_unit => 'ton');
  perform rfq.buyer_submit_rfq(v_rfq1);
  perform rfq.buyer_invite_suppliers(v_rfq1, array[v_sup]);

  v_rfq2 := rfq.buyer_create_rfq(p_title => 'R045-draft');
  v_item2 := rfq.buyer_upsert_rfq_item(p_request_id => v_rfq2, p_product_id => v_prod, p_quantity => 100, p_quantity_unit => 'ton');
  perform rfq.buyer_submit_rfq(v_rfq2);
  perform rfq.buyer_invite_suppliers(v_rfq2, array[v_sup]);

  v_rfq3 := rfq.buyer_create_rfq(p_title => 'R045-review');
  v_item3 := rfq.buyer_upsert_rfq_item(p_request_id => v_rfq3, p_product_id => v_prod, p_quantity => 200, p_quantity_unit => 'ton');
  perform rfq.buyer_submit_rfq(v_rfq3);
  perform rfq.buyer_invite_suppliers(v_rfq3, array[v_sup]);

  v_rfq4 := rfq.buyer_create_rfq(p_title => 'R045-cancelled');
  v_item4 := rfq.buyer_upsert_rfq_item(p_request_id => v_rfq4, p_product_id => v_prod, p_quantity => 50, p_quantity_unit => 'ton');
  perform rfq.buyer_submit_rfq(v_rfq4);
  perform rfq.buyer_invite_suppliers(v_rfq4, array[v_sup]);
  reset role;

  -- Supplier submits offers on all four
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','11000000-0000-0000-0000-000000000003','role','authenticated',
                       'tenant_id','11000000-0000-0000-0000-00000000000a',
                       'organization_id','11000000-0000-0000-0000-00000000002a')::text, true);
  perform set_config('request.jwt.claim.sub', '11000000-0000-0000-0000-000000000003', true);
  set local role authenticated;
  v_off1 := offer.supplier_create_draft_offer(p_request_id => v_rfq1);
  perform offer.supplier_upsert_offer_item(p_offer_id => v_off1, p_request_item_id => v_item1,
    p_offered_quantity => 1000, p_quantity_unit => 'ton', p_unit_price => 380, p_currency => 'USD');
  perform offer.supplier_submit_my_offer(v_off1);

  v_off2 := offer.supplier_create_draft_offer(p_request_id => v_rfq2);
  perform offer.supplier_upsert_offer_item(p_offer_id => v_off2, p_request_item_id => v_item2,
    p_offered_quantity => 100, p_quantity_unit => 'ton', p_unit_price => 390, p_currency => 'USD');
  perform offer.supplier_submit_my_offer(v_off2);

  v_off3 := offer.supplier_create_draft_offer(p_request_id => v_rfq3);
  perform offer.supplier_upsert_offer_item(p_offer_id => v_off3, p_request_item_id => v_item3,
    p_offered_quantity => 200, p_quantity_unit => 'ton', p_unit_price => 400, p_currency => 'USD');
  perform offer.supplier_submit_my_offer(v_off3);

  v_off4 := offer.supplier_create_draft_offer(p_request_id => v_rfq4);
  perform offer.supplier_upsert_offer_item(p_offer_id => v_off4, p_request_item_id => v_item4,
    p_offered_quantity => 50, p_quantity_unit => 'ton', p_unit_price => 410, p_currency => 'USD');
  perform offer.supplier_submit_my_offer(v_off4);
  reset role;

  -- Buyer builds preparations
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','11000000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','11000000-0000-0000-0000-00000000000a',
                       'organization_id','11000000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '11000000-0000-0000-0000-000000000001', true);
  set local role authenticated;

  v_dec1 := evaluation.buyer_select_for_contract(p_offer_id => v_off1);
  v_p_ready := contract.buyer_create_preparation(p_decision_id => v_dec1, p_title => 'ready prep');
  perform contract.buyer_mark_ready_for_contract(v_p_ready);

  v_dec2 := evaluation.buyer_select_for_contract(p_offer_id => v_off2);
  v_p_draft := contract.buyer_create_preparation(p_decision_id => v_dec2, p_title => 'draft prep');
  -- left in draft

  v_dec3 := evaluation.buyer_select_for_contract(p_offer_id => v_off3);
  v_p_review := contract.buyer_create_preparation(p_decision_id => v_dec3, p_title => 'review prep');
  perform contract.buyer_move_to_under_review(v_p_review);

  v_dec4 := evaluation.buyer_select_for_contract(p_offer_id => v_off4);
  v_p_cancelled := contract.buyer_create_preparation(p_decision_id => v_dec4, p_title => 'cancelled prep');
  perform contract.buyer_cancel_preparation(v_p_cancelled, p_reason => 'test');
  reset role;

  perform set_config('test.p_ready',     v_p_ready::text,     false);
  perform set_config('test.p_draft',     v_p_draft::text,     false);
  perform set_config('test.p_review',    v_p_review::text,    false);
  perform set_config('test.p_cancelled', v_p_cancelled::text, false);
end;
$$;

select plan(6);

-- 1. Buyer B cannot create executed contract from buyer A's ready preparation.
select tests.authenticate_as(
  '11000000-0000-0000-0000-000000000002',
  '11000000-0000-0000-0000-00000000000b',
  '11000000-0000-0000-0000-00000000001b'
);
set local role authenticated;
select throws_ok(
  format($$ select contract.buyer_create_executed_contract(%L::uuid) $$, current_setting('test.p_ready')),
  '42501', null,
  'buyer B cannot create executed contract from buyer A''s preparation (42501)'
);
reset role;

-- 2. Executed contract from draft preparation rejected.
select tests.authenticate_as(
  '11000000-0000-0000-0000-000000000001',
  '11000000-0000-0000-0000-00000000000a',
  '11000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select throws_ok(
  format($$ select contract.buyer_create_executed_contract(%L::uuid) $$, current_setting('test.p_draft')),
  'P0001', null,
  'executed contract from draft preparation is rejected (P0001)'
);

-- 3. Executed contract from under_review preparation rejected.
select throws_ok(
  format($$ select contract.buyer_create_executed_contract(%L::uuid) $$, current_setting('test.p_review')),
  'P0001', null,
  'executed contract from under_review preparation is rejected (P0001)'
);

-- 4. Executed contract from cancelled preparation rejected.
select throws_ok(
  format($$ select contract.buyer_create_executed_contract(%L::uuid) $$, current_setting('test.p_cancelled')),
  'P0001', null,
  'executed contract from cancelled preparation is rejected (P0001)'
);

-- 5. Duplicate active executed contract for same preparation rejected.
do $$
declare v_c uuid;
begin
  v_c := contract.buyer_create_executed_contract(
    p_preparation_id => current_setting('test.p_ready')::uuid,
    p_title => 'first executed contract'
  );
  perform set_config('test.contract', v_c::text, false);
end;
$$;

select throws_ok(
  format($$ select contract.buyer_create_executed_contract(%L::uuid, p_title => 'second') $$,
         current_setting('test.p_ready')),
  '23505', null,
  'duplicate active executed contract for same preparation is rejected (23505)'
);
reset role;

-- 6. No forbidden side-effect schemas exist.
select is(
  (select count(*)::int from information_schema.schemata
    where schema_name in ('payment','shipment','settlement','escrow','invoice','accounting','negotiation','pricing')),
  0,
  'no shipment/payment/settlement/escrow/invoice/accounting/negotiation/pricing schemas were created'
);

select * from finish();
rollback;
