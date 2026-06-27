-- CC-66 Test 149 — workflow start + task generation (buyer)
--
-- Assertions (10):
--   1.  buyer_start_workflow returns a uuid instance_id
--   2.  instance status is 'running'
--   3.  workflow_instance_tasks count equals step count
--   4.  execution.shipment_tasks count equals step count (for the shipment)
--   5.  generated task metadata carries workflow_instance_id
--   6.  due_at is set when default_due_offset_hours is provided
--   7.  workflow_events has an instance_started event
--   8.  workflow_events step_generated event count equals step count
--   9.  starting on an inactive (draft) template raises
--  10.  a duplicate active instance on same (template, shipment) raises

set search_path = extensions, public, identity, organization, audit, supplier,
                  commodity, rfq, offer, evaluation, contract, shipment, notify,
                  marketplace, dispatch, telematics, execution, workflow, tests;
begin;

-- ---------------------------------------------------------------------------
-- Fixture: users + tenant + orgs + roles + full shipment chain
-- ---------------------------------------------------------------------------
insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '54000000-0000-0000-0000-000000000149', 'authenticated', 'authenticated',
   '149-admin@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '54000000-0000-0000-0000-000000000249', 'authenticated', 'authenticated',
   '149-buyer@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('54000000-0000-0000-0000-00000000014c', 'tenant-149', 'تست', 'Test 149');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status, country_code) values
  ('54000000-0000-0000-0000-00000000014d', '54000000-0000-0000-0000-00000000014c',
   'buy-149', 'خریدار', 'Buyer 149', 'buyer', 'active', 'IR'),
  ('54000000-0000-0000-0000-00000000014e', '54000000-0000-0000-0000-00000000014c',
   'sup-149', 'تأمین', 'Supplier 149', 'supplier', 'active', 'IR');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('54000000-0000-0000-0000-000000000149', '54000000-0000-0000-0000-00000000014c',
   '54000000-0000-0000-0000-00000000014d', 'Admin 149', 'fa', 'active'),
  ('54000000-0000-0000-0000-000000000249', '54000000-0000-0000-0000-00000000014c',
   '54000000-0000-0000-0000-00000000014d', 'Buyer 149', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '54000000-0000-0000-0000-00000000014c', '54000000-0000-0000-0000-00000000014d',
       '54000000-0000-0000-0000-000000000249', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '54000000-0000-0000-0000-000000000149', r.id, 'platform', null
  from identity.roles r where r.code = 'platform_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '54000000-0000-0000-0000-000000000249', r.id, 'organization',
       '54000000-0000-0000-0000-00000000014d'
  from identity.roles r where r.code = 'buyer_admin';

-- Shipment chain.
insert into rfq.requests (id, tenant_id, organization_id, requester_user_id, rfq_code, title, status, visibility, preferred_currency)
values ('54000000-0000-0000-0000-00000000015a', '54000000-0000-0000-0000-00000000014c',
        '54000000-0000-0000-0000-00000000014d', '54000000-0000-0000-0000-000000000249',
        'RFQ-149', 'Stub', 'submitted', 'private_invited', 'USD');
insert into offer.supplier_offers (id, tenant_id, organization_id, request_id, supplier_id, offer_code, currency, status)
values ('54000000-0000-0000-0000-00000000015b', '54000000-0000-0000-0000-00000000014c',
        '54000000-0000-0000-0000-00000000014e', '54000000-0000-0000-0000-00000000015a',
        (select id from supplier.suppliers where organization_id = '54000000-0000-0000-0000-00000000014e'),
        'OF-149', 'USD', 'submitted');
insert into evaluation.offer_decisions (id, tenant_id, organization_id, request_id, offer_id, decision_status)
values ('54000000-0000-0000-0000-00000000015c', '54000000-0000-0000-0000-00000000014c',
        '54000000-0000-0000-0000-00000000014d', '54000000-0000-0000-0000-00000000015a',
        '54000000-0000-0000-0000-00000000015b', 'selected_for_contract');
insert into contract.contract_preparations (id, tenant_id, organization_id, request_id, offer_id, decision_id, supplier_id, preparation_code, title, status)
values ('54000000-0000-0000-0000-00000000015d', '54000000-0000-0000-0000-00000000014c',
        '54000000-0000-0000-0000-00000000014d', '54000000-0000-0000-0000-00000000015a',
        '54000000-0000-0000-0000-00000000015b', '54000000-0000-0000-0000-00000000015c',
        (select id from supplier.suppliers where organization_id = '54000000-0000-0000-0000-00000000014e'),
        'PREP-149', 'Prep', 'ready_for_contract');
insert into contract.executed_contracts (id, tenant_id, organization_id, preparation_id, request_id, offer_id, decision_id, supplier_id, contract_code, status, contract_type, title, currency, executed_at)
values ('54000000-0000-0000-0000-00000000016a', '54000000-0000-0000-0000-00000000014c',
        '54000000-0000-0000-0000-00000000014d', '54000000-0000-0000-0000-00000000015d',
        '54000000-0000-0000-0000-00000000015a', '54000000-0000-0000-0000-00000000015b',
        '54000000-0000-0000-0000-00000000015c',
        (select id from supplier.suppliers where organization_id = '54000000-0000-0000-0000-00000000014e'),
        'CTR-149', 'executed', 'spot', 'CT-149', 'USD', now());
insert into shipment.shipments (id, tenant_id, organization_id, executed_contract_id, request_id, offer_id, supplier_id, shipment_code, status, transport_mode, origin_country, destination_country, planned_pickup_date)
values ('54000000-0000-0000-0000-00000000017a', '54000000-0000-0000-0000-00000000014c',
        '54000000-0000-0000-0000-00000000014d', '54000000-0000-0000-0000-00000000016a',
        '54000000-0000-0000-0000-00000000015a', '54000000-0000-0000-0000-00000000015b',
        (select id from supplier.suppliers where organization_id = '54000000-0000-0000-0000-00000000014e'),
        'SH-149', 'planned', 'road', 'IR', 'DE', now() + interval '7 days');

-- ---------------------------------------------------------------------------
-- Admin builds + activates a 3-step template, plus a draft (inactive) template.
-- ---------------------------------------------------------------------------
do $$
declare v_tpl uuid; v_tpl_draft uuid; v_s1 uuid; v_s2 uuid; v_s3 uuid;
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','54000000-0000-0000-0000-000000000149',
                       'role','authenticated',
                       'tenant_id','54000000-0000-0000-0000-00000000014c')::text, true);
  perform set_config('request.jwt.claim.sub',
                     '54000000-0000-0000-0000-000000000149', true);
  set local role authenticated;

  v_tpl := workflow.admin_create_template('TPL-149','Shipment 149','desc','shipment','shipment','{}'::jsonb);
  v_s1 := workflow.admin_add_step(v_tpl,'S1','Prepare docs',null,'task',100,'buyer',null,'normal',24,'{}'::jsonb,'{}'::jsonb);
  v_s2 := workflow.admin_add_step(v_tpl,'S2','Pickup',null,'task',200,'carrier',null,'high',null,'{}'::jsonb,'{}'::jsonb);
  v_s3 := workflow.admin_add_step(v_tpl,'S3','Confirm delivery',null,'checkpoint',300,'buyer',null,'normal',48,'{}'::jsonb,'{}'::jsonb);
  perform workflow.admin_activate_template(v_tpl);
  perform set_config('test.tpl_149', v_tpl::text, true);

  v_tpl_draft := workflow.admin_create_template('TPL-149-D','Draft 149',null,'shipment','shipment','{}'::jsonb);
  perform set_config('test.tpl_149_draft', v_tpl_draft::text, true);

  reset role;
end $$;

-- ---------------------------------------------------------------------------
-- Buyer starts the workflow against the shipment.
-- ---------------------------------------------------------------------------
do $$
declare v_inst uuid;
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','54000000-0000-0000-0000-000000000249',
                       'role','authenticated',
                       'tenant_id','54000000-0000-0000-0000-00000000014c',
                       'organization_id','54000000-0000-0000-0000-00000000014d')::text, true);
  perform set_config('request.jwt.claim.sub',
                     '54000000-0000-0000-0000-000000000249', true);
  set local role authenticated;

  v_inst := workflow.buyer_start_workflow(
    current_setting('test.tpl_149')::uuid,
    '54000000-0000-0000-0000-00000000017a'::uuid,
    jsonb_build_object('source','test-149'));
  perform set_config('test.inst_149', v_inst::text, true);

  reset role;
end $$;

select plan(10);

-- 1
select isnt(
  (select current_setting('test.inst_149', true)),
  '', 'buyer_start_workflow returns a uuid instance_id');

-- 2
select is(
  (select status::text from workflow.workflow_instances
    where id = current_setting('test.inst_149')::uuid),
  'running', 'instance status is running');

-- 3
select is(
  (select count(*)::int from workflow.workflow_instance_tasks
    where instance_id = current_setting('test.inst_149')::uuid),
  3, 'workflow_instance_tasks count equals step count (3)');

-- 4
select is(
  (select count(*)::int from execution.shipment_tasks
    where shipment_id = '54000000-0000-0000-0000-00000000017a'::uuid),
  3, 'execution.shipment_tasks count equals step count (3) for shipment');

-- 5
select ok(
  (select bool_and(t.metadata ? 'workflow_instance_id')
     from workflow.workflow_instance_tasks wit
     join execution.shipment_tasks t on t.id = wit.task_id
    where wit.instance_id = current_setting('test.inst_149')::uuid),
  'every generated task metadata carries workflow_instance_id');

-- 6: S1 had offset=24 → due_at should be set on its task
select isnt(
  (select t.due_at::text
     from workflow.workflow_instance_tasks wit
     join execution.shipment_tasks t on t.id = wit.task_id
     join workflow.workflow_steps s on s.id = wit.step_id
    where wit.instance_id = current_setting('test.inst_149')::uuid
      and s.step_code = 'S1'),
  null, 'due_at is set when default_due_offset_hours is provided');

-- 7
select cmp_ok(
  (select count(*)::int from workflow.workflow_events
    where instance_id = current_setting('test.inst_149')::uuid
      and event_type = 'instance_started'),
  '>=', 1, 'workflow_events has an instance_started event');

-- 8
select is(
  (select count(*)::int from workflow.workflow_events
    where instance_id = current_setting('test.inst_149')::uuid
      and event_type = 'step_generated'),
  3, 'workflow_events step_generated event count equals step count (3)');

-- 9: starting on a draft (inactive) template raises
do $$
declare v_err text := '';
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','54000000-0000-0000-0000-000000000249',
                       'role','authenticated',
                       'tenant_id','54000000-0000-0000-0000-00000000014c',
                       'organization_id','54000000-0000-0000-0000-00000000014d')::text, true);
  perform set_config('request.jwt.claim.sub',
                     '54000000-0000-0000-0000-000000000249', true);
  set local role authenticated;
  begin
    perform workflow.buyer_start_workflow(
      current_setting('test.tpl_149_draft')::uuid,
      '54000000-0000-0000-0000-00000000017a'::uuid,
      '{}'::jsonb);
  exception when others then
    v_err := SQLERRM;
  end;
  reset role;
  perform set_config('test.draft_err', v_err, true);
end $$;
select isnt(
  (select current_setting('test.draft_err', true)),
  '', 'starting on a draft (inactive) template raises');

-- 10: duplicate active instance raises
do $$
declare v_err text := '';
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','54000000-0000-0000-0000-000000000249',
                       'role','authenticated',
                       'tenant_id','54000000-0000-0000-0000-00000000014c',
                       'organization_id','54000000-0000-0000-0000-00000000014d')::text, true);
  perform set_config('request.jwt.claim.sub',
                     '54000000-0000-0000-0000-000000000249', true);
  set local role authenticated;
  begin
    perform workflow.buyer_start_workflow(
      current_setting('test.tpl_149')::uuid,
      '54000000-0000-0000-0000-00000000017a'::uuid,
      '{}'::jsonb);
  exception when others then
    v_err := SQLERRM;
  end;
  reset role;
  perform set_config('test.dup_err', v_err, true);
end $$;
select isnt(
  (select current_setting('test.dup_err', true)),
  '', 'duplicate active instance raises');

select * from finish();
rollback;
