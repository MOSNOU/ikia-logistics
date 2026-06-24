-- CC-22 Test 090 — kyc.events is append-only (immutable ledger).
--
-- Assertions (5):
--   1. authenticated cannot UPDATE kyc.events (no policy match → 0 rows or 42501)
--   2. authenticated cannot DELETE kyc.events
--   3. authenticated cannot INSERT into kyc.events directly (no policy match)
--   4. subject sees own events; non-subject sees nothing
--   5. platform_admin sees all events

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  app_storage, finance, settlement, dispute, notify, kyc, tests;
begin;

insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '90000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '090-subject@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '90000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', '090-peer@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '90000000-0000-0000-0000-000000000099', 'authenticated', 'authenticated', '090-admin@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('90000000-0000-0000-0000-00000000000a', 'tenant-090', 'تست', 'Test 090');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('90000000-0000-0000-0000-00000000001a', '90000000-0000-0000-0000-00000000000a',
   'org-090', 'سازمان', 'Org 090', 'buyer', 'active');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('90000000-0000-0000-0000-000000000001', '90000000-0000-0000-0000-00000000000a',
   '90000000-0000-0000-0000-00000000001a', 'Subject', 'fa', 'active'),
  ('90000000-0000-0000-0000-000000000002', '90000000-0000-0000-0000-00000000000a',
   '90000000-0000-0000-0000-00000000001a', 'Peer', 'fa', 'active'),
  ('90000000-0000-0000-0000-000000000099', '90000000-0000-0000-0000-00000000000a',
   '90000000-0000-0000-0000-00000000001a', 'Admin', 'fa', 'active');

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '90000000-0000-0000-0000-000000000099', r.id, 'platform', null
  from identity.roles r where r.code = 'platform_admin';

insert into kyc.personal_verifications (id, tenant_id, user_id, attempt_no, status)
values ('90000000-0000-0000-0000-000000000aa1',
        '90000000-0000-0000-0000-00000000000a',
        '90000000-0000-0000-0000-000000000001', 1, 'draft');

-- Pre-seed an event for the subject to exercise SELECT visibility.
insert into kyc.events (tenant_id, subject_type, user_id,
                       personal_verification_id, event_kind, actor_user_id, payload)
values ('90000000-0000-0000-0000-00000000000a', 'person',
        '90000000-0000-0000-0000-000000000001',
        '90000000-0000-0000-0000-000000000aa1', 'submitted',
        '90000000-0000-0000-0000-000000000001', '{}'::jsonb);

select plan(5);

-- 1. UPDATE as authenticated → 42501 (no UPDATE grant).
select tests.authenticate_as(
  '90000000-0000-0000-0000-000000000001',
  '90000000-0000-0000-0000-00000000000a',
  '90000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select throws_ok(
  $$ update kyc.events set payload = '{"tampered": true}'::jsonb
       where personal_verification_id = '90000000-0000-0000-0000-000000000aa1' $$,
  '42501', null,
  'authenticated UPDATE on kyc.events fails (42501) — append-only'
);
reset role;

-- 2. DELETE as authenticated → 42501.
select tests.authenticate_as(
  '90000000-0000-0000-0000-000000000001',
  '90000000-0000-0000-0000-00000000000a',
  '90000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select throws_ok(
  $$ delete from kyc.events
       where personal_verification_id = '90000000-0000-0000-0000-000000000aa1' $$,
  '42501', null,
  'authenticated DELETE on kyc.events fails (42501) — append-only'
);
reset role;

-- 3. INSERT as authenticated → 42501 (no INSERT grant, no policy match)
select tests.authenticate_as(
  '90000000-0000-0000-0000-000000000001',
  '90000000-0000-0000-0000-00000000000a',
  '90000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select throws_ok(
  $$ insert into kyc.events (tenant_id, subject_type, user_id, event_kind, payload)
     values ('90000000-0000-0000-0000-00000000000a', 'person',
             '90000000-0000-0000-0000-000000000001',
             'approved', '{}'::jsonb) $$,
  '42501', null,
  'authenticated direct INSERT into kyc.events fails (42501)'
);
reset role;

-- 4. Subject sees own events; peer sees nothing.
select tests.authenticate_as(
  '90000000-0000-0000-0000-000000000001',
  '90000000-0000-0000-0000-00000000000a',
  '90000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
do $$
declare v_subj int; v_peer int;
begin
  v_subj := (select count(*)::int from kyc.events
              where user_id = '90000000-0000-0000-0000-000000000001');
  perform set_config('test.subject_events', v_subj::text, false);
end;
$$;
reset role;

select tests.authenticate_as(
  '90000000-0000-0000-0000-000000000002',
  '90000000-0000-0000-0000-00000000000a',
  '90000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
do $$
declare v_peer int;
begin
  v_peer := (select count(*)::int from kyc.events
              where user_id = '90000000-0000-0000-0000-000000000001');
  perform set_config('test.peer_events', v_peer::text, false);
end;
$$;
reset role;

select is(
  current_setting('test.subject_events')::int >= 1
    and current_setting('test.peer_events')::int = 0,
  true,
  'subject sees own events; peer sees none'
);

-- 5. Platform admin sees all
select tests.authenticate_as(
  '90000000-0000-0000-0000-000000000099',
  '90000000-0000-0000-0000-00000000000a',
  '90000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select cmp_ok(
  (select count(*)::int from kyc.events
    where tenant_id = '90000000-0000-0000-0000-00000000000a'),
  '>=', 1,
  'platform_admin sees kyc.events'
);
reset role;

select * from finish();
rollback;
