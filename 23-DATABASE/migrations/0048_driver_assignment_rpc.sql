-- ===========================================================================
-- 0048 — Driver assignment RPC (v1.1 Phase B foundation)
-- ===========================================================================
-- Additive, idempotent (create-or-replace functions only; no schema/table
-- changes). Closes the MVP gap where dispatch.dispatch_assignments.driver_user_id
-- could only be set by direct SQL: there was no carrier/admin application path
-- to assign a real driver to a dispatch.
--
-- Adds:
--   * dispatch.carrier_assign_driver(uuid, uuid)          — assign / re-assign
--   * dispatch.carrier_list_assignable_drivers(uuid)      — pick-list helper
--
-- Security posture (both functions):
--   * SECURITY DEFINER, set search_path = '', every object schema-qualified.
--   * Authorization reuses dispatch.fn_assert_carrier_for_dispatch, i.e.
--     carrier_admin / organization_admin on the dispatch's carrier org, or
--     platform_admin. operations_user is intentionally NOT granted assignment
--     rights here — that matches the existing dispatch write RPC convention
--     (carrier_release/cancel). Revisit if ops-initiated assignment is needed.
--   * EXECUTE granted to `authenticated` only; no table write grants added.
--
-- Lifecycle rules (documented):
--   * A driver may be assigned only while the dispatch is in a pre-execution
--     lifecycle state: 'assigned', 'ready' or 'released'. 'draft' is too early
--     (not yet an operational dispatch) and 'cancelled' is terminal.
--   * The driver may NOT be changed once the trip has actually started: allowed
--     only when execution_status is null or 'assigned' (i.e. not yet accepted).
--   * execution_status is initialised to 'assigned' on first assignment and is
--     otherwise preserved (never downgraded).
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- carrier_assign_driver — assign (or re-assign, pre-start) a driver.
-- Returns the resulting assignment snapshot as a single row.
-- ---------------------------------------------------------------------------
create or replace function dispatch.carrier_assign_driver(
  p_dispatch_id    uuid,
  p_driver_user_id uuid
)
returns table (
  dispatch_id      uuid,
  driver_user_id   uuid,
  execution_status dispatch.trip_execution_status,
  status           dispatch.dispatch_status,
  updated_at       timestamptz
)
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor       uuid := auth.uid();
  v_status      dispatch.dispatch_status;
  v_carrier     uuid;
  v_exec        dispatch.trip_execution_status;
  v_prev_driver uuid;
begin
  -- (1) Authentication.
  if v_actor is null then
    raise exception 'dispatch: authentication required' using errcode = '42501';
  end if;
  if p_dispatch_id is null or p_driver_user_id is null then
    raise exception 'dispatch: dispatch id and driver id are required'
      using errcode = '22004';
  end if;

  -- (2)+(3) Caller authorization: carrier_admin / organization_admin on the
  -- dispatch's carrier org, or platform_admin. Returns the current status and
  -- raises 42501 / P0002 otherwise. Also proves the dispatch exists.
  v_status := dispatch.fn_assert_carrier_for_dispatch(p_dispatch_id);

  select da.carrier_organization_id, da.execution_status, da.driver_user_id
    into v_carrier, v_exec, v_prev_driver
    from dispatch.dispatch_assignments da
   where da.id = p_dispatch_id and da.deleted_at is null;

  -- (5) Dispatch lifecycle gate.
  if v_status not in ('assigned', 'ready', 'released') then
    raise exception
      'dispatch: cannot assign a driver while dispatch status is % (allowed: assigned, ready, released)',
      v_status using errcode = 'P0001';
  end if;

  -- (7) Re-assignment guard — never rebind once the trip has started.
  if v_exec is not null and v_exec <> 'assigned' then
    raise exception
      'dispatch: driver cannot be changed after the trip has started (execution_status=%)',
      v_exec using errcode = 'P0001';
  end if;

  -- (4) Target driver validation ------------------------------------------
  if not exists (select 1 from auth.users u where u.id = p_driver_user_id) then
    raise exception 'dispatch: target driver user not found' using errcode = 'P0002';
  end if;

  if not exists (
    select 1 from identity.user_profiles up
     where up.id = p_driver_user_id and up.status = 'active'
  ) then
    raise exception 'dispatch: target driver has no active profile'
      using errcode = 'P0001';
  end if;

  -- driver role, organization-scoped to THIS dispatch's carrier org, active.
  if not exists (
    select 1
      from identity.user_roles ur
      join identity.roles r on r.id = ur.role_id
     where ur.user_id    = p_driver_user_id
       and r.code        = 'driver'
       and ur.scope_type = 'organization'
       and ur.scope_id   = v_carrier
       and ur.revoked_at is null
       and ur.deleted_at is null
  ) then
    raise exception
      'dispatch: target user is not a driver in the dispatch carrier organization'
      using errcode = '42501';
  end if;

  -- active membership in the carrier org.
  if not exists (
    select 1 from organization.memberships m
     where m.user_id         = p_driver_user_id
       and m.organization_id = v_carrier
       and m.status          = 'active'
       and m.deleted_at is null
  ) then
    raise exception
      'dispatch: target driver has no active membership in the carrier organization'
      using errcode = '42501';
  end if;

  -- (6) Apply. execution_status preserved when set (only null / 'assigned'
  -- reach here), else initialised to 'assigned'.
  update dispatch.dispatch_assignments da
     set driver_user_id   = p_driver_user_id,
         execution_status = coalesce(da.execution_status, 'assigned'),
         updated_at       = now(),
         version          = version + 1
   where da.id = p_dispatch_id;

  -- (8) Dispatch event ledger (no status change: from = to) + audit. The
  -- notify trigger no-ops on unknown event_type, so this is side-effect safe.
  perform dispatch.fn_record_dispatch_event(
    p_dispatch_id, v_status, v_status, 'driver_assigned', 'carrier', null,
    jsonb_build_object(
      'driver_user_id',          p_driver_user_id::text,
      'previous_driver_user_id', v_prev_driver::text));
  perform dispatch.fn_audit('dispatch.driver_assigned', p_dispatch_id,
    jsonb_build_object('driver_user_id', p_driver_user_id::text));

  return query
    select da.id, da.driver_user_id, da.execution_status, da.status, da.updated_at
      from dispatch.dispatch_assignments da
     where da.id = p_dispatch_id;
end;
$$;

comment on function dispatch.carrier_assign_driver(uuid, uuid) is
  'v1.1 Phase B: carrier/admin assigns (or re-assigns, pre-start) a driver to a dispatch. Validates carrier authorization, dispatch lifecycle state, and that the target is an active org-scoped driver with active membership. SECURITY DEFINER.';

revoke all on function dispatch.carrier_assign_driver(uuid, uuid) from public;
grant execute on function dispatch.carrier_assign_driver(uuid, uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- carrier_list_assignable_drivers — pick-list of active org-scoped drivers for
-- the dispatch's carrier org. Same carrier authorization as assignment.
-- ---------------------------------------------------------------------------
create or replace function dispatch.carrier_list_assignable_drivers(
  p_dispatch_id uuid
)
returns table (
  driver_user_id  uuid,
  full_name       text,
  organization_id uuid
)
language plpgsql stable security definer set search_path = ''
as $$
declare v_carrier uuid;
begin
  -- Authorization (returns status; ignored here).
  perform dispatch.fn_assert_carrier_for_dispatch(p_dispatch_id);

  select da.carrier_organization_id into v_carrier
    from dispatch.dispatch_assignments da
   where da.id = p_dispatch_id and da.deleted_at is null;

  return query
    select distinct up.id, up.full_name, v_carrier
      from identity.user_profiles up
      join identity.user_roles ur on ur.user_id = up.id
      join identity.roles r       on r.id = ur.role_id
      join organization.memberships m
        on m.user_id = up.id and m.organization_id = v_carrier
     where up.status     = 'active'
       and r.code        = 'driver'
       and ur.scope_type = 'organization'
       and ur.scope_id   = v_carrier
       and ur.revoked_at is null
       and ur.deleted_at is null
       and m.status      = 'active'
       and m.deleted_at is null
     order by up.full_name;
end;
$$;

comment on function dispatch.carrier_list_assignable_drivers(uuid) is
  'v1.1 Phase B: lists active organization-scoped drivers eligible for assignment to a dispatch (carrier authorization required). Read-only helper for the future carrier assign-driver UI.';

revoke all on function dispatch.carrier_list_assignable_drivers(uuid) from public;
grant execute on function dispatch.carrier_list_assignable_drivers(uuid) to authenticated;
