-- CC-09 Test 027 — Cross-organization isolation + status transition rules.
--
-- Assertions (5):
--   1. Buyer in org A cannot mutate org B's RFQ via buyer_update_rfq (42501)
--   2. Buyer in org A sees only their own org RFQs via buyer_list_rfqs
--   3. buyer_submit_rfq from status='submitted' raises invalid_transition P0001
--   4. buyer_update_rfq when status='submitted' raises P0001 (locked)
--   5. buyer_cancel_rfq from terminal status (cancelled) raises P0001

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, tests;
begin;

-- Two buyer orgs (A and B) with one buyer_admin each.
insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '02020000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '027-A@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '02020000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', '027-B@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('02020000-0000-0000-0000-00000000000a', 'tenant-027a', 'الف', 'A'),
  ('02020000-0000-0000-0000-00000000000b', 'tenant-027b', 'ب',  'B');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('02020000-0000-0000-0000-00000000001a', '02020000-0000-0000-0000-00000000000a',
   'buyer-027a', 'خریدار الف', 'Buyer A', 'buyer', 'active'),
  ('02020000-0000-0000-0000-00000000001b', '02020000-0000-0000-0000-00000000000b',
   'buyer-027b', 'خریدار ب',  'Buyer B', 'buyer', 'active');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('02020000-0000-0000-0000-000000000001', '02020000-0000-0000-0000-00000000000a',
   '02020000-0000-0000-0000-00000000001a', 'A', 'fa', 'active'),
  ('02020000-0000-0000-0000-000000000002', '02020000-0000-0000-0000-00000000000b',
   '02020000-0000-0000-0000-00000000001b', 'B', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '02020000-0000-0000-0000-00000000000a', '02020000-0000-0000-0000-00000000001a',
       '02020000-0000-0000-0000-000000000001', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '02020000-0000-0000-0000-00000000000b', '02020000-0000-0000-0000-00000000001b',
       '02020000-0000-0000-0000-000000000002', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '02020000-0000-0000-0000-000000000001', r.id, 'organization', '02020000-0000-0000-0000-00000000001a'
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '02020000-0000-0000-0000-000000000002', r.id, 'organization', '02020000-0000-0000-0000-00000000001b'
  from identity.roles r where r.code = 'buyer_admin';

-- User A creates an RFQ in org A; user B creates one in org B.
select tests.authenticate_as(
  '02020000-0000-0000-0000-000000000001',
  '02020000-0000-0000-0000-00000000000a',
  '02020000-0000-0000-0000-00000000001a'
);
set local role authenticated;
do $$
declare v_rfq_a uuid;
begin
  v_rfq_a := rfq.buyer_create_rfq(p_title => 'RFQ A');
  perform set_config('test.rfq_a', v_rfq_a::text, false);
end;
$$;
reset role;

select tests.authenticate_as(
  '02020000-0000-0000-0000-000000000002',
  '02020000-0000-0000-0000-00000000000b',
  '02020000-0000-0000-0000-00000000001b'
);
set local role authenticated;
do $$
declare v_rfq_b uuid;
begin
  v_rfq_b := rfq.buyer_create_rfq(p_title => 'RFQ B');
  perform set_config('test.rfq_b', v_rfq_b::text, false);
end;
$$;
reset role;

select plan(5);

-- 1. Buyer A cannot mutate org B's RFQ.
select tests.authenticate_as(
  '02020000-0000-0000-0000-000000000001',
  '02020000-0000-0000-0000-00000000000a',
  '02020000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select throws_ok(
  format($$ select rfq.buyer_update_rfq(%L::uuid, p_title => 'TAMPER') $$,
         current_setting('test.rfq_b')),
  '42501', null,
  'buyer in org A cannot mutate org B RFQ (42501)'
);

-- 2. Buyer A sees only own org's RFQs via buyer_list_rfqs.
select is(
  (select count(*)::int from rfq.buyer_list_rfqs(null, 100, 0)),
  1,
  'buyer_list_rfqs returns only caller org RFQs (1, not 2)'
);
reset role;

-- 3. buyer_submit_rfq from submitted state raises P0001.
select tests.authenticate_as(
  '02020000-0000-0000-0000-000000000001',
  '02020000-0000-0000-0000-00000000000a',
  '02020000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select rfq.buyer_submit_rfq(current_setting('test.rfq_a')::uuid);
select throws_ok(
  format($$ select rfq.buyer_submit_rfq(%L::uuid) $$, current_setting('test.rfq_a')),
  'P0001', null,
  'buyer_submit_rfq from submitted raises invalid_transition (P0001)'
);

-- 4. buyer_update_rfq when status='submitted' raises P0001.
select throws_ok(
  format($$ select rfq.buyer_update_rfq(%L::uuid, p_title => 'NO') $$,
         current_setting('test.rfq_a')),
  'P0001', null,
  'buyer_update_rfq on submitted RFQ raises invalid_transition (P0001)'
);

-- 5. Cancel from terminal state raises P0001.
select rfq.buyer_cancel_rfq(current_setting('test.rfq_a')::uuid, p_reason => 'change of plan');
select throws_ok(
  format($$ select rfq.buyer_cancel_rfq(%L::uuid, p_reason => 'again') $$,
         current_setting('test.rfq_a')),
  'P0001', null,
  'buyer_cancel_rfq from cancelled raises invalid_transition (P0001)'
);
reset role;

select * from finish();
rollback;
