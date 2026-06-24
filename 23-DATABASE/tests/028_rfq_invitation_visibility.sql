-- CC-09 Test 028 — Supplier invitation visibility.
--
-- Assertions (5):
--   1. buyer_invite_suppliers creates invitation rows scoped to the buyer's RFQ
--   2. Invited supplier sees the RFQ via supplier_get_rfq
--   3. Invited supplier sees own invitation in supplier_list_rfq_invitations
--   4. Unrelated supplier raises P0002 from supplier_get_rfq (not invited)
--   5. Unrelated supplier sees 0 rows from supplier_list_rfq_invitations

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, tests;
begin;

-- Fixtures: 1 buyer org A + 2 supplier orgs (X invited, Y not invited).
insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '03030000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '028-buyer@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '03030000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', '028-supX@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '03030000-0000-0000-0000-000000000003', 'authenticated', 'authenticated', '028-supY@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('03030000-0000-0000-0000-00000000000a', 'tenant-028', 'تست', 'Test');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('03030000-0000-0000-0000-00000000001a', '03030000-0000-0000-0000-00000000000a',
   'buyer-028',  'خریدار',     'Buyer',    'buyer',    'active'),
  ('03030000-0000-0000-0000-00000000002a', '03030000-0000-0000-0000-00000000000a',
   'sup-028-X',  'تأمین ایکس', 'Supplier X', 'supplier', 'active'),
  ('03030000-0000-0000-0000-00000000003a', '03030000-0000-0000-0000-00000000000a',
   'sup-028-Y',  'تأمین وای',  'Supplier Y', 'supplier', 'active');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('03030000-0000-0000-0000-000000000001', '03030000-0000-0000-0000-00000000000a',
   '03030000-0000-0000-0000-00000000001a', 'Buyer', 'fa', 'active'),
  ('03030000-0000-0000-0000-000000000002', '03030000-0000-0000-0000-00000000000a',
   '03030000-0000-0000-0000-00000000002a', 'X', 'fa', 'active'),
  ('03030000-0000-0000-0000-000000000003', '03030000-0000-0000-0000-00000000000a',
   '03030000-0000-0000-0000-00000000003a', 'Y', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '03030000-0000-0000-0000-00000000000a', '03030000-0000-0000-0000-00000000001a',
       '03030000-0000-0000-0000-000000000001', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '03030000-0000-0000-0000-00000000000a', '03030000-0000-0000-0000-00000000002a',
       '03030000-0000-0000-0000-000000000002', r.id, 'active', now()
  from identity.roles r where r.code = 'supplier_admin';
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '03030000-0000-0000-0000-00000000000a', '03030000-0000-0000-0000-00000000003a',
       '03030000-0000-0000-0000-000000000003', r.id, 'active', now()
  from identity.roles r where r.code = 'supplier_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '03030000-0000-0000-0000-000000000001', r.id, 'organization', '03030000-0000-0000-0000-00000000001a'
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '03030000-0000-0000-0000-000000000002', r.id, 'organization', '03030000-0000-0000-0000-00000000002a'
  from identity.roles r where r.code = 'supplier_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '03030000-0000-0000-0000-000000000003', r.id, 'organization', '03030000-0000-0000-0000-00000000003a'
  from identity.roles r where r.code = 'supplier_admin';

-- Capture supplier ids and product id.
do $$
declare v_x uuid; v_y uuid; v_prod uuid;
begin
  select id into v_x from supplier.suppliers where organization_id = '03030000-0000-0000-0000-00000000002a';
  select id into v_y from supplier.suppliers where organization_id = '03030000-0000-0000-0000-00000000003a';
  select id into v_prod from commodity.products where code = 'methanol';
  perform set_config('test.sup_x', v_x::text, false);
  perform set_config('test.sup_y', v_y::text, false);
  perform set_config('test.product', v_prod::text, false);
end;
$$;

-- Buyer creates an RFQ, adds an item, submits, invites only supplier X.
select tests.authenticate_as(
  '03030000-0000-0000-0000-000000000001',
  '03030000-0000-0000-0000-00000000000a',
  '03030000-0000-0000-0000-00000000001a'
);
set local role authenticated;
do $$
declare v_rfq uuid;
begin
  v_rfq := rfq.buyer_create_rfq(p_title => 'RFQ for Methanol');
  perform rfq.buyer_upsert_rfq_item(
    p_request_id => v_rfq,
    p_product_id => current_setting('test.product')::uuid,
    p_quantity   => 1000, p_quantity_unit => 'ton'
  );
  perform rfq.buyer_submit_rfq(v_rfq);
  perform rfq.buyer_invite_suppliers(
    v_rfq,
    array[current_setting('test.sup_x')::uuid],
    'Please quote'
  );
  perform set_config('test.rfq', v_rfq::text, false);
end;
$$;
reset role;

select plan(5);

-- 1. invitation rows: exactly 1 invitation row created scoped to the RFQ
select is(
  (select count(*)::int from rfq.request_supplier_invitations
    where request_id = current_setting('test.rfq')::uuid
      and supplier_id = current_setting('test.sup_x')::uuid
      and deleted_at is null),
  1,
  'buyer_invite_suppliers creates exactly one invitation for supplier X'
);

-- 2. invited supplier X sees the RFQ via supplier_get_rfq
select tests.authenticate_as(
  '03030000-0000-0000-0000-000000000002',
  '03030000-0000-0000-0000-00000000000a',
  '03030000-0000-0000-0000-00000000002a'
);
set local role authenticated;
select isnt(
  rfq.supplier_get_rfq(current_setting('test.rfq')::uuid),
  null,
  'invited supplier X can fetch the RFQ via supplier_get_rfq'
);
reset role;

-- 3. invited supplier X sees own invitation in supplier_list_rfq_invitations
select tests.authenticate_as(
  '03030000-0000-0000-0000-000000000002',
  '03030000-0000-0000-0000-00000000000a',
  '03030000-0000-0000-0000-00000000002a'
);
set local role authenticated;
select is(
  (select count(*)::int from rfq.supplier_list_rfq_invitations(null, 100, 0)
     where request_id = current_setting('test.rfq')::uuid),
  1,
  'invited supplier X sees own invitation in supplier_list_rfq_invitations'
);
reset role;

-- 4. unrelated supplier Y → supplier_get_rfq raises P0002
select tests.authenticate_as(
  '03030000-0000-0000-0000-000000000003',
  '03030000-0000-0000-0000-00000000000a',
  '03030000-0000-0000-0000-00000000003a'
);
set local role authenticated;
select throws_ok(
  format($$ select rfq.supplier_get_rfq(%L::uuid) $$, current_setting('test.rfq')),
  'P0002', null,
  'unrelated supplier Y raises P0002 from supplier_get_rfq (not invited)'
);

-- 5. unrelated supplier Y sees 0 invitations
select is(
  (select count(*)::int from rfq.supplier_list_rfq_invitations(null, 100, 0)),
  0,
  'unrelated supplier Y sees 0 rows from supplier_list_rfq_invitations'
);
reset role;

select * from finish();
rollback;
