-- CC-67 Test 154 — rules schema shape
--
-- Assertions (16):
--   1.  schema rules exists
--   2.  enum rule_status exists
--   3.  enum rule_scope exists
--   4.  enum rule_effect_type exists
--   5.  enum rule_eval_status exists
--   6.  table rule_sets exists
--   7.  table rules exists
--   8.  table rule_evaluations exists
--   9.  table rule_evaluation_results exists
--  10.  table rule_events exists
--  11.  rule_sets unique (tenant_id, rule_set_code) constraint exists
--  12.  rules unique (rule_set_id, rule_code) constraint exists
--  13.  rule_evaluation_results score range constraint exists
--  14.  rule_sets(tenant_id, status, scope) index exists
--  15.  rule_evaluations(scope, subject_id, evaluated_at) index exists
--  16.  rule_events(evaluation_id, created_at) index exists

set search_path = extensions, public, identity, organization, audit, supplier,
                  commodity, rfq, offer, evaluation, contract, shipment, notify,
                  marketplace, dispatch, telematics, execution, workflow, rules, tests;
begin;

select plan(16);

select has_schema('rules', 'schema rules exists');

select has_type('rules', 'rule_status', 'enum rule_status exists');
select has_type('rules', 'rule_scope', 'enum rule_scope exists');
select has_type('rules', 'rule_effect_type', 'enum rule_effect_type exists');
select has_type('rules', 'rule_eval_status', 'enum rule_eval_status exists');

select has_table('rules', 'rule_sets', 'table rule_sets exists');
select has_table('rules', 'rules', 'table rules exists');
select has_table('rules', 'rule_evaluations', 'table rule_evaluations exists');
select has_table('rules', 'rule_evaluation_results',
  'table rule_evaluation_results exists');
select has_table('rules', 'rule_events', 'table rule_events exists');

select is(
  (select count(*)::int from pg_constraint c
    join pg_class t on t.oid = c.conrelid
    join pg_namespace n on n.oid = t.relnamespace
   where n.nspname = 'rules'
     and t.relname = 'rule_sets'
     and c.conname = 'rule_sets_code_unique'),
  1, 'rule_sets unique (tenant_id, rule_set_code) constraint exists');

select is(
  (select count(*)::int from pg_constraint c
    join pg_class t on t.oid = c.conrelid
    join pg_namespace n on n.oid = t.relnamespace
   where n.nspname = 'rules'
     and t.relname = 'rules'
     and c.conname = 'rules_code_unique'),
  1, 'rules unique (rule_set_id, rule_code) constraint exists');

select is(
  (select count(*)::int from pg_constraint c
    join pg_class t on t.oid = c.conrelid
    join pg_namespace n on n.oid = t.relnamespace
   where n.nspname = 'rules'
     and t.relname = 'rule_evaluation_results'
     and c.conname = 'rule_evaluation_results_score_range'),
  1, 'rule_evaluation_results score range constraint exists');

select has_index('rules', 'rule_sets',
  'rule_sets_tenant_status_scope_idx',
  'rule_sets(tenant_id, status, scope) index exists');

select has_index('rules', 'rule_evaluations',
  'rule_evaluations_scope_subject_idx',
  'rule_evaluations(scope, subject_id, evaluated_at) index exists');

select has_index('rules', 'rule_events',
  'rule_events_evaluation_created_idx',
  'rule_events(evaluation_id, created_at) index exists');

select * from finish();
rollback;
