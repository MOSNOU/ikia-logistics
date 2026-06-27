-- CC-67 Test 160 — rule_events ledger immutability + chain
--
-- Assertions (6):
--   1.  authenticated has no INSERT on rule_events
--   2.  UPDATE on rule_events raises (append-only trigger)
--   3.  DELETE on rule_events raises (append-only trigger)
--   4.  rule_set.created event recorded on create
--   5.  rule_set.activated event recorded on activate
--   6.  evaluation.completed event recorded on evaluate_context

set search_path = extensions, public, identity, organization, audit, supplier,
                  commodity, rfq, offer, evaluation, contract, shipment, notify,
                  marketplace, dispatch, telematics, execution, workflow, rules, tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '55000000-0000-0000-0000-000000000160', 'authenticated','authenticated','160-admin@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '55000000-0000-0000-0000-000000000260', 'authenticated','authenticated','160-buyer@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('55000000-0000-0000-0000-000000000160', 'tenant-160', 'تست', 'Test 160');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status, country_code) values
  ('55000000-0000-0000-0000-000000000a60', '55000000-0000-0000-0000-000000000160',
   'buy-160', 'خریدار', 'Buyer 160', 'buyer', 'active', 'IR'),
  ('55000000-0000-0000-0000-000000000b60', '55000000-0000-0000-0000-000000000160',
   'sup-160', 'تأمین', 'Supplier 160', 'supplier', 'active', 'IR');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('55000000-0000-0000-0000-000000000160', '55000000-0000-0000-0000-000000000160',
   '55000000-0000-0000-0000-000000000a60', 'Admin 160', 'fa', 'active'),
  ('55000000-0000-0000-0000-000000000260', '55000000-0000-0000-0000-000000000160',
   '55000000-0000-0000-0000-000000000a60', 'Buyer 160', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '55000000-0000-0000-0000-000000000160', '55000000-0000-0000-0000-000000000a60',
       '55000000-0000-0000-0000-000000000260', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '55000000-0000-0000-0000-000000000160', r.id, 'platform', null
  from identity.roles r where r.code = 'platform_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '55000000-0000-0000-0000-000000000260', r.id, 'organization',
       '55000000-0000-0000-0000-000000000a60'
  from identity.roles r where r.code = 'buyer_admin';

-- Shipment chain
insert into rfq.requests (id, tenant_id, organization_id, requester_user_id, rfq_code, title, status, visibility, preferred_currency)
values ('55000000-0000-0000-0000-000000000660', '55000000-0000-0000-0000-000000000160',
        '55000000-0000-0000-0000-000000000a60', '55000000-0000-0000-0000-000000000260',
        'RFQ-160', 'Stub', 'submitted', 'private_invited', 'USD');
insert into offer.supplier_offers (id, tenant_id, organization_id, request_id, supplier_id, offer_code, currency, status)
values ('55000000-0000-0000-0000-000000000760', '55000000-0000-0000-0000-000000000160',
        '55000000-0000-0000-0000-000000000b60', '55000000-0000-0000-0000-000000000660',
        (select id from supplier.suppliers where organization_id = '55000000-0000-0000-0000-000000000b60'),
        'OF-160', 'USD', 'submitted');
insert into evaluation.offer_decisions (id, tenant_id, organization_id, request_id, offer_id, decision_status)
values ('55000000-0000-0000-0000-000000000860', '55000000-0000-0000-0000-000000000160',
        '55000000-0000-0000-0000-000000000a60', '55000000-0000-0000-0000-000000000660',
        '55000000-0000-0000-0000-000000000760', 'selected_for_contract');
insert into contract.contract_preparations (id, tenant_id, organization_id, request_id, offer_id, decision_id, supplier_id, preparation_code, title, status)
values ('55000000-0000-0000-0000-000000000960', '55000000-0000-0000-0000-000000000160',
        '55000000-0000-0000-0000-000000000a60', '55000000-0000-0000-0000-000000000660',
        '55000000-0000-0000-0000-000000000760', '55000000-0000-0000-0000-000000000860',
        (select id from supplier.suppliers where organization_id = '55000000-0000-0000-0000-000000000b60'),
        'PREP-160', 'Prep', 'ready_for_contract');
insert into contract.executed_contracts (id, tenant_id, organization_id, preparation_id, request_id, offer_id, decision_id, supplier_id, contract_code, status, contract_type, title, currency, executed_at)
values ('55000000-0000-0000-0000-000000000c60', '55000000-0000-0000-0000-000000000160',
        '55000000-0000-0000-0000-000000000a60', '55000000-0000-0000-0000-000000000960',
        '55000000-0000-0000-0000-000000000660', '55000000-0000-0000-0000-000000000760',
        '55000000-0000-0000-0000-000000000860',
        (select id from supplier.suppliers where organization_id = '55000000-0000-0000-0000-000000000b60'),
        'CTR-160', 'executed', 'spot', 'CT-160', 'USD', now());
insert into shipment.shipments (id, tenant_id, organization_id, executed_contract_id, request_id, offer_id, supplier_id, shipment_code, status, transport_mode, origin_country, destination_country, planned_pickup_date)
values ('55000000-0000-0000-0000-000000000d60', '55000000-0000-0000-0000-000000000160',
        '55000000-0000-0000-0000-000000000a60', '55000000-0000-0000-0000-000000000c60',
        '55000000-0000-0000-0000-000000000660', '55000000-0000-0000-0000-000000000760',
        (select id from supplier.suppliers where organization_id = '55000000-0000-0000-0000-000000000b60'),
        'SH-160', 'planned', 'road', 'IR', 'TR', now() + interval '7 days');

-- Build a rule + evaluate as admin.
do $$
declare v_rs uuid; v_r uuid; v_eval jsonb;
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','55000000-0000-0000-0000-000000000160',
                       'role','authenticated',
                       'tenant_id','55000000-0000-0000-0000-000000000160')::text, true);
  perform set_config('request.jwt.claim.sub',
                     '55000000-0000-0000-0000-000000000160', true);
  set local role authenticated;
  v_rs := rules.admin_create_rule_set('RS-160','Set','d','shipment',100,'{}'::jsonb);
  v_r := rules.admin_create_rule(v_rs,'R-160','Road',null,'shipment','requirement',100,
    jsonb_build_object('all', jsonb_build_array(
      jsonb_build_object('path','shipment.transport_mode','op','eq','value','road')
    )),
    '{}'::jsonb,'{}'::jsonb);
  perform rules.admin_activate_rule_set(v_rs);
  perform rules.admin_activate_rule(v_r);
  perform set_config('test.rs_160', v_rs::text, true);

  v_eval := rules.evaluate_context(
    'shipment'::rules.rule_scope,
    '55000000-0000-0000-0000-000000000d60'::uuid,
    '{}'::jsonb, true);
  perform set_config('test.eval_id_160', (v_eval ->> 'evaluation_id'), true);
  reset role;
end $$;

select plan(6);

-- 1
select is(
  has_table_privilege('authenticated', 'rules.rule_events', 'INSERT'),
  false, 'authenticated has no INSERT on rule_events');

-- 2: UPDATE blocked
select throws_ok(
  $upd$ update rules.rule_events
           set payload = '{}'::jsonb
         where id = (
           select id from rules.rule_events
            where rule_set_id = current_setting('test.rs_160')::uuid
            limit 1
         )
  $upd$,
  '42501', null, 'UPDATE on rule_events raises append-only trigger');

-- 3: DELETE blocked
select throws_ok(
  $del$ delete from rules.rule_events
         where id = (
           select id from rules.rule_events
            where rule_set_id = current_setting('test.rs_160')::uuid
            limit 1
         )
  $del$,
  '42501', null, 'DELETE on rule_events raises append-only trigger');

-- 4
select cmp_ok(
  (select count(*)::int from rules.rule_events
    where rule_set_id = current_setting('test.rs_160')::uuid
      and event_type = 'rule_set.created'),
  '>=', 1, 'rule_set.created event recorded');

-- 5
select cmp_ok(
  (select count(*)::int from rules.rule_events
    where rule_set_id = current_setting('test.rs_160')::uuid
      and event_type = 'rule_set.activated'),
  '>=', 1, 'rule_set.activated event recorded');

-- 6
select cmp_ok(
  (select count(*)::int from rules.rule_events
    where evaluation_id = current_setting('test.eval_id_160')::uuid
      and event_type = 'evaluation.completed'),
  '>=', 1, 'evaluation.completed event recorded on evaluate_context');

select * from finish();
rollback;
