-- CC-07 Security Acceptance Test 018 — Supplier shell-creation trigger safety.
--
-- Assertions (4):
--   1. Inserting organization.type='supplier' creates exactly 1 supplier shell.
--   2. Re-running the trigger logic (ON CONFLICT DO NOTHING insert) does NOT
--      create a duplicate. The unique(organization_id) constraint guarantees
--      this even if the trigger were called twice for the same org.
--   3. organization.type='buyer' does NOT create a supplier shell.
--   4. organization.type='carrier' does NOT create a supplier shell.

set search_path = extensions, public, identity, organization, audit, supplier, tests;
begin;

insert into identity.tenants (id, code, name_fa, name_en) values
  ('30100000-0000-0000-0000-00000000000a', 'tenant-018', 'تست', 'Test');

select plan(4);

-- 1. supplier-type org → trigger creates supplier shell
insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('30100000-0000-0000-0000-00000000001a', '30100000-0000-0000-0000-00000000000a',
   'sup-018', 'تأمین', 'Supplier', 'supplier', 'active');

select is(
  (select count(*) from supplier.suppliers
    where organization_id = '30100000-0000-0000-0000-00000000001a'),
  1::bigint,
  'trigger creates exactly one supplier shell on type=supplier insert'
);

-- 2. Re-running the trigger logic via ON CONFLICT DO NOTHING is idempotent
insert into supplier.suppliers (
  tenant_id, organization_id, display_name, status, verification_status
) values (
  '30100000-0000-0000-0000-00000000000a',
  '30100000-0000-0000-0000-00000000001a',
  'تأمین', 'draft', 'unverified'
) on conflict (organization_id) do nothing;

select is(
  (select count(*) from supplier.suppliers
    where organization_id = '30100000-0000-0000-0000-00000000001a'),
  1::bigint,
  'idempotent: ON CONFLICT DO NOTHING prevents duplicate supplier shell'
);

-- 3. buyer-type org → NO supplier shell
insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('30100000-0000-0000-0000-00000000002a', '30100000-0000-0000-0000-00000000000a',
   'buyer-018', 'خریدار', 'Buyer', 'buyer', 'active');

select is(
  (select count(*) from supplier.suppliers
    where organization_id = '30100000-0000-0000-0000-00000000002a'),
  0::bigint,
  'buyer-type organization does NOT create a supplier shell'
);

-- 4. carrier-type org → NO supplier shell
insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('30100000-0000-0000-0000-00000000003a', '30100000-0000-0000-0000-00000000000a',
   'carrier-018', 'حمل‌کننده', 'Carrier', 'carrier', 'active');

select is(
  (select count(*) from supplier.suppliers
    where organization_id = '30100000-0000-0000-0000-00000000003a'),
  0::bigint,
  'carrier-type organization does NOT create a supplier shell'
);

select * from finish();
rollback;
