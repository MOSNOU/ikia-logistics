-- CC-10 Test 032 — Buyer visibility scope:
--   * buyer sees offers received on own org RFQs (buyer_list_received_offers)
--   * unrelated buyer cannot see another buyer's offer via buyer_get_offer (42501)
--   * unrelated buyer's list returns zero rows for the other buyer's RFQs

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, tests;
begin;

-- Two buyer orgs (A and B) + one supplier invited only to buyer A's RFQ.
insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '06060000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '032-buyerA@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '06060000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', '032-buyerB@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '06060000-0000-0000-0000-000000000003', 'authenticated', 'authenticated', '032-sup@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('06060000-0000-0000-0000-00000000000a', 'tenant-032a', 'الف', 'A'),
  ('06060000-0000-0000-0000-00000000000b', 'tenant-032b', 'ب',  'B');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('06060000-0000-0000-0000-00000000001a', '06060000-0000-0000-0000-00000000000a',
   'buyer-032a', 'خریدار الف', 'Buyer A', 'buyer', 'active'),
  ('06060000-0000-0000-0000-00000000001b', '06060000-0000-0000-0000-00000000000b',
   'buyer-032b', 'خریدار ب',  'Buyer B', 'buyer', 'active'),
  ('06060000-0000-0000-0000-00000000002a', '06060000-0000-0000-0000-00000000000a',
   'sup-032',   'تأمین‌کننده', 'Supplier',  'supplier', 'active');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('06060000-0000-0000-0000-000000000001', '06060000-0000-0000-0000-00000000000a',
   '06060000-0000-0000-0000-00000000001a', 'BuyerA', 'fa', 'active'),
  ('06060000-0000-0000-0000-000000000002', '06060000-0000-0000-0000-00000000000b',
   '06060000-0000-0000-0000-00000000001b', 'BuyerB', 'fa', 'active'),
  ('06060000-0000-0000-0000-000000000003', '06060000-0000-0000-0000-00000000000a',
   '06060000-0000-0000-0000-00000000002a', 'Supplier', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '06060000-0000-0000-0000-00000000000a', '06060000-0000-0000-0000-00000000001a',
       '06060000-0000-0000-0000-000000000001', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '06060000-0000-0000-0000-00000000000b', '06060000-0000-0000-0000-00000000001b',
       '06060000-0000-0000-0000-000000000002', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '06060000-0000-0000-0000-00000000000a', '06060000-0000-0000-0000-00000000002a',
       '06060000-0000-0000-0000-000000000003', r.id, 'active', now()
  from identity.roles r where r.code = 'supplier_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '06060000-0000-0000-0000-000000000001', r.id, 'organization', '06060000-0000-0000-0000-00000000001a'
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '06060000-0000-0000-0000-000000000002', r.id, 'organization', '06060000-0000-0000-0000-00000000001b'
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '06060000-0000-0000-0000-000000000003', r.id, 'organization', '06060000-0000-0000-0000-00000000002a'
  from identity.roles r where r.code = 'supplier_admin';

-- Buyer A creates RFQ, invites supplier. Supplier submits an offer.
do $$
declare
  v_sup uuid; v_prod uuid; v_rfq uuid; v_item uuid; v_off uuid;
begin
  select id into v_sup  from supplier.suppliers where organization_id = '06060000-0000-0000-0000-00000000002a';
  select id into v_prod from commodity.products where code = 'methanol';
  perform set_config('test.sup', v_sup::text, false);
  perform set_config('test.prod', v_prod::text, false);

  -- buyer A creates + invites
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','06060000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','06060000-0000-0000-0000-00000000000a',
                       'organization_id','06060000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '06060000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_rfq := rfq.buyer_create_rfq(p_title => 'R for offer-buyer-visibility');
  v_item := rfq.buyer_upsert_rfq_item(p_request_id => v_rfq, p_product_id => v_prod,
                                      p_quantity => 1000, p_quantity_unit => 'ton');
  perform rfq.buyer_submit_rfq(v_rfq);
  perform rfq.buyer_invite_suppliers(v_rfq, array[v_sup]);
  reset role;

  -- supplier creates draft offer + item + submits
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','06060000-0000-0000-0000-000000000003','role','authenticated',
                       'tenant_id','06060000-0000-0000-0000-00000000000a',
                       'organization_id','06060000-0000-0000-0000-00000000002a')::text, true);
  perform set_config('request.jwt.claim.sub', '06060000-0000-0000-0000-000000000003', true);
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

select plan(3);

-- 1. Buyer A sees their received offer via buyer_list_received_offers.
select tests.authenticate_as(
  '06060000-0000-0000-0000-000000000001',
  '06060000-0000-0000-0000-00000000000a',
  '06060000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select is(
  (select count(*)::int from offer.buyer_list_received_offers(null, null, 100, 0)),
  1,
  'buyer A sees own RFQ offer in buyer_list_received_offers'
);
reset role;

-- 2. Buyer B's list returns 0 rows (the offer is on buyer A's RFQ).
select tests.authenticate_as(
  '06060000-0000-0000-0000-000000000002',
  '06060000-0000-0000-0000-00000000000b',
  '06060000-0000-0000-0000-00000000001b'
);
set local role authenticated;
select is(
  (select count(*)::int from offer.buyer_list_received_offers(null, null, 100, 0)),
  0,
  'buyer B sees 0 offers — RFQ owner is buyer A'
);

-- 3. Buyer B cannot read the offer detail via buyer_get_offer (42501).
select throws_ok(
  format($$ select offer.buyer_get_offer(%L::uuid) $$, current_setting('test.offer')),
  '42501', null,
  'buyer B cannot read offer on buyer A''s RFQ (42501)'
);
reset role;

select * from finish();
rollback;
