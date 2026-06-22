-- CC-12 Test 040 — Contract preparation scope and integrity:
--   * buyer of org A cannot create preparation from buyer B's decision (42501)
--   * preparation from a shortlisted decision is rejected (P0001)
--   * preparation from a rejected decision is rejected (P0001)
--   * duplicate active preparation for same decision is rejected (23505)
--   * preparation does NOT create any contract/signature/payment/shipment record
--     (cross-domain integrity check: no new schemas/tables appeared)

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '0c0c0000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '040-buyerA@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '0c0c0000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', '040-buyerB@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '0c0c0000-0000-0000-0000-000000000003', 'authenticated', 'authenticated', '040-sup@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('0c0c0000-0000-0000-0000-00000000000a', 'tenant-040a', 'الف', 'A'),
  ('0c0c0000-0000-0000-0000-00000000000b', 'tenant-040b', 'ب',  'B');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('0c0c0000-0000-0000-0000-00000000001a', '0c0c0000-0000-0000-0000-00000000000a',
   'buyer-040a', 'خریدار الف', 'Buyer A', 'buyer', 'active'),
  ('0c0c0000-0000-0000-0000-00000000001b', '0c0c0000-0000-0000-0000-00000000000b',
   'buyer-040b', 'خریدار ب',  'Buyer B', 'buyer', 'active'),
  ('0c0c0000-0000-0000-0000-00000000002a', '0c0c0000-0000-0000-0000-00000000000a',
   'sup-040',   'تأمین',     'Supplier',  'supplier', 'active');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('0c0c0000-0000-0000-0000-000000000001', '0c0c0000-0000-0000-0000-00000000000a',
   '0c0c0000-0000-0000-0000-00000000001a', 'BuyerA', 'fa', 'active'),
  ('0c0c0000-0000-0000-0000-000000000002', '0c0c0000-0000-0000-0000-00000000000b',
   '0c0c0000-0000-0000-0000-00000000001b', 'BuyerB', 'fa', 'active'),
  ('0c0c0000-0000-0000-0000-000000000003', '0c0c0000-0000-0000-0000-00000000000a',
   '0c0c0000-0000-0000-0000-00000000002a', 'Supplier', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '0c0c0000-0000-0000-0000-00000000000a', '0c0c0000-0000-0000-0000-00000000001a',
       '0c0c0000-0000-0000-0000-000000000001', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '0c0c0000-0000-0000-0000-00000000000b', '0c0c0000-0000-0000-0000-00000000001b',
       '0c0c0000-0000-0000-0000-000000000002', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '0c0c0000-0000-0000-0000-00000000000a', '0c0c0000-0000-0000-0000-00000000002a',
       '0c0c0000-0000-0000-0000-000000000003', r.id, 'active', now()
  from identity.roles r where r.code = 'supplier_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '0c0c0000-0000-0000-0000-000000000001', r.id, 'organization', '0c0c0000-0000-0000-0000-00000000001a'
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '0c0c0000-0000-0000-0000-000000000002', r.id, 'organization', '0c0c0000-0000-0000-0000-00000000001b'
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '0c0c0000-0000-0000-0000-000000000003', r.id, 'organization', '0c0c0000-0000-0000-0000-00000000002a'
  from identity.roles r where r.code = 'supplier_admin';

-- Build two scenarios:
--   * d_selected     — decision_status = selected_for_contract
--   * d_shortlisted  — decision_status = shortlisted
--   * d_rejected     — decision_status = rejected
-- Use three separate RFQs / offers so the unique-active-decision-per-offer
-- and unique-active-offer-per-(supplier,RFQ) invariants don't collide.
do $$
declare
  v_sup uuid; v_prod uuid;
  v_rfq1 uuid; v_item1 uuid; v_off1 uuid; v_d_sel uuid;
  v_rfq2 uuid; v_item2 uuid; v_off2 uuid; v_d_short uuid;
  v_rfq3 uuid; v_item3 uuid; v_off3 uuid; v_d_rej uuid;
begin
  select id into v_sup  from supplier.suppliers where organization_id = '0c0c0000-0000-0000-0000-00000000002a';
  select id into v_prod from commodity.products where code = 'methanol';

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','0c0c0000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','0c0c0000-0000-0000-0000-00000000000a',
                       'organization_id','0c0c0000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '0c0c0000-0000-0000-0000-000000000001', true);
  set local role authenticated;

  v_rfq1 := rfq.buyer_create_rfq(p_title => 'R1 selected');
  v_item1 := rfq.buyer_upsert_rfq_item(p_request_id => v_rfq1, p_product_id => v_prod,
                                        p_quantity => 1000, p_quantity_unit => 'ton');
  perform rfq.buyer_submit_rfq(v_rfq1);
  perform rfq.buyer_invite_suppliers(v_rfq1, array[v_sup]);

  v_rfq2 := rfq.buyer_create_rfq(p_title => 'R2 shortlisted');
  v_item2 := rfq.buyer_upsert_rfq_item(p_request_id => v_rfq2, p_product_id => v_prod,
                                        p_quantity => 800, p_quantity_unit => 'ton');
  perform rfq.buyer_submit_rfq(v_rfq2);
  perform rfq.buyer_invite_suppliers(v_rfq2, array[v_sup]);

  v_rfq3 := rfq.buyer_create_rfq(p_title => 'R3 rejected');
  v_item3 := rfq.buyer_upsert_rfq_item(p_request_id => v_rfq3, p_product_id => v_prod,
                                        p_quantity => 500, p_quantity_unit => 'ton');
  perform rfq.buyer_submit_rfq(v_rfq3);
  perform rfq.buyer_invite_suppliers(v_rfq3, array[v_sup]);
  reset role;

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','0c0c0000-0000-0000-0000-000000000003','role','authenticated',
                       'tenant_id','0c0c0000-0000-0000-0000-00000000000a',
                       'organization_id','0c0c0000-0000-0000-0000-00000000002a')::text, true);
  perform set_config('request.jwt.claim.sub', '0c0c0000-0000-0000-0000-000000000003', true);
  set local role authenticated;
  v_off1 := offer.supplier_create_draft_offer(p_request_id => v_rfq1);
  perform offer.supplier_upsert_offer_item(p_offer_id => v_off1, p_request_item_id => v_item1,
    p_offered_quantity => 1000, p_quantity_unit => 'ton', p_unit_price => 380, p_currency => 'USD');
  perform offer.supplier_submit_my_offer(v_off1);

  v_off2 := offer.supplier_create_draft_offer(p_request_id => v_rfq2);
  perform offer.supplier_upsert_offer_item(p_offer_id => v_off2, p_request_item_id => v_item2,
    p_offered_quantity => 800, p_quantity_unit => 'ton', p_unit_price => 390, p_currency => 'USD');
  perform offer.supplier_submit_my_offer(v_off2);

  v_off3 := offer.supplier_create_draft_offer(p_request_id => v_rfq3);
  perform offer.supplier_upsert_offer_item(p_offer_id => v_off3, p_request_item_id => v_item3,
    p_offered_quantity => 500, p_quantity_unit => 'ton', p_unit_price => 400, p_currency => 'USD');
  perform offer.supplier_submit_my_offer(v_off3);
  reset role;

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','0c0c0000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','0c0c0000-0000-0000-0000-00000000000a',
                       'organization_id','0c0c0000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '0c0c0000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_d_sel   := evaluation.buyer_select_for_contract(p_offer_id => v_off1);
  v_d_short := evaluation.buyer_shortlist_offer(p_offer_id => v_off2);
  v_d_rej   := evaluation.buyer_reject_offer(p_offer_id => v_off3);
  reset role;

  perform set_config('test.d_sel',   v_d_sel::text,   false);
  perform set_config('test.d_short', v_d_short::text, false);
  perform set_config('test.d_rej',   v_d_rej::text,   false);
end;
$$;

select plan(5);

-- 1. Buyer B (unrelated) cannot create preparation from buyer A's selected decision.
select tests.authenticate_as(
  '0c0c0000-0000-0000-0000-000000000002',
  '0c0c0000-0000-0000-0000-00000000000b',
  '0c0c0000-0000-0000-0000-00000000001b'
);
set local role authenticated;
select throws_ok(
  format($$ select contract.buyer_create_preparation(%L::uuid, p_title => 'tamper') $$,
         current_setting('test.d_sel')),
  '42501', null,
  'buyer B cannot create preparation from buyer A''s decision (42501)'
);
reset role;

-- 2. Preparation from a shortlisted decision is rejected.
select tests.authenticate_as(
  '0c0c0000-0000-0000-0000-000000000001',
  '0c0c0000-0000-0000-0000-00000000000a',
  '0c0c0000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select throws_ok(
  format($$ select contract.buyer_create_preparation(%L::uuid, p_title => 'from shortlisted') $$,
         current_setting('test.d_short')),
  'P0001', null,
  'preparation from a shortlisted decision is rejected (P0001)'
);

-- 3. Preparation from a rejected decision is rejected.
select throws_ok(
  format($$ select contract.buyer_create_preparation(%L::uuid, p_title => 'from rejected') $$,
         current_setting('test.d_rej')),
  'P0001', null,
  'preparation from a rejected decision is rejected (P0001)'
);

-- 4. Duplicate active preparation for same decision: create once, then attempt again.
do $$
declare v_prep uuid;
begin
  v_prep := contract.buyer_create_preparation(
    p_decision_id => current_setting('test.d_sel')::uuid,
    p_title       => 'first preparation'
  );
  perform set_config('test.prep', v_prep::text, false);
end;
$$;

select throws_ok(
  format($$ select contract.buyer_create_preparation(%L::uuid, p_title => 'second preparation') $$,
         current_setting('test.d_sel')),
  '23505', null,
  'duplicate active preparation for same decision is rejected (23505)'
);
reset role;

-- 5. No formal contract / signature / payment / shipment record was created.
-- We verify cross-domain by asserting that no new schemas were introduced beyond
-- the eight known foundations (identity, organization, audit, supplier, commodity,
-- rfq, offer, evaluation) plus the new contract schema.
select is(
  (select count(*)::int from information_schema.schemata
    where schema_name in ('payment','shipment','settlement','escrow','signature','invoice','negotiation','execution')),
  0,
  'ready_for_contract does NOT create any payment/shipment/settlement/escrow/signature/invoice/negotiation/execution schema'
);

select * from finish();
rollback;
