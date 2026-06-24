-- CC-43 Test 122 — Dispatch buyer flow.
--
-- Assertions (7):
--   1. buyer_list_my_dispatches returns the buyer's own dispatch
--   2. buyer_get_dispatch returns the dispatch jsonb bundle
--   3. buyer_cancel from non-terminal moves → cancelled
--   4. buyer_cancel event has actor_party = 'buyer'
--   5. buyer_cancel on terminal state raises P0001
--   6. non-owner buyer cannot get another buyer’s dispatch (42501)
--   7. carrier user denied buyer_cancel (42501)

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  notify, marketplace, dispatch, tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '43000000-0000-0000-0000-000000000101', 'authenticated', 'authenticated', '122-buyer@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '43000000-0000-0000-0000-000000000102', 'authenticated', 'authenticated', '122-other-buyer@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '43000000-0000-0000-0000-000000000103', 'authenticated', 'authenticated', '122-carrier@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('43000000-0000-0000-0000-00000000010a', 'tenant-122', 'تست', 'Test 122');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status, country_code) values
  ('43000000-0000-0000-0000-00000000011a', '43000000-0000-0000-0000-00000000010a',
   'buy-122', 'خریدار', 'Buyer 122', 'buyer', 'active', 'IR'),
  ('43000000-0000-0000-0000-00000000011b', '43000000-0000-0000-0000-00000000010a',
   'buy-122b', 'خریدار ب', 'Buyer 122B', 'buyer', 'active', 'IR'),
  ('43000000-0000-0000-0000-00000000012a', '43000000-0000-0000-0000-00000000010a',
   'sup-122', 'تأمین', 'Supplier 122', 'supplier', 'active', 'IR'),
  ('43000000-0000-0000-0000-00000000013a', '43000000-0000-0000-0000-00000000010a',
   'carr-122', 'حمل', 'Carrier 122', 'carrier', 'active', 'IR');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('43000000-0000-0000-0000-000000000101', '43000000-0000-0000-0000-00000000010a',
   '43000000-0000-0000-0000-00000000011a', 'Buyer', 'fa', 'active'),
  ('43000000-0000-0000-0000-000000000102', '43000000-0000-0000-0000-00000000010a',
   '43000000-0000-0000-0000-00000000011b', 'OtherBuyer', 'fa', 'active'),
  ('43000000-0000-0000-0000-000000000103', '43000000-0000-0000-0000-00000000010a',
   '43000000-0000-0000-0000-00000000013a', 'Carrier', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '43000000-0000-0000-0000-00000000010a', '43000000-0000-0000-0000-00000000011a',
       '43000000-0000-0000-0000-000000000101', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '43000000-0000-0000-0000-000000000101', r.id, 'organization', '43000000-0000-0000-0000-00000000011a'
  from identity.roles r where r.code = 'buyer_admin';

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '43000000-0000-0000-0000-00000000010a', '43000000-0000-0000-0000-00000000011b',
       '43000000-0000-0000-0000-000000000102', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '43000000-0000-0000-0000-000000000102', r.id, 'organization', '43000000-0000-0000-0000-00000000011b'
  from identity.roles r where r.code = 'buyer_admin';

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '43000000-0000-0000-0000-00000000010a', '43000000-0000-0000-0000-00000000013a',
       '43000000-0000-0000-0000-000000000103', r.id, 'active', now()
  from identity.roles r where r.code = 'carrier_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '43000000-0000-0000-0000-000000000103', r.id, 'organization', '43000000-0000-0000-0000-00000000013a'
  from identity.roles r where r.code = 'carrier_admin';

-- Shipment chain + booking + dispatch (compressed)
insert into rfq.requests (id, tenant_id, organization_id, requester_user_id, rfq_code, title, status, visibility, preferred_currency)
values ('43000000-0000-0000-0000-00000000014a', '43000000-0000-0000-0000-00000000010a',
        '43000000-0000-0000-0000-00000000011a', '43000000-0000-0000-0000-000000000101',
        'RFQ-122', 'Stub', 'submitted', 'private_invited', 'USD');
insert into offer.supplier_offers (id, tenant_id, organization_id, request_id, supplier_id, offer_code, currency, status)
values ('43000000-0000-0000-0000-00000000014b', '43000000-0000-0000-0000-00000000010a',
        '43000000-0000-0000-0000-00000000012a', '43000000-0000-0000-0000-00000000014a',
        (select id from supplier.suppliers where organization_id = '43000000-0000-0000-0000-00000000012a'),
        'OF-122', 'USD', 'submitted');
insert into evaluation.offer_decisions (id, tenant_id, organization_id, request_id, offer_id, decision_status)
values ('43000000-0000-0000-0000-00000000014c', '43000000-0000-0000-0000-00000000010a',
        '43000000-0000-0000-0000-00000000011a', '43000000-0000-0000-0000-00000000014a',
        '43000000-0000-0000-0000-00000000014b', 'selected_for_contract');
insert into contract.contract_preparations (id, tenant_id, organization_id, request_id, offer_id, decision_id, supplier_id, preparation_code, title, status)
values ('43000000-0000-0000-0000-00000000014d', '43000000-0000-0000-0000-00000000010a',
        '43000000-0000-0000-0000-00000000011a', '43000000-0000-0000-0000-00000000014a',
        '43000000-0000-0000-0000-00000000014b', '43000000-0000-0000-0000-00000000014c',
        (select id from supplier.suppliers where organization_id = '43000000-0000-0000-0000-00000000012a'),
        'PREP-122', 'Prep', 'ready_for_contract');
insert into contract.executed_contracts (id, tenant_id, organization_id, preparation_id, request_id, offer_id, decision_id, supplier_id, contract_code, status, contract_type, title, currency, executed_at)
values ('43000000-0000-0000-0000-00000000015a', '43000000-0000-0000-0000-00000000010a',
        '43000000-0000-0000-0000-00000000011a', '43000000-0000-0000-0000-00000000014d',
        '43000000-0000-0000-0000-00000000014a', '43000000-0000-0000-0000-00000000014b',
        '43000000-0000-0000-0000-00000000014c',
        (select id from supplier.suppliers where organization_id = '43000000-0000-0000-0000-00000000012a'),
        'CTR-122', 'executed', 'spot', 'CT-122', 'USD', now());
insert into shipment.shipments (id, tenant_id, organization_id, executed_contract_id, request_id, offer_id, supplier_id, shipment_code, status, transport_mode, origin_country, destination_country, planned_pickup_date)
values ('43000000-0000-0000-0000-00000000016a', '43000000-0000-0000-0000-00000000010a',
        '43000000-0000-0000-0000-00000000011a', '43000000-0000-0000-0000-00000000015a',
        '43000000-0000-0000-0000-00000000014a', '43000000-0000-0000-0000-00000000014b',
        (select id from supplier.suppliers where organization_id = '43000000-0000-0000-0000-00000000012a'),
        'SH-122', 'planned', 'road', 'IR', 'DE', now() + interval '7 days');

insert into marketplace.carrier_profiles (tenant_id, organization_id, display_name_fa, status, transport_modes, service_country_codes)
values ('43000000-0000-0000-0000-00000000010a', '43000000-0000-0000-0000-00000000013a',
        'حمل', 'active', array['road'::shipment.transport_mode], array['IR'::citext, 'DE'::citext]);
insert into marketplace.carrier_directory_visibility (carrier_organization_id, tenant_id, is_public, published_at)
values ('43000000-0000-0000-0000-00000000013a', '43000000-0000-0000-0000-00000000010a', true, now());
insert into marketplace.capacity_listings (id, tenant_id, carrier_organization_id, transport_mode, origin_country_code, destination_country_code, valid_from, valid_until, status)
values ('43000000-0000-0000-0000-00000000017a', '43000000-0000-0000-0000-00000000010a',
        '43000000-0000-0000-0000-00000000013a', 'road', 'IR'::citext, 'DE'::citext,
        now() - interval '1 day', now() + interval '30 days', 'active');

-- Build booking (buyer → carrier → buyer_confirmed) then create dispatch.
select set_config('request.jwt.claims',
  jsonb_build_object('sub','43000000-0000-0000-0000-000000000101','role','authenticated',
                     'tenant_id','43000000-0000-0000-0000-00000000010a',
                     'organization_id','43000000-0000-0000-0000-00000000011a')::text, true);
select set_config('request.jwt.claim.sub', '43000000-0000-0000-0000-000000000101', true);
set local role authenticated;

do $$
declare v_id uuid;
begin
  v_id := marketplace.buyer_create_booking_request(
    p_shipment_id => '43000000-0000-0000-0000-00000000016a',
    p_capacity_listing_id => '43000000-0000-0000-0000-00000000017a'
  );
  perform set_config('test.booking_id_122', v_id::text, true);
end $$;

reset role;
select set_config('request.jwt.claims',
  jsonb_build_object('sub','43000000-0000-0000-0000-000000000103','role','authenticated',
                     'tenant_id','43000000-0000-0000-0000-00000000010a',
                     'organization_id','43000000-0000-0000-0000-00000000013a')::text, true);
select set_config('request.jwt.claim.sub', '43000000-0000-0000-0000-000000000103', true);
set local role authenticated;

do $$
begin
  perform marketplace.carrier_accept_booking(current_setting('test.booking_id_122')::uuid, null);
end $$;

reset role;
select set_config('request.jwt.claims',
  jsonb_build_object('sub','43000000-0000-0000-0000-000000000101','role','authenticated',
                     'tenant_id','43000000-0000-0000-0000-00000000010a',
                     'organization_id','43000000-0000-0000-0000-00000000011a')::text, true);
select set_config('request.jwt.claim.sub', '43000000-0000-0000-0000-000000000101', true);
set local role authenticated;

do $$
begin
  perform marketplace.buyer_confirm_booking(current_setting('test.booking_id_122')::uuid);
end $$;

reset role;
select set_config('request.jwt.claims',
  jsonb_build_object('sub','43000000-0000-0000-0000-000000000103','role','authenticated',
                     'tenant_id','43000000-0000-0000-0000-00000000010a',
                     'organization_id','43000000-0000-0000-0000-00000000013a')::text, true);
select set_config('request.jwt.claim.sub', '43000000-0000-0000-0000-000000000103', true);
set local role authenticated;

do $$
declare v_id uuid;
begin
  v_id := dispatch.carrier_create_dispatch(
    p_booking_request_id => current_setting('test.booking_id_122')::uuid,
    p_vehicle_reference => 'IR-22-22-A',
    p_vehicle_type => 'truck',
    p_driver_name => 'Driver',
    p_driver_phone => '+989121111111'
  );
  perform set_config('test.dispatch_id_122', v_id::text, true);
end $$;

reset role;
-- Buyer perspective.
select set_config('request.jwt.claims',
  jsonb_build_object('sub','43000000-0000-0000-0000-000000000101','role','authenticated',
                     'tenant_id','43000000-0000-0000-0000-00000000010a',
                     'organization_id','43000000-0000-0000-0000-00000000011a')::text, true);
select set_config('request.jwt.claim.sub', '43000000-0000-0000-0000-000000000101', true);
set local role authenticated;

select plan(7);

-- 1. buyer_list_my_dispatches returns the dispatch.
select is(
  (select count(*)::int from dispatch.buyer_list_my_dispatches()),
  1, 'buyer_list_my_dispatches returns the owned dispatch');

-- 2. buyer_get_dispatch returns jsonb object.
select is(
  jsonb_typeof(dispatch.buyer_get_dispatch(current_setting('test.dispatch_id_122')::uuid)),
  'object', 'buyer_get_dispatch returns jsonb object');

-- 3. buyer_cancel from non-terminal.
do $$
begin
  perform dispatch.buyer_cancel_dispatch(current_setting('test.dispatch_id_122')::uuid, 'changed our mind');
end $$;

select is(
  (select status::text from dispatch.dispatch_assignments
    where id = current_setting('test.dispatch_id_122')::uuid),
  'cancelled', 'buyer_cancel moved dispatch → cancelled');

-- 4. event actor_party = 'buyer'.
select is(
  (select actor_party from dispatch.dispatch_events
    where dispatch_id = current_setting('test.dispatch_id_122')::uuid
      and to_status = 'cancelled' limit 1),
  'buyer', 'buyer_cancel event has actor_party = buyer');

-- 5. re-cancel raises P0001.
select throws_ok(
  'select dispatch.buyer_cancel_dispatch('''
    || current_setting('test.dispatch_id_122')
    || '''::uuid, null)',
  'P0001', NULL,
  'buyer_cancel on terminal state raises P0001');

-- 6. non-owner buyer denied.
reset role;
select set_config('request.jwt.claims',
  jsonb_build_object('sub','43000000-0000-0000-0000-000000000102','role','authenticated',
                     'tenant_id','43000000-0000-0000-0000-00000000010a',
                     'organization_id','43000000-0000-0000-0000-00000000011b')::text, true);
select set_config('request.jwt.claim.sub', '43000000-0000-0000-0000-000000000102', true);
set local role authenticated;

select throws_ok(
  'select dispatch.buyer_get_dispatch('''
    || current_setting('test.dispatch_id_122')
    || '''::uuid)',
  '42501', NULL,
  'non-owner buyer cannot get another buyer’s dispatch');

-- 7. carrier user denied buyer_cancel.
reset role;
select set_config('request.jwt.claims',
  jsonb_build_object('sub','43000000-0000-0000-0000-000000000103','role','authenticated',
                     'tenant_id','43000000-0000-0000-0000-00000000010a',
                     'organization_id','43000000-0000-0000-0000-00000000013a')::text, true);
select set_config('request.jwt.claim.sub', '43000000-0000-0000-0000-000000000103', true);
set local role authenticated;

select throws_ok(
  'select dispatch.buyer_cancel_dispatch('''
    || current_setting('test.dispatch_id_122')
    || '''::uuid, null)',
  '42501', NULL,
  'carrier role cannot call buyer_cancel_dispatch');

reset role;
select * from finish();
rollback;
