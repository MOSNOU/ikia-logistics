# CC-38 — Capacity & Carrier Marketplace Foundation

## Mission
First marketplace visibility layer. Buyers discover carriers, suppliers see
the publish surface, admins observe marketplace activity. Visibility only —
no booking engine, no matching engine, no pricing changes.

## Boundaries respected
- No DB schema / migration / RPC / RLS / grant / trigger / business-logic changes.
- No new dependencies.
- `src/types/database.ts` untouched.
- `supabase/config.toml` untouched.
- No client-side Supabase mutations.

## Data-source reality check
A marketplace schema does not yet exist in the database. CC-38 wires routes
against the closest existing primitives and degrades gracefully where no
backend exists:

| Concept | Source today | Notes |
|---|---|---|
| Carrier | `organization.organizations` filtered by `type='carrier'` | RLS denies non-admin non-member access; buyer pages show explanatory empty-state |
| Capacity listing | None (no table, no RPC) | `listCapacity` returns `{ rows: [], available: false }` with a Persian note explaining the deferral |
| Marketplace activity | Synthesized from `admin_list_shipments` (booked + in_transit) | Until a dedicated event ledger exists |
| Marketplace KPIs | Carrier count via direct SELECT + shipments grouped by `transport_mode` | Admin sees full counts; buyer/supplier see RLS-scoped counts |
| Publish capacity | `publishCapacity` Server Action returns deferred-API error | UI form is fully wired; only the action body changes when a DB CC adds the RPC |

## Files created (15)

### Sidecar types (`src/types/database.compat.ts`)
- CC-38 block: `TransportMode`, `CarrierSummary`, `CapacityListing`,
  `MarketplaceKpiBundle`, `MarketplaceActivityRow`.

### Loaders (`src/lib/marketplace/`)
- `list-carriers.ts` — `listCarriers` + `getCarrier` direct SELECT on
  `organization.organizations`.
- `list-capacity.ts` — placeholder; returns `{ rows: [], available: false, note }`.
- `list-marketplace-kpis.ts` — count carriers + audience-switched recent-shipments
  with mode distribution.
- `list-marketplace-activity.ts` — synthesized from recent admin shipments
  in `booked`/`in_transit` status.
- `publish-capacity.ts` — Server Action stub returning deferred-API error.

### Components (`src/components/marketplace/`)
- `carrier-card.tsx` — organization summary card with status badge.
- `capacity-card.tsx` — listing card with mode, route, validity window.
- `marketplace-filters.tsx` — composable filter form (search / mode / route).
- `marketplace-kpi-card.tsx` — KPI tile with `available` fallback.
- `activity-feed.tsx` — Persian-labelled activity table.

### Routes (8)
| Route | Audience | Source |
|---|---|---|
| `/buyer/marketplace` | buyer | KPIs from buyer-shipments + carrier count |
| `/buyer/marketplace/carriers` | buyer | `listCarriers` (RLS-degraded for buyers) |
| `/buyer/marketplace/capacity` | buyer | placeholder list, filter UI in place |
| `/supplier/marketplace` | supplier | KPIs from supplier-shipments + carrier count |
| `/supplier/marketplace/capacity` | supplier | placeholder list |
| `/supplier/marketplace/publish` | supplier | client form + deferred Server Action |
| `/admin/marketplace` | admin | KPIs + carrier sample + mode distribution |
| `/admin/marketplace/activity` | admin | synthesized activity feed |

Plus one supporting client form: `src/app/supplier/marketplace/publish/publish-capacity-form.tsx`.

## Files modified (2)
- `src/types/database.compat.ts` — appended CC-38 block.
- `scripts/verify-admin-route-guards.sh` — three CC-38 verifier blocks
  (admin/supplier/buyer) plus header bump.

## Route count
Before: **110**. After: **118** (+8).

## Validation results

| Gate | Result |
|---|---|
| `bash 23-DATABASE/tests/run.sh` | 101 / 790 / 0 — unchanged |
| `npm run typecheck` | 0 errors |
| `npm run build` | exit 0; 8 new routes |
| `bash scripts/verify-admin-route-guards.sh` | VERIFICATION PASSED |

## Mid-execution findings

- **No `carrier.*` or `marketplace.*` schema exists.** Carriers are
  organizations with `type='carrier'`; a dedicated marketplace schema is
  expected in a future DB CC.
- **Organizations RLS denies cross-org reads for non-admin users.** Buyer and
  supplier carrier-list pages will be empty until either (a) the user's org is
  itself a carrier (membership grants visibility), or (b) a future
  `carrier_directory` RPC opens read access. Empty-state copy explains this in
  Persian.
- **No capacity table.** Capacity routes show a deferred-API explanation, the
  filter UI is wired and ready for the day data arrives.
- **No marketplace events.** Admin activity feed is synthesized from
  `admin_list_shipments` (`booked` + `in_transit`). When a marketplace event
  table is added later, only `list-marketplace-activity.ts` changes.
- **`publishCapacity` Server Action** has the right shape but no backing RPC.
  When a future DB CC adds e.g. `marketplace.carrier_publish_capacity(...)`,
  only the action body changes; the form, route, and verifier stay put.

## Confirmation
No DB / migration / RPC / RLS / grant / trigger / config changes were made.
Migrations 0001–0032 untouched. No new dependencies. `src/types/database.ts`
untouched.
