-- CC-66 Test 153 — workflow event ledger immutability + ordering
--
-- Assertions (6):
--   1.  authenticated has no INSERT on workflow_events (table privilege)
--   2.  UPDATE on workflow_events raises (append-only trigger)
--   3.  DELETE on workflow_events raises (append-only trigger)
--   4.  template_created event recorded on create
--   5.  template_activated event recorded on activate
--   6.  instance_started + step_generated events recorded on start

set search_path = extensions, public, identity, organization, audit, supplier,
                  commodity, rfq, offer, evaluation, contract, shipment, notify,
                  marketplace, dispatch, telematics, execution, workflow, tests;
begin;

-- ---------------------------------------------------------------------------
-- Fixture (admin + minimal shipment chain so we can start an instance)
-- ---------------------------------------------------------------------------
insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '54000000-0000-0000-0000-000000000153', 'authenticated','authenticated','153-admin@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '54000000-0000-0000-0000-000000000253', 'authenticated','authenticated','153-buyer@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('54000000-0000-0000-0000-000000000153', 'tenant-153', 'تست', 'Test 153');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status, country_code) values
  ('54000000-0000-0000-0000-000000000a53', '54000000-0000-0000-0000-000000000153',
   'buy-153', 'خریدار', 'Buyer 153', 'buyer', 'active', 'IR'),
  ('54000000-0000-0000-0000-000000000b53', '54000000-0000-0000-0000-000000000153',
   'sup-153', 'تأمین', 'Supplier 153', 'supplier', 'active', 'IR');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('54000000-0000-0000-0000-000000000153', '54000000-0000-0000-0000-000000000153',
   '54000000-0000-0000-0000-000000000a53', 'Admin 153', 'fa', 'active'),
  ('54000000-0000-0000-0000-000000000253', '54000000-0000-0000-0000-000000000153',
   '54000000-0000-0000-0000-000000000a53', 'Buyer 153', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '54000000-0000-0000-0000-000000000153', '54000000-0000-0000-0000-000000000a53',
       '54000000-0000-0000-0000-000000000253', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '54000000-0000-0000-0000-000000000153', r.id, 'platform', null
  from identity.roles r where r.code = 'platform_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '54000000-0000-0000-0000-000000000253', r.id, 'organization',
       '54000000-0000-0000-0000-000000000a53'
  from identity.roles r where r.code = 'buyer_admin';

insert into rfq.requests (id, tenant_id, organization_id, requester_user_id, rfq_code, title, status, visibility, preferred_currency)
values ('54000000-0000-0000-0000-000000000653', '54000000-0000-0000-0000-000000000153',
        '54000000-0000-0000-0000-000000000a53', '54000000-0000-0000-0000-000000000253',
        'RFQ-153', 'Stub', 'submitted', 'private_invited', 'USD');
insert into offer.supplier_offers (id, tenant_id, organization_id, request_id, supplier_id, offer_code, currency, status)
values ('54000000-0000-0000-0000-000000000753', '54000000-0000-0000-0000-000000000153',
        '54000000-0000-0000-0000-000000000b53', '54000000-0000-0000-0000-000000000653',
        (select id from supplier.suppliers where organization_id = '54000000-0000-0000-0000-000000000b53'),
        'OF-153', 'USD', 'submitted');
insert into evaluation.offer_decisions (id, tenant_id, organization_id, request_id, offer_id, decision_status)
values ('54000000-0000-0000-0000-000000000853', '54000000-0000-0000-0000-000000000153',
        '54000000-0000-0000-0000-000000000a53', '54000000-0000-0000-0000-000000000653',
        '54000000-0000-0000-0000-000000000753', 'selected_for_contract');
insert into contract.contract_preparations (id, tenant_id, organization_id, request_id, offer_id, decision_id, supplier_id, preparation_code, title, status)
values ('54000000-0000-0000-0000-000000000953', '54000000-0000-0000-0000-000000000153',
        '54000000-0000-0000-0000-000000000a53', '54000000-0000-0000-0000-000000000653',
        '54000000-0000-0000-0000-000000000753', '54000000-0000-0000-0000-000000000853',
        (select id from supplier.suppliers where organization_id = '54000000-0000-0000-0000-000000000b53'),
        'PREP-153', 'Prep', 'ready_for_contract');
insert into contract.executed_contracts (id, tenant_id, organization_id, preparation_id, request_id, offer_id, decision_id, supplier_id, contract_code, status, contract_type, title, currency, executed_at)
values ('54000000-0000-0000-0000-000000000c53', '54000000-0000-0000-0000-000000000153',
        '54000000-0000-0000-0000-000000000a53', '54000000-0000-0000-0000-000000000953',
        '54000000-0000-0000-0000-000000000653', '54000000-0000-0000-0000-000000000753',
        '54000000-0000-0000-0000-000000000853',
        (select id from supplier.suppliers where organization_id = '54000000-0000-0000-0000-000000000b53'),
        'CTR-153', 'executed', 'spot', 'CT-153', 'USD', now());
insert into shipment.shipments (id, tenant_id, organization_id, executed_contract_id, request_id, offer_id, supplier_id, shipment_code, status, transport_mode, origin_country, destination_country, planned_pickup_date)
values ('54000000-0000-0000-0000-000000000d53', '54000000-0000-0000-0000-000000000153',
        '54000000-0000-0000-0000-000000000a53', '54000000-0000-0000-0000-000000000c53',
        '54000000-0000-0000-0000-000000000653', '54000000-0000-0000-0000-000000000753',
        (select id from supplier.suppliers where organization_id = '54000000-0000-0000-0000-000000000b53'),
        'SH-153', 'planned', 'road', 'IR', 'DE', now() + interval '7 days');

-- Build template + start instance.
do $$
declare v_t uuid; v_inst uuid;
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','54000000-0000-0000-0000-000000000153',
                       'role','authenticated',
                       'tenant_id','54000000-0000-0000-0000-000000000153')::text, true);
  perform set_config('request.jwt.claim.sub',
                     '54000000-0000-0000-0000-000000000153', true);
  set local role authenticated;
  v_t := workflow.admin_create_template('TPL-153','T153',null,'shipment','shipment','{}'::jsonb);
  perform workflow.admin_add_step(v_t,'S1','Step1',null,'task',100,'buyer',null,'normal',null,'{}'::jsonb,'{}'::jsonb);
  perform workflow.admin_activate_template(v_t);
  perform set_config('test.t_153', v_t::text, true);
  reset role;

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','54000000-0000-0000-0000-000000000253',
                       'role','authenticated',
                       'tenant_id','54000000-0000-0000-0000-000000000153',
                       'organization_id','54000000-0000-0000-0000-000000000a53')::text, true);
  perform set_config('request.jwt.claim.sub',
                     '54000000-0000-0000-0000-000000000253', true);
  set local role authenticated;
  v_inst := workflow.buyer_start_workflow(
    v_t, '54000000-0000-0000-0000-000000000d53'::uuid, '{}'::jsonb);
  perform set_config('test.inst_153', v_inst::text, true);
  reset role;
end $$;

select plan(6);

-- 1
select is(
  has_table_privilege('authenticated', 'workflow.workflow_events', 'INSERT'),
  false, 'authenticated has no INSERT on workflow_events');

-- 2: UPDATE blocked via trigger (superuser session here, but trigger still
-- fires; pgTAP throws_ok captures the raised exception)
select throws_ok(
  $upd$ update workflow.workflow_events
           set payload = '{}'::jsonb
         where id = (
           select id from workflow.workflow_events
            where instance_id = current_setting('test.inst_153')::uuid
            limit 1
         )
  $upd$,
  '42501',
  null,
  'UPDATE on workflow_events raises append-only trigger');

-- 3: DELETE blocked via trigger
select throws_ok(
  $del$ delete from workflow.workflow_events
         where id = (
           select id from workflow.workflow_events
            where instance_id = current_setting('test.inst_153')::uuid
            limit 1
         )
  $del$,
  '42501',
  null,
  'DELETE on workflow_events raises append-only trigger');

-- 4: template_created event recorded
select cmp_ok(
  (select count(*)::int from workflow.workflow_events
    where template_id = current_setting('test.t_153')::uuid
      and event_type = 'template_created'),
  '>=', 1, 'template_created event recorded');

-- 5: template_activated event recorded
select cmp_ok(
  (select count(*)::int from workflow.workflow_events
    where template_id = current_setting('test.t_153')::uuid
      and event_type = 'template_activated'),
  '>=', 1, 'template_activated event recorded');

-- 6: instance_started + step_generated events recorded
select ok(
  (select count(*) filter (where event_type = 'instance_started') > 0
        and count(*) filter (where event_type = 'step_generated') > 0
     from workflow.workflow_events
    where instance_id = current_setting('test.inst_153')::uuid),
  'instance_started + step_generated events recorded on start');

select * from finish();
rollback;
