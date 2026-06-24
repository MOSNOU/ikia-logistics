-- CC-03 / Migration 0010
-- Row Level Security policies on audit.* tables.
-- Append-only: writes via triggers (security definer) or service_role.
-- Reads gated to compliance officers in same tenant or platform admin.

alter table audit.audit_event  enable row level security;
alter table audit.audit_entity enable row level security;
alter table audit.audit_access enable row level security;

drop policy if exists audit_event_select on audit.audit_event;
create policy audit_event_select on audit.audit_event
  for select
  using (
    identity.is_platform_admin()
    or (
      identity.has_role('compliance_officer')
      and tenant_id = identity.current_tenant_id()
    )
  );

drop policy if exists audit_entity_select on audit.audit_entity;
create policy audit_entity_select on audit.audit_entity
  for select
  using (
    identity.is_platform_admin()
    or (
      identity.has_role('compliance_officer')
      and tenant_id = identity.current_tenant_id()
    )
  );

drop policy if exists audit_access_select on audit.audit_access;
create policy audit_access_select on audit.audit_access
  for select
  using (
    identity.is_platform_admin()
    or (
      identity.has_role('compliance_officer')
      and tenant_id = identity.current_tenant_id()
    )
  );

-- No insert/update/delete policies. Writes only via:
--   1) audit.fn_audit_entity trigger (security definer)
--   2) service_role (RLS bypass by default)
-- Anything else is refused by RLS.
