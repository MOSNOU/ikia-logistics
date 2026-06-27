-- CC-66 Test 147 — workflow grants & RLS posture
--
-- Assertions (12):
--   1.  workflow_templates RLS enabled
--   2.  workflow_steps RLS enabled
--   3.  workflow_step_dependencies RLS enabled
--   4.  workflow_instances RLS enabled
--   5.  workflow_instance_tasks RLS enabled
--   6.  workflow_events RLS enabled
--   7.  authenticated has no INSERT on workflow_templates
--   8.  authenticated has no UPDATE on workflow_events
--   9.  authenticated has no DELETE on workflow_events
--  10.  admin_create_template is SECURITY DEFINER
--  11.  buyer_start_workflow is SECURITY DEFINER
--  12.  authenticated has EXECUTE on admin_create_template

set search_path = extensions, public, identity, organization, audit, supplier,
                  commodity, rfq, offer, evaluation, contract, shipment, notify,
                  marketplace, dispatch, telematics, execution, workflow, tests;
begin;

select plan(12);

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='workflow' and c.relname='workflow_templates'),
  true, 'workflow_templates RLS enabled');

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='workflow' and c.relname='workflow_steps'),
  true, 'workflow_steps RLS enabled');

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='workflow' and c.relname='workflow_step_dependencies'),
  true, 'workflow_step_dependencies RLS enabled');

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='workflow' and c.relname='workflow_instances'),
  true, 'workflow_instances RLS enabled');

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='workflow' and c.relname='workflow_instance_tasks'),
  true, 'workflow_instance_tasks RLS enabled');

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='workflow' and c.relname='workflow_events'),
  true, 'workflow_events RLS enabled');

select is(
  has_table_privilege('authenticated', 'workflow.workflow_templates', 'INSERT'),
  false, 'authenticated has no INSERT on workflow_templates');

select is(
  has_table_privilege('authenticated', 'workflow.workflow_events', 'UPDATE'),
  false, 'authenticated has no UPDATE on workflow_events');

select is(
  has_table_privilege('authenticated', 'workflow.workflow_events', 'DELETE'),
  false, 'authenticated has no DELETE on workflow_events');

select is(
  (select prosecdef from pg_proc p join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='workflow' and p.proname='admin_create_template'),
  true, 'admin_create_template is SECURITY DEFINER');

select is(
  (select prosecdef from pg_proc p join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='workflow' and p.proname='buyer_start_workflow'),
  true, 'buyer_start_workflow is SECURITY DEFINER');

select is(
  has_function_privilege('authenticated',
    'workflow.admin_create_template(text,text,text,text,text,jsonb)',
    'EXECUTE'),
  true, 'authenticated has EXECUTE on admin_create_template');

select * from finish();
rollback;
