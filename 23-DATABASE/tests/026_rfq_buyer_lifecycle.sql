-- CC-09 Test 026 — Buyer lifecycle: create, edit, submit, status event written.
--
-- Assertions (7):
--   1. buyer_create_rfq returns uuid; row exists with status='draft'
--   2. buyer_update_rfq updates a draft RFQ
--   3. buyer_upsert_rfq_item adds an item
--   4. buyer_upsert_item_specification adds a spec for the item
--   5. buyer_upsert_doc_requirement adds a doc requirement
--   6. buyer_submit_rfq moves status draft → submitted
--   7. submitting created a row in rfq.request_status_events

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, tests;
begin;

-- Fixtures: 1 buyer org + 1 buyer_admin user + a commodity product.
insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '01010000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '026-buyer@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('01010000-0000-0000-0000-00000000000a', 'tenant-026', 'تست', 'Test');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('01010000-0000-0000-0000-00000000001a', '01010000-0000-0000-0000-00000000000a',
   'buyer-026', 'خریدار', 'Buyer 026', 'buyer', 'active');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('01010000-0000-0000-0000-000000000001', '01010000-0000-0000-0000-00000000000a',
   '01010000-0000-0000-0000-00000000001a', 'Buyer', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '01010000-0000-0000-0000-00000000000a', '01010000-0000-0000-0000-00000000001a',
       '01010000-0000-0000-0000-000000000001', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '01010000-0000-0000-0000-000000000001', r.id, 'organization', '01010000-0000-0000-0000-00000000001a'
  from identity.roles r where r.code = 'buyer_admin';

-- Capture product id (Bitumen 60/70 seeded by CC-08).
do $$
declare v_p uuid;
begin
  select id into v_p from commodity.products where code = 'bitumen_60_70';
  perform set_config('test.product_id', v_p::text, false);
end;
$$;

select plan(7);

-- 1. buyer_create_rfq → uuid; row exists status='draft'.
select tests.authenticate_as(
  '01010000-0000-0000-0000-000000000001',
  '01010000-0000-0000-0000-00000000000a',
  '01010000-0000-0000-0000-00000000001a'
);
set local role authenticated;
do $$
declare v_id uuid;
begin
  v_id := rfq.buyer_create_rfq(
    p_title       => 'RFQ for Bitumen 60/70',
    p_description => 'Q1 2026 supply',
    p_preferred_currency => 'USD'
  );
  perform set_config('test.rfq_id', v_id::text, false);
end;
$$;
reset role;

select is(
  (select status::text from rfq.requests where id = current_setting('test.rfq_id')::uuid),
  'draft',
  'buyer_create_rfq creates RFQ with status=draft'
);

-- 2. buyer_update_rfq edits draft.
select tests.authenticate_as(
  '01010000-0000-0000-0000-000000000001',
  '01010000-0000-0000-0000-00000000000a',
  '01010000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select rfq.buyer_update_rfq(
  current_setting('test.rfq_id')::uuid,
  p_title => 'RFQ for Bitumen 60/70 — revised'
);
reset role;

select is(
  (select title from rfq.requests where id = current_setting('test.rfq_id')::uuid),
  'RFQ for Bitumen 60/70 — revised',
  'buyer_update_rfq edits draft title'
);

-- 3. buyer_upsert_rfq_item adds an item.
select tests.authenticate_as(
  '01010000-0000-0000-0000-000000000001',
  '01010000-0000-0000-0000-00000000000a',
  '01010000-0000-0000-0000-00000000001a'
);
set local role authenticated;
do $$
declare v_iid uuid;
begin
  v_iid := rfq.buyer_upsert_rfq_item(
    p_request_id  => current_setting('test.rfq_id')::uuid,
    p_product_id  => current_setting('test.product_id')::uuid,
    p_quantity    => 5000,
    p_quantity_unit => 'ton'
  );
  perform set_config('test.item_id', v_iid::text, false);
end;
$$;
reset role;

select is(
  (select count(*)::int from rfq.request_items
    where request_id = current_setting('test.rfq_id')::uuid and deleted_at is null),
  1,
  'buyer_upsert_rfq_item adds exactly one item to RFQ'
);

-- 4. buyer_upsert_item_specification adds a spec.
select tests.authenticate_as(
  '01010000-0000-0000-0000-000000000001',
  '01010000-0000-0000-0000-00000000000a',
  '01010000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select rfq.buyer_upsert_item_specification(
  p_request_item_id => current_setting('test.item_id')::uuid,
  p_spec_key        => 'penetration',
  p_display_name_en => 'Penetration at 25°C',
  p_unit            => '0.1mm',
  p_min_value       => 60,
  p_max_value       => 70,
  p_is_required     => true
);
reset role;

select is(
  (select count(*)::int from rfq.request_item_specifications
    where request_item_id = current_setting('test.item_id')::uuid and deleted_at is null),
  1,
  'buyer_upsert_item_specification adds exactly one spec'
);

-- 5. buyer_upsert_doc_requirement adds a request-level doc requirement.
select tests.authenticate_as(
  '01010000-0000-0000-0000-000000000001',
  '01010000-0000-0000-0000-00000000000a',
  '01010000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select rfq.buyer_upsert_doc_requirement(
  p_request_id    => current_setting('test.rfq_id')::uuid,
  p_document_kind => 'coa'::commodity.document_kind
);
reset role;

select is(
  (select count(*)::int from rfq.request_document_requirements
    where request_id = current_setting('test.rfq_id')::uuid and deleted_at is null),
  1,
  'buyer_upsert_doc_requirement adds one doc requirement'
);

-- 6. buyer_submit_rfq: draft → submitted.
select tests.authenticate_as(
  '01010000-0000-0000-0000-000000000001',
  '01010000-0000-0000-0000-00000000000a',
  '01010000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select rfq.buyer_submit_rfq(current_setting('test.rfq_id')::uuid);
reset role;

select is(
  (select status::text from rfq.requests where id = current_setting('test.rfq_id')::uuid),
  'submitted',
  'buyer_submit_rfq moves status draft → submitted'
);

-- 7. Submission wrote a status event.
select is(
  (select count(*)::int from rfq.request_status_events
    where request_id = current_setting('test.rfq_id')::uuid
      and from_status = 'draft' and to_status = 'submitted'),
  1,
  'buyer_submit_rfq writes one status event draft → submitted'
);

select * from finish();
rollback;
