-- CC-44 Test 127 — Admin summary + activity ledger.
--
-- Assertions (8):
--   1. admin_summary returns a jsonb object
--   2. admin_summary.audience = 'admin'
--   3. admin_summary counts confirmed bookings across the platform
--   4. admin_summary counts active dispatches across the platform
--   5. non-admin denied for admin_summary (42501)
--   6. admin_activity returns rows from the union
--   7. admin_activity rows are ordered by created_at desc
--   8. non-admin denied for admin_activity (42501)

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  notify, marketplace, dispatch, settlement, dispute, tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '44000000-0000-0000-0000-000000000201', 'authenticated', 'authenticated', '127-buyer@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '44000000-0000-0000-0000-000000000202', 'authenticated', 'authenticated', '127-carrier@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '44000000-0000-0000-0000-000000000299', 'authenticated', 'authenticated', '127-admin@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('44000000-0000-0000-0000-00000000020a', 'tenant-127', 'تست', 'Test 127');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status, country_code) values
  ('44000000-0000-0000-0000-00000000021a', '44000000-0000-0000-0000-00000000020a',
   'buy-127', 'خریدار', 'Buyer 127', 'buyer', 'active', 'IR'),
  ('44000000-0000-0000-0000-00000000022a', '44000000-0000-0000-0000-00000000020a',
   'sup-127', 'تأمین', 'Supplier 127', 'supplier', 'active', 'IR'),
  ('44000000-0000-0000-0000-00000000023a', '44000000-0000-0000-0000-00000000020a',
   'carr-127', 'حمل', 'Carrier 127', 'carrier', 'active', 'IR');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('44000000-0000-0000-0000-000000000201', '44000000-0000-0000-0000-00000000020a',
   '44000000-0000-0000-0000-00000000021a', 'Buyer', 'fa', 'active'),
  ('44000000-0000-0000-0000-000000000202', '44000000-0000-0000-0000-00000000020a',
   '44000000-0000-0000-0000-00000000023a', 'Carrier', 'fa', 'active'),
  ('44000000-0000-0000-0000-000000000299', '44000000-0000-0000-0000-00000000020a',
   '44000000-0000-0000-0000-00000000021a', 'Admin', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '44000000-0000-0000-0000-00000000020a', '44000000-0000-0000-0000-00000000021a',
       '44000000-0000-0000-0000-000000000201', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '44000000-0000-0000-0000-000000000201', r.id, 'organization', '44000000-0000-0000-0000-00000000021a'
  from identity.roles r where r.code = 'buyer_admin';

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '44000000-0000-0000-0000-00000000020a', '44000000-0000-0000-0000-00000000023a',
       '44000000-0000-0000-0000-000000000202', r.id, 'active', now()
  from identity.roles r where r.code = 'carrier_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '44000000-0000-0000-0000-000000000202', r.id, 'organization', '44000000-0000-0000-0000-00000000023a'
  from identity.roles r where r.code = 'carrier_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '44000000-0000-0000-0000-000000000299', r.id, 'platform', null
  from identity.roles r where r.code = 'platform_admin';

insert into rfq.requests (id, tenant_id, organization_id, requester_user_id, rfq_code, title, status, visibility, preferred_currency)
values ('44000000-0000-0000-0000-00000000024a', '44000000-0000-0000-0000-00000000020a',
        '44000000-0000-0000-0000-00000000021a', '44000000-0000-0000-0000-000000000201',
        'RFQ-127', 'Stub', 'submitted', 'private_invited', 'USD');
insert into offer.supplier_offers (id, tenant_id, organization_id, request_id, supplier_id, offer_code, currency, status)
values ('44000000-0000-0000-0000-00000000024b', '44000000-0000-0000-0000-00000000020a',
        '44000000-0000-0000-0000-00000000022a', '44000000-0000-0000-0000-00000000024a',
        (select id from supplier.suppliers where organization_id = '44000000-0000-0000-0000-00000000022a'),
        'OF-127', 'USD', 'submitted');
insert into evaluation.offer_decisions (id, tenant_id, organization_id, request_id, offer_id, decision_status)
values ('44000000-0000-0000-0000-00000000024c', '44000000-0000-0000-0000-00000000020a',
        '44000000-0000-0000-0000-00000000021a', '44000000-0000-0000-0000-00000000024a',
        '44000000-0000-0000-0000-00000000024b', 'selected_for_contract');
insert into contract.contract_preparations (id, tenant_id, organization_id, request_id, offer_id, decision_id, supplier_id, preparation_code, title, status)
values ('44000000-0000-0000-0000-00000000024d', '44000000-0000-0000-0000-00000000020a',
        '44000000-0000-0000-0000-00000000021a', '44000000-0000-0000-0000-00000000024a',
        '44000000-0000-0000-0000-00000000024b', '44000000-0000-0000-0000-00000000024c',
        (select id from supplier.suppliers where organization_id = '44000000-0000-0000-0000-00000000022a'),
        'PREP-127', 'Prep', 'ready_for_contract');
insert into contract.executed_contracts (id, tenant_id, organization_id, preparation_id, request_id, offer_id, decision_id, supplier_id, contract_code, status, contract_type, title, currency, executed_at)
values ('44000000-0000-0000-0000-00000000025a', '44000000-0000-0000-0000-00000000020a',
        '44000000-0000-0000-0000-00000000021a', '44000000-0000-0000-0000-00000000024d',
        '44000000-0000-0000-0000-00000000024a', '44000000-0000-0000-0000-00000000024b',
        '44000000-0000-0000-0000-00000000024c',
        (select id from supplier.suppliers where organization_id = '44000000-0000-0000-0000-00000000022a'),
        'CTR-127', 'executed', 'spot', 'CT-127', 'USD', now());
insert into shipment.shipments (id, tenant_id, organization_id, executed_contract_id, request_id, offer_id, supplier_id, shipment_code, status, transport_mode, origin_country, destination_country, planned_pickup_date)
values ('44000000-0000-0000-0000-00000000026a', '44000000-0000-0000-0000-00000000020a',
        '44000000-0000-0000-0000-00000000021a', '44000000-0000-0000-0000-00000000025a',
        '44000000-0000-0000-0000-00000000024a', '44000000-0000-0000-0000-00000000024b',
        (select id from supplier.suppliers where organization_id = '44000000-0000-0000-0000-00000000022a'),
        'SH-127', 'planned', 'road', 'IR', 'DE', now() + interval '7 days');

insert into marketplace.carrier_profiles (tenant_id, organization_id, display_name_fa, status, transport_modes, service_country_codes)
values ('44000000-0000-0000-0000-00000000020a', '44000000-0000-0000-0000-00000000023a',
        'حمل', 'active', array['road'::shipment.transport_mode], array['IR'::citext, 'DE'::citext]);
insert into marketplace.carrier_directory_visibility (carrier_organization_id, tenant_id, is_public, published_at)
values ('44000000-0000-0000-0000-00000000023a', '44000000-0000-0000-0000-00000000020a', true, now());
insert into marketplace.capacity_listings (id, tenant_id, carrier_organization_id, transport_mode, origin_country_code, destination_country_code, valid_from, valid_until, status)
values ('44000000-0000-0000-0000-00000000027a', '44000000-0000-0000-0000-00000000020a',
        '44000000-0000-0000-0000-00000000023a', 'road', 'IR'::citext, 'DE'::citext,
        now() - interval '1 day', now() + interval '30 days', 'active');

-- Run buyer create → carrier accept → buyer confirm → carrier create dispatch.
select set_config('request.jwt.claims',
  jsonb_build_object('sub','44000000-0000-0000-0000-000000000201','role','authenticated',
                     'tenant_id','44000000-0000-0000-0000-00000000020a',
                     'organization_id','44000000-0000-0000-0000-00000000021a')::text, true);
select set_config('request.jwt.claim.sub', '44000000-0000-0000-0000-000000000201', true);
set local role authenticated;

do $$
declare v_b uuid;
begin
  v_b := marketplace.buyer_create_booking_request(
    p_shipment_id => '44000000-0000-0000-0000-00000000026a',
    p_capacity_listing_id => '44000000-0000-0000-0000-00000000027a'
  );
  perform set_config('test.booking_id_127', v_b::text, true);
end $$;

reset role;
select set_config('request.jwt.claims',
  jsonb_build_object('sub','44000000-0000-0000-0000-000000000202','role','authenticated',
                     'tenant_id','44000000-0000-0000-0000-00000000020a',
                     'organization_id','44000000-0000-0000-0000-00000000023a')::text, true);
select set_config('request.jwt.claim.sub', '44000000-0000-0000-0000-000000000202', true);
set local role authenticated;

do $$
begin
  perform marketplace.carrier_accept_booking(current_setting('test.booking_id_127')::uuid, null);
end $$;

reset role;
select set_config('request.jwt.claims',
  jsonb_build_object('sub','44000000-0000-0000-0000-000000000201','role','authenticated',
                     'tenant_id','44000000-0000-0000-0000-00000000020a',
                     'organization_id','44000000-0000-0000-0000-00000000021a')::text, true);
select set_config('request.jwt.claim.sub', '44000000-0000-0000-0000-000000000201', true);
set local role authenticated;

do $$
begin
  perform marketplace.buyer_confirm_booking(current_setting('test.booking_id_127')::uuid);
end $$;

reset role;
select set_config('request.jwt.claims',
  jsonb_build_object('sub','44000000-0000-0000-0000-000000000202','role','authenticated',
                     'tenant_id','44000000-0000-0000-0000-00000000020a',
                     'organization_id','44000000-0000-0000-0000-00000000023a')::text, true);
select set_config('request.jwt.claim.sub', '44000000-0000-0000-0000-000000000202', true);
set local role authenticated;

do $$
begin
  perform dispatch.carrier_create_dispatch(
    p_booking_request_id => current_setting('test.booking_id_127')::uuid,
    p_vehicle_reference => 'V', p_vehicle_type => 'T',
    p_driver_name => 'D', p_driver_phone => '+98'
  );
end $$;

reset role;
-- Switch to admin role.
select set_config('request.jwt.claims',
  jsonb_build_object('sub','44000000-0000-0000-0000-000000000299','role','authenticated',
                     'tenant_id','44000000-0000-0000-0000-00000000020a')::text, true);
select set_config('request.jwt.claim.sub', '44000000-0000-0000-0000-000000000299', true);
set local role authenticated;

select plan(8);

select is(
  jsonb_typeof(public.control_tower_admin_summary()),
  'object', 'admin_summary returns jsonb object');

select is(
  (public.control_tower_admin_summary()->>'audience'),
  'admin', 'admin_summary returns audience=admin');

select is(
  ((public.control_tower_admin_summary()->>'confirmed_bookings')::int),
  1, 'admin_summary counts the buyer-confirmed booking');

select is(
  ((public.control_tower_admin_summary()->>'active_dispatches')::int),
  1, 'admin_summary counts the active dispatch');

-- 5. Non-admin denied.
reset role;
select set_config('request.jwt.claims',
  jsonb_build_object('sub','44000000-0000-0000-0000-000000000201','role','authenticated',
                     'tenant_id','44000000-0000-0000-0000-00000000020a',
                     'organization_id','44000000-0000-0000-0000-00000000021a')::text, true);
select set_config('request.jwt.claim.sub', '44000000-0000-0000-0000-000000000201', true);
set local role authenticated;

select throws_ok(
  $$ select public.control_tower_admin_summary() $$,
  '42501', NULL,
  'non-admin denied for admin_summary');

-- 6. Admin activity returns at least 5 events (booking_requested + accepted +
-- confirmed + dispatch_created + dispatch_assigned = 5).
reset role;
select set_config('request.jwt.claims',
  jsonb_build_object('sub','44000000-0000-0000-0000-000000000299','role','authenticated',
                     'tenant_id','44000000-0000-0000-0000-00000000020a')::text, true);
select set_config('request.jwt.claim.sub', '44000000-0000-0000-0000-000000000299', true);
set local role authenticated;

select ok(
  (select count(*)::int from public.control_tower_admin_activity()) >= 5,
  'admin_activity returns at least 5 events across the lifecycle');

-- 7. Admin activity is ordered by created_at desc.
select ok(
  (
    with rows as (
      select created_at,
             row_number() over (order by created_at desc) as rn,
             row_number() over () as actual_rn
        from public.control_tower_admin_activity()
    )
    select bool_and(rn = actual_rn) from rows
  ),
  'admin_activity rows are ordered by created_at desc');

-- 8. Non-admin denied for admin_activity.
reset role;
select set_config('request.jwt.claims',
  jsonb_build_object('sub','44000000-0000-0000-0000-000000000201','role','authenticated',
                     'tenant_id','44000000-0000-0000-0000-00000000020a',
                     'organization_id','44000000-0000-0000-0000-00000000021a')::text, true);
select set_config('request.jwt.claim.sub', '44000000-0000-0000-0000-000000000201', true);
set local role authenticated;

select throws_ok(
  $$ select * from public.control_tower_admin_activity() $$,
  '42501', NULL,
  'non-admin denied for admin_activity');

reset role;
select * from finish();
rollback;
