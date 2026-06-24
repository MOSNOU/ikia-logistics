# CC-15 — Phase 2.8 Document / File Storage Foundation, Schema Notes

Version: 1.0 (DRAFT)
Scope: Ninth business domain step — application-layer file metadata + versioning + polymorphic entity linking. Bytes live in Supabase Storage (or an external object store) addressed by `(bucket, object_key)`; the rows in this domain record metadata, lifecycle, version history, and links to entities created in CC-09 through CC-14 (RFQ, offer, evaluation, decision, contract preparation, executed contract, shipment, supplier, organization).
Migration: `23-DATABASE/migrations/0026_document_file_storage_foundation.sql` (single, append-only).
Status: Implementation complete; tests 053–056 pass (31 assertions). Pending user acceptance.

## Schema name deviation

The CC-15 prompt asked for a `storage` schema. The Supabase Storage Service already owns a schema literally named `storage`, populated with `buckets`, `objects`, `migrations`, `s3_multipart_uploads`, etc. (owner: `supabase_storage_admin`). Even the migration runner cannot `CREATE TYPE` inside that schema — applying our DDL there fails with `42501: permission denied for schema storage`.

To honour the spirit of the prompt without colliding with the platform-managed schema, this migration uses **`app_storage`** as the top-level schema. All RPC namespaces, table names, and grants are otherwise unchanged. The Supabase `storage` schema is left untouched.

## Mission

CC-15 introduces application-layer file metadata so any domain entity can attach versioned files (specifications, certificates, BoL scans, contracts, etc.) without each domain re-implementing storage tracking. The schema records:

- `app_storage.files` — current head metadata for each logical file (filename, mime type, status, current version).
- `app_storage.file_versions` — full version history with one row per version (bytes addressed by `(bucket, object_key)`).
- `app_storage.file_associations` — polymorphic links to domain entities (`entity_type`, `entity_id`).

No bytes are stored in PostgreSQL; the bytes live in Supabase Storage (or a future external object store), addressed by the `(bucket, object_key)` pair recorded on each version. Upload itself is performed client-side via Supabase Storage's signed-URL flow; our RPCs only track metadata.

## Relationship to existing foundations

| Foundation | How CC-15 uses it |
|------------|-------------------|
| identity | `is_platform_admin()`, `current_organization_id()`, `current_user_id()` |
| organization | `organizations`, `memberships` — file's owning org is the caller's org |
| supplier | `supplier.fn_portal_supplier_id()` (safely swallowed for non-supplier callers) for cross-org supplier visibility |
| rfq | `rfq.requests`, `rfq.request_supplier_invitations` for entity-visibility check on rfq files |
| offer | `offer.supplier_offers` for entity-visibility check on offer files |
| evaluation | `evaluation.offer_evaluations`, `evaluation.offer_decisions` for entity-visibility |
| contract | `contract.contract_preparations`, `contract.executed_contracts` for entity-visibility |
| shipment | `shipment.shipments` for entity-visibility |
| audit | `audit.audit_event` written by `app_storage.fn_audit` and indirectly via the generic audit trigger on every table |
| Supabase Storage Service | external service that hosts the actual bytes; this domain only records the `(bucket, object_key)` pointer |

## Locked decisions

| # | Decision | Source |
|---|----------|--------|
| 1 | Single append-only migration `0026_document_file_storage_foundation.sql`. | CC-15 prompt |
| 2 | Schema `app_storage` (prompt asked for `storage`; renamed due to Supabase reserved schema). | This document |
| 3 | RPC namespace `portal_*` for cross-domain file actions; `admin_*` for platform admin. No domain-specific buyer_/supplier_ namespaces — `entity_type` is parameterised. | CC-15 prompt #6 |
| 4 | All mutations via SECURITY DEFINER RPCs. No direct INSERT/UPDATE/DELETE grants. | CC-15 prompt #5 |
| 5 | `search_path = ''` on every SECURITY DEFINER function. | CC-15 prompt #5 |
| 6 | Portal RPCs derive organization from `identity.current_organization_id()` — no `p_organization_id`, no `p_supplier_id`, no `p_buyer_organization_id` parameters. | CC-15 prompt #5 |
| 7 | A file's owning organization is the caller's org at registration time. Listing files for an entity uses an entity-visibility check, so suppliers can read files attached to entities they own (e.g. their shipment) even though the file's organization_id is the buyer's. | CC-15 design |
| 8 | `portal_register_file` generates a deterministic `object_key = {org_id}/{file_id}/{sanitised-filename}` and creates a v1 row in `file_versions` simultaneously. | CC-15 design |
| 9 | `portal_create_file_version` marks the previous head as `superseded` and bumps `files.current_version`. | CC-15 design |
| 10 | `portal_link_file_to_entity` is the only way to attach files to entities; it runs `fn_caller_can_see_entity` so cross-org links are blocked unless the caller has visibility. | CC-15 prompt #7 |
| 11 | No file_buckets table — the `bucket` column is a free text label that points at a Supabase Storage bucket name. Bucket policies live inside Supabase Storage's own ACLs, not in this schema. | CC-15 design (prompt said "optional") |
| 12 | No file_upload_sessions table — Supabase Storage handles resumable upload sessions itself. Adding our own table would duplicate that. Future addition if we need to track multi-part uploads through our domain. | CC-15 design (prompt said "optional") |

## Schema overview

### Enums (3)

- `app_storage.file_status` — `pending, uploaded, processed, archived`
- `app_storage.file_type` — `pdf, image, doc, xlsx, txt, other`
- `app_storage.file_version_status` — `pending, uploaded, archived, superseded`

### Tables (3)

| Table | Purpose |
|-------|---------|
| `app_storage.files` | One row per logical file. Carries owning org, uploader, current `(bucket, object_key)` pointer, mime type, size, status, current version pointer. |
| `app_storage.file_versions` | Per-file version history. Each version has its own `(bucket, object_key)`. Statuses: `pending` (registered but not uploaded yet), `uploaded`, `archived`, `superseded`. |
| `app_storage.file_associations` | Polymorphic link rows: `(file_id, entity_type, entity_id, role)` with partial unique index for active links. |

## File lifecycle

```
            portal_register_file(filename, mime?, size?, bucket?)
                              │  ↳ creates files row in 'pending' + v1 in file_versions ('pending')
                              │    returns {file_id, bucket, object_key, version_number}
                              ▼
                           pending
                              │ client uploads bytes via Supabase Storage signed URL
                              │
                  portal_finalize_file_upload(file_id, size?, checksum?)
                              │  ↳ flips files.status + v1.status to 'uploaded'
                              ▼
                          uploaded
                              │
                       (optional)
                              │ portal_create_file_version(file_id, ...)
                              │  ↳ marks current head 'superseded',
                              │    inserts new version, bumps files.current_version,
                              │    resets files.status to 'pending'
                              │
                  portal_link_file_to_entity / portal_remove_file_association
                              │
                              │
                  portal_archive_file(file_id, reason?)
                              ▼
                          archived (terminal)
```

- Files can be linked to multiple entities (one association row per entity) — both buyer and supplier flows can attach the same file as evidence.
- `archived` is the only terminal state. The bytes are not deleted from Supabase Storage by this RPC — operators can run a separate sweep against archived rows.

## Security model

### RLS

All 3 tables have RLS enabled with a simple predicate:

- **Org members** — members of the file's `organization_id`.
- **Platform admin** — always.

Cross-org supplier read access (e.g. supplier reading buyer-owned files attached to their shipment) is **NOT** granted by RLS. It is granted by the `portal_list_files_for_entity` RPC, which runs `fn_caller_can_see_entity` to verify the caller can read the target entity, then returns the file rows via SECURITY DEFINER. This keeps the RLS policy simple and the cross-domain rule explicit and reviewable.

### Grants

```
anon          → app_storage.files                                       SELECT (RLS returns 0)
authenticated → app_storage.files, file_versions, file_associations     SELECT
```

`file_versions` and `file_associations` are intentionally NOT exposed to `anon`. **No INSERT/UPDATE/DELETE direct grants on any `app_storage` table.**

### Helper functions (internal, SECURITY DEFINER, `search_path=''`)

| Function | Purpose |
|----------|---------|
| `app_storage.fn_audit(action, file_id, payload)` | Writes domain audit event; exception-swallowed. |
| `app_storage.fn_assert_authenticated_member()` | Returns `(tenant_id, organization_id)` of caller; raises `42501` if not authenticated or `P0002` if no active org. |
| `app_storage.fn_assert_file_owned(file_id)` | Raises `42501` if caller's org doesn't own the file. |
| `app_storage.fn_caller_can_see_entity(entity_type, entity_id)` | Returns boolean. Recognizes `rfq`, `offer`, `evaluation`, `decision`, `contract_preparation`, `executed_contract`, `shipment`, `supplier`, `organization`. Returns `true` for platform admin and for org/supplier members with visibility into the entity per existing domain rules. Returns `false` for unrecognised types. Safely swallows `supplier.fn_portal_supplier_id()` exceptions for non-supplier callers. |
| `app_storage.fn_default_object_key(org, file_id, filename)` | Generates `{org}/{file_id}/{sanitised}` keys. |

## RPC inventory (12)

### Portal RPCs (9)

| Function | Vol | Purpose |
|----------|-----|---------|
| `portal_register_file(filename, mime?, size?, bucket?, file_type?, extension?, metadata?)` returns jsonb | volatile | Creates file (status='pending') + v1 version row. Returns `{file_id, bucket, object_key, status, version_number}`. Client uses bucket/object_key with Supabase Storage's signed URL. |
| `portal_finalize_file_upload(file_id, size?, checksum?)` | volatile | Flips status pending → uploaded on both the file row and the current head version. |
| `portal_archive_file(file_id, reason?)` | volatile | Marks file archived. |
| `portal_create_file_version(file_id, mime?, size?, metadata?)` returns jsonb | volatile | Supersedes the previous head; creates a new version row in `pending`; bumps `files.current_version`. Returns the new `{file_id, version_id, version_number, bucket, object_key}`. |
| `portal_link_file_to_entity(file_id, entity_type, entity_id, role?, metadata?)` returns uuid | volatile | Upsert by `(file_id, entity_type, entity_id, coalesce(role,''))`. Runs entity-visibility check. |
| `portal_remove_file_association(association_id)` | volatile | Soft-delete the link. |
| `portal_list_files_for_entity(entity_type, entity_id, limit, offset)` returns table | stable | Lists files associated with an entity; gated by `fn_caller_can_see_entity`. Enables cross-org supplier visibility. |
| `portal_get_file_metadata(file_id)` returns jsonb | stable | Full detail with versions + associations arrays. |
| `portal_list_my_files(status?, limit, offset)` returns table | stable | Lists files owned by caller's organization. |

### Admin RPCs (3)

| Function | Vol | Purpose |
|----------|-----|---------|
| `admin_list_files(organization_id?, status?, limit, offset)` | stable | Cross-org admin list. |
| `admin_get_file(file_id)` returns jsonb | stable | Detail with counts. |
| `admin_force_archive_file(file_id, reason?)` | volatile | Admin override to archived. |

**12 RPCs total.** All `SECURITY DEFINER`, all `search_path=""`, single owner `postgres`. Volatility split: 5 stable / 7 volatile.

## Validation Summary

### Migration apply

```
Applying migration 20260622090026_document_file_storage_foundation.sql...
Finished supabase db reset on branch main.
```

All 26 migrations apply cleanly. One mid-implementation fix was required: `fn_caller_can_see_entity` initially called `supplier.fn_portal_supplier_id()` unconditionally, which raises `42501` for buyer-only users. Wrapped in a safe try/catch so buyer callers fall through to the buyer-org checks.

### Verification queries (snapshot)

- 3 `app_storage.*` tables, all `relrowsecurity = t`, `relforcerowsecurity = f`
- 0 INSERT/UPDATE/DELETE direct grants on `app_storage.*`
- 12 RPCs across portal/admin namespaces (9 portal + 3 admin)
- All RPCs `owner=postgres`, `security_definer=t`, `search_path=""`
- 5 stable + 7 volatile (split matches read/write intent)
- 0 portal RPCs accept `p_organization_id`, `p_supplier_id`, or `p_buyer_organization_id`
- Single distinct owner across all RPCs

### pgTAP suite

```
================================================================
Files: 56 passed, 0 failed
Assertions: 364 passed, 0 failed
================================================================
```

| File | Assertions | Coverage |
|------|------------|----------|
| 001–052 | 333 | CC-05 through CC-14 (incl. acceptance) |
| **053 app_storage RLS, grants, RPC metadata, safety** | **11** | **CC-15** |
| **054 file lifecycle** (register → v1 → finalize → link → list_for_entity → metadata jsonb → create_version supersedes v1 → remove association → archive) | **10** | **CC-15** |
| **055 scope + integrity** (cross-buyer block, cross-buyer link block, list-for-unseen-entity 42501, link-to-unseen-entity 42501, double finalize P0001) | **5** | **CC-15** |
| **056 cross-domain visibility** (supplier reads file via own-shipment, unrelated supplier 42501 on list & get, direct UPDATE/DELETE on associations blocked) | **5** | **CC-15** |
| **CC-15 new** | **31** | |
| **Suite total** | **364** | **across 56 files** |

### Frontend

CC-15 added no frontend code. The frontend remains at its CC-07 surface (22 routes). `supabase/config.toml` does not yet expose the `app_storage` schema to PostgREST — must be added before any UI calls these RPCs.

## Known limitations / handoff notes for CC-16

1. **No actual file upload integration.** `portal_register_file` returns `(bucket, object_key)`; the client is expected to call Supabase Storage's `createSignedUploadUrl` (or equivalent) and PUT the bytes. CC-16 frontend work needs to wire this together.
2. **No Supabase Storage bucket provisioning.** The `bucket` field defaults to `'app-documents'` but that bucket must be created in the Supabase dashboard / via a separate Supabase Storage migration. Documentation of the expected bucket configuration (private, RLS-locked) is a CC-16 deliverable.
3. **No file deletion of underlying bytes.** `portal_archive_file` flips status; the bytes remain in Supabase Storage. A periodic sweep RPC / background job to delete archived bytes is a future addition.
4. **No virus scanning, MIME sniffing, or content validation.** Mime type is taken from the client; no server-side verification.
5. **No quotas or rate limits.** A buyer org can register unlimited files. Quota policies (per-org, per-day) are a future addition.
6. **No `file_upload_sessions` table.** Resumable / multi-part uploads are handled by Supabase Storage itself. If we ever need to track sessions through our domain (e.g. for very large files with custom workflow), the table can be added.
7. **No `file_buckets` table.** Bucket configuration lives in Supabase Storage. If we ever need our own bucket-policy metadata layer, a `file_buckets` table can be added.
8. **`fn_caller_can_see_entity` returns false for unknown entity_types.** This is intentionally strict — UI must use one of the recognised types (`rfq`, `offer`, `evaluation`, `decision`, `contract_preparation`, `executed_contract`, `shipment`, `supplier`, `organization`). Adding a new entity type requires extending the helper.
9. **`schema storage` deviation.** This domain uses `app_storage`, not `storage`. Future docs, route guards, and frontend wrappers should use `app_storage` schema references.
10. **No `Database` type entry for `app_storage`** in the frontend types file. Will be added when file-upload UI lands in CC-16.
11. **No pricing / settlement / escrow / payment / invoice / accounting / insurance / GPS / negotiation.** Same exclusion boundary as CC-13/CC-14. Test 053/11 verifies that no schemas with those names exist.
12. **Direct INSERTs by `service_role` bypass entity-visibility checks.** Cross-org integrity is RPC-enforced, not FK-enforced. Mitigated by no-direct-write-grants on `authenticated`.
