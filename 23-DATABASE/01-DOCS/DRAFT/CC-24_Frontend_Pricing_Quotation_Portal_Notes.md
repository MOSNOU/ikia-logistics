# CC-24 — Phase 2.17 Frontend Pricing & Quotation Portal Foundation, Notes

Version: 1.0 (DRAFT)
Scope: Eighteenth platform step. Frontend-only — wires the CC-23 `pricing.*`
RPCs through Next.js Server Actions + server-rendered pages across the
existing supplier, buyer, and admin portals.
Migration: **none.** DB baseline 0001–0032 is unchanged.
Status: Implementation complete; all directives met. Pending user acceptance.

## Locked decisions (Q1–Q10)

| # | Decision | Notes |
|---|----------|--------|
| Q1 | A — all 10 routes shipped | Supplier × 6, buyer × 2, admin × 2. |
| Q2 | B — read-only captures tab in `/admin/pricing` | No admin "capture" form; admins call SQL when needed. |
| Q3 | B — read-only rates table + `/admin/pricing/currency-rates/new` form | One form, no inline edits. |
| Q4 | A — added 4 row/wrapper interfaces to `database.compat.ts` | `PriceListListRow`, `QuotationListRow`, `CurrencyRateRow`, `QuotationDetail`. |
| Q5 | A — `src/app/buyer/layout.tsx` (already existed; reused as-is) | Verifier now asserts presence + role gate. |
| Q6 | A — Next.js Server Actions only | `"use server"` modules in `src/lib/pricing/*` and `src/lib/admin/*`. |
| Q7 | A — inline upsert per row | One POST per item; matches `/supplier/documents/new` pattern. |
| Q8 | A — no KYC badge / gate | Quotation send works regardless of supplier KYC status. |
| Q9 | A — `scripts/verify-admin-route-guards.sh` extended | Buyer-portal section added + checks for all 10 new pages. |
| Q10 | A — stop at typecheck + build + verifier green | No browser smoke. |

## What changed

### Files created (22)

**Server-action / data-loader modules (10)**

| File | RPCs |
|---|---|
| `src/lib/pricing/list-my-price-lists.ts` | `pricing.get_my_price_lists` |
| `src/lib/pricing/get-price-list.ts` | `pricing.price_lists` + `pricing.price_list_items` SELECT |
| `src/lib/pricing/list-my-quotations.ts` | `pricing.portal_list_my_quotations` |
| `src/lib/pricing/get-quotation.ts` | `pricing.get_quotation` |
| `src/lib/pricing/portal-actions.ts` | 10 Server Actions: create / upsert-item / publish / pause / archive price-list; create / add-item / send / accept / reject quotation |
| `src/lib/admin/list-price-lists.ts` | `pricing.admin_list_price_lists` |
| `src/lib/admin/list-quotations.ts` | `pricing.admin_list_quotations` |
| `src/lib/admin/list-currency-rates.ts` | `pricing.list_currency_rates` |
| `src/lib/admin/list-quote-captures.ts` | `pricing.quote_captures` SELECT (Q2=B read-only) |
| `src/lib/admin/pricing-admin-actions.ts` | 2 Server Actions: `admin_set_currency_rate`, `admin_expire_due_quotations` |

**Page + component files (12)**

| Path | Purpose |
|---|---|
| `app/supplier/price-lists/page.tsx` | list view + status filter |
| `app/supplier/price-lists/new/page.tsx` + `create-price-list-form.tsx` | create form |
| `app/supplier/price-lists/[listId]/page.tsx` + `status-actions.tsx` + `upsert-item-form.tsx` | detail + actions + inline upsert |
| `app/supplier/quotations/page.tsx` | list view + status filter |
| `app/supplier/quotations/new/page.tsx` + `create-quotation-form.tsx` | create form |
| `app/supplier/quotations/[quotationId]/page.tsx` + `add-item-form.tsx` + `send-quotation-form.tsx` | detail + add item + send |
| `app/buyer/quotations/page.tsx` | list view |
| `app/buyer/quotations/[quotationId]/page.tsx` + `response-actions.tsx` | detail + accept / reject (inline) |
| `app/admin/pricing/page.tsx` | tabbed dashboard (price lists / quotations / currency rates / captures) |
| `app/admin/pricing/currency-rates/new/page.tsx` + `set-currency-rate-form.tsx` | rate insert form |

### Files modified (2)

| File | Change |
|---|---|
| `src/types/database.compat.ts` | Added 4 interfaces + 3 enum aliases under "CC-24: Pricing portal types" section. CC-21 sidecar pattern preserved. |
| `scripts/verify-admin-route-guards.sh` | Header expanded for CC-24. Added admin pricing checks. Added supplier pricing checks. Added entire "Buyer portal" section (layout + 2 pages). |

**Files NOT touched:** CC-23 migrations, `pricing.*` schema / RPCs / RLS / grants, `database.ts` generated file, `supabase/config.toml`, all CC-22 KYC code, all CC-21 sidecar entries below the new "CC-24" block, all `notify.*` / `offer.*` / `contract.*` / `supplier.*` / `commodity.*` / `finance.*` / `settlement.*` / `dispute.*` code.

### Route inventory

10 new routes:

```
/supplier/price-lists                           (server-rendered list)
/supplier/price-lists/new                       (form)
/supplier/price-lists/[listId]                  (detail + status actions + upsert form)
/supplier/quotations                            (server-rendered list)
/supplier/quotations/new                        (form)
/supplier/quotations/[quotationId]              (detail + add-item + send)
/buyer/quotations                               (server-rendered list)
/buyer/quotations/[quotationId]                 (detail + accept / reject)
/admin/pricing                                  (tabbed dashboard)
/admin/pricing/currency-rates/new               (rate insert form)
```

Build route count: **25 → 35 (+10).**

## Validation results

| Gate | Required | Actual |
|---|---|---|
| `bash 23-DATABASE/tests/run.sh` | 101 / 790 / 0 (unchanged) | **101 files / 790 assertions / 0 failures** |
| `npm run typecheck` | 0 errors | **0 errors** |
| `npm run build` | exit 0; route count grows | **35 routes built**, exit 0 |
| `bash scripts/verify-admin-route-guards.sh` | extended + pass | **VERIFICATION PASSED** (admin + supplier + buyer sections all green) |

### Type wiring

- Canonical pricing types come from the regenerated `Database['pricing']['Tables'][...]['Row']` / `Database['pricing']['Enums'][...]` shapes generated in CC-23.
- The 4 sidecar interfaces (`PriceListListRow`, `QuotationListRow`, `CurrencyRateRow`, `QuotationDetail`) model the projected shapes of `SET RETURNING` RPCs and the `get_quotation` jsonb wrapper — the same convention used for `AdminSupplierListRow` / `AdminSupplierDetailRow` in CC-21.
- Loader functions cast RPC return shapes through `as unknown as <Interface>[]` (intentional, documented), matching CC-21 `get-supplier.ts`.

## Mid-execution findings

None. CC-23's RPC argument shapes mapped cleanly to Server Action signatures on the first pass. Typecheck went green without iteration; build went green on the first attempt.

## Boundaries respected

- ✅ No DB schema / RPC / RLS / grant modifications. CC-23 baseline is byte-identical.
- ✅ No new migrations. First slot remains `0033_*` reserved for the next CC.
- ✅ No client-side Supabase mutations. Every write goes through `"use server"` modules and `createClient()` from `src/lib/supabase/server.ts`.
- ✅ No real-time / WebSocket / polling.
- ✅ No CSV / Excel import-export.
- ✅ No payment / PSP / tax / VAT UI.
- ✅ No automatic discount application.
- ✅ No KYC badge or gate on the UI.
- ✅ No notify-inbox integration.
- ✅ No changes to `notify.*` / `offer.*` / `contract.*` / `supplier.*` / `commodity.*` / `finance.*` / `settlement.*` / `dispute.*` schemas or RPCs.
- ✅ Append-only file additions; no existing supplier / admin route deleted or refactored.

## Known limitations / handoff notes

1. **Product picker is UUID-only.** The upsert-item and add-item forms currently take `product_id` as a raw UUID string. A typeahead picker backed by `commodity.products` is a small follow-up (UI only, no DB change).
2. **Buyer organization picker is UUID-only.** Same story — the buyer side of `portal_create_quotation` takes `buyer_organization_id` as a raw UUID. Reads cleanly from URL or paste; a picker is a future polish item.
3. **No `portal_withdraw_quotation` UI** because the RPC does not exist in CC-23 (the enum value exists; the RPC is reserved for a future CC). Supplier sees the option in status-filter dropdown for completeness only.
4. **No "resume" button on paused price lists.** CC-23 lacks a `portal_resume_price_list` RPC; the only post-pause action is archive. UI surfaces only what the RPC supports.
5. **Currency-rates listing lives only inside the `/admin/pricing?tab=currency-rates` tab.** No standalone `/admin/pricing/currency-rates` index route — the form lives one level deeper at `/admin/pricing/currency-rates/new`. This is intentional to keep the tab-based dashboard pattern.
6. **Quote-captures tab is read-only (Q2=B).** `admin_capture_quote` is exposed in the server-actions module (`admin/pricing-admin-actions.ts`) but not wired to any UI button. Future captures will be driven by upstream events (offer submission, contract execution) when those domains add capture calls.
7. **Sidecar interfaces are projection-shaped, not table-shaped.** As with CC-21, if the canonical pricing RPC return shapes ever change, both the sidecar and the consumer code need updating. A pgTAP tripwire test (analogous to `082_cc21_schema_drift_guard.sql`) could lock the column sets — deliberately not added in CC-24 since pgTAP baseline must stay unchanged.

## Acceptance criteria

- [ ] `bash 23-DATABASE/tests/run.sh` reports **101 / 790 / 0** (unchanged). ✓
- [ ] `npm run typecheck` exits 0. ✓
- [ ] `npm run build` exits 0 with 35 routes. ✓
- [ ] `bash scripts/verify-admin-route-guards.sh` passes the extended verifier. ✓
- [ ] Confirm the inline UUID picker pattern is acceptable as a starting point (vs. blocking on a typeahead product / org picker).
- [ ] Confirm CC-25 may proceed (Tracking / Workflow / PSP / MVP).
