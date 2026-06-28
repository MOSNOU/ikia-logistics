-- CC-68 Test 166 — recommendation accept/dismiss lifecycle
--
-- Assertions (6):
--   1.  buyer accept sets status = accepted
--   2.  accept does NOT create a workflow instance
--   3.  accepting a terminal recommendation again raises
--   4.  admin dismiss sets status=dismissed with dismissed_at + reason
--   5.  dismissing a terminal recommendation again raises
--   6.  dismiss with empty reason raises

set search_path = extensions, public, identity, organization, audit, supplier,
                  commodity, rfq, offer, evaluation, contract, shipment, notify,
                  marketplace, dispatch, telematics, execution, workflow, rules, tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000','55000000-0000-0000-0000-000000000166','authenticated','authenticated','166-admin@example.com'),
  ('00000000-0000-0000-0000-000000000000','55000000-0000-0000-0000-000000000266','authenticated','authenticated','166-buyer@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('55000000-0000-0000-0000-000000000166', 'tenant-166', 'تست', 'Test 166');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status, country_code) values
  ('55000000-0000-0000-0000-000000000a66','55000000-0000-0000-0000-000000000166','buy-166','خریدار','Buyer 166','buyer','active','IR'),
  ('55000000-0000-0000-0000-000000000b66','55000000-0000-0000-0000-000000000166','sup-166','تأمین','Supplier 166','supplier','active','IR');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('55000000-0000-0000-0000-000000000166','55000000-0000-0000-0000-000000000166','55000000-0000-0000-0000-000000000a66','Admin 166','fa','active'),
  ('55000000-0000-0000-0000-000000000266','55000000-0000-0000-0000-000000000166','55000000-0000-0000-0000-000000000a66','Buyer 166','fa','active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '55000000-0000-0000-0000-000000000166','55000000-0000-0000-0000-000000000a66','55000000-0000-0000-0000-000000000266', r.id,'active',now() from identity.roles r where r.code='buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '55000000-0000-0000-0000-000000000166', r.id, 'platform', null from identity.roles r where r.code='platform_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '55000000-0000-0000-0000-000000000266', r.id, 'organization','55000000-0000-0000-0000-000000000a66' from identity.roles r where r.code='buyer_admin';

insert into rfq.requests (id, tenant_id, organization_id, requester_user_id, rfq_code, title, status, visibility, preferred_currency)
values ('55000000-0000-0000-0000-000000000666','55000000-0000-0000-0000-000000000166','55000000-0000-0000-0000-000000000a66','55000000-0000-0000-0000-000000000266','RFQ-166','S','submitted','private_invited','USD');
insert into offer.supplier_offers (id, tenant_id, organization_id, request_id, supplier_id, offer_code, currency, status)
values ('55000000-0000-0000-0000-000000000766','55000000-0000-0000-0000-000000000166','55000000-0000-0000-0000-000000000b66','55000000-0000-0000-0000-000000000666',
        (select id from supplier.suppliers where organization_id='55000000-0000-0000-0000-000000000b66'),'OF-166','USD','submitted');
insert into evaluation.offer_decisions (id, tenant_id, organization_id, request_id, offer_id, decision_status)
values ('55000000-0000-0000-0000-000000000866','55000000-0000-0000-0000-000000000166','55000000-0000-0000-0000-000000000a66','55000000-0000-0000-0000-000000000666','55000000-0000-0000-0000-000000000766','selected_for_contract');
insert into contract.contract_preparations (id, tenant_id, organization_id, request_id, offer_id, decision_id, supplier_id, preparation_code, title, status)
values ('55000000-0000-0000-0000-000000000966','55000000-0000-0000-0000-000000000166','55000000-0000-0000-0000-000000000a66','55000000-0000-0000-0000-000000000666','55000000-0000-0000-0000-000000000766','55000000-0000-0000-0000-000000000866',
        (select id from supplier.suppliers where organization_id='55000000-0000-0000-0000-000000000b66'),'PREP-166','Prep','ready_for_contract');
insert into contract.executed_contracts (id, tenant_id, organization_id, preparation_id, request_id, offer_id, decision_id, supplier_id, contract_code, status, contract_type, title, currency, executed_at)
values ('55000000-0000-0000-0000-000000000c66','55000000-0000-0000-0000-000000000166','55000000-0000-0000-0000-000000000a66','55000000-0000-0000-0000-000000000966','55000000-0000-0000-0000-000000000666','55000000-0000-0000-0000-000000000766','55000000-0000-0000-0000-000000000866',
        (select id from supplier.suppliers where organization_id='55000000-0000-0000-0000-000000000b66'),'CTR-166','executed','spot','CT-166','USD',now());
insert into shipment.shipments (id, tenant_id, organization_id, executed_contract_id, request_id, offer_id, supplier_id, shipment_code, status, transport_mode, origin_country, destination_country, planned_pickup_date)
values ('55000000-0000-0000-0000-000000000d66','55000000-0000-0000-0000-000000000166','55000000-0000-0000-0000-000000000a66','55000000-0000-0000-0000-000000000c66','55000000-0000-0000-0000-000000000666','55000000-0000-0000-0000-000000000766',
        (select id from supplier.suppliers where organization_id='55000000-0000-0000-0000-000000000b66'),'SH-166','planned','road','IR','TR',now()+interval '7 days');

-- Admin builds an active template and THREE recommendation rules (distinct
-- rule_id -> distinct recommendation rows for the same template), then runs
-- the bridge to generate three open recommendations.
do $$
declare v_tpl uuid; v_step uuid; v_rs uuid; v_r1 uuid; v_r2 uuid; v_r3 uuid;
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','55000000-0000-0000-0000-000000000166','role','authenticated',
                       'tenant_id','55000000-0000-0000-0000-000000000166')::text, true);
  perform set_config('request.jwt.claim.sub','55000000-0000-0000-0000-000000000166', true);
  set local role authenticated;
  v_tpl := workflow.admin_create_template('WF-166','Prep','d','shipment','shipment','{}'::jsonb);
  v_step := workflow.admin_add_step(v_tpl,'S1','Step');
  perform workflow.admin_activate_template(v_tpl);
  v_rs := rules.admin_create_rule_set('RS-166','Set','d','shipment',100,'{}'::jsonb);
  v_r1 := rules.admin_create_rule(v_rs,'R-166-1','Road1',null,'shipment','recommendation',100,
    jsonb_build_object('all', jsonb_build_array(jsonb_build_object('path','shipment.transport_mode','op','eq','value','road'))),
    jsonb_build_object('workflow_template_id', v_tpl::text,'confidence_score',60),'{}'::jsonb);
  v_r2 := rules.admin_create_rule(v_rs,'R-166-2','Road2',null,'shipment','recommendation',100,
    jsonb_build_object('all', jsonb_build_array(jsonb_build_object('path','shipment.transport_mode','op','eq','value','road'))),
    jsonb_build_object('workflow_template_id', v_tpl::text,'confidence_score',60),'{}'::jsonb);
  v_r3 := rules.admin_create_rule(v_rs,'R-166-3','Road3',null,'shipment','recommendation',100,
    jsonb_build_object('all', jsonb_build_array(jsonb_build_object('path','shipment.transport_mode','op','eq','value','road'))),
    jsonb_build_object('workflow_template_id', v_tpl::text,'confidence_score',60),'{}'::jsonb);
  perform rules.admin_activate_rule_set(v_rs);
  perform rules.admin_activate_rule(v_r1);
  perform rules.admin_activate_rule(v_r2);
  perform rules.admin_activate_rule(v_r3);
  perform rules.evaluate_shipment_workflow_recommendations('55000000-0000-0000-0000-000000000d66'::uuid,'{}'::jsonb,true);
  perform set_config('test.rec1_166',
    (select id::text from rules.workflow_recommendations where shipment_id='55000000-0000-0000-0000-000000000d66' and rule_id=v_r1), true);
  perform set_config('test.rec2_166',
    (select id::text from rules.workflow_recommendations where shipment_id='55000000-0000-0000-0000-000000000d66' and rule_id=v_r2), true);
  perform set_config('test.rec3_166',
    (select id::text from rules.workflow_recommendations where shipment_id='55000000-0000-0000-0000-000000000d66' and rule_id=v_r3), true);
  reset role;
end $$;

-- Buyer accepts rec1.
do $$
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','55000000-0000-0000-0000-000000000266','role','authenticated',
                       'tenant_id','55000000-0000-0000-0000-000000000166',
                       'organization_id','55000000-0000-0000-0000-000000000a66')::text, true);
  perform set_config('request.jwt.claim.sub','55000000-0000-0000-0000-000000000266', true);
  set local role authenticated;
  perform rules.buyer_accept_workflow_recommendation(current_setting('test.rec1_166')::uuid, 'looks good');
  reset role;
end $$;

select plan(6);

-- 1
select is(
  (select status from rules.workflow_recommendations where id = current_setting('test.rec1_166')::uuid),
  'accepted', 'buyer accept sets status = accepted');

-- 2
select is(
  (select count(*)::int from workflow.workflow_instances
    where shipment_id = '55000000-0000-0000-0000-000000000d66'),
  0, 'accept does NOT create a workflow instance');

-- 3: re-accepting a terminal recommendation raises
do $$
declare v_err text := '';
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','55000000-0000-0000-0000-000000000266','role','authenticated',
                       'tenant_id','55000000-0000-0000-0000-000000000166',
                       'organization_id','55000000-0000-0000-0000-000000000a66')::text, true);
  perform set_config('request.jwt.claim.sub','55000000-0000-0000-0000-000000000266', true);
  set local role authenticated;
  begin
    perform rules.buyer_accept_workflow_recommendation(current_setting('test.rec1_166')::uuid, 'again');
  exception when others then v_err := SQLERRM; end;
  reset role;
  perform set_config('test.reaccept_err_166', v_err, true);
end $$;
select isnt(
  current_setting('test.reaccept_err_166', true), '',
  'accepting a terminal recommendation again raises');

-- 4: admin dismisses rec2 with reason
do $$
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','55000000-0000-0000-0000-000000000166','role','authenticated',
                       'tenant_id','55000000-0000-0000-0000-000000000166')::text, true);
  perform set_config('request.jwt.claim.sub','55000000-0000-0000-0000-000000000166', true);
  set local role authenticated;
  perform rules.admin_dismiss_workflow_recommendation(current_setting('test.rec2_166')::uuid, 'not applicable');
  reset role;
end $$;
select is(
  (select status||':'||(dismissed_at is not null)::text||':'||coalesce(dismissal_reason,'')
     from rules.workflow_recommendations where id = current_setting('test.rec2_166')::uuid),
  'dismissed:true:not applicable',
  'admin dismiss sets status=dismissed with dismissed_at + reason');

-- 5: re-dismissing a terminal recommendation raises
do $$
declare v_err text := '';
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','55000000-0000-0000-0000-000000000166','role','authenticated',
                       'tenant_id','55000000-0000-0000-0000-000000000166')::text, true);
  perform set_config('request.jwt.claim.sub','55000000-0000-0000-0000-000000000166', true);
  set local role authenticated;
  begin
    perform rules.admin_dismiss_workflow_recommendation(current_setting('test.rec2_166')::uuid, 'again');
  exception when others then v_err := SQLERRM; end;
  reset role;
  perform set_config('test.redismiss_err_166', v_err, true);
end $$;
select isnt(
  current_setting('test.redismiss_err_166', true), '',
  'dismissing a terminal recommendation again raises');

-- 6: dismiss with empty reason raises (on still-open rec3)
do $$
declare v_err text := '';
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','55000000-0000-0000-0000-000000000166','role','authenticated',
                       'tenant_id','55000000-0000-0000-0000-000000000166')::text, true);
  perform set_config('request.jwt.claim.sub','55000000-0000-0000-0000-000000000166', true);
  set local role authenticated;
  begin
    perform rules.admin_dismiss_workflow_recommendation(current_setting('test.rec3_166')::uuid, '   ');
  exception when others then v_err := SQLERRM; end;
  reset role;
  perform set_config('test.emptyreason_err_166', v_err, true);
end $$;
select isnt(
  current_setting('test.emptyreason_err_166', true), '',
  'dismiss with empty reason raises');

select * from finish();
rollback;
