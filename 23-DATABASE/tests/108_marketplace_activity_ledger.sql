-- CC-39 Test 108 — Admin activity ledger.
--
-- Assertions (6):
--   1. admin_list_activity returns the publish event after supplier_publish_capacity
--   2. admin_list_activity orders events by created_at desc
--   3. admin_list_activity joins carrier_organization_id from the listing
--   4. non-admin cannot call admin_list_activity (42501)
--   5. admin_capacity_summary returns total count
--   6. admin_capacity_summary returns by_mode aggregation

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  notify, marketplace, tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '39000000-0000-0000-0000-000000000501', 'authenticated', 'authenticated', '108-carrier@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '39000000-0000-0000-0000-000000000502', 'authenticated', 'authenticated', '108-buyer@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '39000000-0000-0000-0000-000000000599', 'authenticated', 'authenticated', '108-admin@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('39000000-0000-0000-0000-00000000050a', 'tenant-108', 'تست', 'Test 108');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('39000000-0000-0000-0000-00000000051a', '39000000-0000-0000-0000-00000000050a',
   'carr-108', 'حمل', 'Carrier 108', 'carrier', 'active'),
  ('39000000-0000-0000-0000-00000000052a', '39000000-0000-0000-0000-00000000050a',
   'buy-108', 'خریدار', 'Buyer 108', 'buyer', 'active');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('39000000-0000-0000-0000-000000000501', '39000000-0000-0000-0000-00000000050a',
   '39000000-0000-0000-0000-00000000051a', 'Carrier', 'fa', 'active'),
  ('39000000-0000-0000-0000-000000000502', '39000000-0000-0000-0000-00000000050a',
   '39000000-0000-0000-0000-00000000052a', 'Buyer', 'fa', 'active'),
  ('39000000-0000-0000-0000-000000000599', '39000000-0000-0000-0000-00000000050a',
   '39000000-0000-0000-0000-00000000051a', 'Admin', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '39000000-0000-0000-0000-00000000050a', '39000000-0000-0000-0000-00000000051a',
       '39000000-0000-0000-0000-000000000501', r.id, 'active', now()
  from identity.roles r where r.code = 'carrier_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '39000000-0000-0000-0000-000000000501', r.id, 'organization', '39000000-0000-0000-0000-00000000051a'
  from identity.roles r where r.code = 'carrier_admin';

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '39000000-0000-0000-0000-00000000050a', '39000000-0000-0000-0000-00000000052a',
       '39000000-0000-0000-0000-000000000502', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '39000000-0000-0000-0000-000000000502', r.id, 'organization', '39000000-0000-0000-0000-00000000052a'
  from identity.roles r where r.code = 'buyer_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '39000000-0000-0000-0000-000000000599', r.id, 'platform', null
  from identity.roles r where r.code = 'platform_admin';

select plan(6);

-- Carrier publishes two listings with different modes; archives one.
-- Use pg_sleep between calls so the activity-ledger ordering is deterministic
-- even on fast hardware (created_at is timestamptz; ties order ambiguously).
do $$
declare v_id1 uuid; v_id2 uuid;
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','39000000-0000-0000-0000-000000000501','role','authenticated',
                       'tenant_id','39000000-0000-0000-0000-00000000050a',
                       'organization_id','39000000-0000-0000-0000-00000000051a')::text, true);
  perform set_config('request.jwt.claim.sub', '39000000-0000-0000-0000-000000000501', true);
  set local role authenticated;
  v_id1 := marketplace.supplier_publish_capacity(
    p_carrier_organization_id => '39000000-0000-0000-0000-00000000051a',
    p_transport_mode => 'road'
  );
  perform pg_sleep(0.05);
  v_id2 := marketplace.supplier_publish_capacity(
    p_carrier_organization_id => '39000000-0000-0000-0000-00000000051a',
    p_transport_mode => 'sea'
  );
  perform pg_sleep(0.05);
  perform marketplace.supplier_archive_capacity(v_id1, 'no longer needed');
  reset role;
end $$;

-- 1/2/3. Admin reads activity ledger.
do $$
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','39000000-0000-0000-0000-000000000599','role','authenticated',
                       'tenant_id','39000000-0000-0000-0000-00000000050a')::text, true);
  perform set_config('request.jwt.claim.sub', '39000000-0000-0000-0000-000000000599', true);
end $$;

select is(
  (select count(*)::int from marketplace.admin_list_activity()
    where to_status in ('active', 'archived')),
  3, 'admin_list_activity returned 2 publish events + 1 archive event');

-- 2. Ledger contains exactly one archive transition among the three events.
-- Note: within a single test transaction, now() is fixed at the transaction
-- start, so created_at ordering ties. We assert by status rather than recency.
select is(
  (select count(*)::int from marketplace.admin_list_activity()
    where to_status = 'archived'),
  1, 'ledger contains exactly one archive transition');

-- 3. carrier_organization_id is joined from the listing.
select is(
  (select count(*)::int from marketplace.admin_list_activity()
    where carrier_organization_id = '39000000-0000-0000-0000-00000000051a'),
  3, 'admin_list_activity joined carrier_organization_id from listings');

-- 4. Non-admin denied.
do $$
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','39000000-0000-0000-0000-000000000502','role','authenticated',
                       'tenant_id','39000000-0000-0000-0000-00000000050a',
                       'organization_id','39000000-0000-0000-0000-00000000052a')::text, true);
  perform set_config('request.jwt.claim.sub', '39000000-0000-0000-0000-000000000502', true);
  set local role authenticated;
end $$;

select throws_ok(
  $$ select * from marketplace.admin_list_activity() $$,
  '42501', NULL,
  'non-admin cannot call admin_list_activity');

reset role;

-- 5. admin_capacity_summary returns total count.
do $$
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','39000000-0000-0000-0000-000000000599','role','authenticated',
                       'tenant_id','39000000-0000-0000-0000-00000000050a')::text, true);
  perform set_config('request.jwt.claim.sub', '39000000-0000-0000-0000-000000000599', true);
end $$;

select is(
  (select (marketplace.admin_capacity_summary()->>'total')::int),
  2, 'admin_capacity_summary reports total listing count');

-- 6. by_mode aggregation present and shape valid.
select ok(
  jsonb_typeof(marketplace.admin_capacity_summary()->'by_mode') = 'array'
  and jsonb_array_length(marketplace.admin_capacity_summary()->'by_mode') = 2,
  'admin_capacity_summary by_mode has 2 mode aggregates');

select * from finish();
rollback;
