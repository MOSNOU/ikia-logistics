-- CC-15 / Migration 0026 — Document / File Storage Foundation
-- Ninth business domain step. Adds an application-layer file-metadata layer.
-- Append-only over migrations 0001-0025.
--
-- Co-existence note:
--   Supabase ships a `storage` schema owned by `supabase_storage_admin` with the
--   tables `buckets`, `objects`, `migrations`, etc. This migration adds new
--   application metadata tables (`files`, `file_versions`, `file_associations`)
--   alongside those. Our table/enum/function names do not collide with any
--   currently shipped Supabase storage object. Trigger attachment is scoped
--   explicitly to our own table list so we never modify Supabase's tables.
--
-- Scope: file metadata + versioning + entity linking only.
-- No pricing, settlement, escrow, payment, invoice, accounting, insurance,
-- GPS tracking. No actual bytes are stored in PostgreSQL — file bytes live in
-- the Supabase Storage Service or external object store, addressed by
-- (bucket, object_key).
--
-- Security model: SECURITY DEFINER RPCs only; no direct write grants; search_path=''.
-- Portal RPCs derive organization from identity.current_organization_id().

-- ===========================================================================
-- 1. Schema
-- Note: `storage` is reserved by Supabase Storage Service (owned by
-- supabase_storage_admin) and rejects CREATE from the migration runner.
-- This domain therefore uses `app_storage` as its top-level schema name to
-- avoid conflict and ownership transfer of Supabase's internal tables.
-- ===========================================================================
create schema if not exists app_storage;
grant usage on schema app_storage to anon, authenticated, service_role;

-- ===========================================================================
-- 2. Enums (3)
-- ===========================================================================
create type app_storage.file_status as enum (
  'pending', 'uploaded', 'processed', 'archived'
);

create type app_storage.file_type as enum (
  'pdf', 'image', 'doc', 'xlsx', 'txt', 'other'
);

create type app_storage.file_version_status as enum (
  'pending', 'uploaded', 'archived', 'superseded'
);

-- ===========================================================================
-- 3. Tables (3)
-- ===========================================================================

-- 3.1 files ----------------------------------------------------------------
create table app_storage.files (
  id                  uuid primary key default gen_random_uuid(),
  tenant_id           uuid not null references identity.tenants(id) on delete restrict,
  organization_id     uuid not null references organization.organizations(id) on delete cascade,
  uploaded_by_user_id uuid references auth.users(id) on delete set null,

  bucket              text not null,
  object_key          text not null,
  filename            text not null,
  extension           text,
  mime_type           text,
  file_type           app_storage.file_type not null default 'other',
  size_bytes          bigint,
  checksum            text,
  status              app_storage.file_status not null default 'pending',
  current_version     integer not null default 1,

  metadata            jsonb not null default '{}'::jsonb,

  uploaded_at         timestamptz,
  processed_at        timestamptz,
  archived_at         timestamptz,
  archived_by         uuid references auth.users(id) on delete set null,
  archived_reason     text,

  created_at          timestamptz not null default now(),
  updated_by          uuid references auth.users(id) on delete set null,
  updated_at          timestamptz not null default now(),
  deleted_at          timestamptz,
  version             integer not null default 1
);

comment on table app_storage.files is
  'Application file metadata. Bytes live in Supabase Storage (or external object store) addressed by (bucket, object_key).';

create unique index files_bucket_object_unique
  on app_storage.files(bucket, lower(object_key))
  where deleted_at is null;

create index files_org_idx     on app_storage.files(organization_id);
create index files_status_idx  on app_storage.files(status);

-- 3.2 file_versions --------------------------------------------------------
create table app_storage.file_versions (
  id                  uuid primary key default gen_random_uuid(),
  tenant_id           uuid not null references identity.tenants(id) on delete restrict,
  organization_id     uuid not null references organization.organizations(id) on delete cascade,
  file_id             uuid not null references app_storage.files(id) on delete cascade,
  uploaded_by_user_id uuid references auth.users(id) on delete set null,

  version_number      integer not null,
  bucket              text not null,
  object_key          text not null,
  size_bytes          bigint,
  mime_type           text,
  checksum            text,
  status              app_storage.file_version_status not null default 'pending',

  metadata            jsonb not null default '{}'::jsonb,

  uploaded_at         timestamptz,
  archived_at         timestamptz,

  created_at          timestamptz not null default now(),
  updated_by          uuid references auth.users(id) on delete set null,
  updated_at          timestamptz not null default now(),
  deleted_at          timestamptz,
  version             integer not null default 1
);

comment on table app_storage.file_versions is
  'Per-file version history. Each version has its own (bucket, object_key) pointing to its own bytes.';

create unique index file_versions_unique_active
  on app_storage.file_versions(file_id, version_number)
  where deleted_at is null;

create index file_versions_file_idx on app_storage.file_versions(file_id);

-- 3.3 file_associations ----------------------------------------------------
create table app_storage.file_associations (
  id                  uuid primary key default gen_random_uuid(),
  tenant_id           uuid not null references identity.tenants(id) on delete restrict,
  organization_id     uuid not null references organization.organizations(id) on delete cascade,
  file_id             uuid not null references app_storage.files(id) on delete cascade,

  entity_type         text not null,
  entity_id           uuid not null,
  role                text,
  metadata            jsonb not null default '{}'::jsonb,

  created_by          uuid references auth.users(id) on delete set null,
  created_at          timestamptz not null default now(),
  updated_by          uuid references auth.users(id) on delete set null,
  updated_at          timestamptz not null default now(),
  deleted_at          timestamptz,
  version             integer not null default 1
);

comment on table app_storage.file_associations is
  'Polymorphic link between a file and a domain entity (RFQ, offer, evaluation, contract preparation, executed contract, shipment, supplier, organization, etc.).';

create unique index file_associations_unique_active
  on app_storage.file_associations(file_id, entity_type, entity_id, coalesce(role, ''))
  where deleted_at is null;

create index file_associations_entity_idx
  on app_storage.file_associations(entity_type, entity_id) where deleted_at is null;

-- ===========================================================================
-- 4. Internal helpers
-- ===========================================================================

-- 4.1 fn_audit -------------------------------------------------------------
create or replace function app_storage.fn_audit(
  p_action_code text,
  p_file_id     uuid,
  p_payload     jsonb default '{}'::jsonb
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare v_t uuid; v_o uuid;
begin
  select tenant_id, organization_id into v_t, v_o
    from app_storage.files where id = p_file_id;
  insert into audit.audit_event (
    tenant_id, organization_id, actor_user_id, action_code,
    resource_type, resource_id, payload, occurred_at
  ) values (
    v_t, v_o, auth.uid(), p_action_code,
    'storage', p_file_id, p_payload, now()
  );
exception when others then
  null;
end;
$$;

-- 4.2 fn_assert_authenticated_member ---------------------------------------
-- Verifies caller is an authenticated member of their current organization
-- (or platform admin). Returns (tenant_id, organization_id).
create or replace function app_storage.fn_assert_authenticated_member()
returns table(tenant_id uuid, organization_id uuid)
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_caller_org uuid := identity.current_organization_id();
  v_uid uuid := auth.uid();
  v_tenant uuid;
begin
  if v_uid is null then
    raise exception 'storage: not authenticated' using errcode = '42501';
  end if;
  if identity.is_platform_admin() then
    -- platform admin: try to use current_organization_id if present, else lookup user profile
    if v_caller_org is null then
      select up.primary_organization_id into v_caller_org
        from identity.user_profiles up where up.id = v_uid;
    end if;
  end if;
  if v_caller_org is null then
    raise exception 'storage: no active organization in JWT' using errcode = 'P0002';
  end if;
  select o.tenant_id into v_tenant from organization.organizations o where o.id = v_caller_org;
  if v_tenant is null then
    raise exception 'storage: organization not found' using errcode = 'P0002';
  end if;
  return query select v_tenant, v_caller_org;
end;
$$;

-- 4.3 fn_assert_file_owned -------------------------------------------------
create or replace function app_storage.fn_assert_file_owned(p_file_id uuid)
returns void
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_file_org uuid;
  v_caller_org uuid := identity.current_organization_id();
begin
  select organization_id into v_file_org from app_storage.files
   where id = p_file_id and deleted_at is null;
  if v_file_org is null then
    raise exception 'storage: file not found' using errcode = 'P0002';
  end if;
  if identity.is_platform_admin() then return; end if;
  if v_caller_org is null or v_caller_org <> v_file_org then
    raise exception 'storage: file is not in caller''s organization' using errcode = '42501';
  end if;
end;
$$;

-- 4.4 fn_caller_can_see_entity ---------------------------------------------
-- Returns true if the caller can read the given domain entity. Used to gate
-- listing files associated with that entity. Recognizes the known entity
-- types of CC-09 through CC-14. Unknown entity_types fall back to "caller's
-- organization owns the entity" via a generic check that any well-known
-- table's `organization_id` column matches caller's org. To stay safe and
-- predictable, unknown types return false (caller must use a recognized
-- entity_type).
create or replace function app_storage.fn_caller_can_see_entity(
  p_entity_type text,
  p_entity_id   uuid
) returns boolean
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_caller_org uuid := identity.current_organization_id();
  v_caller_supplier uuid;
  v_entity_org uuid;
  v_entity_supplier uuid;
  v_buyer_org uuid;
begin
  if identity.is_platform_admin() then
    return true;
  end if;
  -- Suppliers identify via supplier.fn_portal_supplier_id(); buyer-only users
  -- hit a RAISE inside that helper, so we swallow it and treat them as not-supplier.
  begin
    v_caller_supplier := supplier.fn_portal_supplier_id();
  exception when others then
    v_caller_supplier := null;
  end;

  case lower(p_entity_type)
    when 'rfq', 'rfq_request', 'request' then
      select organization_id into v_entity_org from rfq.requests where id = p_entity_id;
      -- buyer sees own org; suppliers must have an invitation row
      if v_entity_org = v_caller_org then return true; end if;
      return exists (
        select 1 from rfq.request_supplier_invitations rsi
         where rsi.request_id = p_entity_id
           and rsi.supplier_id = v_caller_supplier
           and rsi.deleted_at is null
      );

    when 'offer', 'supplier_offer' then
      select organization_id, supplier_id into v_buyer_org, v_entity_supplier
        from offer.supplier_offers where id = p_entity_id;
      if v_entity_supplier = v_caller_supplier then return true; end if;
      -- buyer is the RFQ owner
      return exists (
        select 1 from offer.supplier_offers so
         join rfq.requests r on r.id = so.request_id
        where so.id = p_entity_id and r.organization_id = v_caller_org
      );

    when 'evaluation', 'offer_evaluation' then
      select organization_id into v_entity_org from evaluation.offer_evaluations where id = p_entity_id;
      return v_entity_org = v_caller_org;

    when 'decision', 'offer_decision' then
      select organization_id into v_entity_org from evaluation.offer_decisions where id = p_entity_id;
      return v_entity_org = v_caller_org;

    when 'contract_preparation', 'preparation' then
      select organization_id, supplier_id into v_entity_org, v_entity_supplier
        from contract.contract_preparations where id = p_entity_id;
      if v_entity_org = v_caller_org then return true; end if;
      return v_entity_supplier = v_caller_supplier;

    when 'executed_contract', 'contract' then
      select organization_id, supplier_id into v_entity_org, v_entity_supplier
        from contract.executed_contracts where id = p_entity_id;
      if v_entity_org = v_caller_org then return true; end if;
      return v_entity_supplier = v_caller_supplier;

    when 'shipment' then
      select organization_id, supplier_id into v_entity_org, v_entity_supplier
        from shipment.shipments where id = p_entity_id;
      if v_entity_org = v_caller_org then return true; end if;
      return v_entity_supplier = v_caller_supplier;

    when 'supplier' then
      select organization_id into v_entity_org from supplier.suppliers where id = p_entity_id;
      if v_entity_org = v_caller_org then return true; end if;
      return p_entity_id = v_caller_supplier;

    when 'organization' then
      return p_entity_id = v_caller_org;

    else
      return false;
  end case;
end;
$$;

-- 4.5 fn_default_object_key ------------------------------------------------
create or replace function app_storage.fn_default_object_key(
  p_organization_id uuid,
  p_file_id         uuid,
  p_filename        text
) returns text
language plpgsql immutable security definer set search_path = ''
as $$
begin
  return p_organization_id::text || '/' || p_file_id::text || '/' ||
         regexp_replace(coalesce(p_filename, 'file'), '[^a-zA-Z0-9._-]', '_', 'g');
end;
$$;

-- ===========================================================================
-- 5. Row Level Security
-- ===========================================================================
alter table app_storage.files              enable row level security;
alter table app_storage.file_versions      enable row level security;
alter table app_storage.file_associations  enable row level security;

-- 5.1 files: org members + admin.
drop policy if exists files_select on app_storage.files;
create policy files_select on app_storage.files
  for select
  using (
    deleted_at is null
    and (
      identity.is_platform_admin()
      or exists (
        select 1 from organization.memberships m
         where m.user_id = identity.current_user_id()
           and m.organization_id = app_storage.files.organization_id
           and m.deleted_at is null and m.status = 'active'
      )
    )
  );

drop policy if exists files_admin_modify on app_storage.files;
create policy files_admin_modify on app_storage.files
  for all using (identity.is_platform_admin()) with check (identity.is_platform_admin());

-- 5.2 file_versions: same as parent file's org members + admin.
drop policy if exists file_versions_select on app_storage.file_versions;
create policy file_versions_select on app_storage.file_versions
  for select
  using (
    deleted_at is null
    and (
      identity.is_platform_admin()
      or exists (
        select 1 from organization.memberships m
         where m.user_id = identity.current_user_id()
           and m.organization_id = app_storage.file_versions.organization_id
           and m.deleted_at is null and m.status = 'active'
      )
    )
  );

drop policy if exists file_versions_admin_modify on app_storage.file_versions;
create policy file_versions_admin_modify on app_storage.file_versions
  for all using (identity.is_platform_admin()) with check (identity.is_platform_admin());

-- 5.3 file_associations: same as files. Cross-org supplier visibility lives
-- in the RPC layer (portal_list_files_for_entity) rather than RLS to keep
-- the policy simple and predictable.
drop policy if exists file_associations_select on app_storage.file_associations;
create policy file_associations_select on app_storage.file_associations
  for select
  using (
    deleted_at is null
    and (
      identity.is_platform_admin()
      or exists (
        select 1 from organization.memberships m
         where m.user_id = identity.current_user_id()
           and m.organization_id = app_storage.file_associations.organization_id
           and m.deleted_at is null and m.status = 'active'
      )
    )
  );

drop policy if exists file_associations_admin_modify on app_storage.file_associations;
create policy file_associations_admin_modify on app_storage.file_associations
  for all using (identity.is_platform_admin()) with check (identity.is_platform_admin());

-- ===========================================================================
-- 6. Portal RPCs
-- ===========================================================================

-- 6.1 portal_register_file -------------------------------------------------
-- Records metadata for a new file. Returns the file id + the (bucket, object_key)
-- the client should use when calling Supabase Storage's createSignedUploadUrl.
-- The actual byte upload is performed client-side via Supabase Storage; once
-- complete, the client calls portal_finalize_file_upload to flip status.
create or replace function app_storage.portal_register_file(
  p_filename     text,
  p_mime_type    text default null,
  p_size_bytes   bigint default null,
  p_bucket       text default 'app-documents',
  p_file_type    app_storage.file_type default 'other',
  p_extension    text default null,
  p_metadata     jsonb default '{}'::jsonb
) returns jsonb
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_tenant uuid; v_org uuid;
  v_id uuid := gen_random_uuid();
  v_key text;
begin
  if p_filename is null or btrim(p_filename) = '' then
    raise exception 'storage: filename is required' using errcode = '22023';
  end if;
  if p_bucket is null or btrim(p_bucket) = '' then
    raise exception 'storage: bucket is required' using errcode = '22023';
  end if;
  select tenant_id, organization_id into v_tenant, v_org
    from app_storage.fn_assert_authenticated_member();

  v_key := app_storage.fn_default_object_key(v_org, v_id, p_filename);

  insert into app_storage.files (
    id, tenant_id, organization_id, uploaded_by_user_id,
    bucket, object_key, filename, extension, mime_type, file_type, size_bytes,
    status, metadata, updated_by
  ) values (
    v_id, v_tenant, v_org, v_actor,
    p_bucket, v_key, p_filename, p_extension, p_mime_type, p_file_type, p_size_bytes,
    'pending', coalesce(p_metadata, '{}'::jsonb), v_actor
  );

  -- Also record the v1 version row.
  insert into app_storage.file_versions (
    tenant_id, organization_id, file_id, uploaded_by_user_id,
    version_number, bucket, object_key, size_bytes, mime_type,
    status, updated_by
  ) values (
    v_tenant, v_org, v_id, v_actor,
    1, p_bucket, v_key, p_size_bytes, p_mime_type,
    'pending', v_actor
  );

  perform app_storage.fn_audit('app_storage.file_registered', v_id,
    jsonb_build_object('bucket', p_bucket, 'filename', p_filename));

  return jsonb_build_object(
    'file_id', v_id,
    'bucket', p_bucket,
    'object_key', v_key,
    'status', 'pending',
    'version_number', 1
  );
end;
$$;

-- 6.2 portal_finalize_file_upload ------------------------------------------
create or replace function app_storage.portal_finalize_file_upload(
  p_file_id     uuid,
  p_size_bytes  bigint default null,
  p_checksum    text default null
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_status app_storage.file_status;
  v_current_version int;
begin
  perform app_storage.fn_assert_file_owned(p_file_id);
  select status, current_version into v_status, v_current_version
    from app_storage.files where id = p_file_id;
  if v_status not in ('pending') then
    raise exception 'storage: file already finalized (status=%)', v_status using errcode = 'P0001';
  end if;

  update app_storage.files
     set status      = 'uploaded',
         size_bytes  = coalesce(p_size_bytes, size_bytes),
         checksum    = coalesce(p_checksum, checksum),
         uploaded_at = now(),
         updated_by  = v_actor
   where id = p_file_id;

  update app_storage.file_versions
     set status      = 'uploaded',
         size_bytes  = coalesce(p_size_bytes, size_bytes),
         checksum    = coalesce(p_checksum, checksum),
         uploaded_at = now(),
         updated_by  = v_actor
   where file_id = p_file_id and version_number = v_current_version;

  perform app_storage.fn_audit('app_storage.file_finalized', p_file_id,
    jsonb_build_object('size_bytes', p_size_bytes));
end;
$$;

-- 6.3 portal_archive_file --------------------------------------------------
create or replace function app_storage.portal_archive_file(
  p_file_id uuid, p_reason text default null
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_status app_storage.file_status;
begin
  perform app_storage.fn_assert_file_owned(p_file_id);
  select status into v_status from app_storage.files where id = p_file_id;
  if v_status = 'archived' then
    raise exception 'storage: file already archived' using errcode = 'P0001';
  end if;
  update app_storage.files
     set status          = 'archived',
         archived_at     = now(),
         archived_by     = v_actor,
         archived_reason = p_reason,
         updated_by      = v_actor
   where id = p_file_id;
  perform app_storage.fn_audit('app_storage.file_archived', p_file_id,
    jsonb_build_object('reason', p_reason));
end;
$$;

-- 6.4 portal_create_file_version -------------------------------------------
-- Adds a new version to an existing file. Returns (file_id, version_number,
-- bucket, object_key). Marks the file row's current_version = new number.
create or replace function app_storage.portal_create_file_version(
  p_file_id     uuid,
  p_mime_type   text default null,
  p_size_bytes  bigint default null,
  p_metadata    jsonb default '{}'::jsonb
) returns jsonb
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_tenant uuid; v_org uuid; v_bucket text; v_filename text;
  v_new_version int;
  v_new_id uuid := gen_random_uuid();
  v_key text;
begin
  perform app_storage.fn_assert_file_owned(p_file_id);
  select tenant_id, organization_id, bucket, filename, current_version + 1
    into v_tenant, v_org, v_bucket, v_filename, v_new_version
    from app_storage.files where id = p_file_id;
  v_key := app_storage.fn_default_object_key(v_org, v_new_id, v_filename) || '.v' || v_new_version::text;

  -- Mark previous head version as superseded.
  update app_storage.file_versions
     set status = 'superseded', updated_by = v_actor
   where file_id = p_file_id
     and version_number = (select current_version from app_storage.files where id = p_file_id)
     and deleted_at is null;

  insert into app_storage.file_versions (
    id, tenant_id, organization_id, file_id, uploaded_by_user_id,
    version_number, bucket, object_key, size_bytes, mime_type,
    status, metadata, updated_by
  ) values (
    v_new_id, v_tenant, v_org, p_file_id, v_actor,
    v_new_version, v_bucket, v_key, p_size_bytes, p_mime_type,
    'pending', coalesce(p_metadata, '{}'::jsonb), v_actor
  );

  update app_storage.files
     set current_version = v_new_version,
         status          = 'pending',
         mime_type       = coalesce(p_mime_type, mime_type),
         size_bytes      = coalesce(p_size_bytes, size_bytes),
         updated_by      = v_actor
   where id = p_file_id;

  perform app_storage.fn_audit('app_storage.file_version_created', p_file_id,
    jsonb_build_object('version_number', v_new_version));

  return jsonb_build_object(
    'file_id', p_file_id,
    'version_id', v_new_id,
    'version_number', v_new_version,
    'bucket', v_bucket,
    'object_key', v_key
  );
end;
$$;

-- 6.5 portal_link_file_to_entity -------------------------------------------
create or replace function app_storage.portal_link_file_to_entity(
  p_file_id     uuid,
  p_entity_type text,
  p_entity_id   uuid,
  p_role        text default null,
  p_metadata    jsonb default '{}'::jsonb
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_tenant uuid; v_org uuid;
  v_id uuid;
begin
  perform app_storage.fn_assert_file_owned(p_file_id);
  if p_entity_type is null or btrim(p_entity_type) = '' then
    raise exception 'storage: entity_type is required' using errcode = '22023';
  end if;
  if not app_storage.fn_caller_can_see_entity(p_entity_type, p_entity_id) then
    raise exception 'storage: caller cannot link to entity %/%', p_entity_type, p_entity_id
      using errcode = '42501';
  end if;

  select tenant_id, organization_id into v_tenant, v_org
    from app_storage.files where id = p_file_id;

  insert into app_storage.file_associations (
    tenant_id, organization_id, file_id, entity_type, entity_id, role, metadata,
    created_by, updated_by
  ) values (
    v_tenant, v_org, p_file_id, p_entity_type, p_entity_id, p_role,
    coalesce(p_metadata, '{}'::jsonb), v_actor, v_actor
  )
  on conflict (file_id, entity_type, entity_id, coalesce(role, '')) where deleted_at is null
  do update set
    metadata   = excluded.metadata,
    updated_by = v_actor
  returning id into v_id;

  perform app_storage.fn_audit('app_storage.file_linked', p_file_id,
    jsonb_build_object('entity_type', p_entity_type, 'entity_id', p_entity_id::text));
  return v_id;
end;
$$;

-- 6.6 portal_remove_file_association ---------------------------------------
create or replace function app_storage.portal_remove_file_association(p_association_id uuid)
returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_file uuid;
begin
  select file_id into v_file from app_storage.file_associations
   where id = p_association_id and deleted_at is null;
  if v_file is null then
    raise exception 'storage: association not found' using errcode = 'P0002';
  end if;
  perform app_storage.fn_assert_file_owned(v_file);

  update app_storage.file_associations
     set deleted_at = now(), updated_by = v_actor
   where id = p_association_id;

  perform app_storage.fn_audit('app_storage.file_unlinked', v_file,
    jsonb_build_object('association_id', p_association_id::text));
end;
$$;

-- 6.7 portal_list_files_for_entity -----------------------------------------
-- Lists files associated with a given entity, performing the entity-visibility
-- check internally so that suppliers can read files attached to entities they
-- have access to even when the file's owning organization differs.
create or replace function app_storage.portal_list_files_for_entity(
  p_entity_type text,
  p_entity_id   uuid,
  p_limit       integer default 100,
  p_offset      integer default 0
) returns table (
  file_id uuid, association_id uuid, role text,
  bucket text, object_key text, filename text,
  mime_type text, size_bytes bigint, status text,
  current_version int, created_at timestamptz, updated_at timestamptz
)
language plpgsql stable security definer set search_path = ''
as $$
begin
  if not app_storage.fn_caller_can_see_entity(p_entity_type, p_entity_id) then
    raise exception 'storage: caller cannot read entity %/%', p_entity_type, p_entity_id
      using errcode = '42501';
  end if;
  return query
    select f.id, a.id, a.role,
           f.bucket, f.object_key, f.filename,
           f.mime_type, f.size_bytes, f.status::text,
           f.current_version, f.created_at, f.updated_at
      from app_storage.file_associations a
      join app_storage.files f on f.id = a.file_id
     where a.entity_type = p_entity_type
       and a.entity_id   = p_entity_id
       and a.deleted_at  is null
       and f.deleted_at  is null
     order by f.created_at desc
     limit p_limit offset p_offset;
end;
$$;

-- 6.8 portal_get_file_metadata ---------------------------------------------
create or replace function app_storage.portal_get_file_metadata(p_file_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
begin
  perform app_storage.fn_assert_file_owned(p_file_id);
  return (
    select jsonb_build_object(
      'id', f.id, 'bucket', f.bucket, 'object_key', f.object_key,
      'filename', f.filename, 'extension', f.extension, 'mime_type', f.mime_type,
      'file_type', f.file_type, 'size_bytes', f.size_bytes,
      'status', f.status, 'current_version', f.current_version,
      'metadata', f.metadata,
      'uploaded_at', f.uploaded_at, 'archived_at', f.archived_at,
      'created_at', f.created_at, 'updated_at', f.updated_at,
      'versions', (
        select coalesce(jsonb_agg(jsonb_build_object(
          'id', v.id, 'version_number', v.version_number,
          'bucket', v.bucket, 'object_key', v.object_key,
          'size_bytes', v.size_bytes, 'status', v.status,
          'uploaded_at', v.uploaded_at
        ) order by v.version_number desc), '[]'::jsonb)
          from app_storage.file_versions v
         where v.file_id = f.id and v.deleted_at is null
      ),
      'associations', (
        select coalesce(jsonb_agg(jsonb_build_object(
          'id', a.id, 'entity_type', a.entity_type, 'entity_id', a.entity_id, 'role', a.role
        )), '[]'::jsonb)
          from app_storage.file_associations a
         where a.file_id = f.id and a.deleted_at is null
      )
    )
    from app_storage.files f where f.id = p_file_id
  );
end;
$$;

-- 6.9 portal_list_my_files -------------------------------------------------
create or replace function app_storage.portal_list_my_files(
  p_status app_storage.file_status default null,
  p_limit  integer              default 50,
  p_offset integer              default 0
) returns table (
  id uuid, bucket text, object_key text, filename text,
  mime_type text, size_bytes bigint, status text, current_version int,
  created_at timestamptz, updated_at timestamptz
)
language plpgsql stable security definer set search_path = ''
as $$
declare v_caller_org uuid := identity.current_organization_id();
begin
  if v_caller_org is null and not identity.is_platform_admin() then
    raise exception 'storage: no active organization in JWT' using errcode = 'P0002';
  end if;
  return query
    select f.id, f.bucket, f.object_key, f.filename,
           f.mime_type, f.size_bytes, f.status::text, f.current_version,
           f.created_at, f.updated_at
      from app_storage.files f
     where f.deleted_at is null
       and (identity.is_platform_admin() or f.organization_id = v_caller_org)
       and (p_status is null or f.status = p_status)
     order by f.created_at desc
     limit p_limit offset p_offset;
end;
$$;

-- ===========================================================================
-- 7. Admin RPCs
-- ===========================================================================

-- 7.1 admin_list_files -----------------------------------------------------
create or replace function app_storage.admin_list_files(
  p_organization_id uuid                  default null,
  p_status          app_storage.file_status   default null,
  p_limit           integer               default 50,
  p_offset          integer               default 0
) returns table (
  id uuid, organization_id uuid, bucket text, object_key text, filename text,
  mime_type text, status text, current_version int, created_at timestamptz
)
language plpgsql stable security definer set search_path = ''
as $$
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_list_files: requires platform_admin' using errcode = '42501';
  end if;
  return query
    select f.id, f.organization_id, f.bucket, f.object_key, f.filename,
           f.mime_type, f.status::text, f.current_version, f.created_at
      from app_storage.files f
     where f.deleted_at is null
       and (p_organization_id is null or f.organization_id = p_organization_id)
       and (p_status is null or f.status = p_status)
     order by f.created_at desc
     limit p_limit offset p_offset;
end;
$$;

-- 7.2 admin_get_file -------------------------------------------------------
create or replace function app_storage.admin_get_file(p_file_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_get_file: requires platform_admin' using errcode = '42501';
  end if;
  return (
    select jsonb_build_object(
      'id', f.id, 'organization_id', f.organization_id,
      'bucket', f.bucket, 'object_key', f.object_key, 'filename', f.filename,
      'mime_type', f.mime_type, 'file_type', f.file_type,
      'status', f.status, 'current_version', f.current_version,
      'created_at', f.created_at, 'updated_at', f.updated_at,
      'associations_count', (select count(*) from app_storage.file_associations
                              where file_id = f.id and deleted_at is null),
      'versions_count', (select count(*) from app_storage.file_versions
                          where file_id = f.id and deleted_at is null)
    )
    from app_storage.files f where f.id = p_file_id
  );
end;
$$;

-- 7.3 admin_force_archive_file ---------------------------------------------
create or replace function app_storage.admin_force_archive_file(
  p_file_id uuid, p_reason text default null
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare v_actor uuid := auth.uid(); v_status app_storage.file_status;
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_force_archive_file: requires platform_admin' using errcode = '42501';
  end if;
  select status into v_status from app_storage.files where id = p_file_id and deleted_at is null;
  if v_status is null then
    raise exception 'storage: file not found' using errcode = 'P0002';
  end if;
  if v_status = 'archived' then
    raise exception 'storage: file already archived' using errcode = 'P0001';
  end if;
  update app_storage.files
     set status = 'archived', archived_at = now(), archived_by = v_actor,
         archived_reason = p_reason, updated_by = v_actor
   where id = p_file_id;
  perform app_storage.fn_audit('app_storage.file_admin_archived', p_file_id,
    jsonb_build_object('reason', p_reason));
end;
$$;

-- ===========================================================================
-- 8. Trigger attachments (set_updated_at + audit) — scoped to OUR table list
-- Important: never touch Supabase Storage's tables (buckets, objects, etc.).
-- ===========================================================================
do $$
declare r record;
begin
  for r in
    select unnest(array['files','file_versions','file_associations']) as table_name
  loop
    execute format(
      'drop trigger if exists trg_set_updated_at on app_storage.%I',
      r.table_name
    );
    execute format(
      'create trigger trg_set_updated_at before update on app_storage.%I '
      'for each row execute function identity.set_updated_at()',
      r.table_name
    );
    execute format(
      'drop trigger if exists trg_audit_entity on app_storage.%I',
      r.table_name
    );
    execute format(
      'create trigger trg_audit_entity after insert or update or delete on app_storage.%I '
      'for each row execute function audit.fn_audit_entity()',
      r.table_name
    );
  end loop;
end;
$$;

-- ===========================================================================
-- 9. Grants (SELECT only on OUR tables; no INSERT/UPDATE/DELETE)
-- ===========================================================================
grant select on app_storage.files              to anon, authenticated;
grant select on app_storage.file_versions      to authenticated;
grant select on app_storage.file_associations  to authenticated;

-- ===========================================================================
-- 10. RPC EXECUTE grants
-- ===========================================================================
grant execute on function app_storage.portal_register_file(text, text, bigint, text, app_storage.file_type, text, jsonb) to authenticated;
grant execute on function app_storage.portal_finalize_file_upload(uuid, bigint, text) to authenticated;
grant execute on function app_storage.portal_archive_file(uuid, text) to authenticated;
grant execute on function app_storage.portal_create_file_version(uuid, text, bigint, jsonb) to authenticated;
grant execute on function app_storage.portal_link_file_to_entity(uuid, text, uuid, text, jsonb) to authenticated;
grant execute on function app_storage.portal_remove_file_association(uuid) to authenticated;
grant execute on function app_storage.portal_list_files_for_entity(text, uuid, integer, integer) to authenticated;
grant execute on function app_storage.portal_get_file_metadata(uuid) to authenticated;
grant execute on function app_storage.portal_list_my_files(app_storage.file_status, integer, integer) to authenticated;

grant execute on function app_storage.admin_list_files(uuid, app_storage.file_status, integer, integer) to authenticated;
grant execute on function app_storage.admin_get_file(uuid) to authenticated;
grant execute on function app_storage.admin_force_archive_file(uuid, text) to authenticated;
