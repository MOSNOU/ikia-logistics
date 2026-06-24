-- CC-22 Test 083 — KYC schema shape (enums, tables, columns, RLS, grants).
--
-- Assertions (26):
--   1-2   : schema kyc exists; usage granted to authenticated
--   3-8   : 6 enums exist
--   9-13  : 5 tables exist
--   14-18 : RLS enabled on all 5 tables
--   19    : 0 direct INSERT/UPDATE/DELETE grants to anon/authenticated
--   20    : every kyc.* RPC is SECURITY DEFINER
--   21    : every kyc.* RPC has search_path = ''
--   22    : kyc.personal_verifications has the 21 expected columns
--   23    : kyc.organization_verifications has the 22 expected columns
--   24    : kyc.documents has the 23 expected columns
--   25    : kyc.events has the 11 expected columns
--   26    : national_id_number_hash column is revoked from authenticated

set search_path = extensions, public, identity, organization, audit,
                  supplier, commodity, rfq, offer, evaluation, contract, shipment,
                  app_storage, finance, settlement, dispute, notify, kyc, tests;
begin;

select plan(26);

-- 1. schema exists
select is(
  (select count(*)::int from pg_namespace where nspname = 'kyc'),
  1, 'kyc schema exists'
);

-- 2. usage granted to authenticated
select is(
  (select has_schema_privilege('authenticated', 'kyc', 'USAGE')),
  true, 'authenticated has USAGE on kyc schema'
);

-- 3-8. enums
select is(
  (select count(*)::int from pg_type t
     join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'kyc' and t.typname = 'kyc_subject_type'),
  1, 'enum kyc.kyc_subject_type exists'
);
select is(
  (select count(*)::int from pg_type t
     join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'kyc' and t.typname = 'kyc_status'),
  1, 'enum kyc.kyc_status exists'
);
select is(
  (select count(*)::int from pg_type t
     join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'kyc' and t.typname = 'kyc_document_kind'),
  1, 'enum kyc.kyc_document_kind exists'
);
select is(
  (select count(*)::int from pg_type t
     join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'kyc' and t.typname = 'kyc_document_status'),
  1, 'enum kyc.kyc_document_status exists'
);
select is(
  (select count(*)::int from pg_type t
     join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'kyc' and t.typname = 'kyc_risk_severity'),
  1, 'enum kyc.kyc_risk_severity exists'
);
select is(
  (select count(*)::int from pg_type t
     join pg_namespace n on n.oid = t.typnamespace
    where n.nspname = 'kyc' and t.typname = 'kyc_event_kind'),
  1, 'enum kyc.kyc_event_kind exists'
);

-- 9-13. tables exist
select is(
  (select count(*)::int from information_schema.tables
    where table_schema = 'kyc' and table_name = 'personal_verifications'),
  1, 'table kyc.personal_verifications exists'
);
select is(
  (select count(*)::int from information_schema.tables
    where table_schema = 'kyc' and table_name = 'organization_verifications'),
  1, 'table kyc.organization_verifications exists'
);
select is(
  (select count(*)::int from information_schema.tables
    where table_schema = 'kyc' and table_name = 'documents'),
  1, 'table kyc.documents exists'
);
select is(
  (select count(*)::int from information_schema.tables
    where table_schema = 'kyc' and table_name = 'risk_flags'),
  1, 'table kyc.risk_flags exists'
);
select is(
  (select count(*)::int from information_schema.tables
    where table_schema = 'kyc' and table_name = 'events'),
  1, 'table kyc.events exists'
);

-- 14-18. RLS enabled
select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'kyc' and c.relname = 'personal_verifications'),
  true, 'RLS enabled on kyc.personal_verifications'
);
select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'kyc' and c.relname = 'organization_verifications'),
  true, 'RLS enabled on kyc.organization_verifications'
);
select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'kyc' and c.relname = 'documents'),
  true, 'RLS enabled on kyc.documents'
);
select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'kyc' and c.relname = 'risk_flags'),
  true, 'RLS enabled on kyc.risk_flags'
);
select is(
  (select relrowsecurity from pg_class c join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'kyc' and c.relname = 'events'),
  true, 'RLS enabled on kyc.events'
);

-- 19. no direct DML grants
select is(
  (select count(*)::int from information_schema.role_table_grants
    where table_schema = 'kyc' and grantee in ('anon','authenticated')
      and privilege_type in ('INSERT','UPDATE','DELETE')),
  0, 'no direct INSERT/UPDATE/DELETE grants on kyc.* tables'
);

-- 20. every RPC is SECURITY DEFINER
select is(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'kyc'
      and (p.proname like 'start_%' or p.proname like 'submit_%'
           or p.proname like 'update_%' or p.proname like 'attach_%'
           or p.proname like 'admin_%' or p.proname like 'get_%'
           or p.proname like 'is_%' or p.proname like 'expire_%')
      and not p.prosecdef),
  0, 'every kyc.* user-facing RPC is security_definer'
);

-- 21. every RPC has search_path = ''
select is(
  (select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'kyc'
      and (p.proname like 'start_%' or p.proname like 'submit_%'
           or p.proname like 'update_%' or p.proname like 'attach_%'
           or p.proname like 'admin_%' or p.proname like 'get_%'
           or p.proname like 'is_%' or p.proname like 'expire_%')
      and not exists (
        select 1 from unnest(coalesce(p.proconfig, array[]::text[])) s where s = 'search_path=""'
      )),
  0, 'every kyc.* user-facing RPC has search_path = empty string'
);

-- 22. personal_verifications column set
select is(
  (select count(*)::int from information_schema.columns
    where table_schema = 'kyc' and table_name = 'personal_verifications'
      and column_name in (
        'id','tenant_id','user_id','attempt_no',
        'status','full_legal_name','national_id_number_hash','national_id_last4',
        'date_of_birth','country_code',
        'submitted_at','reviewed_at','reviewed_by','decision_reason',
        'approved_at','expires_at',
        'created_at','updated_by','updated_at','deleted_at','version'
      )),
  21, 'kyc.personal_verifications has the 21 expected columns'
);

-- 23. organization_verifications column set
select is(
  (select count(*)::int from information_schema.columns
    where table_schema = 'kyc' and table_name = 'organization_verifications'
      and column_name in (
        'id','tenant_id','organization_id','attempt_no',
        'status','legal_name','registration_number','tax_id',
        'country_code','incorporated_on','authorized_signatory_user_id',
        'submitted_at','reviewed_at','reviewed_by','decision_reason',
        'approved_at','expires_at',
        'created_at','updated_by','updated_at','deleted_at','version'
      )),
  22, 'kyc.organization_verifications has the 22 expected columns'
);

-- 24. documents column set
select is(
  (select count(*)::int from information_schema.columns
    where table_schema = 'kyc' and table_name = 'documents'
      and column_name in (
        'id','tenant_id','subject_type',
        'personal_verification_id','organization_verification_id',
        'document_kind','title','bucket','storage_path','mime_type','size_bytes',
        'issued_on','expires_on','status','rejection_reason',
        'reviewed_at','reviewed_by',
        'created_by','created_at','updated_by','updated_at','deleted_at','version'
      )),
  23, 'kyc.documents has the 23 expected columns'
);

-- 25. events column set
select is(
  (select count(*)::int from information_schema.columns
    where table_schema = 'kyc' and table_name = 'events'
      and column_name in (
        'id','tenant_id','subject_type','user_id','organization_id',
        'personal_verification_id','organization_verification_id',
        'event_kind','actor_user_id','payload','occurred_at'
      )),
  11, 'kyc.events has the 11 expected columns'
);

-- 26. hash column is revoked from authenticated
select is(
  (select count(*)::int from information_schema.column_privileges
    where table_schema = 'kyc' and table_name = 'personal_verifications'
      and column_name = 'national_id_number_hash'
      and grantee = 'authenticated'
      and privilege_type = 'SELECT'),
  0, 'national_id_number_hash SELECT is revoked from authenticated'
);

select * from finish();
rollback;
