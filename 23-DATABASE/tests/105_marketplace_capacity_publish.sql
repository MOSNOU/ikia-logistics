-- CC-39 Test 105 — Marketplace capacity publish flow.
--
-- Assertions (7):
--   1. supplier_publish_capacity creates a row with status='active'
--   2. supplier_publish_capacity wrote a status event (draft → active)
--   3. supplier_publish_capacity by non-carrier-admin raises 42501
--   4. supplier_publish_capacity into a buyer-typed org raises 22023
--   5. supplier_update_capacity patches origin_city
--   6. supplier_list_my_capacity returns the carrier's own listing
--   7. supplier_publish_capacity without transport_mode raises 22023

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  notify, marketplace, tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '39000000-0000-0000-0000-000000000201', 'authenticated', 'authenticated', '105-carrier@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '39000000-0000-0000-0000-000000000202', 'authenticated', 'authenticated', '105-buyer@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('39000000-0000-0000-0000-00000000020a', 'tenant-105', 'تست', 'Test 105');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('39000000-0000-0000-0000-00000000021a', '39000000-0000-0000-0000-00000000020a',
   'carr-105', 'حمل', 'Carrier 105', 'carrier', 'active'),
  ('39000000-0000-0000-0000-00000000022a', '39000000-0000-0000-0000-00000000020a',
   'buy-105', 'خریدار', 'Buyer 105', 'buyer', 'active');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('39000000-0000-0000-0000-000000000201', '39000000-0000-0000-0000-00000000020a',
   '39000000-0000-0000-0000-00000000021a', 'Carrier', 'fa', 'active'),
  ('39000000-0000-0000-0000-000000000202', '39000000-0000-0000-0000-00000000020a',
   '39000000-0000-0000-0000-00000000022a', 'Buyer', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '39000000-0000-0000-0000-00000000020a', '39000000-0000-0000-0000-00000000021a',
       '39000000-0000-0000-0000-000000000201', r.id, 'active', now()
  from identity.roles r where r.code = 'carrier_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '39000000-0000-0000-0000-000000000201', r.id, 'organization', '39000000-0000-0000-0000-00000000021a'
  from identity.roles r where r.code = 'carrier_admin';

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '39000000-0000-0000-0000-00000000020a', '39000000-0000-0000-0000-00000000022a',
       '39000000-0000-0000-0000-000000000202', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '39000000-0000-0000-0000-000000000202', r.id, 'organization', '39000000-0000-0000-0000-00000000022a'
  from identity.roles r where r.code = 'buyer_admin';

select plan(7);

-- 1. Carrier admin publishes capacity.
do $$
declare v_id uuid;
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','39000000-0000-0000-0000-000000000201','role','authenticated',
                       'tenant_id','39000000-0000-0000-0000-00000000020a',
                       'organization_id','39000000-0000-0000-0000-00000000021a')::text, true);
  perform set_config('request.jwt.claim.sub', '39000000-0000-0000-0000-000000000201', true);
  set local role authenticated;
  v_id := marketplace.supplier_publish_capacity(
    p_carrier_organization_id => '39000000-0000-0000-0000-00000000021a',
    p_transport_mode => 'road',
    p_origin_country => 'IR'::citext,
    p_destination_country => 'DE'::citext,
    p_capacity_units => 10
  );
  reset role;
end $$;

select is(
  (select status::text from marketplace.capacity_listings
    where carrier_organization_id = '39000000-0000-0000-0000-00000000021a'),
  'active', 'publish_capacity created listing with status=active');

-- 2. Status event recorded for the publish transition.
select is(
  (select count(*)::int from marketplace.capacity_status_events e
    join marketplace.capacity_listings cl on cl.id = e.capacity_listing_id
   where cl.carrier_organization_id = '39000000-0000-0000-0000-00000000021a'
     and e.from_status = 'draft' and e.to_status = 'active'),
  1, 'publish recorded draft → active status event');

-- 3. Non-carrier-admin (buyer) cannot publish to the carrier org.
do $$
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','39000000-0000-0000-0000-000000000202','role','authenticated',
                       'tenant_id','39000000-0000-0000-0000-00000000020a',
                       'organization_id','39000000-0000-0000-0000-00000000022a')::text, true);
  perform set_config('request.jwt.claim.sub', '39000000-0000-0000-0000-000000000202', true);
  set local role authenticated;
end $$;

select throws_ok(
  $$ select marketplace.supplier_publish_capacity(
       p_carrier_organization_id => '39000000-0000-0000-0000-00000000021a',
       p_transport_mode => 'road'
     ) $$,
  '42501', NULL,
  'non-carrier-admin denied');

reset role;

-- 4. Publishing into a buyer-typed org raises 22023.
do $$
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','39000000-0000-0000-0000-000000000201','role','authenticated',
                       'tenant_id','39000000-0000-0000-0000-00000000020a',
                       'organization_id','39000000-0000-0000-0000-00000000021a')::text, true);
  perform set_config('request.jwt.claim.sub', '39000000-0000-0000-0000-000000000201', true);
  set local role authenticated;
end $$;

select throws_ok(
  $$ select marketplace.supplier_publish_capacity(
       p_carrier_organization_id => '39000000-0000-0000-0000-00000000022a',
       p_transport_mode => 'road'
     ) $$,
  '22023', NULL,
  'publishing into a buyer-typed org raises 22023');

reset role;

-- 5. Update patches origin_city.
do $$
declare v_id uuid;
begin
  select id into v_id from marketplace.capacity_listings
   where carrier_organization_id = '39000000-0000-0000-0000-00000000021a' limit 1;
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','39000000-0000-0000-0000-000000000201','role','authenticated',
                       'tenant_id','39000000-0000-0000-0000-00000000020a',
                       'organization_id','39000000-0000-0000-0000-00000000021a')::text, true);
  perform set_config('request.jwt.claim.sub', '39000000-0000-0000-0000-000000000201', true);
  set local role authenticated;
  perform marketplace.supplier_update_capacity(
    p_listing_id => v_id,
    p_origin_city => 'Tehran'
  );
  reset role;
end $$;

select is(
  (select origin_city from marketplace.capacity_listings
    where carrier_organization_id = '39000000-0000-0000-0000-00000000021a' limit 1),
  'Tehran', 'update_capacity patched origin_city');

-- 6. supplier_list_my_capacity returns the row.
do $$
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','39000000-0000-0000-0000-000000000201','role','authenticated',
                       'tenant_id','39000000-0000-0000-0000-00000000020a',
                       'organization_id','39000000-0000-0000-0000-00000000021a')::text, true);
  perform set_config('request.jwt.claim.sub', '39000000-0000-0000-0000-000000000201', true);
  set local role authenticated;
end $$;

select is(
  (select count(*)::int from marketplace.supplier_list_my_capacity(
     p_carrier_organization_id => '39000000-0000-0000-0000-00000000021a'
   )),
  1, 'supplier_list_my_capacity returns own listing');

reset role;

-- 7. publish without transport_mode → 22023.
do $$
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','39000000-0000-0000-0000-000000000201','role','authenticated',
                       'tenant_id','39000000-0000-0000-0000-00000000020a',
                       'organization_id','39000000-0000-0000-0000-00000000021a')::text, true);
  perform set_config('request.jwt.claim.sub', '39000000-0000-0000-0000-000000000201', true);
  set local role authenticated;
end $$;

select throws_ok(
  $$ select marketplace.supplier_publish_capacity(
       p_carrier_organization_id => '39000000-0000-0000-0000-00000000021a',
       p_transport_mode => null
     ) $$,
  '22023', NULL,
  'publish without transport_mode raises 22023');

reset role;

select * from finish();
rollback;
