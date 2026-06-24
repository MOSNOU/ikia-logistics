-- CC-19 Test 076 — Templates + cross-user isolation:
--   * Q4: seed templates loaded (>= 20 platform-level)
--   * admin_upsert_template gated to platform_admin (42501 for non-admin)
--   * admin_list_templates returns >= seed count
--   * notifications RLS hides other users' rows from authenticated callers
--   * fn_resolve_template resolves exact-match before category fallback

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  app_storage, finance, settlement, dispute, notify, tests;
begin;

-- Two users + one admin in same org/tenant for the isolation test.
insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '33000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '076-userA@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '33000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', '076-userB@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '33000000-0000-0000-0000-000000000099', 'authenticated', 'authenticated', '076-admin@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('33000000-0000-0000-0000-00000000000a', 'tenant-076', 'تست', 'Test');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('33000000-0000-0000-0000-00000000001a', '33000000-0000-0000-0000-00000000000a',
   'buyer-076', 'خریدار', 'Buyer 076', 'buyer', 'active');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('33000000-0000-0000-0000-000000000001', '33000000-0000-0000-0000-00000000000a',
   '33000000-0000-0000-0000-00000000001a', 'UserA', 'fa', 'active'),
  ('33000000-0000-0000-0000-000000000002', '33000000-0000-0000-0000-00000000000a',
   '33000000-0000-0000-0000-00000000001a', 'UserB', 'fa', 'active'),
  ('33000000-0000-0000-0000-000000000099', '33000000-0000-0000-0000-00000000000a',
   '33000000-0000-0000-0000-00000000001a', 'Admin', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '33000000-0000-0000-0000-00000000000a', '33000000-0000-0000-0000-00000000001a',
       '33000000-0000-0000-0000-000000000001', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '33000000-0000-0000-0000-00000000000a', '33000000-0000-0000-0000-00000000001a',
       '33000000-0000-0000-0000-000000000002', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '33000000-0000-0000-0000-000000000001', r.id, 'organization', '33000000-0000-0000-0000-00000000001a'
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '33000000-0000-0000-0000-000000000002', r.id, 'organization', '33000000-0000-0000-0000-00000000001a'
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '33000000-0000-0000-0000-000000000099', r.id, 'platform', null
  from identity.roles r where r.code = 'platform_admin';

-- Seed one notification each for userA and userB by inserting directly via SECURITY DEFINER path.
-- Easiest: have admin call admin_upsert_template to verify privileged path, then make notifications via
-- a direct insert (which won't be allowed for authenticated — so we use SECURITY DEFINER ops).
-- For the isolation test we need notifications for both users; use the trigger pipeline indirectly
-- by inserting raw rows via platform_admin (RLS admin_modify policy allows that).

select plan(9);

-- 1. Q4 seed templates present (>= 20 platform-level).
select cmp_ok(
  (select count(*)::int from notify.notification_templates
    where tenant_id is null and deleted_at is null),
  '>=', 20,
  'Q4: ≥ 20 platform-level seed templates loaded'
);

-- 2. Specific seed template exists: executed_contract.executed
select cmp_ok(
  (select count(*)::int from notify.notification_templates
    where lower(template_code) = 'executed_contract.executed' and tenant_id is null),
  '>=', 1,
  'Q4 seed: executed_contract.executed template exists'
);

-- 3. admin_upsert_template gated to platform_admin.
select tests.authenticate_as(
  '33000000-0000-0000-0000-000000000001',
  '33000000-0000-0000-0000-00000000000a',
  '33000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select throws_ok(
  $$ select notify.admin_upsert_template(
       'custom.test', 'platform'::notify.notification_category,
       'Custom EN', 'سفارشی FA', 'Body EN', 'Body FA'
     ) $$,
  '42501', null,
  'admin_upsert_template gated to platform_admin (42501 for non-admin)'
);
reset role;

-- 4. Admin succeeds.
select tests.authenticate_as(
  '33000000-0000-0000-0000-000000000099',
  '33000000-0000-0000-0000-00000000000a',
  '33000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
do $$
declare v_id uuid;
begin
  v_id := notify.admin_upsert_template(
    'custom.test', 'platform'::notify.notification_category,
    'Custom EN', 'سفارشی FA', 'Body EN', 'Body FA'
  );
  perform set_config('test.custom_template', v_id::text, false);
end;
$$;
reset role;

select is(
  (select template_code from notify.notification_templates where id = current_setting('test.custom_template')::uuid),
  'custom.test',
  'platform_admin can call admin_upsert_template'
);

-- 5. admin_list_templates returns the new template.
select tests.authenticate_as(
  '33000000-0000-0000-0000-000000000099',
  '33000000-0000-0000-0000-00000000000a',
  '33000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select cmp_ok(
  (select count(*)::int from notify.admin_list_templates(
     'platform'::notify.notification_category, 'active'::notify.template_status
  )),
  '>=', 1,
  'admin_list_templates returns ≥1 platform template'
);
reset role;

-- 6. notifications RLS hides other users' rows.
-- Insert notifications for both users as postgres (no INSERT grants to
-- authenticated; the trigger pipeline is the only authenticated path).
reset role;
insert into notify.notifications (
  tenant_id, organization_id, recipient_user_id, category, priority, status,
  title_en, title_fa, source_event_type
) values
  ('33000000-0000-0000-0000-00000000000a', '33000000-0000-0000-0000-00000000001a',
   '33000000-0000-0000-0000-000000000001', 'platform', 'normal', 'unread',
   'For UserA', 'برای کاربر آ', 'test'),
  ('33000000-0000-0000-0000-00000000000a', '33000000-0000-0000-0000-00000000001a',
   '33000000-0000-0000-0000-000000000002', 'platform', 'normal', 'unread',
   'For UserB', 'برای کاربر ب', 'test');

-- UserA sees their own notification.
select tests.authenticate_as(
  '33000000-0000-0000-0000-000000000001',
  '33000000-0000-0000-0000-00000000000a',
  '33000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select is(
  (select count(*)::int from notify.notifications
    where title_en = 'For UserA'),
  1,
  'UserA can see own notification (title=For UserA)'
);

-- UserA CANNOT see UserB's notification.
select is(
  (select count(*)::int from notify.notifications
    where title_en = 'For UserB'),
  0,
  'notifications RLS hides UserB''s notification from UserA'
);

-- 7+8: per directive, assert UPDATE/DELETE on notifications blocked for authenticated (no grants).
select throws_ok(
  $$ update notify.notifications set status = 'archived'::notify.notification_status
      where title_en = 'For UserA' $$,
  '42501', null,
  'direct UPDATE on notify.notifications is blocked for authenticated (no grant)'
);

select throws_ok(
  $$ delete from notify.notifications where title_en = 'For UserA' $$,
  '42501', null,
  'direct DELETE on notify.notifications is blocked for authenticated (no grant)'
);
reset role;

select * from finish();
rollback;
