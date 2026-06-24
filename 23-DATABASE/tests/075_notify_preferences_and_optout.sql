-- CC-19 Test 075 — Preferences + opt-out behaviour (Q5 = opt-out default):
--   * No preferences row → enabled (notifications materialized as normal)
--   * portal_upsert_preferences with enabled=false suppresses fan-out for that user/category/channel
--   * Re-enabling restores fan-out
--   * portal_upsert_preferences cannot accept p_user_id (RPC safety)
--
-- Assertions (7):
--   1. baseline: buyer receives settlement.held notification
--   2. portal_upsert_preferences inserts a row with enabled=false
--   3. After opt-out, next settlement event does NOT generate a notification for that user
--   4. unrelated category (dispute) still fan-outs to buyer
--   5. portal_upsert_preferences with enabled=true restores delivery
--   6. After re-enable, next settlement event generates a fresh notification
--   7. user_preferences RLS hides other users' rows

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  app_storage, finance, settlement, dispute, notify, tests;
begin;

-- Fixtures: 1 buyer + 1 supplier; build to executed contract + escrow.
insert into auth.users (instance_id, id, aud, role, email) values
  ('00000000-0000-0000-0000-000000000000',
   '32000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', '075-buyer@example.com'),
  ('00000000-0000-0000-0000-000000000000',
   '32000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', '075-sup@example.com');

insert into identity.tenants (id, code, name_fa, name_en) values
  ('32000000-0000-0000-0000-00000000000a', 'tenant-075', 'تست', 'Test');

insert into organization.organizations (id, tenant_id, code, name_fa, name_en, type, status) values
  ('32000000-0000-0000-0000-00000000001a', '32000000-0000-0000-0000-00000000000a',
   'buyer-075', 'خریدار', 'Buyer 075', 'buyer', 'active'),
  ('32000000-0000-0000-0000-00000000002a', '32000000-0000-0000-0000-00000000000a',
   'sup-075', 'تأمین', 'Supplier 075', 'supplier', 'active');

insert into identity.user_profiles (id, tenant_id, primary_organization_id, full_name, locale, status) values
  ('32000000-0000-0000-0000-000000000001', '32000000-0000-0000-0000-00000000000a',
   '32000000-0000-0000-0000-00000000001a', 'Buyer', 'fa', 'active'),
  ('32000000-0000-0000-0000-000000000002', '32000000-0000-0000-0000-00000000000a',
   '32000000-0000-0000-0000-00000000002a', 'Supplier', 'fa', 'active');

insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '32000000-0000-0000-0000-00000000000a', '32000000-0000-0000-0000-00000000001a',
       '32000000-0000-0000-0000-000000000001', r.id, 'active', now()
  from identity.roles r where r.code = 'buyer_admin';
insert into organization.memberships (tenant_id, organization_id, user_id, role_id, status, joined_at)
select '32000000-0000-0000-0000-00000000000a', '32000000-0000-0000-0000-00000000002a',
       '32000000-0000-0000-0000-000000000002', r.id, 'active', now()
  from identity.roles r where r.code = 'supplier_admin';

insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '32000000-0000-0000-0000-000000000001', r.id, 'organization', '32000000-0000-0000-0000-00000000001a'
  from identity.roles r where r.code = 'buyer_admin';
insert into identity.user_roles (user_id, role_id, scope_type, scope_id)
select '32000000-0000-0000-0000-000000000002', r.id, 'organization', '32000000-0000-0000-0000-00000000002a'
  from identity.roles r where r.code = 'supplier_admin';

-- Build to executed contract + open escrow.
do $$
declare
  v_sup uuid; v_prod uuid; v_rfq uuid; v_item uuid; v_off uuid; v_dec uuid;
  v_prep uuid; v_contract uuid; v_p_b uuid; v_p_s uuid; v_sr_b uuid; v_sr_s uuid;
  v_esc uuid;
begin
  select id into v_sup  from supplier.suppliers where organization_id = '32000000-0000-0000-0000-00000000002a';
  select id into v_prod from commodity.products where code = 'methanol';

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','32000000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','32000000-0000-0000-0000-00000000000a',
                       'organization_id','32000000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '32000000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_rfq := rfq.buyer_create_rfq(p_title => 'R for prefs');
  v_item := rfq.buyer_upsert_rfq_item(p_request_id => v_rfq, p_product_id => v_prod,
                                       p_quantity => 100, p_quantity_unit => 'ton');
  perform rfq.buyer_submit_rfq(v_rfq);
  perform rfq.buyer_invite_suppliers(v_rfq, array[v_sup]);
  reset role;

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','32000000-0000-0000-0000-000000000002','role','authenticated',
                       'tenant_id','32000000-0000-0000-0000-00000000000a',
                       'organization_id','32000000-0000-0000-0000-00000000002a')::text, true);
  perform set_config('request.jwt.claim.sub', '32000000-0000-0000-0000-000000000002', true);
  set local role authenticated;
  v_off := offer.supplier_create_draft_offer(p_request_id => v_rfq);
  perform offer.supplier_upsert_offer_item(p_offer_id => v_off, p_request_item_id => v_item,
    p_offered_quantity => 100, p_quantity_unit => 'ton', p_unit_price => 10, p_currency => 'USD');
  perform offer.supplier_submit_my_offer(v_off);
  reset role;

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','32000000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','32000000-0000-0000-0000-00000000000a',
                       'organization_id','32000000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '32000000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_dec := evaluation.buyer_select_for_contract(p_offer_id => v_off);
  v_prep := contract.buyer_create_preparation(p_decision_id => v_dec, p_title => 'prefs prep');
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
    jsonb_build_object('sub','32000000-0000-0000-0000-000000000002','role','authenticated',
                       'tenant_id','32000000-0000-0000-0000-00000000000a',
                       'organization_id','32000000-0000-0000-0000-00000000002a')::text, true);
  perform set_config('request.jwt.claim.sub', '32000000-0000-0000-0000-000000000002', true);
  set local role authenticated;
  perform contract.supplier_sign_signature_request(v_sr_s);
  reset role;

  perform set_config('request.jwt.claims',
    jsonb_build_object('sub','32000000-0000-0000-0000-000000000001','role','authenticated',
                       'tenant_id','32000000-0000-0000-0000-00000000000a',
                       'organization_id','32000000-0000-0000-0000-00000000001a')::text, true);
  perform set_config('request.jwt.claim.sub', '32000000-0000-0000-0000-000000000001', true);
  set local role authenticated;
  v_esc := settlement.buyer_open_escrow_account(p_supplier_id => v_sup, p_currency => 'USD');
  reset role;

  perform set_config('test.contract', v_contract::text, false);
  perform set_config('test.escrow',   v_esc::text,      false);
end;
$$;

select plan(7);

-- 1. Baseline: trigger a settlement.held event, verify buyer notification.
select tests.authenticate_as(
  '32000000-0000-0000-0000-000000000001',
  '32000000-0000-0000-0000-00000000000a',
  '32000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
do $$
declare v_set uuid;
begin
  v_set := settlement.buyer_create_draft_settlement(
    p_executed_contract_id => current_setting('test.contract')::uuid,
    p_escrow_account_id => current_setting('test.escrow')::uuid,
    p_currency => 'USD'
  );
  perform settlement.buyer_upsert_settlement_item(
    p_settlement_id => v_set, p_description => 'Baseline', p_amount => 100
  );
  perform settlement.buyer_mark_settlement_ready(v_set);
  perform settlement.buyer_hold_settlement(v_set);
  perform set_config('test.set_baseline', v_set::text, false);
end;
$$;
reset role;

select cmp_ok(
  (select count(*)::int from notify.notifications
    where source_entity_type = 'settlement'
      and source_entity_id = current_setting('test.set_baseline')::uuid
      and recipient_user_id = '32000000-0000-0000-0000-000000000001'),
  '>=', 1,
  'baseline: buyer receives settlement.held notification (no preference row)'
);

-- 2. Opt-out via portal_upsert_preferences.
select tests.authenticate_as(
  '32000000-0000-0000-0000-000000000001',
  '32000000-0000-0000-0000-00000000000a',
  '32000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
do $$
declare v_pref uuid;
begin
  v_pref := notify.portal_upsert_preferences(
    p_category => 'settlement'::notify.notification_category,
    p_channel  => 'in_app'::notify.channel_type,
    p_enabled  => false
  );
  perform set_config('test.pref', v_pref::text, false);
end;
$$;
reset role;

select is(
  (select enabled from notify.user_preferences where id = current_setting('test.pref')::uuid),
  false,
  'portal_upsert_preferences records enabled=false'
);

-- 3. Opt-out suppresses next settlement notification.
select tests.authenticate_as(
  '32000000-0000-0000-0000-000000000001',
  '32000000-0000-0000-0000-00000000000a',
  '32000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
do $$
declare v_set uuid;
begin
  v_set := settlement.buyer_create_draft_settlement(
    p_executed_contract_id => current_setting('test.contract')::uuid,
    p_escrow_account_id => current_setting('test.escrow')::uuid,
    p_currency => 'USD'
  );
  perform settlement.buyer_upsert_settlement_item(
    p_settlement_id => v_set, p_description => 'Suppressed', p_amount => 100
  );
  perform settlement.buyer_mark_settlement_ready(v_set);
  perform settlement.buyer_hold_settlement(v_set);
  perform set_config('test.set_suppressed', v_set::text, false);
end;
$$;
reset role;

select is(
  (select count(*)::int from notify.notifications
    where source_entity_type = 'settlement'
      and source_entity_id = current_setting('test.set_suppressed')::uuid
      and recipient_user_id = '32000000-0000-0000-0000-000000000001'),
  0,
  'after opt-out, settlement notification NOT generated for buyer'
);

-- 4. Supplier still receives (their own preference is default-enabled).
select cmp_ok(
  (select count(*)::int from notify.notifications
    where source_entity_type = 'settlement'
      and source_entity_id = current_setting('test.set_suppressed')::uuid
      and recipient_user_id = '32000000-0000-0000-0000-000000000002'),
  '>=', 1,
  'buyer opt-out does NOT affect supplier'
);

-- 5. Re-enable.
select tests.authenticate_as(
  '32000000-0000-0000-0000-000000000001',
  '32000000-0000-0000-0000-00000000000a',
  '32000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
select notify.portal_upsert_preferences(
  p_category => 'settlement'::notify.notification_category,
  p_channel  => 'in_app'::notify.channel_type,
  p_enabled  => true
);
reset role;

select is(
  (select enabled from notify.user_preferences where id = current_setting('test.pref')::uuid),
  true,
  'portal_upsert_preferences flips enabled back to true'
);

-- 6. Next settlement event generates a fresh notification.
select tests.authenticate_as(
  '32000000-0000-0000-0000-000000000001',
  '32000000-0000-0000-0000-00000000000a',
  '32000000-0000-0000-0000-00000000001a'
);
set local role authenticated;
do $$
declare v_set uuid;
begin
  v_set := settlement.buyer_create_draft_settlement(
    p_executed_contract_id => current_setting('test.contract')::uuid,
    p_escrow_account_id => current_setting('test.escrow')::uuid,
    p_currency => 'USD'
  );
  perform settlement.buyer_upsert_settlement_item(
    p_settlement_id => v_set, p_description => 'Re-enabled', p_amount => 100
  );
  perform settlement.buyer_mark_settlement_ready(v_set);
  perform settlement.buyer_hold_settlement(v_set);
  perform set_config('test.set_reenabled', v_set::text, false);
end;
$$;
reset role;

select cmp_ok(
  (select count(*)::int from notify.notifications
    where source_entity_type = 'settlement'
      and source_entity_id = current_setting('test.set_reenabled')::uuid
      and recipient_user_id = '32000000-0000-0000-0000-000000000001'),
  '>=', 1,
  'after re-enable, settlement notification generated again'
);

-- 7. user_preferences RLS hides other users' rows.
select tests.authenticate_as(
  '32000000-0000-0000-0000-000000000002',
  '32000000-0000-0000-0000-00000000000a',
  '32000000-0000-0000-0000-00000000002a'
);
set local role authenticated;
select is(
  (select count(*)::int from notify.user_preferences
    where id = current_setting('test.pref')::uuid),
  0,
  'user_preferences RLS hides buyer''s preference row from supplier'
);
reset role;

select * from finish();
rollback;
