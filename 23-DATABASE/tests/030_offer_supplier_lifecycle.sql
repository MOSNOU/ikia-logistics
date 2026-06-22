-- CC-10 Test 030 — Supplier offer lifecycle: create draft → item → spec → doc
-- → submit (writes status event) → withdraw.
--
-- Assertions (7):
--   1. supplier_create_draft_offer creates row with status='draft'
--   2. supplier_upsert_offer_item adds an item
--   3. supplier_upsert_spec_response adds a spec response
--   4. supplier_upsert_doc_commitment adds a document commitment
--   5. supplier_submit_my_offer moves status draft → submitted
--   6. submission writes a status_events row (draft → submitted)
--   7. supplier_withdraw_my_offer moves status → withdrawn + soft-deletes

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, tests;
begin;

-- Fixtures: 1 buyer org + 1 supplier org + buyer_admin + supplier_admin.
insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '04040000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '030-buyer@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '04040000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', '030-sup@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('04040000-0000-0000-0000-00000000000a', 'tenant-030', 'تست', 'Test');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('04040000-0000-0000-0000-00000000001a', '04040000-0000-0000-0000-00000000000a',
   'buyer-030', 'خریدار', 'Buyer', 'buyer', 'active'),
  ('04040000-0000-0000-0000-00000000002a', '04040000-0000-0000-0000-00000000000a',
   'sup-030', 'تأمین‌کننده', 'Supplier', 'supplier', 'active');
-- trigger auto-creates supplier shell for the supplier org

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('04040000-0000-0000-0000-000000000001', '04040000-0000-0000-0000-00000000000a',
   '04040000-0000-0000-0000-00000000001a', 'Buyer', 'fa', 'active'),
  ('04040000-0000-0000-0000-000000000002', '04040000-0000-0000-0000-00000000000a',
   '04040000-0000-0000-0000-00000000002a', 'Supplier', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '04040000-0000-0000-0000-00000000000a', '04040000-0000-0000-0000-00000000001a',
       '04040000-0000-0000-0000-000000000001', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '04040000-0000-0000-0000-00000000000a', '04040000-0000-0000-0000-00000000002a',
       '04040000-0000-0000-0000-000000000002', r.id, 'active', now()
  from identity.roles r where r.code = 'supplier_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '04040000-0000-0000-0000-000000000001', r.id, 'organization', '04040000-0000-0000-0000-00000000001a'
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '04040000-0000-0000-0000-000000000002', r.id, 'organization', '04040000-0000-0000-0000-00000000002a'
  from identity.roles r where r.code = 'supplier_admin';

-- Capture supplier id + product id; build RFQ via RPC; invite supplier.
do $$
declare v_sup uuid; v_prod uuid; v_rfq uuid; v_item uuid;
begin
  select id into v_sup  from supplier.suppliers where organization_id = '04040000-0000-0000-0000-00000000002a';
  select id into v_prod from commodity.products where code = 'methanol';
  perform set_config('test.sup', v_sup::text, false);
  perform set_config('test.prod', v_prod::text, false);

  -- Buyer creates RFQ (act as buyer)
  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','04040000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','04040000-0000-0000-0000-00000000000a',
                       'organization_id','04040000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '04040000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_rfq := rfq.buyer_create_rfq(p_title => 'RFQ for offer-lifecycle test');
  v_item := rfq.buyer_upsert_rfq_item(p_request_id => v_rfq, p_product_id => v_prod,
                                      p_quantity => 1000, p_quantity_unit => 'ton');
  perform rfq.buyer_upsert_item_specification(
    p_request_item_id => v_item, p_spec_key => 'purity', p_data_type => 'number',
    p_unit => '%', p_min_value => 99.85, p_is_required => true
  );
  perform rfq.buyer_upsert_doc_requirement(
    p_request_id => v_rfq, p_document_kind => 'coa'::commodity.document_kind
  );
  perform rfq.buyer_submit_rfq(v_rfq);
  perform rfq.buyer_invite_suppliers(v_rfq, array[v_sup]);
  reset role;

  perform set_config('test.rfq', v_rfq::text, false);
  perform set_config('test.item', v_item::text, false);
end;
$$;

select plan(7);

-- Authenticate as supplier and create draft offer.
select tests.authenticate_as(
  '04040000-0000-0000-0000-000000000002',
  '04040000-0000-0000-0000-00000000000a',
  '04040000-0000-0000-0000-00000000002a'
);
set local role authenticated;

do $$
declare v_off uuid;
begin
  v_off := offer.supplier_create_draft_offer(
    p_request_id => current_setting('test.rfq')::uuid,
    p_currency   => 'USD'
  );
  perform set_config('test.offer', v_off::text, false);
end;
$$;
reset role;

-- 1. Draft offer row exists with status='draft'
select is(
  (select status::text from offer.supplier_offers
    where id = current_setting('test.offer')::uuid),
  'draft',
  'supplier_create_draft_offer creates offer with status=draft'
);

-- 2. Add an offer item.
select tests.authenticate_as(
  '04040000-0000-0000-0000-000000000002',
  '04040000-0000-0000-0000-00000000000a',
  '04040000-0000-0000-0000-00000000002a'
);
set local role authenticated;
do $$
declare v_oitem uuid;
begin
  v_oitem := offer.supplier_upsert_offer_item(
    p_offer_id        => current_setting('test.offer')::uuid,
    p_request_item_id => current_setting('test.item')::uuid,
    p_offered_quantity=> 1000,
    p_quantity_unit   => 'ton',
    p_unit_price      => 380,
    p_total_price     => 380000,
    p_currency        => 'USD'
  );
  perform set_config('test.offer_item', v_oitem::text, false);
end;
$$;
reset role;

select is(
  (select count(*)::int from offer.supplier_offer_items
    where offer_id = current_setting('test.offer')::uuid and deleted_at is null),
  1,
  'supplier_upsert_offer_item adds exactly one item'
);

-- 3. Add a spec response.
select tests.authenticate_as(
  '04040000-0000-0000-0000-000000000002',
  '04040000-0000-0000-0000-00000000000a',
  '04040000-0000-0000-0000-00000000002a'
);
set local role authenticated;
select offer.supplier_upsert_spec_response(
  p_offer_item_id   => current_setting('test.offer_item')::uuid,
  p_spec_key        => 'purity',
  p_data_type       => 'number'::commodity.spec_data_type,
  p_unit            => '%',
  p_offered_value   => '99.92',
  p_compliance_status => 'compliant'::offer.compliance_status
);
reset role;

select is(
  (select count(*)::int from offer.supplier_offer_item_specifications
    where offer_item_id = current_setting('test.offer_item')::uuid and deleted_at is null),
  1,
  'supplier_upsert_spec_response adds one spec response'
);

-- 4. Add a doc commitment (offer-level).
select tests.authenticate_as(
  '04040000-0000-0000-0000-000000000002',
  '04040000-0000-0000-0000-00000000000a',
  '04040000-0000-0000-0000-00000000002a'
);
set local role authenticated;
select offer.supplier_upsert_doc_commitment(
  p_offer_id        => current_setting('test.offer')::uuid,
  p_document_kind   => 'coa'::commodity.document_kind,
  p_commitment_status => 'committed'::offer.commitment_status
);
reset role;

select is(
  (select count(*)::int from offer.supplier_offer_document_commitments
    where offer_id = current_setting('test.offer')::uuid and deleted_at is null),
  1,
  'supplier_upsert_doc_commitment adds one document commitment'
);

-- 5. Submit.
select tests.authenticate_as(
  '04040000-0000-0000-0000-000000000002',
  '04040000-0000-0000-0000-00000000000a',
  '04040000-0000-0000-0000-00000000002a'
);
set local role authenticated;
select offer.supplier_submit_my_offer(current_setting('test.offer')::uuid);
reset role;

select is(
  (select status::text from offer.supplier_offers
    where id = current_setting('test.offer')::uuid),
  'submitted',
  'supplier_submit_my_offer moves status draft → submitted'
);

-- 6. Status event was written.
select is(
  (select count(*)::int from offer.supplier_offer_status_events
    where offer_id = current_setting('test.offer')::uuid
      and from_status = 'draft' and to_status = 'submitted'),
  1,
  'submit writes one status_events row draft → submitted'
);

-- 7. Withdraw.
select tests.authenticate_as(
  '04040000-0000-0000-0000-000000000002',
  '04040000-0000-0000-0000-00000000000a',
  '04040000-0000-0000-0000-00000000002a'
);
set local role authenticated;
select offer.supplier_withdraw_my_offer(current_setting('test.offer')::uuid, p_reason => 'pricing changed');
reset role;

select is(
  (
    (select status::text from offer.supplier_offers
       where id = current_setting('test.offer')::uuid) || '|' ||
    case when (select deleted_at from offer.supplier_offers
                where id = current_setting('test.offer')::uuid) is not null
         then 'soft-deleted' else 'active' end
  ),
  'withdrawn|soft-deleted',
  'supplier_withdraw_my_offer sets status=withdrawn and soft-deletes the row'
);

select * from finish();
rollback;
