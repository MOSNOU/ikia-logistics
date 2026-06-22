-- CC-11 Test 034 — Buyer evaluation lifecycle:
--   create_evaluation → upsert_score(x2) → update_evaluation → complete_evaluation.
-- Then snapshot creation.
--
-- Assertions (7):
--   1. buyer_create_evaluation creates row with status='draft'
--   2. buyer_upsert_score adds two distinct dimension rows
--   3. buyer_upsert_score on same dimension is upsert (count stays at 2)
--   4. buyer_update_evaluation patches notes fields
--   5. buyer_complete_evaluation moves draft → completed
--   6. buyer_get_evaluation returns scores array
--   7. buyer_create_comparison_snapshot persists snapshot

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, tests;
begin;

-- Fixtures: 1 buyer org + 1 supplier; supplier submits one offer to buyer's RFQ.
insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '07070000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '034-buyer@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '07070000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', '034-sup@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('07070000-0000-0000-0000-00000000000a', 'tenant-034', 'تست', 'Test');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('07070000-0000-0000-0000-00000000001a', '07070000-0000-0000-0000-00000000000a',
   'buyer-034', 'خریدار', 'Buyer', 'buyer', 'active'),
  ('07070000-0000-0000-0000-00000000002a', '07070000-0000-0000-0000-00000000000a',
   'sup-034', 'تأمین‌کننده', 'Supplier', 'supplier', 'active');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('07070000-0000-0000-0000-000000000001', '07070000-0000-0000-0000-00000000000a',
   '07070000-0000-0000-0000-00000000001a', 'Buyer', 'fa', 'active'),
  ('07070000-0000-0000-0000-000000000002', '07070000-0000-0000-0000-00000000000a',
   '07070000-0000-0000-0000-00000000002a', 'Supplier', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '07070000-0000-0000-0000-00000000000a', '07070000-0000-0000-0000-00000000001a',
       '07070000-0000-0000-0000-000000000001', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '07070000-0000-0000-0000-00000000000a', '07070000-0000-0000-0000-00000000002a',
       '07070000-0000-0000-0000-000000000002', r.id, 'active', now()
  from identity.roles r where r.code = 'supplier_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '07070000-0000-0000-0000-000000000001', r.id, 'organization', '07070000-0000-0000-0000-00000000001a'
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '07070000-0000-0000-0000-000000000002', r.id, 'organization', '07070000-0000-0000-0000-00000000002a'
  from identity.roles r where r.code = 'supplier_admin';

-- Build RFQ + supplier offer.
do $$
declare
  v_sup uuid; v_prod uuid; v_rfq uuid; v_item uuid; v_off uuid;
begin
  select id into v_sup  from supplier.suppliers where organization_id = '07070000-0000-0000-0000-00000000002a';
  select id into v_prod from commodity.products where code = 'methanol';

  -- buyer creates + invites
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','07070000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','07070000-0000-0000-0000-00000000000a',
                       'organization_id','07070000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '07070000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_rfq := rfq.buyer_create_rfq(p_title => 'R for evaluation lifecycle');
  v_item := rfq.buyer_upsert_rfq_item(p_request_id => v_rfq, p_product_id => v_prod,
                                       p_quantity => 1000, p_quantity_unit => 'ton');
  perform rfq.buyer_submit_rfq(v_rfq);
  perform rfq.buyer_invite_suppliers(v_rfq, array[v_sup]);
  reset role;

  -- supplier draft + submit
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','07070000-0000-0000-0000-000000000002','role','authenticated',
                       'tenant_id','07070000-0000-0000-0000-00000000000a',
                       'organization_id','07070000-0000-0000-0000-00000000002a')::text, true);
  perform set_config('request.jwt.claim.sub', '07070000-0000-0000-0000-000000000002', true);
  set local role authenticated;
  v_off := offer.supplier_create_draft_offer(p_request_id => v_rfq);
  perform offer.supplier_upsert_offer_item(
    p_offer_id => v_off, p_request_item_id => v_item,
    p_offered_quantity => 1000, p_quantity_unit => 'ton',
    p_unit_price => 380, p_currency => 'USD'
  );
  perform offer.supplier_submit_my_offer(v_off);
  reset role;

  perform set_config('test.rfq',   v_rfq::text, false);
  perform set_config('test.offer', v_off::text, false);
end;
$$;

select plan(7);

-- 1. Buyer creates evaluation.
select tests.authenticate_as(
  '07070000-0000-0000-0000-000000000001',
  '07070000-0000-0000-0000-00000000000a',
  '07070000-0000-0000-0000-00000000001a'
);
set local role authenticated;
do $$
declare v_eval uuid;
begin
  v_eval := evaluation.buyer_create_evaluation(
    p_offer_id => current_setting('test.offer')::uuid,
    p_technical_notes => 'tech ok'
  );
  perform set_config('test.eval', v_eval::text, false);
end;
$$;
reset role;

select is(
  (select status::text from evaluation.offer_evaluations
    where id = current_setting('test.eval')::uuid),
  'draft',
  'buyer_create_evaluation creates evaluation with status=draft'
);

-- 2. Upsert two scores on distinct dimensions.
select tests.authenticate_as(
  '07070000-0000-0000-0000-000000000001',
  '07070000-0000-0000-0000-00000000000a',
  '07070000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select evaluation.buyer_upsert_score(
  p_evaluation_id => current_setting('test.eval')::uuid,
  p_dimension => 'price',
  p_score_value => 7, p_max_score => 10, p_weight => 0.4, p_weighted_score => 2.8
);
select evaluation.buyer_upsert_score(
  p_evaluation_id => current_setting('test.eval')::uuid,
  p_dimension => 'delivery',
  p_score_value => 8, p_max_score => 10, p_weight => 0.3, p_weighted_score => 2.4
);
reset role;

select is(
  (select count(*)::int from evaluation.offer_evaluation_scores
    where evaluation_id = current_setting('test.eval')::uuid and deleted_at is null),
  2,
  'two distinct dimension scores recorded'
);

-- 3. Upsert same dimension again — should update, not insert.
select tests.authenticate_as(
  '07070000-0000-0000-0000-000000000001',
  '07070000-0000-0000-0000-00000000000a',
  '07070000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select evaluation.buyer_upsert_score(
  p_evaluation_id => current_setting('test.eval')::uuid,
  p_dimension => 'price',
  p_score_value => 9, p_max_score => 10, p_weight => 0.4, p_weighted_score => 3.6
);
reset role;

select is(
  (select count(*)::int from evaluation.offer_evaluation_scores
    where evaluation_id = current_setting('test.eval')::uuid and deleted_at is null),
  2,
  'duplicate dimension upsert keeps count at 2 (idempotent on dimension)'
);

-- 4. Update evaluation notes.
select tests.authenticate_as(
  '07070000-0000-0000-0000-000000000001',
  '07070000-0000-0000-0000-00000000000a',
  '07070000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select evaluation.buyer_update_evaluation(
  p_evaluation_id => current_setting('test.eval')::uuid,
  p_commercial_notes => 'pricing acceptable',
  p_overall_notes    => 'strong candidate'
);
reset role;

select is(
  (select overall_notes from evaluation.offer_evaluations
    where id = current_setting('test.eval')::uuid),
  'strong candidate',
  'buyer_update_evaluation patches overall_notes'
);

-- 5. Complete evaluation.
select tests.authenticate_as(
  '07070000-0000-0000-0000-000000000001',
  '07070000-0000-0000-0000-00000000000a',
  '07070000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select evaluation.buyer_complete_evaluation(current_setting('test.eval')::uuid);
reset role;

select is(
  (select status::text from evaluation.offer_evaluations
    where id = current_setting('test.eval')::uuid),
  'completed',
  'buyer_complete_evaluation moves draft → completed'
);

-- 6. buyer_get_evaluation returns scores.
select tests.authenticate_as(
  '07070000-0000-0000-0000-000000000001',
  '07070000-0000-0000-0000-00000000000a',
  '07070000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select is(
  jsonb_array_length(
    (evaluation.buyer_get_evaluation(current_setting('test.eval')::uuid))->'scores'
  ),
  2,
  'buyer_get_evaluation returns scores array of length 2'
);
reset role;

-- 7. Snapshot.
select tests.authenticate_as(
  '07070000-0000-0000-0000-000000000001',
  '07070000-0000-0000-0000-00000000000a',
  '07070000-0000-0000-0000-00000000001a'
);
set local role authenticated;
do $$
declare v_snap uuid;
begin
  v_snap := evaluation.buyer_create_comparison_snapshot(
    p_request_id    => current_setting('test.rfq')::uuid,
    p_title         => 'shortlist v1',
    p_snapshot_data => jsonb_build_object('offers', jsonb_build_array(current_setting('test.offer')))
  );
  perform set_config('test.snap', v_snap::text, false);
end;
$$;
reset role;

select is(
  (select count(*)::int from evaluation.offer_comparison_snapshots
    where id = current_setting('test.snap')::uuid),
  1,
  'buyer_create_comparison_snapshot persists the snapshot row'
);

select * from finish();
rollback;
