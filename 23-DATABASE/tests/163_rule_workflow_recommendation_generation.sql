-- CC-68 Test 163 — recommendation generation from matched rules
--
-- Assertions (6):
--   1.  evaluate_shipment_workflow_recommendations returns a jsonb object
--   2.  recommendation_count >= 1
--   3.  recommendation row persisted for the shipment
--   4.  workflow_recommendation.created event written
--   5.  persisted confidence_score = 85
--   6.  re-running does not duplicate the open recommendation

set search_path = extensions, public, identity, organization, audit, supplier,
                  commodity, rfq, offer, evaluation, contract, shipment, notify,
                  marketplace, dispatch, telematics, execution, workflow, rules, tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '55000000-0000-0000-0000-000000000163', 'authenticated','authenticated','163-admin@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '55000000-0000-0000-0000-000000000263', 'authenticated','authenticated','163-buyer@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('55000000-0000-0000-0000-000000000163', 'tenant-163', 'تست', 'Test 163');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status, country_code) values
  ('55000000-0000-0000-0000-000000000a63', '55000000-0000-0000-0000-000000000163',
   'buy-163', 'خریدار', 'Buyer 163', 'buyer', 'active', 'IR'),
  ('55000000-0000-0000-0000-000000000b63', '55000000-0000-0000-0000-000000000163',
   'sup-163', 'تأمین', 'Supplier 163', 'supplier', 'active', 'IR');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('55000000-0000-0000-0000-000000000163', '55000000-0000-0000-0000-000000000163',
   '55000000-0000-0000-0000-000000000a63', 'Admin 163', 'fa', 'active'),
  ('55000000-0000-0000-0000-000000000263', '55000000-0000-0000-0000-000000000163',
   '55000000-0000-0000-0000-000000000a63', 'Buyer 163', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '55000000-0000-0000-0000-000000000163', '55000000-0000-0000-0000-000000000a63',
       '55000000-0000-0000-0000-000000000263', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '55000000-0000-0000-0000-000000000163', r.id, 'platform', null
  from identity.roles r where r.code = 'platform_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '55000000-0000-0000-0000-000000000263', r.id, 'organization',
       '55000000-0000-0000-0000-000000000a63'
  from identity.roles r where r.code = 'buyer_admin';

-- Shipment chain (road -> TR)
insert into rfq.requests (id, tenant_id, organization_id, requester_user_id, rfq_code, title, status, visibility, preferred_currency)
values ('55000000-0000-0000-0000-000000000663', '55000000-0000-0000-0000-000000000163',
        '55000000-0000-0000-0000-000000000a63', '55000000-0000-0000-0000-000000000263',
        'RFQ-163', 'Stub', 'submitted', 'private_invited', 'USD');
insert into offer.supplier_offers (id, tenant_id, organization_id, request_id, supplier_id, offer_code, currency, status)
values ('55000000-0000-0000-0000-000000000763', '55000000-0000-0000-0000-000000000163',
        '55000000-0000-0000-0000-000000000b63', '55000000-0000-0000-0000-000000000663',
        (select id from supplier.suppliers where organization_id = '55000000-0000-0000-0000-000000000b63'),
        'OF-163', 'USD', 'submitted');
insert into evaluation.offer_decisions (id, tenant_id, organization_id, request_id, offer_id, decision_status)
values ('55000000-0000-0000-0000-000000000863', '55000000-0000-0000-0000-000000000163',
        '55000000-0000-0000-0000-000000000a63', '55000000-0000-0000-0000-000000000663',
        '55000000-0000-0000-0000-000000000763', 'selected_for_contract');
insert into contract.contract_preparations (id, tenant_id, organization_id, request_id, offer_id, decision_id, supplier_id, preparation_code, title, status)
values ('55000000-0000-0000-0000-000000000963', '55000000-0000-0000-0000-000000000163',
        '55000000-0000-0000-0000-000000000a63', '55000000-0000-0000-0000-000000000663',
        '55000000-0000-0000-0000-000000000763', '55000000-0000-0000-0000-000000000863',
        (select id from supplier.suppliers where organization_id = '55000000-0000-0000-0000-000000000b63'),
        'PREP-163', 'Prep', 'ready_for_contract');
insert into contract.executed_contracts (id, tenant_id, organization_id, preparation_id, request_id, offer_id, decision_id, supplier_id, contract_code, status, contract_type, title, currency, executed_at)
values ('55000000-0000-0000-0000-000000000c63', '55000000-0000-0000-0000-000000000163',
        '55000000-0000-0000-0000-000000000a63', '55000000-0000-0000-0000-000000000963',
        '55000000-0000-0000-0000-000000000663', '55000000-0000-0000-0000-000000000763',
        '55000000-0000-0000-0000-000000000863',
        (select id from supplier.suppliers where organization_id = '55000000-0000-0000-0000-000000000b63'),
        'CTR-163', 'executed', 'spot', 'CT-163', 'USD', now());
insert into shipment.shipments (id, tenant_id, organization_id, executed_contract_id, request_id, offer_id, supplier_id, shipment_code, status, transport_mode, origin_country, destination_country, planned_pickup_date)
values ('55000000-0000-0000-0000-000000000d63', '55000000-0000-0000-0000-000000000163',
        '55000000-0000-0000-0000-000000000a63', '55000000-0000-0000-0000-000000000c63',
        '55000000-0000-0000-0000-000000000663', '55000000-0000-0000-0000-000000000763',
        (select id from supplier.suppliers where organization_id = '55000000-0000-0000-0000-000000000b63'),
        'SH-163', 'planned', 'road', 'IR', 'TR', now() + interval '7 days');

-- Admin builds an active workflow template + an active recommendation rule
-- whose effect points at the template, then runs the bridge.
do $$
declare
  v_tpl    uuid;
  v_step   uuid;
  v_rs     uuid;
  v_rule   uuid;
  v_result jsonb;
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','55000000-0000-0000-0000-000000000163',
                       'role','authenticated',
                       'tenant_id','55000000-0000-0000-0000-000000000163')::text, true);
  perform set_config('request.jwt.claim.sub',
                     '55000000-0000-0000-0000-000000000163', true);
  set local role authenticated;

  v_tpl := workflow.admin_create_template('WF-163','Ocean Prep','d','shipment','shipment','{}'::jsonb);
  v_step := workflow.admin_add_step(v_tpl,'S1','Collect docs');
  perform workflow.admin_activate_template(v_tpl);

  v_rs := rules.admin_create_rule_set('RS-163','Set','d','shipment',100,'{}'::jsonb);
  v_rule := rules.admin_create_rule(v_rs,'R-163','Road needs prep',null,
    'shipment','recommendation',100,
    jsonb_build_object('all', jsonb_build_array(
      jsonb_build_object('path','shipment.transport_mode','op','eq','value','road')
    )),
    jsonb_build_object(
      'workflow_template_id', v_tpl::text,
      'recommendation_reason', 'Road shipment needs prep workflow',
      'confidence_score', 85),
    '{}'::jsonb);
  perform rules.admin_activate_rule_set(v_rs);
  perform rules.admin_activate_rule(v_rule);

  v_result := rules.evaluate_shipment_workflow_recommendations(
    '55000000-0000-0000-0000-000000000d63'::uuid, '{}'::jsonb, true);
  perform set_config('test.result_163', v_result::text, true);

  -- Second run to prove dedup of the open recommendation.
  perform rules.evaluate_shipment_workflow_recommendations(
    '55000000-0000-0000-0000-000000000d63'::uuid, '{}'::jsonb, true);

  reset role;
end $$;

select plan(6);

-- 1
select is(
  jsonb_typeof(current_setting('test.result_163', true)::jsonb),
  'object', 'evaluate_shipment_workflow_recommendations returns a jsonb object');

-- 2
select cmp_ok(
  ((current_setting('test.result_163', true)::jsonb) ->> 'recommendation_count')::int,
  '>=', 1, 'recommendation_count >= 1');

-- 3
select cmp_ok(
  (select count(*)::int from rules.workflow_recommendations
    where shipment_id = '55000000-0000-0000-0000-000000000d63'),
  '>=', 1, 'recommendation row persisted for the shipment');

-- 4
select cmp_ok(
  (select count(*)::int from rules.workflow_recommendation_events e
    join rules.workflow_recommendations wr on wr.id = e.recommendation_id
   where wr.shipment_id = '55000000-0000-0000-0000-000000000d63'
     and e.event_type = 'workflow_recommendation.created'),
  '>=', 1, 'workflow_recommendation.created event written');

-- 5
select is(
  (select confidence_score from rules.workflow_recommendations
    where shipment_id = '55000000-0000-0000-0000-000000000d63' limit 1),
  85::numeric, 'persisted confidence_score = 85');

-- 6
select is(
  (select count(*)::int from rules.workflow_recommendations
    where shipment_id = '55000000-0000-0000-0000-000000000d63' and status = 'open'),
  1, 're-running does not duplicate the open recommendation');

select * from finish();
rollback;
