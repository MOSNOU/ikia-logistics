-- CC-22 / Migration 0031 — KYC & Identity Verification Foundation
-- Fourteenth business-domain step. New `kyc` schema atop CC-09..CC-19 (notify).
-- Append-only over migrations 0001-0030. Strictly additive — does not modify
-- any prior table, RPC body, grant, trigger, or seed.
--
-- Locked decisions (Q1–Q10):
--   Q1=A   single migration (schema + RPCs + RLS in one file).
--   Q2=Yes kyc exposed via PostgREST (config.toml updated alongside).
--   Q3=A   tenant-scoped attempts (unique per tenant_id × subject × attempt_no).
--   Q4=A   National-ID stored as sha256 hash + last-4 only; raw value never
--          persisted. Hash column revoked from authenticated.
--   Q5=A   12-month default approval validity via p_validity_months RPC arg.
--   Q6=B   Documents reference a new dedicated bucket name 'kyc-private'
--          (default column value). Actual storage.buckets row is created
--          out-of-band by Supabase operator; this migration only stamps the
--          bucket name on document metadata, matching CC-15 (app_storage)
--          pattern.
--   Q7=B   risk_flags.source is free-text (not enum) — accommodates future
--          provider:xyz feeds without enum churn.
--   Q8=A   no wiring into existing supplier.* RPCs; supplier.suppliers
--          verification_status semantics unchanged.
--   Q9=A   no UI deliverable; schema spine only.
--   Q10=A  stop at typecheck/build/pgTAP green.
--
-- Out-of-scope (literal "Do Not Build" list — see CC-22 draft §9):
--   - Real government / sanctions / PEP / banking / PSP / biometric / OCR.
--   - Existing supplier/finance/settlement/dispute/contract RPC modifications.
--   - Cross-tenant verification reuse, SLA timers, escalation jobs.
--   - notify-channel materialization wiring for KYC entity types — deferred
--     to a future CC; this migration writes domain events into kyc.events
--     and audit.audit_event but does NOT call notify.fn_materialize_event.
--
-- Security model: SECURITY DEFINER RPCs only; no direct DML grants on tables;
-- search_path=''. Subject RPCs derive identity from auth.uid(); admin RPCs
-- check identity.is_platform_admin() inside body.

-- ===========================================================================
-- 1. Schema
-- ===========================================================================
create schema if not exists kyc;
grant usage on schema kyc to anon, authenticated, service_role;
comment on schema kyc is
  'iKIA Phase 2 — KYC / KYB foundation. Personal + organization identity '
  'verification record-keeping, document metadata, lifecycle, immutable events. '
  'No external provider integration; admins decide manually in CC-22.';

-- ===========================================================================
-- 2. Enums
-- ===========================================================================
create type kyc.kyc_subject_type as enum ('person', 'organization');

create type kyc.kyc_status as enum (
  'not_started',
  'draft',
  'submitted',
  'in_review',
  'info_requested',
  'approved',
  'rejected',
  'expired'
);

create type kyc.kyc_document_kind as enum (
  -- personal
  'national_id_card', 'passport', 'driver_license', 'proof_of_address',
  -- organization
  'company_registration', 'tax_certificate', 'articles_of_association',
  'authorized_signatory_letter', 'ownership_disclosure',
  -- shared
  'other'
);

create type kyc.kyc_document_status as enum (
  'pending', 'accepted', 'rejected', 'superseded'
);

create type kyc.kyc_risk_severity as enum (
  'info', 'low', 'medium', 'high', 'critical'
);

create type kyc.kyc_risk_status as enum (
  'open', 'acknowledged', 'mitigated', 'dismissed'
);

create type kyc.kyc_event_kind as enum (
  'submitted', 'assigned', 'info_requested', 'resubmitted',
  'approved', 'rejected', 'expired',
  'risk_flag_raised', 'risk_flag_resolved',
  'document_attached', 'document_decision'
);

-- ===========================================================================
-- 3. Tables (5)
-- ===========================================================================

-- 3.1 personal_verifications -----------------------------------------------
create table kyc.personal_verifications (
  id                       uuid primary key default gen_random_uuid(),
  tenant_id                uuid not null references identity.tenants(id) on delete restrict,
  user_id                  uuid not null references auth.users(id) on delete cascade,
  attempt_no               integer not null default 1,

  status                   kyc.kyc_status not null default 'draft',
  full_legal_name          text,
  national_id_number_hash  text,
  national_id_last4        text,
  date_of_birth            date,
  country_code             char(2),

  submitted_at             timestamptz,
  reviewed_at              timestamptz,
  reviewed_by              uuid references auth.users(id) on delete set null,
  decision_reason          text,
  approved_at              timestamptz,
  expires_at               timestamptz,

  created_at               timestamptz not null default now(),
  updated_by               uuid references auth.users(id) on delete set null,
  updated_at               timestamptz not null default now(),
  deleted_at               timestamptz,
  version                  integer not null default 1,

  unique (tenant_id, user_id, attempt_no)
);

comment on table kyc.personal_verifications is
  'One row per KYC attempt by a person. The latest non-expired approved row is the operative attempt.';

create index personal_verifications_user_idx
  on kyc.personal_verifications(user_id) where deleted_at is null;
create index personal_verifications_status_idx
  on kyc.personal_verifications(status) where deleted_at is null;
create index personal_verifications_tenant_idx
  on kyc.personal_verifications(tenant_id) where deleted_at is null;
create index personal_verifications_expires_idx
  on kyc.personal_verifications(expires_at)
  where status = 'approved' and deleted_at is null;

-- 3.2 organization_verifications -------------------------------------------
create table kyc.organization_verifications (
  id                            uuid primary key default gen_random_uuid(),
  tenant_id                     uuid not null references identity.tenants(id) on delete restrict,
  organization_id               uuid not null references organization.organizations(id) on delete cascade,
  attempt_no                    integer not null default 1,

  status                        kyc.kyc_status not null default 'draft',
  legal_name                    text,
  registration_number           text,
  tax_id                        text,
  country_code                  char(2),
  incorporated_on               date,
  authorized_signatory_user_id  uuid references auth.users(id) on delete set null,

  submitted_at                  timestamptz,
  reviewed_at                   timestamptz,
  reviewed_by                   uuid references auth.users(id) on delete set null,
  decision_reason               text,
  approved_at                   timestamptz,
  expires_at                    timestamptz,

  created_at                    timestamptz not null default now(),
  updated_by                    uuid references auth.users(id) on delete set null,
  updated_at                    timestamptz not null default now(),
  deleted_at                    timestamptz,
  version                       integer not null default 1,

  unique (tenant_id, organization_id, attempt_no)
);

comment on table kyc.organization_verifications is
  'One row per KYB attempt by an organization.';

create index organization_verifications_org_idx
  on kyc.organization_verifications(organization_id) where deleted_at is null;
create index organization_verifications_status_idx
  on kyc.organization_verifications(status) where deleted_at is null;
create index organization_verifications_tenant_idx
  on kyc.organization_verifications(tenant_id) where deleted_at is null;
create index organization_verifications_expires_idx
  on kyc.organization_verifications(expires_at)
  where status = 'approved' and deleted_at is null;

-- 3.3 documents ------------------------------------------------------------
create table kyc.documents (
  id                            uuid primary key default gen_random_uuid(),
  tenant_id                     uuid not null references identity.tenants(id) on delete restrict,
  subject_type                  kyc.kyc_subject_type not null,
  personal_verification_id      uuid references kyc.personal_verifications(id) on delete cascade,
  organization_verification_id  uuid references kyc.organization_verifications(id) on delete cascade,

  document_kind                 kyc.kyc_document_kind not null,
  title                         text,
  bucket                        text not null default 'kyc-private',
  storage_path                  text,
  mime_type                     text,
  size_bytes                    bigint,
  issued_on                     date,
  expires_on                    date,

  status                        kyc.kyc_document_status not null default 'pending',
  rejection_reason              text,
  reviewed_at                   timestamptz,
  reviewed_by                   uuid references auth.users(id) on delete set null,

  created_by                    uuid references auth.users(id) on delete set null,
  created_at                    timestamptz not null default now(),
  updated_by                    uuid references auth.users(id) on delete set null,
  updated_at                    timestamptz not null default now(),
  deleted_at                    timestamptz,
  version                       integer not null default 1,

  -- Exactly one parent verification (xor)
  check (
    (personal_verification_id is not null and organization_verification_id is null)
    or
    (personal_verification_id is null and organization_verification_id is not null)
  ),
  -- subject_type must agree with which parent FK is set
  check (
    (subject_type = 'person'       and personal_verification_id is not null)
    or
    (subject_type = 'organization' and organization_verification_id is not null)
  )
);

comment on table kyc.documents is
  'Per-attempt document attachments. Bytes live in Supabase Storage bucket '
  '"kyc-private" addressed by (bucket, storage_path). Q6=B: dedicated bucket; '
  'bucket creation is operational, not migration-driven.';

create index documents_personal_idx
  on kyc.documents(personal_verification_id) where deleted_at is null;
create index documents_organization_idx
  on kyc.documents(organization_verification_id) where deleted_at is null;
create index documents_tenant_idx
  on kyc.documents(tenant_id) where deleted_at is null;
create index documents_status_idx
  on kyc.documents(status) where deleted_at is null;

-- 3.4 risk_flags -----------------------------------------------------------
create table kyc.risk_flags (
  id                  uuid primary key default gen_random_uuid(),
  tenant_id           uuid not null references identity.tenants(id) on delete restrict,
  subject_type        kyc.kyc_subject_type not null,
  user_id             uuid references auth.users(id) on delete cascade,
  organization_id     uuid references organization.organizations(id) on delete cascade,

  source              text not null default 'manual',
  severity            kyc.kyc_risk_severity not null,
  status              kyc.kyc_risk_status not null default 'open',
  code                text not null,
  detail              text,

  raised_at           timestamptz not null default now(),
  raised_by           uuid references auth.users(id) on delete set null,
  resolved_at         timestamptz,
  resolved_by         uuid references auth.users(id) on delete set null,
  resolution_note     text,

  created_at          timestamptz not null default now(),
  updated_by          uuid references auth.users(id) on delete set null,
  updated_at          timestamptz not null default now(),
  deleted_at          timestamptz,
  version             integer not null default 1,

  check (
    (subject_type = 'person'       and user_id is not null and organization_id is null)
    or
    (subject_type = 'organization' and organization_id is not null and user_id is null)
  )
);

comment on table kyc.risk_flags is
  'Risk indicators raised against a subject. Q7=B: source is free-text to '
  'accommodate future provider integrations without enum churn.';

create index risk_flags_user_idx
  on kyc.risk_flags(user_id) where deleted_at is null and subject_type = 'person';
create index risk_flags_org_idx
  on kyc.risk_flags(organization_id) where deleted_at is null and subject_type = 'organization';
create index risk_flags_status_idx
  on kyc.risk_flags(status, severity) where deleted_at is null;
create index risk_flags_tenant_idx
  on kyc.risk_flags(tenant_id) where deleted_at is null;

-- 3.5 events (append-only) -------------------------------------------------
create table kyc.events (
  id                            uuid primary key default gen_random_uuid(),
  tenant_id                     uuid not null references identity.tenants(id) on delete restrict,
  subject_type                  kyc.kyc_subject_type not null,
  user_id                       uuid,
  organization_id               uuid,
  personal_verification_id      uuid references kyc.personal_verifications(id) on delete cascade,
  organization_verification_id  uuid references kyc.organization_verifications(id) on delete cascade,

  event_kind                    kyc.kyc_event_kind not null,
  actor_user_id                 uuid references auth.users(id) on delete set null,
  payload                       jsonb not null default '{}'::jsonb,
  occurred_at                   timestamptz not null default now()
);

comment on table kyc.events is
  'Immutable ledger of KYC decisions. UPDATE and DELETE revoked; insert via '
  'SECURITY DEFINER RPCs only.';

create index events_personal_idx
  on kyc.events(personal_verification_id, occurred_at desc);
create index events_org_idx
  on kyc.events(organization_verification_id, occurred_at desc);
create index events_actor_idx
  on kyc.events(actor_user_id, occurred_at desc);
create index events_kind_idx
  on kyc.events(event_kind, occurred_at desc);

-- ===========================================================================
-- 4. Row Level Security
-- ===========================================================================
alter table kyc.personal_verifications      enable row level security;
alter table kyc.organization_verifications  enable row level security;
alter table kyc.documents                   enable row level security;
alter table kyc.risk_flags                  enable row level security;
alter table kyc.events                      enable row level security;

-- 4.1 personal_verifications: subject sees own row; platform_admin sees all.
drop policy if exists personal_verifications_select on kyc.personal_verifications;
create policy personal_verifications_select on kyc.personal_verifications
  for select
  using (
    deleted_at is null
    and (
      identity.is_platform_admin()
      or user_id = identity.current_user_id()
    )
  );

drop policy if exists personal_verifications_admin_modify on kyc.personal_verifications;
create policy personal_verifications_admin_modify on kyc.personal_verifications
  for all using (identity.is_platform_admin()) with check (identity.is_platform_admin());

-- 4.2 organization_verifications: org member sees own org; platform_admin sees all.
drop policy if exists organization_verifications_select on kyc.organization_verifications;
create policy organization_verifications_select on kyc.organization_verifications
  for select
  using (
    deleted_at is null
    and (
      identity.is_platform_admin()
      or exists (
        select 1 from organization.memberships m
         where m.user_id = identity.current_user_id()
           and m.organization_id = organization_verifications.organization_id
           and m.deleted_at is null
           and m.status = 'active'
      )
    )
  );

drop policy if exists organization_verifications_admin_modify on kyc.organization_verifications;
create policy organization_verifications_admin_modify on kyc.organization_verifications
  for all using (identity.is_platform_admin()) with check (identity.is_platform_admin());

-- 4.3 documents: subject ↔ parent verification ownership rules.
drop policy if exists documents_select on kyc.documents;
create policy documents_select on kyc.documents
  for select
  using (
    deleted_at is null
    and (
      identity.is_platform_admin()
      or (
        personal_verification_id is not null
        and exists (
          select 1 from kyc.personal_verifications pv
           where pv.id = documents.personal_verification_id
             and pv.user_id = identity.current_user_id()
        )
      )
      or (
        organization_verification_id is not null
        and exists (
          select 1
            from kyc.organization_verifications ov
            join organization.memberships m
              on m.organization_id = ov.organization_id
           where ov.id = documents.organization_verification_id
             and m.user_id = identity.current_user_id()
             and m.deleted_at is null
             and m.status = 'active'
        )
      )
    )
  );

drop policy if exists documents_admin_modify on kyc.documents;
create policy documents_admin_modify on kyc.documents
  for all using (identity.is_platform_admin()) with check (identity.is_platform_admin());

-- 4.4 risk_flags: platform_admin only (sensitive).
drop policy if exists risk_flags_select on kyc.risk_flags;
create policy risk_flags_select on kyc.risk_flags
  for select using (identity.is_platform_admin());

drop policy if exists risk_flags_admin_modify on kyc.risk_flags;
create policy risk_flags_admin_modify on kyc.risk_flags
  for all using (identity.is_platform_admin()) with check (identity.is_platform_admin());

-- 4.5 events: subject sees own events; platform_admin sees all. UPDATE/DELETE
--             are not granted at all (append-only).
drop policy if exists events_select on kyc.events;
create policy events_select on kyc.events
  for select
  using (
    identity.is_platform_admin()
    or (
      subject_type = 'person'
      and user_id = identity.current_user_id()
    )
    or (
      subject_type = 'organization'
      and exists (
        select 1 from organization.memberships m
         where m.user_id = identity.current_user_id()
           and m.organization_id = events.organization_id
           and m.deleted_at is null
           and m.status = 'active'
      )
    )
  );

-- ===========================================================================
-- 5. Internal helpers
-- ===========================================================================

-- 5.1 fn_audit -------------------------------------------------------------
-- Mirrors notify.fn_audit pattern: writes a single audit.audit_event row.
-- Failures are swallowed so a domain mutation is never blocked by audit.
create or replace function kyc.fn_audit(
  p_action_code text,
  p_resource_id uuid,
  p_tenant_id   uuid,
  p_payload     jsonb default '{}'::jsonb
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
begin
  insert into audit.audit_event (
    tenant_id, actor_user_id, action_code,
    resource_type, resource_id, payload, occurred_at
  ) values (
    p_tenant_id, auth.uid(), p_action_code,
    'kyc', p_resource_id, p_payload, now()
  );
exception when others then
  null;
end;
$$;

-- 5.2 fn_record_event ------------------------------------------------------
-- Append a row to kyc.events. Used by every state-changing RPC.
create or replace function kyc.fn_record_event(
  p_tenant_id                     uuid,
  p_subject_type                  kyc.kyc_subject_type,
  p_user_id                       uuid,
  p_organization_id               uuid,
  p_personal_verification_id      uuid,
  p_organization_verification_id  uuid,
  p_event_kind                    kyc.kyc_event_kind,
  p_payload                       jsonb default '{}'::jsonb
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare v_id uuid;
begin
  insert into kyc.events (
    tenant_id, subject_type, user_id, organization_id,
    personal_verification_id, organization_verification_id,
    event_kind, actor_user_id, payload, occurred_at
  ) values (
    p_tenant_id, p_subject_type, p_user_id, p_organization_id,
    p_personal_verification_id, p_organization_verification_id,
    p_event_kind, auth.uid(), coalesce(p_payload, '{}'::jsonb), now()
  ) returning id into v_id;
  return v_id;
end;
$$;

-- 5.3 fn_hash_national_id --------------------------------------------------
-- Q4=A: sha256 hash + last-4 only; raw value never leaves the RPC body.
create or replace function kyc.fn_hash_national_id(p_raw text)
returns text
language plpgsql immutable security definer set search_path = ''
as $$
begin
  if p_raw is null or btrim(p_raw) = '' then
    return null;
  end if;
  return pg_catalog.encode(extensions.digest(btrim(p_raw), 'sha256'), 'hex');
end;
$$;

-- 5.4 fn_assert_personal_subject -------------------------------------------
-- Loads a personal_verifications row by id and verifies the caller owns it.
create or replace function kyc.fn_assert_personal_subject(
  p_verification_id uuid
) returns kyc.personal_verifications
language plpgsql stable security definer set search_path = ''
as $$
declare v_row kyc.personal_verifications%rowtype;
begin
  select * into v_row from kyc.personal_verifications
   where id = p_verification_id and deleted_at is null;
  if v_row.id is null then
    raise exception 'kyc: verification not found' using errcode = 'P0002';
  end if;
  if v_row.user_id <> auth.uid() then
    raise exception 'kyc: not your verification' using errcode = '42501';
  end if;
  return v_row;
end;
$$;

-- 5.5 fn_assert_organization_subject ---------------------------------------
-- Loads an organization_verifications row and verifies the caller is an
-- active member of the parent organization with org_admin / supplier_admin
-- / buyer_admin / organization_admin role.
create or replace function kyc.fn_assert_organization_subject(
  p_verification_id uuid
) returns kyc.organization_verifications
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_row kyc.organization_verifications%rowtype;
  v_ok  boolean;
begin
  select * into v_row from kyc.organization_verifications
   where id = p_verification_id and deleted_at is null;
  if v_row.id is null then
    raise exception 'kyc: verification not found' using errcode = 'P0002';
  end if;

  select exists (
    select 1
      from organization.memberships m
      join identity.roles r on r.id = m.role_id
     where m.organization_id = v_row.organization_id
       and m.user_id = auth.uid()
       and m.deleted_at is null
       and m.status = 'active'
       and r.code in (
         'organization_admin', 'buyer_admin', 'supplier_admin',
         'carrier_admin', 'compliance_officer'
       )
  ) into v_ok;

  if not v_ok then
    raise exception 'kyc: not authorized for this organization' using errcode = '42501';
  end if;
  return v_row;
end;
$$;

-- 5.6 fn_assert_admin ------------------------------------------------------
create or replace function kyc.fn_assert_admin() returns void
language plpgsql stable security definer set search_path = ''
as $$
begin
  if not identity.is_platform_admin() then
    raise exception 'kyc: requires platform_admin' using errcode = '42501';
  end if;
end;
$$;

-- ===========================================================================
-- 6. Subject (self-service) RPCs
-- ===========================================================================

-- 6.1 start_personal_verification ------------------------------------------
-- Creates a draft for the caller. If the caller has any non-terminal draft,
-- returns that one. Otherwise allocates a new attempt_no = max+1.
create or replace function kyc.start_personal_verification()
returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_tenant_id uuid;
  v_existing uuid;
  v_attempt int;
  v_id uuid;
begin
  if v_uid is null then
    raise exception 'kyc: not authenticated' using errcode = '42501';
  end if;

  select tenant_id into v_tenant_id
    from identity.user_profiles where id = v_uid and deleted_at is null;
  if v_tenant_id is null then
    raise exception 'kyc: user profile missing or has no tenant' using errcode = 'P0002';
  end if;

  -- Reuse open draft when present.
  select id into v_existing from kyc.personal_verifications
   where user_id = v_uid
     and status = 'draft'
     and deleted_at is null
   order by attempt_no desc
   limit 1;
  if v_existing is not null then
    return v_existing;
  end if;

  select coalesce(max(attempt_no), 0) + 1 into v_attempt
    from kyc.personal_verifications
   where user_id = v_uid and tenant_id = v_tenant_id;

  insert into kyc.personal_verifications (tenant_id, user_id, attempt_no, status)
  values (v_tenant_id, v_uid, v_attempt, 'draft')
  returning id into v_id;

  perform kyc.fn_audit('kyc.personal.draft_created', v_id, v_tenant_id,
                      jsonb_build_object('attempt_no', v_attempt));
  return v_id;
end;
$$;

-- 6.2 update_personal_draft ------------------------------------------------
create or replace function kyc.update_personal_draft(
  p_id                 uuid,
  p_full_legal_name    text default null,
  p_national_id_number text default null,
  p_date_of_birth      date default null,
  p_country_code       char(2) default null
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_row kyc.personal_verifications%rowtype;
  v_hash text;
  v_last4 text;
begin
  v_row := kyc.fn_assert_personal_subject(p_id);
  if v_row.status not in ('draft', 'info_requested') then
    raise exception 'kyc: cannot edit verification in status %', v_row.status
      using errcode = '22023';
  end if;

  if p_national_id_number is not null and btrim(p_national_id_number) <> '' then
    v_hash := kyc.fn_hash_national_id(p_national_id_number);
    v_last4 := right(btrim(p_national_id_number), 4);
  else
    v_hash := v_row.national_id_number_hash;
    v_last4 := v_row.national_id_last4;
  end if;

  update kyc.personal_verifications
     set full_legal_name = coalesce(p_full_legal_name, full_legal_name),
         national_id_number_hash = v_hash,
         national_id_last4 = v_last4,
         date_of_birth = coalesce(p_date_of_birth, date_of_birth),
         country_code = coalesce(p_country_code, country_code),
         updated_by = auth.uid()
   where id = p_id;

  perform kyc.fn_audit('kyc.personal.draft_updated', p_id, v_row.tenant_id,
                      jsonb_build_object('fields_supplied',
                        coalesce(p_full_legal_name is not null, false)
                        or coalesce(p_national_id_number is not null, false)
                        or coalesce(p_date_of_birth is not null, false)
                        or coalesce(p_country_code is not null, false)));
end;
$$;

-- 6.3 submit_personal_verification -----------------------------------------
create or replace function kyc.submit_personal_verification(p_id uuid)
returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare v_row kyc.personal_verifications%rowtype;
begin
  v_row := kyc.fn_assert_personal_subject(p_id);
  if v_row.status not in ('draft', 'info_requested') then
    raise exception 'kyc: cannot submit verification in status %', v_row.status
      using errcode = '22023';
  end if;

  if v_row.full_legal_name is null
     or v_row.national_id_number_hash is null
     or v_row.date_of_birth is null
     or v_row.country_code is null then
    raise exception 'kyc: required fields missing (legal_name / national_id / dob / country)'
      using errcode = '22023';
  end if;

  update kyc.personal_verifications
     set status = 'submitted',
         submitted_at = now(),
         updated_by = auth.uid()
   where id = p_id;

  perform kyc.fn_record_event(
    v_row.tenant_id, 'person'::kyc.kyc_subject_type, v_row.user_id, null,
    p_id, null,
    (case when v_row.status = 'info_requested' then 'resubmitted' else 'submitted' end)::kyc.kyc_event_kind,
    jsonb_build_object('attempt_no', v_row.attempt_no)
  );
  perform kyc.fn_audit('kyc.personal.submitted', p_id, v_row.tenant_id,
                      jsonb_build_object('attempt_no', v_row.attempt_no));
end;
$$;

-- 6.4 start_organization_verification --------------------------------------
create or replace function kyc.start_organization_verification(p_organization_id uuid)
returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_tenant_id uuid;
  v_authorized boolean;
  v_existing uuid;
  v_attempt int;
  v_id uuid;
begin
  if v_uid is null then
    raise exception 'kyc: not authenticated' using errcode = '42501';
  end if;

  select tenant_id into v_tenant_id from organization.organizations
   where id = p_organization_id and deleted_at is null;
  if v_tenant_id is null then
    raise exception 'kyc: organization not found' using errcode = 'P0002';
  end if;

  select exists (
    select 1
      from organization.memberships m
      join identity.roles r on r.id = m.role_id
     where m.organization_id = p_organization_id
       and m.user_id = v_uid
       and m.deleted_at is null
       and m.status = 'active'
       and r.code in (
         'organization_admin', 'buyer_admin', 'supplier_admin',
         'carrier_admin', 'compliance_officer'
       )
  ) into v_authorized;
  if not v_authorized then
    raise exception 'kyc: not authorized for this organization' using errcode = '42501';
  end if;

  select id into v_existing from kyc.organization_verifications
   where organization_id = p_organization_id
     and status = 'draft'
     and deleted_at is null
   order by attempt_no desc
   limit 1;
  if v_existing is not null then
    return v_existing;
  end if;

  select coalesce(max(attempt_no), 0) + 1 into v_attempt
    from kyc.organization_verifications
   where organization_id = p_organization_id and tenant_id = v_tenant_id;

  insert into kyc.organization_verifications (
    tenant_id, organization_id, attempt_no, status, authorized_signatory_user_id
  ) values (
    v_tenant_id, p_organization_id, v_attempt, 'draft', v_uid
  ) returning id into v_id;

  perform kyc.fn_audit('kyc.organization.draft_created', v_id, v_tenant_id,
                      jsonb_build_object('organization_id', p_organization_id,
                                         'attempt_no', v_attempt));
  return v_id;
end;
$$;

-- 6.5 update_organization_draft --------------------------------------------
create or replace function kyc.update_organization_draft(
  p_id                  uuid,
  p_legal_name          text default null,
  p_registration_number text default null,
  p_tax_id              text default null,
  p_country_code        char(2) default null,
  p_incorporated_on     date default null
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare v_row kyc.organization_verifications%rowtype;
begin
  v_row := kyc.fn_assert_organization_subject(p_id);
  if v_row.status not in ('draft', 'info_requested') then
    raise exception 'kyc: cannot edit verification in status %', v_row.status
      using errcode = '22023';
  end if;

  update kyc.organization_verifications
     set legal_name          = coalesce(p_legal_name, legal_name),
         registration_number = coalesce(p_registration_number, registration_number),
         tax_id              = coalesce(p_tax_id, tax_id),
         country_code        = coalesce(p_country_code, country_code),
         incorporated_on     = coalesce(p_incorporated_on, incorporated_on),
         updated_by          = auth.uid()
   where id = p_id;

  perform kyc.fn_audit('kyc.organization.draft_updated', p_id, v_row.tenant_id,
                      '{}'::jsonb);
end;
$$;

-- 6.6 submit_organization_verification -------------------------------------
create or replace function kyc.submit_organization_verification(p_id uuid)
returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare v_row kyc.organization_verifications%rowtype;
begin
  v_row := kyc.fn_assert_organization_subject(p_id);
  if v_row.status not in ('draft', 'info_requested') then
    raise exception 'kyc: cannot submit verification in status %', v_row.status
      using errcode = '22023';
  end if;

  if v_row.legal_name is null
     or v_row.registration_number is null
     or v_row.country_code is null then
    raise exception 'kyc: required fields missing (legal_name / registration_number / country)'
      using errcode = '22023';
  end if;

  update kyc.organization_verifications
     set status = 'submitted',
         submitted_at = now(),
         updated_by = auth.uid()
   where id = p_id;

  perform kyc.fn_record_event(
    v_row.tenant_id, 'organization'::kyc.kyc_subject_type,
    null, v_row.organization_id,
    null, p_id,
    (case when v_row.status = 'info_requested' then 'resubmitted' else 'submitted' end)::kyc.kyc_event_kind,
    jsonb_build_object('attempt_no', v_row.attempt_no)
  );
  perform kyc.fn_audit('kyc.organization.submitted', p_id, v_row.tenant_id,
                      jsonb_build_object('attempt_no', v_row.attempt_no,
                                         'organization_id', v_row.organization_id));
end;
$$;

-- 6.7 attach_document ------------------------------------------------------
create or replace function kyc.attach_document(
  p_verification_id uuid,
  p_subject_type    kyc.kyc_subject_type,
  p_document_kind   kyc.kyc_document_kind,
  p_storage_path    text,
  p_title           text default null,
  p_mime_type       text default null,
  p_size_bytes      bigint default null,
  p_issued_on       date default null,
  p_expires_on      date default null
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_pv kyc.personal_verifications%rowtype;
  v_ov kyc.organization_verifications%rowtype;
  v_tenant uuid;
  v_uid uuid := auth.uid();
  v_id uuid;
begin
  if p_storage_path is null or btrim(p_storage_path) = '' then
    raise exception 'kyc: storage_path is required' using errcode = '22023';
  end if;

  if p_subject_type = 'person' then
    v_pv := kyc.fn_assert_personal_subject(p_verification_id);
    if v_pv.status not in ('draft', 'info_requested', 'submitted', 'in_review') then
      raise exception 'kyc: cannot attach to verification in status %', v_pv.status
        using errcode = '22023';
    end if;
    v_tenant := v_pv.tenant_id;
    insert into kyc.documents (
      tenant_id, subject_type, personal_verification_id, document_kind,
      title, bucket, storage_path, mime_type, size_bytes,
      issued_on, expires_on, status, created_by
    ) values (
      v_tenant, 'person', p_verification_id, p_document_kind,
      p_title, 'kyc-private', p_storage_path, p_mime_type, p_size_bytes,
      p_issued_on, p_expires_on, 'pending', v_uid
    ) returning id into v_id;
    perform kyc.fn_record_event(
      v_tenant, 'person'::kyc.kyc_subject_type, v_pv.user_id, null,
      p_verification_id, null,
      'document_attached',
      jsonb_build_object('document_id', v_id, 'document_kind', p_document_kind)
    );
  else
    v_ov := kyc.fn_assert_organization_subject(p_verification_id);
    if v_ov.status not in ('draft', 'info_requested', 'submitted', 'in_review') then
      raise exception 'kyc: cannot attach to verification in status %', v_ov.status
        using errcode = '22023';
    end if;
    v_tenant := v_ov.tenant_id;
    insert into kyc.documents (
      tenant_id, subject_type, organization_verification_id, document_kind,
      title, bucket, storage_path, mime_type, size_bytes,
      issued_on, expires_on, status, created_by
    ) values (
      v_tenant, 'organization', p_verification_id, p_document_kind,
      p_title, 'kyc-private', p_storage_path, p_mime_type, p_size_bytes,
      p_issued_on, p_expires_on, 'pending', v_uid
    ) returning id into v_id;
    perform kyc.fn_record_event(
      v_tenant, 'organization'::kyc.kyc_subject_type, null, v_ov.organization_id,
      null, p_verification_id,
      'document_attached',
      jsonb_build_object('document_id', v_id, 'document_kind', p_document_kind)
    );
  end if;

  perform kyc.fn_audit('kyc.document.attached', v_id, v_tenant,
                      jsonb_build_object('document_kind', p_document_kind));
  return v_id;
end;
$$;

-- ===========================================================================
-- 7. Admin RPCs
-- ===========================================================================

-- 7.1 admin_assign_verification --------------------------------------------
-- submitted → in_review (reviewer = caller).
create or replace function kyc.admin_assign_verification(
  p_verification_id uuid,
  p_subject_type    kyc.kyc_subject_type
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_tenant uuid;
  v_uid uuid := auth.uid();
  v_user_id uuid;
  v_org_id uuid;
  v_current kyc.kyc_status;
begin
  perform kyc.fn_assert_admin();
  if p_subject_type = 'person' then
    select tenant_id, status, user_id into v_tenant, v_current, v_user_id
      from kyc.personal_verifications where id = p_verification_id and deleted_at is null;
    if v_tenant is null then
      raise exception 'kyc: verification not found' using errcode = 'P0002';
    end if;
    if v_current <> 'submitted' then
      raise exception 'kyc: cannot assign verification in status %', v_current
        using errcode = '22023';
    end if;
    update kyc.personal_verifications
       set status = 'in_review', reviewed_by = v_uid, updated_by = v_uid
     where id = p_verification_id;
    perform kyc.fn_record_event(
      v_tenant, 'person', v_user_id, null,
      p_verification_id, null, 'assigned',
      jsonb_build_object('reviewer', v_uid)
    );
  else
    select tenant_id, status, organization_id into v_tenant, v_current, v_org_id
      from kyc.organization_verifications where id = p_verification_id and deleted_at is null;
    if v_tenant is null then
      raise exception 'kyc: verification not found' using errcode = 'P0002';
    end if;
    if v_current <> 'submitted' then
      raise exception 'kyc: cannot assign verification in status %', v_current
        using errcode = '22023';
    end if;
    update kyc.organization_verifications
       set status = 'in_review', reviewed_by = v_uid, updated_by = v_uid
     where id = p_verification_id;
    perform kyc.fn_record_event(
      v_tenant, 'organization', null, v_org_id,
      null, p_verification_id, 'assigned',
      jsonb_build_object('reviewer', v_uid)
    );
  end if;
  perform kyc.fn_audit('kyc.assigned', p_verification_id, v_tenant,
                      jsonb_build_object('subject_type', p_subject_type, 'reviewer', v_uid));
end;
$$;

-- 7.2 admin_request_info ---------------------------------------------------
create or replace function kyc.admin_request_info(
  p_verification_id uuid,
  p_subject_type    kyc.kyc_subject_type,
  p_reason          text
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_tenant uuid;
  v_uid uuid := auth.uid();
  v_user_id uuid;
  v_org_id uuid;
  v_current kyc.kyc_status;
begin
  perform kyc.fn_assert_admin();
  if p_reason is null or btrim(p_reason) = '' then
    raise exception 'kyc: reason is required' using errcode = '22023';
  end if;

  if p_subject_type = 'person' then
    select tenant_id, status, user_id into v_tenant, v_current, v_user_id
      from kyc.personal_verifications where id = p_verification_id and deleted_at is null;
    if v_tenant is null then
      raise exception 'kyc: verification not found' using errcode = 'P0002';
    end if;
    if v_current <> 'in_review' then
      raise exception 'kyc: cannot request info on verification in status %', v_current
        using errcode = '22023';
    end if;
    update kyc.personal_verifications
       set status = 'info_requested',
           decision_reason = p_reason,
           updated_by = v_uid
     where id = p_verification_id;
    perform kyc.fn_record_event(
      v_tenant, 'person', v_user_id, null,
      p_verification_id, null, 'info_requested',
      jsonb_build_object('reason', p_reason)
    );
  else
    select tenant_id, status, organization_id into v_tenant, v_current, v_org_id
      from kyc.organization_verifications where id = p_verification_id and deleted_at is null;
    if v_tenant is null then
      raise exception 'kyc: verification not found' using errcode = 'P0002';
    end if;
    if v_current <> 'in_review' then
      raise exception 'kyc: cannot request info on verification in status %', v_current
        using errcode = '22023';
    end if;
    update kyc.organization_verifications
       set status = 'info_requested',
           decision_reason = p_reason,
           updated_by = v_uid
     where id = p_verification_id;
    perform kyc.fn_record_event(
      v_tenant, 'organization', null, v_org_id,
      null, p_verification_id, 'info_requested',
      jsonb_build_object('reason', p_reason)
    );
  end if;
  perform kyc.fn_audit('kyc.info_requested', p_verification_id, v_tenant,
                      jsonb_build_object('subject_type', p_subject_type));
end;
$$;

-- 7.3 admin_approve_verification -------------------------------------------
create or replace function kyc.admin_approve_verification(
  p_verification_id uuid,
  p_subject_type    kyc.kyc_subject_type,
  p_validity_months integer default 12
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_tenant uuid;
  v_uid uuid := auth.uid();
  v_user_id uuid;
  v_org_id uuid;
  v_current kyc.kyc_status;
  v_expires timestamptz;
begin
  perform kyc.fn_assert_admin();
  if p_validity_months is null or p_validity_months <= 0 then
    p_validity_months := 12;
  end if;
  v_expires := now() + (p_validity_months || ' months')::interval;

  if p_subject_type = 'person' then
    select tenant_id, status, user_id into v_tenant, v_current, v_user_id
      from kyc.personal_verifications where id = p_verification_id and deleted_at is null;
    if v_tenant is null then
      raise exception 'kyc: verification not found' using errcode = 'P0002';
    end if;
    if v_current <> 'in_review' then
      raise exception 'kyc: cannot approve verification in status %', v_current
        using errcode = '22023';
    end if;
    update kyc.personal_verifications
       set status = 'approved',
           approved_at = now(),
           reviewed_at = now(),
           reviewed_by = v_uid,
           expires_at = v_expires,
           updated_by = v_uid
     where id = p_verification_id;
    perform kyc.fn_record_event(
      v_tenant, 'person', v_user_id, null,
      p_verification_id, null, 'approved',
      jsonb_build_object('validity_months', p_validity_months,
                         'expires_at', v_expires)
    );
  else
    select tenant_id, status, organization_id into v_tenant, v_current, v_org_id
      from kyc.organization_verifications where id = p_verification_id and deleted_at is null;
    if v_tenant is null then
      raise exception 'kyc: verification not found' using errcode = 'P0002';
    end if;
    if v_current <> 'in_review' then
      raise exception 'kyc: cannot approve verification in status %', v_current
        using errcode = '22023';
    end if;
    update kyc.organization_verifications
       set status = 'approved',
           approved_at = now(),
           reviewed_at = now(),
           reviewed_by = v_uid,
           expires_at = v_expires,
           updated_by = v_uid
     where id = p_verification_id;
    perform kyc.fn_record_event(
      v_tenant, 'organization', null, v_org_id,
      null, p_verification_id, 'approved',
      jsonb_build_object('validity_months', p_validity_months,
                         'expires_at', v_expires)
    );
  end if;
  perform kyc.fn_audit('kyc.approved', p_verification_id, v_tenant,
                      jsonb_build_object('subject_type', p_subject_type,
                                         'expires_at', v_expires));
end;
$$;

-- 7.4 admin_reject_verification --------------------------------------------
create or replace function kyc.admin_reject_verification(
  p_verification_id uuid,
  p_subject_type    kyc.kyc_subject_type,
  p_reason          text
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_tenant uuid;
  v_uid uuid := auth.uid();
  v_user_id uuid;
  v_org_id uuid;
  v_current kyc.kyc_status;
begin
  perform kyc.fn_assert_admin();
  if p_reason is null or btrim(p_reason) = '' then
    raise exception 'kyc: reason is required' using errcode = '22023';
  end if;

  if p_subject_type = 'person' then
    select tenant_id, status, user_id into v_tenant, v_current, v_user_id
      from kyc.personal_verifications where id = p_verification_id and deleted_at is null;
    if v_tenant is null then
      raise exception 'kyc: verification not found' using errcode = 'P0002';
    end if;
    if v_current <> 'in_review' then
      raise exception 'kyc: cannot reject verification in status %', v_current
        using errcode = '22023';
    end if;
    update kyc.personal_verifications
       set status = 'rejected',
           reviewed_at = now(),
           reviewed_by = v_uid,
           decision_reason = p_reason,
           updated_by = v_uid
     where id = p_verification_id;
    perform kyc.fn_record_event(
      v_tenant, 'person', v_user_id, null,
      p_verification_id, null, 'rejected',
      jsonb_build_object('reason', p_reason)
    );
  else
    select tenant_id, status, organization_id into v_tenant, v_current, v_org_id
      from kyc.organization_verifications where id = p_verification_id and deleted_at is null;
    if v_tenant is null then
      raise exception 'kyc: verification not found' using errcode = 'P0002';
    end if;
    if v_current <> 'in_review' then
      raise exception 'kyc: cannot reject verification in status %', v_current
        using errcode = '22023';
    end if;
    update kyc.organization_verifications
       set status = 'rejected',
           reviewed_at = now(),
           reviewed_by = v_uid,
           decision_reason = p_reason,
           updated_by = v_uid
     where id = p_verification_id;
    perform kyc.fn_record_event(
      v_tenant, 'organization', null, v_org_id,
      null, p_verification_id, 'rejected',
      jsonb_build_object('reason', p_reason)
    );
  end if;
  perform kyc.fn_audit('kyc.rejected', p_verification_id, v_tenant,
                      jsonb_build_object('subject_type', p_subject_type));
end;
$$;

-- 7.5 admin_decide_document ------------------------------------------------
create or replace function kyc.admin_decide_document(
  p_document_id uuid,
  p_decision    kyc.kyc_document_status,
  p_reason      text default null
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_doc kyc.documents%rowtype;
  v_uid uuid := auth.uid();
  v_user_id uuid;
  v_org_id uuid;
begin
  perform kyc.fn_assert_admin();
  if p_decision not in ('accepted', 'rejected', 'superseded') then
    raise exception 'kyc: decision must be accepted/rejected/superseded' using errcode = '22023';
  end if;
  if p_decision = 'rejected' and (p_reason is null or btrim(p_reason) = '') then
    raise exception 'kyc: reason required when rejecting a document' using errcode = '22023';
  end if;

  select * into v_doc from kyc.documents where id = p_document_id and deleted_at is null;
  if v_doc.id is null then
    raise exception 'kyc: document not found' using errcode = 'P0002';
  end if;

  update kyc.documents
     set status = p_decision,
         rejection_reason = case when p_decision = 'rejected' then p_reason else rejection_reason end,
         reviewed_at = now(),
         reviewed_by = v_uid,
         updated_by = v_uid
   where id = p_document_id;

  if v_doc.subject_type = 'person' then
    select user_id into v_user_id from kyc.personal_verifications
     where id = v_doc.personal_verification_id;
    perform kyc.fn_record_event(
      v_doc.tenant_id, 'person', v_user_id, null,
      v_doc.personal_verification_id, null, 'document_decision',
      jsonb_build_object('document_id', p_document_id,
                         'decision', p_decision,
                         'reason', p_reason)
    );
  else
    select organization_id into v_org_id from kyc.organization_verifications
     where id = v_doc.organization_verification_id;
    perform kyc.fn_record_event(
      v_doc.tenant_id, 'organization', null, v_org_id,
      null, v_doc.organization_verification_id, 'document_decision',
      jsonb_build_object('document_id', p_document_id,
                         'decision', p_decision,
                         'reason', p_reason)
    );
  end if;
  perform kyc.fn_audit('kyc.document.decided', p_document_id, v_doc.tenant_id,
                      jsonb_build_object('decision', p_decision));
end;
$$;

-- 7.6 admin_raise_risk_flag ------------------------------------------------
create or replace function kyc.admin_raise_risk_flag(
  p_subject_type    kyc.kyc_subject_type,
  p_user_id         uuid default null,
  p_organization_id uuid default null,
  p_code            text default null,
  p_severity        kyc.kyc_risk_severity default 'medium',
  p_detail          text default null,
  p_source          text default 'manual'
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_tenant uuid;
  v_id uuid;
begin
  perform kyc.fn_assert_admin();
  if p_code is null or btrim(p_code) = '' then
    raise exception 'kyc: risk_flag code is required' using errcode = '22023';
  end if;

  if p_subject_type = 'person' then
    if p_user_id is null then
      raise exception 'kyc: user_id required for person risk_flag' using errcode = '22023';
    end if;
    select tenant_id into v_tenant from identity.user_profiles
     where id = p_user_id and deleted_at is null;
    if v_tenant is null then
      raise exception 'kyc: user not found' using errcode = 'P0002';
    end if;
    insert into kyc.risk_flags (
      tenant_id, subject_type, user_id, source,
      severity, status, code, detail, raised_by, updated_by
    ) values (
      v_tenant, 'person', p_user_id, coalesce(p_source, 'manual'),
      p_severity, 'open', p_code, p_detail, auth.uid(), auth.uid()
    ) returning id into v_id;
    perform kyc.fn_record_event(
      v_tenant, 'person', p_user_id, null, null, null,
      'risk_flag_raised',
      jsonb_build_object('flag_id', v_id, 'code', p_code,
                         'severity', p_severity, 'source', p_source)
    );
  else
    if p_organization_id is null then
      raise exception 'kyc: organization_id required for organization risk_flag' using errcode = '22023';
    end if;
    select tenant_id into v_tenant from organization.organizations
     where id = p_organization_id and deleted_at is null;
    if v_tenant is null then
      raise exception 'kyc: organization not found' using errcode = 'P0002';
    end if;
    insert into kyc.risk_flags (
      tenant_id, subject_type, organization_id, source,
      severity, status, code, detail, raised_by, updated_by
    ) values (
      v_tenant, 'organization', p_organization_id, coalesce(p_source, 'manual'),
      p_severity, 'open', p_code, p_detail, auth.uid(), auth.uid()
    ) returning id into v_id;
    perform kyc.fn_record_event(
      v_tenant, 'organization', null, p_organization_id, null, null,
      'risk_flag_raised',
      jsonb_build_object('flag_id', v_id, 'code', p_code,
                         'severity', p_severity, 'source', p_source)
    );
  end if;
  perform kyc.fn_audit('kyc.risk_flag.raised', v_id, v_tenant,
                      jsonb_build_object('subject_type', p_subject_type,
                                         'code', p_code,
                                         'severity', p_severity));
  return v_id;
end;
$$;

-- 7.7 admin_resolve_risk_flag ----------------------------------------------
create or replace function kyc.admin_resolve_risk_flag(
  p_flag_id uuid,
  p_status  kyc.kyc_risk_status,
  p_note    text default null
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare v_flag kyc.risk_flags%rowtype;
begin
  perform kyc.fn_assert_admin();
  if p_status not in ('acknowledged', 'mitigated', 'dismissed') then
    raise exception 'kyc: resolution status must be acknowledged/mitigated/dismissed'
      using errcode = '22023';
  end if;

  select * into v_flag from kyc.risk_flags where id = p_flag_id and deleted_at is null;
  if v_flag.id is null then
    raise exception 'kyc: risk_flag not found' using errcode = 'P0002';
  end if;
  if v_flag.status <> 'open' then
    raise exception 'kyc: risk_flag is already %', v_flag.status using errcode = '22023';
  end if;

  update kyc.risk_flags
     set status = p_status,
         resolved_at = now(),
         resolved_by = auth.uid(),
         resolution_note = p_note,
         updated_by = auth.uid()
   where id = p_flag_id;

  perform kyc.fn_record_event(
    v_flag.tenant_id, v_flag.subject_type, v_flag.user_id, v_flag.organization_id,
    null, null, 'risk_flag_resolved',
    jsonb_build_object('flag_id', p_flag_id, 'status', p_status, 'note', p_note)
  );
  perform kyc.fn_audit('kyc.risk_flag.resolved', p_flag_id, v_flag.tenant_id,
                      jsonb_build_object('status', p_status));
end;
$$;

-- 7.8 expire_due_verifications --------------------------------------------
-- Idempotent batch flip: approved → expired when expires_at <= now().
-- Returns number of rows flipped.
create or replace function kyc.expire_due_verifications()
returns integer
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_count integer := 0;
  v_row record;
begin
  -- Personal
  for v_row in
    update kyc.personal_verifications
       set status = 'expired',
           updated_by = auth.uid()
     where status = 'approved'
       and expires_at is not null
       and expires_at <= now()
       and deleted_at is null
    returning id, tenant_id, user_id
  loop
    perform kyc.fn_record_event(
      v_row.tenant_id, 'person', v_row.user_id, null,
      v_row.id, null, 'expired', '{}'::jsonb
    );
    v_count := v_count + 1;
  end loop;
  -- Organization
  for v_row in
    update kyc.organization_verifications
       set status = 'expired',
           updated_by = auth.uid()
     where status = 'approved'
       and expires_at is not null
       and expires_at <= now()
       and deleted_at is null
    returning id, tenant_id, organization_id
  loop
    perform kyc.fn_record_event(
      v_row.tenant_id, 'organization', null, v_row.organization_id,
      null, v_row.id, 'expired', '{}'::jsonb
    );
    v_count := v_count + 1;
  end loop;
  return v_count;
end;
$$;

-- ===========================================================================
-- 8. Read RPCs (subject + admin)
-- ===========================================================================

-- 8.1 get_my_personal_verification -----------------------------------------
create or replace function kyc.get_my_personal_verification()
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare v_uid uuid := auth.uid(); v_result jsonb;
begin
  if v_uid is null then
    raise exception 'kyc: not authenticated' using errcode = '42501';
  end if;
  with latest as (
    select * from kyc.personal_verifications
     where user_id = v_uid and deleted_at is null
     order by attempt_no desc
     limit 1
  )
  select jsonb_build_object(
    'id',                 latest.id,
    'tenant_id',          latest.tenant_id,
    'attempt_no',         latest.attempt_no,
    'status',             latest.status,
    'full_legal_name',    latest.full_legal_name,
    'national_id_last4',  latest.national_id_last4,
    'date_of_birth',      latest.date_of_birth,
    'country_code',       latest.country_code,
    'submitted_at',       latest.submitted_at,
    'reviewed_at',        latest.reviewed_at,
    'decision_reason',    latest.decision_reason,
    'approved_at',        latest.approved_at,
    'expires_at',         latest.expires_at,
    'documents', coalesce(
      (select jsonb_agg(jsonb_build_object(
          'id', d.id,
          'document_kind', d.document_kind,
          'title', d.title,
          'status', d.status,
          'rejection_reason', d.rejection_reason,
          'issued_on', d.issued_on,
          'expires_on', d.expires_on,
          'created_at', d.created_at
        )) from kyc.documents d
        where d.personal_verification_id = latest.id and d.deleted_at is null),
      '[]'::jsonb)
  ) into v_result from latest;

  return coalesce(v_result, jsonb_build_object('status', 'not_started'));
end;
$$;

-- 8.2 get_my_organization_verification -------------------------------------
create or replace function kyc.get_my_organization_verification(p_organization_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_ok boolean;
  v_result jsonb;
begin
  if v_uid is null then
    raise exception 'kyc: not authenticated' using errcode = '42501';
  end if;
  if not identity.is_platform_admin() then
    select exists (
      select 1 from organization.memberships m
       where m.user_id = v_uid
         and m.organization_id = p_organization_id
         and m.deleted_at is null
         and m.status = 'active'
    ) into v_ok;
    if not v_ok then
      raise exception 'kyc: not authorized for this organization' using errcode = '42501';
    end if;
  end if;

  with latest as (
    select * from kyc.organization_verifications
     where organization_id = p_organization_id and deleted_at is null
     order by attempt_no desc
     limit 1
  )
  select jsonb_build_object(
    'id',                  latest.id,
    'tenant_id',           latest.tenant_id,
    'organization_id',     latest.organization_id,
    'attempt_no',          latest.attempt_no,
    'status',              latest.status,
    'legal_name',          latest.legal_name,
    'registration_number', latest.registration_number,
    'tax_id',              latest.tax_id,
    'country_code',        latest.country_code,
    'incorporated_on',     latest.incorporated_on,
    'submitted_at',        latest.submitted_at,
    'reviewed_at',         latest.reviewed_at,
    'decision_reason',     latest.decision_reason,
    'approved_at',         latest.approved_at,
    'expires_at',          latest.expires_at,
    'documents', coalesce(
      (select jsonb_agg(jsonb_build_object(
          'id', d.id,
          'document_kind', d.document_kind,
          'title', d.title,
          'status', d.status,
          'rejection_reason', d.rejection_reason,
          'issued_on', d.issued_on,
          'expires_on', d.expires_on,
          'created_at', d.created_at
        )) from kyc.documents d
        where d.organization_verification_id = latest.id and d.deleted_at is null),
      '[]'::jsonb)
  ) into v_result from latest;

  return coalesce(v_result, jsonb_build_object('status', 'not_started'));
end;
$$;

-- 8.3 admin_list_verifications ---------------------------------------------
create or replace function kyc.admin_list_verifications(
  p_subject_type   kyc.kyc_subject_type,
  p_status_filter  kyc.kyc_status default null,
  p_limit          integer default 25,
  p_offset         integer default 0
) returns table (
  id uuid,
  tenant_id uuid,
  subject_type text,
  subject_id uuid,
  attempt_no integer,
  status text,
  submitted_at timestamptz,
  reviewed_at timestamptz,
  approved_at timestamptz,
  expires_at timestamptz,
  created_at timestamptz
)
language plpgsql stable security definer set search_path = ''
as $$
begin
  perform kyc.fn_assert_admin();
  if p_subject_type = 'person' then
    return query
      select pv.id, pv.tenant_id, 'person'::text, pv.user_id,
             pv.attempt_no, pv.status::text,
             pv.submitted_at, pv.reviewed_at, pv.approved_at, pv.expires_at,
             pv.created_at
        from kyc.personal_verifications pv
       where pv.deleted_at is null
         and (p_status_filter is null or pv.status = p_status_filter)
       order by pv.created_at desc
       limit p_limit offset p_offset;
  else
    return query
      select ov.id, ov.tenant_id, 'organization'::text, ov.organization_id,
             ov.attempt_no, ov.status::text,
             ov.submitted_at, ov.reviewed_at, ov.approved_at, ov.expires_at,
             ov.created_at
        from kyc.organization_verifications ov
       where ov.deleted_at is null
         and (p_status_filter is null or ov.status = p_status_filter)
       order by ov.created_at desc
       limit p_limit offset p_offset;
  end if;
end;
$$;

-- 8.4 admin_get_verification ----------------------------------------------
create or replace function kyc.admin_get_verification(
  p_verification_id uuid,
  p_subject_type    kyc.kyc_subject_type
) returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare v_result jsonb;
begin
  perform kyc.fn_assert_admin();
  if p_subject_type = 'person' then
    select jsonb_build_object(
      'subject_type', 'person',
      'verification', to_jsonb(pv),
      'documents', coalesce(
        (select jsonb_agg(to_jsonb(d)) from kyc.documents d
          where d.personal_verification_id = pv.id and d.deleted_at is null),
        '[]'::jsonb),
      'risk_flags', coalesce(
        (select jsonb_agg(to_jsonb(rf)) from kyc.risk_flags rf
          where rf.subject_type = 'person' and rf.user_id = pv.user_id and rf.deleted_at is null),
        '[]'::jsonb),
      'events', coalesce(
        (select jsonb_agg(to_jsonb(e) order by e.occurred_at desc) from kyc.events e
          where e.personal_verification_id = pv.id),
        '[]'::jsonb)
    ) into v_result
      from kyc.personal_verifications pv
     where pv.id = p_verification_id and pv.deleted_at is null;
  else
    select jsonb_build_object(
      'subject_type', 'organization',
      'verification', to_jsonb(ov),
      'documents', coalesce(
        (select jsonb_agg(to_jsonb(d)) from kyc.documents d
          where d.organization_verification_id = ov.id and d.deleted_at is null),
        '[]'::jsonb),
      'risk_flags', coalesce(
        (select jsonb_agg(to_jsonb(rf)) from kyc.risk_flags rf
          where rf.subject_type = 'organization' and rf.organization_id = ov.organization_id
            and rf.deleted_at is null),
        '[]'::jsonb),
      'events', coalesce(
        (select jsonb_agg(to_jsonb(e) order by e.occurred_at desc) from kyc.events e
          where e.organization_verification_id = ov.id),
        '[]'::jsonb)
    ) into v_result
      from kyc.organization_verifications ov
     where ov.id = p_verification_id and ov.deleted_at is null;
  end if;

  if v_result is null then
    raise exception 'kyc: verification not found' using errcode = 'P0002';
  end if;
  return v_result;
end;
$$;

-- ===========================================================================
-- 9. Helper RPCs (downstream gating)
-- ===========================================================================

-- 9.1 is_personal_verified -------------------------------------------------
create or replace function kyc.is_personal_verified(p_user_id uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from kyc.personal_verifications
     where user_id = p_user_id
       and status = 'approved'
       and deleted_at is null
       and (expires_at is null or expires_at > now())
  );
$$;

comment on function kyc.is_personal_verified(uuid) is
  'True iff the user has a non-expired approved KYC attempt. Helper for future downstream gating; not wired into CC-22.';

-- 9.2 is_organization_verified ---------------------------------------------
create or replace function kyc.is_organization_verified(p_organization_id uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from kyc.organization_verifications
     where organization_id = p_organization_id
       and status = 'approved'
       and deleted_at is null
       and (expires_at is null or expires_at > now())
  );
$$;

comment on function kyc.is_organization_verified(uuid) is
  'True iff the organization has a non-expired approved KYB attempt. Helper for future downstream gating; not wired into CC-22.';

-- ===========================================================================
-- 10. Trigger attachments (updated_at + audit_entity)
-- ===========================================================================
do $$
declare r record;
begin
  for r in
    select unnest(array[
      'personal_verifications', 'organization_verifications',
      'documents', 'risk_flags'
    ]) as table_name
  loop
    execute format(
      'drop trigger if exists trg_set_updated_at on kyc.%I',
      r.table_name
    );
    execute format(
      'create trigger trg_set_updated_at before update on kyc.%I '
      'for each row execute function identity.set_updated_at()',
      r.table_name
    );
  end loop;
end;
$$;

do $$
declare r record;
begin
  for r in
    select unnest(array[
      'personal_verifications', 'organization_verifications',
      'documents', 'risk_flags', 'events'
    ]) as table_name
  loop
    execute format(
      'drop trigger if exists trg_audit_entity on kyc.%I',
      r.table_name
    );
    execute format(
      'create trigger trg_audit_entity after insert or update or delete on kyc.%I '
      'for each row execute function audit.fn_audit_entity()',
      r.table_name
    );
  end loop;
end;
$$;

-- ===========================================================================
-- 11. Grants (SELECT only; mutations via SECURITY DEFINER RPCs)
-- ===========================================================================
-- 11.1 Default revokes from anon (RLS is the second wall).
revoke all on all tables in schema kyc from anon;

-- 11.2 Explicit table grants.
-- Q4: personal_verifications uses column-list SELECT (excludes
-- national_id_number_hash). PostgreSQL ignores column-level REVOKE after a
-- table-level GRANT, so we never grant SELECT at table-level for this table.
grant select (
  id, tenant_id, user_id, attempt_no,
  status, full_legal_name, national_id_last4,
  date_of_birth, country_code,
  submitted_at, reviewed_at, reviewed_by, decision_reason,
  approved_at, expires_at,
  created_at, updated_by, updated_at, deleted_at, version
) on kyc.personal_verifications to authenticated;

grant select on kyc.organization_verifications  to authenticated;
grant select on kyc.documents                   to authenticated;
grant select on kyc.events                      to authenticated;
-- risk_flags: no direct SELECT grant to authenticated; admin RPC reads only.

-- ===========================================================================
-- 12. RPC EXECUTE grants
-- ===========================================================================
grant execute on function kyc.start_personal_verification()        to authenticated;
grant execute on function kyc.update_personal_draft(uuid, text, text, date, char) to authenticated;
grant execute on function kyc.submit_personal_verification(uuid)   to authenticated;
grant execute on function kyc.start_organization_verification(uuid) to authenticated;
grant execute on function kyc.update_organization_draft(uuid, text, text, text, char, date) to authenticated;
grant execute on function kyc.submit_organization_verification(uuid) to authenticated;
grant execute on function kyc.attach_document(uuid, kyc.kyc_subject_type, kyc.kyc_document_kind, text, text, text, bigint, date, date) to authenticated;

grant execute on function kyc.admin_assign_verification(uuid, kyc.kyc_subject_type) to authenticated;
grant execute on function kyc.admin_request_info(uuid, kyc.kyc_subject_type, text)  to authenticated;
grant execute on function kyc.admin_approve_verification(uuid, kyc.kyc_subject_type, integer) to authenticated;
grant execute on function kyc.admin_reject_verification(uuid, kyc.kyc_subject_type, text) to authenticated;
grant execute on function kyc.admin_decide_document(uuid, kyc.kyc_document_status, text) to authenticated;
grant execute on function kyc.admin_raise_risk_flag(kyc.kyc_subject_type, uuid, uuid, text, kyc.kyc_risk_severity, text, text) to authenticated;
grant execute on function kyc.admin_resolve_risk_flag(uuid, kyc.kyc_risk_status, text) to authenticated;
grant execute on function kyc.expire_due_verifications() to authenticated, service_role;

grant execute on function kyc.get_my_personal_verification()       to authenticated;
grant execute on function kyc.get_my_organization_verification(uuid) to authenticated;
grant execute on function kyc.admin_list_verifications(kyc.kyc_subject_type, kyc.kyc_status, integer, integer) to authenticated;
grant execute on function kyc.admin_get_verification(uuid, kyc.kyc_subject_type) to authenticated;

grant execute on function kyc.is_personal_verified(uuid)       to authenticated;
grant execute on function kyc.is_organization_verified(uuid)   to authenticated;
