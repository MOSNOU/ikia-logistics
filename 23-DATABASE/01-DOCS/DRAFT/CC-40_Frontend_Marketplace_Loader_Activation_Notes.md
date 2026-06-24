# CC-40 — Frontend Marketplace Loader Activation

## Mission
Activate CC-38's stubbed marketplace UI by rerouting every loader and the
publish Server Action to the CC-39 RPCs. Frontend-only — no DB schema /
migration / RPC / RLS / grant / trigger changes.

## Boundaries respected
- Migrations 0001–0033 untouched. No migration 0034.
- No `marketplace.*` SQL / RPC / RLS / grant changes.
- No new dependencies. No new routes. No nav changes.
- No booking, matching, pricing, dispatch, carrier assignment, shipment
  binding, GPS, map, payment, PSP, tax, insurance, or notification-channel
  logic added.
- `supabase/config.toml` untouched.
- `src/types/database.ts` was regenerated via `supabase gen types typescript
  --local` because typecheck proved it required: the supabase client narrows
  `schema(...)` arguments to the literal set of schemas in the generated
  types, and the pre-CC-39 file did not contain `marketplace`. The CC-21
  barrel re-export (`export * from "./database.compat"`) was re-appended
  after regeneration so the sidecar continues to work.

## Loader activation map

| Loader / action | CC-38 source | CC-40 source |
|---|---|---|
| `listCarriers(audience, …)` | direct SELECT on `organization.organizations` (type='carrier') | `marketplace.buyer_list_carriers` / `marketplace.admin_list_carriers` |
| `getCarrier(id, audience)` | direct SELECT | `marketplace.buyer_get_carrier` / `marketplace.admin_get_carrier` |
| `listCapacity(audience, …)` | placeholder returning `{ rows: [], available: false, note }` | `marketplace.buyer_list_capacity` / `supplier_list_my_capacity` / `admin_list_capacity` |
| `listMarketplaceKpis(audience, input)` | carrier count via direct SELECT, capacity count hard-coded 0 | `buyer/admin_list_carriers` (count), `admin_capacity_summary` (admin total), `buyer_list_capacity` / `supplier_list_my_capacity` (non-admin totals) |
| `listMarketplaceActivity()` | synthesized from `admin_list_shipments` (booked + in_transit) | `marketplace.admin_list_activity` over the real `capacity_status_events` ledger |
| `publishCapacity` Server Action | deferred-API stub returning Persian error | `marketplace.supplier_publish_capacity` with full param mapping + error-code translation |
| `archiveCapacity` Server Action | (none) | `marketplace.supplier_archive_capacity` — exposed for forthcoming archive UI |

`shipmentsByMode` and `recentShipmentCount` continue to draw from existing
shipment list loaders since CC-39 did not introduce any shipment-side surface.

## Files modified (14)

### Loaders + action (`src/lib/marketplace/`)
- `list-carriers.ts` — rewritten as audience-switched RPC caller.
- `list-capacity.ts` — rewritten as audience-switched RPC caller; supplier
  audience needs `carrierOrganizationId`; absent it returns a friendly empty
  state instead of failing the page.
- `list-marketplace-kpis.ts` — `carriers.count` and `capacityListings.count`
  now come from marketplace RPCs; admin path uses `admin_capacity_summary`
  for the platform-wide total.
- `list-marketplace-activity.ts` — rewritten over `marketplace.admin_list_activity`;
  maps `to_status=active` → `capacity_published`, `to_status=archived` →
  `capacity_archived`.
- `publish-capacity.ts` — real call to `supplier_publish_capacity`. RPC error
  codes 22023 (non-carrier org) and 42501 (insufficient role) are translated
  into Persian copy. Added `archiveCapacity` action over
  `supplier_archive_capacity` for follow-on UI.

### Components (`src/components/marketplace/`)
- `carrier-card.tsx` — status labels updated to `marketplace.carrier_profile_status`
  values; display-name fallback (display_name_fa → name_fa, EN equivalent).
- `capacity-card.tsx` — uses new field names (`carrier_organization_id`,
  `carrier_name_fa/en`, `origin_country_code`, etc.); status optional.
- `activity-feed.tsx` — KIND_LABEL extended with `capacity_archived`.

### Sidecar types (`src/types/database.compat.ts`)
- `CarrierSummary` reshaped to match `marketplace.{buyer|admin}_list_carriers`.
- `CapacityListing` reshaped to match the three `*_list_capacity` RPCs;
  `status` made optional (buyer RPC omits it).
- `MarketplaceActivityRow.kind` extended with `capacity_archived`.
- Added `CarrierProfileStatus` and `CapacityStatus` (pulled from the
  regenerated `Database["marketplace"]["Enums"]`).

### Routes (8 — pages unchanged structurally; loader call sites + empty-state
copy updated)
- `/buyer/marketplace` — KPI captions reworded; deferred-API notice replaced
  with a real "only public carriers and active in-window capacity surface
  here" explanation.
- `/buyer/marketplace/carriers` — `listCarriers("buyer", …)`; empty-state
  copy updated.
- `/buyer/marketplace/capacity` — `listCapacity("buyer", …)`; intro copy
  updated.
- `/supplier/marketplace` — passes `carrierOrganizationId` from
  `getProfile()`; KPI caption explains the non-carrier case.
- `/supplier/marketplace/capacity` — `listCapacity("supplier", …)` with
  caller's org; empty-state copy points at the publish flow.
- `/supplier/marketplace/publish` + `publish-capacity-form.tsx` — server
  component now reads `getProfile()` and passes `carrierOrganizationId` as a
  hidden field; form disables submit when org is missing.
- `/admin/marketplace` — `listCarriers("admin", …)`; KPI caption updated.
- `/admin/marketplace/activity` — intro copy now references the real ledger.

### Generated types
- `src/types/database.ts` — regenerated via `supabase gen types typescript
  --local` (12 168 lines + the CC-21 barrel re-export). This was the
  triggering change for the typecheck escape hatch in the brief.

## Files created (1)

- `23-DATABASE/01-DOCS/DRAFT/CC-40_Frontend_Marketplace_Loader_Activation_Notes.md`

## Validation results

| Gate | Target | Result |
|---|---|---|
| `bash 23-DATABASE/tests/run.sh` | 108 / 842 / 0 | **108 / 842 / 0** ✓ |
| `npm run typecheck` | 0 errors | **0 errors** ✓ |
| `npm run build` | exit 0 | **exit 0** ✓ |
| `bash scripts/verify-admin-route-guards.sh` | VERIFICATION PASSED | **VERIFICATION PASSED** ✓ |

Route count unchanged at **118** (CC-38 routes retained structurally).

## Mid-execution findings

1. **Typecheck triggered `database.ts` regeneration.** The supabase typed
   client narrows `schema(...)` to the literal union of schemas in the
   generated `Database` type. Without regeneration, every
   `supabase.schema("marketplace").rpc(...)` call raised a TS2345. The brief
   explicitly permits regeneration when typecheck proves it required;
   regenerated via `supabase gen types typescript --local` and re-appended
   the CC-21 sidecar barrel.
2. **Status enums migrated to typed Database references** after regeneration.
   The transient string-union fallback used during the brown-out is replaced
   by `Database["marketplace"]["Enums"]["carrier_profile_status"]` and
   `["capacity_status"]` so the sidecar stays in lock-step with SQL.
3. **`CarrierSummary` had to be reshaped, not extended.** CC-38's projection
   exposed `tenant_id` (which the RPC does not return) and used
   `OrganizationStatus` (the RPC returns `carrier_profile_status`). Updating
   the carrier-card to render the new status set was mandatory.
4. **`CapacityListing.status` is now optional.** `buyer_list_capacity` only
   surfaces active rows and omits the status column from its projection;
   `supplier_list_my_capacity` and `admin_list_capacity` include it. The
   capacity-card renders the status badge only when present.
5. **Empty-state copy was demoted from "بزودی".** Now reflects real
   visibility semantics: "only carriers with public visibility appear",
   "capacity surfaces here once published and in window", etc.
6. **Supplier publish requires `carrierOrganizationId`.** The form passes the
   caller's `primaryOrganizationId` as a hidden field; the RPC's
   `fn_assert_carrier_org_type` and `fn_assert_carrier_actor` provide the
   real gate. If the caller's org is not a carrier (22023) or they lack
   `carrier_admin` (42501), the action returns a translated Persian error.

## Confirmation
- No changes to migrations 0001–0033. No new migration. No marketplace SQL,
  RPC, RLS, or grant changes. `supabase/config.toml` unchanged.
- No new routes; CC-38 route count of 118 preserved.
- No new package dependencies.
- The frontend now reads/writes through the CC-39 marketplace surface end to
  end; CC-38's deferred-API stubs are gone.
