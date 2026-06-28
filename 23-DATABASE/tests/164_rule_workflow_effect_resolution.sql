-- CC-68 Test 164 — effect-to-template resolution
--
-- Assertions (5):
--   1.  effect.workflow_template_id resolves to the active template
--   2.  effect.template_id resolves to the active template
--   3.  effect.workflow_template_code resolves to the active template
--   4.  inactive (draft) template id is skipped (NULL)
--   5.  invalid template id is skipped (NULL)

set search_path = extensions, public, identity, organization, audit, supplier,
                  commodity, rfq, offer, evaluation, contract, shipment, notify,
                  marketplace, dispatch, telematics, execution, workflow, rules, tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '55000000-0000-0000-0000-000000000164', 'authenticated','authenticated','164-admin@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('55000000-0000-0000-0000-000000000164', 'tenant-164', 'تست', 'Test 164');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status, country_code) values
  ('55000000-0000-0000-0000-000000000a64', '55000000-0000-0000-0000-000000000164',
   'buy-164', 'خریدار', 'Buyer 164', 'buyer', 'active', 'IR');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('55000000-0000-0000-0000-000000000164', '55000000-0000-0000-0000-000000000164',
   '55000000-0000-0000-0000-000000000a64', 'Admin 164', 'fa', 'active');

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '55000000-0000-0000-0000-000000000164', r.id, 'platform', null
  from identity.roles r where r.code = 'platform_admin';

-- Admin builds one active template and one draft template.
do $$
declare v_active uuid; v_draft uuid; v_step uuid;
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','55000000-0000-0000-0000-000000000164',
                       'role','authenticated',
                       'tenant_id','55000000-0000-0000-0000-000000000164')::text, true);
  perform set_config('request.jwt.claim.sub',
                     '55000000-0000-0000-0000-000000000164', true);
  set local role authenticated;

  v_active := workflow.admin_create_template('WF-164A','Active','d','shipment','shipment','{}'::jsonb);
  v_step   := workflow.admin_add_step(v_active,'S1','Step');
  perform workflow.admin_activate_template(v_active);

  v_draft  := workflow.admin_create_template('WF-164D','Draft','d','shipment','shipment','{}'::jsonb);

  perform set_config('test.tpl_active_164', v_active::text, true);
  perform set_config('test.tpl_draft_164',  v_draft::text, true);
  reset role;
end $$;

select plan(5);

-- 1
select is(
  rules.fn_resolve_workflow_template_from_effect(
    jsonb_build_object('workflow_template_id', current_setting('test.tpl_active_164')),
    '55000000-0000-0000-0000-000000000164'::uuid),
  current_setting('test.tpl_active_164')::uuid,
  'effect.workflow_template_id resolves to the active template');

-- 2
select is(
  rules.fn_resolve_workflow_template_from_effect(
    jsonb_build_object('template_id', current_setting('test.tpl_active_164')),
    '55000000-0000-0000-0000-000000000164'::uuid),
  current_setting('test.tpl_active_164')::uuid,
  'effect.template_id resolves to the active template');

-- 3
select is(
  rules.fn_resolve_workflow_template_from_effect(
    jsonb_build_object('workflow_template_code', 'WF-164A'),
    '55000000-0000-0000-0000-000000000164'::uuid),
  current_setting('test.tpl_active_164')::uuid,
  'effect.workflow_template_code resolves to the active template');

-- 4
select is(
  rules.fn_resolve_workflow_template_from_effect(
    jsonb_build_object('workflow_template_id', current_setting('test.tpl_draft_164')),
    '55000000-0000-0000-0000-000000000164'::uuid),
  null::uuid,
  'inactive (draft) template id is skipped');

-- 5
select is(
  rules.fn_resolve_workflow_template_from_effect(
    jsonb_build_object('workflow_template_id', '55000000-0000-0000-0000-0000000000ff'),
    '55000000-0000-0000-0000-000000000164'::uuid),
  null::uuid,
  'invalid template id is skipped');

select * from finish();
rollback;
