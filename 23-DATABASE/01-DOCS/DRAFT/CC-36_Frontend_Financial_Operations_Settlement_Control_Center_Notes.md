# CC-36 — Frontend Financial Operations & Settlement Control Center

## Mission
Read-only finance control center across buyer / supplier / admin portals.
Surfaces invoices, settlements, escrow accounts, and an admin exception queue
without introducing any mutations or new backend surface area.

## Q1–Q10 accepted defaults (as drafted)
- **Q1=A** All buyer/supplier/admin finance routes built (10 total).
- **Q2=A** Read-only settlement center — every settlement page is a wrapper
  over existing `*_get_settlement` and `*_list_*_settlements` RPCs; no actions.
- **Q3=A** Escrow dashboards included on buyer, supplier (when RLS allows),
  and admin sides. Admin uses `settlement.admin_list_escrow_accounts`;
  buyer/supplier use direct SELECT on `settlement.escrow_accounts` with RLS.
- **Q4=A** Revenue dashboard included via `finance.{buyer|supplier|admin}_list_invoices`
  KPI aggregation (count, totals, paid, outstanding, overdue).
- **Q5=A** Admin exception center at `/admin/finance/exceptions` synthesizing
  settlements (`holding` with balance, `disputed`) + escrow accounts (`frozen`,
  `closed` with balance) via direct SELECT. No new backend logic.
- **Q6=A** `database.compat.ts` extended (sidecar) with `InvoiceSummaryRow`,
  `AdminEscrowAccountRow`, `OrgEscrowAccountRow`, `FinanceKpiBundle`,
  `FinanceExceptionRow`, `FinanceExceptionKind`. Generated `database.ts`
  untouched.
- **Q7=A** `scripts/verify-admin-route-guards.sh` extended with three CC-36
  blocks (admin/supplier/buyer).
- **Q8=A** Shared finance components: `amount-cell`, `status-badge`,
  `kpi-tile`, `settlement-summary-card`.
- **Q9=A** No workflow mutations — every page is a Server Component reading
  via existing RPCs or RLS-scoped direct SELECT. No Server Actions added.
- **Q10=A** Stopped after final validation report.

## Boundaries respected (literal — observed)
- No DB schema / migration / RPC / RLS / grant / trigger / business-logic changes.
- No migrations created. Migrations 0001–0032 untouched.
- `supabase/config.toml` untouched.
- `src/types/database.ts` untouched.
- No client-side Supabase mutations. No client-side Supabase calls at all in
  CC-36 — all routes are Server Components.
- No PSP, banking API, payment gateway, accounting system, tax engine, wallet,
  FX engine, or invoice-generation logic introduced.
- No new package dependencies added.

## Files created (20)

### Server modules (`src/lib/finance/`)
- `list-invoices.ts` — audience-switched (`buyer | supplier | admin`) wrapper
  around `finance.{buyer|supplier|admin}_list_invoices`.
- `list-escrow-accounts.ts` — admin wrapper around
  `settlement.admin_list_escrow_accounts`; plus `listOrgEscrowAccounts` direct
  SELECT for buyer/supplier visibility (RLS-driven, returns `[]` on denial).
- `compute-kpis.ts` — pure TS KPI aggregator over invoices, settlements, and
  escrow accounts. Used by all three dashboards.
- `list-exceptions.ts` — admin exception synthesis (direct SELECT on
  `settlement.settlements` + `settlement.escrow_accounts`, capped at 100 rows).

### Shared components (`src/components/finance/`)
- `amount-cell.tsx` — `formatAmount` + `<AmountCell>` (LTR-locked, fa-IR
  number formatting, currency code suffix).
- `status-badge.tsx` — `FinanceStatusBadge` domain-aware (invoice / settlement
  / escrow) with Persian labels and tone variants.
- `kpi-tile.tsx` — labelled tile with amount/count + caption + optional tone.
- `settlement-summary-card.tsx` — reusable detail card consumed by all three
  audience detail pages.

### Routes (10)
| Route | Source | Notes |
|---|---|---|
| `/buyer/finance` | `buyer_list_invoices`, `buyer_list_settlements`, direct `escrow_accounts` SELECT | KPI tiles + recent invoices + escrow table |
| `/buyer/finance/settlements` | `buyer_list_settlements` | Finance-lens settlement list |
| `/buyer/finance/settlements/[id]` | `buyer_get_settlement` | Read-only summary card |
| `/supplier/finance` | `supplier_list_my_invoices`, `supplier_list_my_settlements`, direct escrow SELECT | Escrow visibility may be empty depending on RLS |
| `/supplier/finance/settlements` | `supplier_list_my_settlements` | |
| `/supplier/finance/settlements/[id]` | `supplier_get_my_settlement` | |
| `/admin/finance` | `admin_list_invoices`, `admin_list_settlements`, `admin_list_escrow_accounts` | Cross-tenant; tables anchor escrow rows with `id="escrow-<uuid>"` for exception page jumps |
| `/admin/finance/settlements` | `admin_list_settlements` | |
| `/admin/finance/settlements/[id]` | `admin_get_settlement` + `admin_list_settlement_events` | Includes events timeline |
| `/admin/finance/exceptions` | direct SELECT on `settlements` + `escrow_accounts` | Synthesized queue; deep-links to settlement detail or admin escrow anchor |

### Verifier
`scripts/verify-admin-route-guards.sh` — three CC-36 blocks added under
admin/supplier/buyer sections; header bumped.

### Sidecar types (`src/types/database.compat.ts`)
- `InvoiceStatus`, `PaymentStatus`
- `InvoiceSummaryRow`, `AdminEscrowAccountRow`, `OrgEscrowAccountRow`
- `FinanceKpiBundle`
- `FinanceExceptionKind`, `FinanceExceptionRow`

## Files modified

- `src/types/database.compat.ts` — appended CC-36 block (no edits to prior types).
- `scripts/verify-admin-route-guards.sh` — three CC-36 verification blocks added.

## Mid-execution findings

- **Settlement status naming.** The settlement status enum uses `holding`
  (not `held`) for the "balance held in escrow" state. The KPI compute,
  status badge, and exception SELECT were corrected before validation passed.
  Escrow uses `frozen` / `closed`. These are now reflected in
  `FinanceStatusBadge`.
- **Supplier escrow direct SELECT.** Suppliers do not have a dedicated escrow
  RPC. The direct SELECT on `settlement.escrow_accounts` is left in place; if
  RLS denies, the page shows a safe explanatory empty state rather than
  failing. No backend was patched.
- **Coexistence with CC-27 settlement routes.** The pre-existing
  `/buyer/settlements`, `/supplier/settlements`, `/admin/settlements` routes
  remain the operational entry points (with mutations). The CC-36 finance
  pages are explicitly read-only mirrors that cross-link back to the
  operational views via "نمای عملیاتی" buttons.
- **Exception center scope.** Exceptions are computed entirely from existing
  table data — no new exception ledger, no new RPC, no notifications. If the
  product later wants a persistent exception queue, that would be a DB CC.

## Read-loader surface (no Server Actions added)

| Module | Audience | Backed by |
|---|---|---|
| `listInvoices("buyer")` | buyer | `finance.buyer_list_invoices` |
| `listInvoices("supplier")` | supplier | `finance.supplier_list_my_invoices` |
| `listInvoices("admin")` | admin | `finance.admin_list_invoices` |
| `listAdminEscrowAccounts` | admin | `settlement.admin_list_escrow_accounts` |
| `listOrgEscrowAccounts` | buyer / supplier | direct SELECT, RLS-driven |
| `listAdminFinanceExceptions` | admin | direct SELECT on `settlements` + `escrow_accounts` |
| `computeFinanceKpis` | all | pure TS, no I/O |
| (reused) `listBuyerSettlements` / `listSupplierSettlements` / `listAdminSettlements` / `getSettlement` / `listSettlementEvents` | per audience | existing CC-27 loaders |

No Server Actions were added in this CC.

## Validation results

| Gate | Result |
|---|---|
| `bash 23-DATABASE/tests/run.sh` | 101 / 790 / 0 — unchanged |
| `npm run typecheck` | 0 errors |
| `npm run build` | exit 0; all 10 CC-36 routes appear in the Next route table |
| `bash scripts/verify-admin-route-guards.sh` | VERIFICATION PASSED |

## Confirmation

No DB schema, migration, RPC, RLS, grant, trigger, or business-logic changes
were made. `supabase/config.toml` and `src/types/database.ts` are untouched.
No new dependencies. Migrations 0001–0032 are untouched.
