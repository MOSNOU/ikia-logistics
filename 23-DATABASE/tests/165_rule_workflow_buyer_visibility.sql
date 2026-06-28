-- CC-68 Test 165 — buyer visibility + carrier/supplier denial
--
-- Assertions (5):
--   1.  buyer (owning org) lists own shipment recommendations
--   2.  buyer gets own recommendation
--   3.  unrelated buyer is denied listing
--   4.  supplier-org member on the shipment is denied (no CC-68 visibility)
--   5.  carrier-org member on the shipment is denied (no CC-68 visibility)

set search_path = extensions, public, identity, organization, audit, supplier,
                  commodity, rfq, offer, evaluation, contract, shipment, notify,
                  marketplace, dispatch, telematics, execution, workflow, rules, tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000','55000000-0000-0000-0000-000000000165','authenticated','authenticated','165-admin@example.com'),
  ('00000000-0000-0000-0000-000000000000','55000000-0000-0000-0000-000000000265','authenticated','authenticated','165-buyer-a@example.com'),
  ('00000000-0000-0000-0000-000000000000','55000000-0000-0000-0000-000000000365','authenticated','authenticated','165-buyer-b@example.com'),
  ('00000000-0000-0000-0000-000000000000','55000000-0000-0000-0000-000000000465','authenticated','authenticated','165-supplier@example.com'),
  ('00000000-0000-0000-0000-000000000000','55000000-0000-0000-0000-000000000565','authenticated','authenticated','165-carrier@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('55000000-0000-0000-0000-000000000165', 'tenant-165', 'تست', 'Test 165');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status, country_code) values
  ('55000000-0000-0000-0000-000000000a65','55000000-0000-0000-0000-000000000165','buy-165-a','خریدار الف','Buyer A','buyer','active','IR'),
  ('55000000-0000-0000-0000-000000000b65','55000000-0000-0000-0000-000000000165','buy-165-b','خریدار ب','Buyer B','buyer','active','IR'),
  ('55000000-0000-0000-0000-000000000c65','55000000-0000-0000-0000-000000000165','sup-165','تأمین','Supplier 165','supplier','active','IR'),
  ('55000000-0000-0000-0000-000000000e65','55000000-0000-0000-0000-000000000165','car-165','حامل','Carrier 165','carrier','active','IR');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('55000000-0000-0000-0000-000000000165','55000000-0000-0000-0000-000000000165','55000000-0000-0000-0000-000000000a65','Admin 165','fa','active'),
  ('55000000-0000-0000-0000-000000000265','55000000-0000-0000-0000-000000000165','55000000-0000-0000-0000-000000000a65','Buyer A','fa','active'),
  ('55000000-0000-0000-0000-000000000365','55000000-0000-0000-0000-000000000165','55000000-0000-0000-0000-000000000b65','Buyer B','fa','active'),
  ('55000000-0000-0000-0000-000000000465','55000000-0000-0000-0000-000000000165','55000000-0000-0000-0000-000000000c65','Supplier U','fa','active'),
  ('55000000-0000-0000-0000-000000000565','55000000-0000-0000-0000-000000000165','55000000-0000-0000-0000-000000000e65','Carrier U','fa','active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '55000000-0000-0000-0000-000000000165','55000000-0000-0000-0000-000000000a65','55000000-0000-0000-0000-000000000265', r.id,'active',now() from identity.roles r where r.code='buyer_admin';
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '55000000-0000-0000-0000-000000000165','55000000-0000-0000-0000-000000000b65','55000000-0000-0000-0000-000000000365', r.id,'active',now() from identity.roles r where r.code='buyer_admin';
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '55000000-0000-0000-0000-000000000165','55000000-0000-0000-0000-000000000c65','55000000-0000-0000-0000-000000000465', r.id,'active',now() from identity.roles r where r.code='supplier_admin';
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '55000000-0000-0000-0000-000000000165','55000000-0000-0000-0000-000000000e65','55000000-0000-0000-0000-000000000565', r.id,'active',now() from identity.roles r where r.code='carrier_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '55000000-0000-0000-0000-000000000165', r.id, 'platform', null from identity.roles r where r.code='platform_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '55000000-0000-0000-0000-000000000265', r.id, 'organization','55000000-0000-0000-0000-000000000a65' from identity.roles r where r.code='buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '55000000-0000-0000-0000-000000000365', r.id, 'organization','55000000-0000-0000-0000-000000000b65' from identity.roles r where r.code='buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '55000000-0000-0000-0000-000000000465', r.id, 'organization','55000000-0000-0000-0000-000000000c65' from identity.roles r where r.code='supplier_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '55000000-0000-0000-0000-000000000565', r.id, 'organization','55000000-0000-0000-0000-000000000e65' from identity.roles r where r.code='carrier_admin';

-- Shipment A: buyer A owns, supplier + carrier orgs attached.
insert into rfq.requests (id, tenant_id, organization_id, requester_user_id, rfq_code, title, status, visibility, preferred_currency)
values ('55000000-0000-0000-0000-000000000665','55000000-0000-0000-0000-000000000165','55000000-0000-0000-0000-000000000a65','55000000-0000-0000-0000-000000000265','RFQ-165','A','submitted','private_invited','USD');
insert into offer.supplier_offers (id, tenant_id, organization_id, request_id, supplier_id, offer_code, currency, status)
values ('55000000-0000-0000-0000-000000000765','55000000-0000-0000-0000-000000000165','55000000-0000-0000-0000-000000000c65','55000000-0000-0000-0000-000000000665',
        (select id from supplier.suppliers where organization_id='55000000-0000-0000-0000-000000000c65'),'OF-165','USD','submitted');
insert into evaluation.offer_decisions (id, tenant_id, organization_id, request_id, offer_id, decision_status)
values ('55000000-0000-0000-0000-000000000865','55000000-0000-0000-0000-000000000165','55000000-0000-0000-0000-000000000a65','55000000-0000-0000-0000-000000000665','55000000-0000-0000-0000-000000000765','selected_for_contract');
insert into contract.contract_preparations (id, tenant_id, organization_id, request_id, offer_id, decision_id, supplier_id, preparation_code, title, status)
values ('55000000-0000-0000-0000-000000000965','55000000-0000-0000-0000-000000000165','55000000-0000-0000-0000-000000000a65','55000000-0000-0000-0000-000000000665','55000000-0000-0000-0000-000000000765','55000000-0000-0000-0000-000000000865',
        (select id from supplier.suppliers where organization_id='55000000-0000-0000-0000-000000000c65'),'PREP-165','Prep','ready_for_contract');
insert into contract.executed_contracts (id, tenant_id, organization_id, preparation_id, request_id, offer_id, decision_id, supplier_id, contract_code, status, contract_type, title, currency, executed_at)
values ('55000000-0000-0000-0000-000000000d65','55000000-0000-0000-0000-000000000165','55000000-0000-0000-0000-000000000a65','55000000-0000-0000-0000-000000000965','55000000-0000-0000-0000-000000000665','55000000-0000-0000-0000-000000000765','55000000-0000-0000-0000-000000000865',
        (select id from supplier.suppliers where organization_id='55000000-0000-0000-0000-000000000c65'),'CTR-165','executed','spot','CT-165','USD',now());
insert into shipment.shipments (id, tenant_id, organization_id, supplier_organization_id, carrier_organization_id, executed_contract_id, request_id, offer_id, supplier_id, shipment_code, status, transport_mode, origin_country, destination_country, planned_pickup_date)
values ('55000000-0000-0000-0000-000000000f65','55000000-0000-0000-0000-000000000165','55000000-0000-0000-0000-000000000a65','55000000-0000-0000-0000-000000000c65','55000000-0000-0000-0000-000000000e65','55000000-0000-0000-0000-000000000d65','55000000-0000-0000-0000-000000000665','55000000-0000-0000-0000-000000000765',
        (select id from supplier.suppliers where organization_id='55000000-0000-0000-0000-000000000c65'),'SH-165','planned','road','IR','TR',now()+interval '7 days');

-- Admin builds template + recommendation rule and generates the recommendation.
do $$
declare v_tpl uuid; v_step uuid; v_rs uuid; v_rule uuid; v_res jsonb;
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','55000000-0000-0000-0000-000000000165','role','authenticated',
                       'tenant_id','55000000-0000-0000-0000-000000000165')::text, true);
  perform set_config('request.jwt.claim.sub','55000000-0000-0000-0000-000000000165', true);
  set local role authenticated;
  v_tpl := workflow.admin_create_template('WF-165','Prep','d','shipment','shipment','{}'::jsonb);
  v_step := workflow.admin_add_step(v_tpl,'S1','Step');
  perform workflow.admin_activate_template(v_tpl);
  v_rs := rules.admin_create_rule_set('RS-165','Set','d','shipment',100,'{}'::jsonb);
  v_rule := rules.admin_create_rule(v_rs,'R-165','Road',null,'shipment','recommendation',100,
    jsonb_build_object('all', jsonb_build_array(
      jsonb_build_object('path','shipment.transport_mode','op','eq','value','road'))),
    jsonb_build_object('workflow_template_id', v_tpl::text, 'confidence_score', 70),
    '{}'::jsonb);
  perform rules.admin_activate_rule_set(v_rs);
  perform rules.admin_activate_rule(v_rule);
  v_res := rules.evaluate_shipment_workflow_recommendations(
    '55000000-0000-0000-0000-000000000f65'::uuid, '{}'::jsonb, true);
  perform set_config('test.rec_id_165',
    ((v_res -> 'recommendations' -> 0) ->> 'recommendation_id'), true);
  reset role;
end $$;

select plan(5);

-- 1: buyer A lists own shipment recommendations
do $$
declare v_count int;
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','55000000-0000-0000-0000-000000000265','role','authenticated',
                       'tenant_id','55000000-0000-0000-0000-000000000165',
                       'organization_id','55000000-0000-0000-0000-000000000a65')::text, true);
  perform set_config('request.jwt.claim.sub','55000000-0000-0000-0000-000000000265', true);
  set local role authenticated;
  select count(*)::int into v_count
    from rules.buyer_list_workflow_recommendations('55000000-0000-0000-0000-000000000f65'::uuid, null, 50, 0);
  reset role;
  perform set_config('test.buyer_a_count_165', v_count::text, true);
end $$;
select cmp_ok(
  current_setting('test.buyer_a_count_165', true)::int, '>=', 1,
  'buyer lists own shipment recommendations');

-- 2: buyer A gets own recommendation
do $$
declare v_json jsonb;
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','55000000-0000-0000-0000-000000000265','role','authenticated',
                       'tenant_id','55000000-0000-0000-0000-000000000165',
                       'organization_id','55000000-0000-0000-0000-000000000a65')::text, true);
  perform set_config('request.jwt.claim.sub','55000000-0000-0000-0000-000000000265', true);
  set local role authenticated;
  v_json := rules.buyer_get_workflow_recommendation(current_setting('test.rec_id_165')::uuid);
  reset role;
  perform set_config('test.buyer_a_get_165', (v_json ? 'recommendation')::text, true);
end $$;
select is(
  current_setting('test.buyer_a_get_165', true), 'true',
  'buyer gets own recommendation');

-- 3: unrelated buyer B denied
do $$
declare v_err text := '';
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','55000000-0000-0000-0000-000000000365','role','authenticated',
                       'tenant_id','55000000-0000-0000-0000-000000000165',
                       'organization_id','55000000-0000-0000-0000-000000000b65')::text, true);
  perform set_config('request.jwt.claim.sub','55000000-0000-0000-0000-000000000365', true);
  set local role authenticated;
  begin
    perform * from rules.buyer_list_workflow_recommendations('55000000-0000-0000-0000-000000000f65'::uuid, null, 50, 0);
  exception when others then v_err := SQLERRM; end;
  reset role;
  perform set_config('test.buyer_b_err_165', v_err, true);
end $$;
select isnt(
  current_setting('test.buyer_b_err_165', true), '',
  'unrelated buyer is denied listing');

-- 4: supplier-org member on the shipment denied
do $$
declare v_err text := '';
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','55000000-0000-0000-0000-000000000465','role','authenticated',
                       'tenant_id','55000000-0000-0000-0000-000000000165',
                       'organization_id','55000000-0000-0000-0000-000000000c65')::text, true);
  perform set_config('request.jwt.claim.sub','55000000-0000-0000-0000-000000000465', true);
  set local role authenticated;
  begin
    perform rules.buyer_get_workflow_recommendation(current_setting('test.rec_id_165')::uuid);
  exception when others then v_err := SQLERRM; end;
  reset role;
  perform set_config('test.supplier_err_165', v_err, true);
end $$;
select isnt(
  current_setting('test.supplier_err_165', true), '',
  'supplier-org member on the shipment is denied');

-- 5: carrier-org member on the shipment denied
do $$
declare v_err text := '';
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','55000000-0000-0000-0000-000000000565','role','authenticated',
                       'tenant_id','55000000-0000-0000-0000-000000000165',
                       'organization_id','55000000-0000-0000-0000-000000000e65')::text, true);
  perform set_config('request.jwt.claim.sub','55000000-0000-0000-0000-000000000565', true);
  set local role authenticated;
  begin
    perform rules.buyer_get_workflow_recommendation(current_setting('test.rec_id_165')::uuid);
  exception when others then v_err := SQLERRM; end;
  reset role;
  perform set_config('test.carrier_err_165', v_err, true);
end $$;
select isnt(
  current_setting('test.carrier_err_165', true), '',
  'carrier-org member on the shipment is denied');

select * from finish();
rollback;
