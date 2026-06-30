-- CC-47 Test 168 — Driver app schema shape.
--
-- Assertions (14):
--   1-4.  the 4 new dispatch enums exist
--   5-8.  the 4 new columns on dispatch.dispatch_assignments exist
--   9-11. the 3 new tables exist
--   12-14 key FK wiring (events.dispatch_id, pods.file_id, issues.reported_by)

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  notify, marketplace, dispatch, telematics, app_storage, tests;
begin;

select plan(14);

-- 1-4. enums
select has_type('dispatch', 'trip_execution_status', 'trip_execution_status enum exists');
select has_type('dispatch', 'trip_issue_category',   'trip_issue_category enum exists');
select has_type('dispatch', 'trip_issue_status',     'trip_issue_status enum exists');
select has_type('dispatch', 'trip_pod_kind',         'trip_pod_kind enum exists');

-- 5-8. new columns on dispatch_assignments
select has_column('dispatch', 'dispatch_assignments', 'driver_user_id',   'da.driver_user_id exists');
select has_column('dispatch', 'dispatch_assignments', 'execution_status', 'da.execution_status exists');
select has_column('dispatch', 'dispatch_assignments', 'accepted_at',      'da.accepted_at exists');
select has_column('dispatch', 'dispatch_assignments', 'completed_at',     'da.completed_at exists');

-- 9-11. new tables
select has_table('dispatch', 'driver_trip_events', 'driver_trip_events table exists');
select has_table('dispatch', 'driver_trip_issues', 'driver_trip_issues table exists');
select has_table('dispatch', 'driver_trip_pods',   'driver_trip_pods table exists');

-- 12-14. FK wiring
select fk_ok('dispatch', 'driver_trip_events', 'dispatch_id',
             'dispatch', 'dispatch_assignments', 'id');
select fk_ok('dispatch', 'driver_trip_pods', 'file_id',
             'app_storage', 'files', 'id');
select fk_ok('dispatch', 'driver_trip_issues', 'reported_by',
             'auth', 'users', 'id');

select * from finish();
rollback;
