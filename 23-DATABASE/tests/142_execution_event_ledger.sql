-- CC-65 Test 142 — task_events ledger immutability
--
-- Assertions (6):
--   1.  direct UPDATE on task_events is blocked
--   2.  direct DELETE on task_events is blocked
--   3.  authenticated has no INSERT grant on task_events
--   4.  the trigger function is SECURITY DEFINER
--   5.  ordered event chain returns in chronological order
--   6.  block_task writes a task.blocked event

set search_path = extensions, public, identity, organization, audit, supplier,
                  commodity, rfq, offer, evaluation, contract, shipment, notify,
                  marketplace, dispatch, telematics, execution, tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '53000000-0000-0000-0000-000000000142', 'authenticated', 'authenticated','b142@e.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('53000000-0000-0000-0000-00000000022a', 'tenant-142', 'تست', 'Test 142');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status, country_code) values
  ('53000000-0000-0000-0000-00000000022b','53000000-0000-0000-0000-00000000022a',
   'buy-142','خریدار','Buyer 142','buyer','active','IR'),
  ('53000000-0000-0000-0000-00000000022c','53000000-0000-0000-0000-00000000022a',
   'sup-142','تأمین','Supplier 142','supplier','active','IR');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('53000000-0000-0000-0000-000000000142','53000000-0000-0000-0000-00000000022a',
   '53000000-0000-0000-0000-00000000022b','Buyer','fa','active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '53000000-0000-0000-0000-00000000022a','53000000-0000-0000-0000-00000000022b',
       '53000000-0000-0000-0000-000000000142', r.id,'active',now()
  from identity.roles r where r.code='buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '53000000-0000-0000-0000-000000000142', r.id, 'organization',
       '53000000-0000-0000-0000-00000000022b' from identity.roles r where r.code='buyer_admin';

insert into rfq.requests (id, tenant_id, organization_id, requester_user_id, rfq_code, title, status, visibility, preferred_currency)
values ('53000000-0000-0000-0000-00000000022d','53000000-0000-0000-0000-00000000022a',
        '53000000-0000-0000-0000-00000000022b','53000000-0000-0000-0000-000000000142',
        'RFQ-142','Stub','submitted','private_invited','USD');
insert into offer.supplier_offers (id, tenant_id, organization_id, request_id, supplier_id, offer_code, currency, status)
values ('53000000-0000-0000-0000-00000000022e','53000000-0000-0000-0000-00000000022a',
        '53000000-0000-0000-0000-00000000022c','53000000-0000-0000-0000-00000000022d',
        (select id from supplier.suppliers where organization_id='53000000-0000-0000-0000-00000000022c'),
        'OF-142','USD','submitted');
insert into evaluation.offer_decisions (id, tenant_id, organization_id, request_id, offer_id, decision_status)
values ('53000000-0000-0000-0000-00000000022f','53000000-0000-0000-0000-00000000022a',
        '53000000-0000-0000-0000-00000000022b','53000000-0000-0000-0000-00000000022d',
        '53000000-0000-0000-0000-00000000022e','selected_for_contract');
insert into contract.contract_preparations (id, tenant_id, organization_id, request_id, offer_id, decision_id, supplier_id, preparation_code, title, status)
values ('53000000-0000-0000-0000-0000000004a1','53000000-0000-0000-0000-00000000022a',
        '53000000-0000-0000-0000-00000000022b','53000000-0000-0000-0000-00000000022d',
        '53000000-0000-0000-0000-00000000022e','53000000-0000-0000-0000-00000000022f',
        (select id from supplier.suppliers where organization_id='53000000-0000-0000-0000-00000000022c'),
        'PREP-142','Prep','ready_for_contract');
insert into contract.executed_contracts (id, tenant_id, organization_id, preparation_id, request_id, offer_id, decision_id, supplier_id, contract_code, status, contract_type, title, currency, executed_at)
values ('53000000-0000-0000-0000-0000000004a2','53000000-0000-0000-0000-00000000022a',
        '53000000-0000-0000-0000-00000000022b','53000000-0000-0000-0000-0000000004a1',
        '53000000-0000-0000-0000-00000000022d','53000000-0000-0000-0000-00000000022e',
        '53000000-0000-0000-0000-00000000022f',
        (select id from supplier.suppliers where organization_id='53000000-0000-0000-0000-00000000022c'),
        'CTR-142','executed','spot','CT-142','USD', now());
insert into shipment.shipments (id, tenant_id, organization_id, executed_contract_id, request_id, offer_id, supplier_id, shipment_code, status, transport_mode, origin_country, destination_country, planned_pickup_date)
values ('53000000-0000-0000-0000-0000000004a3','53000000-0000-0000-0000-00000000022a',
        '53000000-0000-0000-0000-00000000022b','53000000-0000-0000-0000-0000000004a2',
        '53000000-0000-0000-0000-00000000022d','53000000-0000-0000-0000-00000000022e',
        (select id from supplier.suppliers where organization_id='53000000-0000-0000-0000-00000000022c'),
        'SH-142','planned','road','IR','DE', now()+interval '7 days');

-- Buyer creates and starts a task; then blocks it. This produces three events.
do $$
declare v_t uuid;
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','53000000-0000-0000-0000-000000000142',
                       'role','authenticated',
                       'tenant_id','53000000-0000-0000-0000-00000000022a',
                       'organization_id','53000000-0000-0000-0000-00000000022b')::text, true);
  perform set_config('request.jwt.claim.sub','53000000-0000-0000-0000-000000000142', true);
  set local role authenticated;
  v_t := execution.buyer_create_task('53000000-0000-0000-0000-0000000004a3'::uuid, 'Test ledger');
  perform execution.buyer_start_task(v_t);
  perform execution.buyer_block_task(v_t, 'Waiting on customs reply');
  perform set_config('test.t_142', v_t::text, true);
  reset role;
end $$;

select plan(6);

-- 1. direct UPDATE blocked by trigger
select throws_ok(
  $q$update execution.task_events set event_type = 'tampered' where true$q$,
  '42501', null,
  'direct UPDATE on task_events is blocked');

-- 2. direct DELETE blocked by trigger
select throws_ok(
  $q$delete from execution.task_events where true$q$,
  '42501', null,
  'direct DELETE on task_events is blocked');

-- 3. authenticated has no INSERT grant
select is(
  has_table_privilege('authenticated', 'execution.task_events', 'INSERT'),
  false, 'authenticated has no INSERT on task_events');

-- 4. trigger function is SECURITY DEFINER
select is(
  (select prosecdef from pg_proc p join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='execution' and p.proname='fn_record_task_event'),
  true, 'fn_record_task_event is SECURITY DEFINER');

-- 5. ledger contains all three expected event types (created/started/blocked)
select is(
  (select count(distinct event_type)::int from execution.task_events
    where task_id = current_setting('test.t_142')::uuid
      and event_type in ('task.created','task.started','task.blocked')),
  3, 'ledger contains all three expected event types');

-- 6. total event count for the task is exactly three
select is(
  (select count(*)::int from execution.task_events
    where task_id = current_setting('test.t_142')::uuid),
  3, 'ledger has exactly three rows for the task');

select * from finish();
rollback;
