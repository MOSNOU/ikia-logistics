-- CC-14 Test 051 — Status transitions write events + events immutability:
--   * draft → planned → booked → in_transit → arrived → delivered transitions
--     each produce one shipment_events row
--   * direct UPDATE on shipment_events row blocked (no grant)
--   * direct DELETE on shipment_events row blocked (no grant)
--   * cancelled shipment is locked from buyer_update_shipment (P0001)
--   * cancel from delivered is rejected (P0001)

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment, tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '16000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '051-buyer@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '16000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', '051-sup@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('16000000-0000-0000-0000-00000000000a', 'tenant-051', 'تست', 'Test');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('16000000-0000-0000-0000-00000000001a', '16000000-0000-0000-0000-00000000000a',
   'buyer-051', 'خریدار', 'Buyer 051', 'buyer', 'active'),
  ('16000000-0000-0000-0000-00000000002a', '16000000-0000-0000-0000-00000000000a',
   'sup-051', 'تأمین', 'Supplier 051', 'supplier', 'active');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('16000000-0000-0000-0000-000000000001', '16000000-0000-0000-0000-00000000000a',
   '16000000-0000-0000-0000-00000000001a', 'Buyer', 'fa', 'active'),
  ('16000000-0000-0000-0000-000000000002', '16000000-0000-0000-0000-00000000000a',
   '16000000-0000-0000-0000-00000000002a', 'Supplier', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '16000000-0000-0000-0000-00000000000a', '16000000-0000-0000-0000-00000000001a',
       '16000000-0000-0000-0000-000000000001', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '16000000-0000-0000-0000-00000000000a', '16000000-0000-0000-0000-00000000002a',
       '16000000-0000-0000-0000-000000000002', r.id, 'active', now()
  from identity.roles r where r.code = 'supplier_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '16000000-0000-0000-0000-000000000001', r.id, 'organization', '16000000-0000-0000-0000-00000000001a'
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '16000000-0000-0000-0000-000000000002', r.id, 'organization', '16000000-0000-0000-0000-00000000002a'
  from identity.roles r where r.code = 'supplier_admin';

-- Build two shipments under one executed contract:
--   sh_full     — runs draft → delivered (all transitions)
--   sh_cancel   — created and cancelled
do $$
declare
  v_sup uuid; v_prod uuid; v_rfq uuid; v_item uuid; v_off uuid; v_dec uuid;
  v_prep uuid; v_contract uuid; v_p_b uuid; v_p_s uuid; v_sr_b uuid; v_sr_s uuid;
  v_sh_full uuid; v_sh_cancel uuid;
begin
  select id into v_sup  from supplier.suppliers where organization_id = '16000000-0000-0000-0000-00000000002a';
  select id into v_prod from commodity.products where code = 'methanol';

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','16000000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','16000000-0000-0000-0000-00000000000a',
                       'organization_id','16000000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '16000000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_rfq := rfq.buyer_create_rfq(p_title => 'R for transitions');
  v_item := rfq.buyer_upsert_rfq_item(p_request_id => v_rfq, p_product_id => v_prod,
                                       p_quantity => 1000, p_quantity_unit => 'ton');
  perform rfq.buyer_submit_rfq(v_rfq);
  perform rfq.buyer_invite_suppliers(v_rfq, array[v_sup]);
  reset role;

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','16000000-0000-0000-0000-000000000002','role','authenticated',
                       'tenant_id','16000000-0000-0000-0000-00000000000a',
                       'organization_id','16000000-0000-0000-0000-00000000002a')::text, true);
  perform set_config('request.jwt.claim.sub', '16000000-0000-0000-0000-000000000002', true);
  set local role authenticated;
  v_off := offer.supplier_create_draft_offer(p_request_id => v_rfq);
  perform offer.supplier_upsert_offer_item(p_offer_id => v_off, p_request_item_id => v_item,
    p_offered_quantity => 1000, p_quantity_unit => 'ton', p_unit_price => 380, p_currency => 'USD');
  perform offer.supplier_submit_my_offer(v_off);
  reset role;

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','16000000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','16000000-0000-0000-0000-00000000000a',
                       'organization_id','16000000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '16000000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_dec := evaluation.buyer_select_for_contract(p_offer_id => v_off);
  v_prep := contract.buyer_create_preparation(p_decision_id => v_dec, p_title => 'transitions prep');
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
    jsonb_build_object('sub','16000000-0000-0000-0000-000000000002','role','authenticated',
                       'tenant_id','16000000-0000-0000-0000-00000000000a',
                       'organization_id','16000000-0000-0000-0000-00000000002a')::text, true);
  perform set_config('request.jwt.claim.sub', '16000000-0000-0000-0000-000000000002', true);
  set local role authenticated;
  perform contract.supplier_sign_signature_request(v_sr_s);
  reset role;

  -- Create two shipments and walk one through the full chain.
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','16000000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','16000000-0000-0000-0000-00000000000a',
                       'organization_id','16000000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '16000000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_sh_full := shipment.buyer_create_shipment(p_executed_contract_id => v_contract);
  perform shipment.buyer_mark_planned(v_sh_full);
  perform shipment.buyer_mark_booked(v_sh_full);
  perform shipment.buyer_mark_in_transit(v_sh_full);
  perform shipment.buyer_mark_arrived(v_sh_full);
  perform shipment.buyer_mark_delivered(v_sh_full);

  v_sh_cancel := shipment.buyer_create_shipment(p_executed_contract_id => v_contract);
  perform shipment.buyer_cancel_shipment(v_sh_cancel, p_reason => 'oversupply');
  reset role;

  perform set_config('test.sh_full',   v_sh_full::text,   false);
  perform set_config('test.sh_cancel', v_sh_cancel::text, false);
end;
$$;

select plan(6);

-- 1. Full transition chain wrote 6 event rows.
select is(
  (select count(*)::int from shipment.shipment_events
    where shipment_id = current_setting('test.sh_full')::uuid),
  6,
  'full transition chain wrote 6 shipment events (create + 5 marks)'
);

-- 2. Each terminal-direction transition wrote one event row each.
select is(
  (select count(*)::int from shipment.shipment_events
    where shipment_id = current_setting('test.sh_full')::uuid
      and from_status = 'arrived' and to_status = 'delivered'),
  1,
  'arrived → delivered transition wrote exactly one event'
);

-- 3. Direct UPDATE on events row blocked (no grant).
select tests.authenticate_as(
  '16000000-0000-0000-0000-000000000001',
  '16000000-0000-0000-0000-00000000000a',
  '16000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select throws_ok(
  format($$ update shipment.shipment_events set reason = 'tamper'
            where shipment_id = %L::uuid $$, current_setting('test.sh_full')),
  '42501', null,
  'direct UPDATE on shipment_events row is blocked (no grant)'
);

-- 4. Direct DELETE on events row blocked.
select throws_ok(
  format($$ delete from shipment.shipment_events
            where shipment_id = %L::uuid $$, current_setting('test.sh_full')),
  '42501', null,
  'direct DELETE on shipment_events row is blocked (no grant)'
);

-- 5. Cancelled shipment is locked from buyer_update_shipment.
select throws_ok(
  format($$ select shipment.buyer_update_shipment(%L::uuid, p_transport_mode => 'air'::shipment.transport_mode) $$,
         current_setting('test.sh_cancel')),
  'P0001', null,
  'cancelled shipment is locked from buyer_update_shipment (P0001)'
);

-- 6. Cancel from delivered is rejected.
select throws_ok(
  format($$ select shipment.buyer_cancel_shipment(%L::uuid) $$, current_setting('test.sh_full')),
  'P0001', null,
  'cancel from delivered is rejected (P0001)'
);
reset role;

select * from finish();
rollback;
