-- CC-09 / Migration 0020 — RFQ Foundation
-- Third business domain (after supplier + commodity). Append-only over 0001-0019.
-- Security model: SECURITY DEFINER RPCs only; no direct write grants; search_path=''.

-- ===========================================================================
-- 1. Schema
-- ===========================================================================
create schema if not exists rfq;
grant usage on schema rfq to anon, authenticated, service_role;
comment on schema rfq is
  'iKIA Phase 2 — RFQ business domain: requests, items, specifications, document requirements, supplier invitations, status events.';

-- ===========================================================================
-- 2. Enums
-- ===========================================================================
create type rfq.request_status as enum (
  'draft', 'submitted', 'published', 'invited', 'closed', 'cancelled', 'expired'
);

create type rfq.visibility_model as enum (
  'private_invited', 'organization', 'public'
);

create type rfq.invitation_status as enum (
  'invited', 'viewed', 'accepted', 'declined', 'withdrawn', 'expired'
);

create type rfq.document_scope as enum (
  'request', 'item'
);

-- ===========================================================================
-- 3. Tables (6)
-- ===========================================================================

-- 3.1 requests --------------------------------------------------------------
create table rfq.requests (
  id                       uuid primary key default gen_random_uuid(),
  tenant_id                uuid not null references identity.tenants(id) on delete restrict,
  organization_id          uuid not null references organization.organizations(id) on delete cascade,
  requester_user_id        uuid not null references auth.users(id),

  rfq_code                 citext not null unique,
  title                    text not null,
  description              text,

  status                   rfq.request_status not null default 'draft',
  visibility               rfq.visibility_model not null default 'private_invited',

  submission_deadline      timestamptz,
  validity_until           timestamptz,

  preferred_incoterms      jsonb not null default '[]'::jsonb,
  preferred_currency       text not null default 'USD',

  delivery_country         char(2),
  delivery_city            text,
  delivery_port            text,
  delivery_location_text   text,

  payment_terms_text       text,
  internal_notes           text,
  metadata                 jsonb not null default '{}'::jsonb,

  submitted_at             timestamptz,
  published_at             timestamptz,
  invited_at               timestamptz,
  closed_at                timestamptz,
  closed_by                uuid references auth.users(id),
  cancelled_at             timestamptz,
  cancelled_by             uuid references auth.users(id),
  cancelled_reason         text,
  expired_at               timestamptz,

  created_by               uuid references auth.users(id),
  created_at               timestamptz not null default now(),
  updated_by               uuid references auth.users(id),
  updated_at               timestamptz not null default now(),
  deleted_at               timestamptz,
  version                  integer not null default 1
);

comment on table rfq.requests is
  'RFQ master record. Buyer organization owns the RFQ; status drives editability and visibility.';

create index rfq_requests_org_idx     on rfq.requests(organization_id);
create index rfq_requests_status_idx  on rfq.requests(status);
create index rfq_requests_created_idx on rfq.requests(created_at desc);

-- 3.2 request_items ---------------------------------------------------------
create table rfq.request_items (
  id                         uuid primary key default gen_random_uuid(),
  tenant_id                  uuid not null references identity.tenants(id) on delete restrict,
  organization_id            uuid not null references organization.organizations(id) on delete cascade,
  request_id                 uuid not null references rfq.requests(id) on delete cascade,
  product_id                 uuid not null references commodity.products(id) on delete restrict,

  quantity                   numeric,
  quantity_unit              text,

  packaging_preference       text,
  origin_country_preference  char(2),
  origin_preference_notes    text,

  delivery_window_start      date,
  delivery_window_end        date,

  notes                      text,
  metadata                   jsonb not null default '{}'::jsonb,
  sort_order                 integer not null default 0,

  created_by                 uuid references auth.users(id),
  created_at                 timestamptz not null default now(),
  updated_by                 uuid references auth.users(id),
  updated_at                 timestamptz not null default now(),
  deleted_at                 timestamptz,
  version                    integer not null default 1
);

create unique index rfq_request_items_unique_active
  on rfq.request_items(request_id, product_id)
  where deleted_at is null;

create index rfq_request_items_request_idx on rfq.request_items(request_id);
create index rfq_request_items_product_idx on rfq.request_items(product_id);

-- 3.3 request_item_specifications -------------------------------------------
create table rfq.request_item_specifications (
  id                       uuid primary key default gen_random_uuid(),
  tenant_id                uuid not null references identity.tenants(id) on delete restrict,
  organization_id          uuid not null references organization.organizations(id) on delete cascade,
  request_id               uuid not null references rfq.requests(id) on delete cascade,
  request_item_id          uuid not null references rfq.request_items(id) on delete cascade,
  product_specification_id uuid references commodity.product_specifications(id) on delete set null,

  spec_key                 citext not null,
  display_name_fa          text,
  display_name_en          text,
  data_type                commodity.spec_data_type not null default 'text',
  unit                     text,
  requested_value          text,
  min_value                numeric,
  max_value                numeric,
  tolerance_text           text,
  is_required              boolean not null default false,
  sort_order               integer not null default 0,
  notes                    text,

  created_by               uuid references auth.users(id),
  created_at               timestamptz not null default now(),
  updated_by               uuid references auth.users(id),
  updated_at               timestamptz not null default now(),
  deleted_at               timestamptz,
  version                  integer not null default 1
);

create unique index rfq_item_specs_unique_active
  on rfq.request_item_specifications(request_item_id, spec_key)
  where deleted_at is null;

create index rfq_item_specs_item_idx on rfq.request_item_specifications(request_item_id);

-- 3.4 request_document_requirements -----------------------------------------
create table rfq.request_document_requirements (
  id                  uuid primary key default gen_random_uuid(),
  tenant_id           uuid not null references identity.tenants(id) on delete restrict,
  organization_id     uuid not null references organization.organizations(id) on delete cascade,
  request_id          uuid not null references rfq.requests(id) on delete cascade,
  request_item_id     uuid references rfq.request_items(id) on delete cascade,
  source_doc_req_id   uuid references commodity.product_document_requirements(id) on delete set null,

  document_kind       commodity.document_kind not null,
  requirement_level   commodity.document_requirement_level not null default 'mandatory',
  scope               rfq.document_scope not null default 'request',
  display_name_fa     text,
  display_name_en     text,
  notes               text,
  sort_order          integer not null default 0,
  is_active           boolean not null default true,

  created_by          uuid references auth.users(id),
  created_at          timestamptz not null default now(),
  updated_by          uuid references auth.users(id),
  updated_at          timestamptz not null default now(),
  deleted_at          timestamptz,
  version             integer not null default 1
);

-- Partial unique by scope.
create unique index rfq_doc_req_unique_request_scope
  on rfq.request_document_requirements(request_id, document_kind)
  where scope = 'request' and request_item_id is null and deleted_at is null;

create unique index rfq_doc_req_unique_item_scope
  on rfq.request_document_requirements(request_item_id, document_kind)
  where scope = 'item' and request_item_id is not null and deleted_at is null;

create index rfq_doc_req_request_idx on rfq.request_document_requirements(request_id);

-- 3.5 request_supplier_invitations ------------------------------------------
create table rfq.request_supplier_invitations (
  id                uuid primary key default gen_random_uuid(),
  tenant_id         uuid not null references identity.tenants(id) on delete restrict,
  organization_id   uuid not null references organization.organizations(id) on delete cascade,
  request_id        uuid not null references rfq.requests(id) on delete cascade,
  supplier_id       uuid not null references supplier.suppliers(id) on delete restrict,

  status            rfq.invitation_status not null default 'invited',
  invited_at        timestamptz not null default now(),
  viewed_at         timestamptz,
  responded_at      timestamptz,
  message           text,
  metadata          jsonb not null default '{}'::jsonb,

  created_by        uuid references auth.users(id),
  created_at        timestamptz not null default now(),
  updated_by        uuid references auth.users(id),
  updated_at        timestamptz not null default now(),
  deleted_at        timestamptz,
  version           integer not null default 1
);

create unique index rfq_invitations_unique_active
  on rfq.request_supplier_invitations(request_id, supplier_id)
  where deleted_at is null;

create index rfq_invitations_supplier_idx on rfq.request_supplier_invitations(supplier_id);
create index rfq_invitations_request_idx  on rfq.request_supplier_invitations(request_id);

-- 3.6 request_status_events (immutable) -------------------------------------
create table rfq.request_status_events (
  id                    uuid primary key default gen_random_uuid(),
  tenant_id             uuid not null references identity.tenants(id) on delete restrict,
  organization_id       uuid not null references organization.organizations(id) on delete cascade,
  request_id            uuid not null references rfq.requests(id) on delete cascade,

  from_status           rfq.request_status,
  to_status             rfq.request_status not null,
  actor_user_id         uuid references auth.users(id),
  actor_organization_id uuid references organization.organizations(id),
  reason                text,
  payload               jsonb not null default '{}'::jsonb,
  created_at            timestamptz not null default now()
);

comment on table rfq.request_status_events is
  'Immutable audit trail of RFQ status transitions. No UPDATE/DELETE policies.';

create index rfq_status_events_request_idx on rfq.request_status_events(request_id, created_at desc);

-- ===========================================================================
-- 4. Internal helpers
-- ===========================================================================

-- 4.1 fn_audit: write a domain audit event ----------------------------------
create or replace function rfq.fn_audit(
  p_action_code   text,
  p_request_id    uuid,
  p_payload       jsonb default '{}'::jsonb
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_t uuid;
  v_o uuid;
begin
  select tenant_id, organization_id into v_t, v_o
    from rfq.requests where id = p_request_id;
  insert into audit.audit_event (
    tenant_id, organization_id, actor_user_id, action_code,
    resource_type, resource_id, payload, occurred_at
  ) values (
    v_t, v_o, auth.uid(), p_action_code,
    'rfq', p_request_id, p_payload, now()
  );
exception when others then
  null;
end;
$$;

-- 4.2 fn_buyer_organization_id: returns active org or raises ----------------
-- Allows buyer_admin, organization_admin, platform_admin for current JWT org.
create or replace function rfq.fn_buyer_organization_id()
returns uuid
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_org_id uuid := identity.current_organization_id();
begin
  if not (
    identity.is_platform_admin()
    or identity.has_role('organization_admin')
    or identity.has_role('buyer_admin')
  ) then
    raise exception 'rfq buyer: requires buyer_admin, organization_admin or platform_admin'
      using errcode = '42501';
  end if;
  if v_org_id is null then
    raise exception 'rfq buyer: no active organization in JWT' using errcode = 'P0002';
  end if;
  return v_org_id;
end;
$$;

-- 4.3 fn_assert_request_buyer_owned: caller must be buyer of request's org
create or replace function rfq.fn_assert_request_buyer_owned(p_request_id uuid)
returns void
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_org uuid;
  v_caller_org uuid := identity.current_organization_id();
begin
  select organization_id into v_org from rfq.requests
   where id = p_request_id and deleted_at is null;
  if v_org is null then
    raise exception 'rfq: request not found' using errcode = 'P0002';
  end if;
  if identity.is_platform_admin() then return; end if;
  if not (
    identity.has_role('buyer_admin') or identity.has_role('organization_admin')
  ) then
    raise exception 'rfq: requires buyer_admin, organization_admin or platform_admin'
      using errcode = '42501';
  end if;
  if v_caller_org is null or v_caller_org <> v_org then
    raise exception 'rfq: caller is not the buyer organization of this request'
      using errcode = '42501';
  end if;
end;
$$;

-- 4.4 fn_assert_request_editable: status must be 'draft' --------------------
create or replace function rfq.fn_assert_request_editable(p_request_id uuid)
returns void
language plpgsql stable security definer set search_path = ''
as $$
declare v_status rfq.request_status;
begin
  select status into v_status from rfq.requests where id = p_request_id and deleted_at is null;
  if v_status is null then
    raise exception 'rfq: request not found' using errcode = 'P0002';
  end if;
  if v_status <> 'draft' then
    raise exception 'rfq: request is locked (status=%)', v_status using errcode = 'P0001';
  end if;
end;
$$;

-- 4.5 fn_record_status_event ------------------------------------------------
create or replace function rfq.fn_record_status_event(
  p_request_id  uuid,
  p_from        rfq.request_status,
  p_to          rfq.request_status,
  p_reason      text default null,
  p_payload     jsonb default '{}'::jsonb
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_t uuid;
  v_o uuid;
begin
  select tenant_id, organization_id into v_t, v_o from rfq.requests where id = p_request_id;
  insert into rfq.request_status_events (
    tenant_id, organization_id, request_id, from_status, to_status,
    actor_user_id, actor_organization_id, reason, payload
  ) values (
    v_t, v_o, p_request_id, p_from, p_to,
    auth.uid(), v_o, p_reason, p_payload
  );
end;
$$;

-- 4.6 fn_caller_supplier_can_see_request -----------------------------------
create or replace function rfq.fn_supplier_can_see_request(p_request_id uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1
      from rfq.request_supplier_invitations inv
      join supplier.suppliers s on s.id = inv.supplier_id
      join organization.memberships m on m.organization_id = s.organization_id
     where inv.request_id   = p_request_id
       and inv.deleted_at   is null
       and m.user_id        = identity.current_user_id()
       and m.deleted_at     is null
       and m.status         = 'active'
  );
$$;

-- ===========================================================================
-- 5. RLS
-- ===========================================================================
alter table rfq.requests                       enable row level security;
alter table rfq.request_items                  enable row level security;
alter table rfq.request_item_specifications    enable row level security;
alter table rfq.request_document_requirements  enable row level security;
alter table rfq.request_supplier_invitations   enable row level security;
alter table rfq.request_status_events          enable row level security;

-- 5.1 requests: platform_admin OR buyer org member OR invited supplier ------
drop policy if exists requests_select on rfq.requests;
create policy requests_select on rfq.requests
  for select
  using (
    deleted_at is null
    and (
      identity.is_platform_admin()
      or exists (
        select 1 from organization.memberships m
         where m.user_id = identity.current_user_id()
           and m.organization_id = rfq.requests.organization_id
           and m.deleted_at is null
           and m.status = 'active'
      )
      or rfq.fn_supplier_can_see_request(rfq.requests.id)
    )
  );

drop policy if exists requests_select_deleted on rfq.requests;
create policy requests_select_deleted on rfq.requests
  for select
  using (
    deleted_at is not null
    and (identity.is_platform_admin() or identity.has_role('compliance_officer'))
  );

drop policy if exists requests_admin_modify on rfq.requests;
create policy requests_admin_modify on rfq.requests
  for all
  using (identity.is_platform_admin())
  with check (identity.is_platform_admin());

-- 5.2 request_items: same visibility as parent request ---------------------
drop policy if exists request_items_select on rfq.request_items;
create policy request_items_select on rfq.request_items
  for select
  using (
    deleted_at is null
    and (
      identity.is_platform_admin()
      or exists (
        select 1 from organization.memberships m
         where m.user_id = identity.current_user_id()
           and m.organization_id = rfq.request_items.organization_id
           and m.deleted_at is null
           and m.status = 'active'
      )
      or rfq.fn_supplier_can_see_request(rfq.request_items.request_id)
    )
  );

drop policy if exists request_items_admin_modify on rfq.request_items;
create policy request_items_admin_modify on rfq.request_items
  for all
  using (identity.is_platform_admin())
  with check (identity.is_platform_admin());

-- 5.3 request_item_specifications -------------------------------------------
drop policy if exists request_specs_select on rfq.request_item_specifications;
create policy request_specs_select on rfq.request_item_specifications
  for select
  using (
    deleted_at is null
    and (
      identity.is_platform_admin()
      or exists (
        select 1 from organization.memberships m
         where m.user_id = identity.current_user_id()
           and m.organization_id = rfq.request_item_specifications.organization_id
           and m.deleted_at is null
           and m.status = 'active'
      )
      or rfq.fn_supplier_can_see_request(rfq.request_item_specifications.request_id)
    )
  );

drop policy if exists request_specs_admin_modify on rfq.request_item_specifications;
create policy request_specs_admin_modify on rfq.request_item_specifications
  for all
  using (identity.is_platform_admin())
  with check (identity.is_platform_admin());

-- 5.4 request_document_requirements -----------------------------------------
drop policy if exists request_doc_reqs_select on rfq.request_document_requirements;
create policy request_doc_reqs_select on rfq.request_document_requirements
  for select
  using (
    deleted_at is null
    and (
      identity.is_platform_admin()
      or exists (
        select 1 from organization.memberships m
         where m.user_id = identity.current_user_id()
           and m.organization_id = rfq.request_document_requirements.organization_id
           and m.deleted_at is null
           and m.status = 'active'
      )
      or rfq.fn_supplier_can_see_request(rfq.request_document_requirements.request_id)
    )
  );

drop policy if exists request_doc_reqs_admin_modify on rfq.request_document_requirements;
create policy request_doc_reqs_admin_modify on rfq.request_document_requirements
  for all
  using (identity.is_platform_admin())
  with check (identity.is_platform_admin());

-- 5.5 request_supplier_invitations -----------------------------------------
-- Buyer org members see all invitations on their RFQs.
-- Supplier members see only invitations targeting their own supplier.
drop policy if exists request_invitations_select on rfq.request_supplier_invitations;
create policy request_invitations_select on rfq.request_supplier_invitations
  for select
  using (
    deleted_at is null
    and (
      identity.is_platform_admin()
      or exists (
        select 1 from organization.memberships m
         where m.user_id = identity.current_user_id()
           and m.organization_id = rfq.request_supplier_invitations.organization_id
           and m.deleted_at is null
           and m.status = 'active'
      )
      or exists (
        select 1 from supplier.suppliers s
         join organization.memberships m on m.organization_id = s.organization_id
        where s.id = rfq.request_supplier_invitations.supplier_id
          and m.user_id = identity.current_user_id()
          and m.deleted_at is null
          and m.status = 'active'
      )
    )
  );

drop policy if exists request_invitations_admin_modify on rfq.request_supplier_invitations;
create policy request_invitations_admin_modify on rfq.request_supplier_invitations
  for all
  using (identity.is_platform_admin())
  with check (identity.is_platform_admin());

-- 5.6 request_status_events: buyer org + admin only (not suppliers) --------
drop policy if exists request_status_events_select on rfq.request_status_events;
create policy request_status_events_select on rfq.request_status_events
  for select
  using (
    identity.is_platform_admin()
    or exists (
      select 1 from organization.memberships m
       where m.user_id = identity.current_user_id()
         and m.organization_id = rfq.request_status_events.organization_id
         and m.deleted_at is null
         and m.status = 'active'
    )
  );

-- No INSERT/UPDATE/DELETE policies on status_events — append-only via RPC.

-- ===========================================================================
-- 6. Buyer RPCs (14)
-- ===========================================================================

-- 6.1 buyer_create_rfq ------------------------------------------------------
create or replace function rfq.buyer_create_rfq(
  p_title                  text,
  p_description            text         default null,
  p_visibility             rfq.visibility_model default 'private_invited',
  p_submission_deadline    timestamptz  default null,
  p_validity_until         timestamptz  default null,
  p_preferred_incoterms    jsonb        default '[]'::jsonb,
  p_preferred_currency     text         default 'USD',
  p_delivery_country       char(2)      default null,
  p_delivery_city          text         default null,
  p_delivery_port          text         default null,
  p_delivery_location_text text         default null,
  p_payment_terms_text     text         default null
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_org uuid := rfq.fn_buyer_organization_id();
  v_tenant uuid;
  v_actor uuid := auth.uid();
  v_id uuid;
  v_code text;
begin
  if p_title is null or btrim(p_title) = '' then
    raise exception 'rfq: title is required' using errcode = '22023';
  end if;
  select tenant_id into v_tenant from organization.organizations where id = v_org;

  v_code := 'RFQ-' || to_char(now(), 'YYYY') || '-' ||
            lpad((floor(random() * 1000000)::int)::text, 6, '0');

  insert into rfq.requests (
    tenant_id, organization_id, requester_user_id, rfq_code, title, description,
    status, visibility, submission_deadline, validity_until,
    preferred_incoterms, preferred_currency,
    delivery_country, delivery_city, delivery_port, delivery_location_text,
    payment_terms_text, created_by, updated_by
  ) values (
    v_tenant, v_org, v_actor, v_code, p_title, p_description,
    'draft', p_visibility, p_submission_deadline, p_validity_until,
    coalesce(p_preferred_incoterms, '[]'::jsonb), coalesce(p_preferred_currency, 'USD'),
    p_delivery_country, p_delivery_city, p_delivery_port, p_delivery_location_text,
    p_payment_terms_text, v_actor, v_actor
  ) returning id into v_id;

  perform rfq.fn_record_status_event(v_id, null, 'draft', 'created');
  perform rfq.fn_audit('rfq.created', v_id, jsonb_build_object('rfq_code', v_code::text));
  return v_id;
end;
$$;

-- 6.2 buyer_update_rfq (partial, only when draft) --------------------------
create or replace function rfq.buyer_update_rfq(
  p_request_id             uuid,
  p_title                  text         default null,
  p_description            text         default null,
  p_visibility             rfq.visibility_model default null,
  p_submission_deadline    timestamptz  default null,
  p_validity_until         timestamptz  default null,
  p_preferred_incoterms    jsonb        default null,
  p_preferred_currency     text         default null,
  p_delivery_country       char(2)      default null,
  p_delivery_city          text         default null,
  p_delivery_port          text         default null,
  p_delivery_location_text text         default null,
  p_payment_terms_text     text         default null,
  p_internal_notes         text         default null
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare v_actor uuid := auth.uid();
begin
  perform rfq.fn_assert_request_buyer_owned(p_request_id);
  perform rfq.fn_assert_request_editable(p_request_id);

  update rfq.requests
     set title                  = coalesce(p_title, title),
         description            = coalesce(p_description, description),
         visibility             = coalesce(p_visibility, visibility),
         submission_deadline    = coalesce(p_submission_deadline, submission_deadline),
         validity_until         = coalesce(p_validity_until, validity_until),
         preferred_incoterms    = coalesce(p_preferred_incoterms, preferred_incoterms),
         preferred_currency     = coalesce(p_preferred_currency, preferred_currency),
         delivery_country       = coalesce(p_delivery_country, delivery_country),
         delivery_city          = coalesce(p_delivery_city, delivery_city),
         delivery_port          = coalesce(p_delivery_port, delivery_port),
         delivery_location_text = coalesce(p_delivery_location_text, delivery_location_text),
         payment_terms_text     = coalesce(p_payment_terms_text, payment_terms_text),
         internal_notes         = coalesce(p_internal_notes, internal_notes),
         updated_by             = v_actor
   where id = p_request_id;

  perform rfq.fn_audit('rfq.updated', p_request_id);
end;
$$;

-- 6.3 buyer_upsert_rfq_item -------------------------------------------------
create or replace function rfq.buyer_upsert_rfq_item(
  p_request_id              uuid,
  p_item_id                 uuid     default null,
  p_product_id              uuid     default null,
  p_quantity                numeric  default null,
  p_quantity_unit           text     default null,
  p_packaging_preference    text     default null,
  p_origin_country_preference char(2) default null,
  p_origin_preference_notes text     default null,
  p_delivery_window_start   date     default null,
  p_delivery_window_end     date     default null,
  p_notes                   text     default null,
  p_sort_order              integer  default 0
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_org   uuid;
  v_tenant uuid;
  v_id    uuid;
begin
  perform rfq.fn_assert_request_buyer_owned(p_request_id);
  perform rfq.fn_assert_request_editable(p_request_id);

  select tenant_id, organization_id into v_tenant, v_org
    from rfq.requests where id = p_request_id;

  if p_item_id is null then
    if p_product_id is null then
      raise exception 'rfq: p_product_id required for new item' using errcode = '22023';
    end if;
    insert into rfq.request_items (
      tenant_id, organization_id, request_id, product_id,
      quantity, quantity_unit, packaging_preference,
      origin_country_preference, origin_preference_notes,
      delivery_window_start, delivery_window_end, notes, sort_order,
      created_by, updated_by
    ) values (
      v_tenant, v_org, p_request_id, p_product_id,
      p_quantity, p_quantity_unit, p_packaging_preference,
      p_origin_country_preference, p_origin_preference_notes,
      p_delivery_window_start, p_delivery_window_end, p_notes, coalesce(p_sort_order, 0),
      v_actor, v_actor
    ) returning id into v_id;
  else
    update rfq.request_items
       set quantity                  = coalesce(p_quantity, quantity),
           quantity_unit             = coalesce(p_quantity_unit, quantity_unit),
           packaging_preference      = coalesce(p_packaging_preference, packaging_preference),
           origin_country_preference = coalesce(p_origin_country_preference, origin_country_preference),
           origin_preference_notes   = coalesce(p_origin_preference_notes, origin_preference_notes),
           delivery_window_start     = coalesce(p_delivery_window_start, delivery_window_start),
           delivery_window_end       = coalesce(p_delivery_window_end, delivery_window_end),
           notes                     = coalesce(p_notes, notes),
           sort_order                = coalesce(p_sort_order, sort_order),
           updated_by                = v_actor
     where id = p_item_id and request_id = p_request_id and deleted_at is null;
    if not found then
      raise exception 'rfq: item not found in request' using errcode = 'P0002';
    end if;
    v_id := p_item_id;
  end if;

  perform rfq.fn_audit('rfq.item_upserted', p_request_id,
    jsonb_build_object('item_id', v_id::text));
  return v_id;
end;
$$;

-- 6.4 buyer_remove_rfq_item (soft) -----------------------------------------
create or replace function rfq.buyer_remove_rfq_item(p_item_id uuid)
returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_request_id uuid;
  v_actor uuid := auth.uid();
begin
  select request_id into v_request_id from rfq.request_items
   where id = p_item_id and deleted_at is null;
  if v_request_id is null then
    raise exception 'rfq: item not found' using errcode = 'P0002';
  end if;
  perform rfq.fn_assert_request_buyer_owned(v_request_id);
  perform rfq.fn_assert_request_editable(v_request_id);

  update rfq.request_items set deleted_at = now(), updated_by = v_actor where id = p_item_id;
  perform rfq.fn_audit('rfq.item_removed', v_request_id,
    jsonb_build_object('item_id', p_item_id::text));
end;
$$;

-- 6.5 buyer_upsert_item_specification --------------------------------------
create or replace function rfq.buyer_upsert_item_specification(
  p_request_item_id          uuid,
  p_spec_key                 text,
  p_display_name_fa          text                       default null,
  p_display_name_en          text                       default null,
  p_data_type                commodity.spec_data_type   default 'text',
  p_unit                     text                       default null,
  p_requested_value          text                       default null,
  p_min_value                numeric                    default null,
  p_max_value                numeric                    default null,
  p_tolerance_text           text                       default null,
  p_is_required              boolean                    default false,
  p_product_specification_id uuid                       default null,
  p_sort_order               integer                    default 0,
  p_notes                    text                       default null
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_request_id uuid;
  v_org uuid;
  v_tenant uuid;
  v_id uuid;
begin
  select request_id, organization_id, tenant_id into v_request_id, v_org, v_tenant
    from rfq.request_items where id = p_request_item_id and deleted_at is null;
  if v_request_id is null then
    raise exception 'rfq: item not found' using errcode = 'P0002';
  end if;
  perform rfq.fn_assert_request_buyer_owned(v_request_id);
  perform rfq.fn_assert_request_editable(v_request_id);

  insert into rfq.request_item_specifications (
    tenant_id, organization_id, request_id, request_item_id, product_specification_id,
    spec_key, display_name_fa, display_name_en, data_type, unit, requested_value,
    min_value, max_value, tolerance_text, is_required, sort_order, notes,
    created_by, updated_by
  ) values (
    v_tenant, v_org, v_request_id, p_request_item_id, p_product_specification_id,
    p_spec_key, p_display_name_fa, p_display_name_en, p_data_type, p_unit, p_requested_value,
    p_min_value, p_max_value, p_tolerance_text, p_is_required, coalesce(p_sort_order, 0), p_notes,
    v_actor, v_actor
  )
  on conflict (request_item_id, spec_key) where deleted_at is null
  do update set
    display_name_fa          = excluded.display_name_fa,
    display_name_en          = excluded.display_name_en,
    data_type                = excluded.data_type,
    unit                     = excluded.unit,
    requested_value          = excluded.requested_value,
    min_value                = excluded.min_value,
    max_value                = excluded.max_value,
    tolerance_text           = excluded.tolerance_text,
    is_required              = excluded.is_required,
    product_specification_id = excluded.product_specification_id,
    sort_order               = excluded.sort_order,
    notes                    = excluded.notes,
    updated_by               = v_actor
  returning id into v_id;

  perform rfq.fn_audit('rfq.item_spec_upserted', v_request_id,
    jsonb_build_object('spec_id', v_id::text, 'spec_key', p_spec_key));
  return v_id;
end;
$$;

-- 6.6 buyer_remove_item_specification --------------------------------------
create or replace function rfq.buyer_remove_item_specification(p_spec_id uuid)
returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_request_id uuid;
begin
  select request_id into v_request_id from rfq.request_item_specifications
   where id = p_spec_id and deleted_at is null;
  if v_request_id is null then
    raise exception 'rfq: spec not found' using errcode = 'P0002';
  end if;
  perform rfq.fn_assert_request_buyer_owned(v_request_id);
  perform rfq.fn_assert_request_editable(v_request_id);

  update rfq.request_item_specifications
     set deleted_at = now(), updated_by = v_actor
   where id = p_spec_id;

  perform rfq.fn_audit('rfq.item_spec_removed', v_request_id,
    jsonb_build_object('spec_id', p_spec_id::text));
end;
$$;

-- 6.7 buyer_upsert_doc_requirement -----------------------------------------
create or replace function rfq.buyer_upsert_doc_requirement(
  p_request_id        uuid,
  p_request_item_id   uuid                                   default null,
  p_document_kind     commodity.document_kind                default 'other',
  p_requirement_level commodity.document_requirement_level   default 'mandatory',
  p_display_name_fa   text                                   default null,
  p_display_name_en   text                                   default null,
  p_notes             text                                   default null,
  p_sort_order        integer                                default 0,
  p_source_doc_req_id uuid                                   default null
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor  uuid := auth.uid();
  v_tenant uuid;
  v_org    uuid;
  v_scope  rfq.document_scope := case when p_request_item_id is null then 'request' else 'item' end;
  v_id     uuid;
begin
  perform rfq.fn_assert_request_buyer_owned(p_request_id);
  perform rfq.fn_assert_request_editable(p_request_id);
  select tenant_id, organization_id into v_tenant, v_org from rfq.requests where id = p_request_id;

  if p_request_item_id is not null then
    if not exists (select 1 from rfq.request_items
                    where id = p_request_item_id
                      and request_id = p_request_id
                      and deleted_at is null) then
      raise exception 'rfq: item not found for this request' using errcode = 'P0002';
    end if;
  end if;

  -- Try update existing active row first (handles re-add after soft-remove too).
  if v_scope = 'request' then
    update rfq.request_document_requirements
       set requirement_level = p_requirement_level,
           display_name_fa   = p_display_name_fa,
           display_name_en   = p_display_name_en,
           notes             = p_notes,
           sort_order        = coalesce(p_sort_order, sort_order),
           source_doc_req_id = coalesce(p_source_doc_req_id, source_doc_req_id),
           deleted_at        = null,
           is_active         = true,
           updated_by        = v_actor
     where request_id = p_request_id
       and scope = 'request'
       and request_item_id is null
       and document_kind = p_document_kind
    returning id into v_id;
  else
    update rfq.request_document_requirements
       set requirement_level = p_requirement_level,
           display_name_fa   = p_display_name_fa,
           display_name_en   = p_display_name_en,
           notes             = p_notes,
           sort_order        = coalesce(p_sort_order, sort_order),
           source_doc_req_id = coalesce(p_source_doc_req_id, source_doc_req_id),
           deleted_at        = null,
           is_active         = true,
           updated_by        = v_actor
     where request_item_id = p_request_item_id
       and scope = 'item'
       and document_kind = p_document_kind
    returning id into v_id;
  end if;

  if v_id is null then
    insert into rfq.request_document_requirements (
      tenant_id, organization_id, request_id, request_item_id, source_doc_req_id,
      document_kind, requirement_level, scope,
      display_name_fa, display_name_en, notes, sort_order, is_active,
      created_by, updated_by
    ) values (
      v_tenant, v_org, p_request_id, p_request_item_id, p_source_doc_req_id,
      p_document_kind, p_requirement_level, v_scope,
      p_display_name_fa, p_display_name_en, p_notes, coalesce(p_sort_order, 0), true,
      v_actor, v_actor
    ) returning id into v_id;
  end if;

  perform rfq.fn_audit('rfq.doc_req_upserted', p_request_id,
    jsonb_build_object('doc_req_id', v_id::text,
                       'document_kind', p_document_kind::text,
                       'scope', v_scope::text));
  return v_id;
end;
$$;

-- 6.8 buyer_remove_doc_requirement -----------------------------------------
create or replace function rfq.buyer_remove_doc_requirement(p_doc_req_id uuid)
returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_request_id uuid;
begin
  select request_id into v_request_id from rfq.request_document_requirements
   where id = p_doc_req_id and deleted_at is null;
  if v_request_id is null then
    raise exception 'rfq: doc requirement not found' using errcode = 'P0002';
  end if;
  perform rfq.fn_assert_request_buyer_owned(v_request_id);
  perform rfq.fn_assert_request_editable(v_request_id);

  update rfq.request_document_requirements
     set deleted_at = now(), is_active = false, updated_by = v_actor
   where id = p_doc_req_id;

  perform rfq.fn_audit('rfq.doc_req_removed', v_request_id,
    jsonb_build_object('doc_req_id', p_doc_req_id::text));
end;
$$;

-- 6.9 buyer_submit_rfq : draft → submitted ---------------------------------
create or replace function rfq.buyer_submit_rfq(p_request_id uuid)
returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_status rfq.request_status;
  v_actor uuid := auth.uid();
begin
  perform rfq.fn_assert_request_buyer_owned(p_request_id);
  select status into v_status from rfq.requests where id = p_request_id;
  if v_status <> 'draft' then
    raise exception 'rfq: invalid_transition: cannot submit from %', v_status
      using errcode = 'P0001';
  end if;

  update rfq.requests
     set status       = 'submitted',
         submitted_at = now(),
         updated_by   = v_actor
   where id = p_request_id;

  perform rfq.fn_record_status_event(p_request_id, 'draft', 'submitted', 'buyer_submit');
  perform rfq.fn_audit('rfq.submitted', p_request_id);
end;
$$;

-- 6.10 buyer_invite_suppliers : submitted|published → invited --------------
create or replace function rfq.buyer_invite_suppliers(
  p_request_id  uuid,
  p_supplier_ids uuid[],
  p_message     text default null
) returns integer
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_status rfq.request_status;
  v_tenant uuid;
  v_org uuid;
  v_sid uuid;
  v_added integer := 0;
begin
  perform rfq.fn_assert_request_buyer_owned(p_request_id);
  select status, tenant_id, organization_id
    into v_status, v_tenant, v_org
    from rfq.requests where id = p_request_id;
  if v_status not in ('submitted', 'published', 'invited') then
    raise exception 'rfq: invalid_transition: cannot invite from %', v_status
      using errcode = 'P0001';
  end if;
  if p_supplier_ids is null or array_length(p_supplier_ids, 1) is null then
    raise exception 'rfq: at least one supplier_id required' using errcode = '22023';
  end if;

  foreach v_sid in array p_supplier_ids loop
    if not exists (select 1 from supplier.suppliers where id = v_sid and deleted_at is null) then
      raise exception 'rfq: supplier % not found', v_sid using errcode = 'P0002';
    end if;

    -- Idempotent: revive soft-deleted, else insert.
    update rfq.request_supplier_invitations
       set deleted_at = null, status = 'invited',
           message = coalesce(p_message, message),
           updated_by = v_actor
     where request_id = p_request_id and supplier_id = v_sid and deleted_at is not null;

    if not found then
      insert into rfq.request_supplier_invitations (
        tenant_id, organization_id, request_id, supplier_id, status,
        message, created_by, updated_by
      ) values (
        v_tenant, v_org, p_request_id, v_sid, 'invited',
        p_message, v_actor, v_actor
      )
      on conflict (request_id, supplier_id) where deleted_at is null
      do nothing;
    end if;

    v_added := v_added + 1;
  end loop;

  -- Move status to 'invited' if not already.
  if v_status <> 'invited' then
    update rfq.requests
       set status     = 'invited',
           invited_at = coalesce(invited_at, now()),
           updated_by = v_actor
     where id = p_request_id;
    perform rfq.fn_record_status_event(p_request_id, v_status, 'invited', 'buyer_invite');
  end if;

  perform rfq.fn_audit('rfq.invitations_added', p_request_id,
    jsonb_build_object('count', v_added));
  return v_added;
end;
$$;

-- 6.11 buyer_cancel_rfq ----------------------------------------------------
create or replace function rfq.buyer_cancel_rfq(
  p_request_id uuid,
  p_reason     text default null
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_status rfq.request_status;
  v_actor  uuid := auth.uid();
begin
  perform rfq.fn_assert_request_buyer_owned(p_request_id);
  select status into v_status from rfq.requests where id = p_request_id;
  if v_status in ('closed', 'cancelled', 'expired') then
    raise exception 'rfq: invalid_transition: cannot cancel from %', v_status
      using errcode = 'P0001';
  end if;

  update rfq.requests
     set status           = 'cancelled',
         cancelled_at     = now(),
         cancelled_by     = v_actor,
         cancelled_reason = p_reason,
         updated_by       = v_actor
   where id = p_request_id;

  perform rfq.fn_record_status_event(p_request_id, v_status, 'cancelled',
    coalesce(p_reason, 'buyer_cancel'));
  perform rfq.fn_audit('rfq.cancelled', p_request_id,
    jsonb_build_object('reason', p_reason));
end;
$$;

-- 6.12 buyer_close_rfq : invited → closed ----------------------------------
create or replace function rfq.buyer_close_rfq(p_request_id uuid)
returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_status rfq.request_status;
  v_actor  uuid := auth.uid();
begin
  perform rfq.fn_assert_request_buyer_owned(p_request_id);
  select status into v_status from rfq.requests where id = p_request_id;
  if v_status not in ('invited', 'published') then
    raise exception 'rfq: invalid_transition: cannot close from %', v_status
      using errcode = 'P0001';
  end if;

  update rfq.requests
     set status     = 'closed',
         closed_at  = now(),
         closed_by  = v_actor,
         updated_by = v_actor
   where id = p_request_id;

  perform rfq.fn_record_status_event(p_request_id, v_status, 'closed', 'buyer_close');
  perform rfq.fn_audit('rfq.closed', p_request_id);
end;
$$;

-- 6.13 buyer_list_rfqs : list own org RFQs ---------------------------------
create or replace function rfq.buyer_list_rfqs(
  p_status rfq.request_status default null,
  p_limit  integer             default 25,
  p_offset integer             default 0
) returns table (
  id uuid, rfq_code text, title text, status text, visibility text,
  submission_deadline timestamptz, validity_until timestamptz,
  item_count bigint, invitation_count bigint,
  created_at timestamptz, updated_at timestamptz
)
language plpgsql stable security definer set search_path = ''
as $$
declare v_org uuid := rfq.fn_buyer_organization_id();
begin
  return query
    select r.id, r.rfq_code::text, r.title, r.status::text, r.visibility::text,
           r.submission_deadline, r.validity_until,
           (select count(*) from rfq.request_items i
             where i.request_id = r.id and i.deleted_at is null),
           (select count(*) from rfq.request_supplier_invitations inv
             where inv.request_id = r.id and inv.deleted_at is null),
           r.created_at, r.updated_at
      from rfq.requests r
     where r.organization_id = v_org
       and r.deleted_at is null
       and (p_status is null or r.status = p_status)
     order by r.created_at desc
     limit p_limit offset p_offset;
end;
$$;

-- 6.14 buyer_get_rfq : detail with items/specs/doc-reqs/invitations --------
create or replace function rfq.buyer_get_rfq(p_request_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_caller_org uuid := identity.current_organization_id();
  v_rfq_org uuid;
  v_result jsonb;
begin
  -- Buyer org members + platform admin can see. Suppliers don't use this RPC.
  select organization_id into v_rfq_org from rfq.requests where id = p_request_id and deleted_at is null;
  if v_rfq_org is null then
    raise exception 'rfq: request not found' using errcode = 'P0002';
  end if;
  if not identity.is_platform_admin() then
    if not (identity.has_role('buyer_admin') or identity.has_role('organization_admin')) then
      raise exception 'rfq: requires buyer_admin or admin' using errcode = '42501';
    end if;
    if v_caller_org is null or v_caller_org <> v_rfq_org then
      raise exception 'rfq: caller not in request owner organization' using errcode = '42501';
    end if;
  end if;

  select jsonb_build_object(
    'id', r.id,
    'rfq_code', r.rfq_code,
    'title', r.title,
    'description', r.description,
    'status', r.status,
    'visibility', r.visibility,
    'submission_deadline', r.submission_deadline,
    'validity_until', r.validity_until,
    'preferred_incoterms', r.preferred_incoterms,
    'preferred_currency', r.preferred_currency,
    'delivery_country', r.delivery_country,
    'delivery_city', r.delivery_city,
    'delivery_port', r.delivery_port,
    'delivery_location_text', r.delivery_location_text,
    'payment_terms_text', r.payment_terms_text,
    'internal_notes', r.internal_notes,
    'created_at', r.created_at,
    'updated_at', r.updated_at,
    'items', (
      select coalesce(jsonb_agg(jsonb_build_object(
        'id', i.id,
        'product_id', i.product_id,
        'quantity', i.quantity,
        'quantity_unit', i.quantity_unit,
        'packaging_preference', i.packaging_preference,
        'origin_country_preference', i.origin_country_preference,
        'origin_preference_notes', i.origin_preference_notes,
        'delivery_window_start', i.delivery_window_start,
        'delivery_window_end', i.delivery_window_end,
        'notes', i.notes,
        'sort_order', i.sort_order
      ) order by i.sort_order, i.created_at), '[]'::jsonb)
        from rfq.request_items i where i.request_id = r.id and i.deleted_at is null
    ),
    'item_specifications', (
      select coalesce(jsonb_agg(jsonb_build_object(
        'id', s.id, 'request_item_id', s.request_item_id, 'spec_key', s.spec_key,
        'display_name_fa', s.display_name_fa, 'display_name_en', s.display_name_en,
        'data_type', s.data_type, 'unit', s.unit, 'requested_value', s.requested_value,
        'min_value', s.min_value, 'max_value', s.max_value,
        'tolerance_text', s.tolerance_text, 'is_required', s.is_required
      ) order by s.sort_order), '[]'::jsonb)
        from rfq.request_item_specifications s
       where s.request_id = r.id and s.deleted_at is null
    ),
    'document_requirements', (
      select coalesce(jsonb_agg(jsonb_build_object(
        'id', d.id, 'request_item_id', d.request_item_id, 'scope', d.scope,
        'document_kind', d.document_kind, 'requirement_level', d.requirement_level,
        'display_name_fa', d.display_name_fa, 'display_name_en', d.display_name_en,
        'notes', d.notes, 'sort_order', d.sort_order
      ) order by d.sort_order), '[]'::jsonb)
        from rfq.request_document_requirements d
       where d.request_id = r.id and d.deleted_at is null and d.is_active
    ),
    'invitations', (
      select coalesce(jsonb_agg(jsonb_build_object(
        'id', inv.id, 'supplier_id', inv.supplier_id, 'status', inv.status,
        'invited_at', inv.invited_at, 'viewed_at', inv.viewed_at,
        'responded_at', inv.responded_at
      ) order by inv.invited_at), '[]'::jsonb)
        from rfq.request_supplier_invitations inv
       where inv.request_id = r.id and inv.deleted_at is null
    )
  ) into v_result
    from rfq.requests r
   where r.id = p_request_id;

  return v_result;
end;
$$;

-- ===========================================================================
-- 7. Supplier RPCs (read-only)
-- ===========================================================================

-- 7.1 supplier_list_rfq_invitations ----------------------------------------
create or replace function rfq.supplier_list_rfq_invitations(
  p_status rfq.invitation_status default null,
  p_limit  integer                 default 25,
  p_offset integer                 default 0
) returns table (
  invitation_id uuid, request_id uuid, rfq_code text, title text,
  invitation_status text, request_status text,
  submission_deadline timestamptz, invited_at timestamptz
)
language plpgsql stable security definer set search_path = ''
as $$
declare v_supplier_id uuid := supplier.fn_portal_supplier_id();
begin
  return query
    select inv.id, inv.request_id, r.rfq_code::text, r.title,
           inv.status::text, r.status::text,
           r.submission_deadline, inv.invited_at
      from rfq.request_supplier_invitations inv
      join rfq.requests r on r.id = inv.request_id
     where inv.supplier_id = v_supplier_id
       and inv.deleted_at is null
       and r.deleted_at is null
       and (p_status is null or inv.status = p_status)
     order by inv.invited_at desc
     limit p_limit offset p_offset;
end;
$$;

-- 7.2 supplier_get_rfq ------------------------------------------------------
create or replace function rfq.supplier_get_rfq(p_request_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_supplier_id uuid := supplier.fn_portal_supplier_id();
  v_result jsonb;
begin
  -- Caller's supplier must have an active invitation for this request.
  if not exists (
    select 1 from rfq.request_supplier_invitations inv
     where inv.request_id = p_request_id
       and inv.supplier_id = v_supplier_id
       and inv.deleted_at is null
  ) then
    raise exception 'rfq: caller supplier is not invited to this request' using errcode = 'P0002';
  end if;

  select jsonb_build_object(
    'id', r.id,
    'rfq_code', r.rfq_code,
    'title', r.title,
    'description', r.description,
    'status', r.status,
    'submission_deadline', r.submission_deadline,
    'validity_until', r.validity_until,
    'preferred_incoterms', r.preferred_incoterms,
    'preferred_currency', r.preferred_currency,
    'delivery_country', r.delivery_country,
    'delivery_city', r.delivery_city,
    'delivery_port', r.delivery_port,
    'delivery_location_text', r.delivery_location_text,
    'payment_terms_text', r.payment_terms_text,
    'items', (
      select coalesce(jsonb_agg(jsonb_build_object(
        'id', i.id, 'product_id', i.product_id,
        'quantity', i.quantity, 'quantity_unit', i.quantity_unit,
        'packaging_preference', i.packaging_preference,
        'origin_country_preference', i.origin_country_preference,
        'delivery_window_start', i.delivery_window_start,
        'delivery_window_end', i.delivery_window_end,
        'notes', i.notes
      ) order by i.sort_order), '[]'::jsonb)
        from rfq.request_items i where i.request_id = r.id and i.deleted_at is null
    ),
    'item_specifications', (
      select coalesce(jsonb_agg(jsonb_build_object(
        'id', s.id, 'request_item_id', s.request_item_id, 'spec_key', s.spec_key,
        'display_name_fa', s.display_name_fa, 'display_name_en', s.display_name_en,
        'data_type', s.data_type, 'unit', s.unit, 'requested_value', s.requested_value,
        'min_value', s.min_value, 'max_value', s.max_value, 'is_required', s.is_required
      ) order by s.sort_order), '[]'::jsonb)
        from rfq.request_item_specifications s
       where s.request_id = r.id and s.deleted_at is null
    ),
    'document_requirements', (
      select coalesce(jsonb_agg(jsonb_build_object(
        'id', d.id, 'request_item_id', d.request_item_id, 'scope', d.scope,
        'document_kind', d.document_kind, 'requirement_level', d.requirement_level,
        'display_name_fa', d.display_name_fa, 'display_name_en', d.display_name_en
      ) order by d.sort_order), '[]'::jsonb)
        from rfq.request_document_requirements d
       where d.request_id = r.id and d.deleted_at is null and d.is_active
    )
  ) into v_result
    from rfq.requests r where r.id = p_request_id;

  -- Note: view-tracking (setting invitation viewed_at) is intentionally not
  -- done here. supplier_get_rfq is `stable` (read-only). A future CC-10
  -- volatile RPC (e.g. supplier_acknowledge_invitation) will handle the
  -- invitation_status / viewed_at side effects.
  return v_result;
end;
$$;

-- ===========================================================================
-- 8. Admin RPCs
-- ===========================================================================

-- 8.1 admin_list_rfqs ------------------------------------------------------
create or replace function rfq.admin_list_rfqs(
  p_status          rfq.request_status default null,
  p_organization_id uuid               default null,
  p_limit           integer            default 25,
  p_offset          integer            default 0
) returns table (
  id uuid, organization_id uuid, rfq_code text, title text, status text,
  submission_deadline timestamptz, invitation_count bigint,
  created_at timestamptz, updated_at timestamptz
)
language plpgsql stable security definer set search_path = ''
as $$
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_list_rfqs: requires platform_admin' using errcode = '42501';
  end if;
  return query
    select r.id, r.organization_id, r.rfq_code::text, r.title, r.status::text,
           r.submission_deadline,
           (select count(*) from rfq.request_supplier_invitations inv
             where inv.request_id = r.id and inv.deleted_at is null),
           r.created_at, r.updated_at
      from rfq.requests r
     where r.deleted_at is null
       and (p_status is null or r.status = p_status)
       and (p_organization_id is null or r.organization_id = p_organization_id)
     order by r.created_at desc
     limit p_limit offset p_offset;
end;
$$;

-- 8.2 admin_get_rfq --------------------------------------------------------
create or replace function rfq.admin_get_rfq(p_request_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_get_rfq: requires platform_admin' using errcode = '42501';
  end if;
  return (
    select jsonb_build_object(
      'id', r.id, 'organization_id', r.organization_id,
      'rfq_code', r.rfq_code, 'title', r.title, 'description', r.description,
      'status', r.status, 'visibility', r.visibility,
      'submission_deadline', r.submission_deadline,
      'validity_until', r.validity_until,
      'created_at', r.created_at, 'updated_at', r.updated_at,
      'items', (
        select coalesce(jsonb_agg(jsonb_build_object(
          'id', i.id, 'product_id', i.product_id,
          'quantity', i.quantity, 'quantity_unit', i.quantity_unit
        )), '[]'::jsonb)
          from rfq.request_items i where i.request_id = r.id and i.deleted_at is null
      ),
      'invitations', (
        select coalesce(jsonb_agg(jsonb_build_object(
          'id', inv.id, 'supplier_id', inv.supplier_id, 'status', inv.status
        )), '[]'::jsonb)
          from rfq.request_supplier_invitations inv
         where inv.request_id = r.id and inv.deleted_at is null
      ),
      'status_events', (
        select coalesce(jsonb_agg(jsonb_build_object(
          'id', e.id, 'from_status', e.from_status, 'to_status', e.to_status,
          'actor_user_id', e.actor_user_id, 'reason', e.reason, 'created_at', e.created_at
        ) order by e.created_at), '[]'::jsonb)
          from rfq.request_status_events e where e.request_id = r.id
      )
    )
    from rfq.requests r where r.id = p_request_id
  );
end;
$$;

-- 8.3 admin_force_cancel_rfq -----------------------------------------------
create or replace function rfq.admin_force_cancel_rfq(
  p_request_id uuid,
  p_reason     text default null
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_status rfq.request_status;
  v_actor uuid := auth.uid();
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_force_cancel_rfq: requires platform_admin' using errcode = '42501';
  end if;
  select status into v_status from rfq.requests where id = p_request_id;
  if v_status is null then
    raise exception 'rfq: request not found' using errcode = 'P0002';
  end if;
  if v_status in ('closed', 'cancelled', 'expired') then
    raise exception 'rfq: invalid_transition: cannot force-cancel from %', v_status
      using errcode = 'P0001';
  end if;

  update rfq.requests
     set status           = 'cancelled',
         cancelled_at     = now(),
         cancelled_by     = v_actor,
         cancelled_reason = p_reason,
         updated_by       = v_actor
   where id = p_request_id;

  perform rfq.fn_record_status_event(p_request_id, v_status, 'cancelled',
    coalesce(p_reason, 'admin_force_cancel'));
  perform rfq.fn_audit('rfq.admin_force_cancelled', p_request_id,
    jsonb_build_object('reason', p_reason));
end;
$$;

-- 8.4 admin_force_close_rfq ------------------------------------------------
create or replace function rfq.admin_force_close_rfq(
  p_request_id uuid,
  p_reason     text default null
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_status rfq.request_status;
  v_actor uuid := auth.uid();
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_force_close_rfq: requires platform_admin' using errcode = '42501';
  end if;
  select status into v_status from rfq.requests where id = p_request_id;
  if v_status is null then
    raise exception 'rfq: request not found' using errcode = 'P0002';
  end if;
  if v_status not in ('invited', 'published') then
    raise exception 'rfq: invalid_transition: cannot force-close from %', v_status
      using errcode = 'P0001';
  end if;

  update rfq.requests
     set status     = 'closed',
         closed_at  = now(),
         closed_by  = v_actor,
         updated_by = v_actor
   where id = p_request_id;

  perform rfq.fn_record_status_event(p_request_id, v_status, 'closed',
    coalesce(p_reason, 'admin_force_close'));
  perform rfq.fn_audit('rfq.admin_force_closed', p_request_id);
end;
$$;

-- 8.5 admin_list_invitations -----------------------------------------------
create or replace function rfq.admin_list_invitations(
  p_request_id  uuid                          default null,
  p_supplier_id uuid                          default null,
  p_status      rfq.invitation_status         default null,
  p_limit       integer                       default 50,
  p_offset      integer                       default 0
) returns table (
  id uuid, request_id uuid, supplier_id uuid, status text,
  invited_at timestamptz, viewed_at timestamptz, responded_at timestamptz
)
language plpgsql stable security definer set search_path = ''
as $$
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_list_invitations: requires platform_admin' using errcode = '42501';
  end if;
  return query
    select inv.id, inv.request_id, inv.supplier_id, inv.status::text,
           inv.invited_at, inv.viewed_at, inv.responded_at
      from rfq.request_supplier_invitations inv
     where inv.deleted_at is null
       and (p_request_id  is null or inv.request_id  = p_request_id)
       and (p_supplier_id is null or inv.supplier_id = p_supplier_id)
       and (p_status      is null or inv.status      = p_status)
     order by inv.invited_at desc
     limit p_limit offset p_offset;
end;
$$;

-- ===========================================================================
-- 9. Trigger attachments
-- ===========================================================================
do $$
declare r record;
begin
  for r in
    select t.table_schema, t.table_name
      from information_schema.tables t
      join information_schema.columns c
        on c.table_schema = t.table_schema and c.table_name = t.table_name
     where t.table_schema = 'rfq'
       and t.table_type   = 'BASE TABLE'
       and c.column_name  = 'updated_at'
  loop
    execute format(
      'drop trigger if exists trg_set_updated_at on %I.%I',
      r.table_schema, r.table_name
    );
    execute format(
      'create trigger trg_set_updated_at before update on %I.%I '
      'for each row execute function identity.set_updated_at()',
      r.table_schema, r.table_name
    );
  end loop;
end;
$$;

do $$
declare r record;
begin
  for r in
    select t.table_schema, t.table_name
      from information_schema.tables t
     where t.table_schema = 'rfq'
       and t.table_type   = 'BASE TABLE'
       and exists (
         select 1 from information_schema.columns c
          where c.table_schema = t.table_schema
            and c.table_name   = t.table_name
            and c.column_name  = 'id'
       )
  loop
    execute format(
      'drop trigger if exists trg_audit_entity on %I.%I',
      r.table_schema, r.table_name
    );
    execute format(
      'create trigger trg_audit_entity after insert or update or delete on %I.%I '
      'for each row execute function audit.fn_audit_entity()',
      r.table_schema, r.table_name
    );
  end loop;
end;
$$;

-- ===========================================================================
-- 10. Grants (SELECT only on tables; no INSERT/UPDATE/DELETE)
-- ===========================================================================
grant select on rfq.requests                      to anon, authenticated;
grant select on rfq.request_items                 to anon, authenticated;
grant select on rfq.request_item_specifications   to anon, authenticated;
grant select on rfq.request_document_requirements to anon, authenticated;
grant select on rfq.request_supplier_invitations  to anon, authenticated;
grant select on rfq.request_status_events         to authenticated;

-- ===========================================================================
-- 11. RPC EXECUTE grants
-- ===========================================================================
grant execute on function rfq.buyer_create_rfq(
  text, text, rfq.visibility_model, timestamptz, timestamptz, jsonb,
  text, char, text, text, text, text
) to authenticated;

grant execute on function rfq.buyer_update_rfq(
  uuid, text, text, rfq.visibility_model, timestamptz, timestamptz, jsonb,
  text, char, text, text, text, text, text
) to authenticated;

grant execute on function rfq.buyer_upsert_rfq_item(
  uuid, uuid, uuid, numeric, text, text, char, text, date, date, text, integer
) to authenticated;

grant execute on function rfq.buyer_remove_rfq_item(uuid) to authenticated;

grant execute on function rfq.buyer_upsert_item_specification(
  uuid, text, text, text, commodity.spec_data_type, text, text,
  numeric, numeric, text, boolean, uuid, integer, text
) to authenticated;

grant execute on function rfq.buyer_remove_item_specification(uuid) to authenticated;

grant execute on function rfq.buyer_upsert_doc_requirement(
  uuid, uuid, commodity.document_kind, commodity.document_requirement_level,
  text, text, text, integer, uuid
) to authenticated;

grant execute on function rfq.buyer_remove_doc_requirement(uuid) to authenticated;

grant execute on function rfq.buyer_submit_rfq(uuid) to authenticated;
grant execute on function rfq.buyer_invite_suppliers(uuid, uuid[], text) to authenticated;
grant execute on function rfq.buyer_cancel_rfq(uuid, text) to authenticated;
grant execute on function rfq.buyer_close_rfq(uuid) to authenticated;
grant execute on function rfq.buyer_list_rfqs(rfq.request_status, integer, integer) to authenticated;
grant execute on function rfq.buyer_get_rfq(uuid) to authenticated;

grant execute on function rfq.supplier_list_rfq_invitations(
  rfq.invitation_status, integer, integer
) to authenticated;
grant execute on function rfq.supplier_get_rfq(uuid) to authenticated;

grant execute on function rfq.admin_list_rfqs(
  rfq.request_status, uuid, integer, integer
) to authenticated;
grant execute on function rfq.admin_get_rfq(uuid) to authenticated;
grant execute on function rfq.admin_force_cancel_rfq(uuid, text) to authenticated;
grant execute on function rfq.admin_force_close_rfq(uuid, text) to authenticated;
grant execute on function rfq.admin_list_invitations(
  uuid, uuid, rfq.invitation_status, integer, integer
) to authenticated;
