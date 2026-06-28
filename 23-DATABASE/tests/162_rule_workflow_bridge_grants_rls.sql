-- CC-68 Test 162 — rule-workflow bridge grants & RLS posture
--
-- Assertions (13):
--   1.  workflow_recommendations RLS enabled
--   2.  workflow_recommendation_events RLS enabled
--   3.  authenticated has no INSERT on workflow_recommendations
--   4.  authenticated has no UPDATE on workflow_recommendations
--   5.  authenticated has no DELETE on workflow_recommendations
--   6.  authenticated has no INSERT on workflow_recommendation_events
--   7.  authenticated has no UPDATE on workflow_recommendation_events
--   8.  authenticated has no DELETE on workflow_recommendation_events
--   9.  evaluate_shipment_workflow_recommendations is SECURITY DEFINER
--  10.  evaluate_shipment_workflow_recommendations sets search_path
--  11.  admin_accept_workflow_recommendation is SECURITY DEFINER
--  12.  authenticated has EXECUTE on evaluate_shipment_workflow_recommendations
--  13.  authenticated has EXECUTE on buyer_accept_workflow_recommendation

set search_path = extensions, public, identity, organization, audit, supplier,
                  commodity, rfq, offer, evaluation, contract, shipment, notify,
                  marketplace, dispatch, telematics, execution, workflow, rules, tests;
begin;

select plan(13);

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='rules' and c.relname='workflow_recommendations'),
  true, 'workflow_recommendations RLS enabled');

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='rules' and c.relname='workflow_recommendation_events'),
  true, 'workflow_recommendation_events RLS enabled');

select is(
  has_table_privilege('authenticated', 'rules.workflow_recommendations', 'INSERT'),
  false, 'authenticated has no INSERT on workflow_recommendations');
select is(
  has_table_privilege('authenticated', 'rules.workflow_recommendations', 'UPDATE'),
  false, 'authenticated has no UPDATE on workflow_recommendations');
select is(
  has_table_privilege('authenticated', 'rules.workflow_recommendations', 'DELETE'),
  false, 'authenticated has no DELETE on workflow_recommendations');

select is(
  has_table_privilege('authenticated', 'rules.workflow_recommendation_events', 'INSERT'),
  false, 'authenticated has no INSERT on workflow_recommendation_events');
select is(
  has_table_privilege('authenticated', 'rules.workflow_recommendation_events', 'UPDATE'),
  false, 'authenticated has no UPDATE on workflow_recommendation_events');
select is(
  has_table_privilege('authenticated', 'rules.workflow_recommendation_events', 'DELETE'),
  false, 'authenticated has no DELETE on workflow_recommendation_events');

select is(
  (select prosecdef from pg_proc p join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='rules' and p.proname='evaluate_shipment_workflow_recommendations'),
  true, 'evaluate_shipment_workflow_recommendations is SECURITY DEFINER');

select ok(
  (select bool_or(cfg like 'search_path=%')
     from pg_proc p
     join pg_namespace n on n.oid=p.pronamespace,
          unnest(p.proconfig) as cfg
    where n.nspname='rules'
      and p.proname='evaluate_shipment_workflow_recommendations'),
  'evaluate_shipment_workflow_recommendations sets search_path');

select is(
  (select prosecdef from pg_proc p join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='rules' and p.proname='admin_accept_workflow_recommendation'),
  true, 'admin_accept_workflow_recommendation is SECURITY DEFINER');

select is(
  has_function_privilege('authenticated',
    'rules.evaluate_shipment_workflow_recommendations(uuid,jsonb,boolean)',
    'EXECUTE'),
  true, 'authenticated has EXECUTE on evaluate_shipment_workflow_recommendations');

select is(
  has_function_privilege('authenticated',
    'rules.buyer_accept_workflow_recommendation(uuid,text)',
    'EXECUTE'),
  true, 'authenticated has EXECUTE on buyer_accept_workflow_recommendation');

select * from finish();
rollback;
