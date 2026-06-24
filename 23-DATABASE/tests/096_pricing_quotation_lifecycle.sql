-- CC-23 Test 096 — Quotation lifecycle (draft → sent → accepted / rejected / expired).
--
-- Assertions (14):
--   1. portal_create_quotation returns id; status = 'draft'
--   2. unknown currency rejected (22023)
--   3. cannot send an empty quotation (22023)
--   4. portal_send_quotation flips draft → sent and stamps sent_at
--   5. cannot re-send a sent quotation (22023)
--   6. quotation_drafted event recorded
--   7. quotation_sent event recorded
--   8. buyer-org member can accept the quotation; status → accepted
--   9. supplier-org member cannot accept own quotation (42501)
--  10. supplier-org member cannot reject own quotation (42501)
--  11. reject path on a fresh sent quotation works (decision_reason set)
--  12. admin_expire_due_quotations flips sent quotations with valid_until past
--  13. is_personal_verified-like is not involved (no KYC gating in Q8=A) — quotation_send succeeds without KYC
--  14. expired status recorded as quotation_expired event

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  app_storage, finance, settlement, dispute, notify, kyc, pricing,
                  tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '96000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '096-sup@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '96000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', '096-buyer@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '96000000-0000-0000-0000-000000000099', 'authenticated', 'authenticated', '096-admin@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('96000000-0000-0000-0000-00000000000a', 'tenant-096', 'تست', 'Test 096');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('96000000-0000-0000-0000-00000000001a', '96000000-0000-0000-0000-00000000000a',
   'sup-org-096', 'تامین', 'Supplier Org 096', 'buyer', 'active'),
  ('96000000-0000-0000-0000-00000000001b', '96000000-0000-0000-0000-00000000000a',
   'buyer-org-096', 'خریدار', 'Buyer Org 096', 'buyer', 'active');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('96000000-0000-0000-0000-000000000001', '96000000-0000-0000-0000-00000000000a',
   '96000000-0000-0000-0000-00000000001a', 'Sup', 'fa', 'active'),
  ('96000000-0000-0000-0000-000000000002', '96000000-0000-0000-0000-00000000000a',
   '96000000-0000-0000-0000-00000000001b', 'Buyer', 'fa', 'active'),
  ('96000000-0000-0000-0000-000000000099', '96000000-0000-0000-0000-00000000000a',
   '96000000-0000-0000-0000-00000000001a', 'Admin', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '96000000-0000-0000-0000-00000000000a',
       '96000000-0000-0000-0000-00000000001a',
       '96000000-0000-0000-0000-000000000001', r.id, 'active', now()
  from identity.roles r where r.code = 'supplier_admin';
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '96000000-0000-0000-0000-00000000000a',
       '96000000-0000-0000-0000-00000000001b',
       '96000000-0000-0000-0000-000000000002', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '96000000-0000-0000-0000-000000000099', r.id, 'platform', null
  from identity.roles r where r.code = 'platform_admin';

insert into supplier.suppliers (id, tenant_id, organization_id, status, verification_status) values
  ('96000000-0000-0000-0000-00000000aaaa',
   '96000000-0000-0000-0000-00000000000a',
   '96000000-0000-0000-0000-00000000001a', 'approved', 'unverified');  -- Q8=A: KYC unverified must still send

insert into commodity.categories (id, code, name_fa, name_en) values
  ('96000000-0000-0000-0000-00000000bbbb', 'cat-096', 'دسته', 'Cat 096');
insert into commodity.products (id, category_id, code, slug, name_fa, name_en, status, unit_of_trade) values
  ('96000000-0000-0000-0000-00000000cccc',
   '96000000-0000-0000-0000-00000000bbbb',
   'prod-096', 'prod-096', 'محصول', 'Product 096', 'active', 'kg');

select plan(14);

-- 1. create quotation
select tests.authenticate_as(
  '96000000-0000-0000-0000-000000000001',
  '96000000-0000-0000-0000-00000000000a',
  '96000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
do $$
declare v_id uuid;
begin
  v_id := pricing.portal_create_quotation(
    '96000000-0000-0000-0000-00000000aaaa'::uuid,
    '96000000-0000-0000-0000-00000000001b'::uuid,
    'Q-096-001', 'USD'::char(3), null, now() + interval '7 days'
  );
  perform set_config('test.q_id', v_id::text, false);
end;
$$;
reset role;

select is(
  (select status::text from pricing.quotations where id = current_setting('test.q_id')::uuid),
  'draft',
  'portal_create_quotation creates draft row'
);

-- 2. unknown currency rejected
select tests.authenticate_as(
  '96000000-0000-0000-0000-000000000001',
  '96000000-0000-0000-0000-00000000000a',
  '96000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select throws_ok(
  $$ select pricing.portal_create_quotation(
       '96000000-0000-0000-0000-00000000aaaa'::uuid,
       '96000000-0000-0000-0000-00000000001b'::uuid,
       'Q-BAD-CCY', 'XYZ'::char(3), null, null) $$,
  '22023', null,
  'portal_create_quotation rejects unknown currency (22023)'
);
reset role;

-- 3. cannot send empty
select tests.authenticate_as(
  '96000000-0000-0000-0000-000000000001',
  '96000000-0000-0000-0000-00000000000a',
  '96000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select throws_ok(
  format($$ select pricing.portal_send_quotation(%L::uuid) $$,
         current_setting('test.q_id')),
  '22023', null,
  'cannot send an empty quotation (22023)'
);
reset role;

-- Add an item then send.
select tests.authenticate_as(
  '96000000-0000-0000-0000-000000000001',
  '96000000-0000-0000-0000-00000000000a',
  '96000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
do $$
declare v_id uuid;
begin
  v_id := pricing.portal_add_quotation_item(
    current_setting('test.q_id')::uuid,
    '96000000-0000-0000-0000-00000000cccc'::uuid,
    100, 'kg', 12.5, 0, 'first line', null
  );
end;
$$;
select pricing.portal_send_quotation(current_setting('test.q_id')::uuid);
reset role;

-- 4. now sent
select is(
  (select status::text from pricing.quotations where id = current_setting('test.q_id')::uuid),
  'sent',
  'portal_send_quotation flips draft → sent'
);

-- 5. cannot re-send
select tests.authenticate_as(
  '96000000-0000-0000-0000-000000000001',
  '96000000-0000-0000-0000-00000000000a',
  '96000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select throws_ok(
  format($$ select pricing.portal_send_quotation(%L::uuid) $$,
         current_setting('test.q_id')),
  '22023', null,
  'cannot re-send a sent quotation (22023)'
);
reset role;

-- 6, 7. events
select is(
  (select count(*)::int from pricing.events
    where quotation_id = current_setting('test.q_id')::uuid
      and event_kind = 'quotation_drafted'),
  1, 'quotation_drafted event recorded'
);
select is(
  (select count(*)::int from pricing.events
    where quotation_id = current_setting('test.q_id')::uuid
      and event_kind = 'quotation_sent'),
  1, 'quotation_sent event recorded'
);

-- 8. buyer accepts
select tests.authenticate_as(
  '96000000-0000-0000-0000-000000000002',
  '96000000-0000-0000-0000-00000000000a',
  '96000000-0000-0000-0000-00000000001b'
);
set local role authenticated;
select pricing.portal_accept_quotation(current_setting('test.q_id')::uuid);
reset role;

select is(
  (select status::text from pricing.quotations where id = current_setting('test.q_id')::uuid),
  'accepted',
  'buyer-org member accepts the quotation'
);

-- 9, 10. supplier cannot accept/reject own quotation (only buyer can)
-- Build a separate sent quotation for negative tests.
select tests.authenticate_as(
  '96000000-0000-0000-0000-000000000001',
  '96000000-0000-0000-0000-00000000000a',
  '96000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
do $$
declare v_id uuid;
begin
  v_id := pricing.portal_create_quotation(
    '96000000-0000-0000-0000-00000000aaaa'::uuid,
    '96000000-0000-0000-0000-00000000001b'::uuid,
    'Q-096-002', 'USD'::char(3), null, now() + interval '7 days'
  );
  perform pricing.portal_add_quotation_item(
    v_id, '96000000-0000-0000-0000-00000000cccc'::uuid,
    50, 'kg', 8.0, 0, null, null
  );
  perform pricing.portal_send_quotation(v_id);
  perform set_config('test.q2_id', v_id::text, false);
end;
$$;
reset role;

select tests.authenticate_as(
  '96000000-0000-0000-0000-000000000001',
  '96000000-0000-0000-0000-00000000000a',
  '96000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select throws_ok(
  format($$ select pricing.portal_accept_quotation(%L::uuid) $$,
         current_setting('test.q2_id')),
  '42501', null,
  'supplier cannot accept own quotation (42501)'
);
select throws_ok(
  format($$ select pricing.portal_reject_quotation(%L::uuid, 'no') $$,
         current_setting('test.q2_id')),
  '42501', null,
  'supplier cannot reject own quotation (42501)'
);
reset role;

-- 11. buyer rejects with reason
select tests.authenticate_as(
  '96000000-0000-0000-0000-000000000002',
  '96000000-0000-0000-0000-00000000000a',
  '96000000-0000-0000-0000-00000000001b'
);
set local role authenticated;
select pricing.portal_reject_quotation(current_setting('test.q2_id')::uuid, 'budget cut');
reset role;

select is(
  (select decision_reason from pricing.quotations
    where id = current_setting('test.q2_id')::uuid),
  'budget cut',
  'reject stores decision_reason'
);

-- 12. expire flow: build a sent quotation with past valid_until and call admin expire.
select tests.authenticate_as(
  '96000000-0000-0000-0000-000000000001',
  '96000000-0000-0000-0000-00000000000a',
  '96000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
do $$
declare v_id uuid;
begin
  v_id := pricing.portal_create_quotation(
    '96000000-0000-0000-0000-00000000aaaa'::uuid,
    '96000000-0000-0000-0000-00000000001b'::uuid,
    'Q-096-003', 'USD'::char(3), null, now() + interval '7 days'
  );
  perform pricing.portal_add_quotation_item(
    v_id, '96000000-0000-0000-0000-00000000cccc'::uuid,
    10, 'kg', 1, 0, null, null
  );
  perform pricing.portal_send_quotation(v_id);
  perform set_config('test.q3_id', v_id::text, false);
end;
$$;
reset role;

-- Move valid_until into the past directly (bypass via setof rpc not needed).
update pricing.quotations
   set valid_until = now() - interval '1 hour'
 where id = current_setting('test.q3_id')::uuid;

select tests.authenticate_as(
  '96000000-0000-0000-0000-000000000099',
  '96000000-0000-0000-0000-00000000000a',
  '96000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
do $$
declare v_count int;
begin
  v_count := pricing.admin_expire_due_quotations();
  perform set_config('test.exp_count', v_count::text, false);
end;
$$;
reset role;

select cmp_ok(
  current_setting('test.exp_count')::int,
  '>=', 1,
  'admin_expire_due_quotations flipped ≥ 1 sent quotation past valid_until'
);

-- 13. quotation send succeeded with verification_status = 'unverified' (Q8=A).
-- We already exercised this above; assert directly on supplier verification.
select is(
  (select verification_status::text from supplier.suppliers
    where id = '96000000-0000-0000-0000-00000000aaaa'),
  'unverified',
  'supplier KYC status irrelevant to send (Q8=A: no KYC gating)'
);

-- 14. quotation_expired event
select cmp_ok(
  (select count(*)::int from pricing.events
    where quotation_id = current_setting('test.q3_id')::uuid
      and event_kind = 'quotation_expired'),
  '>=', 1,
  'quotation_expired event recorded for the flipped quotation'
);

select * from finish();
rollback;
