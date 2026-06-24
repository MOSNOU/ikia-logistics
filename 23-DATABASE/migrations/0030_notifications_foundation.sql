-- CC-19 / Migration 0030 — Notifications & Messaging Foundation
-- Thirteenth business-domain step. New `notify` schema atop CC-09..CC-18.
-- Append-only over migrations 0001-0029. Strictly additive — does not modify
-- any prior table, RPC body, or grant.
--
-- Locked decisions (Q1–Q10):
--   Q1=A (per-domain AFTER INSERT triggers), Q2=skip subscriptions,
--   Q3=adopt materialization_audit, Q4=ship seed templates, Q5=opt-out,
--   Q6=skipped for non-in_app, Q7=no dismiss RPC, Q8=buyer-only evaluation,
--   Q9=all 12 source tables hooked, Q10=no UI.
--
-- Security model: SECURITY DEFINER RPCs only; no direct write grants;
-- search_path=''. Portal RPCs derive caller from auth.uid() — no
-- p_organization_id / p_supplier_id / p_user_id parameters.

-- ===========================================================================
-- 1. Schema
-- ===========================================================================
create schema if not exists notify;
grant usage on schema notify to anon, authenticated, service_role;
comment on schema notify is
  'iKIA Phase 2 — notifications / messaging foundation. Record-keeping + in-app inbox only; no email/SMS/push provider, no WebSocket, no worker, no UI.';

-- ===========================================================================
-- 2. Enums (6)
-- ===========================================================================
create type notify.notification_category as enum (
  'rfq', 'offer', 'evaluation', 'contract', 'shipment',
  'finance', 'settlement', 'dispute', 'supplier_admin', 'platform', 'other'
);

create type notify.notification_priority as enum (
  'low', 'normal', 'high', 'urgent'
);

create type notify.notification_status as enum (
  'unread', 'read', 'archived', 'dismissed'
);

create type notify.channel_type as enum (
  'in_app', 'email', 'sms', 'push', 'webhook'
);

create type notify.delivery_status as enum (
  'pending', 'sent', 'delivered', 'failed', 'skipped', 'suppressed'
);

create type notify.template_status as enum (
  'draft', 'active', 'deprecated'
);

-- ===========================================================================
-- 3. Tables (5)
-- ===========================================================================

-- 3.1 notification_templates ----------------------------------------------
create table notify.notification_templates (
  id                  uuid primary key default gen_random_uuid(),
  tenant_id           uuid references identity.tenants(id) on delete restrict,
  organization_id     uuid references organization.organizations(id) on delete cascade,

  template_code       text not null,
  category            notify.notification_category not null,
  default_priority    notify.notification_priority not null default 'normal',
  default_channels    notify.channel_type[] not null default array['in_app']::notify.channel_type[],
  status              notify.template_status not null default 'active',

  title_en            text not null,
  title_fa            text not null,
  body_en             text not null,
  body_fa             text not null,
  action_url_template text,
  event_type_filter   text,

  metadata            jsonb not null default '{}'::jsonb,

  created_by          uuid references auth.users(id) on delete set null,
  created_at          timestamptz not null default now(),
  updated_by          uuid references auth.users(id) on delete set null,
  updated_at          timestamptz not null default now(),
  deleted_at          timestamptz,
  version             integer not null default 1
);

comment on table notify.notification_templates is
  'Template registry. organization_id IS NULL means platform-level; org-scoped templates win during resolution.';

-- Q4: ensure tenant+code uniqueness for active templates.
create unique index notification_templates_unique_active
  on notify.notification_templates(coalesce(tenant_id, '00000000-0000-0000-0000-000000000000'::uuid),
                                    lower(template_code))
  where deleted_at is null;

create index notification_templates_category_idx
  on notify.notification_templates(category)
  where deleted_at is null;

-- 3.2 user_preferences ----------------------------------------------------
create table notify.user_preferences (
  id                  uuid primary key default gen_random_uuid(),
  tenant_id           uuid not null references identity.tenants(id) on delete restrict,
  user_id             uuid not null references auth.users(id) on delete cascade,
  organization_id     uuid references organization.organizations(id) on delete cascade,

  category            notify.notification_category not null,
  channel             notify.channel_type not null,
  enabled             boolean not null default true,
  quiet_hours_start   time,
  quiet_hours_end     time,
  metadata            jsonb not null default '{}'::jsonb,

  created_at          timestamptz not null default now(),
  updated_by          uuid references auth.users(id) on delete set null,
  updated_at          timestamptz not null default now(),
  deleted_at          timestamptz,
  version             integer not null default 1
);

comment on table notify.user_preferences is
  'Q5: opt-out default. Absence of a row means enabled. organization_id NULL = applies across all orgs the user belongs to.';

create unique index user_preferences_unique_active
  on notify.user_preferences(user_id,
                              coalesce(organization_id, '00000000-0000-0000-0000-000000000000'::uuid),
                              category, channel)
  where deleted_at is null;

create index user_preferences_user_idx
  on notify.user_preferences(user_id) where deleted_at is null;

-- 3.3 notifications (inbox) ----------------------------------------------
create table notify.notifications (
  id                  uuid primary key default gen_random_uuid(),
  tenant_id           uuid not null references identity.tenants(id) on delete restrict,
  organization_id     uuid references organization.organizations(id) on delete set null,

  recipient_user_id   uuid not null references auth.users(id) on delete cascade,
  recipient_role_hint text,
  recipient_party     text,

  category            notify.notification_category not null,
  priority            notify.notification_priority not null default 'normal',
  status              notify.notification_status not null default 'unread',

  template_code       text,
  title_en            text not null,
  title_fa            text not null,
  body_en             text,
  body_fa             text,
  action_url          text,

  source_event_type   text,
  source_entity_type  text,
  source_entity_id    uuid,
  source_event_id     uuid,

  payload             jsonb not null default '{}'::jsonb,
  read_at             timestamptz,
  read_by             uuid references auth.users(id) on delete set null,
  archived_at         timestamptz,
  dismissed_at        timestamptz,

  created_at          timestamptz not null default now(),
  deleted_at          timestamptz,
  version             integer not null default 1
);

comment on table notify.notifications is
  'Per-user inbox row. One source event → N notification rows (one per recipient × channel).';

create index notifications_recipient_status_idx
  on notify.notifications(recipient_user_id, status, created_at desc) where deleted_at is null;

create index notifications_recipient_unread_idx
  on notify.notifications(recipient_user_id)
  where status = 'unread' and deleted_at is null;

create index notifications_entity_idx
  on notify.notifications(source_entity_type, source_entity_id) where deleted_at is null;

create index notifications_org_idx
  on notify.notifications(tenant_id, organization_id, created_at desc) where deleted_at is null;

-- 3.4 delivery_attempts --------------------------------------------------
create table notify.delivery_attempts (
  id                  uuid primary key default gen_random_uuid(),
  tenant_id           uuid not null references identity.tenants(id) on delete restrict,
  organization_id     uuid references organization.organizations(id) on delete set null,
  notification_id     uuid not null references notify.notifications(id) on delete cascade,

  channel             notify.channel_type not null,
  status              notify.delivery_status not null default 'pending',
  attempt_number      integer not null default 1,
  attempted_at        timestamptz,
  delivered_at        timestamptz,
  failed_at           timestamptz,
  failure_reason      text,
  external_reference  text,
  payload             jsonb not null default '{}'::jsonb,
  created_at          timestamptz not null default now()
);

comment on table notify.delivery_attempts is
  'Per-(notification, channel) delivery record. in_app=delivered immediately; other channels Q6=skipped with channel_not_implemented.';

create index delivery_attempts_notification_idx
  on notify.delivery_attempts(notification_id, attempt_number);
create index delivery_attempts_status_idx
  on notify.delivery_attempts(channel, status);

-- 3.5 materialization_audit (immutable, Q3) -------------------------------
create table notify.materialization_audit (
  id                      uuid primary key default gen_random_uuid(),
  tenant_id               uuid references identity.tenants(id) on delete set null,
  organization_id         uuid references organization.organizations(id) on delete set null,
  source_event_type       text,
  source_entity_type      text,
  source_entity_id        uuid,
  source_event_id         uuid,
  template_code           text,
  recipients_resolved     integer not null default 0,
  notifications_created   integer not null default 0,
  notes                   text,
  metadata                jsonb not null default '{}'::jsonb,
  created_at              timestamptz not null default now()
);

comment on table notify.materialization_audit is
  'Q3: immutable trace of every event the materializer processed. No UPDATE/DELETE policies.';

create index materialization_audit_entity_idx
  on notify.materialization_audit(source_entity_type, source_entity_id, created_at desc);

-- ===========================================================================
-- 4. Internal helpers
-- ===========================================================================

-- 4.1 fn_audit -------------------------------------------------------------
create or replace function notify.fn_audit(
  p_action_code text,
  p_notification_id uuid,
  p_payload jsonb default '{}'::jsonb
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare v_t uuid; v_o uuid;
begin
  select tenant_id, organization_id into v_t, v_o
    from notify.notifications where id = p_notification_id;
  insert into audit.audit_event (
    tenant_id, organization_id, actor_user_id, action_code,
    resource_type, resource_id, payload, occurred_at
  ) values (v_t, v_o, auth.uid(), p_action_code,
            'notification', p_notification_id, p_payload, now());
exception when others then null;
end;
$$;

-- 4.2 fn_resolve_template --------------------------------------------------
-- Lookup priority: tenant+code exact (org-scoped wins via tenant filter), then
-- platform (tenant_id NULL) + code exact, then category-fallback.
create or replace function notify.fn_resolve_template(
  p_template_code text,
  p_category      notify.notification_category,
  p_tenant_id     uuid
) returns notify.notification_templates
language plpgsql stable security definer set search_path = ''
as $$
declare v_row notify.notification_templates%rowtype;
begin
  -- Org/tenant-scoped exact match
  select * into v_row from notify.notification_templates
   where tenant_id = p_tenant_id
     and lower(template_code) = lower(p_template_code)
     and status = 'active'
     and deleted_at is null
   limit 1;
  if v_row.id is not null then return v_row; end if;

  -- Platform-scoped exact match (tenant_id IS NULL)
  select * into v_row from notify.notification_templates
   where tenant_id is null
     and lower(template_code) = lower(p_template_code)
     and status = 'active'
     and deleted_at is null
   limit 1;
  if v_row.id is not null then return v_row; end if;

  -- Category fallback
  select * into v_row from notify.notification_templates
   where category = p_category
     and event_type_filter is null
     and status = 'active'
     and deleted_at is null
   order by case when tenant_id = p_tenant_id then 0 else 1 end
   limit 1;
  return v_row;
end;
$$;

-- 4.3 fn_resolve_recipients ------------------------------------------------
-- Returns the recipient set (user_id, party, role_hint, organization_id) for
-- a domain entity. Q8 default: suppliers do NOT receive evaluation events.
create or replace function notify.fn_resolve_recipients(
  p_entity_type text,
  p_entity_id   uuid,
  p_category    notify.notification_category
) returns table (
  recipient_user_id    uuid,
  recipient_party      text,
  recipient_role_hint  text,
  organization_id      uuid
)
language plpgsql stable security definer set search_path = ''
as $$
declare
  v_buyer_org uuid;
  v_supplier_id uuid;
  v_supplier_org uuid;
  v_mediator uuid;
begin
  case p_entity_type
    when 'rfq' then
      select r.organization_id into v_buyer_org from rfq.requests r where r.id = p_entity_id;
    when 'offer' then
      select r.organization_id, so.supplier_id, so.organization_id
        into v_buyer_org, v_supplier_id, v_supplier_org
        from offer.supplier_offers so
        join rfq.requests r on r.id = so.request_id
       where so.id = p_entity_id;
    when 'evaluation_decision' then
      select d.organization_id into v_buyer_org
        from evaluation.offer_decisions d where d.id = p_entity_id;
    when 'contract_preparation' then
      select p.organization_id, p.supplier_id, p.supplier_organization_id
        into v_buyer_org, v_supplier_id, v_supplier_org
        from contract.contract_preparations p where p.id = p_entity_id;
    when 'executed_contract' then
      select ec.organization_id, ec.supplier_id, ec.supplier_organization_id
        into v_buyer_org, v_supplier_id, v_supplier_org
        from contract.executed_contracts ec where ec.id = p_entity_id;
    when 'signature_request' then
      select ec.organization_id, ec.supplier_id, ec.supplier_organization_id
        into v_buyer_org, v_supplier_id, v_supplier_org
        from contract.contract_signature_requests sr
        join contract.executed_contracts ec on ec.id = sr.contract_id
       where sr.id = p_entity_id;
    when 'shipment' then
      select sh.organization_id, sh.supplier_id, sh.supplier_organization_id
        into v_buyer_org, v_supplier_id, v_supplier_org
        from shipment.shipments sh where sh.id = p_entity_id;
    when 'invoice' then
      select i.organization_id, i.supplier_id, i.supplier_organization_id
        into v_buyer_org, v_supplier_id, v_supplier_org
        from finance.invoices i where i.id = p_entity_id;
    when 'payment' then
      select i.organization_id, i.supplier_id, i.supplier_organization_id
        into v_buyer_org, v_supplier_id, v_supplier_org
        from finance.payments p
        join finance.invoices i on i.id = p.invoice_id
       where p.id = p_entity_id;
    when 'settlement' then
      select s.organization_id, s.supplier_id, s.supplier_organization_id
        into v_buyer_org, v_supplier_id, v_supplier_org
        from settlement.settlements s where s.id = p_entity_id;
    when 'escrow_account' then
      select ea.organization_id, ea.supplier_id, ea.supplier_organization_id
        into v_buyer_org, v_supplier_id, v_supplier_org
        from settlement.escrow_accounts ea where ea.id = p_entity_id;
    when 'dispute' then
      select d.organization_id, d.supplier_id, d.supplier_organization_id, d.assigned_mediator_id
        into v_buyer_org, v_supplier_id, v_supplier_org, v_mediator
        from dispute.disputes d where d.id = p_entity_id;
    else
      return;
  end case;

  if v_buyer_org is null then return; end if;

  -- Buyer-side recipients (DISTINCT user_id)
  return query
    select distinct m.user_id, 'buyer'::text,
           (array_agg(r.code) over (partition by m.user_id))[1]::text, v_buyer_org
      from organization.memberships m
      join identity.roles r on r.id = m.role_id
     where m.organization_id = v_buyer_org
       and m.deleted_at is null
       and m.status = 'active'
       and r.code in ('buyer_admin', 'organization_admin');

  -- Supplier-side (Q8: suppressed for evaluation category).
  if v_supplier_org is not null and p_category <> 'evaluation' then
    return query
      select distinct m.user_id, 'supplier'::text,
             (array_agg(r.code) over (partition by m.user_id))[1]::text, v_supplier_org
        from organization.memberships m
        join identity.roles r on r.id = m.role_id
       where m.organization_id = v_supplier_org
         and m.deleted_at is null
         and m.status = 'active'
         and r.code in ('supplier_admin', 'organization_admin');
  end if;

  -- Mediator (disputes only).
  if v_mediator is not null then
    return query select v_mediator, 'platform'::text, 'platform_admin'::text, v_buyer_org;
  end if;
end;
$$;

-- 4.4 fn_substitute_action_url ---------------------------------------------
create or replace function notify.fn_substitute_action_url(
  p_template text, p_entity_id uuid
) returns text
language plpgsql immutable security definer set search_path = ''
as $$
begin
  if p_template is null then return null; end if;
  return replace(p_template, '${entity_id}', p_entity_id::text);
end;
$$;

-- 4.5 fn_materialize_event -------------------------------------------------
create or replace function notify.fn_materialize_event(
  p_source_event_type   text,
  p_source_entity_type  text,
  p_source_entity_id    uuid,
  p_source_event_id     uuid,
  p_category            notify.notification_category,
  p_payload             jsonb,
  p_tenant_id           uuid
) returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_template notify.notification_templates%rowtype;
  v_recip record;
  v_recipients int := 0;
  v_notifications int := 0;
  v_n_id uuid;
  v_action_url text;
  v_channel notify.channel_type;
  v_pref_enabled boolean;
begin
  v_template := notify.fn_resolve_template(p_source_event_type, p_category, p_tenant_id);
  if v_template.id is null then
    insert into notify.materialization_audit (
      tenant_id, source_event_type, source_entity_type,
      source_entity_id, source_event_id, template_code,
      recipients_resolved, notifications_created, notes
    ) values (
      p_tenant_id, p_source_event_type, p_source_entity_type,
      p_source_entity_id, p_source_event_id, null, 0, 0, 'no_template_matched'
    );
    return;
  end if;

  v_action_url := notify.fn_substitute_action_url(v_template.action_url_template, p_source_entity_id);

  for v_recip in
    select * from notify.fn_resolve_recipients(p_source_entity_type, p_source_entity_id, p_category)
  loop
    v_recipients := v_recipients + 1;

    foreach v_channel in array v_template.default_channels loop
      -- Q5 opt-out: check explicit preferences. Absence = enabled.
      v_pref_enabled := null;
      select enabled into v_pref_enabled
        from notify.user_preferences
       where user_id = v_recip.recipient_user_id
         and (organization_id = v_recip.organization_id or organization_id is null)
         and category = p_category
         and channel = v_channel
         and deleted_at is null
       order by case when organization_id = v_recip.organization_id then 0 else 1 end
       limit 1;
      if v_pref_enabled is false then continue; end if;

      insert into notify.notifications (
        tenant_id, organization_id, recipient_user_id, recipient_role_hint, recipient_party,
        category, priority, status, template_code,
        title_en, title_fa, body_en, body_fa, action_url,
        source_event_type, source_entity_type, source_entity_id, source_event_id, payload
      ) values (
        p_tenant_id, v_recip.organization_id,
        v_recip.recipient_user_id, v_recip.recipient_role_hint, v_recip.recipient_party,
        p_category, v_template.default_priority, 'unread', v_template.template_code,
        v_template.title_en, v_template.title_fa, v_template.body_en, v_template.body_fa, v_action_url,
        p_source_event_type, p_source_entity_type, p_source_entity_id, p_source_event_id,
        coalesce(p_payload, '{}'::jsonb)
      ) returning id into v_n_id;
      v_notifications := v_notifications + 1;

      if v_channel = 'in_app' then
        insert into notify.delivery_attempts (
          tenant_id, organization_id, notification_id, channel,
          status, attempted_at, delivered_at
        ) values (
          p_tenant_id, v_recip.organization_id, v_n_id, 'in_app',
          'delivered', now(), now()
        );
      else
        -- Q6: skipped for non-in_app channels in CC-19.
        insert into notify.delivery_attempts (
          tenant_id, organization_id, notification_id, channel,
          status, attempted_at, failure_reason
        ) values (
          p_tenant_id, v_recip.organization_id, v_n_id, v_channel,
          'skipped', now(), 'channel_not_implemented'
        );
      end if;
    end loop;
  end loop;

  insert into notify.materialization_audit (
    tenant_id, source_event_type, source_entity_type,
    source_entity_id, source_event_id, template_code,
    recipients_resolved, notifications_created, notes
  ) values (
    p_tenant_id, p_source_event_type, p_source_entity_type,
    p_source_entity_id, p_source_event_id, v_template.template_code,
    v_recipients, v_notifications,
    case when v_recipients = 0 then 'no_recipients' else 'ok' end
  );
exception when others then
  -- Never block the upstream domain write.
  insert into notify.materialization_audit (
    tenant_id, source_event_type, source_entity_type,
    source_entity_id, source_event_id, template_code,
    recipients_resolved, notifications_created, notes
  ) values (
    p_tenant_id, p_source_event_type, p_source_entity_type,
    p_source_entity_id, p_source_event_id, null, 0, 0,
    'error: ' || sqlerrm
  );
end;
$$;

-- ===========================================================================
-- 5. Per-domain trigger functions (12, Q1=A)
-- ===========================================================================

create or replace function notify.fn_trg_from_rfq_status()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  perform notify.fn_materialize_event(
    'rfq.' || new.to_status::text, 'rfq', new.request_id, new.id,
    'rfq'::notify.notification_category, coalesce(new.payload, '{}'::jsonb), new.tenant_id
  );
  return new;
end;
$$;

create or replace function notify.fn_trg_from_offer_status()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  perform notify.fn_materialize_event(
    'offer.' || new.to_status::text, 'offer', new.offer_id, new.id,
    'offer'::notify.notification_category, coalesce(new.payload, '{}'::jsonb), new.tenant_id
  );
  return new;
end;
$$;

create or replace function notify.fn_trg_from_evaluation_decision()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  perform notify.fn_materialize_event(
    'evaluation.' || new.to_status::text, 'evaluation_decision', new.decision_id, new.id,
    'evaluation'::notify.notification_category, coalesce(new.payload, '{}'::jsonb), new.tenant_id
  );
  return new;
end;
$$;

create or replace function notify.fn_trg_from_preparation()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  perform notify.fn_materialize_event(
    'contract_preparation.' || new.to_status::text, 'contract_preparation',
    new.preparation_id, new.id,
    'contract'::notify.notification_category, coalesce(new.payload, '{}'::jsonb), new.tenant_id
  );
  return new;
end;
$$;

create or replace function notify.fn_trg_from_executed_contract()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  perform notify.fn_materialize_event(
    'executed_contract.' || new.to_status::text, 'executed_contract',
    new.contract_id, new.id,
    'contract'::notify.notification_category, coalesce(new.payload, '{}'::jsonb), new.tenant_id
  );
  return new;
end;
$$;

create or replace function notify.fn_trg_from_signature()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  perform notify.fn_materialize_event(
    'signature.' || coalesce(new.event_type, new.to_status::text),
    'signature_request', new.signature_request_id, new.id,
    'contract'::notify.notification_category, coalesce(new.metadata, '{}'::jsonb), new.tenant_id
  );
  return new;
end;
$$;

create or replace function notify.fn_trg_from_shipment()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  perform notify.fn_materialize_event(
    'shipment.' || coalesce(new.event_type, new.to_status::text),
    'shipment', new.shipment_id, new.id,
    'shipment'::notify.notification_category, coalesce(new.metadata, '{}'::jsonb), new.tenant_id
  );
  return new;
end;
$$;

create or replace function notify.fn_trg_from_invoice()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  perform notify.fn_materialize_event(
    'invoice.' || new.to_status::text, 'invoice', new.invoice_id, new.id,
    'finance'::notify.notification_category, coalesce(new.payload, '{}'::jsonb), new.tenant_id
  );
  return new;
end;
$$;

create or replace function notify.fn_trg_from_payment()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  perform notify.fn_materialize_event(
    'payment.' || new.to_status::text, 'payment', new.payment_id, new.id,
    'finance'::notify.notification_category, coalesce(new.payload, '{}'::jsonb), new.tenant_id
  );
  return new;
end;
$$;

create or replace function notify.fn_trg_from_settlement()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  perform notify.fn_materialize_event(
    'settlement.' || coalesce(new.event_type, new.to_status::text),
    'settlement', new.settlement_id, new.id,
    'settlement'::notify.notification_category, coalesce(new.payload, '{}'::jsonb), new.tenant_id
  );
  return new;
end;
$$;

create or replace function notify.fn_trg_from_escrow()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  perform notify.fn_materialize_event(
    'escrow.' || new.to_status::text, 'escrow_account', new.escrow_account_id, new.id,
    'settlement'::notify.notification_category, coalesce(new.metadata, '{}'::jsonb), new.tenant_id
  );
  return new;
end;
$$;

create or replace function notify.fn_trg_from_dispute()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  perform notify.fn_materialize_event(
    'dispute.' || coalesce(new.event_type, new.to_status::text),
    'dispute', new.dispute_id, new.id,
    'dispute'::notify.notification_category, coalesce(new.payload, '{}'::jsonb), new.tenant_id
  );
  return new;
end;
$$;

-- ===========================================================================
-- 6. Trigger attachments on existing event tables (additive only)
-- ===========================================================================
drop trigger if exists trg_notify_from_rfq_status on rfq.request_status_events;
create trigger trg_notify_from_rfq_status after insert on rfq.request_status_events
  for each row execute function notify.fn_trg_from_rfq_status();

drop trigger if exists trg_notify_from_offer_status on offer.supplier_offer_status_events;
create trigger trg_notify_from_offer_status after insert on offer.supplier_offer_status_events
  for each row execute function notify.fn_trg_from_offer_status();

drop trigger if exists trg_notify_from_evaluation_decision on evaluation.offer_decision_events;
create trigger trg_notify_from_evaluation_decision after insert on evaluation.offer_decision_events
  for each row execute function notify.fn_trg_from_evaluation_decision();

drop trigger if exists trg_notify_from_preparation on contract.contract_preparation_events;
create trigger trg_notify_from_preparation after insert on contract.contract_preparation_events
  for each row execute function notify.fn_trg_from_preparation();

drop trigger if exists trg_notify_from_executed_contract on contract.executed_contract_events;
create trigger trg_notify_from_executed_contract after insert on contract.executed_contract_events
  for each row execute function notify.fn_trg_from_executed_contract();

drop trigger if exists trg_notify_from_signature on contract.contract_signature_events;
create trigger trg_notify_from_signature after insert on contract.contract_signature_events
  for each row execute function notify.fn_trg_from_signature();

drop trigger if exists trg_notify_from_shipment on shipment.shipment_events;
create trigger trg_notify_from_shipment after insert on shipment.shipment_events
  for each row execute function notify.fn_trg_from_shipment();

drop trigger if exists trg_notify_from_invoice on finance.invoice_status_events;
create trigger trg_notify_from_invoice after insert on finance.invoice_status_events
  for each row execute function notify.fn_trg_from_invoice();

drop trigger if exists trg_notify_from_payment on finance.payment_status_events;
create trigger trg_notify_from_payment after insert on finance.payment_status_events
  for each row execute function notify.fn_trg_from_payment();

drop trigger if exists trg_notify_from_settlement on settlement.settlement_events;
create trigger trg_notify_from_settlement after insert on settlement.settlement_events
  for each row execute function notify.fn_trg_from_settlement();

drop trigger if exists trg_notify_from_escrow on settlement.escrow_status_events;
create trigger trg_notify_from_escrow after insert on settlement.escrow_status_events
  for each row execute function notify.fn_trg_from_escrow();

drop trigger if exists trg_notify_from_dispute on dispute.dispute_events;
create trigger trg_notify_from_dispute after insert on dispute.dispute_events
  for each row execute function notify.fn_trg_from_dispute();

-- ===========================================================================
-- 7. Row Level Security
-- ===========================================================================
alter table notify.notification_templates  enable row level security;
alter table notify.user_preferences        enable row level security;
alter table notify.notifications           enable row level security;
alter table notify.delivery_attempts       enable row level security;
alter table notify.materialization_audit   enable row level security;

-- 7.1 notification_templates: org members for org-scoped; all auth for platform.
drop policy if exists notification_templates_select on notify.notification_templates;
create policy notification_templates_select on notify.notification_templates
  for select
  using (
    deleted_at is null
    and (
      identity.is_platform_admin()
      or tenant_id is null
      or exists (
        select 1 from organization.memberships m
         where m.user_id = identity.current_user_id()
           and m.organization_id = notification_templates.organization_id
           and m.deleted_at is null and m.status = 'active'
      )
    )
  );

drop policy if exists notification_templates_admin_modify on notify.notification_templates;
create policy notification_templates_admin_modify on notify.notification_templates
  for all using (identity.is_platform_admin()) with check (identity.is_platform_admin());

-- 7.2 user_preferences: own user.
drop policy if exists user_preferences_select on notify.user_preferences;
create policy user_preferences_select on notify.user_preferences
  for select
  using (
    deleted_at is null
    and (
      identity.is_platform_admin()
      or user_id = identity.current_user_id()
    )
  );

drop policy if exists user_preferences_admin_modify on notify.user_preferences;
create policy user_preferences_admin_modify on notify.user_preferences
  for all using (identity.is_platform_admin()) with check (identity.is_platform_admin());

-- 7.3 notifications: own inbox only.
drop policy if exists notifications_select on notify.notifications;
create policy notifications_select on notify.notifications
  for select
  using (
    deleted_at is null
    and (
      identity.is_platform_admin()
      or recipient_user_id = identity.current_user_id()
    )
  );

drop policy if exists notifications_admin_modify on notify.notifications;
create policy notifications_admin_modify on notify.notifications
  for all using (identity.is_platform_admin()) with check (identity.is_platform_admin());

-- 7.4 delivery_attempts: parent notification's recipient org members + admin.
drop policy if exists delivery_attempts_select on notify.delivery_attempts;
create policy delivery_attempts_select on notify.delivery_attempts
  for select
  using (
    identity.is_platform_admin()
    or exists (
      select 1 from notify.notifications n
       where n.id = delivery_attempts.notification_id
         and n.recipient_user_id = identity.current_user_id()
    )
  );

-- 7.5 materialization_audit: platform_admin only.
drop policy if exists materialization_audit_select on notify.materialization_audit;
create policy materialization_audit_select on notify.materialization_audit
  for select using (identity.is_platform_admin());

-- ===========================================================================
-- 8. Portal RPCs (7)
-- ===========================================================================

-- 8.1 portal_list_my_notifications -----------------------------------------
create or replace function notify.portal_list_my_notifications(
  p_status   notify.notification_status default null,
  p_category notify.notification_category default null,
  p_limit    integer default 25,
  p_offset   integer default 0
) returns table (
  id uuid, category text, priority text, status text,
  title_en text, title_fa text, body_en text, body_fa text, action_url text,
  source_event_type text, source_entity_type text, source_entity_id uuid,
  read_at timestamptz, created_at timestamptz
)
language plpgsql stable security definer set search_path = ''
as $$
declare v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'notify: not authenticated' using errcode = '42501';
  end if;
  return query
    select n.id, n.category::text, n.priority::text, n.status::text,
           n.title_en, n.title_fa, n.body_en, n.body_fa, n.action_url,
           n.source_event_type, n.source_entity_type, n.source_entity_id,
           n.read_at, n.created_at
      from notify.notifications n
     where n.deleted_at is null
       and n.recipient_user_id = v_uid
       and (p_status is null or n.status = p_status)
       and (p_category is null or n.category = p_category)
     order by case n.priority
                when 'urgent' then 0 when 'high' then 1
                when 'normal' then 2 else 3 end,
              n.created_at desc
     limit p_limit offset p_offset;
end;
$$;

-- 8.2 portal_get_notification ----------------------------------------------
create or replace function notify.portal_get_notification(p_notification_id uuid)
returns jsonb
language plpgsql stable security definer set search_path = ''
as $$
declare v_uid uuid := auth.uid(); v_recipient uuid;
begin
  select recipient_user_id into v_recipient from notify.notifications
   where id = p_notification_id and deleted_at is null;
  if v_recipient is null then
    raise exception 'notify: not found' using errcode = 'P0002';
  end if;
  if v_recipient <> v_uid and not identity.is_platform_admin() then
    raise exception 'notify: not your notification' using errcode = '42501';
  end if;
  return (
    select jsonb_build_object(
      'id', n.id, 'category', n.category, 'priority', n.priority, 'status', n.status,
      'title_en', n.title_en, 'title_fa', n.title_fa,
      'body_en', n.body_en, 'body_fa', n.body_fa,
      'action_url', n.action_url,
      'source_event_type', n.source_event_type,
      'source_entity_type', n.source_entity_type,
      'source_entity_id', n.source_entity_id,
      'payload', n.payload,
      'read_at', n.read_at, 'created_at', n.created_at
    ) from notify.notifications n where n.id = p_notification_id
  );
end;
$$;

-- 8.3 portal_unread_count --------------------------------------------------
create or replace function notify.portal_unread_count(
  p_category notify.notification_category default null
) returns integer
language plpgsql stable security definer set search_path = ''
as $$
declare v_uid uuid := auth.uid(); v_count integer;
begin
  if v_uid is null then return 0; end if;
  select count(*) into v_count from notify.notifications
   where recipient_user_id = v_uid
     and status = 'unread' and deleted_at is null
     and (p_category is null or category = p_category);
  return v_count;
end;
$$;

-- 8.4 portal_mark_read -----------------------------------------------------
create or replace function notify.portal_mark_read(p_notification_id uuid)
returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare v_uid uuid := auth.uid(); v_recipient uuid; v_status notify.notification_status;
begin
  if v_uid is null then
    raise exception 'notify: not authenticated' using errcode = '42501';
  end if;
  select recipient_user_id, status into v_recipient, v_status
    from notify.notifications where id = p_notification_id and deleted_at is null;
  if v_recipient is null then
    raise exception 'notify: not found' using errcode = 'P0002';
  end if;
  if v_recipient <> v_uid then
    raise exception 'notify: not your notification' using errcode = '42501';
  end if;
  if v_status = 'unread' then
    update notify.notifications
       set status = 'read', read_at = now(), read_by = v_uid
     where id = p_notification_id;
    perform notify.fn_audit('notify.marked_read', p_notification_id);
  end if;
end;
$$;

-- 8.5 portal_mark_all_read -------------------------------------------------
create or replace function notify.portal_mark_all_read(
  p_category notify.notification_category default null
) returns integer
language plpgsql volatile security definer set search_path = ''
as $$
declare v_uid uuid := auth.uid(); v_count integer;
begin
  if v_uid is null then
    raise exception 'notify: not authenticated' using errcode = '42501';
  end if;
  with updated as (
    update notify.notifications
       set status = 'read', read_at = now(), read_by = v_uid
     where recipient_user_id = v_uid
       and status = 'unread' and deleted_at is null
       and (p_category is null or category = p_category)
     returning 1
  ) select count(*) into v_count from updated;
  return coalesce(v_count, 0);
end;
$$;

-- 8.6 portal_archive_notification ------------------------------------------
create or replace function notify.portal_archive_notification(p_notification_id uuid)
returns void
language plpgsql volatile security definer set search_path = ''
as $$
declare v_uid uuid := auth.uid(); v_recipient uuid;
begin
  if v_uid is null then
    raise exception 'notify: not authenticated' using errcode = '42501';
  end if;
  select recipient_user_id into v_recipient
    from notify.notifications where id = p_notification_id and deleted_at is null;
  if v_recipient is null then
    raise exception 'notify: not found' using errcode = 'P0002';
  end if;
  if v_recipient <> v_uid then
    raise exception 'notify: not your notification' using errcode = '42501';
  end if;
  update notify.notifications
     set status = 'archived', archived_at = now()
   where id = p_notification_id;
  perform notify.fn_audit('notify.archived', p_notification_id);
end;
$$;

-- 8.7 portal_upsert_preferences --------------------------------------------
create or replace function notify.portal_upsert_preferences(
  p_category    notify.notification_category,
  p_channel     notify.channel_type,
  p_enabled     boolean,
  p_organization_id uuid default null,
  p_quiet_hours_start time default null,
  p_quiet_hours_end   time default null
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_tenant uuid;
  v_id uuid;
begin
  if v_uid is null then
    raise exception 'notify: not authenticated' using errcode = '42501';
  end if;
  select primary_organization_id into v_tenant from identity.user_profiles where id = v_uid;
  if v_tenant is null then
    raise exception 'notify: user profile missing' using errcode = 'P0002';
  end if;
  select tenant_id into v_tenant from organization.organizations
   where id = (select primary_organization_id from identity.user_profiles where id = v_uid);

  -- Upsert by (user_id, organization_id, category, channel)
  insert into notify.user_preferences (
    tenant_id, user_id, organization_id, category, channel,
    enabled, quiet_hours_start, quiet_hours_end, updated_by
  ) values (
    v_tenant, v_uid, p_organization_id, p_category, p_channel,
    p_enabled, p_quiet_hours_start, p_quiet_hours_end, v_uid
  )
  on conflict (user_id,
               coalesce(organization_id, '00000000-0000-0000-0000-000000000000'::uuid),
               category, channel) where deleted_at is null
  do update set
    enabled = excluded.enabled,
    quiet_hours_start = excluded.quiet_hours_start,
    quiet_hours_end = excluded.quiet_hours_end,
    updated_by = v_uid
  returning id into v_id;
  return v_id;
end;
$$;

-- ===========================================================================
-- 9. Admin RPCs (4)
-- ===========================================================================

-- 9.1 admin_list_notifications ---------------------------------------------
create or replace function notify.admin_list_notifications(
  p_recipient_user_id uuid default null,
  p_organization_id   uuid default null,
  p_category notify.notification_category default null,
  p_limit integer default 25,
  p_offset integer default 0
) returns table (
  id uuid, recipient_user_id uuid, organization_id uuid,
  category text, status text, title_en text,
  source_event_type text, created_at timestamptz
)
language plpgsql stable security definer set search_path = ''
as $$
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_list_notifications: requires platform_admin' using errcode = '42501';
  end if;
  return query
    select n.id, n.recipient_user_id, n.organization_id,
           n.category::text, n.status::text, n.title_en,
           n.source_event_type, n.created_at
      from notify.notifications n
     where n.deleted_at is null
       and (p_recipient_user_id is null or n.recipient_user_id = p_recipient_user_id)
       and (p_organization_id is null or n.organization_id = p_organization_id)
       and (p_category is null or n.category = p_category)
     order by n.created_at desc
     limit p_limit offset p_offset;
end;
$$;

-- 9.2 admin_upsert_template ------------------------------------------------
create or replace function notify.admin_upsert_template(
  p_template_code     text,
  p_category          notify.notification_category,
  p_title_en          text,
  p_title_fa          text,
  p_body_en           text,
  p_body_fa           text,
  p_action_url_template text default null,
  p_default_priority  notify.notification_priority default 'normal',
  p_default_channels  notify.channel_type[] default array['in_app']::notify.channel_type[],
  p_event_type_filter text default null,
  p_tenant_id         uuid default null,
  p_organization_id   uuid default null
) returns uuid
language plpgsql volatile security definer set search_path = ''
as $$
declare v_actor uuid := auth.uid(); v_id uuid;
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_upsert_template: requires platform_admin' using errcode = '42501';
  end if;
  if p_template_code is null or btrim(p_template_code) = '' then
    raise exception 'notify: template_code required' using errcode = '22023';
  end if;

  insert into notify.notification_templates (
    tenant_id, organization_id, template_code, category,
    default_priority, default_channels, status,
    title_en, title_fa, body_en, body_fa,
    action_url_template, event_type_filter,
    created_by, updated_by
  ) values (
    p_tenant_id, p_organization_id, p_template_code, p_category,
    p_default_priority, p_default_channels, 'active',
    p_title_en, p_title_fa, p_body_en, p_body_fa,
    p_action_url_template, p_event_type_filter,
    v_actor, v_actor
  )
  on conflict (coalesce(tenant_id, '00000000-0000-0000-0000-000000000000'::uuid),
               lower(template_code)) where deleted_at is null
  do update set
    category = excluded.category,
    default_priority = excluded.default_priority,
    default_channels = excluded.default_channels,
    title_en = excluded.title_en, title_fa = excluded.title_fa,
    body_en = excluded.body_en, body_fa = excluded.body_fa,
    action_url_template = excluded.action_url_template,
    event_type_filter = excluded.event_type_filter,
    updated_by = v_actor
  returning id into v_id;
  return v_id;
end;
$$;

-- 9.3 admin_list_templates -------------------------------------------------
create or replace function notify.admin_list_templates(
  p_category notify.notification_category default null,
  p_status   notify.template_status default null
) returns table (
  id uuid, template_code text, organization_id uuid,
  category text, default_priority text, status text, title_en text
)
language plpgsql stable security definer set search_path = ''
as $$
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_list_templates: requires platform_admin' using errcode = '42501';
  end if;
  return query
    select t.id, t.template_code, t.organization_id,
           t.category::text, t.default_priority::text, t.status::text, t.title_en
      from notify.notification_templates t
     where t.deleted_at is null
       and (p_category is null or t.category = p_category)
       and (p_status is null or t.status = p_status)
     order by t.template_code;
end;
$$;

-- 9.4 admin_list_delivery_attempts -----------------------------------------
create or replace function notify.admin_list_delivery_attempts(
  p_notification_id uuid default null,
  p_channel notify.channel_type default null,
  p_status  notify.delivery_status default null,
  p_limit integer default 25,
  p_offset integer default 0
) returns table (
  id uuid, notification_id uuid, channel text, status text,
  attempted_at timestamptz, delivered_at timestamptz,
  failure_reason text, created_at timestamptz
)
language plpgsql stable security definer set search_path = ''
as $$
begin
  if not identity.is_platform_admin() then
    raise exception 'admin_list_delivery_attempts: requires platform_admin' using errcode = '42501';
  end if;
  return query
    select da.id, da.notification_id, da.channel::text, da.status::text,
           da.attempted_at, da.delivered_at, da.failure_reason, da.created_at
      from notify.delivery_attempts da
     where (p_notification_id is null or da.notification_id = p_notification_id)
       and (p_channel is null or da.channel = p_channel)
       and (p_status is null or da.status = p_status)
     order by da.created_at desc
     limit p_limit offset p_offset;
end;
$$;

-- ===========================================================================
-- 10. Trigger attachments (set_updated_at + audit) for OUR mutable tables
-- ===========================================================================
-- Note: notify.notifications is intentionally NOT in this list — that table
-- carries explicit per-state timestamps (read_at / archived_at / dismissed_at)
-- and has no generic updated_at column.
do $$
declare r record;
begin
  for r in
    select unnest(array['notification_templates','user_preferences']) as table_name
  loop
    execute format(
      'drop trigger if exists trg_set_updated_at on notify.%I',
      r.table_name
    );
    execute format(
      'create trigger trg_set_updated_at before update on notify.%I '
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
      'notification_templates','user_preferences','notifications',
      'delivery_attempts','materialization_audit'
    ]) as table_name
  loop
    execute format(
      'drop trigger if exists trg_audit_entity on notify.%I',
      r.table_name
    );
    execute format(
      'create trigger trg_audit_entity after insert or update or delete on notify.%I '
      'for each row execute function audit.fn_audit_entity()',
      r.table_name
    );
  end loop;
end;
$$;

-- ===========================================================================
-- 11. Grants (SELECT only; no INSERT/UPDATE/DELETE)
-- ===========================================================================
grant select on notify.notification_templates  to authenticated;
grant select on notify.user_preferences        to authenticated;
grant select on notify.notifications           to authenticated;
grant select on notify.delivery_attempts       to authenticated;
-- materialization_audit: no direct SELECT grant; only admin_list_* RPCs.

-- ===========================================================================
-- 12. RPC EXECUTE grants
-- ===========================================================================
grant execute on function notify.portal_list_my_notifications(notify.notification_status, notify.notification_category, integer, integer) to authenticated;
grant execute on function notify.portal_get_notification(uuid) to authenticated;
grant execute on function notify.portal_unread_count(notify.notification_category) to authenticated;
grant execute on function notify.portal_mark_read(uuid) to authenticated;
grant execute on function notify.portal_mark_all_read(notify.notification_category) to authenticated;
grant execute on function notify.portal_archive_notification(uuid) to authenticated;
grant execute on function notify.portal_upsert_preferences(notify.notification_category, notify.channel_type, boolean, uuid, time, time) to authenticated;

grant execute on function notify.admin_list_notifications(uuid, uuid, notify.notification_category, integer, integer) to authenticated;
grant execute on function notify.admin_upsert_template(text, notify.notification_category, text, text, text, text, text, notify.notification_priority, notify.channel_type[], text, uuid, uuid) to authenticated;
grant execute on function notify.admin_list_templates(notify.notification_category, notify.template_status) to authenticated;
grant execute on function notify.admin_list_delivery_attempts(uuid, notify.channel_type, notify.delivery_status, integer, integer) to authenticated;

-- ===========================================================================
-- 13. Q4: platform-level seed templates (tenant_id IS NULL = platform-scoped)
-- ===========================================================================
insert into notify.notification_templates (
  template_code, category, default_priority, default_channels,
  title_en, title_fa, body_en, body_fa, action_url_template
) values
  -- Contract execution / signature
  ('executed_contract.draft_execution', 'contract', 'normal', array['in_app']::notify.channel_type[],
   'Executed contract created', 'قرارداد اجرایی ایجاد شد',
   'A new executable contract was created from your preparation.',
   'یک قرارداد قابل اجرا از آماده‌سازی شما ایجاد شد.',
   '/contracts/${entity_id}'),
  ('executed_contract.pending_signatures', 'contract', 'high', array['in_app']::notify.channel_type[],
   'Contract awaiting signatures', 'قرارداد در انتظار امضا',
   'A contract is awaiting signatures.', 'یک قرارداد در انتظار امضا است.',
   '/contracts/${entity_id}'),
  ('executed_contract.executed', 'contract', 'high', array['in_app']::notify.channel_type[],
   'Contract executed', 'قرارداد اجرا شد',
   'All required signatures collected. Contract is now executed.',
   'تمامی امضاهای لازم جمع‌آوری شد. قرارداد اکنون اجرا شده است.',
   '/contracts/${entity_id}'),
  ('signature.requested', 'contract', 'high', array['in_app']::notify.channel_type[],
   'Signature required', 'امضا مورد نیاز است',
   'You have a pending signature request on a contract.',
   'شما یک درخواست امضای معلق روی قرارداد دارید.',
   '/signatures/${entity_id}'),
  ('signature.signed', 'contract', 'normal', array['in_app']::notify.channel_type[],
   'Signature recorded', 'امضا ثبت شد',
   'A signature was recorded on a contract.',
   'یک امضا روی قرارداد ثبت شد.',
   '/contracts/${entity_id}'),

  -- Shipment lifecycle (CC-14)
  ('shipment.marked_planned', 'shipment', 'normal', array['in_app']::notify.channel_type[],
   'Shipment planned', 'محموله برنامه‌ریزی شد',
   'A shipment moved to planned.', 'یک محموله به وضعیت برنامه‌ریزی شده منتقل شد.',
   '/shipments/${entity_id}'),
  ('shipment.marked_booked', 'shipment', 'normal', array['in_app']::notify.channel_type[],
   'Shipment booked', 'محموله رزرو شد',
   'A shipment was booked with a carrier.', 'یک محموله با حمل‌کننده رزرو شد.',
   '/shipments/${entity_id}'),
  ('shipment.marked_in_transit', 'shipment', 'high', array['in_app']::notify.channel_type[],
   'Shipment in transit', 'محموله در حال حمل',
   'A shipment is now in transit.', 'یک محموله اکنون در حال حمل است.',
   '/shipments/${entity_id}'),
  ('shipment.marked_delivered', 'shipment', 'high', array['in_app']::notify.channel_type[],
   'Shipment delivered', 'محموله تحویل داده شد',
   'A shipment was delivered.', 'یک محموله تحویل داده شد.',
   '/shipments/${entity_id}'),

  -- Finance (CC-16)
  ('invoice.issued', 'finance', 'normal', array['in_app']::notify.channel_type[],
   'Invoice issued', 'فاکتور صادر شد',
   'An invoice was issued.', 'یک فاکتور صادر شد.', '/invoices/${entity_id}'),
  ('invoice.sent', 'finance', 'normal', array['in_app']::notify.channel_type[],
   'Invoice sent', 'فاکتور ارسال شد',
   'An invoice was sent.', 'یک فاکتور ارسال شد.', '/invoices/${entity_id}'),
  ('invoice.paid', 'finance', 'high', array['in_app']::notify.channel_type[],
   'Invoice paid', 'فاکتور پرداخت شد',
   'An invoice was fully paid.', 'یک فاکتور به طور کامل پرداخت شد.', '/invoices/${entity_id}'),
  ('invoice.partial', 'finance', 'normal', array['in_app']::notify.channel_type[],
   'Invoice partially paid', 'فاکتور تا حدی پرداخت شد',
   'A partial payment was recorded.', 'یک پرداخت جزئی ثبت شد.', '/invoices/${entity_id}'),
  ('invoice.overdue', 'finance', 'urgent', array['in_app']::notify.channel_type[],
   'Invoice overdue', 'فاکتور موعدش گذشته',
   'An invoice is overdue.', 'موعد یک فاکتور گذشته است.', '/invoices/${entity_id}'),

  -- Settlement (CC-17)
  ('settlement.marked_ready', 'settlement', 'normal', array['in_app']::notify.channel_type[],
   'Settlement ready', 'تسویه آماده است',
   'A settlement is ready for hold.', 'یک تسویه آماده نگهداری است.', '/settlements/${entity_id}'),
  ('settlement.settlement_held', 'settlement', 'high', array['in_app']::notify.channel_type[],
   'Settlement held in escrow', 'تسویه در اسکرو نگهداری شد',
   'Funds were held in the escrow account.', 'وجوه در حساب اسکرو نگهداری شد.', '/settlements/${entity_id}'),
  ('settlement.settlement_released', 'settlement', 'high', array['in_app']::notify.channel_type[],
   'Settlement released', 'تسویه آزاد شد',
   'A settlement was released.', 'یک تسویه آزاد شد.', '/settlements/${entity_id}'),
  ('settlement.supplier_reconciled', 'settlement', 'normal', array['in_app']::notify.channel_type[],
   'Settlement reconciled', 'تسویه تطبیق داده شد',
   'Supplier reconciled the settlement.', 'تأمین‌کننده تسویه را تطبیق داد.', '/settlements/${entity_id}'),

  -- Dispute (CC-18)
  ('dispute.opened', 'dispute', 'urgent', array['in_app']::notify.channel_type[],
   'Dispute opened', 'اختلاف باز شد',
   'A dispute case was opened.', 'یک پرونده اختلاف باز شد.', '/disputes/${entity_id}'),
  ('dispute.review_started', 'dispute', 'high', array['in_app']::notify.channel_type[],
   'Dispute under review', 'اختلاف در حال بررسی',
   'A mediator started review on a dispute.', 'یک میانجی بررسی اختلاف را آغاز کرد.', '/disputes/${entity_id}'),
  ('dispute.decision_recorded', 'dispute', 'urgent', array['in_app']::notify.channel_type[],
   'Dispute decided', 'اختلاف تصمیم‌گیری شد',
   'A mediator recorded a decision on a dispute.', 'یک میانجی تصمیمی روی اختلاف ثبت کرد.', '/disputes/${entity_id}'),
  ('dispute.evidence_submitted', 'dispute', 'normal', array['in_app']::notify.channel_type[],
   'Evidence submitted', 'مدرک ثبت شد',
   'New evidence was submitted on a dispute.', 'مدرک جدیدی روی اختلاف ثبت شد.', '/disputes/${entity_id}');

-- Category-level fallbacks (event_type_filter = NULL).
insert into notify.notification_templates (
  template_code, category, event_type_filter, default_priority, default_channels,
  title_en, title_fa, body_en, body_fa, action_url_template
) values
  ('contract.fallback', 'contract', null, 'normal', array['in_app']::notify.channel_type[],
   'Contract update', 'به‌روزرسانی قرارداد',
   'There is an update on a contract.', 'به‌روزرسانی روی قرارداد وجود دارد.',
   '/contracts/${entity_id}'),
  ('shipment.fallback', 'shipment', null, 'normal', array['in_app']::notify.channel_type[],
   'Shipment update', 'به‌روزرسانی محموله',
   'There is an update on a shipment.', 'به‌روزرسانی روی محموله وجود دارد.',
   '/shipments/${entity_id}'),
  ('finance.fallback', 'finance', null, 'normal', array['in_app']::notify.channel_type[],
   'Finance update', 'به‌روزرسانی مالی',
   'There is a finance update.', 'به‌روزرسانی مالی وجود دارد.',
   '/finance/${entity_id}'),
  ('settlement.fallback', 'settlement', null, 'normal', array['in_app']::notify.channel_type[],
   'Settlement update', 'به‌روزرسانی تسویه',
   'There is an update on a settlement.', 'به‌روزرسانی روی تسویه وجود دارد.',
   '/settlements/${entity_id}'),
  ('dispute.fallback', 'dispute', null, 'high', array['in_app']::notify.channel_type[],
   'Dispute update', 'به‌روزرسانی اختلاف',
   'There is an update on a dispute.', 'به‌روزرسانی روی اختلاف وجود دارد.',
   '/disputes/${entity_id}'),
  ('rfq.fallback', 'rfq', null, 'normal', array['in_app']::notify.channel_type[],
   'RFQ update', 'به‌روزرسانی استعلام',
   'There is an update on an RFQ.', 'به‌روزرسانی روی استعلام وجود دارد.',
   '/rfqs/${entity_id}'),
  ('offer.fallback', 'offer', null, 'normal', array['in_app']::notify.channel_type[],
   'Offer update', 'به‌روزرسانی پیشنهاد',
   'There is an update on an offer.', 'به‌روزرسانی روی پیشنهاد وجود دارد.',
   '/offers/${entity_id}'),
  ('evaluation.fallback', 'evaluation', null, 'normal', array['in_app']::notify.channel_type[],
   'Evaluation update', 'به‌روزرسانی ارزیابی',
   'There is an update on an evaluation decision.', 'به‌روزرسانی روی تصمیم ارزیابی وجود دارد.',
   '/evaluations/${entity_id}');
