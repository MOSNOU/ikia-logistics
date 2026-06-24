# CC-39 — Carrier / Capacity Marketplace Backend Foundation

## Mission
Add the minimum DB primitives behind CC-38's deferred frontend stubs:
carrier-profile extension over `organization.organizations`, opt-in directory
visibility, publishable capacity listings, an immutable status-event ledger,
audience-scoped RPCs, RLS, grants, audit + notify integration, and pgTAP
coverage. No frontend changes — CC-40 wires the loaders.

## Locked decisions (Q1–Q10 as authorized)
- **Q1** schema name `marketplace`
- **Q2** extension table over `organization.organizations`
- **Q3** carrier-only ownership (org type=`carrier`, enforced via trigger)
- **Q4** opt-in directory visibility (`carrier_directory_visibility` table)
- **Q5** country_code (citext) + city (text), matching `shipment.shipments`
- **Q6** no pricing fields (notes only)
- **Q7** enforced 5-state lifecycle: `draft → active → reserved → expired → archived`
- **Q8** notify on publish + archive only (single trigger emits both event types)
- **Q9** admin archive-only moderation (no admin content edits)
- **Q10** no seed data

## Boundaries respected
- No changes to supplier or shipment schemas / RPCs.
- No changes to migrations 0001–0032 (append-only via 0033).
- No frontend changes — CC-38's UI continues showing its deferred-API state
  until CC-40 swaps loader bodies.
- No new dependencies.
- The notify integration adds **one new trigger function** on the new
  `marketplace.capacity_listings` table; **no existing notify logic was
  modified**. Routing uses category `'other'` to avoid touching the
  `notify.notification_category` enum.

## Files created (8)

### Migration
- `23-DATABASE/migrations/0033_marketplace_foundation.sql` — 4 tables, 2 enums,
  15 RPCs, 4 RLS-enabled tables with policies, 3 triggers (2 carrier-org-type
  asserts + 1 notify dispatch), all SELECT grants, EXECUTE grants on all
  audience RPCs.

### pgTAP tests
- `tests/102_marketplace_schema_shape.sql` — 10 assertions
- `tests/103_marketplace_grants_and_rls.sql` — 8 assertions
- `tests/104_marketplace_carrier_directory.sql` — 8 assertions
- `tests/105_marketplace_capacity_publish.sql` — 7 assertions
- `tests/106_marketplace_capacity_lifecycle.sql` — 7 assertions
- `tests/107_marketplace_admin_moderation.sql` — 6 assertions
- `tests/108_marketplace_activity_ledger.sql` — 6 assertions

Total added: **+7 files / +52 assertions** (baseline 101/790 → 108/842).

## Files modified (2)

- `supabase/config.toml` — added `marketplace` to PostgREST `schemas` and
  `extra_search_path` (required so CC-40 frontend can call the RPCs).
- `tests/080_cc20_database_type_sync.sql` — added `marketplace` to the
  CC-20 locked allow-list (otherwise the schema-introspection guard would
  flag the new schema as unexpected).

## Schema added — `marketplace`

### Enums (2)
- `marketplace.carrier_profile_status` — `draft | active | suspended | archived`
- `marketplace.capacity_status` — `draft | active | reserved | expired | archived`

### Tables (4)
| Table | Purpose | Key constraints |
|---|---|---|
| `carrier_profiles` | One row per carrier org; metadata extension | UNIQUE per organization_id; org_type=carrier via trigger |
| `carrier_directory_visibility` | Opt-in flag | PK = carrier_organization_id |
| `capacity_listings` | Publishable capacity | Carrier-org owned via trigger |
| `capacity_status_events` | Immutable status-change ledger | INSERT only via SECURITY DEFINER helper |

### Helpers (4)
- `marketplace.fn_audit(action, resource_id, type, payload)` — writes to `audit.audit_event`
- `marketplace.fn_assert_carrier_org_type(org_id)` — Q3 enforcement
- `marketplace.fn_assert_carrier_actor(org_id)` — role + ownership gate
- `marketplace.fn_record_capacity_event(listing_id, from, to, reason, payload)`

### Trigger functions (3)
- `marketplace.fn_trg_assert_carrier_profile_org` — Q3 trigger on `carrier_profiles`
- `marketplace.fn_trg_assert_capacity_org` — Q3 trigger on `capacity_listings`
- `notify.fn_trg_from_capacity_listing` — Q8 dispatch on `capacity_listings.status` changes

### RPCs (15)
| RPC | Audience |
|---|---|
| `carrier_upsert_profile`, `carrier_set_directory_visibility` | carrier_admin / org_admin / platform_admin |
| `buyer_list_carriers`, `buyer_get_carrier` | all authenticated (RLS-filtered) |
| `admin_list_carriers`, `admin_get_carrier` | platform_admin only |
| `supplier_publish_capacity`, `supplier_update_capacity`, `supplier_archive_capacity`, `supplier_list_my_capacity` | carrier_admin / org_admin / platform_admin of the carrier org |
| `buyer_list_capacity` | all authenticated (filters: active + public + non-expired) |
| `admin_list_capacity`, `admin_archive_capacity`, `admin_list_activity`, `admin_capacity_summary` | platform_admin only |

### RLS policies (4 tables, 7 policies)
- `carrier_profiles`: SELECT to admin / org member / (active+public via visibility join). Admin-modify policy for all writes.
- `carrier_directory_visibility`: SELECT to admin / org member / is_public=true rows.
- `capacity_listings`: SELECT to admin / carrier-org member (any status) / (active + public).
- `capacity_status_events`: SELECT inherits from parent listing.

## Integration

- **organization** — FK + Q3 trigger constraint that org.type='carrier'.
- **shipment** — reuses `shipment.transport_mode` enum directly. No FK from
  shipment to capacity (visibility-only, as authorized).
- **supplier** — **not linked**. "Supplier" in the RPC names refers to the
  CC-38 portal-shell convention; the backend role gate strictly requires
  carrier_admin / organization_admin / platform_admin on a `type='carrier'`
  org.
- **notify** — single trigger `notify.fn_trg_from_capacity_listing` fires on
  `capacity_listings.status` changes; emits `capacity.published` and
  `capacity.archived` event types via `notify.fn_materialize_event`. Routed
  through category `'other'` because `notification_category` enum does not
  include 'marketplace' yet — a later notify-extension CC can add the value
  without touching CC-39. Template lookups gracefully log
  `no_template_matched` until templates are seeded.
- **audit** — `marketplace.fn_audit` writes through the canonical
  `audit.audit_event` channel.

## Mid-execution findings & fixes

1. **`citext` requires `public.` qualification under `set search_path = ''`.**
   Initial RPC bodies cast to bare `citext[]`; failed inside SECURITY DEFINER
   functions. Replaced with `public.citext[]` throughout RPC bodies.
2. **`returns table` column types must match the source columns exactly.**
   `organization.organizations.code` is `citext`, not `text`. Updated
   `buyer_list_carriers` and `admin_list_carriers` table returns accordingly.
3. **Table SELECT grants were initially missing.** RLS policies on
   `capacity_listings` reference `carrier_directory_visibility` via a
   subquery; without SELECT grant on the referenced table the caller's role
   trips `42501: permission denied for table carrier_directory_visibility`
   before the RPC's own logic runs. Added explicit `grant select` on all
   four marketplace tables (and the visibility table additionally to `anon`
   since it gates buyer-facing reads).
4. **CC-20 schema allow-list test (080) needed updating** to include
   `marketplace`. This is the standard follow-on for any schema-adding CC;
   `kyc` (CC-22) and `pricing` (CC-23) did the same.
5. **Test ordering ties.** Within a single test transaction, `now()` returns
   the transaction start time, so `created_at` ties across multiple RPC
   calls. Test 108 was rewritten to assert on event status (count of
   archive transitions) rather than recency-order.
6. **`SET LOCAL role` semantics.** When `set local role authenticated` is
   placed inside a DO block, it persists across statements within the
   transaction, but the subsequent `throws_ok` was being affected. Moved
   the role + JWT setup in test 106 to top-level statements (matching the
   CC-22 test 088 pattern) to keep the role context unambiguous across
   multiple `throws_ok` calls.

## Validation results

| Gate | Target | Result |
|---|---|---|
| `bash 23-DATABASE/tests/run.sh` | 108 / ~845 / 0 | **108 / 842 / 0** ✓ |
| `npm run typecheck` | 0 errors | **0 errors** ✓ |
| `npm run build` | exit 0 | **exit 0** ✓ |
| `bash scripts/verify-admin-route-guards.sh` | VERIFICATION PASSED | **VERIFICATION PASSED** ✓ |

CC-38 frontend remains visually identical (its deferred-state messaging is
still accurate; CC-40 will swap the loaders).

## Out of scope (literal — observed)
- Booking, matching, dispatch automation, real-time tracking.
- Pricing / FX / quote integration on capacity rows.
- Capacity → shipment auto-binding.
- Rich-media carrier profiles (logos, attachments).
- Frontend wiring — that's CC-40.
- Supplier or shipment schema / RPC changes — explicitly unchanged.
- `notify.notification_category` enum extension — deferred to a notify-side CC.

## Confirmation
No changes to supplier or shipment schemas / RPCs. Migrations 0001–0032
untouched. The single notify change is a NEW trigger function on a NEW
marketplace table — no existing notify function was modified. Frontend
source files were not touched. `src/types/database.ts` was not regenerated
(can be refreshed by a routine `supabase gen types` run; not required for
CC-39 since no frontend currently references the new schema).
