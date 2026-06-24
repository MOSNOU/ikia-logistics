-- CC-07 Security Acceptance Test 017 — Supplier grants + exposure.
-- Proves the grants matrix and the absence of direct write paths.
--
-- Assertions (13):
--   1. anon cannot SELECT supplier.categories            (no grant)
--   2. authenticated CAN SELECT supplier.categories      (12 seeded)
--   3. anon sees 0 supplier.suppliers                    (grant + RLS=0)
--   4. anon sees 0 supplier.supplier_categories          (grant + RLS=0)
--   5. anon sees 0 supplier.supplier_documents           (grant + RLS=0)
--   6. authenticated with NO org context sees 0 supplier.suppliers
--   7. authenticated in UNRELATED org sees 0 supplier.suppliers
--   8. authenticated cannot INSERT supplier.suppliers    (no grant)
--   9. authenticated cannot UPDATE supplier.suppliers    (no grant)
--  10. authenticated cannot DELETE supplier.suppliers    (no grant)
--  11. authenticated cannot INSERT supplier.supplier_documents (no grant)
--  12. authenticated cannot UPDATE supplier.supplier_documents (no grant)
--  13. authenticated cannot DELETE supplier.supplier_documents (no grant)

set search_path = extensions, public, identity, organization, audit, supplier, tests;
begin;

-- Fixtures ------------------------------------------------------------------
insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '20100000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '017-rookie@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '20100000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', '017-other@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '20100000-0000-0000-0000-000000000003', 'authenticated', 'authenticated', '017-orphan@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('20100000-0000-0000-0000-00000000000a', 'tenant-017a', 'الف', 'A'),
  ('20100000-0000-0000-0000-00000000000b', 'tenant-017b', 'ب',  'B');

-- Supplier org A (with auto-shell) + unrelated org B (also supplier-type).
insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('20100000-0000-0000-0000-00000000001a', '20100000-0000-0000-0000-00000000000a',
   'sup-017a', 'تأمین‌کننده الف', 'Supplier A', 'supplier', 'active'),
  ('20100000-0000-0000-0000-00000000001b', '20100000-0000-0000-0000-00000000000b',
   'sup-017b', 'تأمین‌کننده ب',  'Supplier B', 'supplier', 'active');

-- User 1 is a supplier_admin of org A, User 2 is a supplier_admin of org B.
insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('20100000-0000-0000-0000-000000000001', '20100000-0000-0000-0000-00000000000a',
   '20100000-0000-0000-0000-00000000001a', 'A', 'fa', 'active'),
  ('20100000-0000-0000-0000-000000000002', '20100000-0000-0000-0000-00000000000b',
   '20100000-0000-0000-0000-00000000001b', 'B', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '20100000-0000-0000-0000-00000000000a', '20100000-0000-0000-0000-00000000001a',
       '20100000-0000-0000-0000-000000000001', r.id, 'active', now()
  from identity.roles r where r.code = 'supplier_admin';
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '20100000-0000-0000-0000-00000000000b', '20100000-0000-0000-0000-00000000001b',
       '20100000-0000-0000-0000-000000000002', r.id, 'active', now()
  from identity.roles r where r.code = 'supplier_admin';

-- Capture a supplier id + a document id for UPDATE/DELETE attempts.
do $$
declare v_sid uuid; v_did uuid; v_org uuid := '20100000-0000-0000-0000-00000000001a';
begin
  select id into v_sid from supplier.suppliers where organization_id = v_org;
  perform set_config('test.sid', v_sid::text, false);

  insert into supplier.supplier_documents (
    tenant_id, organization_id, supplier_id, document_type, title, status
  ) values (
    '20100000-0000-0000-0000-00000000000a', v_org, v_sid, 'license', 'fixture-doc', 'pending'
  ) returning id into v_did;
  perform set_config('test.did', v_did::text, false);
end;
$$;

select plan(13);

-- ANON ----------------------------------------------------------------------
select tests.set_anon();
set local role anon;

-- 1. anon cannot SELECT supplier.categories
select throws_ok(
  $$ select count(*) from supplier.categories $$,
  '42501', null,
  'anon cannot SELECT supplier.categories (no grant)'
);

-- 3. anon sees 0 supplier.suppliers (grant + RLS)
select is(
  (select count(*) from supplier.suppliers),
  0::bigint,
  'anon sees 0 supplier.suppliers'
);

-- 4. anon sees 0 supplier.supplier_categories
select is(
  (select count(*) from supplier.supplier_categories),
  0::bigint,
  'anon sees 0 supplier.supplier_categories'
);

-- 5. anon sees 0 supplier.supplier_documents
select is(
  (select count(*) from supplier.supplier_documents),
  0::bigint,
  'anon sees 0 supplier.supplier_documents'
);

reset role;

-- AUTHENTICATED (no org context / orphan) -----------------------------------
select tests.authenticate_as('20100000-0000-0000-0000-000000000003');
set local role authenticated;

-- 2. authenticated CAN SELECT supplier.categories
select is(
  (select count(*) from supplier.categories),
  12::bigint,
  'authenticated CAN SELECT supplier.categories (12 seeded)'
);

-- 6. authenticated with no org context (orphan) sees 0 supplier.suppliers
select is(
  (select count(*) from supplier.suppliers),
  0::bigint,
  'authenticated with no org context sees 0 supplier.suppliers'
);

reset role;

-- AUTHENTICATED in UNRELATED org B ------------------------------------------
select tests.authenticate_as(
  '20100000-0000-0000-0000-000000000002',
  '20100000-0000-0000-0000-00000000000b',
  '20100000-0000-0000-0000-00000000001b'
);
set local role authenticated;

-- 7. User B (in org B) cannot see supplier in org A
select is(
  (select count(*) from supplier.suppliers
    where organization_id = '20100000-0000-0000-0000-00000000001a'),
  0::bigint,
  'authenticated in unrelated organization sees 0 supplier A rows'
);

-- 8. authenticated cannot INSERT supplier.suppliers (no GRANT)
select throws_ok(
  $$ insert into supplier.suppliers
       (tenant_id, organization_id, status, verification_status)
     values
       ('20100000-0000-0000-0000-00000000000b'::uuid,
        '20100000-0000-0000-0000-000000000099'::uuid,
        'draft', 'unverified') $$,
  '42501', null,
  'authenticated cannot INSERT supplier.suppliers (no GRANT)'
);

-- 9. authenticated cannot UPDATE supplier.suppliers
select throws_ok(
  format($$ update supplier.suppliers set display_name = 'tamper'
             where id = %L $$, current_setting('test.sid')),
  '42501', null,
  'authenticated cannot UPDATE supplier.suppliers (no GRANT)'
);

-- 10. authenticated cannot DELETE supplier.suppliers
select throws_ok(
  format($$ delete from supplier.suppliers where id = %L $$, current_setting('test.sid')),
  '42501', null,
  'authenticated cannot DELETE supplier.suppliers (no GRANT)'
);

-- 11. authenticated cannot INSERT supplier.supplier_documents
select throws_ok(
  format($$ insert into supplier.supplier_documents
              (tenant_id, organization_id, supplier_id, document_type, title, status)
            values ('20100000-0000-0000-0000-00000000000a'::uuid,
                    '20100000-0000-0000-0000-00000000001a'::uuid,
                    %L::uuid, 'license', 'tampered', 'pending') $$,
         current_setting('test.sid')),
  '42501', null,
  'authenticated cannot INSERT supplier.supplier_documents (no GRANT)'
);

-- 12. authenticated cannot UPDATE supplier.supplier_documents
select throws_ok(
  format($$ update supplier.supplier_documents set title = 'tamper'
             where id = %L $$, current_setting('test.did')),
  '42501', null,
  'authenticated cannot UPDATE supplier.supplier_documents (no GRANT)'
);

-- 13. authenticated cannot DELETE supplier.supplier_documents
select throws_ok(
  format($$ delete from supplier.supplier_documents where id = %L $$, current_setting('test.did')),
  '42501', null,
  'authenticated cannot DELETE supplier.supplier_documents (no GRANT)'
);

reset role;
select * from finish();
rollback;
