-- CC-39 Test 107 — Admin moderation surface.
--
-- Assertions (6):
--   1. admin_archive_capacity moves active → archived
--   2. admin archive event captures reason
--   3. admin archive event captures admin_action=true payload flag
--   4. non-admin cannot call admin_archive_capacity (42501)
--   5. admin can archive a draft listing too
--   6. admin_list_capacity returns the archived row

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  notify, marketplace, tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '39000000-0000-0000-0000-000000000401', 'authenticated', 'authenticated', '107-carrier@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '39000000-0000-0000-0000-000000000402', 'authenticated', 'authenticated', '107-buyer@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '39000000-0000-0000-0000-000000000499', 'authenticated', 'authenticated', '107-admin@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('39000000-0000-0000-0000-00000000040a', 'tenant-107', 'تست', 'Test 107');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('39000000-0000-0000-0000-00000000041a', '39000000-0000-0000-0000-00000000040a',
   'carr-107', 'حمل', 'Carrier 107', 'carrier', 'active'),
  ('39000000-0000-0000-0000-00000000042a', '39000000-0000-0000-0000-00000000040a',
   'buy-107', 'خریدار', 'Buyer 107', 'buyer', 'active');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('39000000-0000-0000-0000-000000000401', '39000000-0000-0000-0000-00000000040a',
   '39000000-0000-0000-0000-00000000041a', 'Carrier', 'fa', 'active'),
  ('39000000-0000-0000-0000-000000000402', '39000000-0000-0000-0000-00000000040a',
   '39000000-0000-0000-0000-00000000042a', 'Buyer', 'fa', 'active'),
  ('39000000-0000-0000-0000-000000000499', '39000000-0000-0000-0000-00000000040a',
   '39000000-0000-0000-0000-00000000041a', 'Admin', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '39000000-0000-0000-0000-00000000040a', '39000000-0000-0000-0000-00000000041a',
       '39000000-0000-0000-0000-000000000401', r.id, 'active', now()
  from identity.roles r where r.code = 'carrier_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '39000000-0000-0000-0000-000000000401', r.id, 'organization', '39000000-0000-0000-0000-00000000041a'
  from identity.roles r where r.code = 'carrier_admin';

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '39000000-0000-0000-0000-00000000040a', '39000000-0000-0000-0000-00000000042a',
       '39000000-0000-0000-0000-000000000402', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '39000000-0000-0000-0000-000000000402', r.id, 'organization', '39000000-0000-0000-0000-00000000042a'
  from identity.roles r where r.code = 'buyer_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '39000000-0000-0000-0000-000000000499', r.id, 'platform', null
  from identity.roles r where r.code = 'platform_admin';

select plan(6);

-- Carrier publishes a listing.
do $$
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','39000000-0000-0000-0000-000000000401','role','authenticated',
                       'tenant_id','39000000-0000-0000-0000-00000000040a',
                       'organization_id','39000000-0000-0000-0000-00000000041a')::text, true);
  perform set_config('request.jwt.claim.sub', '39000000-0000-0000-0000-000000000401', true);
  set local role authenticated;
  perform marketplace.supplier_publish_capacity(
    p_carrier_organization_id => '39000000-0000-0000-0000-00000000041a',
    p_transport_mode => 'road'
  );
  reset role;
end $$;

-- Insert a draft listing directly so we can verify admin can archive even drafts.
insert into marketplace.capacity_listings (
  tenant_id, carrier_organization_id, transport_mode, status
) values (
  '39000000-0000-0000-0000-00000000040a',
  '39000000-0000-0000-0000-00000000041a',
  'rail',
  'draft'
);

-- 1. Admin archives the active listing with a reason.
do $$
declare v_id uuid;
begin
  select id into v_id from marketplace.capacity_listings
   where carrier_organization_id = '39000000-0000-0000-0000-00000000041a'
     and transport_mode = 'road' and status = 'active' limit 1;
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','39000000-0000-0000-0000-000000000499','role','authenticated',
                       'tenant_id','39000000-0000-0000-0000-00000000040a')::text, true);
  perform set_config('request.jwt.claim.sub', '39000000-0000-0000-0000-000000000499', true);
  set local role authenticated;
  perform marketplace.admin_archive_capacity(v_id, 'policy violation');
  reset role;
end $$;

select is(
  (select status::text from marketplace.capacity_listings
    where carrier_organization_id = '39000000-0000-0000-0000-00000000041a'
      and transport_mode = 'road'),
  'archived', 'admin_archive_capacity moves active → archived');

-- 2. Archive event has the reason text.
select is(
  (select reason from marketplace.capacity_status_events
    where capacity_listing_id = (
      select id from marketplace.capacity_listings
       where carrier_organization_id = '39000000-0000-0000-0000-00000000041a'
         and transport_mode = 'road' limit 1
    ) and to_status = 'archived'),
  'policy violation', 'archive event captured the reason');

-- 3. Archive event payload includes admin_action flag.
select is(
  (select (payload->>'admin_action') from marketplace.capacity_status_events
    where capacity_listing_id = (
      select id from marketplace.capacity_listings
       where carrier_organization_id = '39000000-0000-0000-0000-00000000041a'
         and transport_mode = 'road' limit 1
    ) and to_status = 'archived'),
  'true', 'archive event payload flags admin_action=true');

-- 4. Non-admin denied.
do $$
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','39000000-0000-0000-0000-000000000402','role','authenticated',
                       'tenant_id','39000000-0000-0000-0000-00000000040a',
                       'organization_id','39000000-0000-0000-0000-00000000042a')::text, true);
  perform set_config('request.jwt.claim.sub', '39000000-0000-0000-0000-000000000402', true);
  set local role authenticated;
end $$;

select throws_ok(
  $$ select marketplace.admin_archive_capacity(
       (select id from marketplace.capacity_listings
         where carrier_organization_id = '39000000-0000-0000-0000-00000000041a'
           and transport_mode = 'rail' limit 1),
       'attempted'
     ) $$,
  '42501', NULL,
  'non-admin cannot call admin_archive_capacity');

reset role;

-- 5. Admin archives the draft listing.
do $$
declare v_id uuid;
begin
  select id into v_id from marketplace.capacity_listings
   where carrier_organization_id = '39000000-0000-0000-0000-00000000041a'
     and transport_mode = 'rail' and status = 'draft' limit 1;
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','39000000-0000-0000-0000-000000000499','role','authenticated',
                       'tenant_id','39000000-0000-0000-0000-00000000040a')::text, true);
  perform set_config('request.jwt.claim.sub', '39000000-0000-0000-0000-000000000499', true);
  set local role authenticated;
  perform marketplace.admin_archive_capacity(v_id, 'pre-publish moderation');
  reset role;
end $$;

select is(
  (select status::text from marketplace.capacity_listings
    where carrier_organization_id = '39000000-0000-0000-0000-00000000041a'
      and transport_mode = 'rail'),
  'archived', 'admin can archive a draft listing');

-- 6. admin_list_capacity returns both rows.
do $$
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','39000000-0000-0000-0000-000000000499','role','authenticated',
                       'tenant_id','39000000-0000-0000-0000-00000000040a')::text, true);
  perform set_config('request.jwt.claim.sub', '39000000-0000-0000-0000-000000000499', true);
end $$;

select is(
  (select count(*)::int from marketplace.admin_list_capacity(
     p_carrier_id => '39000000-0000-0000-0000-00000000041a'
   )),
  2, 'admin_list_capacity returns both listings (incl. archived)');

select * from finish();
rollback;
