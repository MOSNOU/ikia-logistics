-- ###########################################################################
-- LOCAL DRIVER E2E DEMO SEED — v1.1 Phase A
-- ###########################################################################
--   ⚠️  DO NOT RUN AGAINST PRODUCTION. LOCAL SUPABASE ONLY.
--   ⚠️  This seed briefly sets session_replication_role = replica (top-level,
--       permitted for the local `postgres` role) ONLY to bypass the
--       booking→dispatch FK chain for a throwaway demo dispatch. It resets to
--       DEFAULT immediately afterwards. Intended for a local Supabase database
--       only.
--
-- Idempotent. Safe to re-run. Contains NO passwords or secrets. Every insert is
-- guarded so that if the demo auth users are absent the seed is a clean no-op
-- (nothing is written) — auth.users must be created out-of-band first.
--
-- Prerequisites (create these two auth users FIRST — Supabase Studio →
-- Authentication → Add user, or the Admin API; this SQL cannot create
-- auth.users):
--     driver  : demo-driver@local.test
--     carrier : demo-carrier-admin@local.test
--
-- What it wires (sentinel UUIDs, prefix dede…):
--   * dev tenant + one carrier org + one buyer org
--   * demo driver: active profile, org-scoped `driver` role, active membership
--   * demo carrier admin: active profile, org-scoped `carrier_admin` role,
--     active membership (for the carrier_assign_driver RPC path)
--   * one RELEASED dispatch (id dede0000-0000-4000-8000-000000000301)
--   * the driver assigned to that dispatch, execution_status = 'assigned'
--
-- Apply (LOCAL only):
--   psql "postgresql://postgres:postgres@127.0.0.1:54322/postgres" \
--        -v ON_ERROR_STOP=1 -f 23-DATABASE/seeds/local_driver_e2e_demo.sql
--
-- NOTE on the earlier version: assigning session_replication_role via
-- set_config(...) INSIDE a DO/plpgsql block is denied for the non-superuser
-- local `postgres` role. This version does the FK-sensitive inserts at the top
-- level, where SET session_replication_role IS permitted for that role.
-- ###########################################################################

-- Sentinel identifiers (fixed, recognisable, demo-only):
--   tenant   dede0000-0000-4000-8000-000000000001
--   carrier  dede0000-0000-4000-8000-000000000101
--   buyer    dede0000-0000-4000-8000-000000000102
--   booking  dede0000-0000-4000-8000-000000000201
--   dispatch dede0000-0000-4000-8000-000000000301

-- ---------------------------------------------------------------------------
-- 1. Tenant + orgs (guarded on the demo users existing; idempotent).
-- ---------------------------------------------------------------------------
insert into identity.tenants (id, code, name_fa, name_en, country_code, status)
select 'dede0000-0000-4000-8000-000000000001', 'ikia-local-e2e', 'تننت دمو محلی', 'Local E2E Tenant', 'IR', 'active'
where exists (select 1 from auth.users where email in ('demo-driver@local.test','demo-carrier-admin@local.test'))
on conflict (id) do nothing;

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status, country_code)
select v.id, 'dede0000-0000-4000-8000-000000000001', v.code, v.name_fa, v.name_en,
       v.type::organization.organization_type, 'active', 'IR'
from (values
  ('dede0000-0000-4000-8000-000000000101'::uuid, 'local-carrier', 'حمل‌کننده دمو', 'Demo Carrier', 'carrier'),
  ('dede0000-0000-4000-8000-000000000102'::uuid, 'local-buyer',   'خریدار دمو',    'Demo Buyer',   'buyer')
) as v(id, code, name_fa, name_en, type)
where exists (select 1 from auth.users where email = 'demo-driver@local.test')
on conflict (id) do nothing;

-- ---------------------------------------------------------------------------
-- 2. Demo driver identity: active profile, org-scoped driver role, membership.
-- ---------------------------------------------------------------------------
insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status)
select u.id, 'dede0000-0000-4000-8000-000000000001', 'dede0000-0000-4000-8000-000000000101', 'راننده دمو', 'fa', 'active'
from auth.users u where u.email = 'demo-driver@local.test'
on conflict (id) do update
  set tenant_id = excluded.tenant_id,
      primary_organization_id = excluded.primary_organization_id,
      status = 'active';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id, granted_at)
select u.id, r.id, 'organization', 'dede0000-0000-4000-8000-000000000101', now()
from auth.users u cross join identity.roles r
where u.email = 'demo-driver@local.test' and r.code = 'driver'
  and not exists (
    select 1 from identity.user_roles x
     where x.user_id = u.id and x.role_id = r.id
       and x.scope_type = 'organization' and x.scope_id = 'dede0000-0000-4000-8000-000000000101'
       and x.revoked_at is null and x.deleted_at is null);

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select 'dede0000-0000-4000-8000-000000000001', 'dede0000-0000-4000-8000-000000000101', u.id, r.id, 'active', now()
from auth.users u cross join identity.roles r
where u.email = 'demo-driver@local.test' and r.code = 'driver'
on conflict (organization_id, user_id, role_id) do nothing;

-- ---------------------------------------------------------------------------
-- 3. Demo carrier admin identity (for the carrier_assign_driver RPC path).
-- ---------------------------------------------------------------------------
insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status)
select u.id, 'dede0000-0000-4000-8000-000000000001', 'dede0000-0000-4000-8000-000000000101', 'مدیر حمل دمو', 'fa', 'active'
from auth.users u where u.email = 'demo-carrier-admin@local.test'
on conflict (id) do nothing;

insert into identity.user_roles (user_id, role_id, scope_type, scope_id, granted_at)
select u.id, r.id, 'organization', 'dede0000-0000-4000-8000-000000000101', now()
from auth.users u cross join identity.roles r
where u.email = 'demo-carrier-admin@local.test' and r.code = 'carrier_admin'
  and not exists (
    select 1 from identity.user_roles x
     where x.user_id = u.id and x.role_id = r.id
       and x.scope_type = 'organization' and x.scope_id = 'dede0000-0000-4000-8000-000000000101'
       and x.revoked_at is null and x.deleted_at is null);

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select 'dede0000-0000-4000-8000-000000000001', 'dede0000-0000-4000-8000-000000000101', u.id, r.id, 'active', now()
from auth.users u cross join identity.roles r
where u.email = 'demo-carrier-admin@local.test' and r.code = 'carrier_admin'
on conflict (organization_id, user_id, role_id) do nothing;

-- ---------------------------------------------------------------------------
-- 4. Released dispatch + backing booking. FK-sensitive: the booking's own
--    upstream FKs (shipment / capacity) are bypassed by briefly disabling
--    triggers via top-level session_replication_role (LOCAL postgres may do
--    this at the top level; it may NOT inside a DO block). Reset immediately.
--    Guarded on the demo driver existing so it is a clean no-op otherwise.
-- ---------------------------------------------------------------------------
set session_replication_role = replica;

insert into marketplace.booking_requests
  (id, tenant_id, shipment_id, capacity_listing_id, buyer_organization_id, carrier_organization_id, status)
select 'dede0000-0000-4000-8000-000000000201', 'dede0000-0000-4000-8000-000000000001',
       gen_random_uuid(), gen_random_uuid(),
       'dede0000-0000-4000-8000-000000000102', 'dede0000-0000-4000-8000-000000000101', 'draft'
where exists (select 1 from auth.users where email = 'demo-driver@local.test')
on conflict (id) do nothing;

insert into dispatch.dispatch_assignments
  (id, tenant_id, booking_request_id, buyer_organization_id, carrier_organization_id,
   status, driver_user_id, execution_status, planned_pickup_at, vehicle_reference)
select 'dede0000-0000-4000-8000-000000000301', 'dede0000-0000-4000-8000-000000000001',
       'dede0000-0000-4000-8000-000000000201',
       'dede0000-0000-4000-8000-000000000102', 'dede0000-0000-4000-8000-000000000101',
       'released', (select id from auth.users where email = 'demo-driver@local.test'),
       'assigned', now() + interval '1 day', 'DEMO-TRUCK-01'
where exists (select 1 from auth.users where email = 'demo-driver@local.test')
on conflict (id) do update
  set driver_user_id   = excluded.driver_user_id,
      execution_status = 'assigned',
      status           = 'released',
      updated_at       = now();

set session_replication_role = default;

-- ---------------------------------------------------------------------------
-- 5. Readiness notice.
-- ---------------------------------------------------------------------------
do $$
declare v_driver uuid; v_admin uuid; v_dispatch_ok boolean;
begin
  select id into v_driver from auth.users where email = 'demo-driver@local.test';
  select id into v_admin  from auth.users where email = 'demo-carrier-admin@local.test';
  select exists (select 1 from dispatch.dispatch_assignments
                  where id = 'dede0000-0000-4000-8000-000000000301'
                    and driver_user_id = v_driver) into v_dispatch_ok;
  if v_driver is null or v_admin is null then
    raise notice 'local_driver_e2e_demo: NO-OP — demo auth users missing (driver=%, admin=%). Create demo-driver@local.test and demo-carrier-admin@local.test via Studio/Admin API, then re-run.', v_driver, v_admin;
  else
    raise notice 'local_driver_e2e_demo: ready. dispatch=dede0000-0000-4000-8000-000000000301 assigned=% driver=% carrier_admin=%', v_dispatch_ok, v_driver, v_admin;
  end if;
end $$;
