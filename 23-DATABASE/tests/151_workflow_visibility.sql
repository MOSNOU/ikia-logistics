-- CC-66 Test 151 — workflow instance visibility by role
--
-- Assertions (8):
--   1.  admin sees the instance via admin_list_instances
--   2.  buyer-org member sees the instance via buyer_list_instances
--   3.  carrier-org member sees the instance via carrier_list_instances
--   4.  supplier-org member sees the instance via supplier_list_instances
--   5.  unrelated stranger sees zero from buyer_list_instances
--   6.  unrelated stranger sees zero from carrier_list_instances
--   7.  fn_assert_can_view_instance allows the buyer
--   8.  fn_assert_can_view_instance denies the stranger

set search_path = extensions, public, identity, organization, audit, supplier,
                  commodity, rfq, offer, evaluation, contract, shipment, notify,
                  marketplace, dispatch, telematics, execution, workflow, tests;
begin;

-- ---------------------------------------------------------------------------
-- Fixture
-- ---------------------------------------------------------------------------
insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '54000000-0000-0000-0000-000000000151', 'authenticated','authenticated','151-admin@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '54000000-0000-0000-0000-000000000251', 'authenticated','authenticated','151-buyer@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '54000000-0000-0000-0000-000000000351', 'authenticated','authenticated','151-carrier@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '54000000-0000-0000-0000-000000000451', 'authenticated','authenticated','151-supplier@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '54000000-0000-0000-0000-000000000551', 'authenticated','authenticated','151-stranger@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('54000000-0000-0000-0000-000000000151', 'tenant-151', 'تست', 'Test 151');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status, country_code) values
  ('54000000-0000-0000-0000-000000000a51', '54000000-0000-0000-0000-000000000151',
   'buy-151', 'خریدار', 'Buyer 151', 'buyer', 'active', 'IR'),
  ('54000000-0000-0000-0000-000000000b51', '54000000-0000-0000-0000-000000000151',
   'sup-151', 'تأمین', 'Supplier 151', 'supplier', 'active', 'IR'),
  ('54000000-0000-0000-0000-000000000c51', '54000000-0000-0000-0000-000000000151',
   'car-151', 'حمل', 'Carrier 151', 'carrier', 'active', 'IR'),
  ('54000000-0000-0000-0000-000000000d51', '54000000-0000-0000-0000-000000000151',
   'oth-151', 'دیگر', 'Other 151', 'buyer', 'active', 'IR');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('54000000-0000-0000-0000-000000000151', '54000000-0000-0000-0000-000000000151',
   '54000000-0000-0000-0000-000000000a51', 'Admin 151', 'fa', 'active'),
  ('54000000-0000-0000-0000-000000000251', '54000000-0000-0000-0000-000000000151',
   '54000000-0000-0000-0000-000000000a51', 'Buyer 151', 'fa', 'active'),
  ('54000000-0000-0000-0000-000000000351', '54000000-0000-0000-0000-000000000151',
   '54000000-0000-0000-0000-000000000c51', 'Carrier 151', 'fa', 'active'),
  ('54000000-0000-0000-0000-000000000451', '54000000-0000-0000-0000-000000000151',
   '54000000-0000-0000-0000-000000000b51', 'Supplier 151', 'fa', 'active'),
  ('54000000-0000-0000-0000-000000000551', '54000000-0000-0000-0000-000000000151',
   '54000000-0000-0000-0000-000000000d51', 'Stranger 151', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '54000000-0000-0000-0000-000000000151', '54000000-0000-0000-0000-000000000a51',
       '54000000-0000-0000-0000-000000000251', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '54000000-0000-0000-0000-000000000151', '54000000-0000-0000-0000-000000000c51',
       '54000000-0000-0000-0000-000000000351', r.id, 'active', now()
  from identity.roles r where r.code = 'organization_admin';
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '54000000-0000-0000-0000-000000000151', '54000000-0000-0000-0000-000000000b51',
       '54000000-0000-0000-0000-000000000451', r.id, 'active', now()
  from identity.roles r where r.code = 'supplier_admin';
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '54000000-0000-0000-0000-000000000151', '54000000-0000-0000-0000-000000000d51',
       '54000000-0000-0000-0000-000000000551', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '54000000-0000-0000-0000-000000000151', r.id, 'platform', null
  from identity.roles r where r.code = 'platform_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '54000000-0000-0000-0000-000000000251', r.id, 'organization',
       '54000000-0000-0000-0000-000000000a51'
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '54000000-0000-0000-0000-000000000351', r.id, 'organization',
       '54000000-0000-0000-0000-000000000c51'
  from identity.roles r where r.code = 'organization_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '54000000-0000-0000-0000-000000000451', r.id, 'organization',
       '54000000-0000-0000-0000-000000000b51'
  from identity.roles r where r.code = 'supplier_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '54000000-0000-0000-0000-000000000551', r.id, 'organization',
       '54000000-0000-0000-0000-000000000d51'
  from identity.roles r where r.code = 'buyer_admin';

-- Shipment chain.
insert into rfq.requests (id, tenant_id, organization_id, requester_user_id, rfq_code, title, status, visibility, preferred_currency)
values ('54000000-0000-0000-0000-000000000651', '54000000-0000-0000-0000-000000000151',
        '54000000-0000-0000-0000-000000000a51', '54000000-0000-0000-0000-000000000251',
        'RFQ-151', 'Stub', 'submitted', 'private_invited', 'USD');
insert into offer.supplier_offers (id, tenant_id, organization_id, request_id, supplier_id, offer_code, currency, status)
values ('54000000-0000-0000-0000-000000000751', '54000000-0000-0000-0000-000000000151',
        '54000000-0000-0000-0000-000000000b51', '54000000-0000-0000-0000-000000000651',
        (select id from supplier.suppliers where organization_id = '54000000-0000-0000-0000-000000000b51'),
        'OF-151', 'USD', 'submitted');
insert into evaluation.offer_decisions (id, tenant_id, organization_id, request_id, offer_id, decision_status)
values ('54000000-0000-0000-0000-000000000851', '54000000-0000-0000-0000-000000000151',
        '54000000-0000-0000-0000-000000000a51', '54000000-0000-0000-0000-000000000651',
        '54000000-0000-0000-0000-000000000751', 'selected_for_contract');
insert into contract.contract_preparations (id, tenant_id, organization_id, request_id, offer_id, decision_id, supplier_id, preparation_code, title, status)
values ('54000000-0000-0000-0000-000000000951', '54000000-0000-0000-0000-000000000151',
        '54000000-0000-0000-0000-000000000a51', '54000000-0000-0000-0000-000000000651',
        '54000000-0000-0000-0000-000000000751', '54000000-0000-0000-0000-000000000851',
        (select id from supplier.suppliers where organization_id = '54000000-0000-0000-0000-000000000b51'),
        'PREP-151', 'Prep', 'ready_for_contract');
insert into contract.executed_contracts (id, tenant_id, organization_id, preparation_id, request_id, offer_id, decision_id, supplier_id, contract_code, status, contract_type, title, currency, executed_at)
values ('54000000-0000-0000-0000-000000000a52', '54000000-0000-0000-0000-000000000151',
        '54000000-0000-0000-0000-000000000a51', '54000000-0000-0000-0000-000000000951',
        '54000000-0000-0000-0000-000000000651', '54000000-0000-0000-0000-000000000751',
        '54000000-0000-0000-0000-000000000851',
        (select id from supplier.suppliers where organization_id = '54000000-0000-0000-0000-000000000b51'),
        'CTR-151', 'executed', 'spot', 'CT-151', 'USD', now());
insert into shipment.shipments (
  id, tenant_id, organization_id, executed_contract_id, request_id, offer_id,
  supplier_id, supplier_organization_id, carrier_organization_id,
  shipment_code, status, transport_mode, origin_country, destination_country, planned_pickup_date)
values ('54000000-0000-0000-0000-000000000b52', '54000000-0000-0000-0000-000000000151',
        '54000000-0000-0000-0000-000000000a51', '54000000-0000-0000-0000-000000000a52',
        '54000000-0000-0000-0000-000000000651', '54000000-0000-0000-0000-000000000751',
        (select id from supplier.suppliers where organization_id = '54000000-0000-0000-0000-000000000b51'),
        '54000000-0000-0000-0000-000000000b51', '54000000-0000-0000-0000-000000000c51',
        'SH-151', 'planned', 'road', 'IR', 'DE', now() + interval '7 days');

-- ---------------------------------------------------------------------------
-- Admin builds + activates a one-step template, buyer starts it.
-- ---------------------------------------------------------------------------
do $$
declare v_t uuid; v_s uuid; v_inst uuid;
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','54000000-0000-0000-0000-000000000151',
                       'role','authenticated',
                       'tenant_id','54000000-0000-0000-0000-000000000151')::text, true);
  perform set_config('request.jwt.claim.sub',
                     '54000000-0000-0000-0000-000000000151', true);
  set local role authenticated;
  v_t := workflow.admin_create_template('TPL-151','T151',null,'shipment','shipment','{}'::jsonb);
  v_s := workflow.admin_add_step(v_t,'S1','Step',null,'task',100,'buyer',null,'normal',null,'{}'::jsonb,'{}'::jsonb);
  perform workflow.admin_activate_template(v_t);
  perform set_config('test.t_151', v_t::text, true);
  reset role;
end $$;

do $$
declare v_inst uuid;
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','54000000-0000-0000-0000-000000000251',
                       'role','authenticated',
                       'tenant_id','54000000-0000-0000-0000-000000000151',
                       'organization_id','54000000-0000-0000-0000-000000000a51')::text, true);
  perform set_config('request.jwt.claim.sub',
                     '54000000-0000-0000-0000-000000000251', true);
  set local role authenticated;
  v_inst := workflow.buyer_start_workflow(
    current_setting('test.t_151')::uuid,
    '54000000-0000-0000-0000-000000000b52'::uuid,
    '{}'::jsonb);
  perform set_config('test.inst_151', v_inst::text, true);
  reset role;
end $$;

select plan(8);

-- 1: admin sees instance
do $$
declare v_count int;
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','54000000-0000-0000-0000-000000000151',
                       'role','authenticated')::text, true);
  perform set_config('request.jwt.claim.sub',
                     '54000000-0000-0000-0000-000000000151', true);
  set local role authenticated;
  select count(*)::int into v_count
    from workflow.admin_list_instances(null, null, 50, 0)
   where id = current_setting('test.inst_151')::uuid;
  reset role;
  perform set_config('test.admin_count_151', v_count::text, true);
end $$;
select is(
  (select current_setting('test.admin_count_151', true)::int),
  1, 'admin sees the instance via admin_list_instances');

-- 2: buyer
do $$
declare v_count int;
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','54000000-0000-0000-0000-000000000251',
                       'role','authenticated',
                       'tenant_id','54000000-0000-0000-0000-000000000151',
                       'organization_id','54000000-0000-0000-0000-000000000a51')::text, true);
  perform set_config('request.jwt.claim.sub',
                     '54000000-0000-0000-0000-000000000251', true);
  set local role authenticated;
  select count(*)::int into v_count
    from workflow.buyer_list_instances(null, null, 50, 0)
   where id = current_setting('test.inst_151')::uuid;
  reset role;
  perform set_config('test.buyer_count_151', v_count::text, true);
end $$;
select is(
  (select current_setting('test.buyer_count_151', true)::int),
  1, 'buyer-org member sees the instance via buyer_list_instances');

-- 3: carrier
do $$
declare v_count int;
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','54000000-0000-0000-0000-000000000351',
                       'role','authenticated',
                       'tenant_id','54000000-0000-0000-0000-000000000151',
                       'organization_id','54000000-0000-0000-0000-000000000c51')::text, true);
  perform set_config('request.jwt.claim.sub',
                     '54000000-0000-0000-0000-000000000351', true);
  set local role authenticated;
  select count(*)::int into v_count
    from workflow.carrier_list_instances(null, null, 50, 0)
   where id = current_setting('test.inst_151')::uuid;
  reset role;
  perform set_config('test.carrier_count_151', v_count::text, true);
end $$;
select is(
  (select current_setting('test.carrier_count_151', true)::int),
  1, 'carrier-org member sees the instance via carrier_list_instances');

-- 4: supplier
do $$
declare v_count int;
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','54000000-0000-0000-0000-000000000451',
                       'role','authenticated',
                       'tenant_id','54000000-0000-0000-0000-000000000151',
                       'organization_id','54000000-0000-0000-0000-000000000b51')::text, true);
  perform set_config('request.jwt.claim.sub',
                     '54000000-0000-0000-0000-000000000451', true);
  set local role authenticated;
  select count(*)::int into v_count
    from workflow.supplier_list_instances(null, null, 50, 0)
   where id = current_setting('test.inst_151')::uuid;
  reset role;
  perform set_config('test.supplier_count_151', v_count::text, true);
end $$;
select is(
  (select current_setting('test.supplier_count_151', true)::int),
  1, 'supplier-org member sees the instance via supplier_list_instances');

-- 5: stranger via buyer_list_instances
do $$
declare v_count int;
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','54000000-0000-0000-0000-000000000551',
                       'role','authenticated',
                       'tenant_id','54000000-0000-0000-0000-000000000151',
                       'organization_id','54000000-0000-0000-0000-000000000d51')::text, true);
  perform set_config('request.jwt.claim.sub',
                     '54000000-0000-0000-0000-000000000551', true);
  set local role authenticated;
  select count(*)::int into v_count
    from workflow.buyer_list_instances(null, null, 50, 0)
   where id = current_setting('test.inst_151')::uuid;
  reset role;
  perform set_config('test.stranger_buyer_count_151', v_count::text, true);
end $$;
select is(
  (select current_setting('test.stranger_buyer_count_151', true)::int),
  0, 'unrelated stranger sees zero from buyer_list_instances');

-- 6: stranger via carrier_list_instances
do $$
declare v_count int;
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','54000000-0000-0000-0000-000000000551',
                       'role','authenticated',
                       'tenant_id','54000000-0000-0000-0000-000000000151',
                       'organization_id','54000000-0000-0000-0000-000000000d51')::text, true);
  perform set_config('request.jwt.claim.sub',
                     '54000000-0000-0000-0000-000000000551', true);
  set local role authenticated;
  select count(*)::int into v_count
    from workflow.carrier_list_instances(null, null, 50, 0)
   where id = current_setting('test.inst_151')::uuid;
  reset role;
  perform set_config('test.stranger_carrier_count_151', v_count::text, true);
end $$;
select is(
  (select current_setting('test.stranger_carrier_count_151', true)::int),
  0, 'unrelated stranger sees zero from carrier_list_instances');

-- 7: fn_assert_can_view_instance allows buyer
do $$
declare v_ok boolean := false;
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','54000000-0000-0000-0000-000000000251',
                       'role','authenticated',
                       'tenant_id','54000000-0000-0000-0000-000000000151',
                       'organization_id','54000000-0000-0000-0000-000000000a51')::text, true);
  perform set_config('request.jwt.claim.sub',
                     '54000000-0000-0000-0000-000000000251', true);
  set local role authenticated;
  begin
    perform workflow.fn_assert_can_view_instance(current_setting('test.inst_151')::uuid);
    v_ok := true;
  exception when others then
    v_ok := false;
  end;
  reset role;
  perform set_config('test.buyer_view_ok_151', v_ok::text, true);
end $$;
select is(
  (select current_setting('test.buyer_view_ok_151', true)),
  'true', 'fn_assert_can_view_instance allows the buyer');

-- 8: fn_assert_can_view_instance denies stranger
do $$
declare v_denied boolean := false;
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','54000000-0000-0000-0000-000000000551',
                       'role','authenticated',
                       'tenant_id','54000000-0000-0000-0000-000000000151',
                       'organization_id','54000000-0000-0000-0000-000000000d51')::text, true);
  perform set_config('request.jwt.claim.sub',
                     '54000000-0000-0000-0000-000000000551', true);
  set local role authenticated;
  begin
    perform workflow.fn_assert_can_view_instance(current_setting('test.inst_151')::uuid);
  exception when others then
    v_denied := true;
  end;
  reset role;
  perform set_config('test.stranger_denied_151', v_denied::text, true);
end $$;
select is(
  (select current_setting('test.stranger_denied_151', true)),
  'true', 'fn_assert_can_view_instance denies the stranger');

select * from finish();
rollback;
