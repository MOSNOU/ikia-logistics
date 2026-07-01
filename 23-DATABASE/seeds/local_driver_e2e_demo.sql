-- ###########################################################################
-- LOCAL DRIVER E2E DEMO SEED — v1.1 Phase A
-- ###########################################################################
--   ⚠️  DO NOT RUN AGAINST PRODUCTION. LOCAL SUPABASE ONLY.
--   ⚠️  This seed uses the superuser-only session_replication_role trick to
--       bypass the booking→dispatch FK chain, and assigns a driver directly.
--       It is intended for a throwaway local Supabase database only.
--
-- Idempotent. Safe to re-run. Contains NO passwords or secrets.
--
-- Prerequisites (create these two auth users FIRST, e.g. Supabase Studio →
-- Authentication → Add user, or the Admin API — this SQL cannot create
-- auth.users):
--     driver  : demo-driver@local.test
--     carrier : demo-carrier-admin@local.test
-- If either is missing this seed no-ops with a NOTICE (like dev_tenant_org.sql).
--
-- What it wires (sentinel UUIDs, prefix dede…):
--   * dev tenant + one carrier org + one buyer org
--   * demo driver: active profile, org-scoped `driver` role, active membership
--   * demo carrier admin: org-scoped `carrier_admin` role (for the RPC path)
--   * one RELEASED dispatch in the carrier org
--   * the driver assigned to that dispatch, execution_status = 'assigned'
--
-- Apply (local):
--   psql "postgres://postgres:postgres@127.0.0.1:54322/postgres" \
--        -f 23-DATABASE/seeds/local_driver_e2e_demo.sql
-- ###########################################################################

do $$
declare
  v_tenant  constant uuid := 'dede0000-0000-0000-0000-0000000000a1';
  v_carrier constant uuid := 'dede0000-0000-0000-0000-0000000000c1';
  v_buyer   constant uuid := 'dede0000-0000-0000-0000-0000000000b1';
  v_booking constant uuid := 'dede0000-0000-0000-0000-0000000000ba';
  v_dispatch constant uuid := 'dede0000-0000-0000-0000-0000000000f1';
  v_driver   uuid;
  v_admin    uuid;
  v_driver_role uuid;
  v_carrier_role uuid;
begin
  -- Guard: this is a LOCAL database. Refuse obviously-not-local hosts is not
  -- reliable from SQL, so we rely on the operator + the header warning.
  select id into v_driver from auth.users where email = 'demo-driver@local.test';
  select id into v_admin  from auth.users where email = 'demo-carrier-admin@local.test';

  if v_driver is null or v_admin is null then
    raise notice 'local_driver_e2e_demo: demo auth users missing (driver=%, admin=%). Create demo-driver@local.test and demo-carrier-admin@local.test via Studio/Admin API, then re-run.',
      v_driver, v_admin;
    return;
  end if;

  select id into v_driver_role  from identity.roles where code = 'driver';
  select id into v_carrier_role from identity.roles where code = 'carrier_admin';

  -- Tenant + orgs -----------------------------------------------------------
  insert into identity.tenants (id, code, name_fa, name_en, country_code, status)
  values (v_tenant, 'ikia-local-e2e', 'تننت دمو محلی', 'Local E2E Tenant', 'IR', 'active')
  on conflict (id) do nothing;

  insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status, country_code)
  values
    (v_carrier, v_tenant, 'local-carrier', 'حمل‌کننده دمو', 'Demo Carrier', 'carrier', 'active', 'IR'),
    (v_buyer,   v_tenant, 'local-buyer',   'خریدار دمو',    'Demo Buyer',   'buyer',   'active', 'IR')
  on conflict (id) do nothing;

  -- Driver identity ---------------------------------------------------------
  insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status)
  values (v_driver, v_tenant, v_carrier, 'راننده دمو', 'fa', 'active')
  on conflict (id) do update
    set tenant_id = excluded.tenant_id,
        primary_organization_id = excluded.primary_organization_id,
        status = 'active';

  if not exists (
    select 1 from identity.user_roles
     where user_id = v_driver and role_id = v_driver_role
       and scope_type = 'organization' and scope_id = v_carrier
       and revoked_at is null and deleted_at is null
  ) then
    insert into identity.user_roles (user_id, role_id, scope_type, scope_id, granted_at)
    values (v_driver, v_driver_role, 'organization', v_carrier, now());
  end if;

  insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
  values (v_tenant, v_carrier, v_driver, v_driver_role, 'active', now())
  on conflict (organization_id, user_id, role_id) do nothing;

  -- Carrier admin identity (so the carrier_assign_driver RPC path can be used
  -- from the app / studio while logged in as this user) -----------------------
  insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status)
  values (v_admin, v_tenant, v_carrier, 'مدیر حمل دمو', 'fa', 'active')
  on conflict (id) do nothing;

  if not exists (
    select 1 from identity.user_roles
     where user_id = v_admin and role_id = v_carrier_role
       and scope_type = 'organization' and scope_id = v_carrier
       and revoked_at is null and deleted_at is null
  ) then
    insert into identity.user_roles (user_id, role_id, scope_type, scope_id, granted_at)
    values (v_admin, v_carrier_role, 'organization', v_carrier, now());
  end if;

  insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
  values (v_tenant, v_carrier, v_admin, v_carrier_role, 'active', now())
  on conflict (organization_id, user_id, role_id) do nothing;

  -- Released dispatch. The booking chain (shipment / capacity) is bypassed via
  -- session_replication_role = replica — LOCAL/superuser only.
  if not exists (select 1 from dispatch.dispatch_assignments where id = v_dispatch) then
    perform set_config('session_replication_role', 'replica', true);

    insert into marketplace.booking_requests
      (id, tenant_id, shipment_id, capacity_listing_id, buyer_organization_id,
       carrier_organization_id, status)
    values
      (v_booking, v_tenant, gen_random_uuid(), gen_random_uuid(), v_buyer, v_carrier, 'draft');

    insert into dispatch.dispatch_assignments
      (id, tenant_id, booking_request_id, buyer_organization_id, carrier_organization_id,
       status, driver_user_id, execution_status, planned_pickup_at, vehicle_reference)
    values
      (v_dispatch, v_tenant, v_booking, v_buyer, v_carrier,
       'released', null, null, now() + interval '1 day', 'DEMO-TRUCK-01');

    perform set_config('session_replication_role', 'origin', true);
  end if;

  -- Assign the demo driver. In production this is the dispatch.carrier_assign_driver
  -- RPC (0048); here we set it directly for a deterministic local fixture.
  -- Production/RPC equivalent (run while logged in as the carrier admin):
  --   select * from dispatch.carrier_assign_driver(v_dispatch, v_driver);
  update dispatch.dispatch_assignments
     set driver_user_id   = v_driver,
         execution_status = coalesce(execution_status, 'assigned'),
         updated_at       = now()
   where id = v_dispatch;

  raise notice 'local_driver_e2e_demo: ready. dispatch=% driver=% carrier_admin=%', v_dispatch, v_driver, v_admin;
end;
$$;
