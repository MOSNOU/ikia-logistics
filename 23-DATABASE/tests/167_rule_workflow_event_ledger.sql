-- CC-68 Test 167 — recommendation event ledger immutability + chain
--
-- Assertions (6):
--   1.  authenticated has no INSERT on workflow_recommendation_events
--   2.  UPDATE on workflow_recommendation_events raises (append-only)
--   3.  DELETE on workflow_recommendation_events raises (append-only)
--   4.  workflow_recommendation.created event recorded on generation
--   5.  workflow_recommendation.accepted event recorded on accept
--   6.  workflow_recommendation.dismissed event recorded on dismiss

set search_path = extensions, public, identity, organization, audit, supplier,
                  commodity, rfq, offer, evaluation, contract, shipment, notify,
                  marketplace, dispatch, telematics, execution, workflow, rules, tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000','55000000-0000-0000-0000-000000000167','authenticated','authenticated','167-admin@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('55000000-0000-0000-0000-000000000167', 'tenant-167', 'تست', 'Test 167');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status, country_code) values
  ('55000000-0000-0000-0000-000000000a67','55000000-0000-0000-0000-000000000167','buy-167','خریدار','Buyer 167','buyer','active','IR'),
  ('55000000-0000-0000-0000-000000000b67','55000000-0000-0000-0000-000000000167','sup-167','تأمین','Supplier 167','supplier','active','IR');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('55000000-0000-0000-0000-000000000167','55000000-0000-0000-0000-000000000167','55000000-0000-0000-0000-000000000a67','Admin 167','fa','active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '55000000-0000-0000-0000-000000000167','55000000-0000-0000-0000-000000000a67','55000000-0000-0000-0000-000000000167', r.id,'active',now() from identity.roles r where r.code='buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '55000000-0000-0000-0000-000000000167', r.id, 'platform', null from identity.roles r where r.code='platform_admin';

insert into rfq.requests (id, tenant_id, organization_id, requester_user_id, rfq_code, title, status, visibility, preferred_currency)
values ('55000000-0000-0000-0000-000000000667','55000000-0000-0000-0000-000000000167','55000000-0000-0000-0000-000000000a67','55000000-0000-0000-0000-000000000167','RFQ-167','S','submitted','private_invited','USD');
insert into offer.supplier_offers (id, tenant_id, organization_id, request_id, supplier_id, offer_code, currency, status)
values ('55000000-0000-0000-0000-000000000767','55000000-0000-0000-0000-000000000167','55000000-0000-0000-0000-000000000b67','55000000-0000-0000-0000-000000000667',
        (select id from supplier.suppliers where organization_id='55000000-0000-0000-0000-000000000b67'),'OF-167','USD','submitted');
insert into evaluation.offer_decisions (id, tenant_id, organization_id, request_id, offer_id, decision_status)
values ('55000000-0000-0000-0000-000000000867','55000000-0000-0000-0000-000000000167','55000000-0000-0000-0000-000000000a67','55000000-0000-0000-0000-000000000667','55000000-0000-0000-0000-000000000767','selected_for_contract');
insert into contract.contract_preparations (id, tenant_id, organization_id, request_id, offer_id, decision_id, supplier_id, preparation_code, title, status)
values ('55000000-0000-0000-0000-000000000967','55000000-0000-0000-0000-000000000167','55000000-0000-0000-0000-000000000a67','55000000-0000-0000-0000-000000000667','55000000-0000-0000-0000-000000000767','55000000-0000-0000-0000-000000000867',
        (select id from supplier.suppliers where organization_id='55000000-0000-0000-0000-000000000b67'),'PREP-167','Prep','ready_for_contract');
insert into contract.executed_contracts (id, tenant_id, organization_id, preparation_id, request_id, offer_id, decision_id, supplier_id, contract_code, status, contract_type, title, currency, executed_at)
values ('55000000-0000-0000-0000-000000000c67','55000000-0000-0000-0000-000000000167','55000000-0000-0000-0000-000000000a67','55000000-0000-0000-0000-000000000967','55000000-0000-0000-0000-000000000667','55000000-0000-0000-0000-000000000767','55000000-0000-0000-0000-000000000867',
        (select id from supplier.suppliers where organization_id='55000000-0000-0000-0000-000000000b67'),'CTR-167','executed','spot','CT-167','USD',now());
insert into shipment.shipments (id, tenant_id, organization_id, executed_contract_id, request_id, offer_id, supplier_id, shipment_code, status, transport_mode, origin_country, destination_country, planned_pickup_date)
values ('55000000-0000-0000-0000-000000000d67','55000000-0000-0000-0000-000000000167','55000000-0000-0000-0000-000000000a67','55000000-0000-0000-0000-000000000c67','55000000-0000-0000-0000-000000000667','55000000-0000-0000-0000-000000000767',
        (select id from supplier.suppliers where organization_id='55000000-0000-0000-0000-000000000b67'),'SH-167','planned','road','IR','TR',now()+interval '7 days');

-- Admin builds template + two rules, generates recs, accepts one, dismisses the other.
do $$
declare v_tpl uuid; v_step uuid; v_rs uuid; v_r1 uuid; v_r2 uuid; v_rec1 uuid; v_rec2 uuid;
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','55000000-0000-0000-0000-000000000167','role','authenticated',
                       'tenant_id','55000000-0000-0000-0000-000000000167')::text, true);
  perform set_config('request.jwt.claim.sub','55000000-0000-0000-0000-000000000167', true);
  set local role authenticated;
  v_tpl := workflow.admin_create_template('WF-167','Prep','d','shipment','shipment','{}'::jsonb);
  v_step := workflow.admin_add_step(v_tpl,'S1','Step');
  perform workflow.admin_activate_template(v_tpl);
  v_rs := rules.admin_create_rule_set('RS-167','Set','d','shipment',100,'{}'::jsonb);
  v_r1 := rules.admin_create_rule(v_rs,'R-167-1','Road1',null,'shipment','recommendation',100,
    jsonb_build_object('all', jsonb_build_array(jsonb_build_object('path','shipment.transport_mode','op','eq','value','road'))),
    jsonb_build_object('workflow_template_id', v_tpl::text,'confidence_score',50),'{}'::jsonb);
  v_r2 := rules.admin_create_rule(v_rs,'R-167-2','Road2',null,'shipment','recommendation',100,
    jsonb_build_object('all', jsonb_build_array(jsonb_build_object('path','shipment.transport_mode','op','eq','value','road'))),
    jsonb_build_object('workflow_template_id', v_tpl::text,'confidence_score',50),'{}'::jsonb);
  perform rules.admin_activate_rule_set(v_rs);
  perform rules.admin_activate_rule(v_r1);
  perform rules.admin_activate_rule(v_r2);
  perform rules.evaluate_shipment_workflow_recommendations('55000000-0000-0000-0000-000000000d67'::uuid,'{}'::jsonb,true);
  select id into v_rec1 from rules.workflow_recommendations where shipment_id='55000000-0000-0000-0000-000000000d67' and rule_id=v_r1;
  select id into v_rec2 from rules.workflow_recommendations where shipment_id='55000000-0000-0000-0000-000000000d67' and rule_id=v_r2;
  perform rules.admin_accept_workflow_recommendation(v_rec1, 'ok');
  perform rules.admin_dismiss_workflow_recommendation(v_rec2, 'nope');
  perform set_config('test.rec1_167', v_rec1::text, true);
  perform set_config('test.rec2_167', v_rec2::text, true);
  reset role;
end $$;

select plan(6);

-- 1
select is(
  has_table_privilege('authenticated', 'rules.workflow_recommendation_events', 'INSERT'),
  false, 'authenticated has no INSERT on workflow_recommendation_events');

-- 2: UPDATE blocked
select throws_ok(
  $upd$ update rules.workflow_recommendation_events
           set payload = '{}'::jsonb
         where id = (select id from rules.workflow_recommendation_events
                      where recommendation_id = current_setting('test.rec1_167')::uuid limit 1)
  $upd$,
  '42501', null, 'UPDATE on workflow_recommendation_events raises append-only');

-- 3: DELETE blocked
select throws_ok(
  $del$ delete from rules.workflow_recommendation_events
         where id = (select id from rules.workflow_recommendation_events
                      where recommendation_id = current_setting('test.rec1_167')::uuid limit 1)
  $del$,
  '42501', null, 'DELETE on workflow_recommendation_events raises append-only');

-- 4
select cmp_ok(
  (select count(*)::int from rules.workflow_recommendation_events
    where recommendation_id = current_setting('test.rec1_167')::uuid
      and event_type = 'workflow_recommendation.created'),
  '>=', 1, 'workflow_recommendation.created event recorded on generation');

-- 5
select cmp_ok(
  (select count(*)::int from rules.workflow_recommendation_events
    where recommendation_id = current_setting('test.rec1_167')::uuid
      and event_type = 'workflow_recommendation.accepted'),
  '>=', 1, 'workflow_recommendation.accepted event recorded on accept');

-- 6
select cmp_ok(
  (select count(*)::int from rules.workflow_recommendation_events
    where recommendation_id = current_setting('test.rec2_167')::uuid
      and event_type = 'workflow_recommendation.dismissed'),
  '>=', 1, 'workflow_recommendation.dismissed event recorded on dismiss');

select * from finish();
rollback;
