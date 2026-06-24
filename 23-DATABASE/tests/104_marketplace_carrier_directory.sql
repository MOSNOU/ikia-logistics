-- CC-39 Test 104 — Marketplace carrier directory.
--
-- Assertions (8):
--   1. carrier_upsert_profile creates a profile (status default = draft)
--   2. carrier_set_directory_visibility(true) flips is_public
--   3. carrier_upsert_profile transitions profile to status='active'
--   4. buyer_list_carriers (anonymous-buyer JWT) sees the public+active carrier
--   5. buyer_list_carriers excludes a non-public carrier
--   6. carrier_upsert_profile against non-carrier org raises 22023
--   7. carrier_upsert_profile by non-owner raises 42501
--   8. admin_list_carriers sees both public and non-public carriers

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  notify, marketplace, tests;
begin;

-- Fixtures
insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '39000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '104-carrier-admin@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '39000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', '104-buyer@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '39000000-0000-0000-0000-000000000099', 'authenticated', 'authenticated', '104-admin@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('39000000-0000-0000-0000-00000000000a', 'tenant-104', 'تست', 'Test 104');

-- Three orgs: one carrier (will be public), one carrier (will stay private), one buyer.
insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('39000000-0000-0000-0000-00000000001a', '39000000-0000-0000-0000-00000000000a',
   'carr-104-pub', 'حمل عمومی', 'Public Carrier 104', 'carrier', 'active'),
  ('39000000-0000-0000-0000-00000000001b', '39000000-0000-0000-0000-00000000000a',
   'carr-104-priv', 'حمل خصوصی', 'Private Carrier 104', 'carrier', 'active'),
  ('39000000-0000-0000-0000-00000000002a', '39000000-0000-0000-0000-00000000000a',
   'buy-104', 'خریدار', 'Buyer 104', 'buyer', 'active');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('39000000-0000-0000-0000-000000000001', '39000000-0000-0000-0000-00000000000a',
   '39000000-0000-0000-0000-00000000001a', 'Carrier Admin', 'fa', 'active'),
  ('39000000-0000-0000-0000-000000000002', '39000000-0000-0000-0000-00000000000a',
   '39000000-0000-0000-0000-00000000002a', 'Buyer', 'fa', 'active'),
  ('39000000-0000-0000-0000-000000000099', '39000000-0000-0000-0000-00000000000a',
   '39000000-0000-0000-0000-00000000001a', 'Admin', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '39000000-0000-0000-0000-00000000000a', '39000000-0000-0000-0000-00000000001a',
       '39000000-0000-0000-0000-000000000001', r.id, 'active', now()
  from identity.roles r where r.code = 'carrier_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '39000000-0000-0000-0000-000000000001', r.id, 'organization', '39000000-0000-0000-0000-00000000001a'
  from identity.roles r where r.code = 'carrier_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '39000000-0000-0000-0000-000000000099', r.id, 'platform', null
  from identity.roles r where r.code = 'platform_admin';

select plan(8);

-- 1. Carrier admin creates a profile (defaults to draft).
do $$
declare v_id uuid;
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','39000000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','39000000-0000-0000-0000-00000000000a',
                       'organization_id','39000000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '39000000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_id := marketplace.carrier_upsert_profile(
    p_organization_id => '39000000-0000-0000-0000-00000000001a',
    p_display_name_fa => 'حمل تستی'
  );
  reset role;
end $$;

select is(
  (select status::text from marketplace.carrier_profiles
    where organization_id = '39000000-0000-0000-0000-00000000001a'),
  'draft', 'profile created with default status=draft');

-- 2. Flip visibility to public.
do $$
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','39000000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','39000000-0000-0000-0000-00000000000a',
                       'organization_id','39000000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '39000000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  perform marketplace.carrier_set_directory_visibility(
    p_organization_id => '39000000-0000-0000-0000-00000000001a',
    p_is_public => true
  );
  reset role;
end $$;

select is(
  (select is_public from marketplace.carrier_directory_visibility
    where carrier_organization_id = '39000000-0000-0000-0000-00000000001a'),
  true, 'directory visibility flipped to public');

-- 3. Upsert to active so buyer_list_carriers can see it.
do $$
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','39000000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','39000000-0000-0000-0000-00000000000a',
                       'organization_id','39000000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '39000000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  perform marketplace.carrier_upsert_profile(
    p_organization_id => '39000000-0000-0000-0000-00000000001a',
    p_status => 'active'
  );
  reset role;
end $$;

select is(
  (select status::text from marketplace.carrier_profiles
    where organization_id = '39000000-0000-0000-0000-00000000001a'),
  'active', 'profile upsert promoted to status=active');

-- 4. Buyer lists carriers — should see the public+active one.
do $$
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','39000000-0000-0000-0000-000000000002','role','authenticated',
                       'tenant_id','39000000-0000-0000-0000-00000000000a',
                       'organization_id','39000000-0000-0000-0000-00000000002a')::text, true);
  perform set_config('request.jwt.claim.sub', '39000000-0000-0000-0000-000000000002', true);
end $$;

select is(
  (select count(*)::int from marketplace.buyer_list_carriers()),
  1, 'buyer_list_carriers returns the public+active carrier');

-- 5. Add a second carrier with profile but no visibility. Buyer should still see only 1.
do $$
begin
  insert into marketplace.carrier_profiles (
    tenant_id, organization_id, display_name_fa, status
  ) values (
    '39000000-0000-0000-0000-00000000000a',
    '39000000-0000-0000-0000-00000000001b',
    'حمل خصوصی',
    'active'
  );
end $$;

select is(
  (select count(*)::int from marketplace.buyer_list_carriers()),
  1, 'buyer_list_carriers still returns 1 (private carrier excluded)');

-- 6. carrier_upsert_profile against a buyer org raises 22023.
do $$
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','39000000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','39000000-0000-0000-0000-00000000000a',
                       'organization_id','39000000-0000-0000-0000-00000000002a')::text, true);
  perform set_config('request.jwt.claim.sub', '39000000-0000-0000-0000-000000000001', true);
  set local role authenticated;
end $$;

select throws_ok(
  $$ select marketplace.carrier_upsert_profile(
       p_organization_id => '39000000-0000-0000-0000-00000000002a',
       p_display_name_fa => 'Bad'
     ) $$,
  '22023', NULL,
  'upsert against non-carrier org raises 22023');

reset role;

-- 7. Non-owner carrier_admin cannot upsert another carrier's profile.
do $$
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','39000000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','39000000-0000-0000-0000-00000000000a',
                       'organization_id','39000000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '39000000-0000-0000-0000-000000000001', true);
  set local role authenticated;
end $$;

select throws_ok(
  $$ select marketplace.carrier_upsert_profile(
       p_organization_id => '39000000-0000-0000-0000-00000000001b',
       p_display_name_fa => 'Bad'
     ) $$,
  '42501', NULL,
  'non-owner cannot upsert another carrier profile');

reset role;

-- 8. Admin sees both carriers regardless of visibility.
do $$
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','39000000-0000-0000-0000-000000000099','role','authenticated',
                       'tenant_id','39000000-0000-0000-0000-00000000000a')::text, true);
  perform set_config('request.jwt.claim.sub', '39000000-0000-0000-0000-000000000099', true);
end $$;

select is(
  (select count(*)::int from marketplace.admin_list_carriers()),
  2, 'admin_list_carriers sees both carriers regardless of visibility');

select * from finish();
rollback;
