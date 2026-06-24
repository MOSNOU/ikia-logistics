-- CC-43 Test 124 — Dispatch event ledger integrity (Q9 immutability).
--
-- Assertions (6):
--   1. After carrier_create_dispatch (complete placeholders) + mark_ready +
--      release, the ledger has exactly 4 events
--   2. Direct INSERT into dispatch_events as authenticated is denied
--   3. UPDATE on dispatch_events is denied
--   4. DELETE on dispatch_events is denied
--   5. RLS lets the carrier SELECT the events
--   6. RLS lets the buyer SELECT the events

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  notify, marketplace, dispatch, tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '43000000-0000-0000-0000-000000000301', 'authenticated', 'authenticated', '124-buyer@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '43000000-0000-0000-0000-000000000302', 'authenticated', 'authenticated', '124-carrier@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('43000000-0000-0000-0000-00000000030a', 'tenant-124', 'تست', 'Test 124');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status, country_code) values
  ('43000000-0000-0000-0000-00000000031a', '43000000-0000-0000-0000-00000000030a',
   'buy-124', 'خریدار', 'Buyer 124', 'buyer', 'active', 'IR'),
  ('43000000-0000-0000-0000-00000000032a', '43000000-0000-0000-0000-00000000030a',
   'sup-124', 'تأمین', 'Supplier 124', 'supplier', 'active', 'IR'),
  ('43000000-0000-0000-0000-00000000033a', '43000000-0000-0000-0000-00000000030a',
   'carr-124', 'حمل', 'Carrier 124', 'carrier', 'active', 'IR');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('43000000-0000-0000-0000-000000000301', '43000000-0000-0000-0000-00000000030a',
   '43000000-0000-0000-0000-00000000031a', 'Buyer', 'fa', 'active'),
  ('43000000-0000-0000-0000-000000000302', '43000000-0000-0000-0000-00000000030a',
   '43000000-0000-0000-0000-00000000033a', 'Carrier', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '43000000-0000-0000-0000-00000000030a', '43000000-0000-0000-0000-00000000031a',
       '43000000-0000-0000-0000-000000000301', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '43000000-0000-0000-0000-000000000301', r.id, 'organization', '43000000-0000-0000-0000-00000000031a'
  from identity.roles r where r.code = 'buyer_admin';

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '43000000-0000-0000-0000-00000000030a', '43000000-0000-0000-0000-00000000033a',
       '43000000-0000-0000-0000-000000000302', r.id, 'active', now()
  from identity.roles r where r.code = 'carrier_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '43000000-0000-0000-0000-000000000302', r.id, 'organization', '43000000-0000-0000-0000-00000000033a'
  from identity.roles r where r.code = 'carrier_admin';

insert into rfq.requests (id, tenant_id, organization_id, requester_user_id, rfq_code, title, status, visibility, preferred_currency)
values ('43000000-0000-0000-0000-00000000034a', '43000000-0000-0000-0000-00000000030a',
        '43000000-0000-0000-0000-00000000031a', '43000000-0000-0000-0000-000000000301',
        'RFQ-124', 'Stub', 'submitted', 'private_invited', 'USD');
insert into offer.supplier_offers (id, tenant_id, organization_id, request_id, supplier_id, offer_code, currency, status)
values ('43000000-0000-0000-0000-00000000034b', '43000000-0000-0000-0000-00000000030a',
        '43000000-0000-0000-0000-00000000032a', '43000000-0000-0000-0000-00000000034a',
        (select id from supplier.suppliers where organization_id = '43000000-0000-0000-0000-00000000032a'),
        'OF-124', 'USD', 'submitted');
insert into evaluation.offer_decisions (id, tenant_id, organization_id, request_id, offer_id, decision_status)
values ('43000000-0000-0000-0000-00000000034c', '43000000-0000-0000-0000-00000000030a',
        '43000000-0000-0000-0000-00000000031a', '43000000-0000-0000-0000-00000000034a',
        '43000000-0000-0000-0000-00000000034b', 'selected_for_contract');
insert into contract.contract_preparations (id, tenant_id, organization_id, request_id, offer_id, decision_id, supplier_id, preparation_code, title, status)
values ('43000000-0000-0000-0000-00000000034d', '43000000-0000-0000-0000-00000000030a',
        '43000000-0000-0000-0000-00000000031a', '43000000-0000-0000-0000-00000000034a',
        '43000000-0000-0000-0000-00000000034b', '43000000-0000-0000-0000-00000000034c',
        (select id from supplier.suppliers where organization_id = '43000000-0000-0000-0000-00000000032a'),
        'PREP-124', 'Prep', 'ready_for_contract');
insert into contract.executed_contracts (id, tenant_id, organization_id, preparation_id, request_id, offer_id, decision_id, supplier_id, contract_code, status, contract_type, title, currency, executed_at)
values ('43000000-0000-0000-0000-00000000035a', '43000000-0000-0000-0000-00000000030a',
        '43000000-0000-0000-0000-00000000031a', '43000000-0000-0000-0000-00000000034d',
        '43000000-0000-0000-0000-00000000034a', '43000000-0000-0000-0000-00000000034b',
        '43000000-0000-0000-0000-00000000034c',
        (select id from supplier.suppliers where organization_id = '43000000-0000-0000-0000-00000000032a'),
        'CTR-124', 'executed', 'spot', 'CT-124', 'USD', now());
insert into shipment.shipments (id, tenant_id, organization_id, executed_contract_id, request_id, offer_id, supplier_id, shipment_code, status, transport_mode, origin_country, destination_country, planned_pickup_date)
values ('43000000-0000-0000-0000-00000000036a', '43000000-0000-0000-0000-00000000030a',
        '43000000-0000-0000-0000-00000000031a', '43000000-0000-0000-0000-00000000035a',
        '43000000-0000-0000-0000-00000000034a', '43000000-0000-0000-0000-00000000034b',
        (select id from supplier.suppliers where organization_id = '43000000-0000-0000-0000-00000000032a'),
        'SH-124', 'planned', 'road', 'IR', 'DE', now() + interval '7 days');

insert into marketplace.carrier_profiles (tenant_id, organization_id, display_name_fa, status, transport_modes, service_country_codes)
values ('43000000-0000-0000-0000-00000000030a', '43000000-0000-0000-0000-00000000033a',
        'حمل', 'active', array['road'::shipment.transport_mode], array['IR'::citext, 'DE'::citext]);
insert into marketplace.carrier_directory_visibility (carrier_organization_id, tenant_id, is_public, published_at)
values ('43000000-0000-0000-0000-00000000033a', '43000000-0000-0000-0000-00000000030a', true, now());
insert into marketplace.capacity_listings (id, tenant_id, carrier_organization_id, transport_mode, origin_country_code, destination_country_code, valid_from, valid_until, status)
values ('43000000-0000-0000-0000-00000000037a', '43000000-0000-0000-0000-00000000030a',
        '43000000-0000-0000-0000-00000000033a', 'road', 'IR'::citext, 'DE'::citext,
        now() - interval '1 day', now() + interval '30 days', 'active');

select set_config('request.jwt.claims',
  jsonb_build_object('sub','43000000-0000-0000-0000-000000000301','role','authenticated',
                     'tenant_id','43000000-0000-0000-0000-00000000030a',
                     'organization_id','43000000-0000-0000-0000-00000000031a')::text, true);
select set_config('request.jwt.claim.sub', '43000000-0000-0000-0000-000000000301', true);
set local role authenticated;

do $$
declare v_id uuid;
begin
  v_id := marketplace.buyer_create_booking_request(
    p_shipment_id => '43000000-0000-0000-0000-00000000036a',
    p_capacity_listing_id => '43000000-0000-0000-0000-00000000037a'
  );
  perform set_config('test.booking_id_124', v_id::text, true);
end $$;

reset role;
select set_config('request.jwt.claims',
  jsonb_build_object('sub','43000000-0000-0000-0000-000000000302','role','authenticated',
                     'tenant_id','43000000-0000-0000-0000-00000000030a',
                     'organization_id','43000000-0000-0000-0000-00000000033a')::text, true);
select set_config('request.jwt.claim.sub', '43000000-0000-0000-0000-000000000302', true);
set local role authenticated;

do $$
begin
  perform marketplace.carrier_accept_booking(current_setting('test.booking_id_124')::uuid, null);
end $$;

reset role;
select set_config('request.jwt.claims',
  jsonb_build_object('sub','43000000-0000-0000-0000-000000000301','role','authenticated',
                     'tenant_id','43000000-0000-0000-0000-00000000030a',
                     'organization_id','43000000-0000-0000-0000-00000000031a')::text, true);
select set_config('request.jwt.claim.sub', '43000000-0000-0000-0000-000000000301', true);
set local role authenticated;

do $$
begin
  perform marketplace.buyer_confirm_booking(current_setting('test.booking_id_124')::uuid);
end $$;

reset role;
select set_config('request.jwt.claims',
  jsonb_build_object('sub','43000000-0000-0000-0000-000000000302','role','authenticated',
                     'tenant_id','43000000-0000-0000-0000-00000000030a',
                     'organization_id','43000000-0000-0000-0000-00000000033a')::text, true);
select set_config('request.jwt.claim.sub', '43000000-0000-0000-0000-000000000302', true);
set local role authenticated;

-- Full lifecycle: create (complete) → mark_ready → release.
do $$
declare v_id uuid;
begin
  v_id := dispatch.carrier_create_dispatch(
    p_booking_request_id => current_setting('test.booking_id_124')::uuid,
    p_vehicle_reference => 'V', p_vehicle_type => 'T',
    p_driver_name => 'D', p_driver_phone => '+98'
  );
  perform dispatch.carrier_mark_ready(v_id);
  perform dispatch.carrier_release_dispatch(v_id, null);
  perform set_config('test.dispatch_id_124', v_id::text, true);
end $$;

select plan(6);

-- 1. Four events total: created + assigned (from create with full placeholders)
-- + ready + released.
select is(
  (select count(*)::int from dispatch.dispatch_events
    where dispatch_id = current_setting('test.dispatch_id_124')::uuid),
  4, 'four events recorded across the create→ready→release lifecycle');

-- 2. Direct INSERT denied.
select throws_ok(
  'insert into dispatch.dispatch_events (tenant_id, dispatch_id, to_status, event_type, actor_party) '
  || 'select tenant_id, id, ''cancelled''::dispatch.dispatch_status, ''spoof'', ''system'' '
  || 'from dispatch.dispatch_assignments where id = '''
  || current_setting('test.dispatch_id_124')
  || '''::uuid',
  '42501', NULL,
  'direct INSERT into dispatch_events is denied');

-- 3. UPDATE denied.
select throws_ok(
  'update dispatch.dispatch_events set reason = ''tamper'' '
  || 'where dispatch_id = '''
  || current_setting('test.dispatch_id_124')
  || '''::uuid',
  '42501', NULL,
  'UPDATE on dispatch_events is denied');

-- 4. DELETE denied.
select throws_ok(
  'delete from dispatch.dispatch_events where dispatch_id = '''
  || current_setting('test.dispatch_id_124')
  || '''::uuid',
  '42501', NULL,
  'DELETE on dispatch_events is denied');

-- 5. Carrier SELECT under RLS.
select is(
  (select count(*)::int from dispatch.dispatch_events
    where dispatch_id = current_setting('test.dispatch_id_124')::uuid),
  4, 'carrier can SELECT all 4 events under RLS');

-- 6. Buyer SELECT under RLS.
reset role;
select set_config('request.jwt.claims',
  jsonb_build_object('sub','43000000-0000-0000-0000-000000000301','role','authenticated',
                     'tenant_id','43000000-0000-0000-0000-00000000030a',
                     'organization_id','43000000-0000-0000-0000-00000000031a')::text, true);
select set_config('request.jwt.claim.sub', '43000000-0000-0000-0000-000000000301', true);
set local role authenticated;

select is(
  (select count(*)::int from dispatch.dispatch_events
    where dispatch_id = current_setting('test.dispatch_id_124')::uuid),
  4, 'buyer can SELECT all 4 events under RLS');

reset role;
select * from finish();
rollback;
