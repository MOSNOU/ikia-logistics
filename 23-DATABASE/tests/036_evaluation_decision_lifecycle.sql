-- CC-11 Test 036 — Buyer decision lifecycle:
--   buyer_shortlist_offer → buyer_reject_offer → buyer_select_for_contract,
--   verifying decision row, decision events, and offer-status sync semantics.
--
-- Assertions (7):
--   1. shortlist creates decision with status='shortlisted'
--   2. shortlist syncs offer.status -> 'shortlisted'
--   3. reject transitions decision -> 'rejected' and writes a decision event
--   4. reject syncs offer.status -> 'rejected'
--   5. select_for_contract transitions decision -> 'selected_for_contract'
--   6. select_for_contract does NOT change offer.status (stays 'rejected')
--   7. decision_events count = 3 (initial + 2 transitions)

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, tests;
begin;

-- Fixtures: 1 buyer + 1 supplier; one submitted offer.
insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '09090000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '036-buyer@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '09090000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', '036-sup@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('09090000-0000-0000-0000-00000000000a', 'tenant-036', 'تست', 'Test');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('09090000-0000-0000-0000-00000000001a', '09090000-0000-0000-0000-00000000000a',
   'buyer-036', 'خریدار', 'Buyer', 'buyer', 'active'),
  ('09090000-0000-0000-0000-00000000002a', '09090000-0000-0000-0000-00000000000a',
   'sup-036', 'تأمین‌کننده', 'Supplier', 'supplier', 'active');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('09090000-0000-0000-0000-000000000001', '09090000-0000-0000-0000-00000000000a',
   '09090000-0000-0000-0000-00000000001a', 'Buyer', 'fa', 'active'),
  ('09090000-0000-0000-0000-000000000002', '09090000-0000-0000-0000-00000000000a',
   '09090000-0000-0000-0000-00000000002a', 'Supplier', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '09090000-0000-0000-0000-00000000000a', '09090000-0000-0000-0000-00000000001a',
       '09090000-0000-0000-0000-000000000001', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '09090000-0000-0000-0000-00000000000a', '09090000-0000-0000-0000-00000000002a',
       '09090000-0000-0000-0000-000000000002', r.id, 'active', now()
  from identity.roles r where r.code = 'supplier_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '09090000-0000-0000-0000-000000000001', r.id, 'organization', '09090000-0000-0000-0000-00000000001a'
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '09090000-0000-0000-0000-000000000002', r.id, 'organization', '09090000-0000-0000-0000-00000000002a'
  from identity.roles r where r.code = 'supplier_admin';

do $$
declare
  v_sup uuid; v_prod uuid; v_rfq uuid; v_item uuid; v_off uuid;
begin
  select id into v_sup  from supplier.suppliers where organization_id = '09090000-0000-0000-0000-00000000002a';
  select id into v_prod from commodity.products where code = 'methanol';

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','09090000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','09090000-0000-0000-0000-00000000000a',
                       'organization_id','09090000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '09090000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_rfq := rfq.buyer_create_rfq(p_title => 'R for decision lifecycle');
  v_item := rfq.buyer_upsert_rfq_item(p_request_id => v_rfq, p_product_id => v_prod,
                                       p_quantity => 1000, p_quantity_unit => 'ton');
  perform rfq.buyer_submit_rfq(v_rfq);
  perform rfq.buyer_invite_suppliers(v_rfq, array[v_sup]);
  reset role;

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','09090000-0000-0000-0000-000000000002','role','authenticated',
                       'tenant_id','09090000-0000-0000-0000-00000000000a',
                       'organization_id','09090000-0000-0000-0000-00000000002a')::text, true);
  perform set_config('request.jwt.claim.sub', '09090000-0000-0000-0000-000000000002', true);
  set local role authenticated;
  v_off := offer.supplier_create_draft_offer(p_request_id => v_rfq);
  perform offer.supplier_upsert_offer_item(
    p_offer_id => v_off, p_request_item_id => v_item,
    p_offered_quantity => 1000, p_quantity_unit => 'ton',
    p_unit_price => 380, p_currency => 'USD'
  );
  perform offer.supplier_submit_my_offer(v_off);
  reset role;

  perform set_config('test.offer', v_off::text, false);
end;
$$;

select plan(7);

-- 1. Shortlist.
select tests.authenticate_as(
  '09090000-0000-0000-0000-000000000001',
  '09090000-0000-0000-0000-00000000000a',
  '09090000-0000-0000-0000-00000000001a'
);
set local role authenticated;
do $$
declare v_dec uuid;
begin
  v_dec := evaluation.buyer_shortlist_offer(
    p_offer_id => current_setting('test.offer')::uuid,
    p_reason => 'meets all required specs'
  );
  perform set_config('test.dec', v_dec::text, false);
end;
$$;
reset role;

select is(
  (select decision_status::text from evaluation.offer_decisions
    where id = current_setting('test.dec')::uuid),
  'shortlisted',
  'buyer_shortlist_offer creates decision with status=shortlisted'
);

-- 2. Offer status sync to 'shortlisted'.
select is(
  (select status::text from offer.supplier_offers
    where id = current_setting('test.offer')::uuid),
  'shortlisted',
  'shortlist syncs offer.status -> shortlisted'
);

-- 3. Reject.
select tests.authenticate_as(
  '09090000-0000-0000-0000-000000000001',
  '09090000-0000-0000-0000-00000000000a',
  '09090000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select evaluation.buyer_reject_offer(
  p_offer_id => current_setting('test.offer')::uuid,
  p_reason => 'pricing too high'
);
reset role;

select is(
  (select decision_status::text from evaluation.offer_decisions
    where id = current_setting('test.dec')::uuid),
  'rejected',
  'buyer_reject_offer transitions decision -> rejected'
);

-- 4. Offer status sync to 'rejected'.
select is(
  (select status::text from offer.supplier_offers
    where id = current_setting('test.offer')::uuid),
  'rejected',
  'reject syncs offer.status -> rejected'
);

-- 5. select_for_contract.
select tests.authenticate_as(
  '09090000-0000-0000-0000-000000000001',
  '09090000-0000-0000-0000-00000000000a',
  '09090000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select evaluation.buyer_select_for_contract(
  p_offer_id => current_setting('test.offer')::uuid,
  p_reason => 'best of remaining'
);
reset role;

select is(
  (select decision_status::text from evaluation.offer_decisions
    where id = current_setting('test.dec')::uuid),
  'selected_for_contract',
  'buyer_select_for_contract transitions decision -> selected_for_contract'
);

-- 6. Offer status NOT changed by select_for_contract (stays 'rejected').
select is(
  (select status::text from offer.supplier_offers
    where id = current_setting('test.offer')::uuid),
  'rejected',
  'select_for_contract does NOT change offer.status'
);

-- 7. Decision events: initial + 2 transitions = 3 events.
select is(
  (select count(*)::int from evaluation.offer_decision_events
    where decision_id = current_setting('test.dec')::uuid),
  3,
  'decision_events count = 3 (initial + 2 transitions)'
);

select * from finish();
rollback;
