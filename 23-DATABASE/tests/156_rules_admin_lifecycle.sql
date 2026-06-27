-- CC-67 Test 156 — admin rule lifecycle
--
-- Assertions (10):
--   1.  admin_create_rule_set returns a uuid
--   2.  new rule_set has status='draft'
--   3.  admin_create_rule returns a uuid
--   4.  admin_activate_rule_set flips rule_set to active
--   5.  admin_activate_rule flips rule to active
--   6.  admin_archive_rule flips rule to archived
--   7.  archived rule has archived_at set
--   8.  rule_events has rule_set.created event
--   9.  rule_events has rule.created event
--  10.  non-admin admin_create_rule_set raises (denied)

set search_path = extensions, public, identity, organization, audit, supplier,
                  commodity, rfq, offer, evaluation, contract, shipment, notify,
                  marketplace, dispatch, telematics, execution, workflow, rules, tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '55000000-0000-0000-0000-000000000156', 'authenticated','authenticated','156-admin@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '55000000-0000-0000-0000-000000000256', 'authenticated','authenticated','156-non-admin@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('55000000-0000-0000-0000-000000000156', 'tenant-156', 'تست', 'Test 156');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status, country_code) values
  ('55000000-0000-0000-0000-000000000a56', '55000000-0000-0000-0000-000000000156',
   'buy-156', 'خریدار', 'Buyer 156', 'buyer', 'active', 'IR');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('55000000-0000-0000-0000-000000000156', '55000000-0000-0000-0000-000000000156',
   '55000000-0000-0000-0000-000000000a56', 'Admin 156', 'fa', 'active'),
  ('55000000-0000-0000-0000-000000000256', '55000000-0000-0000-0000-000000000156',
   '55000000-0000-0000-0000-000000000a56', 'NonAdmin 156', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '55000000-0000-0000-0000-000000000156', '55000000-0000-0000-0000-000000000a56',
       '55000000-0000-0000-0000-000000000256', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '55000000-0000-0000-0000-000000000156', r.id, 'platform', null
  from identity.roles r where r.code = 'platform_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '55000000-0000-0000-0000-000000000256', r.id, 'organization',
       '55000000-0000-0000-0000-000000000a56'
  from identity.roles r where r.code = 'buyer_admin';

do $$
declare v_rs uuid; v_r uuid;
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','55000000-0000-0000-0000-000000000156',
                       'role','authenticated',
                       'tenant_id','55000000-0000-0000-0000-000000000156')::text, true);
  perform set_config('request.jwt.claim.sub',
                     '55000000-0000-0000-0000-000000000156', true);
  set local role authenticated;

  v_rs := rules.admin_create_rule_set('RS-156', 'Set 156', 'desc', 'shipment', 100, '{}'::jsonb);
  perform set_config('test.rs_156', v_rs::text, true);

  v_r := rules.admin_create_rule(v_rs, 'R-156-1', 'Rule 156-1', null,
    'shipment', 'requirement', 100,
    jsonb_build_object('all', jsonb_build_array(
      jsonb_build_object('path','shipment.transport_mode','op','eq','value','road')
    )),
    '{}'::jsonb, '{}'::jsonb);
  perform set_config('test.r_156', v_r::text, true);

  perform rules.admin_activate_rule_set(v_rs);
  perform rules.admin_activate_rule(v_r);
  perform rules.admin_archive_rule(v_r);

  reset role;
end $$;

select plan(10);

-- 1
select isnt(
  (select current_setting('test.rs_156', true)), '',
  'admin_create_rule_set returns a uuid');

-- 2: a separate draft set to inspect the default status (the first one is
-- already active by now).
do $$
declare v_status text;
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','55000000-0000-0000-0000-000000000156',
                       'role','authenticated',
                       'tenant_id','55000000-0000-0000-0000-000000000156')::text, true);
  perform set_config('request.jwt.claim.sub',
                     '55000000-0000-0000-0000-000000000156', true);
  set local role authenticated;
  perform rules.admin_create_rule_set('RS-156-D', 'Draft', null, 'shipment', 100, '{}'::jsonb);
  select status::text into v_status
    from rules.rule_sets where rule_set_code = 'RS-156-D';
  reset role;
  perform set_config('test.rs_draft_status', v_status, true);
end $$;
select is(
  (select current_setting('test.rs_draft_status', true)),
  'draft', 'new rule_set has status draft');

-- 3
select isnt(
  (select current_setting('test.r_156', true)), '',
  'admin_create_rule returns a uuid');

-- 4
select is(
  (select status::text from rules.rule_sets
    where id = current_setting('test.rs_156')::uuid),
  'active', 'admin_activate_rule_set flips rule_set to active');

-- 5+6: the rule was activated then archived in the same fixture; the
-- terminal status check verifies the archive path.
select is(
  (select status::text from rules.rules
    where id = current_setting('test.r_156')::uuid),
  'archived', 'admin_archive_rule flips rule to archived (after activate)');

-- We also want a positive activation check.  Activate again should pull
-- archived_at back to null and status to active.
do $$
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','55000000-0000-0000-0000-000000000156',
                       'role','authenticated')::text, true);
  perform set_config('request.jwt.claim.sub',
                     '55000000-0000-0000-0000-000000000156', true);
  set local role authenticated;
  perform rules.admin_activate_rule(current_setting('test.r_156')::uuid);
  reset role;
end $$;
select is(
  (select status::text from rules.rules
    where id = current_setting('test.r_156')::uuid),
  'active', 'admin_activate_rule flips rule to active');

-- 7: archive again
do $$
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','55000000-0000-0000-0000-000000000156',
                       'role','authenticated')::text, true);
  perform set_config('request.jwt.claim.sub',
                     '55000000-0000-0000-0000-000000000156', true);
  set local role authenticated;
  perform rules.admin_archive_rule(current_setting('test.r_156')::uuid);
  reset role;
end $$;
select isnt(
  (select archived_at::text from rules.rules
    where id = current_setting('test.r_156')::uuid),
  null, 'archived rule has archived_at set');

-- 8
select cmp_ok(
  (select count(*)::int from rules.rule_events
    where rule_set_id = current_setting('test.rs_156')::uuid
      and event_type = 'rule_set.created'),
  '>=', 1, 'rule_events has rule_set.created event');

-- 9
select cmp_ok(
  (select count(*)::int from rules.rule_events
    where rule_id = current_setting('test.r_156')::uuid
      and event_type = 'rule.created'),
  '>=', 1, 'rule_events has rule.created event');

-- 10: non-admin denied
do $$
declare v_err text := '';
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','55000000-0000-0000-0000-000000000256',
                       'role','authenticated',
                       'tenant_id','55000000-0000-0000-0000-000000000156')::text, true);
  perform set_config('request.jwt.claim.sub',
                     '55000000-0000-0000-0000-000000000256', true);
  set local role authenticated;
  begin
    perform rules.admin_create_rule_set('RS-156-X', 'X', null, 'shipment', 100, '{}'::jsonb);
  exception when others then
    v_err := SQLERRM;
  end;
  reset role;
  perform set_config('test.non_admin_err', v_err, true);
end $$;
select isnt(
  (select current_setting('test.non_admin_err', true)),
  '', 'non-admin admin_create_rule_set raises (denied)');

select * from finish();
rollback;
