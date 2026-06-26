-- CC-65 Test 140 — task dependency graph
--
-- Assertions (8):
--   1.  insert valid dependency succeeds
--   2.  dependent task cannot start before predecessor completes
--   3.  dependent task can start after predecessor completes
--   4.  self-dependency rejected (check constraint)
--   5.  duplicate dependency rejected (unique constraint)
--   6.  2-node cycle rejected by trigger
--   7.  cross-shipment dependency rejected by trigger
--   8.  fn_task_dependencies_satisfied returns true with no deps

set search_path = extensions, public, identity, organization, audit, supplier,
                  commodity, rfq, offer, evaluation, contract, shipment, notify,
                  marketplace, dispatch, telematics, execution, tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '53000000-0000-0000-0000-000000000140', 'authenticated', 'authenticated','b140@e.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('53000000-0000-0000-0000-00000000020a', 'tenant-140', 'تست', 'Test 140');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status, country_code) values
  ('53000000-0000-0000-0000-00000000020b','53000000-0000-0000-0000-00000000020a',
   'buy-140','خریدار','Buyer 140','buyer','active','IR'),
  ('53000000-0000-0000-0000-00000000020c','53000000-0000-0000-0000-00000000020a',
   'sup-140','تأمین','Supplier 140','supplier','active','IR');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('53000000-0000-0000-0000-000000000140','53000000-0000-0000-0000-00000000020a',
   '53000000-0000-0000-0000-00000000020b','Buyer','fa','active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '53000000-0000-0000-0000-00000000020a','53000000-0000-0000-0000-00000000020b',
       '53000000-0000-0000-0000-000000000140', r.id,'active',now()
  from identity.roles r where r.code='buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '53000000-0000-0000-0000-000000000140', r.id, 'organization',
       '53000000-0000-0000-0000-00000000020b' from identity.roles r where r.code='buyer_admin';

insert into rfq.requests (id, tenant_id, organization_id, requester_user_id, rfq_code, title, status, visibility, preferred_currency)
values ('53000000-0000-0000-0000-00000000020d','53000000-0000-0000-0000-00000000020a',
        '53000000-0000-0000-0000-00000000020b','53000000-0000-0000-0000-000000000140',
        'RFQ-140','Stub','submitted','private_invited','USD');
insert into offer.supplier_offers (id, tenant_id, organization_id, request_id, supplier_id, offer_code, currency, status)
values ('53000000-0000-0000-0000-00000000020e','53000000-0000-0000-0000-00000000020a',
        '53000000-0000-0000-0000-00000000020c','53000000-0000-0000-0000-00000000020d',
        (select id from supplier.suppliers where organization_id='53000000-0000-0000-0000-00000000020c'),
        'OF-140','USD','submitted');
insert into evaluation.offer_decisions (id, tenant_id, organization_id, request_id, offer_id, decision_status)
values ('53000000-0000-0000-0000-00000000020f','53000000-0000-0000-0000-00000000020a',
        '53000000-0000-0000-0000-00000000020b','53000000-0000-0000-0000-00000000020d',
        '53000000-0000-0000-0000-00000000020e','selected_for_contract');
insert into contract.contract_preparations (id, tenant_id, organization_id, request_id, offer_id, decision_id, supplier_id, preparation_code, title, status)
values ('53000000-0000-0000-0000-0000000002a1','53000000-0000-0000-0000-00000000020a',
        '53000000-0000-0000-0000-00000000020b','53000000-0000-0000-0000-00000000020d',
        '53000000-0000-0000-0000-00000000020e','53000000-0000-0000-0000-00000000020f',
        (select id from supplier.suppliers where organization_id='53000000-0000-0000-0000-00000000020c'),
        'PREP-140','Prep','ready_for_contract');
insert into contract.executed_contracts (id, tenant_id, organization_id, preparation_id, request_id, offer_id, decision_id, supplier_id, contract_code, status, contract_type, title, currency, executed_at)
values ('53000000-0000-0000-0000-0000000002a2','53000000-0000-0000-0000-00000000020a',
        '53000000-0000-0000-0000-00000000020b','53000000-0000-0000-0000-0000000002a1',
        '53000000-0000-0000-0000-00000000020d','53000000-0000-0000-0000-00000000020e',
        '53000000-0000-0000-0000-00000000020f',
        (select id from supplier.suppliers where organization_id='53000000-0000-0000-0000-00000000020c'),
        'CTR-140','executed','spot','CT-140','USD', now());
insert into shipment.shipments (id, tenant_id, organization_id, executed_contract_id, request_id, offer_id, supplier_id, shipment_code, status, transport_mode, origin_country, destination_country, planned_pickup_date)
values
  ('53000000-0000-0000-0000-0000000002a3','53000000-0000-0000-0000-00000000020a',
   '53000000-0000-0000-0000-00000000020b','53000000-0000-0000-0000-0000000002a2',
   '53000000-0000-0000-0000-00000000020d','53000000-0000-0000-0000-00000000020e',
   (select id from supplier.suppliers where organization_id='53000000-0000-0000-0000-00000000020c'),
   'SH-140A','planned','road','IR','DE', now()+interval '7 days'),
  ('53000000-0000-0000-0000-0000000002a4','53000000-0000-0000-0000-00000000020a',
   '53000000-0000-0000-0000-00000000020b','53000000-0000-0000-0000-0000000002a2',
   '53000000-0000-0000-0000-00000000020d','53000000-0000-0000-0000-00000000020e',
   (select id from supplier.suppliers where organization_id='53000000-0000-0000-0000-00000000020c'),
   'SH-140B','planned','road','IR','DE', now()+interval '7 days');

-- Create three tasks: A (shipment 1), B (shipment 1), C (shipment 2).
do $$
declare v_a uuid; v_b uuid; v_c uuid;
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','53000000-0000-0000-0000-000000000140',
                       'role','authenticated',
                       'tenant_id','53000000-0000-0000-0000-00000000020a',
                       'organization_id','53000000-0000-0000-0000-00000000020b')::text, true);
  perform set_config('request.jwt.claim.sub','53000000-0000-0000-0000-000000000140', true);
  set local role authenticated;
  v_a := execution.buyer_create_task('53000000-0000-0000-0000-0000000002a3'::uuid, 'A');
  v_b := execution.buyer_create_task('53000000-0000-0000-0000-0000000002a3'::uuid, 'B');
  v_c := execution.buyer_create_task('53000000-0000-0000-0000-0000000002a4'::uuid, 'C');
  perform set_config('test.t_a_140', v_a::text, true);
  perform set_config('test.t_b_140', v_b::text, true);
  perform set_config('test.t_c_140', v_c::text, true);
  reset role;
end $$;

select plan(8);

-- 1. Insert valid dependency: B depends on A.
select lives_ok(
  format($q$insert into execution.task_dependencies (tenant_id, task_id, depends_on_task_id)
            values ('53000000-0000-0000-0000-00000000020a', '%s', '%s')$q$,
         current_setting('test.t_b_140'), current_setting('test.t_a_140')),
  'valid dependency insert succeeds');

-- 2. B cannot start before A is completed
do $$
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','53000000-0000-0000-0000-000000000140',
                       'role','authenticated',
                       'tenant_id','53000000-0000-0000-0000-00000000020a',
                       'organization_id','53000000-0000-0000-0000-00000000020b')::text, true);
  perform set_config('request.jwt.claim.sub','53000000-0000-0000-0000-000000000140', true);
  set local role authenticated;
end $$;
select throws_ok(
  format($q$select execution.buyer_start_task('%s'::uuid)$q$,
         current_setting('test.t_b_140')),
  '22023', null,
  'B cannot start before A completes');

-- 3. Complete A, then B can start
do $$
begin
  perform execution.buyer_start_task(current_setting('test.t_a_140')::uuid);
  perform execution.buyer_complete_task(current_setting('test.t_a_140')::uuid);
end $$;
select is(
  (execution.buyer_start_task(current_setting('test.t_b_140')::uuid)).status::text,
  'in_progress',
  'B starts once A is completed');

reset role;

-- 4. Self-dependency rejected
select throws_ok(
  format($q$insert into execution.task_dependencies (tenant_id, task_id, depends_on_task_id)
            values ('53000000-0000-0000-0000-00000000020a', '%s', '%s')$q$,
         current_setting('test.t_a_140'), current_setting('test.t_a_140')),
  '23514', null,
  'self-dependency rejected by check constraint');

-- 5. Duplicate dependency rejected
select throws_ok(
  format($q$insert into execution.task_dependencies (tenant_id, task_id, depends_on_task_id)
            values ('53000000-0000-0000-0000-00000000020a', '%s', '%s')$q$,
         current_setting('test.t_b_140'), current_setting('test.t_a_140')),
  '23505', null,
  'duplicate dependency rejected by unique constraint');

-- 6. 2-node cycle: try inserting A depends on B (B already depends on A)
select throws_ok(
  format($q$insert into execution.task_dependencies (tenant_id, task_id, depends_on_task_id)
            values ('53000000-0000-0000-0000-00000000020a', '%s', '%s')$q$,
         current_setting('test.t_a_140'), current_setting('test.t_b_140')),
  '22023', null,
  '2-node cycle rejected by trigger');

-- 7. Cross-shipment dependency rejected
select throws_ok(
  format($q$insert into execution.task_dependencies (tenant_id, task_id, depends_on_task_id)
            values ('53000000-0000-0000-0000-00000000020a', '%s', '%s')$q$,
         current_setting('test.t_a_140'), current_setting('test.t_c_140')),
  '22023', null,
  'cross-shipment dependency rejected by trigger');

-- 8. fn_task_dependencies_satisfied returns true for a task with no deps
select is(
  execution.fn_task_dependencies_satisfied(current_setting('test.t_c_140')::uuid),
  true, 'task with no deps is satisfied');

select * from finish();
rollback;
