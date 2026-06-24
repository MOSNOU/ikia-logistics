-- CC-03 / Migration 0001
-- Extensions and schemas for Phase 1 foundation.

create extension if not exists pgcrypto;
create extension if not exists citext;

create schema if not exists identity;
create schema if not exists organization;
create schema if not exists audit;

grant usage on schema identity     to anon, authenticated, service_role;
grant usage on schema organization to anon, authenticated, service_role;
grant usage on schema audit        to anon, authenticated, service_role;

comment on schema identity     is 'iKIA Phase 1 — identity, access, and tenancy root entities.';
comment on schema organization is 'iKIA Phase 1 — organizations, business units, and memberships.';
comment on schema audit        is 'iKIA Phase 1 — append-only audit log of platform events.';
