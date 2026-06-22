-- CC-03 / Migration 0007
-- Generic audit trigger and trigger attachment loops.
-- Attaches set_updated_at on every identity + organization table that has updated_at.
-- Attaches the audit entity trigger on every identity + organization base table
-- except identity.permissions (pure lookup, low audit value).

create or replace function audit.fn_audit_entity()
  returns trigger
  language plpgsql
  security definer
  set search_path = ''
as $$
declare
  v_action    audit.audit_action;
  v_before    jsonb;
  v_after     jsonb;
  v_id        uuid;
  v_tenant    uuid;
  v_org       uuid;
  v_changed   text[];
begin
  if tg_op = 'INSERT' then
    v_action := 'insert';
    v_before := null;
    v_after  := to_jsonb(new);
    v_id     := (v_after ->> 'id')::uuid;
  elsif tg_op = 'UPDATE' then
    v_action := 'update';
    v_before := to_jsonb(old);
    v_after  := to_jsonb(new);
    v_id     := (v_after ->> 'id')::uuid;
    select array_agg(key)
      into v_changed
      from jsonb_each(v_after) as t(key, value)
     where v_before -> key is distinct from value;
  else
    v_action := 'delete';
    v_before := to_jsonb(old);
    v_after  := null;
    v_id     := (v_before ->> 'id')::uuid;
  end if;

  v_tenant := coalesce(
    nullif(v_after  ->> 'tenant_id', '')::uuid,
    nullif(v_before ->> 'tenant_id', '')::uuid
  );
  v_org := coalesce(
    nullif(v_after  ->> 'organization_id', '')::uuid,
    nullif(v_before ->> 'organization_id', '')::uuid
  );

  insert into audit.audit_entity (
    tenant_id, organization_id, entity_schema, entity_table, entity_id,
    action, changed_columns, before_state, after_state, actor_user_id, changed_at
  ) values (
    v_tenant, v_org, tg_table_schema, tg_table_name, v_id,
    v_action, v_changed, v_before, v_after, identity.current_user_id(), now()
  );

  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

comment on function audit.fn_audit_entity() is
  'Generic AFTER trigger. Writes to audit.audit_entity. Skips tables without an id column at trigger creation time.';

-- Attach set_updated_at on every identity + organization table that has updated_at.
do $$
declare
  r record;
begin
  for r in
    select c.table_schema, c.table_name
      from information_schema.columns c
      join information_schema.tables t
        on t.table_schema = c.table_schema and t.table_name = c.table_name
     where c.table_schema in ('identity', 'organization')
       and c.column_name  = 'updated_at'
       and t.table_type   = 'BASE TABLE'
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

-- Attach audit trigger on every identity + organization base table that has an id column,
-- except identity.permissions (pure lookup).
do $$
declare
  r record;
begin
  for r in
    select t.table_schema, t.table_name
      from information_schema.tables t
     where t.table_schema in ('identity', 'organization')
       and t.table_type = 'BASE TABLE'
       and not (t.table_schema = 'identity' and t.table_name = 'permissions')
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
