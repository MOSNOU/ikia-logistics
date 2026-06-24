-- CC-11 Test 037 — Supplier visibility into buyer decisions on their own offers:
--   * supplier sees their own decision via supplier_list_my_decisions
--   * supplier gets decision detail via supplier_get_my_decision
--   * unrelated supplier sees 0 decisions and cannot read another supplier's decision
--   * supplier CANNOT see evaluation rows (evaluation is buyer-private)

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, tests;
begin;

-- 1 buyer + 2 suppliers (X invited, Y not). Buyer shortlists X's offer.
insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '0a0a0000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '037-buyer@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '0a0a0000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', '037-supX@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '0a0a0000-0000-0000-0000-000000000003', 'authenticated', 'authenticated', '037-supY@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('0a0a0000-0000-0000-0000-00000000000a', 'tenant-037', 'تست', 'Test');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('0a0a0000-0000-0000-0000-00000000001a', '0a0a0000-0000-0000-0000-00000000000a',
   'buyer-037', 'خریدار', 'Buyer', 'buyer', 'active'),
  ('0a0a0000-0000-0000-0000-00000000002a', '0a0a0000-0000-0000-0000-00000000000a',
   'sup-037-X', 'ایکس', 'SupX', 'supplier', 'active'),
  ('0a0a0000-0000-0000-0000-00000000002b', '0a0a0000-0000-0000-0000-00000000000a',
   'sup-037-Y', 'وای',  'SupY', 'supplier', 'active');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('0a0a0000-0000-0000-0000-000000000001', '0a0a0000-0000-0000-0000-00000000000a',
   '0a0a0000-0000-0000-0000-00000000001a', 'Buyer', 'fa', 'active'),
  ('0a0a0000-0000-0000-0000-000000000002', '0a0a0000-0000-0000-0000-00000000000a',
   '0a0a0000-0000-0000-0000-00000000002a', 'SupX', 'fa', 'active'),
  ('0a0a0000-0000-0000-0000-000000000003', '0a0a0000-0000-0000-0000-00000000000a',
   '0a0a0000-0000-0000-0000-00000000002b', 'SupY', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '0a0a0000-0000-0000-0000-00000000000a', '0a0a0000-0000-0000-0000-00000000001a',
       '0a0a0000-0000-0000-0000-000000000001', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '0a0a0000-0000-0000-0000-00000000000a', '0a0a0000-0000-0000-0000-00000000002a',
       '0a0a0000-0000-0000-0000-000000000002', r.id, 'active', now()
  from identity.roles r where r.code = 'supplier_admin';
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '0a0a0000-0000-0000-0000-00000000000a', '0a0a0000-0000-0000-0000-00000000002b',
       '0a0a0000-0000-0000-0000-000000000003', r.id, 'active', now()
  from identity.roles r where r.code = 'supplier_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '0a0a0000-0000-0000-0000-000000000001', r.id, 'organization', '0a0a0000-0000-0000-0000-00000000001a'
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '0a0a0000-0000-0000-0000-000000000002', r.id, 'organization', '0a0a0000-0000-0000-0000-00000000002a'
  from identity.roles r where r.code = 'supplier_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '0a0a0000-0000-0000-0000-000000000003', r.id, 'organization', '0a0a0000-0000-0000-0000-00000000002b'
  from identity.roles r where r.code = 'supplier_admin';

do $$
declare
  v_supX uuid; v_prod uuid; v_rfq uuid; v_item uuid; v_off uuid; v_eval uuid; v_dec uuid;
begin
  select id into v_supX from supplier.suppliers where organization_id = '0a0a0000-0000-0000-0000-00000000002a';
  select id into v_prod from commodity.products where code = 'methanol';

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','0a0a0000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','0a0a0000-0000-0000-0000-00000000000a',
                       'organization_id','0a0a0000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '0a0a0000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_rfq := rfq.buyer_create_rfq(p_title => 'R for supplier visibility');
  v_item := rfq.buyer_upsert_rfq_item(p_request_id => v_rfq, p_product_id => v_prod,
                                       p_quantity => 1000, p_quantity_unit => 'ton');
  perform rfq.buyer_submit_rfq(v_rfq);
  perform rfq.buyer_invite_suppliers(v_rfq, array[v_supX]);
  reset role;

  -- supplier X submits offer
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','0a0a0000-0000-0000-0000-000000000002','role','authenticated',
                       'tenant_id','0a0a0000-0000-0000-0000-00000000000a',
                       'organization_id','0a0a0000-0000-0000-0000-00000000002a')::text, true);
  perform set_config('request.jwt.claim.sub', '0a0a0000-0000-0000-0000-000000000002', true);
  set local role authenticated;
  v_off := offer.supplier_create_draft_offer(p_request_id => v_rfq);
  perform offer.supplier_upsert_offer_item(
    p_offer_id => v_off, p_request_item_id => v_item,
    p_offered_quantity => 1000, p_quantity_unit => 'ton',
    p_unit_price => 380, p_currency => 'USD'
  );
  perform offer.supplier_submit_my_offer(v_off);
  reset role;

  -- buyer shortlists + creates evaluation
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','0a0a0000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','0a0a0000-0000-0000-0000-00000000000a',
                       'organization_id','0a0a0000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '0a0a0000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_eval := evaluation.buyer_create_evaluation(p_offer_id => v_off);
  v_dec := evaluation.buyer_shortlist_offer(p_offer_id => v_off);
  reset role;

  perform set_config('test.offer', v_off::text, false);
  perform set_config('test.eval',  v_eval::text, false);
  perform set_config('test.dec',   v_dec::text, false);
end;
$$;

select plan(5);

-- 1. Supplier X sees their own decision via supplier_list_my_decisions.
select tests.authenticate_as(
  '0a0a0000-0000-0000-0000-000000000002',
  '0a0a0000-0000-0000-0000-00000000000a',
  '0a0a0000-0000-0000-0000-00000000002a'
);
set local role authenticated;
select is(
  (select count(*)::int from evaluation.supplier_list_my_decisions(null, 100, 0)),
  1,
  'supplier X sees their own decision via supplier_list_my_decisions'
);
reset role;

-- 2. Supplier X reads decision detail via supplier_get_my_decision.
select tests.authenticate_as(
  '0a0a0000-0000-0000-0000-000000000002',
  '0a0a0000-0000-0000-0000-00000000000a',
  '0a0a0000-0000-0000-0000-00000000002a'
);
set local role authenticated;
select is(
  (evaluation.supplier_get_my_decision(current_setting('test.dec')::uuid))->>'decision_status',
  'shortlisted',
  'supplier_get_my_decision returns decision_status=shortlisted'
);
reset role;

-- 3. Supplier Y sees 0 decisions.
select tests.authenticate_as(
  '0a0a0000-0000-0000-0000-000000000003',
  '0a0a0000-0000-0000-0000-00000000000a',
  '0a0a0000-0000-0000-0000-00000000002b'
);
set local role authenticated;
select is(
  (select count(*)::int from evaluation.supplier_list_my_decisions(null, 100, 0)),
  0,
  'supplier Y sees 0 decisions (none of their offers)'
);

-- 4. Supplier Y cannot read supplier X's decision (42501).
select throws_ok(
  format($$ select evaluation.supplier_get_my_decision(%L::uuid) $$, current_setting('test.dec')),
  '42501', null,
  'supplier Y cannot read supplier X''s decision (42501)'
);
reset role;

-- 5. Supplier cannot see evaluation rows (evaluation is buyer-private).
select tests.authenticate_as(
  '0a0a0000-0000-0000-0000-000000000002',
  '0a0a0000-0000-0000-0000-00000000000a',
  '0a0a0000-0000-0000-0000-00000000002a'
);
set local role authenticated;
select is(
  (select count(*)::int from evaluation.offer_evaluations
    where id = current_setting('test.eval')::uuid),
  0,
  'supplier cannot see evaluation rows via direct SELECT (RLS blocks)'
);
reset role;

select * from finish();
rollback;
