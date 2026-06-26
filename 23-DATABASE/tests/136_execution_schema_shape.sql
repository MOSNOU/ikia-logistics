-- CC-65 Test 136 — execution engine schema shape
--
-- Assertions (12):
--   1.  schema execution exists
--   2.  enum task_status exists
--   3.  enum task_priority exists
--   4.  enum task_owner_type exists
--   5.  enum escalation_status exists
--   6.  table shipment_tasks exists
--   7.  table task_dependencies exists
--   8.  table task_events exists
--   9.  table task_escalations exists
--  10.  shipment_tasks unique (tenant_id, task_code)
--  11.  task_dependencies no-self check
--  12.  shipment_tasks(shipment_id, status) index exists

set search_path = extensions, public, identity, organization, audit, supplier,
                  commodity, rfq, offer, evaluation, contract, shipment, notify,
                  marketplace, dispatch, telematics, execution, tests;
begin;

select plan(12);

select has_schema('execution', 'schema execution exists');

select has_type('execution', 'task_status', 'enum task_status exists');
select has_type('execution', 'task_priority', 'enum task_priority exists');
select has_type('execution', 'task_owner_type', 'enum task_owner_type exists');
select has_type('execution', 'escalation_status', 'enum escalation_status exists');

select has_table('execution', 'shipment_tasks', 'table shipment_tasks exists');
select has_table('execution', 'task_dependencies', 'table task_dependencies exists');
select has_table('execution', 'task_events', 'table task_events exists');
select has_table('execution', 'task_escalations', 'table task_escalations exists');

select is(
  (select count(*)::int from pg_constraint c
    join pg_class t on t.oid = c.conrelid
    join pg_namespace n on n.oid = t.relnamespace
   where n.nspname = 'execution'
     and t.relname = 'shipment_tasks'
     and c.conname = 'shipment_tasks_code_unique'),
  1, 'shipment_tasks unique (tenant_id, task_code) constraint exists');

select is(
  (select count(*)::int from pg_constraint c
    join pg_class t on t.oid = c.conrelid
    join pg_namespace n on n.oid = t.relnamespace
   where n.nspname = 'execution'
     and t.relname = 'task_dependencies'
     and c.conname = 'task_dependencies_no_self'),
  1, 'task_dependencies no-self check constraint exists');

select has_index('execution', 'shipment_tasks',
  'shipment_tasks_shipment_status_idx',
  'shipment_tasks(shipment_id, status) index exists');

select * from finish();
rollback;
