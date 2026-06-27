-- CC-67 Test 158 — shipment-scope evaluation
--
-- Assertions (8):
--   1.  evaluate_context returns a jsonb result
--   2.  result has matched_count = 1 with two rules (one match, one not)
--   3.  rule_evaluations row persisted
--   4.  rule_evaluation_results count equals active rule count
--   5.  matched result row has status='matched'
--   6.  not_matched result row has status='not_matched'
--   7.  evaluation summary has rule_count
--   8.  rule_events has evaluation.completed event

set search_path = extensions, public, identity, organization, audit, supplier,
                  commodity, rfq, offer, evaluation, contract, shipment, notify,
                  marketplace, dispatch, telematics, execution, workflow, rules, tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '55000000-0000-0000-0000-000000000158', 'authenticated','authenticated','158-admin@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '55000000-0000-0000-0000-000000000258', 'authenticated','authenticated','158-buyer@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('55000000-0000-0000-0000-000000000158', 'tenant-158', 'تست', 'Test 158');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status, country_code) values
  ('55000000-0000-0000-0000-000000000a58', '55000000-0000-0000-0000-000000000158',
   'buy-158', 'خریدار', 'Buyer 158', 'buyer', 'active', 'IR'),
  ('55000000-0000-0000-0000-000000000b58', '55000000-0000-0000-0000-000000000158',
   'sup-158', 'تأمین', 'Supplier 158', 'supplier', 'active', 'IR');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('55000000-0000-0000-0000-000000000158', '55000000-0000-0000-0000-000000000158',
   '55000000-0000-0000-0000-000000000a58', 'Admin 158', 'fa', 'active'),
  ('55000000-0000-0000-0000-000000000258', '55000000-0000-0000-0000-000000000158',
   '55000000-0000-0000-0000-000000000a58', 'Buyer 158', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '55000000-0000-0000-0000-000000000158', '55000000-0000-0000-0000-000000000a58',
       '55000000-0000-0000-0000-000000000258', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '55000000-0000-0000-0000-000000000158', r.id, 'platform', null
  from identity.roles r where r.code = 'platform_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '55000000-0000-0000-0000-000000000258', r.id, 'organization',
       '55000000-0000-0000-0000-000000000a58'
  from identity.roles r where r.code = 'buyer_admin';

-- Shipment chain
insert into rfq.requests (id, tenant_id, organization_id, requester_user_id, rfq_code, title, status, visibility, preferred_currency)
values ('55000000-0000-0000-0000-000000000658', '55000000-0000-0000-0000-000000000158',
        '55000000-0000-0000-0000-000000000a58', '55000000-0000-0000-0000-000000000258',
        'RFQ-158', 'Stub', 'submitted', 'private_invited', 'USD');
insert into offer.supplier_offers (id, tenant_id, organization_id, request_id, supplier_id, offer_code, currency, status)
values ('55000000-0000-0000-0000-000000000758', '55000000-0000-0000-0000-000000000158',
        '55000000-0000-0000-0000-000000000b58', '55000000-0000-0000-0000-000000000658',
        (select id from supplier.suppliers where organization_id = '55000000-0000-0000-0000-000000000b58'),
        'OF-158', 'USD', 'submitted');
insert into evaluation.offer_decisions (id, tenant_id, organization_id, request_id, offer_id, decision_status)
values ('55000000-0000-0000-0000-000000000858', '55000000-0000-0000-0000-000000000158',
        '55000000-0000-0000-0000-000000000a58', '55000000-0000-0000-0000-000000000658',
        '55000000-0000-0000-0000-000000000758', 'selected_for_contract');
insert into contract.contract_preparations (id, tenant_id, organization_id, request_id, offer_id, decision_id, supplier_id, preparation_code, title, status)
values ('55000000-0000-0000-0000-000000000958', '55000000-0000-0000-0000-000000000158',
        '55000000-0000-0000-0000-000000000a58', '55000000-0000-0000-0000-000000000658',
        '55000000-0000-0000-0000-000000000758', '55000000-0000-0000-0000-000000000858',
        (select id from supplier.suppliers where organization_id = '55000000-0000-0000-0000-000000000b58'),
        'PREP-158', 'Prep', 'ready_for_contract');
insert into contract.executed_contracts (id, tenant_id, organization_id, preparation_id, request_id, offer_id, decision_id, supplier_id, contract_code, status, contract_type, title, currency, executed_at)
values ('55000000-0000-0000-0000-000000000c58', '55000000-0000-0000-0000-000000000158',
        '55000000-0000-0000-0000-000000000a58', '55000000-0000-0000-0000-000000000958',
        '55000000-0000-0000-0000-000000000658', '55000000-0000-0000-0000-000000000758',
        '55000000-0000-0000-0000-000000000858',
        (select id from supplier.suppliers where organization_id = '55000000-0000-0000-0000-000000000b58'),
        'CTR-158', 'executed', 'spot', 'CT-158', 'USD', now());
insert into shipment.shipments (id, tenant_id, organization_id, executed_contract_id, request_id, offer_id, supplier_id, shipment_code, status, transport_mode, origin_country, destination_country, planned_pickup_date)
values ('55000000-0000-0000-0000-000000000d58', '55000000-0000-0000-0000-000000000158',
        '55000000-0000-0000-0000-000000000a58', '55000000-0000-0000-0000-000000000c58',
        '55000000-0000-0000-0000-000000000658', '55000000-0000-0000-0000-000000000758',
        (select id from supplier.suppliers where organization_id = '55000000-0000-0000-0000-000000000b58'),
        'SH-158', 'planned', 'road', 'IR', 'TR', now() + interval '7 days');

-- Build a rule set with two rules: one matches, one does not.
do $$
declare v_rs uuid; v_r_match uuid; v_r_nomatch uuid; v_result jsonb;
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','55000000-0000-0000-0000-000000000158',
                       'role','authenticated',
                       'tenant_id','55000000-0000-0000-0000-000000000158')::text, true);
  perform set_config('request.jwt.claim.sub',
                     '55000000-0000-0000-0000-000000000158', true);
  set local role authenticated;

  v_rs := rules.admin_create_rule_set('RS-158','Set','desc','shipment',100,'{}'::jsonb);
  v_r_match := rules.admin_create_rule(v_rs, 'R-MATCH','Road to TR',null,
    'shipment','requirement',100,
    jsonb_build_object('all', jsonb_build_array(
      jsonb_build_object('path','shipment.transport_mode','op','eq','value','road'),
      jsonb_build_object('path','shipment.destination_country','op','eq','value','TR')
    )),
    '{}'::jsonb,'{}'::jsonb);
  v_r_nomatch := rules.admin_create_rule(v_rs, 'R-NOMATCH','Rail only',null,
    'shipment','warning',100,
    jsonb_build_object('all', jsonb_build_array(
      jsonb_build_object('path','shipment.transport_mode','op','eq','value','rail')
    )),
    '{}'::jsonb,'{}'::jsonb);
  perform rules.admin_activate_rule_set(v_rs);
  perform rules.admin_activate_rule(v_r_match);
  perform rules.admin_activate_rule(v_r_nomatch);
  perform set_config('test.rs_158', v_rs::text, true);
  perform set_config('test.r_match_158', v_r_match::text, true);
  perform set_config('test.r_nomatch_158', v_r_nomatch::text, true);

  v_result := rules.evaluate_context(
    'shipment'::rules.rule_scope,
    '55000000-0000-0000-0000-000000000d58'::uuid,
    '{}'::jsonb, true);
  perform set_config('test.result_158', v_result::text, true);
  perform set_config('test.eval_id_158', (v_result ->> 'evaluation_id'), true);

  reset role;
end $$;

select plan(8);

-- 1
select is(
  jsonb_typeof(current_setting('test.result_158', true)::jsonb),
  'object', 'evaluate_context returns a jsonb object');

-- 2
select is(
  ((current_setting('test.result_158', true)::jsonb) ->> 'matched_count')::int,
  1, 'matched_count = 1 with one matching + one non-matching rule');

-- 3
select isnt(
  (select current_setting('test.eval_id_158', true)),
  '', 'rule_evaluations row persisted (evaluation_id returned)');

-- 4
select is(
  (select count(*)::int from rules.rule_evaluation_results
    where evaluation_id = current_setting('test.eval_id_158')::uuid),
  2, 'rule_evaluation_results count equals active rule count');

-- 5
select is(
  (select status::text from rules.rule_evaluation_results
    where evaluation_id = current_setting('test.eval_id_158')::uuid
      and rule_id = current_setting('test.r_match_158')::uuid),
  'matched', 'matched result row has status=matched');

-- 6
select is(
  (select status::text from rules.rule_evaluation_results
    where evaluation_id = current_setting('test.eval_id_158')::uuid
      and rule_id = current_setting('test.r_nomatch_158')::uuid),
  'not_matched', 'not_matched result row has status=not_matched');

-- 7
select is(
  ((select summary from rules.rule_evaluations
     where id = current_setting('test.eval_id_158')::uuid) ->> 'rule_count')::int,
  2, 'evaluation summary has rule_count');

-- 8
select cmp_ok(
  (select count(*)::int from rules.rule_events
    where evaluation_id = current_setting('test.eval_id_158')::uuid
      and event_type = 'evaluation.completed'),
  '>=', 1, 'rule_events has evaluation.completed event');

select * from finish();
rollback;
