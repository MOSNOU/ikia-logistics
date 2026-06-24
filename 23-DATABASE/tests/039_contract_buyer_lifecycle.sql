-- CC-12 Test 039 — Buyer contract preparation lifecycle:
--   create → items derived → initial snapshot → update → upsert clause →
--   upsert dedupe → remove clause → manual snapshot → under_review → ready_for_contract
--   → ready locks edits.
--
-- Assertions (11):
--   1. buyer_create_preparation creates preparation with status='draft'
--   2. items are derived from the selected offer items (count = 1)
--   3. initial_from_offer snapshot is auto-created
--   4. buyer_update_preparation patches incoterm
--   5. buyer_upsert_clause adds a clause
--   6. upsert with same (clause_type, clause_key) is idempotent — count stays at 1
--   7. buyer_remove_clause soft-deletes the clause
--   8. buyer_create_snapshot persists a review_snapshot
--   9. buyer_move_to_under_review transitions draft → under_review
--  10. buyer_mark_ready_for_contract transitions under_review → ready_for_contract
--  11. ready_for_contract locks normal edits (P0001)

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, tests;
begin;

-- Fixtures: 1 buyer org + 1 supplier; supplier submits offer; buyer
-- selects_for_contract → preparation flow.
insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '0b0b0000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '039-buyer@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '0b0b0000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', '039-sup@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('0b0b0000-0000-0000-0000-00000000000a', 'tenant-039', 'تست', 'Test');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('0b0b0000-0000-0000-0000-00000000001a', '0b0b0000-0000-0000-0000-00000000000a',
   'buyer-039', 'خریدار', 'Buyer', 'buyer', 'active'),
  ('0b0b0000-0000-0000-0000-00000000002a', '0b0b0000-0000-0000-0000-00000000000a',
   'sup-039', 'تأمین‌کننده', 'Supplier', 'supplier', 'active');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('0b0b0000-0000-0000-0000-000000000001', '0b0b0000-0000-0000-0000-00000000000a',
   '0b0b0000-0000-0000-0000-00000000001a', 'Buyer', 'fa', 'active'),
  ('0b0b0000-0000-0000-0000-000000000002', '0b0b0000-0000-0000-0000-00000000000a',
   '0b0b0000-0000-0000-0000-00000000002a', 'Supplier', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '0b0b0000-0000-0000-0000-00000000000a', '0b0b0000-0000-0000-0000-00000000001a',
       '0b0b0000-0000-0000-0000-000000000001', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '0b0b0000-0000-0000-0000-00000000000a', '0b0b0000-0000-0000-0000-00000000002a',
       '0b0b0000-0000-0000-0000-000000000002', r.id, 'active', now()
  from identity.roles r where r.code = 'supplier_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '0b0b0000-0000-0000-0000-000000000001', r.id, 'organization', '0b0b0000-0000-0000-0000-00000000001a'
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '0b0b0000-0000-0000-0000-000000000002', r.id, 'organization', '0b0b0000-0000-0000-0000-00000000002a'
  from identity.roles r where r.code = 'supplier_admin';

do $$
declare
  v_sup uuid; v_prod uuid; v_rfq uuid; v_item uuid; v_off uuid; v_dec uuid;
begin
  select id into v_sup  from supplier.suppliers where organization_id = '0b0b0000-0000-0000-0000-00000000002a';
  select id into v_prod from commodity.products where code = 'methanol';

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','0b0b0000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','0b0b0000-0000-0000-0000-00000000000a',
                       'organization_id','0b0b0000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '0b0b0000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_rfq := rfq.buyer_create_rfq(p_title => 'R for contract preparation');
  v_item := rfq.buyer_upsert_rfq_item(p_request_id => v_rfq, p_product_id => v_prod,
                                       p_quantity => 1000, p_quantity_unit => 'ton');
  perform rfq.buyer_submit_rfq(v_rfq);
  perform rfq.buyer_invite_suppliers(v_rfq, array[v_sup]);
  reset role;

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','0b0b0000-0000-0000-0000-000000000002','role','authenticated',
                       'tenant_id','0b0b0000-0000-0000-0000-00000000000a',
                       'organization_id','0b0b0000-0000-0000-0000-00000000002a')::text, true);
  perform set_config('request.jwt.claim.sub', '0b0b0000-0000-0000-0000-000000000002', true);
  set local role authenticated;
  v_off := offer.supplier_create_draft_offer(p_request_id => v_rfq);
  perform offer.supplier_upsert_offer_item(
    p_offer_id => v_off, p_request_item_id => v_item,
    p_offered_quantity => 1000, p_quantity_unit => 'ton',
    p_unit_price => 380, p_total_price => 380000, p_currency => 'USD',
    p_packaging => 'IBC 1000L', p_origin_country => 'IR'
  );
  perform offer.supplier_submit_my_offer(v_off);
  reset role;

  -- buyer selects offer for contract
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','0b0b0000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','0b0b0000-0000-0000-0000-00000000000a',
                       'organization_id','0b0b0000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '0b0b0000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_dec := evaluation.buyer_select_for_contract(p_offer_id => v_off, p_reason => 'best offer');
  reset role;

  perform set_config('test.dec',   v_dec::text, false);
  perform set_config('test.offer', v_off::text, false);
  perform set_config('test.rfq',   v_rfq::text, false);
end;
$$;

select plan(11);

-- 1. Create preparation.
select tests.authenticate_as(
  '0b0b0000-0000-0000-0000-000000000001',
  '0b0b0000-0000-0000-0000-00000000000a',
  '0b0b0000-0000-0000-0000-00000000001a'
);
set local role authenticated;
do $$
declare v_prep uuid;
begin
  v_prep := contract.buyer_create_preparation(
    p_decision_id => current_setting('test.dec')::uuid,
    p_title       => 'Methanol contract draft',
    p_currency    => 'USD'
  );
  perform set_config('test.prep', v_prep::text, false);
end;
$$;
reset role;

select is(
  (select status::text from contract.contract_preparations
    where id = current_setting('test.prep')::uuid),
  'draft',
  'buyer_create_preparation creates preparation with status=draft'
);

-- 2. Items derived from offer items (1 offer item -> 1 preparation item).
select is(
  (select count(*)::int from contract.contract_preparation_items
    where preparation_id = current_setting('test.prep')::uuid and deleted_at is null),
  1,
  'items derived from the selected offer items (count=1)'
);

-- 3. initial_from_offer snapshot was auto-created.
select is(
  (select count(*)::int from contract.contract_preparation_snapshots
    where preparation_id = current_setting('test.prep')::uuid
      and snapshot_type = 'initial_from_offer'),
  1,
  'initial_from_offer snapshot is auto-created on preparation create'
);

-- 4. Update preparation.
select tests.authenticate_as(
  '0b0b0000-0000-0000-0000-000000000001',
  '0b0b0000-0000-0000-0000-00000000000a',
  '0b0b0000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select contract.buyer_update_preparation(
  p_preparation_id => current_setting('test.prep')::uuid,
  p_incoterm       => 'FOB',
  p_payment_terms_text => 'net 30'
);
reset role;

select is(
  (select incoterm from contract.contract_preparations
    where id = current_setting('test.prep')::uuid),
  'FOB',
  'buyer_update_preparation patches incoterm'
);

-- 5. Add a clause.
select tests.authenticate_as(
  '0b0b0000-0000-0000-0000-000000000001',
  '0b0b0000-0000-0000-0000-00000000000a',
  '0b0b0000-0000-0000-0000-00000000001a'
);
set local role authenticated;
do $$
declare v_clause uuid;
begin
  v_clause := contract.buyer_upsert_clause(
    p_preparation_id => current_setting('test.prep')::uuid,
    p_clause_type    => 'payment'::contract.preparation_clause_type,
    p_clause_key     => 'standard',
    p_title_en       => 'Payment Terms',
    p_body_en        => 'Net 30 days after BL date',
    p_is_required    => true
  );
  perform set_config('test.clause', v_clause::text, false);
end;
$$;
reset role;

select is(
  (select count(*)::int from contract.contract_preparation_clauses
    where preparation_id = current_setting('test.prep')::uuid and deleted_at is null),
  1,
  'buyer_upsert_clause adds one clause'
);

-- 6. Upsert same (clause_type, key) is idempotent.
select tests.authenticate_as(
  '0b0b0000-0000-0000-0000-000000000001',
  '0b0b0000-0000-0000-0000-00000000000a',
  '0b0b0000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select contract.buyer_upsert_clause(
  p_preparation_id => current_setting('test.prep')::uuid,
  p_clause_type    => 'payment'::contract.preparation_clause_type,
  p_clause_key     => 'standard',
  p_title_en       => 'Payment Terms (rev2)',
  p_body_en        => 'Net 45 days'
);
reset role;

select is(
  (select count(*)::int from contract.contract_preparation_clauses
    where preparation_id = current_setting('test.prep')::uuid and deleted_at is null),
  1,
  'upsert with same (clause_type, clause_key) is idempotent — count stays at 1'
);

-- 7. Remove clause.
select tests.authenticate_as(
  '0b0b0000-0000-0000-0000-000000000001',
  '0b0b0000-0000-0000-0000-00000000000a',
  '0b0b0000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select contract.buyer_remove_clause(current_setting('test.clause')::uuid);
reset role;

select is(
  (select count(*)::int from contract.contract_preparation_clauses
    where preparation_id = current_setting('test.prep')::uuid and deleted_at is null),
  0,
  'buyer_remove_clause soft-deletes the clause'
);

-- 8. Manual snapshot.
select tests.authenticate_as(
  '0b0b0000-0000-0000-0000-000000000001',
  '0b0b0000-0000-0000-0000-00000000000a',
  '0b0b0000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select contract.buyer_create_snapshot(
  p_preparation_id => current_setting('test.prep')::uuid,
  p_snapshot_type  => 'review_snapshot'::contract.preparation_snapshot_type,
  p_title          => 'mid-review v1',
  p_snapshot_data  => jsonb_build_object('checkpoint', 1)
);
reset role;

select is(
  (select count(*)::int from contract.contract_preparation_snapshots
    where preparation_id = current_setting('test.prep')::uuid
      and snapshot_type = 'review_snapshot'),
  1,
  'buyer_create_snapshot persists a review_snapshot'
);

-- 9. Move to under_review.
select tests.authenticate_as(
  '0b0b0000-0000-0000-0000-000000000001',
  '0b0b0000-0000-0000-0000-00000000000a',
  '0b0b0000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select contract.buyer_move_to_under_review(current_setting('test.prep')::uuid);
reset role;

select is(
  (select status::text from contract.contract_preparations
    where id = current_setting('test.prep')::uuid),
  'under_review',
  'buyer_move_to_under_review transitions draft → under_review'
);

-- 10. Mark ready_for_contract.
select tests.authenticate_as(
  '0b0b0000-0000-0000-0000-000000000001',
  '0b0b0000-0000-0000-0000-00000000000a',
  '0b0b0000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select contract.buyer_mark_ready_for_contract(current_setting('test.prep')::uuid);
reset role;

select is(
  (select status::text from contract.contract_preparations
    where id = current_setting('test.prep')::uuid),
  'ready_for_contract',
  'buyer_mark_ready_for_contract transitions under_review → ready_for_contract'
);

-- 11. ready_for_contract locks normal edits.
select tests.authenticate_as(
  '0b0b0000-0000-0000-0000-000000000001',
  '0b0b0000-0000-0000-0000-00000000000a',
  '0b0b0000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select throws_ok(
  format($$ select contract.buyer_update_preparation(%L::uuid, p_incoterm => 'CIF') $$,
         current_setting('test.prep')),
  'P0001', null,
  'ready_for_contract preparation is locked from update (P0001)'
);
reset role;

select * from finish();
rollback;
