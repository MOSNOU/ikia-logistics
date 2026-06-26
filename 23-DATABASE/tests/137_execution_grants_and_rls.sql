-- CC-65 Test 137 — execution grants & RLS posture
--
-- Assertions (10):
--   1.  shipment_tasks RLS enabled
--   2.  task_dependencies RLS enabled
--   3.  task_events RLS enabled
--   4.  task_escalations RLS enabled
--   5.  authenticated has no INSERT on shipment_tasks
--   6.  authenticated has no UPDATE on shipment_tasks
--   7.  authenticated has no DELETE on shipment_tasks
--   8.  buyer_create_task is SECURITY DEFINER
--   9.  admin_raise_escalation is SECURITY DEFINER
--  10.  authenticated has EXECUTE on buyer_create_task

set search_path = extensions, public, identity, organization, audit, supplier,
                  commodity, rfq, offer, evaluation, contract, shipment, notify,
                  marketplace, dispatch, telematics, execution, tests;
begin;

select plan(10);

select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='execution' and c.relname='shipment_tasks'),
  true, 'shipment_tasks RLS enabled');
select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='execution' and c.relname='task_dependencies'),
  true, 'task_dependencies RLS enabled');
select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='execution' and c.relname='task_events'),
  true, 'task_events RLS enabled');
select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='execution' and c.relname='task_escalations'),
  true, 'task_escalations RLS enabled');

select is(
  has_table_privilege('authenticated', 'execution.shipment_tasks', 'INSERT'),
  false, 'authenticated has no INSERT on shipment_tasks');
select is(
  has_table_privilege('authenticated', 'execution.shipment_tasks', 'UPDATE'),
  false, 'authenticated has no UPDATE on shipment_tasks');
select is(
  has_table_privilege('authenticated', 'execution.shipment_tasks', 'DELETE'),
  false, 'authenticated has no DELETE on shipment_tasks');

select is(
  (select prosecdef from pg_proc p join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='execution' and p.proname='buyer_create_task'),
  true, 'buyer_create_task is SECURITY DEFINER');
select is(
  (select prosecdef from pg_proc p join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='execution' and p.proname='admin_raise_escalation'),
  true, 'admin_raise_escalation is SECURITY DEFINER');

select is(
  has_function_privilege('authenticated',
    'execution.buyer_create_task(uuid,text,text,execution.task_owner_type,uuid,uuid,execution.task_priority,timestamptz,jsonb)',
    'EXECUTE'),
  true, 'authenticated has EXECUTE on buyer_create_task');

select * from finish();
rollback;
