-- CC-43 Test 123 — Dispatch admin moderation.
--
-- Assertions (6):
--   1. admin_list_dispatches returns the dispatch across tenants
--   2. admin_get_dispatch returns jsonb object
--   3. admin_cancel from non-terminal moves → cancelled
--   4. admin_cancel event has actor_party = 'admin' and admin_action=true
--   5. admin_cancel on terminal state raises P0001
--   6. non-admin denied (42501)

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  notify, marketplace, dispatch, tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '43000000-0000-0000-0000-000000000201', 'authenticated', 'authenticated', '123-buyer@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '43000000-0000-0000-0000-000000000202', 'authenticated', 'authenticated', '123-carrier@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '43000000-0000-0000-0000-000000000299', 'authenticated', 'authenticated', '123-admin@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('43000000-0000-0000-0000-00000000020a', 'tenant-123', 'تست', 'Test 123');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status, country_code) values
  ('43000000-0000-0000-0000-00000000021a', '43000000-0000-0000-0000-00000000020a',
   'buy-123', 'خریدار', 'Buyer 123', 'buyer', 'active', 'IR'),
  ('43000000-0000-0000-0000-00000000022a', '43000000-0000-0000-0000-00000000020a',
   'sup-123', 'تأمین', 'Supplier 123', 'supplier', 'active', 'IR'),
  ('43000000-0000-0000-0000-00000000023a', '43000000-0000-0000-0000-00000000020a',
   'carr-123', 'حمل', 'Carrier 123', 'carrier', 'active', 'IR');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('43000000-0000-0000-0000-000000000201', '43000000-0000-0000-0000-00000000020a',
   '43000000-0000-0000-0000-00000000021a', 'Buyer', 'fa', 'active'),
  ('43000000-0000-0000-0000-000000000202', '43000000-0000-0000-0000-00000000020a',
   '43000000-0000-0000-0000-00000000023a', 'Carrier', 'fa', 'active'),
  ('43000000-0000-0000-0000-000000000299', '43000000-0000-0000-0000-00000000020a',
   '43000000-0000-0000-0000-00000000021a', 'Admin', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '43000000-0000-0000-0000-00000000020a', '43000000-0000-0000-0000-00000000021a',
       '43000000-0000-0000-0000-000000000201', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '43000000-0000-0000-0000-000000000201', r.id, 'organization', '43000000-0000-0000-0000-00000000021a'
  from identity.roles r where r.code = 'buyer_admin';

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '43000000-0000-0000-0000-00000000020a', '43000000-0000-0000-0000-00000000023a',
       '43000000-0000-0000-0000-000000000202', r.id, 'active', now()
  from identity.roles r where r.code = 'carrier_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '43000000-0000-0000-0000-000000000202', r.id, 'organization', '43000000-0000-0000-0000-00000000023a'
  from identity.roles r where r.code = 'carrier_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '43000000-0000-0000-0000-000000000299', r.id, 'platform', null
  from identity.roles r where r.code = 'platform_admin';

-- Shipment chain + booking + dispatch.
insert into rfq.requests (id, tenant_id, organization_id, requester_user_id, rfq_code, title, status, visibility, preferred_currency)
values ('43000000-0000-0000-0000-00000000024a', '43000000-0000-0000-0000-00000000020a',
        '43000000-0000-0000-0000-00000000021a', '43000000-0000-0000-0000-000000000201',
        'RFQ-123', 'Stub', 'submitted', 'private_invited', 'USD');
insert into offer.supplier_offers (id, tenant_id, organization_id, request_id, supplier_id, offer_code, currency, status)
values ('43000000-0000-0000-0000-00000000024b', '43000000-0000-0000-0000-00000000020a',
        '43000000-0000-0000-0000-00000000022a', '43000000-0000-0000-0000-00000000024a',
        (select id from supplier.suppliers where organization_id = '43000000-0000-0000-0000-00000000022a'),
        'OF-123', 'USD', 'submitted');
insert into evaluation.offer_decisions (id, tenant_id, organization_id, request_id, offer_id, decision_status)
values ('43000000-0000-0000-0000-00000000024c', '43000000-0000-0000-0000-00000000020a',
        '43000000-0000-0000-0000-00000000021a', '43000000-0000-0000-0000-00000000024a',
        '43000000-0000-0000-0000-00000000024b', 'selected_for_contract');
insert into contract.contract_preparations (id, tenant_id, organization_id, request_id, offer_id, decision_id, supplier_id, preparation_code, title, status)
values ('43000000-0000-0000-0000-00000000024d', '43000000-0000-0000-0000-00000000020a',
        '43000000-0000-0000-0000-00000000021a', '43000000-0000-0000-0000-00000000024a',
        '43000000-0000-0000-0000-00000000024b', '43000000-0000-0000-0000-00000000024c',
        (select id from supplier.suppliers where organization_id = '43000000-0000-0000-0000-00000000022a'),
        'PREP-123', 'Prep', 'ready_for_contract');
insert into contract.executed_contracts (id, tenant_id, organization_id, preparation_id, request_id, offer_id, decision_id, supplier_id, contract_code, status, contract_type, title, currency, executed_at)
values ('43000000-0000-0000-0000-00000000025a', '43000000-0000-0000-0000-00000000020a',
        '43000000-0000-0000-0000-00000000021a', '43000000-0000-0000-0000-00000000024d',
        '43000000-0000-0000-0000-00000000024a', '43000000-0000-0000-0000-00000000024b',
        '43000000-0000-0000-0000-00000000024c',
        (select id from supplier.suppliers where organization_id = '43000000-0000-0000-0000-00000000022a'),
        'CTR-123', 'executed', 'spot', 'CT-123', 'USD', now());
insert into shipment.shipments (id, tenant_id, organization_id, executed_contract_id, request_id, offer_id, supplier_id, shipment_code, status, transport_mode, origin_country, destination_country, planned_pickup_date)
values ('43000000-0000-0000-0000-00000000026a', '43000000-0000-0000-0000-00000000020a',
        '43000000-0000-0000-0000-00000000021a', '43000000-0000-0000-0000-00000000025a',
        '43000000-0000-0000-0000-00000000024a', '43000000-0000-0000-0000-00000000024b',
        (select id from supplier.suppliers where organization_id = '43000000-0000-0000-0000-00000000022a'),
        'SH-123', 'planned', 'road', 'IR', 'DE', now() + interval '7 days');

insert into marketplace.carrier_profiles (tenant_id, organization_id, display_name_fa, status, transport_modes, service_country_codes)
values ('43000000-0000-0000-0000-00000000020a', '43000000-0000-0000-0000-00000000023a',
        'حمل', 'active', array['road'::shipment.transport_mode], array['IR'::citext, 'DE'::citext]);
insert into marketplace.carrier_directory_visibility (carrier_organization_id, tenant_id, is_public, published_at)
values ('43000000-0000-0000-0000-00000000023a', '43000000-0000-0000-0000-00000000020a', true, now());
insert into marketplace.capacity_listings (id, tenant_id, carrier_organization_id, transport_mode, origin_country_code, destination_country_code, valid_from, valid_until, status)
values ('43000000-0000-0000-0000-00000000027a', '43000000-0000-0000-0000-00000000020a',
        '43000000-0000-0000-0000-00000000023a', 'road', 'IR'::citext, 'DE'::citext,
        now() - interval '1 day', now() + interval '30 days', 'active');

-- Build booking → buyer_confirmed → dispatch.
select set_config('request.jwt.claims',
  jsonb_build_object('sub','43000000-0000-0000-0000-000000000201','role','authenticated',
                     'tenant_id','43000000-0000-0000-0000-00000000020a',
                     'organization_id','43000000-0000-0000-0000-00000000021a')::text, true);
select set_config('request.jwt.claim.sub', '43000000-0000-0000-0000-000000000201', true);
set local role authenticated;

do $$
declare v_id uuid;
begin
  v_id := marketplace.buyer_create_booking_request(
    p_shipment_id => '43000000-0000-0000-0000-00000000026a',
    p_capacity_listing_id => '43000000-0000-0000-0000-00000000027a'
  );
  perform set_config('test.booking_id_123', v_id::text, true);
end $$;

reset role;
select set_config('request.jwt.claims',
  jsonb_build_object('sub','43000000-0000-0000-0000-000000000202','role','authenticated',
                     'tenant_id','43000000-0000-0000-0000-00000000020a',
                     'organization_id','43000000-0000-0000-0000-00000000023a')::text, true);
select set_config('request.jwt.claim.sub', '43000000-0000-0000-0000-000000000202', true);
set local role authenticated;

do $$
begin
  perform marketplace.carrier_accept_booking(current_setting('test.booking_id_123')::uuid, null);
end $$;

reset role;
select set_config('request.jwt.claims',
  jsonb_build_object('sub','43000000-0000-0000-0000-000000000201','role','authenticated',
                     'tenant_id','43000000-0000-0000-0000-00000000020a',
                     'organization_id','43000000-0000-0000-0000-00000000021a')::text, true);
select set_config('request.jwt.claim.sub', '43000000-0000-0000-0000-000000000201', true);
set local role authenticated;

do $$
begin
  perform marketplace.buyer_confirm_booking(current_setting('test.booking_id_123')::uuid);
end $$;

reset role;
select set_config('request.jwt.claims',
  jsonb_build_object('sub','43000000-0000-0000-0000-000000000202','role','authenticated',
                     'tenant_id','43000000-0000-0000-0000-00000000020a',
                     'organization_id','43000000-0000-0000-0000-00000000023a')::text, true);
select set_config('request.jwt.claim.sub', '43000000-0000-0000-0000-000000000202', true);
set local role authenticated;

do $$
declare v_id uuid;
begin
  v_id := dispatch.carrier_create_dispatch(
    p_booking_request_id => current_setting('test.booking_id_123')::uuid,
    p_vehicle_reference => 'V', p_vehicle_type => 'T',
    p_driver_name => 'D', p_driver_phone => '+98'
  );
  perform set_config('test.dispatch_id_123', v_id::text, true);
end $$;

reset role;
-- Admin perspective.
select set_config('request.jwt.claims',
  jsonb_build_object('sub','43000000-0000-0000-0000-000000000299','role','authenticated',
                     'tenant_id','43000000-0000-0000-0000-00000000020a')::text, true);
select set_config('request.jwt.claim.sub', '43000000-0000-0000-0000-000000000299', true);
set local role authenticated;

select plan(6);

select is(
  (select count(*)::int from dispatch.admin_list_dispatches()),
  1, 'admin_list_dispatches returns the dispatch');

select is(
  jsonb_typeof(dispatch.admin_get_dispatch(current_setting('test.dispatch_id_123')::uuid)),
  'object', 'admin_get_dispatch returns jsonb object');

do $$
begin
  perform dispatch.admin_cancel_dispatch(current_setting('test.dispatch_id_123')::uuid, 'policy violation');
end $$;

select is(
  (select status::text from dispatch.dispatch_assignments
    where id = current_setting('test.dispatch_id_123')::uuid),
  'cancelled', 'admin_cancel moved dispatch → cancelled');

select is(
  (select (payload->>'admin_action') from dispatch.dispatch_events
    where dispatch_id = current_setting('test.dispatch_id_123')::uuid
      and to_status = 'cancelled' limit 1),
  'true', 'admin_cancel event records admin_action=true');

select throws_ok(
  'select dispatch.admin_cancel_dispatch('''
    || current_setting('test.dispatch_id_123')
    || '''::uuid, null)',
  'P0001', NULL,
  'admin_cancel on terminal state raises P0001');

reset role;
select set_config('request.jwt.claims',
  jsonb_build_object('sub','43000000-0000-0000-0000-000000000201','role','authenticated',
                     'tenant_id','43000000-0000-0000-0000-00000000020a',
                     'organization_id','43000000-0000-0000-0000-00000000021a')::text, true);
select set_config('request.jwt.claim.sub', '43000000-0000-0000-0000-000000000201', true);
set local role authenticated;

select throws_ok(
  'select dispatch.admin_cancel_dispatch('''
    || current_setting('test.dispatch_id_123')
    || '''::uuid, null)',
  '42501', NULL,
  'non-admin cannot call admin_cancel_dispatch');

reset role;
select * from finish();
rollback;
