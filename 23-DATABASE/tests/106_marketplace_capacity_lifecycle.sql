-- CC-39 Test 106 — Marketplace capacity lifecycle.
--
-- Assertions (7):
--   1. supplier_archive_capacity transitions active → archived
--   2. archive recorded a status event with to_status='archived'
--   3. archive on already-archived listing raises P0001
--   4. supplier_update_capacity on archived listing raises P0001
--   5. buyer_list_capacity excludes archived listings
--   6. buyer_list_capacity excludes listings with valid_until in the past
--   7. carrier without public visibility — buyer_list_capacity returns 0

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  notify, marketplace, tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '39000000-0000-0000-0000-000000000301', 'authenticated', 'authenticated', '106-carrier@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('39000000-0000-0000-0000-00000000030a', 'tenant-106', 'تست', 'Test 106');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('39000000-0000-0000-0000-00000000031a', '39000000-0000-0000-0000-00000000030a',
   'carr-106', 'حمل', 'Carrier 106', 'carrier', 'active');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('39000000-0000-0000-0000-000000000301', '39000000-0000-0000-0000-00000000030a',
   '39000000-0000-0000-0000-00000000031a', 'Carrier', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '39000000-0000-0000-0000-00000000030a', '39000000-0000-0000-0000-00000000031a',
       '39000000-0000-0000-0000-000000000301', r.id, 'active', now()
  from identity.roles r where r.code = 'carrier_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '39000000-0000-0000-0000-000000000301', r.id, 'organization', '39000000-0000-0000-0000-00000000031a'
  from identity.roles r where r.code = 'carrier_admin';

select plan(7);

-- Publish a listing + make carrier public so buyer_list_capacity could see it.
do $$
declare v_id uuid;
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','39000000-0000-0000-0000-000000000301','role','authenticated',
                       'tenant_id','39000000-0000-0000-0000-00000000030a',
                       'organization_id','39000000-0000-0000-0000-00000000031a')::text, true);
  perform set_config('request.jwt.claim.sub', '39000000-0000-0000-0000-000000000301', true);
  set local role authenticated;
  v_id := marketplace.supplier_publish_capacity(
    p_carrier_organization_id => '39000000-0000-0000-0000-00000000031a',
    p_transport_mode => 'road',
    p_valid_until => now() + interval '7 days'
  );
  perform marketplace.carrier_set_directory_visibility(
    p_organization_id => '39000000-0000-0000-0000-00000000031a',
    p_is_public => true
  );
  reset role;
end $$;

-- 1. Archive.
do $$
declare v_id uuid;
begin
  select id into v_id from marketplace.capacity_listings
   where carrier_organization_id = '39000000-0000-0000-0000-00000000031a' limit 1;
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','39000000-0000-0000-0000-000000000301','role','authenticated',
                       'tenant_id','39000000-0000-0000-0000-00000000030a',
                       'organization_id','39000000-0000-0000-0000-00000000031a')::text, true);
  perform set_config('request.jwt.claim.sub', '39000000-0000-0000-0000-000000000301', true);
  set local role authenticated;
  perform marketplace.supplier_archive_capacity(v_id, 'no longer needed');
  reset role;
end $$;

select is(
  (select status::text from marketplace.capacity_listings
    where carrier_organization_id = '39000000-0000-0000-0000-00000000031a' limit 1),
  'archived', 'supplier_archive_capacity moved listing to archived');

-- 2. Archive event recorded.
select is(
  (select count(*)::int from marketplace.capacity_status_events e
    join marketplace.capacity_listings cl on cl.id = e.capacity_listing_id
   where cl.carrier_organization_id = '39000000-0000-0000-0000-00000000031a'
     and e.to_status = 'archived'),
  1, 'archive recorded a status event');

-- 3. Re-archive raises P0001.
-- Set role and JWT at top level so they persist across throws_ok calls.
select set_config('request.jwt.claims',
  jsonb_build_object('sub','39000000-0000-0000-0000-000000000301','role','authenticated',
                     'tenant_id','39000000-0000-0000-0000-00000000030a',
                     'organization_id','39000000-0000-0000-0000-00000000031a')::text, true);
select set_config('request.jwt.claim.sub', '39000000-0000-0000-0000-000000000301', true);
set local role authenticated;

select throws_ok(
  $$ select marketplace.supplier_archive_capacity(
       (select id from marketplace.capacity_listings
         where carrier_organization_id = '39000000-0000-0000-0000-00000000031a' limit 1),
       null
     ) $$,
  'P0001', NULL,
  'archiving an already-archived listing raises P0001');

-- 4. Update on archived listing raises P0001.
select throws_ok(
  $$ select marketplace.supplier_update_capacity(
       (select id from marketplace.capacity_listings
         where carrier_organization_id = '39000000-0000-0000-0000-00000000031a' limit 1),
       p_origin_city => 'X'
     ) $$,
  'P0001', NULL,
  'update on archived listing raises P0001');

reset role;

-- 5/6/7. Buyer-side visibility.
-- Add a fresh active+public listing AND an expired one; then a private carrier with active+today.
do $$
declare v_id uuid;
begin
  -- (a) Active listing on a brand-new carrier with public visibility.
  insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
    ('39000000-0000-0000-0000-00000000032a', '39000000-0000-0000-0000-00000000030a',
     'carr-106b', 'حمل ب', 'Carrier 106-B', 'carrier', 'active');
  insert into marketplace.carrier_directory_visibility
    (carrier_organization_id, tenant_id, is_public, published_at)
    values ('39000000-0000-0000-0000-00000000032a',
            '39000000-0000-0000-0000-00000000030a', true, now());
  -- Active listing valid into the future.
  insert into marketplace.capacity_listings (
    tenant_id, carrier_organization_id, transport_mode,
    status, valid_until, created_at
  ) values (
    '39000000-0000-0000-0000-00000000030a', '39000000-0000-0000-0000-00000000032a', 'road',
    'active', now() + interval '7 days', now()
  );
  -- Expired listing on same carrier.
  insert into marketplace.capacity_listings (
    tenant_id, carrier_organization_id, transport_mode,
    status, valid_until, created_at
  ) values (
    '39000000-0000-0000-0000-00000000030a', '39000000-0000-0000-0000-00000000032a', 'sea',
    'active', now() - interval '1 day', now() - interval '2 days'
  );

  -- (b) Private carrier with active listing (no visibility row).
  insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
    ('39000000-0000-0000-0000-00000000033a', '39000000-0000-0000-0000-00000000030a',
     'carr-106c', 'حمل ج', 'Carrier 106-C', 'carrier', 'active');
  insert into marketplace.capacity_listings (
    tenant_id, carrier_organization_id, transport_mode,
    status, created_at
  ) values (
    '39000000-0000-0000-0000-00000000030a', '39000000-0000-0000-0000-00000000033a', 'air',
    'active', now()
  );
end $$;

-- 5. Buyer listing excludes archived (no JWT needed; RPC is SECURITY DEFINER but applies its own filters).
do $$
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','39000000-0000-0000-0000-000000000301','role','authenticated',
                       'tenant_id','39000000-0000-0000-0000-00000000030a',
                       'organization_id','39000000-0000-0000-0000-00000000031a')::text, true);
  perform set_config('request.jwt.claim.sub', '39000000-0000-0000-0000-000000000301', true);
end $$;

-- The original carrier (031a) had only one listing which is now archived; the
-- new carrier 032a has one active (in future) + one expired; carrier 033a is
-- private. Buyer should see only carrier 032a's active+future listing → 1 row.
select is(
  (select count(*)::int from marketplace.buyer_list_capacity()),
  1, 'buyer_list_capacity excludes archived + expired + private');

-- 6. Expired exclusion specifically — filter by mode 'sea' (which only the
-- expired listing has) returns 0.
select is(
  (select count(*)::int from marketplace.buyer_list_capacity(
     p_transport_mode => 'sea'
   )),
  0, 'expired listing excluded');

-- 7. Private carrier exclusion — filter by mode 'air' returns 0.
select is(
  (select count(*)::int from marketplace.buyer_list_capacity(
     p_transport_mode => 'air'
   )),
  0, 'private-carrier listing excluded');

select * from finish();
rollback;
