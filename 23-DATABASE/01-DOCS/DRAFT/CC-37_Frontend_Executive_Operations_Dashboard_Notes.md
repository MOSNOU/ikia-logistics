# CC-37 — Frontend Executive Operations Dashboard

## Mission
Read-only executive dashboard across buyer / supplier / admin portals that
aggregates platform status from the existing frontend surfaces (RFQ, offers,
evaluations, contracts, shipments, finance, settlements, disputes, KYC,
notifications). Frontend-only. No new backend.

## Boundaries respected
- No DB schema / migration / RPC / RLS / grant / trigger / business-logic changes.
- Migrations 0001–0032 untouched. No migrations created.
- `supabase/config.toml` untouched.
- `src/types/database.ts` untouched.
- No new dependencies.
- No client-side Supabase calls — every page is a Server Component reading via
  existing loaders.

## Audience matrix
| Audience | Scope | Auth gate |
|---|---|---|
| `/admin/executive` | Platform-wide | `PLATFORM_ADMIN` via existing `/admin` layout |
| `/buyer/executive` | Buyer org | `BUYER_ADMIN, ORGANIZATION_ADMIN, PLATFORM_ADMIN` via existing `/buyer` layout |
| `/supplier/executive` | Supplier org | `SUPPLIER_ADMIN, ORGANIZATION_ADMIN, PLATFORM_ADMIN` via existing `/supplier` layout |

## Files created (12)

### Sidecar types (`src/types/database.compat.ts`)
- CC-37 block: `ExecutiveAudience`, `ExecutiveKpi`, `PipelineStep`, `RiskItem`,
  `ActivityRow`, `QuickLink`, `ExecutiveDashboardBundle`.

### Loaders (`src/lib/executive/`)
- `compute-dashboard-kpis.ts` — pure TS aggregator that derives KPIs, pipeline
  steps, risk panel, and activity feed from raw rows. Includes `ACTIVE_STATUS`
  constants so every audience uses the same definition of "active".
- `load-admin-executive-dashboard.ts` — orchestrator for the platform admin
  dashboard. Calls 13 existing loaders in parallel.
- `load-buyer-executive-dashboard.ts` — buyer-org orchestrator. Calls 11
  existing loaders + `getMyOrganizationVerification`.
- `load-supplier-executive-dashboard.ts` — supplier orchestrator. Calls 11
  existing loaders + both `getMyOrganizationVerification` and
  `getMyPersonalVerification`.

### Components (`src/components/executive/`)
- `kpi-card.tsx` — labelled KPI with value, tone, and optional href.
- `status-breakdown.tsx` — chip grid for status-keyed counts.
- `operations-timeline.tsx` — horizontal pipeline (RFQ → Offer → Evaluation →
  Contract → Shipment → Settlement) with arrows and per-step counts.
- `risk-panel.tsx` — risk table with severity badges and detail links.
- `action-link-grid.tsx` — quick-link grid for portal entry points.

### Routes (3)
- `/admin/executive` — platform-wide.
- `/buyer/executive` — buyer-org scoped.
- `/supplier/executive` — supplier-org scoped.

## Files modified (2)
- `src/types/database.compat.ts` — appended CC-37 block.
- `scripts/verify-admin-route-guards.sh` — three CC-37 verifier blocks plus
  header bump.

## Route count
- Before CC-37: **107** routes.
- After CC-37: **110** routes (+3).

## Loader surface
No Server Actions added. CC-37 is entirely read-side. Reused loaders:

| Domain | Admin | Buyer | Supplier |
|---|---|---|---|
| RFQ | `listAdminRfqs` | `listBuyerRfqs` | `listSupplierRfqs` (invitation-shape, normalized) |
| Offer | `listAdminOffers` | `listBuyerReceivedOffers` | `listSupplierOffers` |
| Evaluation | `listAdminEvaluations` | `listBuyerEvaluations` | **N/A** (no supplier RPC) — degraded |
| Contract | `listAdminPreparations` + `listAdminExecuted` | `listBuyerPreparations` + `listBuyerExecuted` | `listSupplierPreparations` + `listSupplierExecuted` |
| Shipment | `listAdminShipments` | `listBuyerShipments` | `listSupplierShipments` |
| Settlement | `listAdminSettlements` | `listBuyerSettlements` | `listSupplierSettlements` |
| Dispute | `listAdminDisputes` | `listBuyerDisputes` | `listSupplierDisputes` |
| KYC/KYB | `listKycVerifications` × {organization, person} | `getMyOrganizationVerification` | `getMyOrganizationVerification` + `getMyPersonalVerification` |
| Notifications | `getUnreadCount` + `listMyNotifications` | same | same |
| Finance exceptions | `listAdminFinanceExceptions` | N/A (admin-only by RPC) — degraded | N/A (admin-only) — degraded |

Graceful degradation: when a section is unavailable for an audience, the
dashboard shows an "N/A" tile and lists the explanation under
`unavailableSections`. No backend was patched.

## Mid-execution findings

- **Supplier evaluation surface is absent.** No supplier-side
  `list-evaluations` loader/RPC exists. The supplier KPI tile is marked
  `available=false` and the pipeline shows `N/A` at the evaluation step.
- **Supplier RFQ shape is invitation-shaped.** `listSupplierRfqs` returns
  `SupplierRfqInvitationRow` (`request_status`, `invited_at`, …). The
  supplier loader normalizes this to the shared `{ status, created_at }`
  shape so the KPI/pipeline/activity builders can stay generic.
- **Finance exceptions are admin-only by design.** Buyer and supplier
  dashboards skip the "finance exceptions" KPI rather than synthesizing a
  different one.
- **High-priority unread notifications** are computed in TS over the first
  page of `listMyNotifications` (50 rows). If a tenant has more than 50
  unread notifications and the high-priority ones land further down, the
  number is a lower bound. Acceptable for an executive overview; a precise
  count would need a dedicated RPC.

## Validation results

| Gate | Result |
|---|---|
| `bash 23-DATABASE/tests/run.sh` | 101 / 790 / 0 — unchanged |
| `npm run typecheck` | 0 errors |
| `npm run build` | exit 0; route count 107 → 110 (+3) |
| `bash scripts/verify-admin-route-guards.sh` | VERIFICATION PASSED |

## Confirmation
No DB / migration / RPC / RLS / grant / trigger / config changes were made.
`supabase/config.toml` and `src/types/database.ts` untouched. No new deps.
