-- CC-67 Test 159 — buyer visibility + scope gating
--
-- Assertions (8):
--   1.  buyer can evaluate own visible shipment
--   2.  buyer cannot evaluate unrelated shipment (raises 42501)
--   3.  buyer_list_shipment_evaluations returns the previously persisted eval
--   4.  buyer_list_shipment_evaluations returns zero rows on unrelated shipment (raises)
--   5.  buyer_get_evaluation returns own eval
--   6.  buyer_get_evaluation raises for unrelated eval
--   7.  non-admin cannot evaluate workflow scope (admin-only in CC-67)
--   8.  non-admin cannot evaluate marketplace scope (admin-only in CC-67)

set search_path = extensions, public, identity, organization, audit, supplier,
                  commodity, rfq, offer, evaluation, contract, shipment, notify,
                  marketplace, dispatch, telematics, execution, workflow, rules, tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '55000000-0000-0000-0000-000000000159', 'authenticated','authenticated','159-admin@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '55000000-0000-0000-0000-000000000259', 'authenticated','authenticated','159-buyer-a@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '55000000-0000-0000-0000-000000000359', 'authenticated','authenticated','159-buyer-b@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('55000000-0000-0000-0000-000000000159', 'tenant-159', 'تست', 'Test 159');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status, country_code) values
  ('55000000-0000-0000-0000-000000000a59', '55000000-0000-0000-0000-000000000159',
   'buy-159-a', 'خریدار الف', 'Buyer A', 'buyer', 'active', 'IR'),
  ('55000000-0000-0000-0000-000000000b59', '55000000-0000-0000-0000-000000000159',
   'buy-159-b', 'خریدار ب', 'Buyer B', 'buyer', 'active', 'IR'),
  ('55000000-0000-0000-0000-000000000c59', '55000000-0000-0000-0000-000000000159',
   'sup-159', 'تأمین', 'Supplier 159', 'supplier', 'active', 'IR');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('55000000-0000-0000-0000-000000000159', '55000000-0000-0000-0000-000000000159',
   '55000000-0000-0000-0000-000000000a59', 'Admin 159', 'fa', 'active'),
  ('55000000-0000-0000-0000-000000000259', '55000000-0000-0000-0000-000000000159',
   '55000000-0000-0000-0000-000000000a59', 'Buyer A', 'fa', 'active'),
  ('55000000-0000-0000-0000-000000000359', '55000000-0000-0000-0000-000000000159',
   '55000000-0000-0000-0000-000000000b59', 'Buyer B', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '55000000-0000-0000-0000-000000000159', '55000000-0000-0000-0000-000000000a59',
       '55000000-0000-0000-0000-000000000259', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '55000000-0000-0000-0000-000000000159', '55000000-0000-0000-0000-000000000b59',
       '55000000-0000-0000-0000-000000000359', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '55000000-0000-0000-0000-000000000159', r.id, 'platform', null
  from identity.roles r where r.code = 'platform_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '55000000-0000-0000-0000-000000000259', r.id, 'organization',
       '55000000-0000-0000-0000-000000000a59'
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '55000000-0000-0000-0000-000000000359', r.id, 'organization',
       '55000000-0000-0000-0000-000000000b59'
  from identity.roles r where r.code = 'buyer_admin';

-- Shipment A (owned by Buyer A's org)
insert into rfq.requests (id, tenant_id, organization_id, requester_user_id, rfq_code, title, status, visibility, preferred_currency)
values ('55000000-0000-0000-0000-000000000659', '55000000-0000-0000-0000-000000000159',
        '55000000-0000-0000-0000-000000000a59', '55000000-0000-0000-0000-000000000259',
        'RFQ-159A', 'A', 'submitted', 'private_invited', 'USD');
insert into offer.supplier_offers (id, tenant_id, organization_id, request_id, supplier_id, offer_code, currency, status)
values ('55000000-0000-0000-0000-000000000759', '55000000-0000-0000-0000-000000000159',
        '55000000-0000-0000-0000-000000000c59', '55000000-0000-0000-0000-000000000659',
        (select id from supplier.suppliers where organization_id = '55000000-0000-0000-0000-000000000c59'),
        'OF-159A', 'USD', 'submitted');
insert into evaluation.offer_decisions (id, tenant_id, organization_id, request_id, offer_id, decision_status)
values ('55000000-0000-0000-0000-000000000859', '55000000-0000-0000-0000-000000000159',
        '55000000-0000-0000-0000-000000000a59', '55000000-0000-0000-0000-000000000659',
        '55000000-0000-0000-0000-000000000759', 'selected_for_contract');
insert into contract.contract_preparations (id, tenant_id, organization_id, request_id, offer_id, decision_id, supplier_id, preparation_code, title, status)
values ('55000000-0000-0000-0000-000000000959', '55000000-0000-0000-0000-000000000159',
        '55000000-0000-0000-0000-000000000a59', '55000000-0000-0000-0000-000000000659',
        '55000000-0000-0000-0000-000000000759', '55000000-0000-0000-0000-000000000859',
        (select id from supplier.suppliers where organization_id = '55000000-0000-0000-0000-000000000c59'),
        'PREP-159A', 'Prep', 'ready_for_contract');
insert into contract.executed_contracts (id, tenant_id, organization_id, preparation_id, request_id, offer_id, decision_id, supplier_id, contract_code, status, contract_type, title, currency, executed_at)
values ('55000000-0000-0000-0000-000000000d59', '55000000-0000-0000-0000-000000000159',
        '55000000-0000-0000-0000-000000000a59', '55000000-0000-0000-0000-000000000959',
        '55000000-0000-0000-0000-000000000659', '55000000-0000-0000-0000-000000000759',
        '55000000-0000-0000-0000-000000000859',
        (select id from supplier.suppliers where organization_id = '55000000-0000-0000-0000-000000000c59'),
        'CTR-159A', 'executed', 'spot', 'CT-159A', 'USD', now());
insert into shipment.shipments (id, tenant_id, organization_id, executed_contract_id, request_id, offer_id, supplier_id, shipment_code, status, transport_mode, origin_country, destination_country, planned_pickup_date)
values ('55000000-0000-0000-0000-000000000e59', '55000000-0000-0000-0000-000000000159',
        '55000000-0000-0000-0000-000000000a59', '55000000-0000-0000-0000-000000000d59',
        '55000000-0000-0000-0000-000000000659', '55000000-0000-0000-0000-000000000759',
        (select id from supplier.suppliers where organization_id = '55000000-0000-0000-0000-000000000c59'),
        'SH-159A', 'planned', 'road', 'IR', 'TR', now() + interval '7 days');

-- Shipment B (owned by Buyer B's org)
insert into rfq.requests (id, tenant_id, organization_id, requester_user_id, rfq_code, title, status, visibility, preferred_currency)
values ('55000000-0000-0000-0000-000000000f59', '55000000-0000-0000-0000-000000000159',
        '55000000-0000-0000-0000-000000000b59', '55000000-0000-0000-0000-000000000359',
        'RFQ-159B', 'B', 'submitted', 'private_invited', 'USD');
insert into offer.supplier_offers (id, tenant_id, organization_id, request_id, supplier_id, offer_code, currency, status)
values ('55000000-0000-0000-0000-000000001059', '55000000-0000-0000-0000-000000000159',
        '55000000-0000-0000-0000-000000000c59', '55000000-0000-0000-0000-000000000f59',
        (select id from supplier.suppliers where organization_id = '55000000-0000-0000-0000-000000000c59'),
        'OF-159B', 'USD', 'submitted');
insert into evaluation.offer_decisions (id, tenant_id, organization_id, request_id, offer_id, decision_status)
values ('55000000-0000-0000-0000-000000001159', '55000000-0000-0000-0000-000000000159',
        '55000000-0000-0000-0000-000000000b59', '55000000-0000-0000-0000-000000000f59',
        '55000000-0000-0000-0000-000000001059', 'selected_for_contract');
insert into contract.contract_preparations (id, tenant_id, organization_id, request_id, offer_id, decision_id, supplier_id, preparation_code, title, status)
values ('55000000-0000-0000-0000-000000001259', '55000000-0000-0000-0000-000000000159',
        '55000000-0000-0000-0000-000000000b59', '55000000-0000-0000-0000-000000000f59',
        '55000000-0000-0000-0000-000000001059', '55000000-0000-0000-0000-000000001159',
        (select id from supplier.suppliers where organization_id = '55000000-0000-0000-0000-000000000c59'),
        'PREP-159B', 'Prep', 'ready_for_contract');
insert into contract.executed_contracts (id, tenant_id, organization_id, preparation_id, request_id, offer_id, decision_id, supplier_id, contract_code, status, contract_type, title, currency, executed_at)
values ('55000000-0000-0000-0000-000000001359', '55000000-0000-0000-0000-000000000159',
        '55000000-0000-0000-0000-000000000b59', '55000000-0000-0000-0000-000000001259',
        '55000000-0000-0000-0000-000000000f59', '55000000-0000-0000-0000-000000001059',
        '55000000-0000-0000-0000-000000001159',
        (select id from supplier.suppliers where organization_id = '55000000-0000-0000-0000-000000000c59'),
        'CTR-159B', 'executed', 'spot', 'CT-159B', 'USD', now());
insert into shipment.shipments (id, tenant_id, organization_id, executed_contract_id, request_id, offer_id, supplier_id, shipment_code, status, transport_mode, origin_country, destination_country, planned_pickup_date)
values ('55000000-0000-0000-0000-000000001459', '55000000-0000-0000-0000-000000000159',
        '55000000-0000-0000-0000-000000000b59', '55000000-0000-0000-0000-000000001359',
        '55000000-0000-0000-0000-000000000f59', '55000000-0000-0000-0000-000000001059',
        (select id from supplier.suppliers where organization_id = '55000000-0000-0000-0000-000000000c59'),
        'SH-159B', 'planned', 'road', 'IR', 'TR', now() + interval '7 days');

-- Admin sets up a minimal rule set + rule.
do $$
declare v_rs uuid; v_r uuid;
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','55000000-0000-0000-0000-000000000159',
                       'role','authenticated')::text, true);
  perform set_config('request.jwt.claim.sub',
                     '55000000-0000-0000-0000-000000000159', true);
  set local role authenticated;
  v_rs := rules.admin_create_rule_set('RS-159','Set','d','shipment',100,'{}'::jsonb);
  v_r := rules.admin_create_rule(v_rs,'R-159','Road',null,'shipment','recommendation',100,
    jsonb_build_object('all', jsonb_build_array(
      jsonb_build_object('path','shipment.transport_mode','op','eq','value','road')
    )),
    '{}'::jsonb,'{}'::jsonb);
  perform rules.admin_activate_rule_set(v_rs);
  perform rules.admin_activate_rule(v_r);
  reset role;
end $$;

-- Buyer A evaluates own shipment A.
do $$
declare v_result jsonb;
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','55000000-0000-0000-0000-000000000259',
                       'role','authenticated',
                       'tenant_id','55000000-0000-0000-0000-000000000159',
                       'organization_id','55000000-0000-0000-0000-000000000a59')::text, true);
  perform set_config('request.jwt.claim.sub',
                     '55000000-0000-0000-0000-000000000259', true);
  set local role authenticated;
  v_result := rules.evaluate_context(
    'shipment'::rules.rule_scope,
    '55000000-0000-0000-0000-000000000e59'::uuid,
    '{}'::jsonb, true);
  perform set_config('test.eval_a_159', (v_result ->> 'evaluation_id'), true);
  reset role;
end $$;

select plan(8);

-- 1: Buyer A's evaluation returned a non-null evaluation_id
select isnt(
  (select current_setting('test.eval_a_159', true)), '',
  'buyer can evaluate own visible shipment');

-- 2: Buyer A trying to evaluate shipment B raises
do $$
declare v_err text := '';
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','55000000-0000-0000-0000-000000000259',
                       'role','authenticated',
                       'tenant_id','55000000-0000-0000-0000-000000000159',
                       'organization_id','55000000-0000-0000-0000-000000000a59')::text, true);
  perform set_config('request.jwt.claim.sub',
                     '55000000-0000-0000-0000-000000000259', true);
  set local role authenticated;
  begin
    perform rules.evaluate_context(
      'shipment'::rules.rule_scope,
      '55000000-0000-0000-0000-000000001459'::uuid,
      '{}'::jsonb, true);
  exception when others then
    v_err := SQLERRM;
  end;
  reset role;
  perform set_config('test.cross_eval_err', v_err, true);
end $$;
select isnt(
  (select current_setting('test.cross_eval_err', true)), '',
  'buyer cannot evaluate unrelated shipment');

-- 3: buyer_list_shipment_evaluations returns own eval
do $$
declare v_count int;
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','55000000-0000-0000-0000-000000000259',
                       'role','authenticated',
                       'tenant_id','55000000-0000-0000-0000-000000000159',
                       'organization_id','55000000-0000-0000-0000-000000000a59')::text, true);
  perform set_config('request.jwt.claim.sub',
                     '55000000-0000-0000-0000-000000000259', true);
  set local role authenticated;
  select count(*)::int into v_count
    from rules.buyer_list_shipment_evaluations(
      '55000000-0000-0000-0000-000000000e59'::uuid, 50, 0);
  reset role;
  perform set_config('test.own_list_count', v_count::text, true);
end $$;
select cmp_ok(
  (select current_setting('test.own_list_count', true)::int),
  '>=', 1, 'buyer_list_shipment_evaluations returns own eval');

-- 4: buyer A listing on shipment B raises
do $$
declare v_err text := '';
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','55000000-0000-0000-0000-000000000259',
                       'role','authenticated',
                       'tenant_id','55000000-0000-0000-0000-000000000159',
                       'organization_id','55000000-0000-0000-0000-000000000a59')::text, true);
  perform set_config('request.jwt.claim.sub',
                     '55000000-0000-0000-0000-000000000259', true);
  set local role authenticated;
  begin
    perform * from rules.buyer_list_shipment_evaluations(
      '55000000-0000-0000-0000-000000001459'::uuid, 50, 0);
  exception when others then
    v_err := SQLERRM;
  end;
  reset role;
  perform set_config('test.cross_list_err', v_err, true);
end $$;
select isnt(
  (select current_setting('test.cross_list_err', true)), '',
  'buyer_list_shipment_evaluations raises on unrelated shipment');

-- 5: buyer_get_evaluation on own eval returns object
do $$
declare v_json jsonb;
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','55000000-0000-0000-0000-000000000259',
                       'role','authenticated',
                       'tenant_id','55000000-0000-0000-0000-000000000159',
                       'organization_id','55000000-0000-0000-0000-000000000a59')::text, true);
  perform set_config('request.jwt.claim.sub',
                     '55000000-0000-0000-0000-000000000259', true);
  set local role authenticated;
  v_json := rules.buyer_get_evaluation(current_setting('test.eval_a_159')::uuid);
  reset role;
  perform set_config('test.get_own', (v_json ? 'evaluation')::text, true);
end $$;
select is(
  (select current_setting('test.get_own', true)),
  'true', 'buyer_get_evaluation returns own eval');

-- 6: buyer B trying to get buyer A's eval raises
do $$
declare v_err text := '';
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','55000000-0000-0000-0000-000000000359',
                       'role','authenticated',
                       'tenant_id','55000000-0000-0000-0000-000000000159',
                       'organization_id','55000000-0000-0000-0000-000000000b59')::text, true);
  perform set_config('request.jwt.claim.sub',
                     '55000000-0000-0000-0000-000000000359', true);
  set local role authenticated;
  begin
    perform rules.buyer_get_evaluation(current_setting('test.eval_a_159')::uuid);
  exception when others then
    v_err := SQLERRM;
  end;
  reset role;
  perform set_config('test.cross_get_err', v_err, true);
end $$;
select isnt(
  (select current_setting('test.cross_get_err', true)), '',
  'buyer_get_evaluation raises for unrelated eval');

-- 7: non-admin cannot evaluate workflow scope
do $$
declare v_err text := '';
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','55000000-0000-0000-0000-000000000259',
                       'role','authenticated',
                       'tenant_id','55000000-0000-0000-0000-000000000159',
                       'organization_id','55000000-0000-0000-0000-000000000a59')::text, true);
  perform set_config('request.jwt.claim.sub',
                     '55000000-0000-0000-0000-000000000259', true);
  set local role authenticated;
  begin
    perform rules.evaluate_context(
      'workflow'::rules.rule_scope,
      extensions.gen_random_uuid(),
      '{}'::jsonb, true);
  exception when others then
    v_err := SQLERRM;
  end;
  reset role;
  perform set_config('test.workflow_err', v_err, true);
end $$;
select isnt(
  (select current_setting('test.workflow_err', true)), '',
  'non-admin cannot evaluate workflow scope');

-- 8: non-admin cannot evaluate marketplace scope
do $$
declare v_err text := '';
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','55000000-0000-0000-0000-000000000259',
                       'role','authenticated',
                       'tenant_id','55000000-0000-0000-0000-000000000159',
                       'organization_id','55000000-0000-0000-0000-000000000a59')::text, true);
  perform set_config('request.jwt.claim.sub',
                     '55000000-0000-0000-0000-000000000259', true);
  set local role authenticated;
  begin
    perform rules.evaluate_context(
      'marketplace'::rules.rule_scope,
      extensions.gen_random_uuid(),
      '{}'::jsonb, true);
  exception when others then
    v_err := SQLERRM;
  end;
  reset role;
  perform set_config('test.marketplace_err', v_err, true);
end $$;
select isnt(
  (select current_setting('test.marketplace_err', true)), '',
  'non-admin cannot evaluate marketplace scope');

select * from finish();
rollback;
