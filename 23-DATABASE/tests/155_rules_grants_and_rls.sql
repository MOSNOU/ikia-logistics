-- CC-67 Test 155 — rules grants & RLS posture
--
-- Assertions (13):
--   1.  rule_sets RLS enabled
--   2.  rules RLS enabled
--   3.  rule_evaluations RLS enabled
--   4.  rule_evaluation_results RLS enabled
--   5.  rule_events RLS enabled
--   6.  authenticated has no INSERT on rule_sets
--   7.  authenticated has no INSERT on rule_evaluations
--   8.  authenticated has no UPDATE on rule_events
--   9.  authenticated has no DELETE on rule_events
--  10.  admin_create_rule_set is SECURITY DEFINER
--  11.  evaluate_context is SECURITY DEFINER
--  12.  authenticated has EXECUTE on admin_create_rule_set
--  13.  authenticated has EXECUTE on evaluate_context

set search_path = extensions, public, identity, organization, audit, supplier,
                  commodity, rfq, offer, evaluation, contract, shipment, notify,
                  marketplace, dispatch, telematics, execution, workflow, rules, tests;
begin;

select plan(13);

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='rules' and c.relname='rule_sets'),
  true, 'rule_sets RLS enabled');

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='rules' and c.relname='rules'),
  true, 'rules RLS enabled');

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='rules' and c.relname='rule_evaluations'),
  true, 'rule_evaluations RLS enabled');

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='rules' and c.relname='rule_evaluation_results'),
  true, 'rule_evaluation_results RLS enabled');

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='rules' and c.relname='rule_events'),
  true, 'rule_events RLS enabled');

select is(
  has_table_privilege('authenticated', 'rules.rule_sets', 'INSERT'),
  false, 'authenticated has no INSERT on rule_sets');

select is(
  has_table_privilege('authenticated', 'rules.rule_evaluations', 'INSERT'),
  false, 'authenticated has no INSERT on rule_evaluations');

select is(
  has_table_privilege('authenticated', 'rules.rule_events', 'UPDATE'),
  false, 'authenticated has no UPDATE on rule_events');

select is(
  has_table_privilege('authenticated', 'rules.rule_events', 'DELETE'),
  false, 'authenticated has no DELETE on rule_events');

select is(
  (select prosecdef from pg_proc p join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='rules' and p.proname='admin_create_rule_set'),
  true, 'admin_create_rule_set is SECURITY DEFINER');

select is(
  (select prosecdef from pg_proc p join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='rules' and p.proname='evaluate_context'),
  true, 'evaluate_context is SECURITY DEFINER');

select is(
  has_function_privilege('authenticated',
    'rules.admin_create_rule_set(text,text,text,rules.rule_scope,int,jsonb)',
    'EXECUTE'),
  true, 'authenticated has EXECUTE on admin_create_rule_set');

select is(
  has_function_privilege('authenticated',
    'rules.evaluate_context(rules.rule_scope,uuid,jsonb,boolean)',
    'EXECUTE'),
  true, 'authenticated has EXECUTE on evaluate_context');

select * from finish();
rollback;
