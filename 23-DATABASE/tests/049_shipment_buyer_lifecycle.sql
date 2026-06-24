-- CC-14 Test 049 — Buyer shipment lifecycle:
--   create draft from executed contract → items derived → update → stop → milestone →
--   doc requirement → document → mark_planned → mark_booked → mark_in_transit →
--   mark_arrived → mark_delivered → delivered locks normal edit.
--
-- Assertions (13):
--   1. buyer_create_shipment creates shipment with status='draft'
--   2. shipment items derived from executed contract items (count=1)
--   3. buyer_update_shipment patches transport_mode
--   4. buyer_upsert_stop adds a stop with sequence=1
--   5. buyer_upsert_stop is idempotent on sequence (count stays at 1)
--   6. buyer_upsert_milestone adds a milestone
--   7. buyer_upsert_doc_requirement adds requirement
--   8. buyer_upsert_document creates a document
--   9. buyer_mark_planned moves draft → planned
--  10. buyer_mark_booked moves planned → booked
--  11. buyer_mark_in_transit / arrived / delivered chain works
--  12. delivered shipment is locked from buyer_update_shipment (P0001)
--  13. status transitions wrote shipment events (>= 5 events)

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment, tests;
begin;

-- Fixtures: build full chain to executed contract.
insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '14000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '049-buyer@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '14000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', '049-sup@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('14000000-0000-0000-0000-00000000000a', 'tenant-049', 'تست', 'Test');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('14000000-0000-0000-0000-00000000001a', '14000000-0000-0000-0000-00000000000a',
   'buyer-049', 'خریدار', 'Buyer 049', 'buyer', 'active'),
  ('14000000-0000-0000-0000-00000000002a', '14000000-0000-0000-0000-00000000000a',
   'sup-049', 'تأمین', 'Supplier 049', 'supplier', 'active');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('14000000-0000-0000-0000-000000000001', '14000000-0000-0000-0000-00000000000a',
   '14000000-0000-0000-0000-00000000001a', 'Buyer', 'fa', 'active'),
  ('14000000-0000-0000-0000-000000000002', '14000000-0000-0000-0000-00000000000a',
   '14000000-0000-0000-0000-00000000002a', 'Supplier', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '14000000-0000-0000-0000-00000000000a', '14000000-0000-0000-0000-00000000001a',
       '14000000-0000-0000-0000-000000000001', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '14000000-0000-0000-0000-00000000000a', '14000000-0000-0000-0000-00000000002a',
       '14000000-0000-0000-0000-000000000002', r.id, 'active', now()
  from identity.roles r where r.code = 'supplier_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '14000000-0000-0000-0000-000000000001', r.id, 'organization', '14000000-0000-0000-0000-00000000001a'
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '14000000-0000-0000-0000-000000000002', r.id, 'organization', '14000000-0000-0000-0000-00000000002a'
  from identity.roles r where r.code = 'supplier_admin';

-- Chain to executed contract.
do $$
declare
  v_sup uuid; v_prod uuid; v_rfq uuid; v_item uuid; v_off uuid; v_dec uuid;
  v_prep uuid; v_contract uuid; v_p_buyer uuid; v_p_sup uuid;
  v_sr_buyer uuid; v_sr_sup uuid;
begin
  select id into v_sup  from supplier.suppliers where organization_id = '14000000-0000-0000-0000-00000000002a';
  select id into v_prod from commodity.products where code = 'methanol';

  -- Buyer creates RFQ + invites supplier.
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','14000000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','14000000-0000-0000-0000-00000000000a',
                       'organization_id','14000000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '14000000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_rfq := rfq.buyer_create_rfq(p_title => 'R for shipment lifecycle');
  v_item := rfq.buyer_upsert_rfq_item(p_request_id => v_rfq, p_product_id => v_prod,
                                       p_quantity => 1000, p_quantity_unit => 'ton');
  perform rfq.buyer_submit_rfq(v_rfq);
  perform rfq.buyer_invite_suppliers(v_rfq, array[v_sup]);
  reset role;

  -- Supplier offers.
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','14000000-0000-0000-0000-000000000002','role','authenticated',
                       'tenant_id','14000000-0000-0000-0000-00000000000a',
                       'organization_id','14000000-0000-0000-0000-00000000002a')::text, true);
  perform set_config('request.jwt.claim.sub', '14000000-0000-0000-0000-000000000002', true);
  set local role authenticated;
  v_off := offer.supplier_create_draft_offer(p_request_id => v_rfq);
  perform offer.supplier_upsert_offer_item(p_offer_id => v_off, p_request_item_id => v_item,
    p_offered_quantity => 1000, p_quantity_unit => 'ton', p_unit_price => 380, p_currency => 'USD',
    p_packaging => 'IBC');
  perform offer.supplier_submit_my_offer(v_off);
  reset role;

  -- Buyer selects → preparation → ready → executed contract.
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','14000000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','14000000-0000-0000-0000-00000000000a',
                       'organization_id','14000000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '14000000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_dec := evaluation.buyer_select_for_contract(p_offer_id => v_off);
  v_prep := contract.buyer_create_preparation(p_decision_id => v_dec, p_title => 'shipment prep');
  perform contract.buyer_mark_ready_for_contract(v_prep);
  v_contract := contract.buyer_create_executed_contract(p_preparation_id => v_prep);

  select id into v_p_buyer from contract.contract_parties
   where contract_id = v_contract and party_type = 'buyer' and deleted_at is null limit 1;
  select id into v_p_sup from contract.contract_parties
   where contract_id = v_contract and party_type = 'supplier' and deleted_at is null limit 1;

  v_sr_buyer := contract.buyer_create_signature_request(p_contract_id => v_contract, p_party_id => v_p_buyer);
  v_sr_sup   := contract.buyer_create_signature_request(p_contract_id => v_contract, p_party_id => v_p_sup);
  perform contract.buyer_mark_pending_signatures(v_contract);
  perform contract.buyer_sign_signature_request(v_sr_buyer);
  reset role;

  -- Supplier signs to push contract to executed.
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','14000000-0000-0000-0000-000000000002','role','authenticated',
                       'tenant_id','14000000-0000-0000-0000-00000000000a',
                       'organization_id','14000000-0000-0000-0000-00000000002a')::text, true);
  perform set_config('request.jwt.claim.sub', '14000000-0000-0000-0000-000000000002', true);
  set local role authenticated;
  perform contract.supplier_sign_signature_request(v_sr_sup);
  reset role;

  perform set_config('test.contract', v_contract::text, false);
end;
$$;

select plan(13);

-- 1. Buyer creates draft shipment.
select tests.authenticate_as(
  '14000000-0000-0000-0000-000000000001',
  '14000000-0000-0000-0000-00000000000a',
  '14000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
do $$
declare v_sh uuid;
begin
  v_sh := shipment.buyer_create_shipment(
    p_executed_contract_id => current_setting('test.contract')::uuid,
    p_transport_mode => 'road'::shipment.transport_mode,
    p_origin_country => 'IR', p_destination_country => 'TR'
  );
  perform set_config('test.shipment', v_sh::text, false);
end;
$$;
reset role;

select is(
  (select status::text from shipment.shipments where id = current_setting('test.shipment')::uuid),
  'draft',
  'buyer_create_shipment creates shipment with status=draft'
);

-- 2. Items derived.
select is(
  (select count(*)::int from shipment.shipment_items
    where shipment_id = current_setting('test.shipment')::uuid and deleted_at is null),
  1,
  'shipment items derived from executed contract items (count=1)'
);

-- 3. Update.
select tests.authenticate_as(
  '14000000-0000-0000-0000-000000000001',
  '14000000-0000-0000-0000-00000000000a',
  '14000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select shipment.buyer_update_shipment(
  p_shipment_id  => current_setting('test.shipment')::uuid,
  p_transport_mode => 'multimodal'::shipment.transport_mode
);
reset role;

select is(
  (select transport_mode::text from shipment.shipments
    where id = current_setting('test.shipment')::uuid),
  'multimodal',
  'buyer_update_shipment patches transport_mode'
);

-- 4. Upsert stop.
select tests.authenticate_as(
  '14000000-0000-0000-0000-000000000001',
  '14000000-0000-0000-0000-00000000000a',
  '14000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select shipment.buyer_upsert_stop(
  p_shipment_id     => current_setting('test.shipment')::uuid,
  p_sequence_number => 1,
  p_stop_type       => 'pickup'::shipment.stop_type,
  p_city            => 'Tehran'
);
reset role;

select is(
  (select count(*)::int from shipment.shipment_stops
    where shipment_id = current_setting('test.shipment')::uuid and deleted_at is null),
  1,
  'buyer_upsert_stop adds a stop with sequence=1'
);

-- 5. Upsert same sequence — count stays at 1.
select tests.authenticate_as(
  '14000000-0000-0000-0000-000000000001',
  '14000000-0000-0000-0000-00000000000a',
  '14000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select shipment.buyer_upsert_stop(
  p_shipment_id     => current_setting('test.shipment')::uuid,
  p_sequence_number => 1,
  p_stop_type       => 'loading'::shipment.stop_type,
  p_city            => 'Tehran (updated)'
);
reset role;

select is(
  (select count(*)::int from shipment.shipment_stops
    where shipment_id = current_setting('test.shipment')::uuid and deleted_at is null),
  1,
  'buyer_upsert_stop is idempotent on sequence (count stays at 1)'
);

-- 6. Milestone.
select tests.authenticate_as(
  '14000000-0000-0000-0000-000000000001',
  '14000000-0000-0000-0000-00000000000a',
  '14000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select shipment.buyer_upsert_milestone(
  p_shipment_id    => current_setting('test.shipment')::uuid,
  p_milestone_type => 'booking_confirmed'::shipment.milestone_type,
  p_status         => 'pending'::shipment.milestone_status
);
reset role;

select is(
  (select count(*)::int from shipment.shipment_milestones
    where shipment_id = current_setting('test.shipment')::uuid and deleted_at is null),
  1,
  'buyer_upsert_milestone adds a milestone'
);

-- 7. Document requirement.
select tests.authenticate_as(
  '14000000-0000-0000-0000-000000000001',
  '14000000-0000-0000-0000-00000000000a',
  '14000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
do $$
declare v_req uuid;
begin
  v_req := shipment.buyer_upsert_doc_requirement(
    p_shipment_id => current_setting('test.shipment')::uuid,
    p_document_kind => 'bill_of_lading'::shipment.document_kind,
    p_requirement_level => 'required'::shipment.requirement_level,
    p_display_name_en => 'Bill of Lading'
  );
  perform set_config('test.requirement', v_req::text, false);
end;
$$;
reset role;

select is(
  (select count(*)::int from shipment.shipment_document_requirements
    where shipment_id = current_setting('test.shipment')::uuid and deleted_at is null),
  1,
  'buyer_upsert_doc_requirement adds requirement'
);

-- 8. Document.
select tests.authenticate_as(
  '14000000-0000-0000-0000-000000000001',
  '14000000-0000-0000-0000-00000000000a',
  '14000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
do $$
declare v_doc uuid;
begin
  v_doc := shipment.buyer_upsert_document(
    p_shipment_id => current_setting('test.shipment')::uuid,
    p_document_kind => 'bill_of_lading'::shipment.document_kind,
    p_document_status => 'pending'::shipment.document_status,
    p_requirement_id => current_setting('test.requirement')::uuid,
    p_external_reference => 'BL-12345'
  );
  perform set_config('test.document', v_doc::text, false);
end;
$$;
reset role;

select is(
  (select count(*)::int from shipment.shipment_documents
    where shipment_id = current_setting('test.shipment')::uuid and deleted_at is null),
  1,
  'buyer_upsert_document creates a document'
);

-- 9. Mark planned.
select tests.authenticate_as(
  '14000000-0000-0000-0000-000000000001',
  '14000000-0000-0000-0000-00000000000a',
  '14000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select shipment.buyer_mark_planned(current_setting('test.shipment')::uuid);
reset role;

select is(
  (select status::text from shipment.shipments
    where id = current_setting('test.shipment')::uuid),
  'planned',
  'buyer_mark_planned moves draft → planned'
);

-- 10. Mark booked.
select tests.authenticate_as(
  '14000000-0000-0000-0000-000000000001',
  '14000000-0000-0000-0000-00000000000a',
  '14000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select shipment.buyer_mark_booked(
  current_setting('test.shipment')::uuid,
  p_carrier_name => 'Acme Logistics',
  p_vehicle_reference => 'TRK-9001'
);
reset role;

select is(
  (select status::text from shipment.shipments
    where id = current_setting('test.shipment')::uuid),
  'booked',
  'buyer_mark_booked moves planned → booked'
);

-- 11. In-transit → arrived → delivered chain.
select tests.authenticate_as(
  '14000000-0000-0000-0000-000000000001',
  '14000000-0000-0000-0000-00000000000a',
  '14000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select shipment.buyer_mark_in_transit(current_setting('test.shipment')::uuid);
select shipment.buyer_mark_arrived(current_setting('test.shipment')::uuid);
select shipment.buyer_mark_delivered(current_setting('test.shipment')::uuid);
reset role;

select is(
  (select status::text from shipment.shipments
    where id = current_setting('test.shipment')::uuid),
  'delivered',
  'in_transit → arrived → delivered chain reaches delivered'
);

-- 12. Delivered is locked.
select tests.authenticate_as(
  '14000000-0000-0000-0000-000000000001',
  '14000000-0000-0000-0000-00000000000a',
  '14000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select throws_ok(
  format($$ select shipment.buyer_update_shipment(%L::uuid, p_transport_mode => 'air'::shipment.transport_mode) $$,
         current_setting('test.shipment')),
  'P0001', null,
  'delivered shipment is locked from buyer_update_shipment (P0001)'
);
reset role;

-- 13. Status transitions wrote events.
select cmp_ok(
  (select count(*)::int from shipment.shipment_events
    where shipment_id = current_setting('test.shipment')::uuid),
  '>=', 5,
  'status transitions wrote shipment events (>= 5: create, planned, booked, in_transit, arrived, delivered)'
);

select * from finish();
rollback;
