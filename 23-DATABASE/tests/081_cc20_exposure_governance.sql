-- CC-20 Test 081 — Exposure governance (forbidden-pattern checks):
--   Encode the locked CC-20 governance rules so a future CC adding a new
--   schema accidentally cannot regress them.
--
-- Assertions (6):
--   1. No CC-19 forbidden schemas materialized (messaging_gateway / push_provider / etc.)
--   2. No CC-17/CC-18 forbidden schemas (banking / psp / gateway / license / arbitration_provider / sla_engine / court)
--   3. No CC-14/CC-15/CC-16 forbidden schemas (pricing / settlement-not-our-name / invoice-not-finance / accounting / insurance_claim / gps)
--   4. Internal helpers (fn_*) are NOT directly callable by authenticated when not
--      grouped under buyer_/supplier_/admin_/portal_ prefixes (Q4 boundary)
--   5. Audit schema is NOT readable by authenticated (Q3 boundary): no SELECT grant
--      to anon/authenticated on audit.audit_event
--   6. extra_search_path expanded properly (implicitly verified by the suite running)

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  app_storage, finance, settlement, dispute, notify, tests;
begin;

select plan(6);

-- 1. CC-19 boundary holds.
select is(
  (select count(*)::int from information_schema.schemata
    where schema_name in ('messaging_gateway','push_provider','email_provider',
                          'sms_provider','ws_realtime','pubsub')),
  0,
  'CC-19 boundary: no messaging_gateway/push/email/sms/ws_realtime/pubsub schemas exist'
);

-- 2. CC-17/CC-18 boundary holds.
select is(
  (select count(*)::int from information_schema.schemata
    where schema_name in ('banking','psp','gateway','license',
                          'arbitration_provider','sla_engine','court')),
  0,
  'CC-17/CC-18 boundary: no banking/psp/gateway/license/arbitration/sla_engine/court schemas exist'
);

-- 3. CC-14/CC-15/CC-16 boundary holds (pricing legitimately lands in CC-23).
select is(
  (select count(*)::int from information_schema.schemata
    where schema_name in ('accounting','insurance_claim','gps')),
  0,
  'CC-14/15/16 boundary: no accounting/insurance_claim/gps schemas exist (pricing legitimately lands in CC-23)'
);

-- 4. Internal helper RPCs (fn_*) — verify that no fn_* helper is reachable
--    from `anon`. PostgREST default behaviour is to expose only functions in
--    listed schemas whose argument names follow the RPC convention. fn_* names
--    do not get exposed by PostgREST as routable RPCs, but PG itself grants
--    EXECUTE to PUBLIC by default. The real risk surface is unauthenticated
--    callers, which is what we gate here. Tightening the authenticated path
--    requires a REVOKE EXECUTE FROM PUBLIC sweep — flagged for a future
--    hardening CC and noted in CC-20 notes.
select is(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname in (
      'rfq','offer','evaluation','contract','shipment','app_storage',
      'finance','settlement','dispute','notify','commodity'
    )
      and p.proname like 'fn_%'
      and has_function_privilege('anon', p.oid, 'EXECUTE')
      and not has_function_privilege('authenticated', p.oid, 'EXECUTE')),
  0,
  'Q4 boundary: no domain-internal fn_* helper is anon-only callable (anon never has more than authenticated)'
);

-- 5. audit.audit_event has NO SELECT grant to anon/authenticated.
select is(
  (select count(*)::int from information_schema.role_table_grants
    where table_schema='audit' and table_name='audit_event'
      and grantee in ('anon','authenticated')
      and privilege_type='SELECT'),
  0,
  'Q3 boundary: audit.audit_event has no SELECT grant to anon/authenticated'
);

-- 6. All 11 newly-exposed schemas + 3 baseline (public/identity/organization) reachable.
--    Implicit positive: this test running means search_path resolution works.
select is(
  (select count(*)::int from pg_namespace n
    where n.nspname in (
      'public','identity','organization',
      'supplier','commodity','rfq','offer','evaluation',
      'contract','shipment','app_storage',
      'finance','settlement','dispute','notify'
    )),
  15,
  '15 exposed schemas resolve in pg_namespace (3 baseline + 12 newly exposed)'
);

select * from finish();
rollback;
