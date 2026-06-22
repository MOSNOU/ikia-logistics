-- CC-03 / Dev Seed — NOT for production
-- Idempotent. Inserts one dev tenant and one platform-type organization,
-- then promotes the earliest auth.users row to platform_admin.
--
-- Apply after migrations:
--   psql ... -f 23-DATABASE/seeds/dev_tenant_org.sql
--
-- Or from Supabase CLI:
--   supabase db reset --linked   (applies migrations, NOT seeds)
--   psql "$DATABASE_URL" -f 23-DATABASE/seeds/dev_tenant_org.sql

insert into identity.tenants (id, code, name_fa, name_en, country_code, status)
values (
  '00000000-0000-0000-0000-000000000001',
  'ikia-dev',
  'تننت توسعه',
  'Dev Tenant',
  'IR',
  'active'
)
on conflict (code) do nothing;

insert into organization.organizations (
  id, tenant_id, code, name_fa, name_en, type, status
) values (
  '00000000-0000-0000-0000-000000000002',
  '00000000-0000-0000-0000-000000000001',
  'ikia-platform',
  'سازمان پلتفرم',
  'Platform Org',
  'platform',
  'active'
)
on conflict (tenant_id, code) do nothing;

do $$
declare
  v_user_id   uuid;
  v_role_id   uuid;
  v_tenant_id constant uuid := '00000000-0000-0000-0000-000000000001';
  v_org_id    constant uuid := '00000000-0000-0000-0000-000000000002';
begin
  select id into v_user_id from auth.users order by created_at limit 1;

  if v_user_id is null then
    raise notice
      'No auth.users present. Create a user via Supabase Studio (or signup), then re-run this seed.';
    return;
  end if;

  insert into identity.user_profiles (
    id, tenant_id, primary_organization_id, full_name, locale, status
  ) values (
    v_user_id, v_tenant_id, v_org_id, 'Dev Admin', 'fa', 'active'
  )
  on conflict (id) do update set
    tenant_id               = excluded.tenant_id,
    primary_organization_id = excluded.primary_organization_id;

  select id into v_role_id from identity.roles where code = 'platform_admin';

  if not exists (
    select 1 from identity.user_roles
     where user_id = v_user_id
       and role_id = v_role_id
       and scope_type = 'platform'
       and revoked_at is null
       and deleted_at is null
  ) then
    insert into identity.user_roles (user_id, role_id, scope_type, granted_at)
    values (v_user_id, v_role_id, 'platform', now());
  end if;

  if not exists (
    select 1 from organization.memberships
     where organization_id = v_org_id
       and user_id = v_user_id
       and role_id = v_role_id
  ) then
    insert into organization.memberships (
      tenant_id, organization_id, user_id, role_id, status, joined_at
    ) values (
      v_tenant_id, v_org_id, v_user_id, v_role_id, 'active', now()
    );
  end if;

  raise notice 'Dev seed wired user % as platform_admin in tenant %', v_user_id, v_tenant_id;
end;
$$;
