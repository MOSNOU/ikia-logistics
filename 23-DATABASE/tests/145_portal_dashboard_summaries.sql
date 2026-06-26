-- CC-73 Test 145 — portal dashboard summary RPCs (buyer / supplier / carrier)
--
-- Assertions (15):
--   Buyer (5)
--     1.  marketplace.buyer_get_dashboard_summary exists with zero args
--     2.  is SECURITY DEFINER, search_path=''
--     3.  authenticated has EXECUTE, anon does not
--     4.  no-org-context caller receives scope="no_org_context"
--     5.  buyer-org caller receives scope="org" and expected keys
--   Supplier (5)
--     6.  supplier.portal_get_dashboard_summary exists with zero args
--     7.  is SECURITY DEFINER, search_path=''
--     8.  authenticated has EXECUTE, anon does not
--     9.  no-supplier-context caller receives scope="no_supplier_context"
--    10.  supplier caller receives scope="supplier" and expected keys
--   Carrier (5)
--    11.  marketplace.carrier_get_dashboard_summary exists with zero args
--    12.  is SECURITY DEFINER, search_path=''
--    13.  authenticated has EXECUTE, anon does not
--    14.  no-org-context caller receives scope="no_org_context"
--    15.  carrier-org caller receives scope="org" and expected keys

set search_path = extensions, public, identity, organization, audit, supplier,
                  commodity, rfq, offer, evaluation, contract, shipment, notify,
                  marketplace, dispatch, telematics, execution, tests;
begin;

-- ---------------------------------------------------------------------------
-- Fixtures: one buyer org user, one carrier org user, one supplier user, and
-- one platform-only user without any org context.
-- ---------------------------------------------------------------------------
insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '53000000-0000-0000-0000-000000000a45', 'authenticated', 'authenticated', 'b@e45.com'),
  ('00000000-0000-0000-0000-000000000000',
   '53000000-0000-0000-0000-000000000b45', 'authenticated', 'authenticated', 's@e45.com'),
  ('00000000-0000-0000-0000-000000000000',
   '53000000-0000-0000-0000-000000000c45', 'authenticated', 'authenticated', 'c@e45.com'),
  ('00000000-0000-0000-0000-000000000000',
   '53000000-0000-0000-0000-000000000d45', 'authenticated', 'authenticated', 'noctx@e45.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('53000000-0000-0000-0000-00000000e45a', 'tenant-145', 'تست', 'Test 145');

insert into organization.organizations
  (id, tenant_id, code, name_fa, name_en, type, status, country_code) values
  ('53000000-0000-0000-0000-00000000e45b',
   '53000000-0000-0000-0000-00000000e45a',
   'buy-145', 'خریدار', 'Buyer 145', 'buyer', 'active', 'IR'),
  ('53000000-0000-0000-0000-00000000e45c',
   '53000000-0000-0000-0000-00000000e45a',
   'sup-145', 'تأمین', 'Supplier 145', 'supplier', 'active', 'IR'),
  ('53000000-0000-0000-0000-00000000e45d',
   '53000000-0000-0000-0000-00000000e45a',
   'carr-145', 'حمل', 'Carrier 145', 'carrier', 'active', 'IR');

insert into identity.user_profiles
  (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('53000000-0000-0000-0000-000000000a45',
   '53000000-0000-0000-0000-00000000e45a',
   '53000000-0000-0000-0000-00000000e45b', 'Buyer 145', 'fa', 'active'),
  ('53000000-0000-0000-0000-000000000b45',
   '53000000-0000-0000-0000-00000000e45a',
   '53000000-0000-0000-0000-00000000e45c', 'Supplier 145', 'fa', 'active'),
  ('53000000-0000-0000-0000-000000000c45',
   '53000000-0000-0000-0000-00000000e45a',
   '53000000-0000-0000-0000-00000000e45d', 'Carrier 145', 'fa', 'active'),
  ('53000000-0000-0000-0000-000000000d45',
   '53000000-0000-0000-0000-00000000e45a',
   null, 'NoContext 145', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '53000000-0000-0000-0000-00000000e45a', '53000000-0000-0000-0000-00000000e45b',
       '53000000-0000-0000-0000-000000000a45', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '53000000-0000-0000-0000-000000000a45', r.id, 'organization',
       '53000000-0000-0000-0000-00000000e45b' from identity.roles r where r.code='buyer_admin';

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '53000000-0000-0000-0000-00000000e45a', '53000000-0000-0000-0000-00000000e45c',
       '53000000-0000-0000-0000-000000000b45', r.id, 'active', now()
  from identity.roles r where r.code = 'supplier_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '53000000-0000-0000-0000-000000000b45', r.id, 'organization',
       '53000000-0000-0000-0000-00000000e45c' from identity.roles r where r.code='supplier_admin';

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '53000000-0000-0000-0000-00000000e45a', '53000000-0000-0000-0000-00000000e45d',
       '53000000-0000-0000-0000-000000000c45', r.id, 'active', now()
  from identity.roles r where r.code = 'carrier_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '53000000-0000-0000-0000-000000000c45', r.id, 'organization',
       '53000000-0000-0000-0000-00000000e45d' from identity.roles r where r.code='carrier_admin';

select plan(15);

-- ---------------------------------------------------------------------------
-- BUYER
-- ---------------------------------------------------------------------------
select has_function(
  'marketplace', 'buyer_get_dashboard_summary', array[]::text[],
  'buyer summary: function exists with zero args');

select ok(
  (select prosecdef from pg_proc p
     join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='marketplace' and p.proname='buyer_get_dashboard_summary')
  and (select unnest(proconfig)::text from pg_proc p
     join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='marketplace' and p.proname='buyer_get_dashboard_summary')
      = 'search_path=""',
  'buyer summary: SECURITY DEFINER + search_path="" both set');

select ok(
  has_function_privilege('authenticated',
    'marketplace.buyer_get_dashboard_summary()', 'EXECUTE')
  and not has_function_privilege('anon',
    'marketplace.buyer_get_dashboard_summary()', 'EXECUTE'),
  'buyer summary: authenticated yes / anon no');

-- no-org-context caller
do $$
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub', '53000000-0000-0000-0000-000000000d45',
                       'role','authenticated')::text, true);
  perform set_config('request.jwt.claim.sub',
                     '53000000-0000-0000-0000-000000000d45', true);
  set local role authenticated;
end $$;
select is(
  (select marketplace.buyer_get_dashboard_summary()->>'scope'),
  'no_org_context',
  'buyer summary: no-org-context caller receives scope="no_org_context"');
reset role;

-- buyer-org caller
do $$
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub', '53000000-0000-0000-0000-000000000a45',
                       'role','authenticated',
                       'organization_id','53000000-0000-0000-0000-00000000e45b'
                      )::text, true);
  perform set_config('request.jwt.claim.sub',
                     '53000000-0000-0000-0000-000000000a45', true);
  set local role authenticated;
end $$;
select ok(
  (
    select marketplace.buyer_get_dashboard_summary()->>'scope' = 'org'
       and marketplace.buyer_get_dashboard_summary() ? 'activeRfqs'
       and marketplace.buyer_get_dashboard_summary() ? 'openBookings'
       and marketplace.buyer_get_dashboard_summary() ? 'activeShipments'
       and marketplace.buyer_get_dashboard_summary() ? 'activeContracts'
       and marketplace.buyer_get_dashboard_summary() ? 'recentBookings'
  ),
  'buyer summary: org caller receives scope="org" and all expected keys');
reset role;

-- ---------------------------------------------------------------------------
-- SUPPLIER
-- ---------------------------------------------------------------------------
select has_function(
  'supplier', 'portal_get_dashboard_summary', array[]::text[],
  'supplier summary: function exists with zero args');

select ok(
  (select prosecdef from pg_proc p
     join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='supplier' and p.proname='portal_get_dashboard_summary')
  and (select unnest(proconfig)::text from pg_proc p
     join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='supplier' and p.proname='portal_get_dashboard_summary')
      = 'search_path=""',
  'supplier summary: SECURITY DEFINER + search_path="" both set');

select ok(
  has_function_privilege('authenticated',
    'supplier.portal_get_dashboard_summary()', 'EXECUTE')
  and not has_function_privilege('anon',
    'supplier.portal_get_dashboard_summary()', 'EXECUTE'),
  'supplier summary: authenticated yes / anon no');

-- no-supplier-context caller (uses the no-context user)
do $$
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub', '53000000-0000-0000-0000-000000000d45',
                       'role','authenticated')::text, true);
  perform set_config('request.jwt.claim.sub',
                     '53000000-0000-0000-0000-000000000d45', true);
  set local role authenticated;
end $$;
select is(
  (select supplier.portal_get_dashboard_summary()->>'scope'),
  'no_supplier_context',
  'supplier summary: no-supplier-context caller receives scope="no_supplier_context"');
reset role;

-- supplier caller (the supplier.suppliers row auto-materialised via trigger
-- when the 'supplier' org was created; fn_portal_supplier_id() resolves it
-- from the JWT organization_id).
do $$
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub', '53000000-0000-0000-0000-000000000b45',
                       'role','authenticated',
                       'organization_id','53000000-0000-0000-0000-00000000e45c'
                      )::text, true);
  perform set_config('request.jwt.claim.sub',
                     '53000000-0000-0000-0000-000000000b45', true);
  set local role authenticated;
end $$;
select ok(
  (
    select supplier.portal_get_dashboard_summary()->>'scope' = 'supplier'
       and supplier.portal_get_dashboard_summary() ? 'activeOffers'
       and supplier.portal_get_dashboard_summary() ? 'activeContracts'
       and supplier.portal_get_dashboard_summary() ? 'activeShipments'
       and supplier.portal_get_dashboard_summary() ? 'addressableRfqs'
       and supplier.portal_get_dashboard_summary() ? 'recentOffers'
  ),
  'supplier summary: supplier caller receives scope="supplier" and all expected keys');
reset role;

-- ---------------------------------------------------------------------------
-- CARRIER
-- ---------------------------------------------------------------------------
select has_function(
  'marketplace', 'carrier_get_dashboard_summary', array[]::text[],
  'carrier summary: function exists with zero args');

select ok(
  (select prosecdef from pg_proc p
     join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='marketplace' and p.proname='carrier_get_dashboard_summary')
  and (select unnest(proconfig)::text from pg_proc p
     join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='marketplace' and p.proname='carrier_get_dashboard_summary')
      = 'search_path=""',
  'carrier summary: SECURITY DEFINER + search_path="" both set');

select ok(
  has_function_privilege('authenticated',
    'marketplace.carrier_get_dashboard_summary()', 'EXECUTE')
  and not has_function_privilege('anon',
    'marketplace.carrier_get_dashboard_summary()', 'EXECUTE'),
  'carrier summary: authenticated yes / anon no');

do $$
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub', '53000000-0000-0000-0000-000000000d45',
                       'role','authenticated')::text, true);
  perform set_config('request.jwt.claim.sub',
                     '53000000-0000-0000-0000-000000000d45', true);
  set local role authenticated;
end $$;
select is(
  (select marketplace.carrier_get_dashboard_summary()->>'scope'),
  'no_org_context',
  'carrier summary: no-org-context caller receives scope="no_org_context"');
reset role;

do $$
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub', '53000000-0000-0000-0000-000000000c45',
                       'role','authenticated',
                       'organization_id','53000000-0000-0000-0000-00000000e45d'
                      )::text, true);
  perform set_config('request.jwt.claim.sub',
                     '53000000-0000-0000-0000-000000000c45', true);
  set local role authenticated;
end $$;
select ok(
  (
    select marketplace.carrier_get_dashboard_summary()->>'scope' = 'org'
       and marketplace.carrier_get_dashboard_summary() ? 'openBookings'
       and marketplace.carrier_get_dashboard_summary() ? 'activeDispatches'
       and marketplace.carrier_get_dashboard_summary() ? 'inTransitShipments'
       and marketplace.carrier_get_dashboard_summary() ? 'activeCapacity'
       and marketplace.carrier_get_dashboard_summary() ? 'recentDispatches'
  ),
  'carrier summary: carrier-org caller receives scope="org" and all expected keys');
reset role;

select * from finish();
rollback;
