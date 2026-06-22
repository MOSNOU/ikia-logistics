-- CC-07 / Migration 0018 — Supplier Foundation
-- First business-domain schema. Builds on the verified CC-01 to CC-06 platform.
-- Append-only over migrations 0001-0017.
--
-- Locked decisions applied:
--   1. Single migration (0018_supplier_foundation.sql)
--   2. Trigger-based shell creation on organization.type='supplier'
--   3. RPC namespace: supplier.admin_* + supplier.portal_*
--   4. Documents: external_reference free text
--   5. Categories: seed-only
--   6. supplier_admin role assignment via CC-06 (no convenience wrapper here)
--
-- Corrections applied:
--   A. portal_remove_my_category is soft-delete (deleted_at + updated_by)
--   B. supplier.categories visible to authenticated only (NOT anon)
--   C. Portal RPCs accept supplier_admin OR organization_admin OR platform_admin
--   D/E/F: covered by the new pgTAP tests + frontend script

-- ===========================================================================
-- 1. Schema
-- ===========================================================================
create schema if not exists supplier;
grant usage on schema supplier to anon, authenticated, service_role;
comment on schema supplier is
  'iKIA Phase 2 — supplier business domain: profile, categories, documents.';

-- ===========================================================================
-- 2. Enums
-- ===========================================================================
create type supplier.supplier_status as enum (
  'draft', 'submitted', 'under_review', 'approved', 'suspended', 'rejected'
);

create type supplier.verification_status as enum (
  'unverified', 'pending', 'verified', 'expired', 'rejected'
);

create type supplier.document_type as enum (
  'license', 'tax_certificate', 'registration', 'iso_certificate',
  'bank_letter', 'other'
);

create type supplier.document_status as enum (
  'pending', 'verified', 'rejected', 'expired'
);

-- ===========================================================================
-- 3. Tables
-- ===========================================================================
create table supplier.suppliers (
  id                      uuid primary key default gen_random_uuid(),
  tenant_id               uuid not null references identity.tenants(id) on delete restrict,
  organization_id         uuid not null references organization.organizations(id) on delete cascade,

  display_name            text,
  description             text,
  website                 text,
  contact_email           citext,
  contact_phone           text,
  country_code            char(2),
  established_year        integer,

  status                  supplier.supplier_status not null default 'draft',
  verification_status     supplier.verification_status not null default 'unverified',

  submitted_at            timestamptz,
  submitted_by            uuid references auth.users(id),
  approved_at             timestamptz,
  approved_by             uuid references auth.users(id),
  rejected_at             timestamptz,
  rejected_by             uuid references auth.users(id),
  rejected_reason         text,
  suspended_at            timestamptz,
  suspended_by            uuid references auth.users(id),
  suspended_reason        text,
  verification_set_at     timestamptz,
  verification_set_by     uuid references auth.users(id),
  verification_reason     text,

  created_by              uuid references auth.users(id),
  created_at              timestamptz not null default now(),
  updated_by              uuid references auth.users(id),
  updated_at              timestamptz not null default now(),
  deleted_at              timestamptz,
  version                 integer not null default 1,

  unique (organization_id)
);

comment on table supplier.suppliers is
  '1:1 with organization where type=supplier. Trigger trg_create_supplier_shell creates the draft row.';

create index suppliers_tenant_idx              on supplier.suppliers(tenant_id);
create index suppliers_status_idx              on supplier.suppliers(status);
create index suppliers_verification_status_idx on supplier.suppliers(verification_status);

create table supplier.categories (
  id                  uuid primary key default gen_random_uuid(),
  code                citext not null unique,
  name_fa             text not null,
  name_en             text not null,
  description         text,
  parent_category_id  uuid references supplier.categories(id) on delete set null,
  is_active           boolean not null default true,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now()
);

comment on table supplier.categories is
  'Supplier category lookup. Seed-only in CC-07. Read by authenticated; mutated by platform_admin (RLS backstop).';

create table supplier.supplier_categories (
  id              uuid primary key default gen_random_uuid(),
  tenant_id       uuid not null references identity.tenants(id) on delete restrict,
  organization_id uuid not null references organization.organizations(id) on delete cascade,
  supplier_id     uuid not null references supplier.suppliers(id) on delete cascade,
  category_id     uuid not null references supplier.categories(id) on delete restrict,
  created_by      uuid references auth.users(id),
  created_at      timestamptz not null default now(),
  updated_by      uuid references auth.users(id),
  updated_at      timestamptz not null default now(),
  deleted_at      timestamptz,
  version         integer not null default 1
);

-- Partial unique on active rows so soft-deleted entries can coexist.
create unique index supplier_categories_unique_active
  on supplier.supplier_categories(supplier_id, category_id)
  where deleted_at is null;

create index supplier_categories_supplier_idx on supplier.supplier_categories(supplier_id);
create index supplier_categories_org_idx      on supplier.supplier_categories(organization_id);

comment on table supplier.supplier_categories is
  'Supplier ↔ category junction. Soft-delete only — never hard DELETE. Partial unique index allows revive after soft-delete.';

create table supplier.supplier_documents (
  id                  uuid primary key default gen_random_uuid(),
  tenant_id           uuid not null references identity.tenants(id) on delete restrict,
  organization_id     uuid not null references organization.organizations(id) on delete cascade,
  supplier_id         uuid not null references supplier.suppliers(id) on delete cascade,
  document_type       supplier.document_type not null,
  title               text not null,
  description         text,
  external_reference  text,
  issued_at           date,
  expires_at          date,
  status              supplier.document_status not null default 'pending',
  verified_at         timestamptz,
  verified_by         uuid references auth.users(id),
  rejection_reason    text,
  created_by          uuid references auth.users(id),
  created_at          timestamptz not null default now(),
  updated_by          uuid references auth.users(id),
  updated_at          timestamptz not null default now(),
  deleted_at          timestamptz,
  version             integer not null default 1
);

comment on table supplier.supplier_documents is
  'Supplier document metadata. external_reference is free text in CC-07 (no URL validation, no file storage).';

create index supplier_documents_supplier_idx on supplier.supplier_documents(supplier_id);
create index supplier_documents_org_idx      on supplier.supplier_documents(organization_id);
create index supplier_documents_status_idx   on supplier.supplier_documents(status);

-- ===========================================================================
-- 4. Trigger: auto-shell on organization.type='supplier'
-- ===========================================================================
create or replace function supplier.fn_create_supplier_shell()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.type = 'supplier' then
    insert into supplier.suppliers (
      tenant_id, organization_id, display_name, status, verification_status,
      created_by, updated_by
    ) values (
      new.tenant_id, new.id, new.name_fa, 'draft', 'unverified',
      new.created_by, new.created_by
    )
    on conflict (organization_id) do nothing;
  end if;
  return new;
end;
$$;

comment on function supplier.fn_create_supplier_shell() is
  'AFTER INSERT trigger on organization.organizations. Idempotent (ON CONFLICT DO NOTHING) so re-runs are safe.';

drop trigger if exists trg_create_supplier_shell on organization.organizations;
create trigger trg_create_supplier_shell
  after insert on organization.organizations
  for each row execute function supplier.fn_create_supplier_shell();

-- ===========================================================================
-- 5. Seed categories
-- ===========================================================================
insert into supplier.categories (code, name_fa, name_en) values
  ('agriculture',           'کشاورزی',              'Agriculture'),
  ('food_processing',       'فرآوری مواد غذایی',    'Food Processing'),
  ('manufacturing',         'تولید',                'Manufacturing'),
  ('construction',          'ساختمانی',             'Construction'),
  ('chemicals',             'مواد شیمیایی',         'Chemicals'),
  ('minerals',              'معدنی',                'Minerals & Mining'),
  ('petroleum',             'نفت و گاز',            'Petroleum'),
  ('machinery',             'ماشین‌آلات',           'Machinery'),
  ('electronics',           'الکترونیک',            'Electronics'),
  ('textile',               'نساجی',                'Textile'),
  ('logistics_services',    'خدمات لجستیک',         'Logistics Services'),
  ('professional_services', 'خدمات تخصصی',          'Professional Services')
on conflict (code) do nothing;

-- ===========================================================================
-- 6. Row Level Security
-- ===========================================================================
alter table supplier.suppliers           enable row level security;
alter table supplier.categories          enable row level security;
alter table supplier.supplier_categories enable row level security;
alter table supplier.supplier_documents  enable row level security;

-- supplier.suppliers --------------------------------------------------------
drop policy if exists suppliers_select on supplier.suppliers;
create policy suppliers_select on supplier.suppliers
  for select
  using (
    deleted_at is null
    and (
      identity.is_platform_admin()
      or exists (
        select 1 from organization.memberships m
         where m.user_id = identity.current_user_id()
           and m.organization_id = supplier.suppliers.organization_id
           and m.deleted_at is null
           and m.status = 'active'
      )
    )
  );

drop policy if exists suppliers_select_deleted on supplier.suppliers;
create policy suppliers_select_deleted on supplier.suppliers
  for select
  using (
    deleted_at is not null
    and (identity.is_platform_admin() or identity.has_role('compliance_officer'))
  );

drop policy if exists suppliers_admin_modify on supplier.suppliers;
create policy suppliers_admin_modify on supplier.suppliers
  for all
  using (identity.is_platform_admin())
  with check (identity.is_platform_admin());

-- supplier.categories (correction B: authenticated only, NOT anon) ----------
drop policy if exists categories_select on supplier.categories;
create policy categories_select on supplier.categories
  for select
  using (auth.role() = 'authenticated');

drop policy if exists categories_modify on supplier.categories;
create policy categories_modify on supplier.categories
  for all
  using (identity.is_platform_admin())
  with check (identity.is_platform_admin());

-- supplier.supplier_categories ----------------------------------------------
drop policy if exists supplier_categories_select on supplier.supplier_categories;
create policy supplier_categories_select on supplier.supplier_categories
  for select
  using (
    deleted_at is null
    and (
      identity.is_platform_admin()
      or exists (
        select 1 from organization.memberships m
         where m.user_id = identity.current_user_id()
           and m.organization_id = supplier.supplier_categories.organization_id
           and m.deleted_at is null
           and m.status = 'active'
      )
    )
  );

drop policy if exists supplier_categories_select_deleted on supplier.supplier_categories;
create policy supplier_categories_select_deleted on supplier.supplier_categories
  for select
  using (
    deleted_at is not null
    and (identity.is_platform_admin() or identity.has_role('compliance_officer'))
  );

drop policy if exists supplier_categories_admin_modify on supplier.supplier_categories;
create policy supplier_categories_admin_modify on supplier.supplier_categories
  for all
  using (identity.is_platform_admin())
  with check (identity.is_platform_admin());

-- supplier.supplier_documents -----------------------------------------------
drop policy if exists supplier_documents_select on supplier.supplier_documents;
create policy supplier_documents_select on supplier.supplier_documents
  for select
  using (
    deleted_at is null
    and (
      identity.is_platform_admin()
      or exists (
        select 1 from organization.memberships m
         where m.user_id = identity.current_user_id()
           and m.organization_id = supplier.supplier_documents.organization_id
           and m.deleted_at is null
           and m.status = 'active'
      )
    )
  );

drop policy if exists supplier_documents_select_deleted on supplier.supplier_documents;
create policy supplier_documents_select_deleted on supplier.supplier_documents
  for select
  using (
    deleted_at is not null
    and (identity.is_platform_admin() or identity.has_role('compliance_officer'))
  );

drop policy if exists supplier_documents_admin_modify on supplier.supplier_documents;
create policy supplier_documents_admin_modify on supplier.supplier_documents
  for all
  using (identity.is_platform_admin())
  with check (identity.is_platform_admin());

-- ===========================================================================
-- 7. Admin RPCs (9). All SECURITY DEFINER, set search_path = '', 42501 on
--    unauthorized callers, audit event on every state mutation.
-- ===========================================================================

-- 7.1 list ------------------------------------------------------------------
create or replace function supplier.admin_list_suppliers(
  p_limit               int                            default 25,
  p_offset              int                            default 0,
  p_status_filter       supplier.supplier_status       default null,
  p_verification_filter supplier.verification_status   default null
)
returns table (
  supplier_id             uuid,
  organization_id         uuid,
  organization_code       text,
  organization_name_fa    text,
  organization_name_en    text,
  display_name            text,
  status                  text,
  verification_status     text,
  category_count          bigint,
  document_count          bigint,
  created_at              timestamptz,
  updated_at              timestamptz
)
language plpgsql stable security definer set search_path = ''
as $$
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_list_suppliers: requires platform_admin' using errcode = '42501';
  end if;
  return query
    select s.id, s.organization_id,
           o.code::text, o.name_fa, o.name_en,
           s.display_name,
           s.status::text, s.verification_status::text,
           (select count(*) from supplier.supplier_categories sc
             where sc.supplier_id = s.id and sc.deleted_at is null),
           (select count(*) from supplier.supplier_documents sd
             where sd.supplier_id = s.id and sd.deleted_at is null),
           s.created_at, s.updated_at
      from supplier.suppliers s
      join organization.organizations o on o.id = s.organization_id
     where s.deleted_at is null
       and (p_status_filter       is null or s.status              = p_status_filter)
       and (p_verification_filter is null or s.verification_status = p_verification_filter)
     order by s.created_at desc
     limit p_limit offset p_offset;
end;
$$;

-- 7.2 get -------------------------------------------------------------------
create or replace function supplier.admin_get_supplier(p_supplier_id uuid)
returns table (
  supplier_id             uuid,
  organization_id         uuid,
  organization_code       text,
  organization_name_fa    text,
  organization_name_en    text,
  display_name            text,
  description             text,
  website                 text,
  contact_email           text,
  contact_phone           text,
  country_code            text,
  established_year        integer,
  status                  text,
  verification_status     text,
  submitted_at            timestamptz,
  approved_at             timestamptz,
  rejected_at             timestamptz,
  rejected_reason         text,
  suspended_at            timestamptz,
  suspended_reason        text,
  verification_set_at     timestamptz,
  verification_reason     text,
  category_count          bigint,
  document_count          bigint,
  created_at              timestamptz,
  updated_at              timestamptz
)
language plpgsql stable security definer set search_path = ''
as $$
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_get_supplier: requires platform_admin' using errcode = '42501';
  end if;
  return query
    select s.id, s.organization_id,
           o.code::text, o.name_fa, o.name_en,
           s.display_name, s.description, s.website,
           s.contact_email::text, s.contact_phone, s.country_code::text,
           s.established_year,
           s.status::text, s.verification_status::text,
           s.submitted_at, s.approved_at,
           s.rejected_at, s.rejected_reason,
           s.suspended_at, s.suspended_reason,
           s.verification_set_at, s.verification_reason,
           (select count(*) from supplier.supplier_categories sc
             where sc.supplier_id = s.id and sc.deleted_at is null),
           (select count(*) from supplier.supplier_documents sd
             where sd.supplier_id = s.id and sd.deleted_at is null),
           s.created_at, s.updated_at
      from supplier.suppliers s
      join organization.organizations o on o.id = s.organization_id
     where s.id = p_supplier_id;
end;
$$;

-- Internal helper: write a supplier audit event. Wrapped in caller's nested
-- begin/exception so audit failure never blocks the operation.
create or replace function supplier.fn_audit(
  p_supplier_id   uuid,
  p_action_code   text,
  p_payload       jsonb default '{}'::jsonb
) returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_t uuid;
  v_o uuid;
begin
  select tenant_id, organization_id into v_t, v_o
    from supplier.suppliers where id = p_supplier_id;
  insert into audit.audit_event (
    tenant_id, organization_id, actor_user_id, action_code,
    resource_type, resource_id, payload, occurred_at
  ) values (
    v_t, v_o, auth.uid(), p_action_code,
    'supplier', p_supplier_id, p_payload, now()
  );
exception when others then
  null;
end;
$$;

-- 7.3 start_review : submitted → under_review -------------------------------
create or replace function supplier.admin_start_review(p_supplier_id uuid)
returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_current supplier.supplier_status;
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_start_review: requires platform_admin' using errcode = '42501';
  end if;
  select status into v_current from supplier.suppliers where id = p_supplier_id;
  if v_current is null then
    raise exception 'supplier not found' using errcode = 'P0002';
  end if;
  if v_current <> 'submitted' then
    raise exception 'invalid_transition: cannot start review from %', v_current
      using errcode = 'P0001';
  end if;
  update supplier.suppliers
     set status = 'under_review', updated_by = auth.uid()
   where id = p_supplier_id;
  perform supplier.fn_audit(p_supplier_id, 'supplier.review_started');
end;
$$;

-- 7.4 approve : under_review → approved (also reactivation pathway) ---------
create or replace function supplier.admin_approve_supplier(p_supplier_id uuid)
returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_current supplier.supplier_status;
  v_actor uuid := auth.uid();
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_approve_supplier: requires platform_admin' using errcode = '42501';
  end if;
  select status into v_current from supplier.suppliers where id = p_supplier_id;
  if v_current is null then
    raise exception 'supplier not found' using errcode = 'P0002';
  end if;
  if v_current not in ('under_review', 'suspended') then
    raise exception 'invalid_transition: cannot approve from %', v_current
      using errcode = 'P0001';
  end if;
  update supplier.suppliers
     set status = 'approved',
         approved_at = now(),
         approved_by = v_actor,
         updated_by  = v_actor
   where id = p_supplier_id;
  perform supplier.fn_audit(
    p_supplier_id,
    case when v_current = 'suspended' then 'supplier.reactivated' else 'supplier.approved' end
  );
end;
$$;

-- 7.5 reject : under_review → rejected --------------------------------------
create or replace function supplier.admin_reject_supplier(
  p_supplier_id uuid,
  p_reason      text default null
)
returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_current supplier.supplier_status;
  v_actor uuid := auth.uid();
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_reject_supplier: requires platform_admin' using errcode = '42501';
  end if;
  select status into v_current from supplier.suppliers where id = p_supplier_id;
  if v_current is null then
    raise exception 'supplier not found' using errcode = 'P0002';
  end if;
  if v_current <> 'under_review' then
    raise exception 'invalid_transition: cannot reject from %', v_current
      using errcode = 'P0001';
  end if;
  update supplier.suppliers
     set status = 'rejected',
         rejected_at = now(),
         rejected_by = v_actor,
         rejected_reason = p_reason,
         updated_by = v_actor
   where id = p_supplier_id;
  perform supplier.fn_audit(
    p_supplier_id, 'supplier.rejected',
    jsonb_build_object('reason', p_reason)
  );
end;
$$;

-- 7.6 suspend : approved → suspended ----------------------------------------
create or replace function supplier.admin_suspend_supplier(
  p_supplier_id uuid,
  p_reason      text default null
)
returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_current supplier.supplier_status;
  v_actor uuid := auth.uid();
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_suspend_supplier: requires platform_admin' using errcode = '42501';
  end if;
  select status into v_current from supplier.suppliers where id = p_supplier_id;
  if v_current is null then
    raise exception 'supplier not found' using errcode = 'P0002';
  end if;
  if v_current <> 'approved' then
    raise exception 'invalid_transition: cannot suspend from %', v_current
      using errcode = 'P0001';
  end if;
  update supplier.suppliers
     set status = 'suspended',
         suspended_at = now(),
         suspended_by = v_actor,
         suspended_reason = p_reason,
         updated_by = v_actor
   where id = p_supplier_id;
  perform supplier.fn_audit(
    p_supplier_id, 'supplier.suspended',
    jsonb_build_object('reason', p_reason)
  );
end;
$$;

-- 7.7 reactivate : suspended → approved (delegates to admin_approve) --------
create or replace function supplier.admin_reactivate_supplier(p_supplier_id uuid)
returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_current supplier.supplier_status;
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_reactivate_supplier: requires platform_admin' using errcode = '42501';
  end if;
  select status into v_current from supplier.suppliers where id = p_supplier_id;
  if v_current is null then
    raise exception 'supplier not found' using errcode = 'P0002';
  end if;
  if v_current <> 'suspended' then
    raise exception 'invalid_transition: cannot reactivate from %', v_current
      using errcode = 'P0001';
  end if;
  -- Delegate to admin_approve_supplier which already handles suspended → approved.
  perform supplier.admin_approve_supplier(p_supplier_id);
end;
$$;

-- 7.8 set verification status -----------------------------------------------
create or replace function supplier.admin_set_verification_status(
  p_supplier_id uuid,
  p_status      supplier.verification_status,
  p_reason      text default null
)
returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_set_verification_status: requires platform_admin' using errcode = '42501';
  end if;
  update supplier.suppliers
     set verification_status = p_status,
         verification_set_at = now(),
         verification_set_by = v_actor,
         verification_reason = p_reason,
         updated_by          = v_actor
   where id = p_supplier_id;
  if not found then
    raise exception 'supplier not found' using errcode = 'P0002';
  end if;
  perform supplier.fn_audit(
    p_supplier_id, 'supplier.verification_set',
    jsonb_build_object('status', p_status::text, 'reason', p_reason)
  );
end;
$$;

-- 7.9 set document status ---------------------------------------------------
create or replace function supplier.admin_set_document_status(
  p_document_id uuid,
  p_status      supplier.document_status,
  p_reason      text default null
)
returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor       uuid := auth.uid();
  v_supplier_id uuid;
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_set_document_status: requires platform_admin' using errcode = '42501';
  end if;
  select supplier_id into v_supplier_id
    from supplier.supplier_documents where id = p_document_id;
  if v_supplier_id is null then
    raise exception 'document not found' using errcode = 'P0002';
  end if;
  update supplier.supplier_documents
     set status = p_status,
         verified_at = case when p_status = 'verified' then now() else verified_at end,
         verified_by = case when p_status = 'verified' then v_actor else verified_by end,
         rejection_reason = case when p_status = 'rejected' then p_reason else rejection_reason end,
         updated_by = v_actor
   where id = p_document_id;
  perform supplier.fn_audit(
    v_supplier_id, 'supplier.document_status_set',
    jsonb_build_object(
      'document_id', p_document_id::text,
      'status', p_status::text,
      'reason', p_reason
    )
  );
end;
$$;

-- ===========================================================================
-- 8. Portal RPCs (6). Correction C: accept supplier_admin OR organization_admin
--    OR platform_admin for the current active organization.
-- ===========================================================================

-- Internal helper for portal authorization.
create or replace function supplier.fn_portal_supplier_id()
returns uuid
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_org_id      uuid := identity.current_organization_id();
  v_supplier_id uuid;
begin
  if not (
    identity.is_platform_admin()
    or identity.has_role('organization_admin')
    or identity.has_role('supplier_admin')
  ) then
    raise exception 'portal: requires supplier_admin, organization_admin or platform_admin'
      using errcode = '42501';
  end if;
  if v_org_id is null then
    raise exception 'portal: no active organization in JWT' using errcode = 'P0002';
  end if;
  select id into v_supplier_id
    from supplier.suppliers
   where organization_id = v_org_id and deleted_at is null;
  if v_supplier_id is null then
    raise exception 'portal: no supplier profile for active organization'
      using errcode = 'P0002';
  end if;
  return v_supplier_id;
end;
$$;

-- 8.1 upsert profile (only when status='draft') -----------------------------
create or replace function supplier.portal_upsert_my_profile(
  p_display_name      text default null,
  p_description       text default null,
  p_website           text default null,
  p_contact_email     citext default null,
  p_contact_phone     text default null,
  p_country_code      char(2) default null,
  p_established_year  integer default null
)
returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_supplier_id uuid := supplier.fn_portal_supplier_id();
  v_actor       uuid := auth.uid();
  v_current     supplier.supplier_status;
begin
  select status into v_current from supplier.suppliers where id = v_supplier_id;
  if v_current <> 'draft' then
    raise exception 'profile is locked: status=%', v_current using errcode = 'P0001';
  end if;
  update supplier.suppliers
     set display_name     = coalesce(p_display_name,     display_name),
         description      = coalesce(p_description,      description),
         website          = coalesce(p_website,          website),
         contact_email    = coalesce(p_contact_email,    contact_email),
         contact_phone    = coalesce(p_contact_phone,    contact_phone),
         country_code     = coalesce(p_country_code,     country_code),
         established_year = coalesce(p_established_year, established_year),
         updated_by       = v_actor
   where id = v_supplier_id;
  perform supplier.fn_audit(v_supplier_id, 'supplier.profile_updated');
end;
$$;

-- 8.2 add category (idempotent; revives soft-deleted row) -------------------
create or replace function supplier.portal_add_my_category(p_category_id uuid)
returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_supplier_id uuid := supplier.fn_portal_supplier_id();
  v_actor       uuid := auth.uid();
  v_tenant      uuid;
  v_org         uuid;
  v_active      boolean;
begin
  select tenant_id, organization_id into v_tenant, v_org
    from supplier.suppliers where id = v_supplier_id;

  if not exists (select 1 from supplier.categories where id = p_category_id and is_active) then
    raise exception 'category not found or inactive' using errcode = 'P0002';
  end if;

  -- Revive soft-deleted row if any.
  update supplier.supplier_categories
     set deleted_at = null, updated_by = v_actor
   where supplier_id = v_supplier_id
     and category_id = p_category_id
     and deleted_at is not null;
  if found then
    perform supplier.fn_audit(v_supplier_id, 'supplier.category_added',
      jsonb_build_object('category_id', p_category_id::text, 'revived', true));
    return;
  end if;

  -- Check active duplicate, then insert.
  select true into v_active
    from supplier.supplier_categories
   where supplier_id = v_supplier_id
     and category_id = p_category_id
     and deleted_at is null
   limit 1;
  if v_active is not null then
    return;
  end if;

  insert into supplier.supplier_categories (
    tenant_id, organization_id, supplier_id, category_id, created_by, updated_by
  ) values (
    v_tenant, v_org, v_supplier_id, p_category_id, v_actor, v_actor
  );
  perform supplier.fn_audit(v_supplier_id, 'supplier.category_added',
    jsonb_build_object('category_id', p_category_id::text, 'revived', false));
end;
$$;

-- 8.3 remove category (SOFT-DELETE per correction A) ------------------------
create or replace function supplier.portal_remove_my_category(p_category_id uuid)
returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_supplier_id uuid := supplier.fn_portal_supplier_id();
  v_actor       uuid := auth.uid();
begin
  update supplier.supplier_categories
     set deleted_at = now(),
         updated_by = v_actor
   where supplier_id = v_supplier_id
     and category_id = p_category_id
     and deleted_at is null;
  if not found then
    return;  -- already removed or never existed; idempotent no-op
  end if;
  perform supplier.fn_audit(v_supplier_id, 'supplier.category_removed',
    jsonb_build_object('category_id', p_category_id::text));
end;
$$;

-- 8.4 add document ----------------------------------------------------------
create or replace function supplier.portal_add_my_document(
  p_document_type     supplier.document_type,
  p_title             text,
  p_description       text default null,
  p_external_reference text default null,
  p_issued_at         date default null,
  p_expires_at        date default null
)
returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_supplier_id uuid := supplier.fn_portal_supplier_id();
  v_actor       uuid := auth.uid();
  v_tenant      uuid;
  v_org         uuid;
  v_id          uuid;
begin
  if p_title is null or btrim(p_title) = '' then
    raise exception 'document title is required' using errcode = '22023';
  end if;
  select tenant_id, organization_id into v_tenant, v_org
    from supplier.suppliers where id = v_supplier_id;

  insert into supplier.supplier_documents (
    tenant_id, organization_id, supplier_id, document_type, title, description,
    external_reference, issued_at, expires_at, status, created_by, updated_by
  ) values (
    v_tenant, v_org, v_supplier_id, p_document_type, p_title, p_description,
    p_external_reference, p_issued_at, p_expires_at, 'pending', v_actor, v_actor
  )
  returning id into v_id;

  perform supplier.fn_audit(v_supplier_id, 'supplier.document_added',
    jsonb_build_object(
      'document_id', v_id::text,
      'document_type', p_document_type::text
    ));
  return v_id;
end;
$$;

-- 8.5 remove document (soft-delete; only when status='pending') --------------
create or replace function supplier.portal_remove_my_document(p_document_id uuid)
returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_supplier_id uuid := supplier.fn_portal_supplier_id();
  v_actor       uuid := auth.uid();
  v_doc_status  supplier.document_status;
  v_doc_supplier uuid;
begin
  select status, supplier_id into v_doc_status, v_doc_supplier
    from supplier.supplier_documents
   where id = p_document_id and deleted_at is null;
  if v_doc_status is null then
    raise exception 'document not found' using errcode = 'P0002';
  end if;
  if v_doc_supplier <> v_supplier_id then
    raise exception 'document does not belong to active supplier' using errcode = '42501';
  end if;
  if v_doc_status <> 'pending' then
    raise exception 'cannot remove document with status=%', v_doc_status using errcode = 'P0001';
  end if;
  update supplier.supplier_documents
     set deleted_at = now(), updated_by = v_actor
   where id = p_document_id;
  perform supplier.fn_audit(v_supplier_id, 'supplier.document_removed',
    jsonb_build_object('document_id', p_document_id::text));
end;
$$;

-- 8.6 submit for review : draft → submitted ---------------------------------
create or replace function supplier.portal_submit_my_profile_for_review()
returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_supplier_id uuid := supplier.fn_portal_supplier_id();
  v_actor       uuid := auth.uid();
  v_current     supplier.supplier_status;
begin
  select status into v_current from supplier.suppliers where id = v_supplier_id;
  if v_current <> 'draft' then
    raise exception 'invalid_transition: cannot submit from %', v_current using errcode = 'P0001';
  end if;
  update supplier.suppliers
     set status = 'submitted',
         submitted_at = now(),
         submitted_by = v_actor,
         updated_by   = v_actor
   where id = v_supplier_id;
  perform supplier.fn_audit(v_supplier_id, 'supplier.submitted');
end;
$$;

-- ===========================================================================
-- 9. Attach set_updated_at + audit triggers to every supplier.* table.
-- ===========================================================================
do $$
declare r record;
begin
  for r in
    select t.table_schema, t.table_name
      from information_schema.tables t
      join information_schema.columns c
        on c.table_schema = t.table_schema and c.table_name = t.table_name
     where t.table_schema = 'supplier'
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
     where t.table_schema = 'supplier'
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
--     Correction B: supplier.categories is authenticated-only, NOT anon.
-- ===========================================================================
grant select on supplier.suppliers           to anon, authenticated;
grant select on supplier.supplier_categories to anon, authenticated;
grant select on supplier.supplier_documents  to anon, authenticated;
grant select on supplier.categories          to authenticated;        -- NOT anon

-- ===========================================================================
-- 11. RPC EXECUTE grants
-- ===========================================================================
grant execute on function supplier.admin_list_suppliers(
  int, int, supplier.supplier_status, supplier.verification_status
) to authenticated;
grant execute on function supplier.admin_get_supplier(uuid) to authenticated;
grant execute on function supplier.admin_start_review(uuid) to authenticated;
grant execute on function supplier.admin_approve_supplier(uuid) to authenticated;
grant execute on function supplier.admin_reject_supplier(uuid, text) to authenticated;
grant execute on function supplier.admin_suspend_supplier(uuid, text) to authenticated;
grant execute on function supplier.admin_reactivate_supplier(uuid) to authenticated;
grant execute on function supplier.admin_set_verification_status(
  uuid, supplier.verification_status, text
) to authenticated;
grant execute on function supplier.admin_set_document_status(
  uuid, supplier.document_status, text
) to authenticated;

grant execute on function supplier.portal_upsert_my_profile(
  text, text, text, citext, text, char, integer
) to authenticated;
grant execute on function supplier.portal_add_my_category(uuid) to authenticated;
grant execute on function supplier.portal_remove_my_category(uuid) to authenticated;
grant execute on function supplier.portal_add_my_document(
  supplier.document_type, text, text, text, date, date
) to authenticated;
grant execute on function supplier.portal_remove_my_document(uuid) to authenticated;
grant execute on function supplier.portal_submit_my_profile_for_review() to authenticated;
