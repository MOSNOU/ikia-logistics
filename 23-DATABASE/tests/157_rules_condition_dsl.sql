-- CC-67 Test 157 — condition DSL operators
--
-- Assertions (12): one per operator + all/any group + edge cases.
--   1.  eq matches
--   2.  eq does not match
--   3.  neq matches when path differs
--   4.  in matches when value in array
--   5.  in does not match when value missing
--   6.  not_in matches when value absent
--   7.  exists matches when path present
--   8.  not_exists matches when path missing
--   9.  gte matches numerically
--  10.  lte does not match numerically
--  11.  all aggregate true when both children true
--  12.  any aggregate true when at least one child true

set search_path = extensions, public, identity, organization, audit, supplier,
                  commodity, rfq, offer, evaluation, contract, shipment, notify,
                  marketplace, dispatch, telematics, execution, workflow, rules, tests;
begin;

select plan(12);

-- Sample context.
do $$
begin
  perform set_config('test.ctx_157', jsonb_build_object(
    'shipment', jsonb_build_object(
      'transport_mode', 'road',
      'destination_country', 'TR',
      'planned_value', 250
    )
  )::text, true);
end $$;

-- 1
select is(
  rules.fn_eval_clause(
    jsonb_build_object('path','shipment.transport_mode','op','eq','value','road'),
    current_setting('test.ctx_157')::jsonb),
  true, 'eq matches');

-- 2
select is(
  rules.fn_eval_clause(
    jsonb_build_object('path','shipment.transport_mode','op','eq','value','rail'),
    current_setting('test.ctx_157')::jsonb),
  false, 'eq does not match');

-- 3
select is(
  rules.fn_eval_clause(
    jsonb_build_object('path','shipment.transport_mode','op','neq','value','rail'),
    current_setting('test.ctx_157')::jsonb),
  true, 'neq matches when path differs');

-- 4
select is(
  rules.fn_eval_clause(
    jsonb_build_object('path','shipment.destination_country','op','in',
                       'value', jsonb_build_array('TR','IQ')),
    current_setting('test.ctx_157')::jsonb),
  true, 'in matches when value in array');

-- 5
select is(
  rules.fn_eval_clause(
    jsonb_build_object('path','shipment.missing_field','op','in',
                       'value', jsonb_build_array('x')),
    current_setting('test.ctx_157')::jsonb),
  false, 'in does not match when path missing');

-- 6
select is(
  rules.fn_eval_clause(
    jsonb_build_object('path','shipment.transport_mode','op','not_in',
                       'value', jsonb_build_array('rail','sea')),
    current_setting('test.ctx_157')::jsonb),
  true, 'not_in matches when value absent from array');

-- 7
select is(
  rules.fn_eval_clause(
    jsonb_build_object('path','shipment.transport_mode','op','exists'),
    current_setting('test.ctx_157')::jsonb),
  true, 'exists matches when path present');

-- 8
select is(
  rules.fn_eval_clause(
    jsonb_build_object('path','shipment.nonexistent','op','not_exists'),
    current_setting('test.ctx_157')::jsonb),
  true, 'not_exists matches when path missing');

-- 9
select is(
  rules.fn_eval_clause(
    jsonb_build_object('path','shipment.planned_value','op','gte','value', 100),
    current_setting('test.ctx_157')::jsonb),
  true, 'gte matches numerically (250 >= 100)');

-- 10
select is(
  rules.fn_eval_clause(
    jsonb_build_object('path','shipment.planned_value','op','lte','value', 100),
    current_setting('test.ctx_157')::jsonb),
  false, 'lte does not match numerically (250 <= 100 false)');

-- 11
select is(
  rules.fn_eval_condition(
    jsonb_build_object('all', jsonb_build_array(
      jsonb_build_object('path','shipment.transport_mode','op','eq','value','road'),
      jsonb_build_object('path','shipment.destination_country','op','eq','value','TR')
    )),
    current_setting('test.ctx_157')::jsonb),
  true, 'all aggregate true when both children true');

-- 12
select is(
  rules.fn_eval_condition(
    jsonb_build_object('any', jsonb_build_array(
      jsonb_build_object('path','shipment.transport_mode','op','eq','value','rail'),
      jsonb_build_object('path','shipment.transport_mode','op','eq','value','road')
    )),
    current_setting('test.ctx_157')::jsonb),
  true, 'any aggregate true when at least one child true');

select * from finish();
rollback;
