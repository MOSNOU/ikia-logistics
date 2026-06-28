-- CC-68 Test 161 — rule-workflow bridge schema shape
--
-- Assertions (12):
--   1.  table workflow_recommendations exists
--   2.  table workflow_recommendation_events exists
--   3.  confidence range constraint exists
--   4.  status check constraint exists
--   5.  dismissed_at required constraint exists
--   6.  dismissal_reason required constraint exists
--   7.  recommendation_code not-blank constraint exists
--   8.  partial unique (shipment_id, template_id, rule_id) where status=open index
--   9.  workflow_recommendations(shipment_id, status) index exists
--  10.  workflow_recommendations(template_id, status) index exists
--  11.  workflow_recommendations(evaluation_id) index exists
--  12.  workflow_recommendation_events(recommendation_id, created_at) index exists

set search_path = extensions, public, identity, organization, audit, supplier,
                  commodity, rfq, offer, evaluation, contract, shipment, notify,
                  marketplace, dispatch, telematics, execution, workflow, rules, tests;
begin;

select plan(12);

select has_table('rules', 'workflow_recommendations',
  'table workflow_recommendations exists');
select has_table('rules', 'workflow_recommendation_events',
  'table workflow_recommendation_events exists');

select is(
  (select count(*)::int from pg_constraint c
    join pg_class t on t.oid = c.conrelid
    join pg_namespace n on n.oid = t.relnamespace
   where n.nspname = 'rules'
     and t.relname = 'workflow_recommendations'
     and c.conname = 'workflow_recommendations_confidence_range'),
  1, 'confidence range constraint exists');

select is(
  (select count(*)::int from pg_constraint c
    join pg_class t on t.oid = c.conrelid
    join pg_namespace n on n.oid = t.relnamespace
   where n.nspname = 'rules'
     and t.relname = 'workflow_recommendations'
     and c.conname = 'workflow_recommendations_status_valid'),
  1, 'status check constraint exists');

select is(
  (select count(*)::int from pg_constraint c
    join pg_class t on t.oid = c.conrelid
    join pg_namespace n on n.oid = t.relnamespace
   where n.nspname = 'rules'
     and t.relname = 'workflow_recommendations'
     and c.conname = 'workflow_recommendations_dismissed_at_required'),
  1, 'dismissed_at required constraint exists');

select is(
  (select count(*)::int from pg_constraint c
    join pg_class t on t.oid = c.conrelid
    join pg_namespace n on n.oid = t.relnamespace
   where n.nspname = 'rules'
     and t.relname = 'workflow_recommendations'
     and c.conname = 'workflow_recommendations_dismissal_reason_required'),
  1, 'dismissal_reason required constraint exists');

select is(
  (select count(*)::int from pg_constraint c
    join pg_class t on t.oid = c.conrelid
    join pg_namespace n on n.oid = t.relnamespace
   where n.nspname = 'rules'
     and t.relname = 'workflow_recommendations'
     and c.conname = 'workflow_recommendations_code_not_blank'),
  1, 'recommendation_code not-blank constraint exists');

select has_index('rules', 'workflow_recommendations',
  'workflow_recommendations_open_unique',
  'partial unique (shipment_id, template_id, rule_id) where status=open exists');

select has_index('rules', 'workflow_recommendations',
  'workflow_recommendations_shipment_status_idx',
  'workflow_recommendations(shipment_id, status) index exists');

select has_index('rules', 'workflow_recommendations',
  'workflow_recommendations_template_status_idx',
  'workflow_recommendations(template_id, status) index exists');

select has_index('rules', 'workflow_recommendations',
  'workflow_recommendations_evaluation_idx',
  'workflow_recommendations(evaluation_id) index exists');

select has_index('rules', 'workflow_recommendation_events',
  'workflow_recommendation_events_rec_created_idx',
  'workflow_recommendation_events(recommendation_id, created_at) index exists');

select * from finish();
rollback;
