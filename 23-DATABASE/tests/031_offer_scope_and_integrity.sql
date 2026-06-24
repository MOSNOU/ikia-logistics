-- CC-10 Test 031 — Scope + data integrity:
--   * uninvited supplier cannot create offer (42501)
--   * duplicate active offer for same (supplier, RFQ) rejected (23505)
--   * offer item from a different RFQ rejected (42501)
--   * spec response on offer item with mismatching RFQ spec rejected (42501)
--   * supplier cannot mutate another supplier's offer (42501)
--   * submitted offer is locked from edits (P0001)

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, tests;
begin;

-- Two suppliers (X invited, Y uninvited) + two RFQs (R1 in buyer A, R2 in buyer B).
insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '05050000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '031-buyerA@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '05050000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', '031-buyerB@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '05050000-0000-0000-0000-000000000003', 'authenticated', 'authenticated', '031-supX@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '05050000-0000-0000-0000-000000000004', 'authenticated', 'authenticated', '031-supY@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('05050000-0000-0000-0000-00000000000a', 'tenant-031a', 'الف', 'A'),
  ('05050000-0000-0000-0000-00000000000b', 'tenant-031b', 'ب',  'B');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('05050000-0000-0000-0000-00000000001a', '05050000-0000-0000-0000-00000000000a',
   'buyer-031a', 'خریدار الف', 'Buyer A', 'buyer', 'active'),
  ('05050000-0000-0000-0000-00000000001b', '05050000-0000-0000-0000-00000000000b',
   'buyer-031b', 'خریدار ب',  'Buyer B', 'buyer', 'active'),
  ('05050000-0000-0000-0000-00000000002a', '05050000-0000-0000-0000-00000000000a',
   'sup-031-X', 'تأمین ایکس', 'Supplier X', 'supplier', 'active'),
  ('05050000-0000-0000-0000-00000000002b', '05050000-0000-0000-0000-00000000000a',
   'sup-031-Y', 'تأمین وای',  'Supplier Y', 'supplier', 'active');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('05050000-0000-0000-0000-000000000001', '05050000-0000-0000-0000-00000000000a',
   '05050000-0000-0000-0000-00000000001a', 'BuyerA', 'fa', 'active'),
  ('05050000-0000-0000-0000-000000000002', '05050000-0000-0000-0000-00000000000b',
   '05050000-0000-0000-0000-00000000001b', 'BuyerB', 'fa', 'active'),
  ('05050000-0000-0000-0000-000000000003', '05050000-0000-0000-0000-00000000000a',
   '05050000-0000-0000-0000-00000000002a', 'SupX', 'fa', 'active'),
  ('05050000-0000-0000-0000-000000000004', '05050000-0000-0000-0000-00000000000a',
   '05050000-0000-0000-0000-00000000002b', 'SupY', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '05050000-0000-0000-0000-00000000000a', '05050000-0000-0000-0000-00000000001a',
       '05050000-0000-0000-0000-000000000001', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '05050000-0000-0000-0000-00000000000b', '05050000-0000-0000-0000-00000000001b',
       '05050000-0000-0000-0000-000000000002', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '05050000-0000-0000-0000-00000000000a', '05050000-0000-0000-0000-00000000002a',
       '05050000-0000-0000-0000-000000000003', r.id, 'active', now()
  from identity.roles r where r.code = 'supplier_admin';
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '05050000-0000-0000-0000-00000000000a', '05050000-0000-0000-0000-00000000002b',
       '05050000-0000-0000-0000-000000000004', r.id, 'active', now()
  from identity.roles r where r.code = 'supplier_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '05050000-0000-0000-0000-000000000001', r.id, 'organization', '05050000-0000-0000-0000-00000000001a'
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '05050000-0000-0000-0000-000000000002', r.id, 'organization', '05050000-0000-0000-0000-00000000001b'
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '05050000-0000-0000-0000-000000000003', r.id, 'organization', '05050000-0000-0000-0000-00000000002a'
  from identity.roles r where r.code = 'supplier_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '05050000-0000-0000-0000-000000000004', r.id, 'organization', '05050000-0000-0000-0000-00000000002b'
  from identity.roles r where r.code = 'supplier_admin';

-- Build R1 (buyer A) inviting only supplier X. R2 (buyer B) inviting nobody.
do $$
declare
  v_supX uuid; v_supY uuid; v_prod uuid;
  v_r1 uuid; v_r1_item uuid; v_r1_spec uuid;
  v_r2 uuid; v_r2_item uuid;
begin
  select id into v_supX from supplier.suppliers where organization_id = '05050000-0000-0000-0000-00000000002a';
  select id into v_supY from supplier.suppliers where organization_id = '05050000-0000-0000-0000-00000000002b';
  select id into v_prod from commodity.products where code = 'methanol';
  perform set_config('test.supX', v_supX::text, false);
  perform set_config('test.supY', v_supY::text, false);
  perform set_config('test.prod', v_prod::text, false);

  -- Buyer A creates R1 + invites supX
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','05050000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','05050000-0000-0000-0000-00000000000a',
                       'organization_id','05050000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '05050000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_r1 := rfq.buyer_create_rfq(p_title => 'R1 buyer A');
  v_r1_item := rfq.buyer_upsert_rfq_item(p_request_id => v_r1, p_product_id => v_prod,
                                          p_quantity => 1000, p_quantity_unit => 'ton');
  v_r1_spec := rfq.buyer_upsert_item_specification(
    p_request_item_id => v_r1_item, p_spec_key => 'purity', p_data_type => 'number',
    p_unit => '%', p_min_value => 99.85, p_is_required => true
  );
  perform rfq.buyer_submit_rfq(v_r1);
  perform rfq.buyer_invite_suppliers(v_r1, array[v_supX]);
  reset role;

  perform set_config('test.r1', v_r1::text, false);
  perform set_config('test.r1_item', v_r1_item::text, false);
  perform set_config('test.r1_spec', v_r1_spec::text, false);

  -- Buyer B creates R2 (different RFQ, supX not invited).
  -- Keep R2 in draft so we can attach an R2-scoped spec later in the test
  -- (item/spec mutation requires the parent RFQ to be in 'draft').
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','05050000-0000-0000-0000-000000000002','role','authenticated',
                       'tenant_id','05050000-0000-0000-0000-00000000000b',
                       'organization_id','05050000-0000-0000-0000-00000000001b')::text, true);
  perform set_config('request.jwt.claim.sub', '05050000-0000-0000-0000-000000000002', true);
  set local role authenticated;
  v_r2 := rfq.buyer_create_rfq(p_title => 'R2 buyer B');
  v_r2_item := rfq.buyer_upsert_rfq_item(p_request_id => v_r2, p_product_id => v_prod,
                                          p_quantity => 500, p_quantity_unit => 'ton');
  reset role;

  perform set_config('test.r2', v_r2::text, false);
  perform set_config('test.r2_item', v_r2_item::text, false);
end;
$$;

select plan(6);

-- 1. Uninvited supplier Y cannot create offer for R1.
select tests.authenticate_as(
  '05050000-0000-0000-0000-000000000004',
  '05050000-0000-0000-0000-00000000000a',
  '05050000-0000-0000-0000-00000000002b'
);
set local role authenticated;
select throws_ok(
  format($$ select offer.supplier_create_draft_offer(%L::uuid) $$, current_setting('test.r1')),
  '42501', null,
  'uninvited supplier Y cannot create offer for R1'
);
reset role;

-- 2. Invited supplier X creates an offer; duplicate active offer is rejected.
select tests.authenticate_as(
  '05050000-0000-0000-0000-000000000003',
  '05050000-0000-0000-0000-00000000000a',
  '05050000-0000-0000-0000-00000000002a'
);
set local role authenticated;
do $$
declare v_off uuid;
begin
  v_off := offer.supplier_create_draft_offer(
    p_request_id => current_setting('test.r1')::uuid
  );
  perform set_config('test.offer_x_r1', v_off::text, false);
end;
$$;
reset role;

select tests.authenticate_as(
  '05050000-0000-0000-0000-000000000003',
  '05050000-0000-0000-0000-00000000000a',
  '05050000-0000-0000-0000-00000000002a'
);
set local role authenticated;
select throws_ok(
  format($$ select offer.supplier_create_draft_offer(%L::uuid) $$, current_setting('test.r1')),
  '23505', null,
  'duplicate active offer by same supplier for same RFQ is rejected (23505)'
);
reset role;

-- 3. Offer item from a different RFQ (R2's item) is rejected.
select tests.authenticate_as(
  '05050000-0000-0000-0000-000000000003',
  '05050000-0000-0000-0000-00000000000a',
  '05050000-0000-0000-0000-00000000002a'
);
set local role authenticated;
select throws_ok(
  format($$ select offer.supplier_upsert_offer_item(
              p_offer_id => %L::uuid,
              p_request_item_id => %L::uuid,
              p_offered_quantity => 100, p_quantity_unit => 'ton'
            ) $$, current_setting('test.offer_x_r1'), current_setting('test.r2_item')),
  '42501', null,
  'offer item referencing an RFQ item from a different RFQ is rejected (42501)'
);
reset role;

-- 4. Spec response with mismatching RFQ spec: create offer item legitimately,
--    then try to attach R1's spec to a spec_response on it via a different mechanism.
--    Here the spec belongs to R1's item, and we use the same offer item — should
--    succeed. To trigger the mismatch we'd need a different RFQ item. Create one
--    on R2 with a separate spec, then try to use R2's spec on R1's offer item.
do $$
declare v_r2_spec uuid;
begin
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','05050000-0000-0000-0000-000000000002','role','authenticated',
                       'tenant_id','05050000-0000-0000-0000-00000000000b',
                       'organization_id','05050000-0000-0000-0000-00000000001b')::text, true);
  perform set_config('request.jwt.claim.sub', '05050000-0000-0000-0000-000000000002', true);
  set local role authenticated;
  v_r2_spec := rfq.buyer_upsert_item_specification(
    p_request_item_id => current_setting('test.r2_item')::uuid,
    p_spec_key => 'purity', p_data_type => 'number', p_unit => '%',
    p_min_value => 99, p_is_required => true
  );
  reset role;
  perform set_config('test.r2_spec', v_r2_spec::text, false);
end;
$$;

select tests.authenticate_as(
  '05050000-0000-0000-0000-000000000003',
  '05050000-0000-0000-0000-00000000000a',
  '05050000-0000-0000-0000-00000000002a'
);
set local role authenticated;
-- First add a valid offer item to attach a spec response.
do $$
declare v_oitem uuid;
begin
  v_oitem := offer.supplier_upsert_offer_item(
    p_offer_id => current_setting('test.offer_x_r1')::uuid,
    p_request_item_id => current_setting('test.r1_item')::uuid,
    p_offered_quantity => 1000, p_quantity_unit => 'ton',
    p_unit_price => 380
  );
  perform set_config('test.x_r1_offer_item', v_oitem::text, false);
end;
$$;

select throws_ok(
  format($$ select offer.supplier_upsert_spec_response(
              p_offer_item_id => %L::uuid,
              p_spec_key => 'purity',
              p_request_item_spec_id => %L::uuid
            ) $$,
         current_setting('test.x_r1_offer_item'),
         current_setting('test.r2_spec')),
  '42501', null,
  'spec response with RFQ spec from a different RFQ item is rejected (42501)'
);
reset role;

-- 5. Supplier Y cannot mutate supplier X's offer.
select tests.authenticate_as(
  '05050000-0000-0000-0000-000000000004',
  '05050000-0000-0000-0000-00000000000a',
  '05050000-0000-0000-0000-00000000002b'
);
set local role authenticated;
select throws_ok(
  format($$ select offer.supplier_update_my_offer(%L::uuid, p_supplier_notes => 'tamper') $$,
         current_setting('test.offer_x_r1')),
  '42501', null,
  'supplier Y cannot mutate supplier X''s offer (42501)'
);
reset role;

-- 6. Submitted offer is locked from normal edit.
select tests.authenticate_as(
  '05050000-0000-0000-0000-000000000003',
  '05050000-0000-0000-0000-00000000000a',
  '05050000-0000-0000-0000-00000000002a'
);
set local role authenticated;
select offer.supplier_submit_my_offer(current_setting('test.offer_x_r1')::uuid);
select throws_ok(
  format($$ select offer.supplier_update_my_offer(%L::uuid, p_supplier_notes => 'late edit') $$,
         current_setting('test.offer_x_r1')),
  'P0001', null,
  'submitted offer is locked from normal edit (P0001)'
);
reset role;

select * from finish();
rollback;
