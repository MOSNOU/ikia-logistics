-- CC-65 Test 141 — task escalations
--
-- Assertions (7):
--   1.  admin_raise_escalation returns a uuid
--   2.  task.escalation_status becomes 'escalated'
--   3.  task_events ledger contains task.escalated
--   4.  admin_resolve_escalation succeeds
--   5.  task.escalation_status becomes 'resolved'
--   6.  task_events ledger contains task.escalation_resolved
--   7.  non-admin cannot raise an escalation

set search_path = extensions, public, identity, organization, audit, supplier,
                  commodity, rfq, offer, evaluation, contract, shipment, notify,
                  marketplace, dispatch, telematics, execution, tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '53000000-0000-0000-0000-000000000141', 'authenticated', 'authenticated','b141@e.com'),
  ('00000000-0000-0000-0000-000000000000',
   '53000000-0000-0000-0000-000000000241', 'service_role', 'service_role','a141@e.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('53000000-0000-0000-0000-00000000021a', 'tenant-141', 'تست', 'Test 141');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status, country_code) values
  ('53000000-0000-0000-0000-00000000021b','53000000-0000-0000-0000-00000000021a',
   'buy-141','خریدار','Buyer 141','buyer','active','IR'),
  ('53000000-0000-0000-0000-00000000021c','53000000-0000-0000-0000-00000000021a',
   'sup-141','تأمین','Supplier 141','supplier','active','IR');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('53000000-0000-0000-0000-000000000141','53000000-0000-0000-0000-00000000021a',
   '53000000-0000-0000-0000-00000000021b','Buyer','fa','active'),
  ('53000000-0000-0000-0000-000000000241','53000000-0000-0000-0000-00000000021a',
   '53000000-0000-0000-0000-00000000021b','Admin','fa','active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '53000000-0000-0000-0000-00000000021a','53000000-0000-0000-0000-00000000021b',
       '53000000-0000-0000-0000-000000000141', r.id,'active',now()
  from identity.roles r where r.code='buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '53000000-0000-0000-0000-000000000141', r.id, 'organization',
       '53000000-0000-0000-0000-00000000021b' from identity.roles r where r.code='buyer_admin';

-- Admin user gets platform-admin role at platform scope.
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '53000000-0000-0000-0000-000000000241', r.id, 'platform', null
  from identity.roles r where r.code='platform_admin';

-- Shipment chain.
insert into rfq.requests (id, tenant_id, organization_id, requester_user_id, rfq_code, title, status, visibility, preferred_currency)
values ('53000000-0000-0000-0000-00000000021d','53000000-0000-0000-0000-00000000021a',
        '53000000-0000-0000-0000-00000000021b','53000000-0000-0000-0000-000000000141',
        'RFQ-141','Stub','submitted','private_invited','USD');
insert into offer.supplier_offers (id, tenant_id, organization_id, request_id, supplier_id, offer_code, currency, status)
values ('53000000-0000-0000-0000-00000000021e','53000000-0000-0000-0000-00000000021a',
        '53000000-0000-0000-0000-00000000021c','53000000-0000-0000-0000-00000000021d',
        (select id from supplier.suppliers where organization_id='53000000-0000-0000-0000-00000000021c'),
        'OF-141','USD','submitted');
insert into evaluation.offer_decisions (id, tenant_id, organization_id, request_id, offer_id, decision_status)
values ('53000000-0000-0000-0000-00000000021f','53000000-0000-0000-0000-00000000021a',
        '53000000-0000-0000-0000-00000000021b','53000000-0000-0000-0000-00000000021d',
        '53000000-0000-0000-0000-00000000021e','selected_for_contract');
insert into contract.contract_preparations (id, tenant_id, organization_id, request_id, offer_id, decision_id, supplier_id, preparation_code, title, status)
values ('53000000-0000-0000-0000-0000000003a1','53000000-0000-0000-0000-00000000021a',
        '53000000-0000-0000-0000-00000000021b','53000000-0000-0000-0000-00000000021d',
        '53000000-0000-0000-0000-00000000021e','53000000-0000-0000-0000-00000000021f',
        (select id from supplier.suppliers where organization_id='53000000-0000-0000-0000-00000000021c'),
        'PREP-141','Prep','ready_for_contract');
insert into contract.executed_contracts (id, tenant_id, organization_id, preparation_id, request_id, offer_id, decision_id, supplier_id, contract_code, status, contract_type, title, currency, executed_at)
values ('53000000-0000-0000-0000-0000000003a2','53000000-0000-0000-0000-00000000021a',
        '53000000-0000-0000-0000-00000000021b','53000000-0000-0000-0000-0000000003a1',
        '53000000-0000-0000-0000-00000000021d','53000000-0000-0000-0000-00000000021e',
        '53000000-0000-0000-0000-00000000021f',
        (select id from supplier.suppliers where organization_id='53000000-0000-0000-0000-00000000021c'),
        'CTR-141','executed','spot','CT-141','USD', now());
insert into shipment.shipments (id, tenant_id, organization_id, executed_contract_id, request_id, offer_id, supplier_id, shipment_code, status, transport_mode, origin_country, destination_country, planned_pickup_date)
values ('53000000-0000-0000-0000-0000000003a3','53000000-0000-0000-0000-00000000021a',
        '53000000-0000-0000-0000-00000000021b','53000000-0000-0000-0000-0000000003a2',
        '53000000-0000-0000-0000-00000000021d','53000000-0000-0000-0000-00000000021e',
        (select id from supplier.suppliers where organization_id='53000000-0000-0000-0000-00000000021c'),
        'SH-141','planned','road','IR','DE', now()+interval '7 days');

-- Buyer creates a task.
do $$
declare v_t uuid;
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','53000000-0000-0000-0000-000000000141',
                       'role','authenticated',
                       'tenant_id','53000000-0000-0000-0000-00000000021a',
                       'organization_id','53000000-0000-0000-0000-00000000021b')::text, true);
  perform set_config('request.jwt.claim.sub','53000000-0000-0000-0000-000000000141', true);
  set local role authenticated;
  v_t := execution.buyer_create_task('53000000-0000-0000-0000-0000000003a3'::uuid, 'Customs paperwork');
  perform set_config('test.t_141', v_t::text, true);
  reset role;
end $$;

-- Admin raises escalation.
do $$
declare v_e uuid;
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','53000000-0000-0000-0000-000000000241',
                       'role','authenticated',
                       'tenant_id','53000000-0000-0000-0000-00000000021a',
                       'organization_id','53000000-0000-0000-0000-00000000021b')::text, true);
  perform set_config('request.jwt.claim.sub','53000000-0000-0000-0000-000000000241', true);
  set local role authenticated;
  v_e := execution.admin_raise_escalation(
    current_setting('test.t_141')::uuid,
    'SLA breach risk',
    'urgent'::execution.task_priority);
  perform set_config('test.e_141', v_e::text, true);
  reset role;
end $$;

select plan(7);

-- 1. escalation id returned
select isnt(
  (select current_setting('test.e_141', true)), '',
  'admin_raise_escalation returns a uuid');

-- 2. task.escalation_status = 'escalated'
select is(
  (select escalation_status::text from execution.shipment_tasks
    where id = current_setting('test.t_141')::uuid),
  'escalated',
  'task.escalation_status becomes escalated');

-- 3. event ledger has task.escalated
select cmp_ok(
  (select count(*)::int from execution.task_events
    where task_id = current_setting('test.t_141')::uuid
      and event_type = 'task.escalated'),
  '>=', 1, 'task_events contains task.escalated');

-- 4. admin resolves
do $$
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','53000000-0000-0000-0000-000000000241',
                       'role','authenticated',
                       'tenant_id','53000000-0000-0000-0000-00000000021a',
                       'organization_id','53000000-0000-0000-0000-00000000021b')::text, true);
  perform set_config('request.jwt.claim.sub','53000000-0000-0000-0000-000000000241', true);
  set local role authenticated;
  perform execution.admin_resolve_escalation(
    current_setting('test.e_141')::uuid,
    'resolved'::execution.escalation_status,
    'Docs cleared');
  reset role;
end $$;
select is(
  (select status::text from execution.task_escalations
    where id = current_setting('test.e_141')::uuid),
  'resolved',
  'escalation status is resolved');

-- 5. task.escalation_status reflects resolution
select is(
  (select escalation_status::text from execution.shipment_tasks
    where id = current_setting('test.t_141')::uuid),
  'resolved',
  'task.escalation_status becomes resolved');

-- 6. event ledger has task.escalation_resolved
select cmp_ok(
  (select count(*)::int from execution.task_events
    where task_id = current_setting('test.t_141')::uuid
      and event_type = 'task.escalation_resolved'),
  '>=', 1, 'task_events contains task.escalation_resolved');

-- 7. non-admin (buyer) cannot raise an escalation
do $$
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','53000000-0000-0000-0000-000000000141',
                       'role','authenticated',
                       'tenant_id','53000000-0000-0000-0000-00000000021a',
                       'organization_id','53000000-0000-0000-0000-00000000021b')::text, true);
  perform set_config('request.jwt.claim.sub','53000000-0000-0000-0000-000000000141', true);
  set local role authenticated;
end $$;
select throws_ok(
  format($q$select execution.admin_raise_escalation('%s'::uuid, 'should fail')$q$,
         current_setting('test.t_141')),
  '42501', null,
  'non-admin cannot raise an escalation');

reset role;
select * from finish();
rollback;
