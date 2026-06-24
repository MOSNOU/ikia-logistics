-- CC-19 Test 072 — Notify RLS, grants, RPC metadata, safety, forbidden schemas, triggers.
--
-- Assertions (14):
--   1-5  : RLS enabled on all 5 notify.* tables
--   6    : 0 direct INSERT/UPDATE/DELETE grants
--   7    : every notify RPC is SECURITY DEFINER
--   8    : every notify RPC has search_path = ''
--   9    : no notify.portal_* RPC accepts p_buyer_organization_id
--   10   : no notify.portal_* RPC accepts p_supplier_id
--   11   : no notify.portal_* RPC accepts p_user_id
--   12   : single consistent RPC owner
--   13   : no forbidden schemas
--   14   : 12 trg_notify_from_* triggers exist on upstream event tables (Q9 + Q1=A)

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  app_storage, finance, settlement, dispute, notify, tests;
begin;

select plan(14);

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='notify' and c.relname='notification_templates'),
  true, 'notify.notification_templates has RLS enabled');

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='notify' and c.relname='user_preferences'),
  true, 'notify.user_preferences has RLS enabled');

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='notify' and c.relname='notifications'),
  true, 'notify.notifications has RLS enabled');

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='notify' and c.relname='delivery_attempts'),
  true, 'notify.delivery_attempts has RLS enabled');

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='notify' and c.relname='materialization_audit'),
  true, 'notify.materialization_audit has RLS enabled');

select is(
  (select count(*)::int from information_schema.role_table_grants
    where table_schema='notify' and grantee in ('anon','authenticated')
      and privilege_type in ('INSERT','UPDATE','DELETE')),
  0, 'no direct INSERT/UPDATE/DELETE grants on notify.* tables');

select is(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='notify'
      and (p.proname like 'portal_%' or p.proname like 'admin_%')
      and not p.prosecdef),
  0, 'every notify RPC is security_definer');

select is(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='notify'
      and (p.proname like 'portal_%' or p.proname like 'admin_%')
      and not exists (
        select 1 from unnest(coalesce(p.proconfig, array[]::text[])) s where s = 'search_path=""'
      )),
  0, 'every notify RPC has search_path = empty string');

select is(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='notify' and p.proname like 'portal_%'
      and p.proargnames is not null and 'p_buyer_organization_id' = any(p.proargnames)),
  0, 'no notify.portal_* RPC accepts a p_buyer_organization_id parameter');

select is(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='notify' and p.proname like 'portal_%'
      and p.proargnames is not null and 'p_supplier_id' = any(p.proargnames)),
  0, 'no notify.portal_* RPC accepts a p_supplier_id parameter');

select is(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='notify' and p.proname like 'portal_%'
      and p.proargnames is not null and 'p_user_id' = any(p.proargnames)),
  0, 'no notify.portal_* RPC accepts a p_user_id parameter');

select is(
  (select count(distinct pg_get_userbyid(p.proowner))::int
     from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='notify'
      and (p.proname like 'portal_%' or p.proname like 'admin_%')),
  1, 'every notify RPC has a single consistent owner');

select is(
  (select count(*)::int from information_schema.schemata
    where schema_name in ('messaging_gateway','push_provider','email_provider',
                          'sms_provider','ws_realtime','pubsub')),
  0, 'no messaging_gateway/push/email/sms/ws_realtime/pubsub schemas were created');

-- Q1=A + Q9: 12 trg_notify_from_* triggers on upstream event tables.
select is(
  (select count(*)::int from pg_trigger t
    where t.tgname like 'trg_notify_from_%' and not t.tgisinternal),
  12,
  'Q9 + Q1=A: 12 trg_notify_from_* triggers attached to upstream event tables'
);

select * from finish();
rollback;
