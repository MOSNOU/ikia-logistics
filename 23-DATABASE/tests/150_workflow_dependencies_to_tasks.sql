-- CC-66 Test 150 — step dependencies translate to task dependencies
--
-- Assertions (8):
--   1.  admin_add_step_dependency adds a workflow_step_dependencies row
--   2.  start_workflow generates an execution.task_dependencies row
--   3.  CC-65 buyer_start_task on a dependent task raises while prereq is open
--   4.  self-dependency rejected
--   5.  cross-template dependency rejected
--   6.  2-node cycle rejected
--   7.  completing prereq unblocks the dependent task
--   8.  generated task_dependencies count equals workflow_step_dependencies count

set search_path = extensions, public, identity, organization, audit, supplier,
                  commodity, rfq, offer, evaluation, contract, shipment, notify,
                  marketplace, dispatch, telematics, execution, workflow, tests;
begin;

-- ---------------------------------------------------------------------------
-- Fixture
-- ---------------------------------------------------------------------------
insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '54000000-0000-0000-0000-000000000150', 'authenticated', 'authenticated',
   '150-admin@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '54000000-0000-0000-0000-000000000250', 'authenticated', 'authenticated',
   '150-buyer@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('54000000-0000-0000-0000-000000000150', 'tenant-150', 'تست', 'Test 150');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status, country_code) values
  ('54000000-0000-0000-0000-000000000a50', '54000000-0000-0000-0000-000000000150',
   'buy-150', 'خریدار', 'Buyer 150', 'buyer', 'active', 'IR'),
  ('54000000-0000-0000-0000-000000000b50', '54000000-0000-0000-0000-000000000150',
   'sup-150', 'تأمین', 'Supplier 150', 'supplier', 'active', 'IR');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('54000000-0000-0000-0000-000000000150', '54000000-0000-0000-0000-000000000150',
   '54000000-0000-0000-0000-000000000a50', 'Admin 150', 'fa', 'active'),
  ('54000000-0000-0000-0000-000000000250', '54000000-0000-0000-0000-000000000150',
   '54000000-0000-0000-0000-000000000a50', 'Buyer 150', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '54000000-0000-0000-0000-000000000150', '54000000-0000-0000-0000-000000000a50',
       '54000000-0000-0000-0000-000000000250', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '54000000-0000-0000-0000-000000000150', r.id, 'platform', null
  from identity.roles r where r.code = 'platform_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '54000000-0000-0000-0000-000000000250', r.id, 'organization',
       '54000000-0000-0000-0000-000000000a50'
  from identity.roles r where r.code = 'buyer_admin';

-- Shipment chain.
insert into rfq.requests (id, tenant_id, organization_id, requester_user_id, rfq_code, title, status, visibility, preferred_currency)
values ('54000000-0000-0000-0000-00000000015e', '54000000-0000-0000-0000-000000000150',
        '54000000-0000-0000-0000-000000000a50', '54000000-0000-0000-0000-000000000250',
        'RFQ-150', 'Stub', 'submitted', 'private_invited', 'USD');
insert into offer.supplier_offers (id, tenant_id, organization_id, request_id, supplier_id, offer_code, currency, status)
values ('54000000-0000-0000-0000-00000000015f', '54000000-0000-0000-0000-000000000150',
        '54000000-0000-0000-0000-000000000b50', '54000000-0000-0000-0000-00000000015e',
        (select id from supplier.suppliers where organization_id = '54000000-0000-0000-0000-000000000b50'),
        'OF-150', 'USD', 'submitted');
insert into evaluation.offer_decisions (id, tenant_id, organization_id, request_id, offer_id, decision_status)
values ('54000000-0000-0000-0000-000000000160', '54000000-0000-0000-0000-000000000150',
        '54000000-0000-0000-0000-000000000a50', '54000000-0000-0000-0000-00000000015e',
        '54000000-0000-0000-0000-00000000015f', 'selected_for_contract');
insert into contract.contract_preparations (id, tenant_id, organization_id, request_id, offer_id, decision_id, supplier_id, preparation_code, title, status)
values ('54000000-0000-0000-0000-000000000161', '54000000-0000-0000-0000-000000000150',
        '54000000-0000-0000-0000-000000000a50', '54000000-0000-0000-0000-00000000015e',
        '54000000-0000-0000-0000-00000000015f', '54000000-0000-0000-0000-000000000160',
        (select id from supplier.suppliers where organization_id = '54000000-0000-0000-0000-000000000b50'),
        'PREP-150', 'Prep', 'ready_for_contract');
insert into contract.executed_contracts (id, tenant_id, organization_id, preparation_id, request_id, offer_id, decision_id, supplier_id, contract_code, status, contract_type, title, currency, executed_at)
values ('54000000-0000-0000-0000-000000000162', '54000000-0000-0000-0000-000000000150',
        '54000000-0000-0000-0000-000000000a50', '54000000-0000-0000-0000-000000000161',
        '54000000-0000-0000-0000-00000000015e', '54000000-0000-0000-0000-00000000015f',
        '54000000-0000-0000-0000-000000000160',
        (select id from supplier.suppliers where organization_id = '54000000-0000-0000-0000-000000000b50'),
        'CTR-150', 'executed', 'spot', 'CT-150', 'USD', now());
insert into shipment.shipments (id, tenant_id, organization_id, executed_contract_id, request_id, offer_id, supplier_id, shipment_code, status, transport_mode, origin_country, destination_country, planned_pickup_date)
values ('54000000-0000-0000-0000-000000000163', '54000000-0000-0000-0000-000000000150',
        '54000000-0000-0000-0000-000000000a50', '54000000-0000-0000-0000-000000000162',
        '54000000-0000-0000-0000-00000000015e', '54000000-0000-0000-0000-00000000015f',
        (select id from supplier.suppliers where organization_id = '54000000-0000-0000-0000-000000000b50'),
        'SH-150', 'planned', 'road', 'IR', 'DE', now() + interval '7 days');

-- ---------------------------------------------------------------------------
-- Admin builds template T1 with S1 + S2, S2 depends on S1, then activates.
-- A second template T2 used to test cross-template dep failure.
-- ---------------------------------------------------------------------------
do $$
declare v_t1 uuid; v_t2 uuid; v_s1 uuid; v_s2 uuid; v_s3 uuid; v_dep uuid;
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','54000000-0000-0000-0000-000000000150',
                       'role','authenticated',
                       'tenant_id','54000000-0000-0000-0000-000000000150')::text, true);
  perform set_config('request.jwt.claim.sub',
                     '54000000-0000-0000-0000-000000000150', true);
  set local role authenticated;

  v_t1 := workflow.admin_create_template('TPL-150-T1','T1',null,'shipment','shipment','{}'::jsonb);
  v_s1 := workflow.admin_add_step(v_t1,'S1','Prepare',null,'task',100,'buyer',null,'normal',null,'{}'::jsonb,'{}'::jsonb);
  v_s2 := workflow.admin_add_step(v_t1,'S2','Pickup',null,'task',200,'buyer',null,'normal',null,'{}'::jsonb,'{}'::jsonb);
  v_dep := workflow.admin_add_step_dependency(v_s2, v_s1, 'finish_to_start');
  perform workflow.admin_activate_template(v_t1);
  perform set_config('test.t1_150', v_t1::text, true);
  perform set_config('test.s1_150', v_s1::text, true);
  perform set_config('test.s2_150', v_s2::text, true);

  v_t2 := workflow.admin_create_template('TPL-150-T2','T2',null,'shipment','shipment','{}'::jsonb);
  v_s3 := workflow.admin_add_step(v_t2,'S3','Other',null,'task',100,'buyer',null,'normal',null,'{}'::jsonb,'{}'::jsonb);
  perform set_config('test.s3_150', v_s3::text, true);

  reset role;
end $$;

-- Buyer starts the workflow.
do $$
declare v_inst uuid;
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','54000000-0000-0000-0000-000000000250',
                       'role','authenticated',
                       'tenant_id','54000000-0000-0000-0000-000000000150',
                       'organization_id','54000000-0000-0000-0000-000000000a50')::text, true);
  perform set_config('request.jwt.claim.sub',
                     '54000000-0000-0000-0000-000000000250', true);
  set local role authenticated;
  v_inst := workflow.buyer_start_workflow(
    current_setting('test.t1_150')::uuid,
    '54000000-0000-0000-0000-000000000163'::uuid,
    '{}'::jsonb);
  perform set_config('test.inst_150', v_inst::text, true);
  reset role;
end $$;

select plan(8);

-- 1
select is(
  (select count(*)::int from workflow.workflow_step_dependencies
    where template_id = current_setting('test.t1_150')::uuid),
  1, 'admin_add_step_dependency added a row');

-- 2
select cmp_ok(
  (select count(*)::int
     from execution.task_dependencies d
     join workflow.workflow_instance_tasks src on src.task_id = d.task_id
     join workflow.workflow_instance_tasks dst on dst.task_id = d.depends_on_task_id
    where src.instance_id = current_setting('test.inst_150')::uuid
      and dst.instance_id = current_setting('test.inst_150')::uuid),
  '>=', 1, 'execution.task_dependencies generated for instance');

-- 3: try to start the dependent task (S2 task) while S1 is still open
do $$
declare v_s2_task uuid; v_err text := '';
begin
  select task_id into v_s2_task from workflow.workflow_instance_tasks
   where instance_id = current_setting('test.inst_150')::uuid
     and step_id = current_setting('test.s2_150')::uuid;
  perform set_config('test.s2_task_150', v_s2_task::text, true);
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','54000000-0000-0000-0000-000000000250',
                       'role','authenticated',
                       'tenant_id','54000000-0000-0000-0000-000000000150',
                       'organization_id','54000000-0000-0000-0000-000000000a50')::text, true);
  perform set_config('request.jwt.claim.sub',
                     '54000000-0000-0000-0000-000000000250', true);
  set local role authenticated;
  begin
    perform execution.buyer_start_task(v_s2_task);
  exception when others then
    v_err := SQLERRM;
  end;
  reset role;
  perform set_config('test.start_blocked_err', v_err, true);
end $$;
select isnt(
  (select current_setting('test.start_blocked_err', true)),
  '', 'CC-65 buyer_start_task raises while prereq dependency is unfinished');

-- 4: self-dependency rejected
do $$
declare v_err text := '';
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','54000000-0000-0000-0000-000000000150',
                       'role','authenticated')::text, true);
  perform set_config('request.jwt.claim.sub',
                     '54000000-0000-0000-0000-000000000150', true);
  set local role authenticated;
  begin
    perform workflow.admin_add_step_dependency(
      current_setting('test.s1_150')::uuid,
      current_setting('test.s1_150')::uuid,
      'finish_to_start');
  exception when others then
    v_err := SQLERRM;
  end;
  reset role;
  perform set_config('test.self_err', v_err, true);
end $$;
select isnt(
  (select current_setting('test.self_err', true)),
  '', 'self-dependency rejected');

-- 5: cross-template dep rejected
do $$
declare v_err text := '';
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','54000000-0000-0000-0000-000000000150',
                       'role','authenticated')::text, true);
  perform set_config('request.jwt.claim.sub',
                     '54000000-0000-0000-0000-000000000150', true);
  set local role authenticated;
  begin
    perform workflow.admin_add_step_dependency(
      current_setting('test.s1_150')::uuid,
      current_setting('test.s3_150')::uuid,
      'finish_to_start');
  exception when others then
    v_err := SQLERRM;
  end;
  reset role;
  perform set_config('test.cross_err', v_err, true);
end $$;
select isnt(
  (select current_setting('test.cross_err', true)),
  '', 'cross-template dependency rejected');

-- 6: 2-node cycle rejected (try to add S1 → S2 while S2 → S1 already exists)
do $$
declare v_err text := '';
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','54000000-0000-0000-0000-000000000150',
                       'role','authenticated')::text, true);
  perform set_config('request.jwt.claim.sub',
                     '54000000-0000-0000-0000-000000000150', true);
  set local role authenticated;
  begin
    perform workflow.admin_add_step_dependency(
      current_setting('test.s1_150')::uuid,
      current_setting('test.s2_150')::uuid,
      'finish_to_start');
  exception when others then
    v_err := SQLERRM;
  end;
  reset role;
  perform set_config('test.cycle_err', v_err, true);
end $$;
select isnt(
  (select current_setting('test.cycle_err', true)),
  '', '2-node cycle rejected');

-- 7: completing prereq unblocks the dependent task
do $$
declare v_s1_task uuid;
begin
  select task_id into v_s1_task from workflow.workflow_instance_tasks
   where instance_id = current_setting('test.inst_150')::uuid
     and step_id = current_setting('test.s1_150')::uuid;
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','54000000-0000-0000-0000-000000000250',
                       'role','authenticated',
                       'tenant_id','54000000-0000-0000-0000-000000000150',
                       'organization_id','54000000-0000-0000-0000-000000000a50')::text, true);
  perform set_config('request.jwt.claim.sub',
                     '54000000-0000-0000-0000-000000000250', true);
  set local role authenticated;
  perform execution.buyer_start_task(v_s1_task);
  perform execution.buyer_complete_task(v_s1_task, 'done');
  perform execution.buyer_start_task(current_setting('test.s2_task_150')::uuid);
  reset role;
end $$;
select is(
  (select status::text from execution.shipment_tasks
    where id = current_setting('test.s2_task_150')::uuid),
  'in_progress', 'dependent task transitioned to in_progress after prereq completed');

-- 8
select is(
  (select count(*)::int
     from execution.task_dependencies d
     join workflow.workflow_instance_tasks src on src.task_id = d.task_id
    where src.instance_id = current_setting('test.inst_150')::uuid),
  (select count(*)::int from workflow.workflow_step_dependencies
    where template_id = current_setting('test.t1_150')::uuid),
  'task_dependencies count matches workflow_step_dependencies count for instance');

select * from finish();
rollback;
