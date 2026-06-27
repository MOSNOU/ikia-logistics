-- CC-66 Test 152 — instance lifecycle (cancel + recalculate completion)
--
-- Assertions (8):
--   1.  admin_cancel_instance moves status to 'cancelled'
--   2.  cancelled_at is set
--   3.  instance_cancelled event recorded
--   4.  cancelling an already-cancelled instance raises
--   5.  recalculate flips instance to 'completed' when all tasks done
--   6.  completed_at is set
--   7.  instance_completed event recorded
--   8.  recalculate is idempotent on already-completed instance

set search_path = extensions, public, identity, organization, audit, supplier,
                  commodity, rfq, offer, evaluation, contract, shipment, notify,
                  marketplace, dispatch, telematics, execution, workflow, tests;
begin;

-- ---------------------------------------------------------------------------
-- Fixture
-- ---------------------------------------------------------------------------
insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '54000000-0000-0000-0000-000000000152', 'authenticated','authenticated','152-admin@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '54000000-0000-0000-0000-000000000252', 'authenticated','authenticated','152-buyer@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('54000000-0000-0000-0000-000000000152', 'tenant-152', 'تست', 'Test 152');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status, country_code) values
  ('54000000-0000-0000-0000-000000000a52', '54000000-0000-0000-0000-000000000152',
   'buy-152', 'خریدار', 'Buyer 152', 'buyer', 'active', 'IR'),
  ('54000000-0000-0000-0000-000000000b52', '54000000-0000-0000-0000-000000000152',
   'sup-152', 'تأمین', 'Supplier 152', 'supplier', 'active', 'IR');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('54000000-0000-0000-0000-000000000152', '54000000-0000-0000-0000-000000000152',
   '54000000-0000-0000-0000-000000000a52', 'Admin 152', 'fa', 'active'),
  ('54000000-0000-0000-0000-000000000252', '54000000-0000-0000-0000-000000000152',
   '54000000-0000-0000-0000-000000000a52', 'Buyer 152', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '54000000-0000-0000-0000-000000000152', '54000000-0000-0000-0000-000000000a52',
       '54000000-0000-0000-0000-000000000252', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '54000000-0000-0000-0000-000000000152', r.id, 'platform', null
  from identity.roles r where r.code = 'platform_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '54000000-0000-0000-0000-000000000252', r.id, 'organization',
       '54000000-0000-0000-0000-000000000a52'
  from identity.roles r where r.code = 'buyer_admin';

-- Shipment chain
insert into rfq.requests (id, tenant_id, organization_id, requester_user_id, rfq_code, title, status, visibility, preferred_currency)
values ('54000000-0000-0000-0000-000000000652', '54000000-0000-0000-0000-000000000152',
        '54000000-0000-0000-0000-000000000a52', '54000000-0000-0000-0000-000000000252',
        'RFQ-152', 'Stub', 'submitted', 'private_invited', 'USD');
insert into offer.supplier_offers (id, tenant_id, organization_id, request_id, supplier_id, offer_code, currency, status)
values ('54000000-0000-0000-0000-000000000752', '54000000-0000-0000-0000-000000000152',
        '54000000-0000-0000-0000-000000000b52', '54000000-0000-0000-0000-000000000652',
        (select id from supplier.suppliers where organization_id = '54000000-0000-0000-0000-000000000b52'),
        'OF-152', 'USD', 'submitted');
insert into evaluation.offer_decisions (id, tenant_id, organization_id, request_id, offer_id, decision_status)
values ('54000000-0000-0000-0000-000000000852', '54000000-0000-0000-0000-000000000152',
        '54000000-0000-0000-0000-000000000a52', '54000000-0000-0000-0000-000000000652',
        '54000000-0000-0000-0000-000000000752', 'selected_for_contract');
insert into contract.contract_preparations (id, tenant_id, organization_id, request_id, offer_id, decision_id, supplier_id, preparation_code, title, status)
values ('54000000-0000-0000-0000-000000000952', '54000000-0000-0000-0000-000000000152',
        '54000000-0000-0000-0000-000000000a52', '54000000-0000-0000-0000-000000000652',
        '54000000-0000-0000-0000-000000000752', '54000000-0000-0000-0000-000000000852',
        (select id from supplier.suppliers where organization_id = '54000000-0000-0000-0000-000000000b52'),
        'PREP-152', 'Prep', 'ready_for_contract');
insert into contract.executed_contracts (id, tenant_id, organization_id, preparation_id, request_id, offer_id, decision_id, supplier_id, contract_code, status, contract_type, title, currency, executed_at)
values ('54000000-0000-0000-0000-000000000c52', '54000000-0000-0000-0000-000000000152',
        '54000000-0000-0000-0000-000000000a52', '54000000-0000-0000-0000-000000000952',
        '54000000-0000-0000-0000-000000000652', '54000000-0000-0000-0000-000000000752',
        '54000000-0000-0000-0000-000000000852',
        (select id from supplier.suppliers where organization_id = '54000000-0000-0000-0000-000000000b52'),
        'CTR-152', 'executed', 'spot', 'CT-152', 'USD', now());
insert into shipment.shipments (id, tenant_id, organization_id, executed_contract_id, request_id, offer_id, supplier_id, supplier_organization_id, shipment_code, status, transport_mode, origin_country, destination_country, planned_pickup_date)
values ('54000000-0000-0000-0000-000000000d52', '54000000-0000-0000-0000-000000000152',
        '54000000-0000-0000-0000-000000000a52', '54000000-0000-0000-0000-000000000c52',
        '54000000-0000-0000-0000-000000000652', '54000000-0000-0000-0000-000000000752',
        (select id from supplier.suppliers where organization_id = '54000000-0000-0000-0000-000000000b52'),
        '54000000-0000-0000-0000-000000000b52',
        'SH-152', 'planned', 'road', 'IR', 'DE', now() + interval '7 days');

-- Admin builds + activates a 2-step buyer-owned template
do $$
declare v_t uuid;
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','54000000-0000-0000-0000-000000000152',
                       'role','authenticated',
                       'tenant_id','54000000-0000-0000-0000-000000000152')::text, true);
  perform set_config('request.jwt.claim.sub',
                     '54000000-0000-0000-0000-000000000152', true);
  set local role authenticated;
  v_t := workflow.admin_create_template('TPL-152','T152',null,'shipment','shipment','{}'::jsonb);
  perform workflow.admin_add_step(v_t,'S1','Step1',null,'task',100,'buyer',null,'normal',null,'{}'::jsonb,'{}'::jsonb);
  perform workflow.admin_add_step(v_t,'S2','Step2',null,'task',200,'buyer',null,'normal',null,'{}'::jsonb,'{}'::jsonb);
  perform workflow.admin_activate_template(v_t);
  perform set_config('test.t_152', v_t::text, true);
  reset role;
end $$;

-- Instance A: buyer starts → admin cancels
do $$
declare v_inst uuid;
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','54000000-0000-0000-0000-000000000252',
                       'role','authenticated',
                       'tenant_id','54000000-0000-0000-0000-000000000152',
                       'organization_id','54000000-0000-0000-0000-000000000a52')::text, true);
  perform set_config('request.jwt.claim.sub',
                     '54000000-0000-0000-0000-000000000252', true);
  set local role authenticated;
  v_inst := workflow.buyer_start_workflow(
    current_setting('test.t_152')::uuid,
    '54000000-0000-0000-0000-000000000d52'::uuid,
    '{}'::jsonb);
  perform set_config('test.inst_a_152', v_inst::text, true);
  reset role;

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','54000000-0000-0000-0000-000000000152',
                       'role','authenticated')::text, true);
  perform set_config('request.jwt.claim.sub',
                     '54000000-0000-0000-0000-000000000152', true);
  set local role authenticated;
  perform workflow.admin_cancel_instance(v_inst, 'no-longer-needed');
  reset role;
end $$;

select plan(8);

-- 1
select is(
  (select status::text from workflow.workflow_instances
    where id = current_setting('test.inst_a_152')::uuid),
  'cancelled', 'admin_cancel_instance moves status to cancelled');

-- 2
select isnt(
  (select cancelled_at::text from workflow.workflow_instances
    where id = current_setting('test.inst_a_152')::uuid),
  null, 'cancelled_at is set');

-- 3
select cmp_ok(
  (select count(*)::int from workflow.workflow_events
    where instance_id = current_setting('test.inst_a_152')::uuid
      and event_type = 'instance_cancelled'),
  '>=', 1, 'instance_cancelled event recorded');

-- 4: re-cancel raises
do $$
declare v_err text := '';
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','54000000-0000-0000-0000-000000000152',
                       'role','authenticated')::text, true);
  perform set_config('request.jwt.claim.sub',
                     '54000000-0000-0000-0000-000000000152', true);
  set local role authenticated;
  begin
    perform workflow.admin_cancel_instance(
      current_setting('test.inst_a_152')::uuid, 'again');
  exception when others then
    v_err := SQLERRM;
  end;
  reset role;
  perform set_config('test.recancel_err', v_err, true);
end $$;
select isnt(
  (select current_setting('test.recancel_err', true)),
  '', 'cancelling an already-cancelled instance raises');

-- Instance B: buyer starts a fresh instance, completes all tasks, then admin
-- recalculates status.
do $$
declare v_inst uuid; v_task uuid;
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','54000000-0000-0000-0000-000000000252',
                       'role','authenticated',
                       'tenant_id','54000000-0000-0000-0000-000000000152',
                       'organization_id','54000000-0000-0000-0000-000000000a52')::text, true);
  perform set_config('request.jwt.claim.sub',
                     '54000000-0000-0000-0000-000000000252', true);
  set local role authenticated;
  v_inst := workflow.buyer_start_workflow(
    current_setting('test.t_152')::uuid,
    '54000000-0000-0000-0000-000000000d52'::uuid,
    '{}'::jsonb);
  perform set_config('test.inst_b_152', v_inst::text, true);
  for v_task in
    select task_id from workflow.workflow_instance_tasks
     where instance_id = v_inst
  loop
    perform execution.buyer_start_task(v_task);
    perform execution.buyer_complete_task(v_task, 'auto-done');
  end loop;
  reset role;

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','54000000-0000-0000-0000-000000000152',
                       'role','authenticated')::text, true);
  perform set_config('request.jwt.claim.sub',
                     '54000000-0000-0000-0000-000000000152', true);
  set local role authenticated;
  perform workflow.admin_recalculate_instance_status(v_inst);
  reset role;
end $$;

-- 5
select is(
  (select status::text from workflow.workflow_instances
    where id = current_setting('test.inst_b_152')::uuid),
  'completed', 'recalculate flips instance to completed when all tasks done');

-- 6
select isnt(
  (select completed_at::text from workflow.workflow_instances
    where id = current_setting('test.inst_b_152')::uuid),
  null, 'completed_at is set');

-- 7
select cmp_ok(
  (select count(*)::int from workflow.workflow_events
    where instance_id = current_setting('test.inst_b_152')::uuid
      and event_type = 'instance_completed'),
  '>=', 1, 'instance_completed event recorded');

-- 8: recalculate again is idempotent (no exception)
do $$
declare v_err text := '';
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','54000000-0000-0000-0000-000000000152',
                       'role','authenticated')::text, true);
  perform set_config('request.jwt.claim.sub',
                     '54000000-0000-0000-0000-000000000152', true);
  set local role authenticated;
  begin
    perform workflow.admin_recalculate_instance_status(
      current_setting('test.inst_b_152')::uuid);
  exception when others then
    v_err := SQLERRM;
  end;
  reset role;
  perform set_config('test.recalc_idempotent_err', v_err, true);
end $$;
select is(
  (select current_setting('test.recalc_idempotent_err', true)),
  '', 'recalculate is idempotent on already-completed instance');

select * from finish();
rollback;
