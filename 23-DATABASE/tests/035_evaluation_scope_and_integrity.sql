-- CC-11 Test 035 — Evaluation scope and integrity:
--   * buyer of org A cannot evaluate buyer B's offer (42501)
--   * evaluation on a draft offer (not submitted) is rejected (P0001)
--   * completed evaluation is locked from update (P0001)
--   * supplier user cannot call buyer_create_evaluation (42501)
--   * duplicate active evaluation by same evaluator for same offer is rejected (23505)

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, tests;
begin;

-- 2 buyer orgs (A, B) + 1 supplier; A invites supplier to RFQ-A. RFQ-A offer submitted.
-- Also create a parallel scenario: RFQ-A2 in draft (offer-side reuses RFQ-A2's offer
-- by leaving it in 'draft' state).
insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '08080000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '035-buyerA@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '08080000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', '035-buyerB@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '08080000-0000-0000-0000-000000000003', 'authenticated', 'authenticated', '035-sup@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('08080000-0000-0000-0000-00000000000a', 'tenant-035a', 'الف', 'A'),
  ('08080000-0000-0000-0000-00000000000b', 'tenant-035b', 'ب',  'B');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('08080000-0000-0000-0000-00000000001a', '08080000-0000-0000-0000-00000000000a',
   'buyer-035a', 'خریدار الف', 'Buyer A', 'buyer', 'active'),
  ('08080000-0000-0000-0000-00000000001b', '08080000-0000-0000-0000-00000000000b',
   'buyer-035b', 'خریدار ب',  'Buyer B', 'buyer', 'active'),
  ('08080000-0000-0000-0000-00000000002a', '08080000-0000-0000-0000-00000000000a',
   'sup-035',   'تأمین‌کننده', 'Supplier',  'supplier', 'active');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('08080000-0000-0000-0000-000000000001', '08080000-0000-0000-0000-00000000000a',
   '08080000-0000-0000-0000-00000000001a', 'BuyerA', 'fa', 'active'),
  ('08080000-0000-0000-0000-000000000002', '08080000-0000-0000-0000-00000000000b',
   '08080000-0000-0000-0000-00000000001b', 'BuyerB', 'fa', 'active'),
  ('08080000-0000-0000-0000-000000000003', '08080000-0000-0000-0000-00000000000a',
   '08080000-0000-0000-0000-00000000002a', 'Supplier', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '08080000-0000-0000-0000-00000000000a', '08080000-0000-0000-0000-00000000001a',
       '08080000-0000-0000-0000-000000000001', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '08080000-0000-0000-0000-00000000000b', '08080000-0000-0000-0000-00000000001b',
       '08080000-0000-0000-0000-000000000002', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '08080000-0000-0000-0000-00000000000a', '08080000-0000-0000-0000-00000000002a',
       '08080000-0000-0000-0000-000000000003', r.id, 'active', now()
  from identity.roles r where r.code = 'supplier_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '08080000-0000-0000-0000-000000000001', r.id, 'organization', '08080000-0000-0000-0000-00000000001a'
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '08080000-0000-0000-0000-000000000002', r.id, 'organization', '08080000-0000-0000-0000-00000000001b'
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '08080000-0000-0000-0000-000000000003', r.id, 'organization', '08080000-0000-0000-0000-00000000002a'
  from identity.roles r where r.code = 'supplier_admin';

-- Buyer A creates RFQ + invites supplier; supplier submits one offer.
do $$
declare
  v_sup uuid; v_prod uuid; v_rfq uuid; v_item uuid; v_off uuid; v_off2 uuid;
begin
  select id into v_sup  from supplier.suppliers where organization_id = '08080000-0000-0000-0000-00000000002a';
  select id into v_prod from commodity.products where code = 'methanol';

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','08080000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','08080000-0000-0000-0000-00000000000a',
                       'organization_id','08080000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '08080000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_rfq := rfq.buyer_create_rfq(p_title => 'R for scope/integrity');
  v_item := rfq.buyer_upsert_rfq_item(p_request_id => v_rfq, p_product_id => v_prod,
                                       p_quantity => 1000, p_quantity_unit => 'ton');
  perform rfq.buyer_submit_rfq(v_rfq);
  perform rfq.buyer_invite_suppliers(v_rfq, array[v_sup]);
  reset role;

  -- supplier creates first offer + submits.
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','08080000-0000-0000-0000-000000000003','role','authenticated',
                       'tenant_id','08080000-0000-0000-0000-00000000000a',
                       'organization_id','08080000-0000-0000-0000-00000000002a')::text, true);
  perform set_config('request.jwt.claim.sub', '08080000-0000-0000-0000-000000000003', true);
  set local role authenticated;
  v_off := offer.supplier_create_draft_offer(p_request_id => v_rfq);
  perform offer.supplier_upsert_offer_item(
    p_offer_id => v_off, p_request_item_id => v_item,
    p_offered_quantity => 1000, p_quantity_unit => 'ton',
    p_unit_price => 380, p_currency => 'USD'
  );
  perform offer.supplier_submit_my_offer(v_off);
  reset role;

  perform set_config('test.rfq',       v_rfq::text, false);
  perform set_config('test.offer',     v_off::text, false);
end;
$$;

-- For test 2 we need an offer in 'draft' status. Build a second RFQ via RPC and
-- have the supplier create — but NOT submit — an offer on it.
do $$
declare
  v_sup uuid; v_prod uuid; v_rfq2 uuid; v_off_draft uuid;
begin
  select id into v_sup  from supplier.suppliers where organization_id = '08080000-0000-0000-0000-00000000002a';
  select id into v_prod from commodity.products where code = 'methanol';

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','08080000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','08080000-0000-0000-0000-00000000000a',
                       'organization_id','08080000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '08080000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_rfq2 := rfq.buyer_create_rfq(p_title => 'R for draft-offer fixture');
  perform rfq.buyer_upsert_rfq_item(p_request_id => v_rfq2, p_product_id => v_prod,
                                     p_quantity => 100, p_quantity_unit => 'ton');
  perform rfq.buyer_submit_rfq(v_rfq2);
  perform rfq.buyer_invite_suppliers(v_rfq2, array[v_sup]);
  reset role;

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','08080000-0000-0000-0000-000000000003','role','authenticated',
                       'tenant_id','08080000-0000-0000-0000-00000000000a',
                       'organization_id','08080000-0000-0000-0000-00000000002a')::text, true);
  perform set_config('request.jwt.claim.sub', '08080000-0000-0000-0000-000000000003', true);
  set local role authenticated;
  v_off_draft := offer.supplier_create_draft_offer(p_request_id => v_rfq2);
  reset role;

  perform set_config('test.offer_draft', v_off_draft::text, false);
end;
$$;

select plan(5);

-- 1. Buyer B (unrelated) cannot create evaluation on buyer A's offer.
select tests.authenticate_as(
  '08080000-0000-0000-0000-000000000002',
  '08080000-0000-0000-0000-00000000000b',
  '08080000-0000-0000-0000-00000000001b'
);
set local role authenticated;
select throws_ok(
  format($$ select evaluation.buyer_create_evaluation(%L::uuid) $$, current_setting('test.offer')),
  '42501', null,
  'buyer B cannot create evaluation on buyer A''s offer (42501)'
);
reset role;

-- 2. Cannot evaluate an offer in 'draft' status.
select tests.authenticate_as(
  '08080000-0000-0000-0000-000000000001',
  '08080000-0000-0000-0000-00000000000a',
  '08080000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select throws_ok(
  format($$ select evaluation.buyer_create_evaluation(%L::uuid) $$, current_setting('test.offer_draft')),
  'P0001', null,
  'evaluation on a draft (not submitted) offer is rejected (P0001)'
);
reset role;

-- 3. Completed evaluation is locked from update.
select tests.authenticate_as(
  '08080000-0000-0000-0000-000000000001',
  '08080000-0000-0000-0000-00000000000a',
  '08080000-0000-0000-0000-00000000001a'
);
set local role authenticated;
do $$
declare v_eval uuid;
begin
  v_eval := evaluation.buyer_create_evaluation(
    p_offer_id => current_setting('test.offer')::uuid
  );
  perform evaluation.buyer_complete_evaluation(v_eval);
  perform set_config('test.completed_eval', v_eval::text, false);
end;
$$;

select throws_ok(
  format($$ select evaluation.buyer_update_evaluation(%L::uuid, p_overall_notes => 'late edit') $$,
         current_setting('test.completed_eval')),
  'P0001', null,
  'completed evaluation is locked from update (P0001)'
);
reset role;

-- 4. Supplier user cannot call buyer_create_evaluation.
select tests.authenticate_as(
  '08080000-0000-0000-0000-000000000003',
  '08080000-0000-0000-0000-00000000000a',
  '08080000-0000-0000-0000-00000000002a'
);
set local role authenticated;
select throws_ok(
  format($$ select evaluation.buyer_create_evaluation(%L::uuid) $$, current_setting('test.offer')),
  '42501', null,
  'supplier user cannot call buyer_create_evaluation (42501)'
);
reset role;

-- 5. Duplicate active evaluation by same evaluator on same offer.
-- (One evaluation was created above and completed — completed counts as active
-- per the unique partial index. Try creating again.)
select tests.authenticate_as(
  '08080000-0000-0000-0000-000000000001',
  '08080000-0000-0000-0000-00000000000a',
  '08080000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select throws_ok(
  format($$ select evaluation.buyer_create_evaluation(%L::uuid) $$, current_setting('test.offer')),
  '23505', null,
  'duplicate active evaluation for same evaluator+offer is rejected (23505)'
);
reset role;

select * from finish();
rollback;
