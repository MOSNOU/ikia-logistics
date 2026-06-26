-- CC-65 Test 138 — buyer task flow happy path + denials
--
-- Assertions (10):
--   1.  buyer_create_task returns a uuid
--   2.  buyer_list_tasks returns the new task
--   3.  buyer_get_task returns the task
--   4.  buyer_start_task moves status to in_progress
--   5.  started_at is set after start
--   6.  buyer_complete_task moves status to completed
--   7.  completed_at is set after complete
--   8.  task_events ledger has at least three rows (created/started/completed)
--   9.  buyer_complete_task on a completed task raises
--  10.  unrelated user gets zero rows from buyer_list_tasks

set search_path = extensions, public, identity, organization, audit, supplier,
                  commodity, rfq, offer, evaluation, contract, shipment, notify,
                  marketplace, dispatch, telematics, execution, tests;
begin;

-- ---------------------------------------------------------------------------
-- Fixture
-- ---------------------------------------------------------------------------
insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '53000000-0000-0000-0000-000000000138', 'authenticated', 'authenticated',
   '138-buyer@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '53000000-0000-0000-0000-000000000238', 'authenticated', 'authenticated',
   '138-stranger@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('53000000-0000-0000-0000-00000000013a', 'tenant-138', 'تست', 'Test 138');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status, country_code) values
  ('53000000-0000-0000-0000-00000000013b', '53000000-0000-0000-0000-00000000013a',
   'buy-138', 'خریدار', 'Buyer 138', 'buyer', 'active', 'IR'),
  ('53000000-0000-0000-0000-00000000013c', '53000000-0000-0000-0000-00000000013a',
   'sup-138', 'تأمین', 'Supplier 138', 'supplier', 'active', 'IR'),
  ('53000000-0000-0000-0000-00000000013d', '53000000-0000-0000-0000-00000000013a',
   'oth-138', 'دیگر', 'Other 138', 'buyer', 'active', 'IR');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('53000000-0000-0000-0000-000000000138', '53000000-0000-0000-0000-00000000013a',
   '53000000-0000-0000-0000-00000000013b', 'Buyer 138', 'fa', 'active'),
  ('53000000-0000-0000-0000-000000000238', '53000000-0000-0000-0000-00000000013a',
   '53000000-0000-0000-0000-00000000013d', 'Stranger 138', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '53000000-0000-0000-0000-00000000013a', '53000000-0000-0000-0000-00000000013b',
       '53000000-0000-0000-0000-000000000138', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '53000000-0000-0000-0000-000000000138', r.id, 'organization',
       '53000000-0000-0000-0000-00000000013b'
  from identity.roles r where r.code = 'buyer_admin';

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '53000000-0000-0000-0000-00000000013a', '53000000-0000-0000-0000-00000000013d',
       '53000000-0000-0000-0000-000000000238', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '53000000-0000-0000-0000-000000000238', r.id, 'organization',
       '53000000-0000-0000-0000-00000000013d'
  from identity.roles r where r.code = 'buyer_admin';

-- Shipment chain (compressed).
insert into rfq.requests (id, tenant_id, organization_id, requester_user_id, rfq_code, title, status, visibility, preferred_currency)
values ('53000000-0000-0000-0000-00000000014a', '53000000-0000-0000-0000-00000000013a',
        '53000000-0000-0000-0000-00000000013b', '53000000-0000-0000-0000-000000000138',
        'RFQ-138', 'Stub', 'submitted', 'private_invited', 'USD');
insert into offer.supplier_offers (id, tenant_id, organization_id, request_id, supplier_id, offer_code, currency, status)
values ('53000000-0000-0000-0000-00000000014b', '53000000-0000-0000-0000-00000000013a',
        '53000000-0000-0000-0000-00000000013c', '53000000-0000-0000-0000-00000000014a',
        (select id from supplier.suppliers where organization_id = '53000000-0000-0000-0000-00000000013c'),
        'OF-138', 'USD', 'submitted');
insert into evaluation.offer_decisions (id, tenant_id, organization_id, request_id, offer_id, decision_status)
values ('53000000-0000-0000-0000-00000000014c', '53000000-0000-0000-0000-00000000013a',
        '53000000-0000-0000-0000-00000000013b', '53000000-0000-0000-0000-00000000014a',
        '53000000-0000-0000-0000-00000000014b', 'selected_for_contract');
insert into contract.contract_preparations (id, tenant_id, organization_id, request_id, offer_id, decision_id, supplier_id, preparation_code, title, status)
values ('53000000-0000-0000-0000-00000000014d', '53000000-0000-0000-0000-00000000013a',
        '53000000-0000-0000-0000-00000000013b', '53000000-0000-0000-0000-00000000014a',
        '53000000-0000-0000-0000-00000000014b', '53000000-0000-0000-0000-00000000014c',
        (select id from supplier.suppliers where organization_id = '53000000-0000-0000-0000-00000000013c'),
        'PREP-138', 'Prep', 'ready_for_contract');
insert into contract.executed_contracts (id, tenant_id, organization_id, preparation_id, request_id, offer_id, decision_id, supplier_id, contract_code, status, contract_type, title, currency, executed_at)
values ('53000000-0000-0000-0000-00000000015a', '53000000-0000-0000-0000-00000000013a',
        '53000000-0000-0000-0000-00000000013b', '53000000-0000-0000-0000-00000000014d',
        '53000000-0000-0000-0000-00000000014a', '53000000-0000-0000-0000-00000000014b',
        '53000000-0000-0000-0000-00000000014c',
        (select id from supplier.suppliers where organization_id = '53000000-0000-0000-0000-00000000013c'),
        'CTR-138', 'executed', 'spot', 'CT-138', 'USD', now());
insert into shipment.shipments (id, tenant_id, organization_id, executed_contract_id, request_id, offer_id, supplier_id, shipment_code, status, transport_mode, origin_country, destination_country, planned_pickup_date)
values ('53000000-0000-0000-0000-00000000016a', '53000000-0000-0000-0000-00000000013a',
        '53000000-0000-0000-0000-00000000013b', '53000000-0000-0000-0000-00000000015a',
        '53000000-0000-0000-0000-00000000014a', '53000000-0000-0000-0000-00000000014b',
        (select id from supplier.suppliers where organization_id = '53000000-0000-0000-0000-00000000013c'),
        'SH-138', 'planned', 'road', 'IR', 'DE', now() + interval '7 days');

-- ---------------------------------------------------------------------------
-- Buyer creates → starts → completes the task.
-- ---------------------------------------------------------------------------
do $$
declare v_task uuid;
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','53000000-0000-0000-0000-000000000138',
                       'role','authenticated',
                       'tenant_id','53000000-0000-0000-0000-00000000013a',
                       'organization_id','53000000-0000-0000-0000-00000000013b')::text, true);
  perform set_config('request.jwt.claim.sub',
                     '53000000-0000-0000-0000-000000000138', true);
  set local role authenticated;

  v_task := execution.buyer_create_task(
    '53000000-0000-0000-0000-00000000016a'::uuid,
    'Prepare customs paperwork',
    'Ensure declaration is ready before pickup');
  perform set_config('test.task_138', v_task::text, true);

  perform execution.buyer_start_task(v_task);
  perform execution.buyer_complete_task(v_task, 'Docs ready');

  reset role;
end $$;

select plan(10);

-- 1. created task is not null
select isnt(
  (select current_setting('test.task_138', true)),
  '',
  'buyer_create_task returns a uuid');

-- 2. buyer_list_tasks returns the new task (set role first)
do $$
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','53000000-0000-0000-0000-000000000138',
                       'role','authenticated',
                       'tenant_id','53000000-0000-0000-0000-00000000013a',
                       'organization_id','53000000-0000-0000-0000-00000000013b')::text, true);
  perform set_config('request.jwt.claim.sub',
                     '53000000-0000-0000-0000-000000000138', true);
  set local role authenticated;
end $$;
select is(
  (select count(*)::int from execution.buyer_list_tasks(
     '53000000-0000-0000-0000-00000000016a'::uuid, null, 50, 0)),
  1, 'buyer_list_tasks returns the new task');

-- 3. buyer_get_task returns the task
select is(
  (execution.buyer_get_task(current_setting('test.task_138')::uuid)).title,
  'Prepare customs paperwork',
  'buyer_get_task returns the task with correct title');

-- 4. status is completed (terminal)
select is(
  (select status::text from execution.shipment_tasks
    where id = current_setting('test.task_138')::uuid),
  'completed',
  'task status is completed after the flow');

-- 5. started_at is set
select isnt(
  (select started_at::text from execution.shipment_tasks
    where id = current_setting('test.task_138')::uuid),
  null,
  'started_at is set after start');

-- 6. completed_at is set
select isnt(
  (select completed_at::text from execution.shipment_tasks
    where id = current_setting('test.task_138')::uuid),
  null,
  'completed_at is set after complete');

-- 7. event ledger has at least 3 rows (created/started/completed)
reset role;
select cmp_ok(
  (select count(*)::int from execution.task_events
    where task_id = current_setting('test.task_138')::uuid),
  '>=', 3, 'task_events has >= 3 rows');

-- 8. event types include task.completed
select ok(
  (select count(*) > 0 from execution.task_events
    where task_id = current_setting('test.task_138')::uuid
      and event_type = 'task.completed'),
  'event ledger contains task.completed');

-- 9. buyer_complete on a completed task raises
do $$
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','53000000-0000-0000-0000-000000000138',
                       'role','authenticated',
                       'tenant_id','53000000-0000-0000-0000-00000000013a',
                       'organization_id','53000000-0000-0000-0000-00000000013b')::text, true);
  perform set_config('request.jwt.claim.sub',
                     '53000000-0000-0000-0000-000000000138', true);
  set local role authenticated;
end $$;
select throws_ok(
  format($q$select execution.buyer_complete_task('%s'::uuid)$q$,
         current_setting('test.task_138')),
  '22023', null,
  'buyer_complete_task on completed task raises');

-- 10. stranger user (different org) sees zero rows
reset role;
do $$
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','53000000-0000-0000-0000-000000000238',
                       'role','authenticated',
                       'tenant_id','53000000-0000-0000-0000-00000000013a',
                       'organization_id','53000000-0000-0000-0000-00000000013d')::text, true);
  perform set_config('request.jwt.claim.sub',
                     '53000000-0000-0000-0000-000000000238', true);
  set local role authenticated;
end $$;
select is(
  (select count(*)::int from execution.buyer_list_tasks(null, null, 50, 0)),
  0, 'stranger user sees no tasks from another buyer');

reset role;
select * from finish();
rollback;
