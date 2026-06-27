-- CC-66 Test 148 — admin workflow template lifecycle
--
-- Assertions (10):
--   1.  admin_create_template returns a uuid
--   2.  new template has status='draft'
--   3.  admin_add_step adds a step
--   4.  admin_activate_template flips status to active
--   5.  admin_get_template returns steps in json
--   6.  admin_list_templates lists at least the new template
--   7.  activating a template with zero steps raises
--   8.  admin_archive_template flips status to archived
--   9.  archived template has archived_at set
--  10.  non-admin admin_create_template raises (denied)

set search_path = extensions, public, identity, organization, audit, supplier,
                  commodity, rfq, offer, evaluation, contract, shipment, notify,
                  marketplace, dispatch, telematics, execution, workflow, tests;
begin;

-- ---------------------------------------------------------------------------
-- Fixture
-- ---------------------------------------------------------------------------
insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '54000000-0000-0000-0000-000000000148', 'authenticated', 'authenticated',
   '148-admin@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '54000000-0000-0000-0000-000000000248', 'authenticated', 'authenticated',
   '148-non-admin@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('54000000-0000-0000-0000-00000000014a', 'tenant-148', 'تست', 'Test 148');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status, country_code) values
  ('54000000-0000-0000-0000-00000000014b', '54000000-0000-0000-0000-00000000014a',
   'buy-148', 'خریدار', 'Buyer 148', 'buyer', 'active', 'IR');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('54000000-0000-0000-0000-000000000148', '54000000-0000-0000-0000-00000000014a',
   '54000000-0000-0000-0000-00000000014b', 'Admin 148', 'fa', 'active'),
  ('54000000-0000-0000-0000-000000000248', '54000000-0000-0000-0000-00000000014a',
   '54000000-0000-0000-0000-00000000014b', 'NonAdmin 148', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '54000000-0000-0000-0000-00000000014a', '54000000-0000-0000-0000-00000000014b',
       '54000000-0000-0000-0000-000000000248', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '54000000-0000-0000-0000-000000000148', r.id, 'platform', null
  from identity.roles r where r.code = 'platform_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '54000000-0000-0000-0000-000000000248', r.id, 'organization',
       '54000000-0000-0000-0000-00000000014b'
  from identity.roles r where r.code = 'buyer_admin';

-- ---------------------------------------------------------------------------
-- Drive the happy path as admin.
-- ---------------------------------------------------------------------------
do $$
declare v_tpl uuid; v_step uuid; v_empty uuid;
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','54000000-0000-0000-0000-000000000148',
                       'role','authenticated',
                       'tenant_id','54000000-0000-0000-0000-00000000014a')::text, true);
  perform set_config('request.jwt.claim.sub',
                     '54000000-0000-0000-0000-000000000148', true);
  set local role authenticated;

  v_tpl := workflow.admin_create_template(
    'TPL-148',  'Standard Shipment Workflow',
    'Test template for CC-66 148',  'shipment', 'shipment',
    jsonb_build_object('source','test-148'));
  perform set_config('test.tpl_148', v_tpl::text, true);

  v_step := workflow.admin_add_step(
    v_tpl, 'STEP-1', 'Prepare paperwork', 'Docs ready before pickup',
    'task', 100, 'buyer', null, 'normal', 24,
    '{}'::jsonb, jsonb_build_object('order',1));
  perform set_config('test.step_148', v_step::text, true);

  perform workflow.admin_activate_template(v_tpl);

  -- A second, empty template to test the "activate empty" failure path.
  v_empty := workflow.admin_create_template(
    'TPL-148-EMPTY', 'Empty', null, 'shipment', 'shipment', '{}'::jsonb);
  perform set_config('test.tpl_148_empty', v_empty::text, true);

  reset role;
end $$;

select plan(10);

-- 1
select isnt(
  (select current_setting('test.tpl_148', true)),
  '', 'admin_create_template returns a uuid');

-- 2
do $$
declare v_status workflow.workflow_template_status;
begin
  -- We need to inspect the row after create.  The template starts as
  -- draft.  However we already activated it after step add.  Instead we
  -- check the empty template (which is still draft) for the assertion.
  select status into v_status
    from workflow.workflow_templates
   where id = current_setting('test.tpl_148_empty')::uuid;
  perform set_config('test.tpl_148_empty_status', v_status::text, true);
end $$;
select is(
  (select current_setting('test.tpl_148_empty_status', true)),
  'draft', 'new template has status draft');

-- 3
select is(
  (select count(*)::int from workflow.workflow_steps
    where template_id = current_setting('test.tpl_148')::uuid
      and deleted_at is null),
  1, 'admin_add_step added a step row');

-- 4
select is(
  (select status::text from workflow.workflow_templates
    where id = current_setting('test.tpl_148')::uuid),
  'active', 'admin_activate_template moved status to active');

-- 5
select ok(
  (select (workflow.admin_get_template(
    current_setting('test.tpl_148')::uuid)
   ) ? 'steps' from (
     -- need session role=admin to call admin_get_template
     select null
   ) s),
  'admin_get_template returns json with steps key');
-- (Set role inline.)
do $$
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','54000000-0000-0000-0000-000000000148',
                       'role','authenticated')::text, true);
  perform set_config('request.jwt.claim.sub',
                     '54000000-0000-0000-0000-000000000148', true);
  set local role authenticated;
end $$;

-- 6
select cmp_ok(
  (select count(*)::int from workflow.admin_list_templates(null, 50, 0)),
  '>=', 1, 'admin_list_templates returns >= 1 template');
reset role;

-- 7  activating zero-step template raises
do $$
declare v_err text := '';
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','54000000-0000-0000-0000-000000000148',
                       'role','authenticated')::text, true);
  perform set_config('request.jwt.claim.sub',
                     '54000000-0000-0000-0000-000000000148', true);
  set local role authenticated;
  begin
    perform workflow.admin_activate_template(
      current_setting('test.tpl_148_empty')::uuid);
  exception when others then
    v_err := SQLERRM;
  end;
  reset role;
  perform set_config('test.activate_empty_err', v_err, true);
end $$;
select isnt(
  (select current_setting('test.activate_empty_err', true)),
  '', 'activating a template with zero steps raises');

-- 8  archive
do $$
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','54000000-0000-0000-0000-000000000148',
                       'role','authenticated')::text, true);
  perform set_config('request.jwt.claim.sub',
                     '54000000-0000-0000-0000-000000000148', true);
  set local role authenticated;
  perform workflow.admin_archive_template(current_setting('test.tpl_148')::uuid);
  reset role;
end $$;
select is(
  (select status::text from workflow.workflow_templates
    where id = current_setting('test.tpl_148')::uuid),
  'archived', 'admin_archive_template moved status to archived');

-- 9  archived_at set
select isnt(
  (select archived_at::text from workflow.workflow_templates
    where id = current_setting('test.tpl_148')::uuid),
  null, 'archived template has archived_at set');

-- 10 non-admin denied
do $$
declare v_err text := '';
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','54000000-0000-0000-0000-000000000248',
                       'role','authenticated',
                       'tenant_id','54000000-0000-0000-0000-00000000014a')::text, true);
  perform set_config('request.jwt.claim.sub',
                     '54000000-0000-0000-0000-000000000248', true);
  set local role authenticated;
  begin
    perform workflow.admin_create_template(
      'TPL-148-X', 'X', null, 'shipment', 'shipment', '{}'::jsonb);
  exception when others then
    v_err := SQLERRM;
  end;
  reset role;
  perform set_config('test.non_admin_err', v_err, true);
end $$;
select isnt(
  (select current_setting('test.non_admin_err', true)),
  '', 'non-admin admin_create_template raises (denied)');

select * from finish();
rollback;
