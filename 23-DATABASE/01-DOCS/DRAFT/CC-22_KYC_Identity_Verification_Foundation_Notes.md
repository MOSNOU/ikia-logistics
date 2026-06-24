# CC-22 — Phase 2.15 KYC & Identity Verification Foundation, Notes

Version: 1.0 (DRAFT)
Scope: Sixteenth platform step — server-side spine for KYC (person) and KYB
(organization) identity verification. Schema + RPCs + RLS + tests only. No
external provider integration; no UI in this CC; no modification of
migrations 0001–0030.
Migration: **0031_kyc_foundation.sql** (new, append-only).
Status: Implementation complete; all directives met. Pending user acceptance.

## Locked decisions (Q1–Q10)

| # | Decision | Notes |
|---|----------|--------|
| Q1 | A — single migration `0031_kyc_foundation.sql` | Schema + RPCs + RLS in one file. |
| Q2 | Yes — `kyc` added to PostgREST exposure | `supabase/config.toml` updated. |
| Q3 | A — tenant-scoped attempts | Unique `(tenant_id, user_id, attempt_no)` and `(tenant_id, organization_id, attempt_no)`. |
| Q4 | A — hash + last-4 only | `national_id_number_hash` (sha256) + `national_id_last4` (display); raw never persisted; column-list GRANT excludes the hash. |
| Q5 | A — 12-month default validity | `kyc.admin_approve_verification(..., p_validity_months int default 12)`. |
| Q6 | B — dedicated `kyc-private` bucket | Stamped on `kyc.documents.bucket` as default; bucket creation is operator-side. |
| Q7 | B — free-text `source` on risk_flags | Avoids enum churn when providers are wired later. |
| Q8 | A — no supplier wiring | `supplier.suppliers.verification_status` semantics unchanged. |
| Q9 | A — zero UI | Schema spine only. |
| Q10 | A — stop at typecheck/build/pgTAP green | Matches CC-21 stop cadence. |

## What changed

### Files created (1 migration + 9 tests + 1 doc)

| File | Purpose |
|---|---|
| `23-DATABASE/migrations/0031_kyc_foundation.sql` | Schema, 6 enums, 5 tables, 5 RLS-enabled policies, 19 RPCs, helpers, audit + event hooks, grants. |
| `supabase/migrations/20260623090031_kyc_foundation.sql` | Symlink → `0031_kyc_foundation.sql`. |
| `23-DATABASE/tests/083_kyc_schema_shape.sql` | Schema/enum/table/RLS/grant assertions (26). |
| `23-DATABASE/tests/084_kyc_rls_personal.sql` | RLS isolation on personal verifications (6). |
| `23-DATABASE/tests/085_kyc_rls_organization.sql` | RLS isolation on organization verifications (6). |
| `23-DATABASE/tests/086_kyc_lifecycle_personal.sql` | Full personal lifecycle (16). |
| `23-DATABASE/tests/087_kyc_lifecycle_organization.sql` | Full organization lifecycle (12). |
| `23-DATABASE/tests/088_kyc_documents.sql` | Documents xor + attach/decide (8). |
| `23-DATABASE/tests/089_kyc_risk_flags.sql` | Risk flag raise/resolve + xor + RLS (8). |
| `23-DATABASE/tests/090_kyc_events_immutable.sql` | Append-only ledger (5). |
| `23-DATABASE/tests/091_kyc_helpers_and_expiry.sql` | Helpers + expire_due_verifications (8). |

### Files modified (2)

| File | Change |
|---|---|
| `supabase/config.toml` | Added `kyc` to `[api].schemas` and `extra_search_path` per Q2=Yes. |
| `23-DATABASE/tests/080_cc20_database_type_sync.sql` | Added `kyc` to the schema allow-list (assertion 5). Without this, the new schema would trip the existing governance assertion. |
| `22-SOURCE-CODE/frontend-web/src/types/database.ts` | Regenerated canonical types (now ~10692 generated lines + CC-21 sidecar barrel). |

### Surfaces created in schema `kyc`

- **6 enums**: `kyc_subject_type`, `kyc_status` (8 states), `kyc_document_kind` (10 kinds), `kyc_document_status`, `kyc_risk_severity`, `kyc_risk_status`, `kyc_event_kind` (11 events).
- **5 tables**: `personal_verifications`, `organization_verifications`, `documents`, `risk_flags`, `events`.
- **19 RPCs (all SECURITY DEFINER, search_path=''):**
  - Subject (self-service, 7): `start_personal_verification`, `update_personal_draft`, `submit_personal_verification`, `start_organization_verification`, `update_organization_draft`, `submit_organization_verification`, `attach_document`.
  - Admin (8): `admin_assign_verification`, `admin_request_info`, `admin_approve_verification`, `admin_reject_verification`, `admin_decide_document`, `admin_raise_risk_flag`, `admin_resolve_risk_flag`, `expire_due_verifications`.
  - Read (2): `get_my_personal_verification`, `get_my_organization_verification`.
  - Admin read (2): `admin_list_verifications`, `admin_get_verification`.
  - Helpers (2): `is_personal_verified`, `is_organization_verified`.

### Status lifecycle

```
draft ─submit→ submitted ─assign→ in_review ─approve→ approved ─expiry→ expired
                                       │
                                       ├─info_request→ info_requested ─resubmit→ submitted
                                       │
                                       └─reject→ rejected
```

Invalid transitions raise SQLSTATE `22023`.

### Security model

- **No direct DML** to `anon` / `authenticated`. All mutations flow through SECURITY DEFINER RPCs.
- **RLS enabled** on all 5 tables with policies:
  - `personal_verifications`: subject (own row) + `platform_admin`.
  - `organization_verifications`: active member of the org + `platform_admin`.
  - `documents`: parent verification subject + `platform_admin`.
  - `risk_flags`: `platform_admin` only (sensitive); no SELECT grant for non-admins.
  - `events`: subject of the parent + `platform_admin`. UPDATE/DELETE forbidden by absence of grants and policies (append-only ledger).
- **PII handling (Q4=A)**: `national_id_number_hash` is sha256-hashed at the RPC boundary; column-level `GRANT SELECT(...)` deliberately excludes the hash for `authenticated`. Admins reach it via `admin_get_verification` RPC only.

## Mid-execution findings (5 → fixed before validation)

| # | Symptom | Root cause | Fix |
|---|---|---|---|
| 1 | `function extensions.encode(bytea, unknown) does not exist` | `encode()` lives in `pg_catalog`, not `extensions`; I had qualified it incorrectly. | `pg_catalog.encode(extensions.digest(...))`. |
| 2 | `function kyc.fn_record_event(...text...) does not exist` | The `CASE WHEN ... END` expression evaluates to `text`; PostgreSQL did not implicitly cast to `kyc.kyc_event_kind`. | Wrapped: `(case ... end)::kyc.kyc_event_kind`. Applied at both submit_personal_verification and submit_organization_verification. |
| 3 | `record "new" has no field "updated_by"` from `identity.set_updated_at()` trigger | `kyc.risk_flags` lacked an `updated_by` column. | Added `updated_by uuid references auth.users(id)`. Updated the raise / resolve RPC inserts/updates to populate it. |
| 4 | `national_id_number_hash` column SELECT still showed for `authenticated` | PostgreSQL ignores column-level REVOKE after a table-level GRANT. | Removed the table-level GRANT; replaced with explicit column-list `GRANT SELECT(...)` excluding the hash column. |
| 5 | Existing test 080 schema allow-list rejected `kyc` | Allow-list is closed; new schema must be added to keep the governance test honest. | Added `'kyc'` to the allow-list. |

## Validation results

| Gate | Required | Actual |
|---|---|---|
| `supabase db reset` | clean | **clean** (migration 0031 applies after 0030 with no errors) |
| `bash 23-DATABASE/tests/run.sh` | green | **91 files / 685 assertions / 0 failures** |
| `supabase gen types typescript` | committed | **canonical regenerated** (~10692 lines + 6-line CC-21 sidecar barrel) |
| `npm run typecheck` | 0 errors | **0 errors** |
| `npm run build` | exit 0 | **23 routes built** (was 22; the new admin-suppliers detail route count is preserved) |
| `bash scripts/verify-admin-route-guards.sh` | pass | **VERIFICATION PASSED** |

### pgTAP delta

```
Pre-CC-22:  82 files / 590 assertions / 0 failures
Post-CC-22: 91 files / 685 assertions / 0 failures
Delta:      +9 files / +95 assertions / 0 failures
```

Files 083–091 contribute the 95 new assertions:

| File | Assertions |
|---|---|
| 083 schema_shape | 26 |
| 084 rls_personal | 6 |
| 085 rls_organization | 6 |
| 086 lifecycle_personal | 16 |
| 087 lifecycle_organization | 12 |
| 088 documents | 8 |
| 089 risk_flags | 8 |
| 090 events_immutable | 5 |
| 091 helpers_and_expiry | 8 |
| **Total** | **95** |

## Out-of-scope boundaries respected (literal "Do Not Build")

- ✅ No real government / NID / passport / sanctions / PEP API integration.
- ✅ No payment, PSP, banking, tax, insurance, biometric, OCR.
- ✅ No new UI; no routes added to the Next.js app; no admin queue page.
- ✅ No modification to migrations 0001–0030.
- ✅ No modification to `supplier.suppliers.verification_status` semantics.
- ✅ No cross-tenant verification reuse; attempts are tenant-scoped.
- ✅ No SLA timers, escalation jobs, reviewer-load balancing.
- ✅ No `notify.*` schema or trigger modifications. Notification wiring for KYC entity types is intentionally deferred to a future CC; `kyc.events` and `audit.audit_event` capture the immutable trail meanwhile.
- ✅ No new dependencies (`package.json` untouched).

## Known limitations / handoff notes

1. **notify integration is deferred.** `notify.fn_resolve_recipients` does not recognize `personal_verification` / `organization_verification` entity types yet. A future CC will add KYC recipient resolution + seed templates. Until then, only `audit.audit_event` and `kyc.events` carry the lifecycle trail.
2. **kyc-private bucket creation is operational.** Migration 0031 defaults `kyc.documents.bucket` to `'kyc-private'` but does not insert a row into Supabase's `storage.buckets`; that is owned by `supabase_storage_admin` and needs to be created out-of-band (Supabase Studio or CLI) before any real upload flow.
3. **Helpers are ungated.** `kyc.is_personal_verified` and `kyc.is_organization_verified` are EXECUTE-granted to `authenticated`. They are intentionally cheap and return `boolean` for downstream gating. A future CC may wire them into finance / settlement / contract.
4. **`expire_due_verifications` is callable, not scheduled.** The RPC flips `approved` → `expired` for due rows and records `expired` events; it is granted to `service_role` so a future scheduled job (`pg_cron`, Supabase scheduled function) can call it on a tick. No scheduler wiring in CC-22.
5. **`kyc.events` is append-only by lack of grants/policies.** No UPDATE or DELETE path exists for any role except superuser. Test 090 locks this in (`42501` on attempts).
6. **No frontend types beyond regeneration.** The CC-21 sidecar (`database.compat.ts`) is unchanged. Future KYC frontend code should consume `Database["kyc"]["Tables"]["..."]["Row"]` and the matching `Functions` shapes directly.

## Acceptance criteria

- [ ] `supabase db reset` exits cleanly. ✓
- [ ] `bash 23-DATABASE/tests/run.sh` reports **91 / 685 / 0**. ✓
- [ ] `supabase gen types typescript --local` regeneration committed. ✓
- [ ] `npm run typecheck` exits 0. ✓
- [ ] `npm run build` exits 0 (23 routes). ✓
- [ ] `bash scripts/verify-admin-route-guards.sh` passes. ✓
- [ ] Confirm the `kyc-private` storage bucket needs operator creation (or schedule a follow-up CC to bootstrap it via Supabase migration of `storage.buckets`).
- [ ] Confirm CC-23 may proceed with notify integration / supplier wiring for KYC (separate scope contract).
