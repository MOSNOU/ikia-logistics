-- CC-66 Test 146 — workflow engine schema shape
--
-- Assertions (16):
--   1.  schema workflow exists
--   2.  enum workflow_template_status exists
--   3.  enum workflow_instance_status exists
--   4.  enum workflow_step_type exists
--   5.  enum workflow_event_type exists
--   6.  table workflow_templates exists
--   7.  table workflow_steps exists
--   8.  table workflow_step_dependencies exists
--   9.  table workflow_instances exists
--  10.  table workflow_instance_tasks exists
--  11.  table workflow_events exists
--  12.  workflow_templates unique (tenant_id, template_code)
--  13.  workflow_step_dependencies no-self check
--  14.  workflow_steps(template_id, sort_order) index exists
--  15.  workflow_instances template+shipment partial unique idx exists
--  16.  workflow_instance_tasks task_id unique

set search_path = extensions, public, identity, organization, audit, supplier,
                  commodity, rfq, offer, evaluation, contract, shipment, notify,
                  marketplace, dispatch, telematics, execution, workflow, tests;
begin;

select plan(16);

select has_schema('workflow', 'schema workflow exists');

select has_type('workflow', 'workflow_template_status',
  'enum workflow_template_status exists');
select has_type('workflow', 'workflow_instance_status',
  'enum workflow_instance_status exists');
select has_type('workflow', 'workflow_step_type',
  'enum workflow_step_type exists');
select has_type('workflow', 'workflow_event_type',
  'enum workflow_event_type exists');

select has_table('workflow', 'workflow_templates',
  'table workflow_templates exists');
select has_table('workflow', 'workflow_steps',
  'table workflow_steps exists');
select has_table('workflow', 'workflow_step_dependencies',
  'table workflow_step_dependencies exists');
select has_table('workflow', 'workflow_instances',
  'table workflow_instances exists');
select has_table('workflow', 'workflow_instance_tasks',
  'table workflow_instance_tasks exists');
select has_table('workflow', 'workflow_events',
  'table workflow_events exists');

select is(
  (select count(*)::int from pg_constraint c
    join pg_class t on t.oid = c.conrelid
    join pg_namespace n on n.oid = t.relnamespace
   where n.nspname = 'workflow'
     and t.relname = 'workflow_templates'
     and c.conname = 'workflow_templates_code_unique'),
  1, 'workflow_templates unique (tenant_id, template_code) constraint exists');

select is(
  (select count(*)::int from pg_constraint c
    join pg_class t on t.oid = c.conrelid
    join pg_namespace n on n.oid = t.relnamespace
   where n.nspname = 'workflow'
     and t.relname = 'workflow_step_dependencies'
     and c.conname = 'workflow_step_dependencies_no_self'),
  1, 'workflow_step_dependencies no-self check constraint exists');

select has_index('workflow', 'workflow_steps',
  'workflow_steps_template_sort_idx',
  'workflow_steps(template_id, sort_order) index exists');

select is(
  (select count(*)::int from pg_indexes
    where schemaname = 'workflow'
      and tablename = 'workflow_instances'
      and indexname = 'workflow_instances_template_shipment_active_uq'),
  1, 'workflow_instances template+shipment partial unique index exists');

select is(
  (select count(*)::int from pg_constraint c
    join pg_class t on t.oid = c.conrelid
    join pg_namespace n on n.oid = t.relnamespace
   where n.nspname = 'workflow'
     and t.relname = 'workflow_instance_tasks'
     and c.conname = 'workflow_instance_tasks_task_unique'),
  1, 'workflow_instance_tasks task_id unique constraint exists');

select * from finish();
rollback;
