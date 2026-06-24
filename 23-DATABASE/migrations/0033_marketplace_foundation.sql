-- CC-39 / Migration 0033 — Capacity & Carrier Marketplace Foundation
-- Backs the CC-38 frontend stubs with real data primitives.
-- Append-only over migrations 0001-0032. Touches notify schema only by adding
-- one new trigger function on a NEW marketplace table — no existing notify
-- logic is modified.
--
-- Locked decisions (CC-39 Q1–Q10):
--   Q1 = schema name `marketplace`
--   Q2 = extension table over organization.organizations
--   Q3 = carrier-only ownership (organization.type='carrier' check via trigger)
--   Q4 = opt-in directory visibility (carrier_directory_visibility table)
--   Q5 = country_code (citext) + city (text), matching shipment addresses
--   Q6 = no pricing fields (notes only)
--   Q7 = enforced 5-state lifecycle: draft → active → reserved → expired → archived
--   Q8 = notify on publish + archive only (one notify trigger, two event types)
--   Q9 = admin archive-only moderation (no admin content edits)
--   Q10 = no seed data
--
-- Out of scope: booking/matching/dispatch automation, pricing/FX, shipment-FK
-- binding, rich-media profiles, frontend wiring (deferred to CC-40).
--
-- Security model: SECURITY DEFINER RPCs only; no direct write grants;
-- search_path = ''.

-- ===========================================================================
-- 1. Schema
-- ===========================================================================
create schema if not exists marketplace;
grant usage on schema marketplace to anon, authenticated, service_role;
comment on schema marketplace is
  'iKIA Phase 2 — capacity & carrier marketplace foundation. Visibility-only; no booking/matching/pricing/dispatch.';

-- ===========================================================================
-- 2. Enums (2)
-- ===========================================================================
create type marketplace.carrier_profile_status as enum (
  'draft', 'active', 'suspended', 'archived'
);

create type marketplace.capacity_status as enum (
  'draft', 'active', 'reserved', 'expired', 'archived'
);

-- ===========================================================================
-- 3. Tables (4)
-- ===========================================================================

-- 3.1 carrier_profiles -----------------------------------------------------
create table marketplace.carrier_profiles (
  id                          uuid primary key default gen_random_uuid(),
  tenant_id                   uuid not null references identity.tenants(id) on delete restrict,
  organization_id             uuid not null references organization.organizations(id) on delete cascade,

  display_name_fa             text,
  display_name_en             text,
  bio_fa                      text,
  bio_en                      text,
  transport_modes             shipment.transport_mode[] not null default '{}'::shipment.transport_mode[],
  service_country_codes       citext[] not null default '{}'::public.citext[],
  fleet_size_hint             integer,
  status                      marketplace.carrier_profile_status not null default 'draft',

  created_by                  uuid references auth.users(id),
  created_at                  timestamptz not null default now(),
  updated_by                  uuid references auth.users(id),
  updated_at                  timestamptz not null default now(),
  deleted_at                  timestamptz,

  constraint carrier_profiles_one_per_org unique (organization_id)
);

comment on table marketplace.carrier_profiles is
  'One profile per carrier organization (organization_type=carrier). Extension over organization.organizations.';

create index carrier_profiles_tenant_idx on marketplace.carrier_profiles(tenant_id);
create index carrier_profiles_status_idx on marketplace.carrier_profiles(status);

-- 3.2 carrier_directory_visibility -----------------------------------------
create table marketplace.carrier_directory_visibility (
  carrier_organization_id     uuid primary key references organization.organizations(id) on delete cascade,
  tenant_id                   uuid not null references identity.tenants(id) on delete restrict,
  is_public                   boolean not null default false,
  published_at                timestamptz,

  created_by                  uuid references auth.users(id),
  created_at                  timestamptz not null default now(),
  updated_by                  uuid references auth.users(id),
  updated_at                  timestamptz not null default now()
);

comment on table marketplace.carrier_directory_visibility is
  'Opt-in directory visibility flag per carrier org. Default-hidden until carrier_admin flips is_public=true.';

create index carrier_directory_visibility_tenant_idx on marketplace.carrier_directory_visibility(tenant_id);

-- 3.3 capacity_listings ----------------------------------------------------
create table marketplace.capacity_listings (
  id                          uuid primary key default gen_random_uuid(),
  tenant_id                   uuid not null references identity.tenants(id) on delete restrict,
  carrier_organization_id     uuid not null references organization.organizations(id) on delete cascade,
  published_by_user_id        uuid references auth.users(id),

  transport_mode              shipment.transport_mode not null,
  origin_country_code         citext,
  origin_city                 text,
  destination_country_code    citext,
  destination_city            text,

  capacity_units              numeric,
  capacity_unit_label         text,

  valid_from                  timestamptz,
  valid_until                 timestamptz,

  status                      marketplace.capacity_status not null default 'draft',
  notes_fa                    text,
  notes_en                    text,

  created_by                  uuid references auth.users(id),
  created_at                  timestamptz not null default now(),
  updated_by                  uuid references auth.users(id),
  updated_at                  timestamptz not null default now(),
  deleted_at                  timestamptz
);

comment on table marketplace.capacity_listings is
  'Publishable capacity. Carrier-org-owned. Visibility = active status + carrier_directory_visibility.is_public. No pricing.';

create index capacity_listings_carrier_status_idx
  on marketplace.capacity_listings(carrier_organization_id, status);
create index capacity_listings_status_valid_idx
  on marketplace.capacity_listings(status, valid_until);
create index capacity_listings_route_idx
  on marketplace.capacity_listings(transport_mode, origin_country_code, destination_country_code);

-- 3.4 capacity_status_events (immutable ledger) ----------------------------
create table marketplace.capacity_status_events (
  id                          uuid primary key default gen_random_uuid(),
  tenant_id                   uuid not null references identity.tenants(id) on delete restrict,
  capacity_listing_id         uuid not null references marketplace.capacity_listings(id) on delete cascade,

  from_status                 marketplace.capacity_status,
  to_status                   marketplace.capacity_status not null,
  reason                      text,
  actor_user_id               uuid references auth.users(id),
  actor_organization_id       uuid references organization.organizations(id) on delete set null,
  payload                     jsonb not null default '{}'::jsonb,

  created_at                  timestamptz not null default now()
);

comment on table marketplace.capacity_status_events is
  'Immutable status-change ledger. Feeds admin_list_activity and audit trail. INSERT only via SECURITY DEFINER helper.';

create index capacity_status_events_listing_idx
  on marketplace.capacity_status_events(capacity_listing_id, created_at desc);
create index capacity_status_events_created_idx
  on marketplace.capacity_status_events(created_at desc);

-- ===========================================================================
-- 4. Internal helpers
-- ===========================================================================

-- 4.1 fn_audit -------------------------------------------------------------
create or replace function marketplace.fn_audit(
  p_action_code   text,
  p_resource_id   uuid,
  p_resource_type text default 'capacity_listing',
  p_payload       jsonb default '{}'::jsonb
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare v_t uuid; v_o uuid;
begin
  if p_resource_type = 'capacity_listing' then
    select tenant_id, carrier_organization_id into v_t, v_o
      from marketplace.capacity_listings where id = p_resource_id;
  elsif p_resource_type = 'carrier_profile' then
    select tenant_id, organization_id into v_t, v_o
      from marketplace.carrier_profiles where id = p_resource_id;
  end if;
  insert into audit.audit_event (
    tenant_id, organization_id, actor_user_id, action_code,
    resource_type, resource_id, payload, occurred_at
  ) values (
    v_t, v_o, auth.uid(), p_action_code,
    p_resource_type, p_resource_id, p_payload, now()
  );
exception when others then
  null;
end;
$$;

-- 4.2 fn_assert_carrier_org_type -------------------------------------------
-- Enforces Q3=carrier-only ownership. Used by RPCs and by the carrier_profiles
-- INSERT/UPDATE trigger.
create or replace function marketplace.fn_assert_carrier_org_type(p_org_id uuid)
returns void
language plpgsql stable security definer set search_path = ''
as $$
declare v_type organization.organization_type;
begin
  select type into v_type from organization.organizations
   where id = p_org_id and deleted_at is null;
  if v_type is null then
    raise exception 'marketplace: organization not found' using errcode = 'P0002';
  end if;
  if v_type <> 'carrier' then
    raise exception 'marketplace: organization must be of type carrier (got %)', v_type
      using errcode = '22023';
  end if;
end;
$$;

-- 4.3 fn_assert_carrier_actor ----------------------------------------------
-- Caller must be platform_admin OR an active member of the carrier org with
-- carrier_admin / organization_admin role.
create or replace function marketplace.fn_assert_carrier_actor(p_org_id uuid)
returns void
language plpgsql stable security definer set search_path = ''
as $$
declare v_caller_org uuid := identity.current_organization_id();
begin
  if identity.is_platform_admin() then return; end if;
  if not (identity.has_role('carrier_admin') or identity.has_role('organization_admin')) then
    raise exception 'marketplace: requires carrier_admin / organization_admin / platform_admin'
      using errcode = '42501';
  end if;
  if v_caller_org is null or v_caller_org <> p_org_id then
    raise exception 'marketplace: caller org does not own this carrier' using errcode = '42501';
  end if;
end;
$$;

-- 4.4 fn_record_capacity_event ---------------------------------------------
create or replace function marketplace.fn_record_capacity_event(
  p_listing_id uuid,
  p_from       marketplace.capacity_status,
  p_to         marketplace.capacity_status,
  p_reason     text default null,
  p_payload    jsonb default '{}'::jsonb
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare v_t uuid; v_o uuid;
begin
  select tenant_id, carrier_organization_id into v_t, v_o
    from marketplace.capacity_listings where id = p_listing_id;
  insert into marketplace.capacity_status_events (
    tenant_id, capacity_listing_id, from_status, to_status,
    reason, actor_user_id, actor_organization_id, payload
  ) values (
    v_t, p_listing_id, p_from, p_to,
    p_reason, auth.uid(), v_o, coalesce(p_payload, '{}'::jsonb)
  );
end;
$$;

-- 4.5 Trigger fn enforcing carrier-only ownership on carrier_profiles ------
create or replace function marketplace.fn_trg_assert_carrier_profile_org()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  perform marketplace.fn_assert_carrier_org_type(new.organization_id);
  return new;
end;
$$;

drop trigger if exists trg_carrier_profile_org_type on marketplace.carrier_profiles;
create trigger trg_carrier_profile_org_type
  before insert or update of organization_id on marketplace.carrier_profiles
  for each row execute function marketplace.fn_trg_assert_carrier_profile_org();

-- 4.6 Trigger fn enforcing carrier-only ownership on capacity_listings -----
create or replace function marketplace.fn_trg_assert_capacity_org()
returns trigger language plpgsql security definer set search_path = ''
as $$
begin
  perform marketplace.fn_assert_carrier_org_type(new.carrier_organization_id);
  return new;
end;
$$;

drop trigger if exists trg_capacity_carrier_org on marketplace.capacity_listings;
create trigger trg_capacity_carrier_org
  before insert or update of carrier_organization_id on marketplace.capacity_listings
  for each row execute function marketplace.fn_trg_assert_capacity_org();

-- 4.7 notify dispatch trigger ---------------------------------------------
-- Q8: emit notifications only for publish and archive transitions.
-- Hooks into the existing notify.fn_materialize_event infrastructure (CC-19/
-- CC-26). When no notification_templates row matches the event types
-- `capacity.published` or `capacity.archived`, notify.fn_materialize_event
-- gracefully logs `no_template_matched` and no-ops; templates can be seeded
-- in a later CC without changing this trigger.
create or replace function notify.fn_trg_from_capacity_listing()
returns trigger language plpgsql security definer set search_path = ''
as $$
declare v_event text;
begin
  if (tg_op = 'INSERT' and new.status = 'active') then
    v_event := 'capacity.published';
  elsif (tg_op = 'UPDATE' and old.status is distinct from new.status) then
    if new.status = 'active' and old.status <> 'active' then
      v_event := 'capacity.published';
    elsif new.status = 'archived' then
      v_event := 'capacity.archived';
    end if;
  end if;
  if v_event is null then return new; end if;
  -- Q8 note: notification_category enum does not yet contain 'marketplace';
  -- routing through 'other' keeps the dispatch deterministic without touching
  -- the notify enum. A later notify-extension CC can introduce a dedicated
  -- 'marketplace' category and re-target this trigger; the event types stay
  -- stable so template matching is unaffected.
  perform notify.fn_materialize_event(
    v_event,
    'capacity_listing',
    new.id,
    null::uuid,
    'other'::notify.notification_category,
    jsonb_build_object(
      'carrier_organization_id', new.carrier_organization_id,
      'transport_mode', new.transport_mode,
      'status', new.status
    ),
    new.tenant_id
  );
  return new;
exception when others then
  -- Never block the upstream marketplace write on a notify failure.
  return new;
end;
$$;

drop trigger if exists trg_capacity_notify on marketplace.capacity_listings;
create trigger trg_capacity_notify
  after insert or update of status on marketplace.capacity_listings
  for each row execute function notify.fn_trg_from_capacity_listing();

-- ===========================================================================
-- 5. Row Level Security
-- ===========================================================================
alter table marketplace.carrier_profiles                 enable row level security;
alter table marketplace.carrier_directory_visibility     enable row level security;
alter table marketplace.capacity_listings                enable row level security;
alter table marketplace.capacity_status_events           enable row level security;

-- 5.1 carrier_profiles -----------------------------------------------------
drop policy if exists carrier_profiles_select on marketplace.carrier_profiles;
create policy carrier_profiles_select on marketplace.carrier_profiles
  for select
  using (
    deleted_at is null
    and (
      identity.is_platform_admin()
      or exists (
        select 1 from organization.memberships m
         where m.user_id = identity.current_user_id()
           and m.organization_id = marketplace.carrier_profiles.organization_id
           and m.deleted_at is null and m.status = 'active'
      )
      or (
        marketplace.carrier_profiles.status = 'active'
        and exists (
          select 1 from marketplace.carrier_directory_visibility v
           where v.carrier_organization_id = marketplace.carrier_profiles.organization_id
             and v.is_public = true
        )
      )
    )
  );

drop policy if exists carrier_profiles_admin_modify on marketplace.carrier_profiles;
create policy carrier_profiles_admin_modify on marketplace.carrier_profiles
  for all using (identity.is_platform_admin()) with check (identity.is_platform_admin());

-- 5.2 carrier_directory_visibility -----------------------------------------
drop policy if exists carrier_directory_visibility_select on marketplace.carrier_directory_visibility;
create policy carrier_directory_visibility_select on marketplace.carrier_directory_visibility
  for select
  using (
    identity.is_platform_admin()
    or is_public = true
    or exists (
      select 1 from organization.memberships m
       where m.user_id = identity.current_user_id()
         and m.organization_id = marketplace.carrier_directory_visibility.carrier_organization_id
         and m.deleted_at is null and m.status = 'active'
    )
  );

drop policy if exists carrier_directory_visibility_admin_modify on marketplace.carrier_directory_visibility;
create policy carrier_directory_visibility_admin_modify on marketplace.carrier_directory_visibility
  for all using (identity.is_platform_admin()) with check (identity.is_platform_admin());

-- 5.3 capacity_listings ----------------------------------------------------
drop policy if exists capacity_listings_select on marketplace.capacity_listings;
create policy capacity_listings_select on marketplace.capacity_listings
  for select
  using (
    deleted_at is null
    and (
      identity.is_platform_admin()
      or exists (
        select 1 from organization.memberships m
         where m.user_id = identity.current_user_id()
           and m.organization_id = marketplace.capacity_listings.carrier_organization_id
           and m.deleted_at is null and m.status = 'active'
      )
      or (
        marketplace.capacity_listings.status = 'active'
        and exists (
          select 1 from marketplace.carrier_directory_visibility v
           where v.carrier_organization_id = marketplace.capacity_listings.carrier_organization_id
             and v.is_public = true
        )
      )
    )
  );

drop policy if exists capacity_listings_admin_modify on marketplace.capacity_listings;
create policy capacity_listings_admin_modify on marketplace.capacity_listings
  for all using (identity.is_platform_admin()) with check (identity.is_platform_admin());

-- 5.4 capacity_status_events (immutable) -----------------------------------
drop policy if exists capacity_status_events_select on marketplace.capacity_status_events;
create policy capacity_status_events_select on marketplace.capacity_status_events
  for select
  using (
    exists (
      select 1 from marketplace.capacity_listings cl
       where cl.id = marketplace.capacity_status_events.capacity_listing_id
         and (
           identity.is_platform_admin()
           or exists (
             select 1 from organization.memberships m
              where m.user_id = identity.current_user_id()
                and m.organization_id = cl.carrier_organization_id
                and m.deleted_at is null and m.status = 'active'
           )
         )
    )
  );

-- ===========================================================================
-- 6. RPCs
-- ===========================================================================

-- 6.1 carrier_upsert_profile ----------------------------------------------
create or replace function marketplace.carrier_upsert_profile(
  p_organization_id           uuid,
  p_display_name_fa           text default null,
  p_display_name_en           text default null,
  p_bio_fa                    text default null,
  p_bio_en                    text default null,
  p_transport_modes           shipment.transport_mode[] default null,
  p_service_country_codes     citext[] default null,
  p_fleet_size_hint           integer default null,
  p_status                    marketplace.carrier_profile_status default null,
  p_profile_id                uuid default null
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_tenant uuid;
  v_id uuid;
begin
  perform marketplace.fn_assert_carrier_org_type(p_organization_id);
  perform marketplace.fn_assert_carrier_actor(p_organization_id);

  select tenant_id into v_tenant from organization.organizations where id = p_organization_id;

  if p_profile_id is null then
    insert into marketplace.carrier_profiles (
      tenant_id, organization_id,
      display_name_fa, display_name_en, bio_fa, bio_en,
      transport_modes, service_country_codes, fleet_size_hint,
      status, created_by, updated_by
    ) values (
      v_tenant, p_organization_id,
      p_display_name_fa, p_display_name_en, p_bio_fa, p_bio_en,
      coalesce(p_transport_modes, '{}'::shipment.transport_mode[]),
      coalesce(p_service_country_codes, '{}'::public.citext[]),
      p_fleet_size_hint,
      coalesce(p_status, 'draft'),
      v_actor, v_actor
    )
    on conflict (organization_id) do update set
      display_name_fa       = coalesce(excluded.display_name_fa, marketplace.carrier_profiles.display_name_fa),
      display_name_en       = coalesce(excluded.display_name_en, marketplace.carrier_profiles.display_name_en),
      bio_fa                = coalesce(excluded.bio_fa, marketplace.carrier_profiles.bio_fa),
      bio_en                = coalesce(excluded.bio_en, marketplace.carrier_profiles.bio_en),
      transport_modes       = excluded.transport_modes,
      service_country_codes = excluded.service_country_codes,
      fleet_size_hint       = coalesce(excluded.fleet_size_hint, marketplace.carrier_profiles.fleet_size_hint),
      status                = coalesce(excluded.status, marketplace.carrier_profiles.status),
      updated_by            = v_actor,
      updated_at            = now()
    returning id into v_id;
  else
    update marketplace.carrier_profiles
       set display_name_fa       = coalesce(p_display_name_fa, display_name_fa),
           display_name_en       = coalesce(p_display_name_en, display_name_en),
           bio_fa                = coalesce(p_bio_fa, bio_fa),
           bio_en                = coalesce(p_bio_en, bio_en),
           transport_modes       = coalesce(p_transport_modes, transport_modes),
           service_country_codes = coalesce(p_service_country_codes, service_country_codes),
           fleet_size_hint       = coalesce(p_fleet_size_hint, fleet_size_hint),
           status                = coalesce(p_status, status),
           updated_by            = v_actor,
           updated_at            = now()
     where id = p_profile_id and organization_id = p_organization_id and deleted_at is null
    returning id into v_id;
    if v_id is null then
      raise exception 'marketplace: profile not found' using errcode = 'P0002';
    end if;
  end if;

  perform marketplace.fn_audit('marketplace.carrier_profile_upserted', v_id,
    'carrier_profile', jsonb_build_object('organization_id', p_organization_id::text));
  return v_id;
end;
$$;

-- 6.2 carrier_set_directory_visibility ------------------------------------
create or replace function marketplace.carrier_set_directory_visibility(
  p_organization_id uuid,
  p_is_public       boolean
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_tenant uuid;
begin
  perform marketplace.fn_assert_carrier_org_type(p_organization_id);
  perform marketplace.fn_assert_carrier_actor(p_organization_id);
  select tenant_id into v_tenant from organization.organizations where id = p_organization_id;

  insert into marketplace.carrier_directory_visibility (
    carrier_organization_id, tenant_id, is_public,
    published_at, created_by, updated_by
  ) values (
    p_organization_id, v_tenant, coalesce(p_is_public, false),
    case when p_is_public then now() else null end, v_actor, v_actor
  )
  on conflict (carrier_organization_id) do update set
    is_public    = excluded.is_public,
    published_at = case when excluded.is_public and marketplace.carrier_directory_visibility.published_at is null
                          then now()
                        else marketplace.carrier_directory_visibility.published_at end,
    updated_by   = v_actor,
    updated_at   = now();
end;
$$;

-- 6.3 buyer_list_carriers --------------------------------------------------
create or replace function marketplace.buyer_list_carriers(
  p_country         citext default null,
  p_transport_mode  shipment.transport_mode default null,
  p_search          text default null,
  p_limit           integer default 25,
  p_offset          integer default 0
) returns table (
  id uuid, organization_id uuid,
  code citext, name_fa text, name_en text,
  display_name_fa text, display_name_en text,
  status marketplace.carrier_profile_status,
  transport_modes shipment.transport_mode[],
  service_country_codes citext[],
  country_code citext, created_at timestamptz
)
language plpgsql stable security definer set search_path = ''
as $$
begin
  return query
    select cp.id, cp.organization_id,
           o.code, o.name_fa, o.name_en,
           cp.display_name_fa, cp.display_name_en,
           cp.status, cp.transport_modes, cp.service_country_codes,
           o.country_code::public.citext, cp.created_at
      from marketplace.carrier_profiles cp
      join organization.organizations o on o.id = cp.organization_id
      join marketplace.carrier_directory_visibility v
        on v.carrier_organization_id = cp.organization_id and v.is_public = true
     where cp.deleted_at is null
       and cp.status = 'active'
       and (p_country is null or p_country = any(cp.service_country_codes))
       and (p_transport_mode is null or p_transport_mode = any(cp.transport_modes))
       and (
         p_search is null or btrim(p_search) = ''
         or o.name_fa ilike '%' || p_search || '%'
         or o.name_en ilike '%' || p_search || '%'
         or o.code   ilike '%' || p_search || '%'
       )
     order by cp.created_at desc
     limit p_limit offset p_offset;
end;
$$;

-- 6.4 buyer_get_carrier ----------------------------------------------------
create or replace function marketplace.buyer_get_carrier(p_carrier_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
begin
  return (
    select jsonb_build_object(
      'id', cp.id, 'organization_id', cp.organization_id,
      'code', o.code, 'name_fa', o.name_fa, 'name_en', o.name_en,
      'display_name_fa', cp.display_name_fa, 'display_name_en', cp.display_name_en,
      'bio_fa', cp.bio_fa, 'bio_en', cp.bio_en,
      'transport_modes', cp.transport_modes,
      'service_country_codes', cp.service_country_codes,
      'fleet_size_hint', cp.fleet_size_hint,
      'status', cp.status,
      'country_code', o.country_code,
      'created_at', cp.created_at, 'updated_at', cp.updated_at
    )
    from marketplace.carrier_profiles cp
    join organization.organizations o on o.id = cp.organization_id
    join marketplace.carrier_directory_visibility v
      on v.carrier_organization_id = cp.organization_id and v.is_public = true
   where cp.id = p_carrier_id and cp.deleted_at is null and cp.status = 'active'
  );
end;
$$;

-- 6.5 admin_list_carriers --------------------------------------------------
create or replace function marketplace.admin_list_carriers(
  p_status  marketplace.carrier_profile_status default null,
  p_search  text default null,
  p_limit   integer default 25,
  p_offset  integer default 0
) returns table (
  id uuid, organization_id uuid,
  code citext, name_fa text, name_en text,
  status marketplace.carrier_profile_status,
  is_public boolean,
  transport_modes shipment.transport_mode[],
  service_country_codes citext[],
  created_at timestamptz
)
language plpgsql stable security definer set search_path = ''
as $$
begin
  if not identity.is_platform_admin() then
    raise exception 'marketplace.admin_list_carriers: requires platform_admin' using errcode = '42501';
  end if;
  return query
    select cp.id, cp.organization_id,
           o.code, o.name_fa, o.name_en,
           cp.status,
           coalesce(v.is_public, false) as is_public,
           cp.transport_modes, cp.service_country_codes,
           cp.created_at
      from marketplace.carrier_profiles cp
      join organization.organizations o on o.id = cp.organization_id
      left join marketplace.carrier_directory_visibility v
        on v.carrier_organization_id = cp.organization_id
     where cp.deleted_at is null
       and (p_status is null or cp.status = p_status)
       and (
         p_search is null or btrim(p_search) = ''
         or o.name_fa ilike '%' || p_search || '%'
         or o.name_en ilike '%' || p_search || '%'
         or o.code   ilike '%' || p_search || '%'
       )
     order by cp.created_at desc
     limit p_limit offset p_offset;
end;
$$;

-- 6.6 admin_get_carrier ----------------------------------------------------
create or replace function marketplace.admin_get_carrier(p_carrier_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
begin
  if not identity.is_platform_admin() then
    raise exception 'marketplace.admin_get_carrier: requires platform_admin' using errcode = '42501';
  end if;
  return (
    select jsonb_build_object(
      'id', cp.id, 'organization_id', cp.organization_id,
      'code', o.code, 'name_fa', o.name_fa, 'name_en', o.name_en,
      'display_name_fa', cp.display_name_fa, 'display_name_en', cp.display_name_en,
      'bio_fa', cp.bio_fa, 'bio_en', cp.bio_en,
      'transport_modes', cp.transport_modes,
      'service_country_codes', cp.service_country_codes,
      'fleet_size_hint', cp.fleet_size_hint,
      'status', cp.status,
      'is_public', coalesce(v.is_public, false),
      'country_code', o.country_code,
      'created_at', cp.created_at, 'updated_at', cp.updated_at
    )
    from marketplace.carrier_profiles cp
    join organization.organizations o on o.id = cp.organization_id
    left join marketplace.carrier_directory_visibility v
      on v.carrier_organization_id = cp.organization_id
   where cp.id = p_carrier_id and cp.deleted_at is null
  );
end;
$$;

-- 6.7 supplier_publish_capacity --------------------------------------------
-- Brief uses "supplier" for the audience name because that's where the form
-- lives in CC-38's portal shell; the backend strictly operates over carrier
-- organizations (Q3). The role gate enforces this via fn_assert_carrier_actor.
create or replace function marketplace.supplier_publish_capacity(
  p_carrier_organization_id   uuid,
  p_transport_mode            shipment.transport_mode,
  p_origin_country            citext default null,
  p_origin_city               text default null,
  p_destination_country       citext default null,
  p_destination_city          text default null,
  p_capacity_units            numeric default null,
  p_unit_label                text default null,
  p_valid_from                timestamptz default null,
  p_valid_until               timestamptz default null,
  p_notes_fa                  text default null,
  p_notes_en                  text default null
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_tenant uuid;
  v_id uuid;
begin
  perform marketplace.fn_assert_carrier_org_type(p_carrier_organization_id);
  perform marketplace.fn_assert_carrier_actor(p_carrier_organization_id);

  if p_transport_mode is null then
    raise exception 'marketplace: transport_mode is required' using errcode = '22023';
  end if;

  select tenant_id into v_tenant from organization.organizations where id = p_carrier_organization_id;

  insert into marketplace.capacity_listings (
    tenant_id, carrier_organization_id, published_by_user_id,
    transport_mode, origin_country_code, origin_city,
    destination_country_code, destination_city,
    capacity_units, capacity_unit_label,
    valid_from, valid_until,
    status, notes_fa, notes_en,
    created_by, updated_by
  ) values (
    v_tenant, p_carrier_organization_id, v_actor,
    p_transport_mode, p_origin_country, p_origin_city,
    p_destination_country, p_destination_city,
    p_capacity_units, p_unit_label,
    p_valid_from, p_valid_until,
    'active', p_notes_fa, p_notes_en,
    v_actor, v_actor
  ) returning id into v_id;

  perform marketplace.fn_record_capacity_event(v_id, 'draft', 'active',
    'published', jsonb_build_object('transport_mode', p_transport_mode::text));
  perform marketplace.fn_audit('marketplace.capacity_published', v_id,
    'capacity_listing', jsonb_build_object('carrier_org', p_carrier_organization_id::text));

  return v_id;
end;
$$;

-- 6.8 supplier_update_capacity ---------------------------------------------
create or replace function marketplace.supplier_update_capacity(
  p_listing_id                uuid,
  p_transport_mode            shipment.transport_mode default null,
  p_origin_country            citext default null,
  p_origin_city               text default null,
  p_destination_country       citext default null,
  p_destination_city          text default null,
  p_capacity_units            numeric default null,
  p_unit_label                text default null,
  p_valid_from                timestamptz default null,
  p_valid_until               timestamptz default null,
  p_notes_fa                  text default null,
  p_notes_en                  text default null
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_org uuid; v_status marketplace.capacity_status;
begin
  select carrier_organization_id, status into v_org, v_status
    from marketplace.capacity_listings where id = p_listing_id and deleted_at is null;
  if v_org is null then
    raise exception 'marketplace: capacity listing not found' using errcode = 'P0002';
  end if;
  perform marketplace.fn_assert_carrier_actor(v_org);
  if v_status not in ('draft', 'active') then
    raise exception 'marketplace: capacity locked from edit (status=%)', v_status using errcode = 'P0001';
  end if;

  update marketplace.capacity_listings
     set transport_mode           = coalesce(p_transport_mode, transport_mode),
         origin_country_code      = coalesce(p_origin_country, origin_country_code),
         origin_city              = coalesce(p_origin_city, origin_city),
         destination_country_code = coalesce(p_destination_country, destination_country_code),
         destination_city         = coalesce(p_destination_city, destination_city),
         capacity_units           = coalesce(p_capacity_units, capacity_units),
         capacity_unit_label      = coalesce(p_unit_label, capacity_unit_label),
         valid_from               = coalesce(p_valid_from, valid_from),
         valid_until              = coalesce(p_valid_until, valid_until),
         notes_fa                 = coalesce(p_notes_fa, notes_fa),
         notes_en                 = coalesce(p_notes_en, notes_en),
         updated_by               = v_actor,
         updated_at               = now()
   where id = p_listing_id;

  perform marketplace.fn_audit('marketplace.capacity_updated', p_listing_id,
    'capacity_listing', '{}'::jsonb);
end;
$$;

-- 6.9 supplier_archive_capacity --------------------------------------------
create or replace function marketplace.supplier_archive_capacity(
  p_listing_id uuid,
  p_reason     text default null
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_org uuid; v_status marketplace.capacity_status;
begin
  select carrier_organization_id, status into v_org, v_status
    from marketplace.capacity_listings where id = p_listing_id and deleted_at is null;
  if v_org is null then
    raise exception 'marketplace: capacity listing not found' using errcode = 'P0002';
  end if;
  perform marketplace.fn_assert_carrier_actor(v_org);
  if v_status = 'archived' then
    raise exception 'marketplace: capacity already archived' using errcode = 'P0001';
  end if;

  update marketplace.capacity_listings
     set status = 'archived', updated_by = v_actor, updated_at = now()
   where id = p_listing_id;

  perform marketplace.fn_record_capacity_event(p_listing_id, v_status, 'archived',
    p_reason, '{}'::jsonb);
  perform marketplace.fn_audit('marketplace.capacity_archived', p_listing_id,
    'capacity_listing', jsonb_build_object('reason', p_reason));
end;
$$;

-- 6.10 supplier_list_my_capacity ------------------------------------------
create or replace function marketplace.supplier_list_my_capacity(
  p_carrier_organization_id uuid,
  p_status                  marketplace.capacity_status default null,
  p_limit                   integer default 25,
  p_offset                  integer default 0
) returns table (
  id uuid, carrier_organization_id uuid,
  transport_mode shipment.transport_mode,
  origin_country_code citext, origin_city text,
  destination_country_code citext, destination_city text,
  capacity_units numeric, capacity_unit_label text,
  valid_from timestamptz, valid_until timestamptz,
  status marketplace.capacity_status,
  created_at timestamptz, updated_at timestamptz
)
language plpgsql stable security definer set search_path = ''
as $$
begin
  perform marketplace.fn_assert_carrier_actor(p_carrier_organization_id);
  return query
    select cl.id, cl.carrier_organization_id,
           cl.transport_mode,
           cl.origin_country_code, cl.origin_city,
           cl.destination_country_code, cl.destination_city,
           cl.capacity_units, cl.capacity_unit_label,
           cl.valid_from, cl.valid_until,
           cl.status,
           cl.created_at, cl.updated_at
      from marketplace.capacity_listings cl
     where cl.carrier_organization_id = p_carrier_organization_id
       and cl.deleted_at is null
       and (p_status is null or cl.status = p_status)
     order by cl.created_at desc
     limit p_limit offset p_offset;
end;
$$;

-- 6.11 buyer_list_capacity -------------------------------------------------
create or replace function marketplace.buyer_list_capacity(
  p_transport_mode       shipment.transport_mode default null,
  p_origin_country       citext default null,
  p_destination_country  citext default null,
  p_carrier_id           uuid default null,
  p_limit                integer default 25,
  p_offset               integer default 0
) returns table (
  id uuid, carrier_organization_id uuid,
  carrier_name_fa text, carrier_name_en text,
  transport_mode shipment.transport_mode,
  origin_country_code citext, origin_city text,
  destination_country_code citext, destination_city text,
  capacity_units numeric, capacity_unit_label text,
  valid_from timestamptz, valid_until timestamptz,
  created_at timestamptz
)
language plpgsql stable security definer set search_path = ''
as $$
begin
  return query
    select cl.id, cl.carrier_organization_id,
           o.name_fa, o.name_en,
           cl.transport_mode,
           cl.origin_country_code, cl.origin_city,
           cl.destination_country_code, cl.destination_city,
           cl.capacity_units, cl.capacity_unit_label,
           cl.valid_from, cl.valid_until, cl.created_at
      from marketplace.capacity_listings cl
      join organization.organizations o on o.id = cl.carrier_organization_id
      join marketplace.carrier_directory_visibility v
        on v.carrier_organization_id = cl.carrier_organization_id and v.is_public = true
     where cl.deleted_at is null
       and cl.status = 'active'
       and (cl.valid_until is null or cl.valid_until > now())
       and (p_transport_mode is null or cl.transport_mode = p_transport_mode)
       and (p_origin_country is null or cl.origin_country_code = p_origin_country)
       and (p_destination_country is null or cl.destination_country_code = p_destination_country)
       and (p_carrier_id is null or cl.carrier_organization_id = p_carrier_id)
     order by cl.created_at desc
     limit p_limit offset p_offset;
end;
$$;

-- 6.12 admin_list_capacity -------------------------------------------------
create or replace function marketplace.admin_list_capacity(
  p_status      marketplace.capacity_status default null,
  p_carrier_id  uuid default null,
  p_limit       integer default 25,
  p_offset      integer default 0
) returns table (
  id uuid, carrier_organization_id uuid,
  carrier_name_fa text, carrier_name_en text,
  transport_mode shipment.transport_mode,
  origin_country_code citext, origin_city text,
  destination_country_code citext, destination_city text,
  status marketplace.capacity_status,
  valid_from timestamptz, valid_until timestamptz,
  created_at timestamptz
)
language plpgsql stable security definer set search_path = ''
as $$
begin
  if not identity.is_platform_admin() then
    raise exception 'marketplace.admin_list_capacity: requires platform_admin' using errcode = '42501';
  end if;
  return query
    select cl.id, cl.carrier_organization_id,
           o.name_fa, o.name_en,
           cl.transport_mode,
           cl.origin_country_code, cl.origin_city,
           cl.destination_country_code, cl.destination_city,
           cl.status, cl.valid_from, cl.valid_until, cl.created_at
      from marketplace.capacity_listings cl
      join organization.organizations o on o.id = cl.carrier_organization_id
     where cl.deleted_at is null
       and (p_status is null or cl.status = p_status)
       and (p_carrier_id is null or cl.carrier_organization_id = p_carrier_id)
     order by cl.created_at desc
     limit p_limit offset p_offset;
end;
$$;

-- 6.13 admin_archive_capacity ---------------------------------------------
create or replace function marketplace.admin_archive_capacity(
  p_listing_id uuid,
  p_reason     text default null
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_status marketplace.capacity_status;
begin
  if not identity.is_platform_admin() then
    raise exception 'marketplace.admin_archive_capacity: requires platform_admin' using errcode = '42501';
  end if;
  select status into v_status from marketplace.capacity_listings
   where id = p_listing_id and deleted_at is null;
  if v_status is null then
    raise exception 'marketplace: capacity listing not found' using errcode = 'P0002';
  end if;
  if v_status = 'archived' then
    raise exception 'marketplace: capacity already archived' using errcode = 'P0001';
  end if;

  update marketplace.capacity_listings
     set status = 'archived', updated_by = v_actor, updated_at = now()
   where id = p_listing_id;

  perform marketplace.fn_record_capacity_event(p_listing_id, v_status, 'archived',
    p_reason, jsonb_build_object('admin_action', true));
  perform marketplace.fn_audit('marketplace.admin_capacity_archived', p_listing_id,
    'capacity_listing', jsonb_build_object('reason', p_reason));
end;
$$;

-- 6.14 admin_list_activity ------------------------------------------------
create or replace function marketplace.admin_list_activity(
  p_limit  integer default 50,
  p_offset integer default 0
) returns table (
  event_id uuid, capacity_listing_id uuid,
  carrier_organization_id uuid,
  from_status marketplace.capacity_status,
  to_status marketplace.capacity_status,
  reason text, actor_user_id uuid,
  created_at timestamptz
)
language plpgsql stable security definer set search_path = ''
as $$
begin
  if not identity.is_platform_admin() then
    raise exception 'marketplace.admin_list_activity: requires platform_admin' using errcode = '42501';
  end if;
  return query
    select e.id, e.capacity_listing_id, cl.carrier_organization_id,
           e.from_status, e.to_status, e.reason, e.actor_user_id, e.created_at
      from marketplace.capacity_status_events e
      join marketplace.capacity_listings cl on cl.id = e.capacity_listing_id
     order by e.created_at desc
     limit p_limit offset p_offset;
end;
$$;

-- 6.15 admin_capacity_summary ---------------------------------------------
create or replace function marketplace.admin_capacity_summary()
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare v jsonb;
begin
  if not identity.is_platform_admin() then
    raise exception 'marketplace.admin_capacity_summary: requires platform_admin' using errcode = '42501';
  end if;
  select jsonb_build_object(
    'total', count(*),
    'by_status', (
      select coalesce(jsonb_agg(jsonb_build_object('status', s, 'count', c)), '[]'::jsonb)
        from (
          select status::text as s, count(*) as c
            from marketplace.capacity_listings
           where deleted_at is null
           group by status
        ) x
    ),
    'by_mode', (
      select coalesce(jsonb_agg(jsonb_build_object('mode', m, 'count', c)), '[]'::jsonb)
        from (
          select transport_mode::text as m, count(*) as c
            from marketplace.capacity_listings
           where deleted_at is null
           group by transport_mode
        ) y
    )
  ) into v
  from marketplace.capacity_listings where deleted_at is null;
  return v;
end;
$$;

-- ===========================================================================
-- 7. RPC grants
-- ===========================================================================

grant execute on function marketplace.carrier_upsert_profile(
  uuid, text, text, text, text,
  shipment.transport_mode[], citext[], integer,
  marketplace.carrier_profile_status, uuid
) to authenticated;

grant execute on function marketplace.carrier_set_directory_visibility(uuid, boolean) to authenticated;

grant execute on function marketplace.buyer_list_carriers(
  citext, shipment.transport_mode, text, integer, integer
) to authenticated;

grant execute on function marketplace.buyer_get_carrier(uuid) to authenticated;

grant execute on function marketplace.admin_list_carriers(
  marketplace.carrier_profile_status, text, integer, integer
) to authenticated;

grant execute on function marketplace.admin_get_carrier(uuid) to authenticated;

grant execute on function marketplace.supplier_publish_capacity(
  uuid, shipment.transport_mode, citext, text, citext, text,
  numeric, text, timestamptz, timestamptz, text, text
) to authenticated;

grant execute on function marketplace.supplier_update_capacity(
  uuid, shipment.transport_mode, citext, text, citext, text,
  numeric, text, timestamptz, timestamptz, text, text
) to authenticated;

grant execute on function marketplace.supplier_archive_capacity(uuid, text) to authenticated;

grant execute on function marketplace.supplier_list_my_capacity(
  uuid, marketplace.capacity_status, integer, integer
) to authenticated;

grant execute on function marketplace.buyer_list_capacity(
  shipment.transport_mode, citext, citext, uuid, integer, integer
) to authenticated;

grant execute on function marketplace.admin_list_capacity(
  marketplace.capacity_status, uuid, integer, integer
) to authenticated;

grant execute on function marketplace.admin_archive_capacity(uuid, text) to authenticated;

grant execute on function marketplace.admin_list_activity(integer, integer) to authenticated;

grant execute on function marketplace.admin_capacity_summary() to authenticated;

-- ===========================================================================
-- 8. Table SELECT grants
-- ===========================================================================
-- Required so RLS subqueries can evaluate when the caller is `authenticated`.
-- No INSERT/UPDATE/DELETE grants — those flow through SECURITY DEFINER RPCs.
grant select on marketplace.carrier_profiles               to authenticated;
grant select on marketplace.carrier_directory_visibility   to authenticated, anon;
grant select on marketplace.capacity_listings              to authenticated;
grant select on marketplace.capacity_status_events         to authenticated;
