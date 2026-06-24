-- CC-12 Test 042 — Supplier visibility into contract preparation:
--   * supplier sees own preparation via supplier_list_my_preparations
--   * supplier gets own preparation detail via supplier_get_my_preparation
--   * unrelated supplier sees 0 preparations
--   * unrelated supplier cannot get preparation detail (42501)
--   * supplier cannot see clauses (buyer-private)

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '0e0e0000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '042-buyer@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '0e0e0000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', '042-supX@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '0e0e0000-0000-0000-0000-000000000003', 'authenticated', 'authenticated', '042-supY@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('0e0e0000-0000-0000-0000-00000000000a', 'tenant-042', 'تست', 'Test');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('0e0e0000-0000-0000-0000-00000000001a', '0e0e0000-0000-0000-0000-00000000000a',
   'buyer-042', 'خریدار', 'Buyer', 'buyer', 'active'),
  ('0e0e0000-0000-0000-0000-00000000002a', '0e0e0000-0000-0000-0000-00000000000a',
   'sup-042-X', 'ایکس', 'SupX', 'supplier', 'active'),
  ('0e0e0000-0000-0000-0000-00000000002b', '0e0e0000-0000-0000-0000-00000000000a',
   'sup-042-Y', 'وای',  'SupY', 'supplier', 'active');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('0e0e0000-0000-0000-0000-000000000001', '0e0e0000-0000-0000-0000-00000000000a',
   '0e0e0000-0000-0000-0000-00000000001a', 'Buyer', 'fa', 'active'),
  ('0e0e0000-0000-0000-0000-000000000002', '0e0e0000-0000-0000-0000-00000000000a',
   '0e0e0000-0000-0000-0000-00000000002a', 'SupX', 'fa', 'active'),
  ('0e0e0000-0000-0000-0000-000000000003', '0e0e0000-0000-0000-0000-00000000000a',
   '0e0e0000-0000-0000-0000-00000000002b', 'SupY', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '0e0e0000-0000-0000-0000-00000000000a', '0e0e0000-0000-0000-0000-00000000001a',
       '0e0e0000-0000-0000-0000-000000000001', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '0e0e0000-0000-0000-0000-00000000000a', '0e0e0000-0000-0000-0000-00000000002a',
       '0e0e0000-0000-0000-0000-000000000002', r.id, 'active', now()
  from identity.roles r where r.code = 'supplier_admin';
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '0e0e0000-0000-0000-0000-00000000000a', '0e0e0000-0000-0000-0000-00000000002b',
       '0e0e0000-0000-0000-0000-000000000003', r.id, 'active', now()
  from identity.roles r where r.code = 'supplier_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '0e0e0000-0000-0000-0000-000000000001', r.id, 'organization', '0e0e0000-0000-0000-0000-00000000001a'
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '0e0e0000-0000-0000-0000-000000000002', r.id, 'organization', '0e0e0000-0000-0000-0000-00000000002a'
  from identity.roles r where r.code = 'supplier_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '0e0e0000-0000-0000-0000-000000000003', r.id, 'organization', '0e0e0000-0000-0000-0000-00000000002b'
  from identity.roles r where r.code = 'supplier_admin';

do $$
declare
  v_supX uuid; v_prod uuid; v_rfq uuid; v_item uuid; v_off uuid; v_dec uuid; v_prep uuid; v_clause uuid;
begin
  select id into v_supX from supplier.suppliers where organization_id = '0e0e0000-0000-0000-0000-00000000002a';
  select id into v_prod from commodity.products where code = 'methanol';

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','0e0e0000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','0e0e0000-0000-0000-0000-00000000000a',
                       'organization_id','0e0e0000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '0e0e0000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_rfq := rfq.buyer_create_rfq(p_title => 'R for supplier visibility');
  v_item := rfq.buyer_upsert_rfq_item(p_request_id => v_rfq, p_product_id => v_prod,
                                       p_quantity => 1000, p_quantity_unit => 'ton');
  perform rfq.buyer_submit_rfq(v_rfq);
  perform rfq.buyer_invite_suppliers(v_rfq, array[v_supX]);
  reset role;

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','0e0e0000-0000-0000-0000-000000000002','role','authenticated',
                       'tenant_id','0e0e0000-0000-0000-0000-00000000000a',
                       'organization_id','0e0e0000-0000-0000-0000-00000000002a')::text, true);
  perform set_config('request.jwt.claim.sub', '0e0e0000-0000-0000-0000-000000000002', true);
  set local role authenticated;
  v_off := offer.supplier_create_draft_offer(p_request_id => v_rfq);
  perform offer.supplier_upsert_offer_item(p_offer_id => v_off, p_request_item_id => v_item,
    p_offered_quantity => 1000, p_quantity_unit => 'ton', p_unit_price => 380, p_currency => 'USD');
  perform offer.supplier_submit_my_offer(v_off);
  reset role;

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','0e0e0000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','0e0e0000-0000-0000-0000-00000000000a',
                       'organization_id','0e0e0000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '0e0e0000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_dec := evaluation.buyer_select_for_contract(p_offer_id => v_off);
  v_prep := contract.buyer_create_preparation(p_decision_id => v_dec, p_title => 'visibility prep');
  v_clause := contract.buyer_upsert_clause(
    p_preparation_id => v_prep,
    p_clause_type    => 'payment'::contract.preparation_clause_type,
    p_title_en       => 'PT', p_body_en => 'buyer-private'
  );
  reset role;

  perform set_config('test.prep', v_prep::text, false);
  perform set_config('test.clause', v_clause::text, false);
end;
$$;

select plan(5);

-- 1. Supplier X sees their own preparation.
select tests.authenticate_as(
  '0e0e0000-0000-0000-0000-000000000002',
  '0e0e0000-0000-0000-0000-00000000000a',
  '0e0e0000-0000-0000-0000-00000000002a'
);
set local role authenticated;
select is(
  (select count(*)::int from contract.supplier_list_my_preparations(null, 100, 0)),
  1,
  'supplier X sees their own preparation via supplier_list_my_preparations'
);
reset role;

-- 2. Supplier X reads own preparation detail.
select tests.authenticate_as(
  '0e0e0000-0000-0000-0000-000000000002',
  '0e0e0000-0000-0000-0000-00000000000a',
  '0e0e0000-0000-0000-0000-00000000002a'
);
set local role authenticated;
select is(
  (contract.supplier_get_my_preparation(current_setting('test.prep')::uuid))->>'title',
  'visibility prep',
  'supplier_get_my_preparation returns the preparation title'
);
reset role;

-- 3. Supplier Y sees 0 preparations.
select tests.authenticate_as(
  '0e0e0000-0000-0000-0000-000000000003',
  '0e0e0000-0000-0000-0000-00000000000a',
  '0e0e0000-0000-0000-0000-00000000002b'
);
set local role authenticated;
select is(
  (select count(*)::int from contract.supplier_list_my_preparations(null, 100, 0)),
  0,
  'supplier Y sees 0 preparations (none of their offers)'
);

-- 4. Supplier Y cannot read supplier X's preparation.
select throws_ok(
  format($$ select contract.supplier_get_my_preparation(%L::uuid) $$, current_setting('test.prep')),
  '42501', null,
  'supplier Y cannot read supplier X''s preparation (42501)'
);
reset role;

-- 5. Supplier cannot see buyer-private clauses via direct SELECT.
select tests.authenticate_as(
  '0e0e0000-0000-0000-0000-000000000002',
  '0e0e0000-0000-0000-0000-00000000000a',
  '0e0e0000-0000-0000-0000-00000000002a'
);
set local role authenticated;
select is(
  (select count(*)::int from contract.contract_preparation_clauses
    where id = current_setting('test.clause')::uuid),
  0,
  'supplier cannot see buyer-private clauses (RLS blocks)'
);
reset role;

select * from finish();
rollback;
