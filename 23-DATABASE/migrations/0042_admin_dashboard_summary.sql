-- CC-72 — identity.admin_get_dashboard_summary()
--
-- The /admin/dashboard page previously rendered four placeholder StatCards
-- (value="—") and two cards reading «پس از اتصال به پایگاه داده نمایش
-- داده می‌شود». This migration adds a single narrow SECURITY DEFINER RPC
-- that lets the admin landing page show real, production-truthful values
-- without exposing any catalog SELECTs.
--
-- The RPC:
--   • derives the caller from the JWT (identity.is_platform_admin()),
--   • takes no parameters at all (no tenant, no scope override),
--   • returns a single jsonb document with platform-wide counts and a
--     short list of the most recent audit events,
--   • bypasses RLS only on the read paths it explicitly needs,
--   • is callable only by the `authenticated` role.
--
-- Additive only. No table or RLS change.

begin;

create or replace function identity.admin_get_dashboard_summary()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_orgs          int;
  v_users         int;
  v_suppliers     int;
  v_audit_24h     int;
  v_audit_events  jsonb;
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_get_dashboard_summary: platform_admin role required'
      using errcode = '42501';
  end if;

  select count(*)::int into v_orgs
    from organization.organizations
   where deleted_at is null;

  select count(*)::int into v_users
    from identity.user_profiles
   where status = 'active' and deleted_at is null;

  select count(*)::int into v_suppliers
    from supplier.suppliers;

  select count(*)::int into v_audit_24h
    from audit.audit_event
   where occurred_at >= now() - interval '24 hours';

  select coalesce(jsonb_agg(row_to_json(e)::jsonb), '[]'::jsonb)
    into v_audit_events
    from (
      select e.id,
             e.occurred_at,
             e.action_code,
             e.resource_type,
             e.organization_id
        from audit.audit_event e
       order by e.occurred_at desc
       limit 5
    ) e;

  return jsonb_build_object(
    'organizationsCount',     v_orgs,
    'activeUsersCount',       v_users,
    'suppliersCount',         v_suppliers,
    'recentAuditEventsCount', v_audit_24h,
    'recentAuditEvents',      v_audit_events
  );
end;
$$;

comment on function identity.admin_get_dashboard_summary() is
  'CC-72: SECURITY DEFINER summary used by the /admin/dashboard server component. Returns platform-wide counts (organizations, active users, suppliers, audit events in last 24h) plus the 5 most recent audit events as jsonb. No parameters — caller must satisfy identity.is_platform_admin() or the function raises 42501.';

revoke all   on function identity.admin_get_dashboard_summary() from public;
revoke all   on function identity.admin_get_dashboard_summary() from anon;
grant execute on function identity.admin_get_dashboard_summary() to authenticated;

commit;
