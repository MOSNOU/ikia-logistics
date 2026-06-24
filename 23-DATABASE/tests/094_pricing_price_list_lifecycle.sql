-- CC-23 Test 094 — Price-list lifecycle (draft → active → paused → archived).
--
-- Assertions (12):
--   1. portal_create_price_list returns id; status = 'draft'
--   2. non-member cannot create a list for a supplier (42501)
--   3. unknown currency rejected (22023)
--   4. portal_publish_price_list flips draft → active
--   5. publish refuses non-draft (22023)
--   6. portal_pause_price_list flips active → paused
--   7. portal_archive_price_list flips paused → archived
--   8. cannot publish an archived list (22023)
--   9. portal_create_price_list fires price_list_created event
--  10. portal_publish_price_list fires price_list_published event
--  11. non-member of supplier cannot pause foreign list (42501)
--  12. anon cannot SELECT price_lists (42501)

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  app_storage, finance, settlement, dispute, notify, kyc, pricing,
                  tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '94000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '094-sup-admin@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '94000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', '094-outsider@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('94000000-0000-0000-0000-00000000000a', 'tenant-094', 'تست', 'Test 094');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('94000000-0000-0000-0000-00000000001a', '94000000-0000-0000-0000-00000000000a',
   'sup-org-094', 'سازمان', 'Sup Org 094', 'buyer', 'active'),
  ('94000000-0000-0000-0000-00000000001b', '94000000-0000-0000-0000-00000000000a',
   'other-org-094', 'دیگر', 'Other Org 094', 'buyer', 'active');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('94000000-0000-0000-0000-000000000001', '94000000-0000-0000-0000-00000000000a',
   '94000000-0000-0000-0000-00000000001a', 'Sup Admin', 'fa', 'active'),
  ('94000000-0000-0000-0000-000000000002', '94000000-0000-0000-0000-00000000000a',
   '94000000-0000-0000-0000-00000000001b', 'Outsider', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '94000000-0000-0000-0000-00000000000a',
       '94000000-0000-0000-0000-00000000001a',
       '94000000-0000-0000-0000-000000000001', r.id, 'active', now()
  from identity.roles r where r.code = 'supplier_admin';

insert into supplier.suppliers (id, tenant_id, organization_id, status, verification_status) values
  ('94000000-0000-0000-0000-00000000aaaa',
   '94000000-0000-0000-0000-00000000000a',
   '94000000-0000-0000-0000-00000000001a', 'approved', 'verified');

select plan(12);

-- 1. portal_create_price_list → draft
select tests.authenticate_as(
  '94000000-0000-0000-0000-000000000001',
  '94000000-0000-0000-0000-00000000000a',
  '94000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
do $$
declare v_id uuid;
begin
  v_id := pricing.portal_create_price_list(
    '94000000-0000-0000-0000-00000000aaaa'::uuid,
    'STD-2026', 'Standard 2026', 'استاندارد ۲۰۲۶', 'USD'::char(3), 'baseline catalog'
  );
  perform set_config('test.pl_id', v_id::text, false);
end;
$$;
reset role;

select is(
  (select status::text from pricing.price_lists where id = current_setting('test.pl_id')::uuid),
  'draft',
  'portal_create_price_list creates draft row'
);

-- 2. non-member rejected
select tests.authenticate_as(
  '94000000-0000-0000-0000-000000000002',
  '94000000-0000-0000-0000-00000000000a',
  '94000000-0000-0000-0000-00000000001b'
);
set local role authenticated;
select throws_ok(
  $$ select pricing.portal_create_price_list(
       '94000000-0000-0000-0000-00000000aaaa'::uuid,
       'BAD', 'Bad', 'بد', 'USD'::char(3), null) $$,
  '42501', null,
  'non-member cannot create price_list for a supplier (42501)'
);
reset role;

-- 3. unknown currency rejected
select tests.authenticate_as(
  '94000000-0000-0000-0000-000000000001',
  '94000000-0000-0000-0000-00000000000a',
  '94000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select throws_ok(
  $$ select pricing.portal_create_price_list(
       '94000000-0000-0000-0000-00000000aaaa'::uuid,
       'XYZ-CCY', 'X', 'ایکس', 'XYZ'::char(3), null) $$,
  '22023', null,
  'portal_create_price_list rejects unknown currency (22023)'
);
reset role;

-- 4. publish → active
select tests.authenticate_as(
  '94000000-0000-0000-0000-000000000001',
  '94000000-0000-0000-0000-00000000000a',
  '94000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select pricing.portal_publish_price_list(current_setting('test.pl_id')::uuid, null);
reset role;

select is(
  (select status::text from pricing.price_lists where id = current_setting('test.pl_id')::uuid),
  'active',
  'portal_publish_price_list flips draft → active'
);

-- 5. publish refuses non-draft
select tests.authenticate_as(
  '94000000-0000-0000-0000-000000000001',
  '94000000-0000-0000-0000-00000000000a',
  '94000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select throws_ok(
  format($$ select pricing.portal_publish_price_list(%L::uuid, null) $$,
         current_setting('test.pl_id')),
  '22023', null,
  'portal_publish_price_list refuses non-draft list (22023)'
);
reset role;

-- 6. pause → paused
select tests.authenticate_as(
  '94000000-0000-0000-0000-000000000001',
  '94000000-0000-0000-0000-00000000000a',
  '94000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select pricing.portal_pause_price_list(current_setting('test.pl_id')::uuid, 'inventory rebalance');
reset role;

select is(
  (select status::text from pricing.price_lists where id = current_setting('test.pl_id')::uuid),
  'paused',
  'portal_pause_price_list flips active → paused'
);

-- 7. archive → archived
select tests.authenticate_as(
  '94000000-0000-0000-0000-000000000001',
  '94000000-0000-0000-0000-00000000000a',
  '94000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select pricing.portal_archive_price_list(current_setting('test.pl_id')::uuid, 'eol');
reset role;

select is(
  (select status::text from pricing.price_lists where id = current_setting('test.pl_id')::uuid),
  'archived',
  'portal_archive_price_list flips paused → archived'
);

-- 8. cannot publish archived
select tests.authenticate_as(
  '94000000-0000-0000-0000-000000000001',
  '94000000-0000-0000-0000-00000000000a',
  '94000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select throws_ok(
  format($$ select pricing.portal_publish_price_list(%L::uuid, null) $$,
         current_setting('test.pl_id')),
  '22023', null,
  'portal_publish_price_list refuses archived list (22023)'
);
reset role;

-- 9, 10. events fired
select is(
  (select count(*)::int from pricing.events
    where price_list_id = current_setting('test.pl_id')::uuid
      and event_kind = 'price_list_created'),
  1, 'price_list_created event recorded'
);
select is(
  (select count(*)::int from pricing.events
    where price_list_id = current_setting('test.pl_id')::uuid
      and event_kind = 'price_list_published'),
  1, 'price_list_published event recorded'
);

-- 11. non-member cannot pause foreign list (create a draft then test).
do $$
declare v_id uuid;
begin
  insert into pricing.price_lists (tenant_id, supplier_id, organization_id, code,
                                   name_en, name_fa, currency_code, status)
  values ('94000000-0000-0000-0000-00000000000a',
          '94000000-0000-0000-0000-00000000aaaa',
          '94000000-0000-0000-0000-00000000001a',
          'OTHER-LIST', 'Other', 'دیگر', 'USD', 'active')
  returning id into v_id;
  perform set_config('test.foreign_pl', v_id::text, false);
end;
$$;

select tests.authenticate_as(
  '94000000-0000-0000-0000-000000000002',
  '94000000-0000-0000-0000-00000000000a',
  '94000000-0000-0000-0000-00000000001b'
);
set local role authenticated;
select throws_ok(
  format($$ select pricing.portal_pause_price_list(%L::uuid, null) $$,
         current_setting('test.foreign_pl')),
  '42501', null,
  'non-member of supplier cannot pause foreign list (42501)'
);
reset role;

-- 12. anon cannot SELECT price_lists
select tests.set_anon();
set local role anon;
select throws_ok(
  $$ select count(*) from pricing.price_lists $$,
  '42501', null,
  'anon has no SELECT privilege on pricing.price_lists'
);
reset role;

select * from finish();
rollback;
