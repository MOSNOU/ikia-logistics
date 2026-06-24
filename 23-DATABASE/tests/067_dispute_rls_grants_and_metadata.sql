-- CC-18 Test 067 — Dispute RLS, grants, RPC metadata, safety, forbidden schemas.
--
-- Assertions (13):
--   1-5  : RLS enabled on all 5 dispute.* tables
--   6    : 0 direct INSERT/UPDATE/DELETE grants
--   7    : every dispute RPC is SECURITY DEFINER
--   8    : every dispute RPC has search_path = ''
--   9    : no dispute.buyer_* RPC accepts p_buyer_organization_id
--   10   : no dispute.supplier_* RPC accepts p_supplier_id
--   11   : single consistent RPC owner
--   12   : no forbidden schemas (banking/psp/gateway/license/insurance_claim/gps/arbitration_provider/sla_engine/court)
--   13   : Q7-A trigger trg_dispute_autocreate exists on settlement.settlements

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  app_storage, finance, settlement, dispute, tests;
begin;

select plan(13);

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='dispute' and c.relname='disputes'),
  true, 'dispute.disputes has RLS enabled');

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='dispute' and c.relname='dispute_participants'),
  true, 'dispute.dispute_participants has RLS enabled');

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='dispute' and c.relname='dispute_evidence'),
  true, 'dispute.dispute_evidence has RLS enabled');

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='dispute' and c.relname='dispute_decisions'),
  true, 'dispute.dispute_decisions has RLS enabled');

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='dispute' and c.relname='dispute_events'),
  true, 'dispute.dispute_events has RLS enabled');

select is(
  (select count(*)::int from information_schema.role_table_grants
    where table_schema='dispute' and grantee in ('anon','authenticated')
      and privilege_type in ('INSERT','UPDATE','DELETE')),
  0, 'no direct INSERT/UPDATE/DELETE grants on dispute.* tables');

select is(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='dispute'
      and (p.proname like 'buyer_%' or p.proname like 'supplier_%' or p.proname like 'admin_%')
      and not p.prosecdef),
  0, 'every dispute RPC is security_definer');

select is(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='dispute'
      and (p.proname like 'buyer_%' or p.proname like 'supplier_%' or p.proname like 'admin_%')
      and not exists (
        select 1 from unnest(coalesce(p.proconfig, array[]::text[])) s
         where s = 'search_path=""'
      )),
  0, 'every dispute RPC has search_path = empty string');

select is(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='dispute' and p.proname like 'buyer_%'
      and p.proargnames is not null and 'p_buyer_organization_id' = any(p.proargnames)),
  0, 'no dispute.buyer_* RPC accepts a p_buyer_organization_id parameter');

select is(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='dispute' and p.proname like 'supplier_%'
      and p.proargnames is not null and 'p_supplier_id' = any(p.proargnames)),
  0, 'no dispute.supplier_* RPC accepts a p_supplier_id parameter');

select is(
  (select count(distinct pg_get_userbyid(p.proowner))::int
     from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname='dispute'
      and (p.proname like 'buyer_%' or p.proname like 'supplier_%' or p.proname like 'admin_%')),
  1, 'every dispute RPC has a single consistent owner');

select is(
  (select count(*)::int from information_schema.schemata
    where schema_name in ('banking','psp','gateway','license','insurance_claim','gps',
                          'arbitration_provider','sla_engine','court')),
  0, 'no banking/psp/gateway/license/insurance/gps/arbitration_provider/sla_engine/court schemas');

select is(
  (select count(*)::int from pg_trigger
    where tgrelid = 'settlement.settlements'::regclass
      and tgname = 'trg_dispute_autocreate'),
  1,
  'Q7-A: trg_dispute_autocreate trigger exists on settlement.settlements'
);

select * from finish();
rollback;
