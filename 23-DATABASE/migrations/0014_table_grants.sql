-- CC-03 / Migration 0014 — TABLE GRANTS
-- Minimum required PostgreSQL table-level grants so RLS becomes the gate
-- (instead of PostgreSQL permission denial).
--
-- Background: GRANT USAGE on schema (migration 0001) lets a role *name* a table.
-- Reading or writing rows additionally requires GRANT ... ON TABLE.
-- Without table grants every anon / authenticated query was failing with
-- "permission denied for table X" before RLS could evaluate.
--
-- Migrations 0001–0013 are not modified. Migration history stays append-only.
--
-- Constraints honored:
--   * audit.* is intentionally NOT granted to anon or authenticated.
--     Writes flow through audit.fn_audit_entity (security definer trigger);
--     reads happen via service_role only or future explicitly-granted surfaces.
--   * Minimum required surface: SELECT on every user-facing identity +
--     organization table, plus the single UPDATE used by CC-04
--     (switchOrganization → identity.user_profiles.primary_organization_id).
--     Broader DML grants (INSERT/UPDATE/DELETE on other tables) are deferred
--     until a feature actually needs them.

-- anon -----------------------------------------------------------------------
-- Grant SELECT so RLS returns 0 rows (instead of "permission denied"). No
-- CC-03/CC-04 RLS policy admits the anon role, so this is observably "no data"
-- with the same security posture as no grant — but with the cleaner failure
-- mode the user expects ("RLS row filtering, not permission denial").

grant select on identity.tenants           to anon;
grant select on identity.user_profiles     to anon;
grant select on identity.roles             to anon;
grant select on identity.permissions       to anon;
grant select on identity.role_permissions  to anon;
grant select on identity.user_roles        to anon;
grant select on organization.organizations  to anon;
grant select on organization.business_units to anon;
grant select on organization.memberships    to anon;

-- authenticated --------------------------------------------------------------
-- SELECT on every user-facing identity + organization table. RLS policies in
-- migrations 0008, 0009, 0013 filter which rows are visible per user.

grant select on identity.tenants           to authenticated;
grant select on identity.user_profiles     to authenticated;
grant select on identity.roles             to authenticated;
grant select on identity.permissions       to authenticated;
grant select on identity.role_permissions  to authenticated;
grant select on identity.user_roles        to authenticated;
grant select on organization.organizations  to authenticated;
grant select on organization.business_units to authenticated;
grant select on organization.memberships    to authenticated;

-- Writes used by CC-04 frontend (switchOrganization).
-- RLS policy user_profiles_self_update (migration 0008/0013) restricts which
-- rows authenticated may modify.
grant update on identity.user_profiles to authenticated;

-- audit.* -------------------------------------------------------------------
-- No grants. Reads are not exposed to clients. Writes use the security-definer
-- trigger audit.fn_audit_entity which runs as the function owner, bypassing
-- the caller's privilege set.
