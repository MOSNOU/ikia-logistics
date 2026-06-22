-- CC-05 / Migration 0016 — JWT helper bug fix
--
-- Bug:
--   identity.current_tenant_id() and identity.current_organization_id() (from
--   migration 0006) cast `current_setting('request.jwt.claims', true)::jsonb`
--   directly. If the GUC has been reset to its default empty string
--   (e.g. via `set_config('request.jwt.claims', null, true)` in the pgTAP
--   `tests.set_anon()` helper), the cast '' :: jsonb raises
--   "invalid input syntax for type json". The bug was masked until CC-05's
--   test 001 explicitly cleared the GUC.
--
-- Fix:
--   Apply `nullif(current_setting(...), '')` BEFORE the `::jsonb` cast so
--   empty-string becomes NULL and the cast yields NULL jsonb (NULL ->> 'x'
--   is NULL, which propagates safely).
--
-- Append-only: migrations 0001-0015 unchanged.
-- Both functions are recreated with CREATE OR REPLACE; signatures, volatility,
-- security definer, search_path and return type are preserved exactly.

create or replace function identity.current_tenant_id()
  returns uuid
  language sql
  stable
  security definer
  set search_path = ''
as $$
  select nullif(
    nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'tenant_id',
    ''
  )::uuid;
$$;

comment on function identity.current_tenant_id() is
  'Extracts tenant_id from the request JWT. Returns NULL when no JWT, claim missing, or GUC reset to empty default.';

create or replace function identity.current_organization_id()
  returns uuid
  language sql
  stable
  security definer
  set search_path = ''
as $$
  select nullif(
    nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'organization_id',
    ''
  )::uuid;
$$;

comment on function identity.current_organization_id() is
  'Extracts active organization_id from the request JWT. Returns NULL when no JWT, claim missing, or GUC reset to empty default.';
