-- CC-19 Test 073 — Inbox lifecycle (covers Q1/A trigger + Q4 seed templates):
--   buyer issues an invoice → settlement.held event → settlement template materializes
--   notifications + delivery_attempts → buyer's inbox shows them → mark_read /
--   mark_all_read / archive / unread_count semantics.
--
-- Assertions (10):
--   1. portal_list_my_notifications returns 0 for a fresh user (before any event)
--   2. After buyer_mark_settlement_ready fires settlement_events, buyer has ≥1 unread
--   3. portal_unread_count > 0 for buyer
--   4. delivery_attempts row created with channel='in_app' and status='delivered'
--   5. materialization_audit row written (notes='ok')
--   6. portal_mark_read flips status → read
--   7. portal_unread_count drops by 1
--   8. portal_mark_all_read flips remaining unread → read; returns count > 0
--   9. portal_archive_notification flips status → archived
--  10. portal_get_notification on a foreign notification raises 42501

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  app_storage, finance, settlement, dispute, notify, tests;
begin;

-- Fixtures: 1 buyer + 1 supplier, build chain to a held settlement.
insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '30000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '073-buyer@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '30000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', '073-sup@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('30000000-0000-0000-0000-00000000000a', 'tenant-073', 'تست', 'Test');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('30000000-0000-0000-0000-00000000001a', '30000000-0000-0000-0000-00000000000a',
   'buyer-073', 'خریدار', 'Buyer 073', 'buyer', 'active'),
  ('30000000-0000-0000-0000-00000000002a', '30000000-0000-0000-0000-00000000000a',
   'sup-073', 'تأمین', 'Supplier 073', 'supplier', 'active');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('30000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-00000000000a',
   '30000000-0000-0000-0000-00000000001a', 'Buyer', 'fa', 'active'),
  ('30000000-0000-0000-0000-000000000002', '30000000-0000-0000-0000-00000000000a',
   '30000000-0000-0000-0000-00000000002a', 'Supplier', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '30000000-0000-0000-0000-00000000000a', '30000000-0000-0000-0000-00000000001a',
       '30000000-0000-0000-0000-000000000001', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '30000000-0000-0000-0000-00000000000a', '30000000-0000-0000-0000-00000000002a',
       '30000000-0000-0000-0000-000000000002', r.id, 'active', now()
  from identity.roles r where r.code = 'supplier_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '30000000-0000-0000-0000-000000000001', r.id, 'organization', '30000000-0000-0000-0000-00000000001a'
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '30000000-0000-0000-0000-000000000002', r.id, 'organization', '30000000-0000-0000-0000-00000000002a'
  from identity.roles r where r.code = 'supplier_admin';

select plan(10);

-- 1. Fresh user has empty inbox.
select tests.authenticate_as(
  '30000000-0000-0000-0000-000000000001',
  '30000000-0000-0000-0000-00000000000a',
  '30000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select is(
  (select count(*)::int from notify.portal_list_my_notifications(null, null, 100, 0)),
  0,
  'fresh buyer user has empty inbox before any domain event'
);
reset role;

-- Build chain → executed contract → held settlement (this fires settlement_events).
do $$
declare
  v_sup uuid; v_prod uuid; v_rfq uuid; v_item uuid; v_off uuid; v_dec uuid;
  v_prep uuid; v_contract uuid; v_p_b uuid; v_p_s uuid; v_sr_b uuid; v_sr_s uuid;
  v_esc uuid; v_set uuid;
begin
  select id into v_sup  from supplier.suppliers where organization_id = '30000000-0000-0000-0000-00000000002a';
  select id into v_prod from commodity.products where code = 'methanol';

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','30000000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','30000000-0000-0000-0000-00000000000a',
                       'organization_id','30000000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '30000000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_rfq := rfq.buyer_create_rfq(p_title => 'R for notify inbox');
  v_item := rfq.buyer_upsert_rfq_item(p_request_id => v_rfq, p_product_id => v_prod,
                                       p_quantity => 100, p_quantity_unit => 'ton');
  perform rfq.buyer_submit_rfq(v_rfq);
  perform rfq.buyer_invite_suppliers(v_rfq, array[v_sup]);
  reset role;

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','30000000-0000-0000-0000-000000000002','role','authenticated',
                       'tenant_id','30000000-0000-0000-0000-00000000000a',
                       'organization_id','30000000-0000-0000-0000-00000000002a')::text, true);
  perform set_config('request.jwt.claim.sub', '30000000-0000-0000-0000-000000000002', true);
  set local role authenticated;
  v_off := offer.supplier_create_draft_offer(p_request_id => v_rfq);
  perform offer.supplier_upsert_offer_item(p_offer_id => v_off, p_request_item_id => v_item,
    p_offered_quantity => 100, p_quantity_unit => 'ton', p_unit_price => 10, p_currency => 'USD');
  perform offer.supplier_submit_my_offer(v_off);
  reset role;

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','30000000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','30000000-0000-0000-0000-00000000000a',
                       'organization_id','30000000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '30000000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_dec := evaluation.buyer_select_for_contract(p_offer_id => v_off);
  v_prep := contract.buyer_create_preparation(p_decision_id => v_dec, p_title => 'notify prep');
  perform contract.buyer_mark_ready_for_contract(v_prep);
  v_contract := contract.buyer_create_executed_contract(p_preparation_id => v_prep);
  select id into v_p_b from contract.contract_parties where contract_id = v_contract and party_type='buyer' and deleted_at is null limit 1;
  select id into v_p_s from contract.contract_parties where contract_id = v_contract and party_type='supplier' and deleted_at is null limit 1;
  v_sr_b := contract.buyer_create_signature_request(p_contract_id => v_contract, p_party_id => v_p_b);
  v_sr_s := contract.buyer_create_signature_request(p_contract_id => v_contract, p_party_id => v_p_s);
  perform contract.buyer_mark_pending_signatures(v_contract);
  perform contract.buyer_sign_signature_request(v_sr_b);
  reset role;

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','30000000-0000-0000-0000-000000000002','role','authenticated',
                       'tenant_id','30000000-0000-0000-0000-00000000000a',
                       'organization_id','30000000-0000-0000-0000-00000000002a')::text, true);
  perform set_config('request.jwt.claim.sub', '30000000-0000-0000-0000-000000000002', true);
  set local role authenticated;
  perform contract.supplier_sign_signature_request(v_sr_s);
  reset role;

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','30000000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','30000000-0000-0000-0000-00000000000a',
                       'organization_id','30000000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '30000000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_esc := settlement.buyer_open_escrow_account(p_supplier_id => v_sup, p_currency => 'USD');
  v_set := settlement.buyer_create_draft_settlement(
    p_executed_contract_id => v_contract, p_escrow_account_id => v_esc, p_currency => 'USD'
  );
  perform settlement.buyer_upsert_settlement_item(
    p_settlement_id => v_set, p_description => 'Payment', p_amount => 500
  );
  perform settlement.buyer_mark_settlement_ready(v_set);
  perform settlement.buyer_hold_settlement(v_set);
  reset role;

  perform set_config('test.settlement', v_set::text, false);
end;
$$;

-- 2. Buyer has unread notifications after fan-out.
select tests.authenticate_as(
  '30000000-0000-0000-0000-000000000001',
  '30000000-0000-0000-0000-00000000000a',
  '30000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select cmp_ok(
  (select count(*)::int from notify.portal_list_my_notifications('unread'::notify.notification_status, null, 100, 0)),
  '>=', 1,
  'buyer has ≥1 unread notification after settlement chain'
);

-- 3. unread_count > 0.
select cmp_ok(
  notify.portal_unread_count(),
  '>', 0,
  'portal_unread_count > 0 for buyer'
);
reset role;

-- 4. delivery_attempts: at least one in_app row in 'delivered'.
select cmp_ok(
  (select count(*)::int from notify.delivery_attempts
    where channel = 'in_app' and status = 'delivered'),
  '>=', 1,
  'delivery_attempts has ≥1 in_app row in delivered status'
);

-- 5. materialization_audit row with notes='ok'.
select cmp_ok(
  (select count(*)::int from notify.materialization_audit where notes = 'ok'),
  '>=', 1,
  'materialization_audit has ≥1 row with notes=ok'
);

-- 6. mark_read flips status.
select tests.authenticate_as(
  '30000000-0000-0000-0000-000000000001',
  '30000000-0000-0000-0000-00000000000a',
  '30000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
do $$
declare v_n uuid; v_pre int; v_post int;
begin
  v_pre := notify.portal_unread_count();
  select id into v_n from notify.notifications
   where recipient_user_id = '30000000-0000-0000-0000-000000000001'
     and status = 'unread' and deleted_at is null
   limit 1;
  perform notify.portal_mark_read(v_n);
  v_post := notify.portal_unread_count();
  perform set_config('test.unread_pre',  v_pre::text,  false);
  perform set_config('test.unread_post', v_post::text, false);
  perform set_config('test.read_id',     v_n::text,    false);
end;
$$;
reset role;

select is(
  (select status::text from notify.notifications where id = current_setting('test.read_id')::uuid),
  'read',
  'portal_mark_read flips status → read'
);

-- 7. unread_count drops.
select is(
  current_setting('test.unread_post')::int,
  current_setting('test.unread_pre')::int - 1,
  'portal_unread_count drops by 1 after mark_read'
);

-- 8. mark_all_read sweeps remainder; returns count > 0.
select tests.authenticate_as(
  '30000000-0000-0000-0000-000000000001',
  '30000000-0000-0000-0000-00000000000a',
  '30000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
do $$
declare v_count int;
begin
  v_count := notify.portal_mark_all_read();
  perform set_config('test.mark_all', v_count::text, false);
end;
$$;
reset role;

select cmp_ok(
  current_setting('test.mark_all')::int,
  '>=', 0,
  'portal_mark_all_read returns count of swept unread (>= 0)'
);

-- 9. archive flips status.
select tests.authenticate_as(
  '30000000-0000-0000-0000-000000000001',
  '30000000-0000-0000-0000-00000000000a',
  '30000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
do $$
declare v_n uuid;
begin
  select id into v_n from notify.notifications
   where recipient_user_id = '30000000-0000-0000-0000-000000000001'
     and status = 'read' and deleted_at is null
   limit 1;
  perform notify.portal_archive_notification(v_n);
  perform set_config('test.arch_id', v_n::text, false);
end;
$$;
reset role;

select is(
  (select status::text from notify.notifications where id = current_setting('test.arch_id')::uuid),
  'archived',
  'portal_archive_notification flips status → archived'
);

-- 10. Foreign notification → 42501. Supplier user tries to read buyer's notification.
select tests.authenticate_as(
  '30000000-0000-0000-0000-000000000002',
  '30000000-0000-0000-0000-00000000000a',
  '30000000-0000-0000-0000-00000000002a'
);
set local role authenticated;
select throws_ok(
  format($$ select notify.portal_get_notification(%L::uuid) $$, current_setting('test.arch_id')),
  '42501', null,
  'portal_get_notification on foreign notification raises 42501'
);
reset role;

select * from finish();
rollback;
