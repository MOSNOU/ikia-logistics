-- CC-12 Test 041 — Contract preparation transitions, events, and immutability:
--   * under_review transition writes an event row (draft → under_review)
--   * ready_for_contract transition writes an event row (under_review → ready_for_contract)
--   * ready_for_contract does NOT create any formal contract/execution/signature/payment/shipment
--     (no rows in offer.* with status='accepted' as a result of marking ready)
--   * direct UPDATE of an events row by authenticated user is blocked by lack of grant
--   * direct DELETE of an events row is blocked by lack of grant

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '0d0d0000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '041-buyer@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '0d0d0000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', '041-sup@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('0d0d0000-0000-0000-0000-00000000000a', 'tenant-041', 'تست', 'Test');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('0d0d0000-0000-0000-0000-00000000001a', '0d0d0000-0000-0000-0000-00000000000a',
   'buyer-041', 'خریدار', 'Buyer', 'buyer', 'active'),
  ('0d0d0000-0000-0000-0000-00000000002a', '0d0d0000-0000-0000-0000-00000000000a',
   'sup-041', 'تأمین', 'Supplier', 'supplier', 'active');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('0d0d0000-0000-0000-0000-000000000001', '0d0d0000-0000-0000-0000-00000000000a',
   '0d0d0000-0000-0000-0000-00000000001a', 'Buyer', 'fa', 'active'),
  ('0d0d0000-0000-0000-0000-000000000002', '0d0d0000-0000-0000-0000-00000000000a',
   '0d0d0000-0000-0000-0000-00000000002a', 'Supplier', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '0d0d0000-0000-0000-0000-00000000000a', '0d0d0000-0000-0000-0000-00000000001a',
       '0d0d0000-0000-0000-0000-000000000001', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '0d0d0000-0000-0000-0000-00000000000a', '0d0d0000-0000-0000-0000-00000000002a',
       '0d0d0000-0000-0000-0000-000000000002', r.id, 'active', now()
  from identity.roles r where r.code = 'supplier_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '0d0d0000-0000-0000-0000-000000000001', r.id, 'organization', '0d0d0000-0000-0000-0000-00000000001a'
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '0d0d0000-0000-0000-0000-000000000002', r.id, 'organization', '0d0d0000-0000-0000-0000-00000000002a'
  from identity.roles r where r.code = 'supplier_admin';

do $$
declare
  v_sup uuid; v_prod uuid; v_rfq uuid; v_item uuid; v_off uuid; v_dec uuid; v_prep uuid;
begin
  select id into v_sup  from supplier.suppliers where organization_id = '0d0d0000-0000-0000-0000-00000000002a';
  select id into v_prod from commodity.products where code = 'methanol';

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','0d0d0000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','0d0d0000-0000-0000-0000-00000000000a',
                       'organization_id','0d0d0000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '0d0d0000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_rfq := rfq.buyer_create_rfq(p_title => 'R for transitions test');
  v_item := rfq.buyer_upsert_rfq_item(p_request_id => v_rfq, p_product_id => v_prod,
                                       p_quantity => 1000, p_quantity_unit => 'ton');
  perform rfq.buyer_submit_rfq(v_rfq);
  perform rfq.buyer_invite_suppliers(v_rfq, array[v_sup]);
  reset role;

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','0d0d0000-0000-0000-0000-000000000002','role','authenticated',
                       'tenant_id','0d0d0000-0000-0000-0000-00000000000a',
                       'organization_id','0d0d0000-0000-0000-0000-00000000002a')::text, true);
  perform set_config('request.jwt.claim.sub', '0d0d0000-0000-0000-0000-000000000002', true);
  set local role authenticated;
  v_off := offer.supplier_create_draft_offer(p_request_id => v_rfq);
  perform offer.supplier_upsert_offer_item(p_offer_id => v_off, p_request_item_id => v_item,
    p_offered_quantity => 1000, p_quantity_unit => 'ton', p_unit_price => 380, p_currency => 'USD');
  perform offer.supplier_submit_my_offer(v_off);
  reset role;

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','0d0d0000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','0d0d0000-0000-0000-0000-00000000000a',
                       'organization_id','0d0d0000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '0d0d0000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_dec := evaluation.buyer_select_for_contract(p_offer_id => v_off);
  v_prep := contract.buyer_create_preparation(
    p_decision_id => v_dec,
    p_title       => 'transition prep'
  );
  perform contract.buyer_move_to_under_review(v_prep);
  perform contract.buyer_mark_ready_for_contract(v_prep);
  reset role;

  perform set_config('test.prep', v_prep::text, false);
  perform set_config('test.offer', v_off::text, false);
end;
$$;

select plan(5);

-- 1. under_review event was written.
select is(
  (select count(*)::int from contract.contract_preparation_events
    where preparation_id = current_setting('test.prep')::uuid
      and from_status = 'draft' and to_status = 'under_review'),
  1,
  'draft → under_review transition writes one event row'
);

-- 2. ready_for_contract event was written.
select is(
  (select count(*)::int from contract.contract_preparation_events
    where preparation_id = current_setting('test.prep')::uuid
      and from_status = 'under_review' and to_status = 'ready_for_contract'),
  1,
  'under_review → ready_for_contract transition writes one event row'
);

-- 3. ready_for_contract DID NOT promote the offer to 'accepted' (no cross-domain
--    auto-execution). Offer.status remains its prior value.
select isnt(
  (select status::text from offer.supplier_offers
    where id = current_setting('test.offer')::uuid),
  'accepted',
  'ready_for_contract does not promote offer to accepted (no auto-execution)'
);

-- 4. Direct UPDATE on events row is blocked by lack of grant (events are immutable).
select tests.authenticate_as(
  '0d0d0000-0000-0000-0000-000000000001',
  '0d0d0000-0000-0000-0000-00000000000a',
  '0d0d0000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select throws_ok(
  format($$ update contract.contract_preparation_events set reason = 'tamper'
            where preparation_id = %L::uuid $$, current_setting('test.prep')),
  '42501', null,
  'direct UPDATE on events row is blocked (no grant)'
);

-- 5. Direct DELETE on events row is blocked by lack of grant.
select throws_ok(
  format($$ delete from contract.contract_preparation_events
            where preparation_id = %L::uuid $$, current_setting('test.prep')),
  '42501', null,
  'direct DELETE on events row is blocked (no grant)'
);
reset role;

select * from finish();
rollback;
